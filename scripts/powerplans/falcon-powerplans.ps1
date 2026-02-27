param(
  [Parameter(Mandatory=$true)]
  [ValidateSet(
    "install_all",
    "apply_extreme",
    "apply_sustain",
    "apply_competitive",
    "apply_balanced",
    "apply_laptop",
    "apply_windows_balanced",
    "apply_windows_high",
    "apply_windows_ultimate",
    "restore_previous",
    "list"
  )]
  [string]$Action,
  [Parameter(Mandatory=$false)][string]$DataPath = "C:\ProgramData\FalconOptimizer\powerplans_state.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p) {
  $d = Split-Path -Parent $p
  if ($d -and !(Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Get-ActivePlanGuid() {
  $out = powercfg /GETACTIVESCHEME 2>$null
  if ($out -match 'GUID:\s*([0-9a-fA-F-]{36})') { return $Matches[1] }
  if ($out -match 'Power Scheme GUID:\s*([0-9a-fA-F-]{36})') { return $Matches[1] }
  return $null
}

function Save-State([hashtable]$extra=$null) {
  Ensure-Dir $DataPath
  $state = @{
    savedAt = (Get-Date).ToString("s")
    previousActiveGuid = (Get-ActivePlanGuid)
    plans = $script:PlanGuids
  }
  if ($extra) {
    foreach ($k in $extra.Keys) { $state[$k] = $extra[$k] }
  }
  $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $DataPath -Encoding UTF8
}

function Load-State() {
  if (Test-Path -LiteralPath $DataPath) {
    try { return (Get-Content -LiteralPath $DataPath -Raw | ConvertFrom-Json) } catch { return $null }
  }
  return $null
}

function Duplicate-Plan([string]$baseGuid) {
  $out = powercfg /DUPLICATESCHEME $baseGuid 2>$null
  if ($out -match '([0-9a-fA-F-]{36})') { return $Matches[1] }
  return $null
}

function Rename-Plan([string]$guid, [string]$name) {
  powercfg /CHANGENAME $guid $name | Out-Null
}

function Find-PlanByName([string]$name) {
  $list = powercfg /LIST 2>$null
  foreach ($line in $list) {
    if ($line -match '([0-9a-fA-F-]{36}).*\((.+)\)') {
      $g = $Matches[1]; $n = $Matches[2]
      if ($n -eq $name) { return $g }
    }
  }
  return $null
}

function Try-SetValue([string]$guid, [string]$sub, [string]$setting, [int]$ac, [int]$dc=$ac) {
  try { powercfg /SETACVALUEINDEX $guid $sub $setting $ac | Out-Null } catch {}
  try { powercfg /SETDCVALUEINDEX $guid $sub $setting $dc | Out-Null } catch {}
}

function Try-Unhide([string]$sub, [string]$setting) {
  try { powercfg -attributes $sub $setting -ATTRIB_HIDE | Out-Null } catch {}
}

# Base schemes
$GUID_BALANCED = "381b4222-f694-41f0-9685-ff5bb260df2e"
$GUID_HIGH     = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$GUID_ULT      = "e9a42b02-d5df-448d-aa00-03f14749eb61" # Ultimate Performance

# Subgroups / settings
$SUB_PROCESSOR = "54533251-82be-4824-96c1-47b60b740d00"
$SUB_PCIEXP    = "501a4d13-42af-4429-9fd1-a8218c268e20"
$SUB_USB       = "2a737441-1930-4402-8d77-b2bebba308a3"
$SUB_SLEEP     = "238c9fa8-0aad-41ed-83f4-97be242c8f20"

$PROC_MIN      = "893dee8e-2bef-41e0-89c6-b55d0929964c"
$PROC_MAX      = "bc5038f7-23e0-4960-96da-33abaf5935ec"
$BOOST_MODE    = "be337238-0d82-4146-a960-4f3749d470c7" # 0=Disabled,1=EfficientAggressive,2=Aggressive
$COOLING_POL   = "94d3a615-a899-4ac5-ae2b-e4d8f634367f" # 0=Passive 1=Active
$IDLE_DISABLE  = "5d76a2ca-e8c0-402f-a133-2158492d58ad" # if supported
$CPMINCORES    = "0cc5b647-c1df-4637-891a-dec35c318583" # core parking min cores
$CPMAXCORES    = "ea062031-0e34-4ff1-9b6d-eb1059334028" # core parking max cores

$PCI_LSPM      = "ee12f906-d277-404b-b6da-e5fa1a576df5" # Link State Power Management (0=Off)
$USB_SUSPEND   = "a7066653-8d6c-40a8-910e-a1f54b84c7e5" # USB selective suspend (0=Disabled)
$SLEEP_IDLE    = "29f6c1db-86da-48c5-9fdb-f2b67b1f44da" # Sleep after (seconds)
$HIBERNATE     = "9d7815a6-7ee4-497e-8888-515a05f02364" # Hibernate after (seconds)

# Unhide commonly-needed settings
Try-Unhide $SUB_PROCESSOR $BOOST_MODE
Try-Unhide $SUB_PROCESSOR $CPMINCORES
Try-Unhide $SUB_PROCESSOR $CPMAXCORES
Try-Unhide $SUB_USB $USB_SUSPEND
Try-Unhide $SUB_PCIEXP $PCI_LSPM

# CPU awareness: Intel hybrid likes EfficientAggressive on balanced/competitive; extreme uses Aggressive.
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 Name
$cpuName = ""
if ($cpu -and $cpu.Name) { $cpuName = [string]$cpu.Name }

function Is-IntelHybrid([string]$n) {
  if (-not $n) { return $false }
  if ($n -match 'i[3579]-1[2-9]\d\d\d' -or $n -match 'i[3579]-1[2-9]\d\d\d[KF]?' ) { return $true }
  if ($n -match 'Core\(TM\)\s+i' -and $n -match '12th|13th|14th') { return $true }
  return $false
}

$intelHybrid = Is-IntelHybrid $cpuName

$names = @{
  extreme      = "Falcon Max FPS (Extreme)"
  sustain      = "Falcon Sustained Boost"
  competitive  = "Falcon Competitive (Low Latency)"
  balanced     = "Falcon Balanced Performance"
  laptop       = "Falcon Laptop Gaming"
}

$script:PlanGuids = @{
  extreme     = (Find-PlanByName $names.extreme)
  sustain     = (Find-PlanByName $names.sustain)
  competitive = (Find-PlanByName $names.competitive)
  balanced    = (Find-PlanByName $names.balanced)
  laptop      = (Find-PlanByName $names.laptop)
}

function Ensure-Plan([string]$key, [string]$baseGuid) {
  if (-not $script:PlanGuids[$key]) {
    $dup = Duplicate-Plan $baseGuid
    if (-not $dup) {
      # fallback to High if Ultimate missing
      $dup = Duplicate-Plan $GUID_HIGH
    }
    if (-not $dup) { throw "Failed duplicating base power plan for $key." }
    Rename-Plan $dup $names[$key]
    $script:PlanGuids[$key] = $dup
  }
}

function Apply-CommonLatency([string]$guid) {
  # Disable PCIe/USB power savings for latency
  Try-SetValue $guid $SUB_PCIEXP $PCI_LSPM 0
  Try-SetValue $guid $SUB_USB $USB_SUSPEND 0
}

function Apply-Extreme([string]$guid) {
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MIN 100
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MAX 100
  Try-SetValue $guid $SUB_PROCESSOR $BOOST_MODE 2
  Try-SetValue $guid $SUB_PROCESSOR $COOLING_POL 1
  Try-SetValue $guid $SUB_PROCESSOR $CPMINCORES 100
  Try-SetValue $guid $SUB_PROCESSOR $CPMAXCORES 100
  try { Try-SetValue $guid $SUB_PROCESSOR $IDLE_DISABLE 1 } catch {}
  Apply-CommonLatency $guid
  Try-SetValue $guid $SUB_SLEEP $SLEEP_IDLE 0
  Try-SetValue $guid $SUB_SLEEP $HIBERNATE 0
  powercfg /SETACTIVE $guid | Out-Null
}

function Apply-Sustain([string]$guid) {
  # Sustained boost: high min state but not necessarily full idle-disable
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MIN 100
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MAX 100
  Try-SetValue $guid $SUB_PROCESSOR $BOOST_MODE 2
  Try-SetValue $guid $SUB_PROCESSOR $COOLING_POL 1
  Try-SetValue $guid $SUB_PROCESSOR $CPMINCORES 100
  Try-SetValue $guid $SUB_PROCESSOR $CPMAXCORES 100
  Apply-CommonLatency $guid
  powercfg /SETACTIVE $guid | Out-Null
}

function Apply-Competitive([string]$guid) {
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MIN 100
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MAX 100
  $boost = 2
  if ($intelHybrid) { $boost = 1 } # often smoother on hybrid for background tasks
  Try-SetValue $guid $SUB_PROCESSOR $BOOST_MODE $boost
  Try-SetValue $guid $SUB_PROCESSOR $COOLING_POL 1
  Try-SetValue $guid $SUB_PROCESSOR $CPMINCORES 100
  Try-SetValue $guid $SUB_PROCESSOR $CPMAXCORES 100
  Apply-CommonLatency $guid
  powercfg /SETACTIVE $guid | Out-Null
}

function Apply-Balanced([string]$guid) {
  # A real balanced gaming plan: keep boost but allow idle
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MIN 5 5
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MAX 100 100
  $boost = 1
  if (-not $intelHybrid) { $boost = 1 } # efficient aggressive
  Try-SetValue $guid $SUB_PROCESSOR $BOOST_MODE $boost
  Try-SetValue $guid $SUB_PROCESSOR $COOLING_POL 1
  # light parking (not fully disabled) - if supported
  Try-SetValue $guid $SUB_PROCESSOR $CPMINCORES 50 50
  Try-SetValue $guid $SUB_PROCESSOR $CPMAXCORES 100 100
  # keep PCIe off for gaming consistency but allow USB suspend on battery
  Try-SetValue $guid $SUB_PCIEXP $PCI_LSPM 0 1
  Try-SetValue $guid $SUB_USB $USB_SUSPEND 0 1
  powercfg /SETACTIVE $guid | Out-Null
}

function Apply-Laptop([string]$guid) {
  # AC: strong perf; DC: cap max to save heat/battery
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MIN 100 5
  Try-SetValue $guid $SUB_PROCESSOR $PROC_MAX 100 90
  Try-SetValue $guid $SUB_PROCESSOR $BOOST_MODE 1 1
  Try-SetValue $guid $SUB_PROCESSOR $COOLING_POL 1 1
  Try-SetValue $guid $SUB_PCIEXP $PCI_LSPM 0 2
  Try-SetValue $guid $SUB_USB $USB_SUSPEND 0 1
  powercfg /SETACTIVE $guid | Out-Null
}

if ($Action -eq "install_all") {
  Ensure-Plan "extreme" $GUID_ULT
  Ensure-Plan "sustain" $GUID_ULT
  Ensure-Plan "competitive" $GUID_HIGH
  Ensure-Plan "balanced" $GUID_BALANCED
  Ensure-Plan "laptop" $GUID_HIGH
  Save-State @{ cpuName=$cpuName; intelHybrid=$intelHybrid }
  "OK: Installed Falcon power plans: $($script:PlanGuids | ConvertTo-Json -Compress)" | Write-Output
  exit 0
}

if ($Action -eq "list") {
  "CPU=$cpuName IntelHybrid=$intelHybrid Active=$(Get-ActivePlanGuid) Plans=$($script:PlanGuids | ConvertTo-Json -Compress)" | Write-Output
  exit 0
}

# ensure installed before apply
if (-not $script:PlanGuids.extreme -or -not $script:PlanGuids.competitive) {
  & $PSCommandPath -Action install_all -DataPath $DataPath | Out-Null
  $script:PlanGuids.extreme     = Find-PlanByName $names.extreme
  $script:PlanGuids.sustain     = Find-PlanByName $names.sustain
  $script:PlanGuids.competitive = Find-PlanByName $names.competitive
  $script:PlanGuids.balanced    = Find-PlanByName $names.balanced
  $script:PlanGuids.laptop      = Find-PlanByName $names.laptop
}

if ($Action -like "apply_*") {
  Save-State
}

switch ($Action) {
  "apply_extreme" { Apply-Extreme $script:PlanGuids.extreme; "OK: Applied $($names.extreme)" | Write-Output; break }
  "apply_sustain" { Apply-Sustain $script:PlanGuids.sustain; "OK: Applied $($names.sustain)" | Write-Output; break }
  "apply_competitive" { Apply-Competitive $script:PlanGuids.competitive; "OK: Applied $($names.competitive)" | Write-Output; break }
  "apply_balanced" { Apply-Balanced $script:PlanGuids.balanced; "OK: Applied $($names.balanced)" | Write-Output; break }
  "apply_laptop" { Apply-Laptop $script:PlanGuids.laptop; "OK: Applied $($names.laptop)" | Write-Output; break }
  "apply_windows_balanced" { powercfg /SETACTIVE $GUID_BALANCED | Out-Null; "OK: Applied Windows Balanced" | Write-Output; break }
  "apply_windows_high" { powercfg /SETACTIVE $GUID_HIGH | Out-Null; "OK: Applied Windows High Performance" | Write-Output; break }
  "apply_windows_ultimate" { 
      # ensure ultimate exists; if not, create by duplicating the GUID itself
      $ult = $GUID_ULT
      # Attempt to set active; on some SKUs it may not exist
      try { powercfg /SETACTIVE $ult | Out-Null; "OK: Applied Windows Ultimate Performance" | Write-Output; break }
      catch {
        # try to duplicate ultimate (will fail if not available)
        try { $dup = Duplicate-Plan $GUID_ULT; if ($dup) { powercfg /SETACTIVE $dup | Out-Null; "OK: Installed + Applied Ultimate Performance clone ($dup)" | Write-Output; break } } catch {}
        throw "Ultimate Performance not available on this Windows edition."
      }
  }
  "restore_previous" {
    $st = Load-State
    if ($st -and $st.previousActiveGuid) {
      powercfg /SETACTIVE $st.previousActiveGuid | Out-Null
      "OK: Restored previous power plan $($st.previousActiveGuid)" | Write-Output
      break
    }
    throw "No previous power plan stored."
  }
  default { throw "Unknown action $Action" }
}
