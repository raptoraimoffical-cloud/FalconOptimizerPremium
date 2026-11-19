'use strict';
const { R, ps } = require('./_steps');

module.exports = () => [
  {
    id: 'act.restore_point',
    category: 'maintenance',
    kind: 'action',
    name: 'Create a restore point',
    summary: 'Enables System Protection on C: if needed and creates a restore point.',
    details: 'Falcon also keeps its own exact-value journal for every change it makes, but a restore point is a good safety net before large changes. Windows normally limits restore points to one per 24 h; Falcon lifts that limit.',
    risk: 'safe',
    reboot: 'none',
    run: [ps(R`
$k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
New-ItemProperty -Path $k -Name SystemRestorePointCreationFrequency -PropertyType DWord -Value 0 -Force | Out-Null
try { Enable-ComputerRestore -Drive "$env:SystemDrive\" } catch {}
Checkpoint-Computer -Description ('Falcon Optimizer ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')) -RestorePointType MODIFY_SETTINGS
'Restore point created.'`)]
  },
  {
    id: 'act.clean_temp',
    category: 'maintenance',
    kind: 'action',
    name: 'Clean temporary files',
    summary: 'Clears user and Windows temp folders and the Windows Update download cache.',
    details: 'Files in use are skipped. Prefetch is intentionally left alone — clearing it only makes the next app launches slower.',
    risk: 'safe',
    reboot: 'none',
    run: [ps(R`
$freed = 0
foreach ($d in @($env:TEMP, "$env:SystemRoot\Temp", "$env:SystemRoot\SoftwareDistribution\Download")) {
  if (-not (Test-Path -LiteralPath $d)) { continue }
  Get-ChildItem -LiteralPath $d -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
    $len = $_.Length
    try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop; $freed += $len } catch {}
  }
}
"Freed {0:N0} MB." -f ($freed / 1MB)`)]
  },
  {
    id: 'act.trim_ssds',
    category: 'maintenance',
    kind: 'action',
    name: 'TRIM all SSDs now',
    summary: 'Runs a retrim on every SSD volume so the drive can keep write performance up.',
    details: 'Windows already does this weekly via scheduled optimization; run it manually after deleting large games.',
    risk: 'safe',
    reboot: 'none',
    run: [ps(R`
$ssd = @(Get-PhysicalDisk | Where-Object MediaType -eq 'SSD')
$n = 0
foreach ($v in Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }) {
  try { Optimize-Volume -DriveLetter $v.DriveLetter -ReTrim -ErrorAction Stop; $n++ } catch {}
}
"Retrimmed $n volume(s) ($($ssd.Count) SSD(s) detected)."`)]
  },
  {
    id: 'act.flush_dns',
    category: 'maintenance',
    kind: 'action',
    name: 'Flush DNS cache',
    summary: 'Clears cached DNS lookups. Useful when a game server or launcher cannot connect after a network change.',
    risk: 'safe',
    reboot: 'none',
    run: [ps(R`Clear-DnsClientCache; 'DNS cache flushed.'`)]
  },
  {
    id: 'act.network_reset',
    category: 'maintenance',
    kind: 'action',
    name: 'Reset network stack',
    summary: 'Resets Winsock and TCP/IP to defaults. Fixes broken connectivity left behind by old network "optimizers".',
    details: 'Removes all custom TCP/IP global settings and Winsock LSPs. Wi-Fi passwords and adapter drivers are kept. A restart is required.',
    risk: 'moderate',
    reboot: 'reboot',
    run: [ps(R`netsh winsock reset | Out-Null; netsh int ip reset | Out-Null; netsh int tcp reset | Out-Null; Clear-DnsClientCache; 'Network stack reset. Restart to finish.'`)]
  },
  {
    id: 'act.repair_windows',
    category: 'maintenance',
    kind: 'action',
    name: 'Repair Windows system files (DISM + SFC)',
    summary: 'Repairs the component store, then verifies and repairs protected system files.',
    details: 'Runs DISM /RestoreHealth followed by SFC /scannow. Takes 5–20 minutes and needs an internet connection for DISM.',
    long: true,
    risk: 'safe',
    reboot: 'none',
    run: [ps(R`
$d = & DISM.exe /Online /Cleanup-Image /RestoreHealth /NoRestart 2>&1 | Select-Object -Last 3
$s = & sfc.exe /scannow 2>&1 | Where-Object { $_ -match '\S' } | Select-Object -Last 3
"DISM: " + (($d | Out-String).Trim())
"SFC: " + ((($s | Out-String) -replace "\x00", '').Trim())`)]
  }
];
