param(
  [ValidateSet("status","start","stop","installTask","removeTask")][string]$Action = "status",
  [ValidateSet("fps","latency","balanced","custom")][string]$Profile = "latency"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$tc = Join-Path $root "scripts\timer-control.ps1"

# microseconds
$map = @{
  latency  = 5000   # 0.5ms
  balanced = 5040   # 0.504ms
  fps      = 5070   # 0.507ms
}

function Get-Overrides {
  $path = Join-Path $env:ProgramData "FalconOptimizer\latency_overrides.json"
  if (Test-Path -LiteralPath $path) {
    try { return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json) } catch { return $null }
  }
  return $null
}

[int]$res = 5000
if ($Profile -eq "custom") {
  $ov = Get-Overrides
  if ($null -eq $ov -or $null -eq $ov.timer -or $null -eq $ov.timer.resolution_us) {
    # Auto-initialize to a safe default instead of failing.
    $dir = Join-Path $env:ProgramData "FalconOptimizer"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $fn = Join-Path $dir "latency_overrides.json"
    $payload = @'
{
  "scheduler": {
    "Win32PrioritySeparation": "0x26"
  },
  "timer": {
    "resolution_us": 5000
  },
  "bcdedit": {
    "disabledynamictick": "yes",
    "useplatformtick": "yes",
    "useplatformclock": "no"
  }
}
'@
    if (-not (Test-Path -LiteralPath $fn)) {
      $payload | Out-File -LiteralPath $fn -Encoding utf8
    }
    $res = 5000
  } else {
    $res = [int]$ov.timer.resolution_us
  }
} else {
  $res = $map[$Profile]
}

powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tc -Action $Action -Resolution $res
