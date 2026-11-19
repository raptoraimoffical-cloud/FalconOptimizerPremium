'use strict';
const { R, regSet, regDel, ps } = require('./_steps');

const GFX = R`HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`;
const DXPREF = R`HKCU\Software\Microsoft\DirectX\UserGpuPreferences`;

// Merge/replace one key inside the semicolon-separated DirectXUserGlobalSettings string without
// clobbering other per-user DirectX settings (e.g. VRROptimizeEnable, AutoHDREnable).
const dxGlobal = (key, val) => R`
$p = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
$cur = (Get-ItemProperty -Path $p -Name DirectXUserGlobalSettings -ErrorAction SilentlyContinue).DirectXUserGlobalSettings
$parts = @(); if ($cur) { $parts = @($cur.Split(';') | Where-Object { $_ -and ($_ -notmatch '^${key}=') }) }
$parts += '${key}=${val}'
Set-ItemProperty -Path $p -Name DirectXUserGlobalSettings -Value (($parts -join ';') + ';') -Type String
'DirectXUserGlobalSettings: ' + (($parts -join ';') + ';')`;
const dxGlobalCheck = (key, val) => R`
$cur = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name DirectXUserGlobalSettings -ErrorAction SilentlyContinue).DirectXUserGlobalSettings
if ($cur -match '(^|;)${key}=${val}(;|$)') { 'true' } else { 'false' }`;

module.exports = (ctx) => {
  const gpus = (ctx.profile.gpus || []).filter((g) => /^PCI\\/i.test(g.pnp || ''));
  const msiKey = (pnp) => `HKLM\\SYSTEM\\CurrentControlSet\\Enum\\${pnp}\\Device Parameters\\Interrupt Management\\MessageSignaledInterruptProperties`;

  return [
    {
      id: 'gpu.hags_on',
      category: 'gpu',
      kind: 'toggle',
      name: 'Hardware-accelerated GPU scheduling (HAGS)',
      summary: 'Lets the GPU manage its own video memory scheduling instead of the CPU-side Windows scheduler.',
      details: 'Removes a layer of CPU work from every frame submission and is required for DLSS Frame Generation (and recommended by NVIDIA/AMD for Reflex/Anti-Lag 2). Supported on GeForce GTX 10-series+, Radeon RX 5000+, and Intel Arc. Default-on for supported GPUs on fresh Windows 11 24H2 installs.',
      impact: { latency: 1, fps: 1 },
      evidence: 'documented',
      risk: 'safe',
      presets: ['latency', 'fps'],
      reboot: 'reboot',
      when: (c) => (c.profile.gpu.vendor === 'unknown' ? 'No supported discrete GPU detected.' : null),
      apply: [regSet(GFX, 'HwSchMode', 'DWORD', 2)],
      revert: [regSet(GFX, 'HwSchMode', 'DWORD', 1)]
    },
    {
      id: 'gpu.windowed_flip_model',
      category: 'gpu',
      kind: 'toggle',
      name: 'Optimizations for windowed games (flip model)',
      summary: 'Upgrades DirectX 10/11 games running windowed or borderless to the low-latency flip presentation model.',
      details: 'Legacy "blt" presentation in windowed/borderless mode goes through an extra DWM composition copy, adding up to a frame of latency. This Windows 11 feature (Settings > Display > Graphics) switches those games to flip model, giving exclusive-fullscreen-like latency in borderless and enabling VRR/Auto HDR. DirectX 12 and Vulkan games already use flip model.',
      impact: { latency: 2, fps: 1 },
      evidence: 'documented',
      risk: 'safe',
      presets: ['latency', 'fps'],
      reboot: 'none',
      when: (c) => (c.profile.os.build < 22621 ? 'Requires Windows 11 22H2 (build 22621) or newer.' : null),
      apply: [ps(dxGlobal('SwapEffectUpgradeEnable', 1), dxGlobalCheck('SwapEffectUpgradeEnable', 1))],
      revert: [ps(dxGlobal('SwapEffectUpgradeEnable', 0))]
    },
    {
      id: 'gpu.game_dvr_off',
      category: 'gpu',
      kind: 'toggle',
      name: 'Disable Xbox Game Bar background recording',
      summary: 'Stops Game DVR from continuously encoding gameplay in the background.',
      details: 'Background recording keeps a hardware encoder session and capture hooks active while you play, costing GPU time and adding frametime variance. NVIDIA Instant Replay / AMD ReLive / OBS are unaffected.',
      tradeoff: 'Win+Alt+G "record that" clips stop working.',
      impact: { latency: 1, fps: 1 },
      evidence: 'measured',
      risk: 'safe',
      presets: ['latency', 'fps'],
      reboot: 'none',
      apply: [
        regSet(R`HKCU\System\GameConfigStore`, 'GameDVR_Enabled', 'DWORD', 0),
        regSet(R`HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR`, 'AppCaptureEnabled', 'DWORD', 0),
        regSet(R`HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR`, 'AllowGameDVR', 'DWORD', 0)
      ],
      revert: [
        regSet(R`HKCU\System\GameConfigStore`, 'GameDVR_Enabled', 'DWORD', 1),
        regSet(R`HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR`, 'AppCaptureEnabled', 'DWORD', 1),
        regDel(R`HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR`, 'AllowGameDVR')
      ]
    },
    {
      id: 'gpu.game_mode_on',
      category: 'gpu',
      kind: 'toggle',
      name: 'Windows Game Mode on',
      summary: 'Keep Game Mode enabled — on modern Windows it helps, not hurts.',
      details: 'Game Mode blocks Windows Update driver installs and restart prompts while a game runs, and gives the game priority for CPU/GPU resources. Early Windows 10 builds had issues, which is why old guides disable it. Dual-CCD Ryzen X3D CPUs rely on it to steer games to the V-Cache CCD.',
      impact: { latency: 0, fps: 1 },
      tags: ['consistency'],
      evidence: 'documented',
      risk: 'safe',
      presets: ['latency', 'fps'],
      reboot: 'none',
      apply: [regSet(R`HKCU\Software\Microsoft\GameBar`, 'AutoGameModeEnabled', 'DWORD', 1)],
      revert: [regDel(R`HKCU\Software\Microsoft\GameBar`, 'AutoGameModeEnabled')]
    },
    {
      id: 'gpu.msi_mode',
      category: 'gpu',
      kind: 'toggle',
      name: 'GPU message-signaled interrupts (MSI mode)',
      summary: 'Makes the GPU signal interrupts via MSI instead of legacy shared line-based interrupts.',
      details: 'Line-based interrupts can be shared with other devices and take a slower path through the interrupt controller; MSI gives the GPU its own vector and lowers interrupt/DPC latency. Every GPU from the last decade supports MSI. Many current drivers enable it by default — if so this already shows as applied.',
      impact: { latency: 1, fps: 0 },
      evidence: 'measured',
      risk: 'moderate',
      presets: ['latency', 'fps'],
      reboot: 'reboot',
      when: () => (gpus.length === 0 ? 'No PCI display adapter detected.' : null),
      apply: gpus.map((g) => regSet(msiKey(g.pnp), 'MSISupported', 'DWORD', 1)),
      revert: gpus.map((g) => regDel(msiKey(g.pnp), 'MSISupported'))
    },
    {
      id: 'gpu.mpo_off',
      category: 'gpu',
      kind: 'toggle',
      name: 'Disable Multiplane Overlay (MPO) — troubleshooting only',
      summary: 'Only for black-screen flicker or stutter when a browser/Discord overlay is open alongside a game.',
      details: 'MPO lets borderless games bypass DWM composition (independent flip), which is what gives borderless its low latency. Disabling it is a workaround for driver bugs and makes borderless latency worse, which is why it is not in any preset. Recent Windows 11 builds may ignore this switch.',
      tags: ['fix'],
      tradeoff: 'Higher latency in borderless/windowed games.',
      impact: { latency: -1, fps: 0 },
      evidence: 'documented',
      risk: 'moderate',
      presets: [],
      reboot: 'reboot',
      apply: [regSet(R`HKLM\SOFTWARE\Microsoft\Windows\Dwm`, 'OverlayTestMode', 'DWORD', 5)],
      revert: [regDel(R`HKLM\SOFTWARE\Microsoft\Windows\Dwm`, 'OverlayTestMode')]
    },
    {
      id: 'gpu.clear_shader_caches',
      category: 'gpu',
      kind: 'action',
      name: 'Clear GPU shader caches',
      summary: 'Deletes DirectX, NVIDIA, AMD and Intel shader caches. Use after a driver update or if a game stutters after patching.',
      details: 'Stale caches from an older driver are recompiled anyway, but corrupted caches can cause persistent stutter or crashes. Expect the first launch of each game afterwards to compile shaders again (brief stutter or a "compiling shaders" screen).',
      impact: { latency: 0, fps: 0 },
      tags: ['fix'],
      risk: 'safe',
      reboot: 'none',
      run: [ps(R`
$targets = @(
  "$env:LOCALAPPDATA\D3DSCache",
  "$env:LOCALAPPDATA\NVIDIA\DXCache", "$env:LOCALAPPDATA\NVIDIA\GLCache", "$env:ProgramData\NVIDIA Corporation\NV_Cache",
  "$env:LOCALAPPDATA\AMD\DxCache", "$env:LOCALAPPDATA\AMD\DxcCache", "$env:LOCALAPPDATA\AMD\VkCache", "$env:LOCALAPPDATA\AMD\GLCache",
  "$env:LOCALAPPDATA\Intel\ShaderCache", "$env:USERPROFILE\AppData\LocalLow\Intel\ShaderCache"
)
$freed = 0
foreach ($t in $targets) {
  if (Test-Path -LiteralPath $t) {
    Get-ChildItem -LiteralPath $t -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
      $len = $_.Length
      try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop; $freed += $len } catch {}
    }
  }
}
"Freed {0:N0} MB of shader cache (files in use were skipped)." -f ($freed / 1MB)`)]
    }
  ];
};
