'use strict';
/**
 * Per-game items, generated for each discovered game. Same schema/engine as the main catalog.
 */
const { R, regSet, regDel, ps } = require('./_steps');

const IFEO = R`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options`;
const psq = (s) => `'${String(s).replace(/'/g, "''")}'`;

function gameItems(game, profile) {
  const id = game.id;
  const exe = game.exe;
  const items = [
    {
      id: `game.${id}.cpu_priority`,
      kind: 'toggle',
      name: 'High CPU priority',
      summary: `Windows starts ${exe} at High priority every time.`,
      details: 'Uses the Image File Execution Options PerfOptions key, which Windows applies at process creation — no background tool needed. High (not Realtime) lets the game win CPU contention against background apps without starving input/audio threads. Some kernel anti-cheats reset priority; that is harmless.',
      impact: { latency: 1, fps: 1 },
      risk: 'safe',
      preset: true,
      reboot: 'none',
      apply: [regSet(`${IFEO}\\${exe}\\PerfOptions`, 'CpuPriorityClass', 'DWORD', 3)],
      revert: [regDel(`${IFEO}\\${exe}\\PerfOptions`, 'CpuPriorityClass')]
    },
    {
      id: `game.${id}.defender_exclusion`,
      kind: 'toggle',
      name: 'Exclude game folder from Defender scans',
      summary: 'Microsoft Defender stops real-time scanning files in the game folder.',
      details: 'Real-time scanning of game archives and shader caches during loading and streaming causes load-time hitches. Excluding only this install folder keeps protection everywhere else. Has no effect if a third-party antivirus replaced Defender.',
      tradeoff: 'Files in this folder are not scanned in real time.',
      impact: { latency: 0, fps: 1 },
      risk: 'moderate',
      preset: true,
      reboot: 'none',
      apply: [ps(
        R`Add-MpPreference -ExclusionPath ${psq(game.installDir)}; 'Excluded from Defender real-time scanning.'`,
        R`$e = @((Get-MpPreference).ExclusionPath); if ($e -contains ${psq(game.installDir)}) { 'true' } elseif ($e -match 'N/A') { 'unknown' } else { 'false' }`
      )],
      revert: [ps(R`Remove-MpPreference -ExclusionPath ${psq(game.installDir)}; 'Exclusion removed.'`)]
    },
    {
      id: `game.${id}.qos`,
      kind: 'toggle',
      name: 'Tag game traffic as high priority (DSCP 46)',
      summary: `Marks packets from ${exe} as Expedited Forwarding so QoS-aware routers send them first.`,
      details: 'Only helps if your router honors DSCP (many gaming routers and "QoS/SQM" setups do; most ISP routers ignore it). Falcon also sets the "Do not use NLA" switch that Windows needs to apply QoS policies on home (non-domain) PCs. Safe either way.',
      impact: { latency: 1, fps: 0 },
      risk: 'safe',
      preset: true,
      reboot: 'none',
      apply: [
        regSet(R`HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS`, 'Do not use NLA', 'SZ', '1'),
        ps(
          R`$n = ${psq(`Falcon ${id}`)}
Get-NetQosPolicy -Name $n -PolicyStore ActiveStore -ErrorAction SilentlyContinue | Remove-NetQosPolicy -Confirm:$false -ErrorAction SilentlyContinue
New-NetQosPolicy -Name $n -AppPathNameMatchCondition ${psq(exe)} -DSCPAction 46 -NetworkProfile All -IPProtocol Both | Out-Null
'QoS policy created.'`,
          R`if (Get-NetQosPolicy -Name ${psq(`Falcon ${id}`)} -ErrorAction SilentlyContinue) { 'true' } else { 'false' }`
        )
      ],
      revert: [ps(R`Get-NetQosPolicy -Name ${psq(`Falcon ${id}`)} -ErrorAction SilentlyContinue | Remove-NetQosPolicy -Confirm:$false; 'QoS policy removed.'`)]
    },
    {
      id: `game.${id}.fso_off`,
      kind: 'toggle',
      name: 'Disable fullscreen optimizations (legacy games only)',
      summary: 'Forces true exclusive fullscreen for this exe.',
      details: 'Only useful for older DirectX 9/11 titles with exclusive fullscreen that misbehave with Windows flip-model optimizations. For DX12/Vulkan and modern borderless games it does nothing or makes things worse, so it is not part of "Optimize game".',
      impact: { latency: 0, fps: 0 },
      risk: 'safe',
      preset: false,
      reboot: 'none',
      apply: [regSet(R`HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers`, game.exePath, 'SZ', '~ DISABLEDXMAXIMIZEDWINDOWEDMODE')],
      revert: [regDel(R`HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers`, game.exePath)]
    }
  ];

  if (profile && profile.hybridGraphics) {
    items.splice(1, 0, {
      id: `game.${id}.gpu_high_perf`,
      kind: 'toggle',
      name: 'Always use the high-performance GPU',
      summary: 'Pins this game to the discrete GPU on laptops / systems with integrated graphics.',
      details: 'Same as Settings > System > Display > Graphics > High performance. Prevents the game from accidentally launching on integrated graphics.',
      impact: { latency: 0, fps: 3 },
      risk: 'safe',
      preset: true,
      reboot: 'none',
      apply: [regSet(R`HKCU\Software\Microsoft\DirectX\UserGpuPreferences`, game.exePath, 'SZ', 'GpuPreference=2;')],
      revert: [regDel(R`HKCU\Software\Microsoft\DirectX\UserGpuPreferences`, game.exePath)]
    });
  }

  return items.map((it) => ({ ...it, category: 'games', gameId: id, presets: [], tags: [], evidence: 'documented' }));
}

module.exports = { gameItems };
