param(
  [ValidateSet("falcon","fps","latency","balanced","custom")][string]$Profile = "falcon"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pc = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
$valName = "Win32PrioritySeparation"

# Defaults: Falcon=0x26, FPS=0x2A, Latency=0x24, Balanced=0x1A
$map = @{
  falcon   = 0x26
  fps      = 0x2A
  latency  = 0x24
  balanced = 0x1A
}

function Get-Overrides {
  $path = Join-Path $env:ProgramData "FalconOptimizer\latency_overrides.json"
  if (Test-Path -LiteralPath $path) {
    try { return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json) } catch { return $null }
  }
  return $null
}

[int]$value = 0
if ($Profile -eq "custom") {
  $ov = Get-Overrides
  if ($null -eq $ov -or $null -eq $ov.scheduler -or $null -eq $ov.scheduler.Win32PrioritySeparation) {
    throw "Custom scheduler value missing. Set ProgramData\FalconOptimizer\latency_overrides.json -> scheduler.Win32PrioritySeparation (decimal or hex string like 0x26)."
  }
  $raw = $ov.scheduler.Win32PrioritySeparation
  if ($raw -is [string] -and $raw.Trim().StartsWith("0x")) {
    $value = [Convert]::ToInt32($raw.Trim().Substring(2),16)
  } else {
    $value = [int]$raw
  }
} else {
  $value = $map[$Profile]
}

New-Item -Path $pc -Force | Out-Null
Set-ItemProperty -Path $pc -Name $valName -Type DWord -Value $value
Write-Output ("Set {0}\{1} = 0x{2:X}" -f $pc,$valName,$value)
