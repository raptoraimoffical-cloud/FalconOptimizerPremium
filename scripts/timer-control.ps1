param(
  [ValidateSet("status","start","stop","installTask","removeTask")]
  [string]$Action = "status",
  [int]$Resolution = 5000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $root "scripts\timer-helper.ps1"

function Get-RunningTimerHelper {
  try {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
      Where-Object { $_.CommandLine -like "*timer-helper.ps1*" }
  } catch { @() }
}

if ($Action -eq "status") {
  $p = Get-RunningTimerHelper
  if ($p -and $p.Count -gt 0) {
    Write-Output ("RUNNING|" + ($p[0].ProcessId))
  } else {
    Write-Output "STOPPED|"
  }
  exit 0
}

if ($Action -eq "stop") {
  $p = Get-RunningTimerHelper
  foreach($proc in $p){
    try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
  }
  Write-Output "OK"
  exit 0
}

if ($Action -eq "start") {
  # Stop first to avoid duplicates
  & $PSCommandPath -Action stop | Out-Null
  $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$helper`" -Resolution $Resolution"
  Start-Process -FilePath "powershell.exe" -ArgumentList $arg -WindowStyle Hidden
  Write-Output "OK"
  exit 0
}

$taskName = "FalconTimerResolution"

if ($Action -eq "removeTask") {
  schtasks /Delete /TN $taskName /F | Out-Null
  Write-Output "OK"
  exit 0
}

if ($Action -eq "installTask") {
  # Create a task that starts the helper at logon with highest privileges
  $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$helper`" -Resolution $Resolution"
  schtasks /Create /TN $taskName /SC ONLOGON /RL HIGHEST /TR $cmd /F | Out-Null
  Write-Output "OK"
  exit 0
}
