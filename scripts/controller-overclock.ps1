param(
  [ValidateSet('list','apply','revert','open')]$Action = 'open'
)

$ErrorActionPreference = 'Stop'

function Out-Json([bool]$Ok, [string[]]$Warnings = @(), [string[]]$Errors = @(), [hashtable]$Data = $null) {
  $o = [ordered]@{ ok = $Ok; errors = $Errors; warnings = $Warnings }
  if ($Data) { $o.data = $Data }
  $o | ConvertTo-Json -Compress
}

try {
  $root = Resolve-Path (Join-Path $PSScriptRoot '..')
  $driverCandidates = @(
    (Join-Path $root 'tools\third_party\controller_overclock_ps\DRIVER'),
    (Join-Path $root 'tools\third_party\controller_overclock_ps\controller_overclock_ps\DRIVER')
  )
  $driverDir = $null
  foreach ($candidate in $driverCandidates) {
    if (Test-Path (Join-Path $candidate 'Setup.exe')) {
      $driverDir = $candidate
      break
    }
  }
  $setupExe = if($driverDir){ Join-Path $driverDir 'Setup.exe' } else { $null }

  if (-not $driverDir) {
    Write-Output (Out-Json $false @() @("HidUSBF Setup.exe was not found. Looked in: $($driverCandidates -join '; ')") )
    exit 1
  }

  if (-not (Test-Path $setupExe)) {
    Write-Output (Out-Json $false @() @("Missing HidUSBF Setup.exe at: $setupExe", "Candidates checked: $($driverCandidates -join '; ')") )
    exit 1
  }

  $zoneBlocked = $false
  try {
    $zoneStream = Get-Item -Path $setupExe -Stream Zone.Identifier -ErrorAction Stop
    if ($zoneStream) { $zoneBlocked = $true }
  } catch {
    $zoneBlocked = $false
  }

  if ($Action -eq 'list') {
    # Lightweight enumeration; not all systems will have PnP cmdlets in restricted env.
    $controllers = @()
    try {
      $controllers = Get-PnpDevice -PresentOnly -Class 'HIDClass' | Where-Object {
        $_.FriendlyName -match 'controller|gamepad|xbox|dualshock|dualsense|wireless' 
      } | Select-Object -First 50 -Property FriendlyName, InstanceId
    } catch {
      # ignore
    }
    Write-Output (Out-Json $true @('Controller list is best-effort. If empty, use HidUSBF Setup to select your controller manually.') @() @{ controllers = $controllers })
    exit 0
  }

  # For apply/revert/open we intentionally open HidUSBF Setup.
  # HidUSBF requires selecting the device in its UI and choosing a polling rate.
  # We do not auto-write unknown registry/device values to avoid misconfiguring input devices.
  $warn = @(
    "Selected driver folder: $driverDir",
    "Setup executable: $setupExe"
  )
  if ($zoneBlocked) {
    $warn += 'Setup.exe has a Zone.Identifier mark (downloaded-from-internet). If SmartScreen prompts, click More info -> Run anyway only if you trust this file.'
  }

  Start-Process -FilePath $setupExe -Verb RunAs -WorkingDirectory $driverDir | Out-Null

  $warn += @(
    'HidUSBF Setup opened. In the list, select your controller (DualShock 4 / DualSense recommended).',
    'Check "Filter On Device", then set the polling rate (250/500/1000 Hz) and click "Restart".',
    'Xbox controllers are typically firmware-locked; 1000 Hz may not apply.'
  )

  $warn += "Executable: $setupExe"
  $warn += "Working directory: $driverDir"
  Write-Output (Out-Json $true $warn @())
  exit 0

} catch {
  Write-Output (Out-Json $false @() @($_.Exception.Message))
  exit 1
}
