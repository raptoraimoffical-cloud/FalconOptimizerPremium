param(
  [Parameter(Mandatory=$true)][ValidateSet("apply","restore","open_overrides")]
  [string]$Action,
  [Parameter(Mandatory=$false)][ValidateSet("falcon","fps","latency","balanced","custom")]
  [string]$Profile = "falcon",
  [Parameter(Mandatory=$false)][string]$StatePath = "C:\ProgramData\FalconOptimizer\network_state.json",
  [Parameter(Mandatory=$false)][string]$OverridesPath = "C:\ProgramData\FalconOptimizer\network_overrides.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p) {
  $d = Split-Path -Parent $p
  if ($d -and !(Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Save-State() {
  Ensure-Dir $StatePath
  $tcp = netsh int tcp show global
  $off = netsh int tcp show heuristics
  $state = @{
    savedAt = (Get-Date).ToString("s")
    tcpGlobal = $tcp
    tcpHeuristics = $off
  }
  $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $StatePath -Encoding UTF8
}

function Ensure-Overrides() {
  if (!(Test-Path -LiteralPath $OverridesPath)) {
    Ensure-Dir $OverridesPath
    $tmpl = @{
      profile = "custom"
      tcp = @{
        autotuning = "normal"   # disabled|highlyrestricted|restricted|normal|experimental
        ecn = "disabled"        # enabled|disabled
        timestamps = "disabled" # enabled|disabled
        rss = "enabled"         # enabled|disabled
      }
      notes = "Edit values then re-run apply with Profile=custom."
    }
    $tmpl | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OverridesPath -Encoding UTF8
  }
}

function Apply-Tcp([string]$autotuning,[string]$ecn,[string]$timestamps,[string]$rss) {
  if ($autotuning) { netsh int tcp set global autotuninglevel=$autotuning | Out-Null }
  if ($ecn) { netsh int tcp set global ecncapability=$ecn | Out-Null }
  if ($timestamps) { netsh int tcp set global timestamps=$timestamps | Out-Null }
  if ($rss) { netsh int tcp set global rss=$rss | Out-Null }
}

if ($Action -eq "open_overrides") {
  Ensure-Overrides
  Start-Process notepad.exe $OverridesPath | Out-Null
  "OK: Opened overrides at $OverridesPath" | Write-Output
  exit 0
}

if ($Action -eq "restore") {
  # Best-effort restore to Windows defaults commonly used on modern builds
  Apply-Tcp "normal" "disabled" "disabled" "enabled"
  "OK: Restored network globals to defaults (best-effort)." | Write-Output
  exit 0
}

if ($Action -eq "apply") {
  Save-State
  $aut="normal"; $ecn="disabled"; $ts="disabled"; $rss="enabled"

  switch ($Profile.ToLower()) {
    "falcon"   { $aut="normal"; $ecn="disabled"; $ts="disabled"; $rss="enabled" }
    "fps"      { $aut="normal"; $ecn="disabled"; $ts="disabled"; $rss="enabled" }
    "balanced" { $aut="normal"; $ecn="disabled"; $ts="disabled"; $rss="enabled" }
    "latency"  { $aut="highlyrestricted"; $ecn="disabled"; $ts="disabled"; $rss="enabled" }
    "custom"   {
      Ensure-Overrides
      $cfg = (Get-Content -LiteralPath $OverridesPath -Raw | ConvertFrom-Json)
      if ($cfg.tcp.autotuning) { $aut = [string]$cfg.tcp.autotuning }
      if ($cfg.tcp.ecn) { $ecn = [string]$cfg.tcp.ecn }
      if ($cfg.tcp.timestamps) { $ts = [string]$cfg.tcp.timestamps }
      if ($cfg.tcp.rss) { $rss = [string]$cfg.tcp.rss }
    }
  }

  Apply-Tcp $aut $ecn $ts $rss
  "OK: Applied Network Profile $Profile (autotuning=$aut ecn=$ecn timestamps=$ts rss=$rss)" | Write-Output
  exit 0
}
