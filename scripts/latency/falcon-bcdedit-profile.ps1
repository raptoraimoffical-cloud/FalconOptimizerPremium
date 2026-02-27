param(
  [ValidateSet("backup","restore","applyProfile","clearProfile")][string]$Action = "applyProfile",
  [ValidateSet("fps","latency","balanced","custom")][string]$Profile = "latency"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$bkDir = Join-Path $env:ProgramData "FalconOptimizer\Backups"
New-Item -ItemType Directory -Force -Path $bkDir | Out-Null
$bk = Join-Path $bkDir "bcd-backup.bak"

function Get-Overrides {
  $path = Join-Path $env:ProgramData "FalconOptimizer\latency_overrides.json"
  if (Test-Path -LiteralPath $path) {
    try { return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json) } catch { return $null }
  }
  return $null
}

function BackupBCD {
  bcdedit /export $bk | Out-Null
  Write-Output ("BCDEdit exported to {0}" -f $bk)
}

function RestoreBCD {
  if (-not (Test-Path -LiteralPath $bk)) { throw "No backup found at $bk" }
  bcdedit /import $bk | Out-Null
  Write-Output ("BCDEdit imported from {0}" -f $bk)
}

# Profiles here apply only the three most common knobs used in these packs.
# disabledynamictick: yes/no
# useplatformtick: yes/no
# useplatformclock: yes/no
$profiles = @{
  latency  = @{ disabledynamictick="yes"; useplatformtick="yes"; useplatformclock="no" }
  balanced = @{ disabledynamictick="yes"; useplatformtick="no";  useplatformclock="no" }
  fps      = @{ disabledynamictick="no";  useplatformtick="no";  useplatformclock="no" }
}

function ApplyKV($k,$v){
  if ($v -eq "no") {
    bcdedit /deletevalue {current} $k | Out-Null
  } else {
    bcdedit /set {current} $k $v | Out-Null
  }
}

if ($Action -eq "backup") { BackupBCD; exit 0 }
if ($Action -eq "restore") { RestoreBCD; exit 0 }

$cfg = $null
if ($Profile -eq "custom") {
  $ov = Get-Overrides
  if ($null -eq $ov -or $null -eq $ov.bcdedit) {
    # Auto-initialize missing bcdedit overrides (default: latency)
    $dir = Join-Path $env:ProgramData "FalconOptimizer"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $fn = Join-Path $dir "latency_overrides.json"
    if (!(Test-Path -LiteralPath $fn)) {
@'
{
  "scheduler": { "Win32PrioritySeparation": "0x26" },
  "timer": { "resolution_us": 5000 },
  "bcdedit": { "disabledynamictick": "yes", "useplatformtick": "yes", "useplatformclock": "no" }
}
'@ | Out-File -LiteralPath $fn -Encoding utf8
    }
    $ov = Get-Overrides
  }
  $cfg = @{
    disabledynamictick = [string]$ov.bcdedit.disabledynamictick
    useplatformtick    = [string]$ov.bcdedit.useplatformtick
    useplatformclock   = [string]$ov.bcdedit.useplatformclock
  }
} else {
  $cfg = $profiles[$Profile]
}

if ($Action -eq "applyProfile") {
  BackupBCD
  ApplyKV "disabledynamictick" $cfg.disabledynamictick
  ApplyKV "useplatformtick"    $cfg.useplatformtick
  ApplyKV "useplatformclock"   $cfg.useplatformclock
  Write-Output ("Applied BCDEdit profile: {0}. Reboot required." -f $Profile)
  exit 0
}

if ($Action -eq "clearProfile") {
  BackupBCD
  bcdedit /deletevalue {current} disabledynamictick | Out-Null
  bcdedit /deletevalue {current} useplatformtick | Out-Null
  bcdedit /deletevalue {current} useplatformclock | Out-Null
  Write-Output "Cleared BCDEdit flags (deleted values). Reboot required."
  exit 0
}
