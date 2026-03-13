$checks = @(
  'Section opens',
  'All 18 tabs load',
  'Plan enumeration',
  'Active plan readback',
  'Clone/export/import',
  'Profile apply + verify',
  'Processor setting change + verify',
  'PCIe setting change + verify',
  'USB setting change + verify',
  'Display setting change + verify',
  'Sleep setting change + verify',
  'NIC property enumeration/change + verify if present',
  'Wake-device enable/disable + verify',
  'Report generation',
  'Snapshot restore',
  'Source build path test',
  'Packaged build path test'
)

Write-Output 'Falcon Power Management Windows Validation Checklist'
$checks | ForEach-Object { Write-Output ('[ ] ' + $_) }

if ($IsWindows) {
  Write-Output 'Running quick smoke checks on this Windows host...'
  powercfg /getactivescheme
  powercfg /list
  powercfg /query SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX
  try { Get-NetAdapter -Physical | Select-Object Name,Status | Format-Table -AutoSize | Out-String | Write-Output } catch {}
  try { powercfg /devicequery wake_programmable | Out-String | Write-Output } catch {}
}
