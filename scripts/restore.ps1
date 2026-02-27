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
  $snapRoot = Join-Path $PSScriptRoot "..\backups\snapshots"
  if (!(Test-Path $snapRoot)) { throw "No snapshots folder found." }
  $latest = Get-ChildItem $snapRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
  if ($null -eq $latest) { throw "No snapshots found." }
  $regFile = Join-Path $latest.FullName "policies.reg"
  if (Test-Path $regFile) { & reg.exe import $regFile | Out-Null }
  Write-LogLine $log "backup:restore $($latest.Name)"
  Write-Output "Restored snapshot: $($latest.FullName)"
  exit 0
} catch {
  $msg = $_.Exception.Message
  Write-LogLine $errors "restore:error $msg"
  Write-Error $msg
  exit 1
}
