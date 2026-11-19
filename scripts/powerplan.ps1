<#
  Builds and activates Falcon power plans.

    -Plan latency   High Performance base, no parking, C-states OFF (desktop), max boost
    -Plan fps       High Performance base, no parking, C-states ON (boost headroom)
    -Plan x3d       Balanced base (keeps AMD V-Cache core parking), device power settings only
    -Plan restore   Re-activates the plan that was active before Falcon, removes Falcon plans
    -AcOnly            Only change "plugged in" values (laptops)
    -Check             Print true/false: is this profile currently active?
#>
param(
  [Parameter(Mandatory = $true)][ValidateSet('latency', 'fps', 'x3d', 'restore')][string]$Plan,
  [switch]$AcOnly,
  [switch]$Check
)
# Cmdlets fail hard; native tools (powercfg/bcdedit/sc) report via $LASTEXITCODE.
# (With 'Stop', PS 5.1 turns any redirected native stderr line into a terminating error.)
$ErrorActionPreference = 'Continue'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$BALANCED = '381b4222-f694-41f0-9685-ff5bb260df2e'
$HIGHPERF = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
$Names = @{ latency = 'Falcon Latency'; fps = 'Falcon FPS'; x3d = 'Falcon X3D' }

$StateDir = Join-Path $env:ProgramData 'FalconOptimizer'
$StatePath = Join-Path $StateDir 'powerplan.json'
if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }

function Get-State {
  $s = @{ previous = $null; plans = @{} }
  if (Test-Path -LiteralPath $StatePath) {
    try {
      $j = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
      $s.previous = $j.previous
      if ($j.plans) { foreach ($p in $j.plans.PSObject.Properties) { $s.plans[$p.Name] = [string]$p.Value } }
    } catch {}
  }
  return $s
}
function Save-State($s) { $s | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $StatePath -Encoding UTF8 }
function Get-Active { $o = (& powercfg.exe /getactivescheme) | Out-String; if ($o -match '([0-9a-fA-F-]{36})') { return $Matches[1].ToLowerInvariant() }; return $null }
function Test-Scheme([string]$g) { if (-not $g) { return $false }; & powercfg.exe /query $g *> $null; return ($LASTEXITCODE -eq 0) }

$state = Get-State
$active = Get-Active
$falconGuids = @($state.plans.Values | ForEach-Object { $_.ToLowerInvariant() })

if ($Check) {
  if ($Plan -eq 'restore') { if ($falconGuids -contains $active) { 'false' } else { 'true' } }
  else { $g = $state.plans[$Plan]; if ($g -and $active -eq $g.ToLowerInvariant()) { 'true' } else { 'false' } }
  exit 0
}

function Remove-FalconPlan([string]$g) {
  if (-not (Test-Scheme $g)) { return }
  if ((Get-Active) -eq $g.ToLowerInvariant()) { & powercfg.exe /setactive $BALANCED | Out-Null }
  & powercfg.exe /delete $g | Out-Null
}

if ($Plan -eq 'restore') {
  $target = $state.previous
  if (-not (Test-Scheme $target) -or ($falconGuids -contains ([string]$target).ToLowerInvariant())) { $target = $BALANCED }
  & powercfg.exe /setactive $target | Out-Null
  foreach ($g in @($state.plans.Values)) { Remove-FalconPlan $g }
  $state.plans = @{}
  Save-State $state
  "Activated previous power plan ($target) and removed Falcon plans."
  exit 0
}

# Remember the user's own plan the first time we switch away from it.
if ($active -and -not ($falconGuids -contains $active)) { $state.previous = $active }

# Rebuild this profile's plan from scratch so settings are always current.
if ($state.plans[$Plan]) { Remove-FalconPlan $state.plans[$Plan] }

$base = $(if ($Plan -eq 'x3d') { $BALANCED } else { $HIGHPERF })
$dup = (& powercfg.exe /duplicatescheme $base 2>$null) | Out-String
if ($dup -notmatch '([0-9a-fA-F-]{36})') {
  # Modern Standby systems hide High Performance; fall back to Balanced and set everything explicitly.
  $dup = (& powercfg.exe /duplicatescheme $BALANCED) | Out-String
  if ($dup -notmatch '([0-9a-fA-F-]{36})') { throw "powercfg /duplicatescheme failed: $dup" }
}
$schemeGuid = $Matches[1]
& powercfg.exe /changename $schemeGuid $Names[$Plan] "Built by Falcon Optimizer ($Plan profile)." | Out-Null

$applied = 0
function Set-Plan([string]$sub, [string]$setting, [int]$value) {
  & powercfg.exe /setacvalueindex $schemeGuid $sub $setting $value 2>$null | Out-Null
  $ok = ($LASTEXITCODE -eq 0)
  if (-not $AcOnly) { & powercfg.exe /setdcvalueindex $schemeGuid $sub $setting $value 2>$null | Out-Null }
  if ($ok) { $script:applied++ }
}

$PROC = '54533251-82be-4824-96c1-47b60b740d00'

# Device power: identical for every profile.
Set-Plan '2a737441-1930-4402-8d77-b2bebba308a3' '48e6b7a6-50f5-4782-a5d4-53bb8f07e226' 0   # USB selective suspend: off
Set-Plan '501a4d13-42af-4429-9fd1-a8218c268e20' 'ee12f906-d277-404b-b6da-e5fa1a576df5' 0   # PCIe link state power management: off
Set-Plan '0012ee47-9041-4b5d-9b77-535fba8b1442' '6738e2c4-e8a5-4a42-b16a-e040e769756e' 0   # Turn off hard disk: never
Set-Plan '0012ee47-9041-4b5d-9b77-535fba8b1442' '0b2d69d7-a2a1-449c-9680-f91c70521c60' 0   # AHCI link power management: active
Set-Plan '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1' '12bbebe6-58d6-4636-95bb-3217ef867c1a' 0   # Wireless adapter: maximum performance

if ($Plan -ne 'x3d') {
  Set-Plan $PROC '893dee8e-2bef-41e0-89c6-b55d0929964c' 100   # Minimum processor state
  Set-Plan $PROC 'bc5038f7-23e0-4960-96da-33abaf5935ec' 100   # Maximum processor state
  Set-Plan $PROC '0cc5b647-c1df-4637-891a-dec35c318583' 100   # Core parking min cores (no parking)
  Set-Plan $PROC '0cc5b647-c1df-4637-891a-dec35c318584' 100   # ...for efficiency class 1 (hybrid CPUs)
  Set-Plan $PROC 'ea062031-0e34-4ff1-9b6d-eb1059334028' 100   # Core parking max cores
  Set-Plan $PROC 'be337238-0d82-4146-a960-4f3749d470c7' 2     # Performance boost mode: aggressive
  Set-Plan $PROC '36687f9e-e3a5-4dbf-b1dc-15eb381c6863' 0     # Energy performance preference: max performance
  Set-Plan $PROC '36687f9e-e3a5-4dbf-b1dc-15eb381c6864' 0     # ...for efficiency class 1

  $isLaptop = $AcOnly.IsPresent
  $idleDisable = $(if ($Plan -eq 'latency' -and -not $isLaptop) { 1 } else { 0 })
  Set-Plan $PROC '5d76a2ca-e8c0-402f-a133-2158492d58ad' $idleDisable   # Processor idle disable (C-states)
}

& powercfg.exe /setactive $schemeGuid | Out-Null
$state.plans[$Plan] = $schemeGuid
Save-State $state
"Activated '$($Names[$Plan])' ($schemeGuid), $applied settings applied."
