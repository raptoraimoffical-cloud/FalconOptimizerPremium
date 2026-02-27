param(
  [string]$Payload = "{}",
  [string]$PayloadPath
)

if ($PayloadPath -and (Test-Path -LiteralPath $PayloadPath)) {
  try { $Payload = Get-Content -LiteralPath $PayloadPath -Raw } catch {}
}
. "$PSScriptRoot\helpers.ps1"
$log = Join-Path $PSScriptRoot "..\logs\actions.log"
$errors = Join-Path $PSScriptRoot "..\logs\errors.log"
try {
  Ensure-Admin
  $ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
  $snapDir = Join-Path $PSScriptRoot "..\backups\snapshots\$ts"
  New-Item -ItemType Directory -Path $snapDir -Force | Out-Null
  Write-LogLine $log "backup:create $ts"
  try { Checkpoint-Computer -Description "Falcon Optimizer Snapshot $ts" -RestorePointType "MODIFY_SETTINGS" | Out-Null } catch {}
  $regExport = Join-Path $snapDir "policies.reg"
  & reg.exe export "HKLM\SOFTWARE\Policies" $regExport /y | Out-Null
  Write-Output "Snapshot created: $snapDir"
  exit 0
} catch {
  $msg = $_.Exception.Message
  Write-LogLine $errors "backup:error $msg"
  Write-Error $msg
  exit 1
}
