<#
  Falcon Optimizer engine (v2)

  One PowerShell process per request. Reads a JSON request, writes a JSON result.

  Request:
    {
      "mode": "apply" | "revert" | "detect",
      "dryRun": false,
      "items": [ { "id": "...", "apply": [steps], "revert": [steps] } ]
    }

  Step types (kept deliberately small):
    reg        { path, name, regType: DWORD|QWORD|SZ|EXPAND_SZ|MULTI_SZ|BINARY, value } set a value
               { path, name, delete: true }                                             remove a value
    service    { name, start: Disabled|Manual|Automatic|AutomaticDelayed }
    task       { path: "\Folder\TaskName", state: Disabled|Enabled }
    bcd        { name, value } | { name, delete: true }
    powercfg   { sub, setting, value, scope: both|ac|dc }   (active scheme)
    netadapter { keyword, value }                           (all physical adapters exposing the keyword)
    ps         { script, check? }                           (custom; check prints true/false/na)

  Detect states: applied | not_applied | partial | na (target absent on this PC) | unknown
  (cannot be read, e.g. bcdedit without admin, or a one-shot script without a check).

  Journal: the first time Falcon changes a value, the original is saved to
  %ProgramData%\FalconOptimizer\journal.json. Revert restores the exact original
  when available, and falls back to the item's explicit revert steps otherwise.
#>
param(
  [Parameter(Mandatory = $true)][string]$RequestFile,
  [Parameter(Mandatory = $true)][string]$ResultFile
)

# Cmdlets fail hard; native tools (powercfg/bcdedit/sc) report via $LASTEXITCODE.
# (With 'Stop', PS 5.1 turns any redirected native stderr line into a terminating error.)
$ErrorActionPreference = 'Continue'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
Set-StrictMode -Version 2.0

# Exposed to catalog `ps` steps: $FalconRoot (app root containing scripts\) and $DataRoot.
$FalconRoot = Split-Path -Parent $PSScriptRoot
$DataRoot = Join-Path $env:ProgramData 'FalconOptimizer'
$JournalPath = Join-Path $DataRoot 'journal.json'
$LogDir = Join-Path $DataRoot 'logs'
foreach ($d in @($DataRoot, $LogDir)) { if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }
$LogFile = Join-Path $LogDir ("engine-{0}.log" -f (Get-Date -Format 'yyyyMMdd'))

function Write-Log([string]$msg) {
  try { Add-Content -LiteralPath $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg) -Encoding UTF8 } catch {}
}

function Test-Admin {
  try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { return $false }
}

function Has([object]$o, [string]$name) {
  return ($null -ne $o) -and ($o.PSObject.Properties.Name -contains $name)
}

# ---------------------------------------------------------------- journal
$script:Journal = @{}
$script:JournalDirty = $false
if (Test-Path -LiteralPath $JournalPath) {
  try {
    $raw = Get-Content -LiteralPath $JournalPath -Raw -Encoding UTF8
    if ($raw) {
      $obj = $raw | ConvertFrom-Json
      foreach ($p in $obj.PSObject.Properties) { $script:Journal[$p.Name] = $p.Value }
    }
  } catch { Write-Log ("journal unreadable, starting fresh: " + $_.Exception.Message) }
}
function Save-Journal {
  if (-not $script:JournalDirty) { return }
  $ordered = New-Object PSObject
  foreach ($k in ($script:Journal.Keys | Sort-Object)) { $ordered | Add-Member -NotePropertyName $k -NotePropertyValue $script:Journal[$k] }
  $ordered | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $JournalPath -Encoding UTF8
}
function Remember([string]$key, [object]$original) {
  if (-not $script:Journal.ContainsKey($key)) {
    $script:Journal[$key] = $original
    $script:JournalDirty = $true
  }
}
function Forget([string]$key) {
  if ($script:Journal.ContainsKey($key)) { $script:Journal.Remove($key); $script:JournalDirty = $true }
}

# ---------------------------------------------------------------- registry
function Convert-RegPath([string]$p) {
  $p = $p.Trim()
  $p = $p -replace '^(HKEY_LOCAL_MACHINE|HKLM:?)\\', 'HKLM:\'
  $p = $p -replace '^(HKEY_CURRENT_USER|HKCU:?)\\', 'HKCU:\'
  $p = $p -replace '^(HKEY_CLASSES_ROOT|HKCR:?)\\', 'Registry::HKEY_CLASSES_ROOT\'
  $p = $p -replace '^(HKEY_USERS|HKU:?)\\', 'Registry::HKEY_USERS\'
  return $p
}
$RegKinds = @{ DWORD = 'DWord'; QWORD = 'QWord'; SZ = 'String'; EXPAND_SZ = 'ExpandString'; MULTI_SZ = 'MultiString'; BINARY = 'Binary' }

function Convert-RegValue([string]$type, [object]$value) {
  switch ($type.ToUpperInvariant()) {
    'DWORD' {
      if ("$value" -match '^0x') { $u = [Convert]::ToUInt32("$value".Substring(2), 16) } else { $u = [uint32]([int64]"$value" -band 0xFFFFFFFFL) }
      return [BitConverter]::ToInt32([BitConverter]::GetBytes($u), 0)
    }
    'QWORD' {
      if ("$value" -match '^0x') { $u = [Convert]::ToUInt64("$value".Substring(2), 16) } else { $u = [uint64]"$value" }
      return [BitConverter]::ToInt64([BitConverter]::GetBytes($u), 0)
    }
    'BINARY' {
      $hex = ("$value" -replace '[^0-9A-Fa-f]', '')
      $b = New-Object byte[] ($hex.Length / 2)
      for ($i = 0; $i -lt $b.Length; $i++) { $b[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16) }
      return , $b
    }
    'MULTI_SZ' { return , ([string[]]@($value)) }
    default { return [string]$value }
  }
}

function Get-RegState([string]$path, [string]$name) {
  $p = Convert-RegPath $path
  try {
    $key = Get-Item -LiteralPath $p -ErrorAction Stop
    $names = $key.GetValueNames()
    if ($names -notcontains $name) { return @{ exists = $false } }
    $kind = $key.GetValueKind($name).ToString()
    $val = $key.GetValue($name, $null, 'DoNotExpandEnvironmentNames')
    if ($val -is [byte[]]) { $val = ($val | ForEach-Object { $_.ToString('X2') }) -join '' }
    return @{ exists = $true; kind = $kind; value = $val }
  } catch { return @{ exists = $false } }
}

function Format-RegCompare([object]$v) {
  if ($null -eq $v) { return '' }
  if ($v -is [array]) { return ($v -join "`n") }
  return [string]$v
}

function Test-RegStep($s) {
  $st = Get-RegState $s.path $s.name
  if ((Has $s 'delete') -and $s.delete) { return (-not $st.exists) }
  if (-not $st.exists) { return $false }
  $want = Convert-RegValue $s.regType $s.value
  if ($s.regType -match '^(DWORD|QWORD)$') { return ([int64]$st.value -eq [int64]$want) }
  if ($s.regType -eq 'BINARY') { $hex = ($want | ForEach-Object { $_.ToString('X2') }) -join ''; return ($st.value -eq $hex) }
  return ((Format-RegCompare $st.value) -eq (Format-RegCompare $want))
}

function Set-RegStep($s, [bool]$journal) {
  $p = Convert-RegPath $s.path
  if ($journal) { Remember "reg|$($s.path)|$($s.name)" (Get-RegState $s.path $s.name) }
  if ((Has $s 'delete') -and $s.delete) {
    if (Test-Path -LiteralPath $p) { Remove-ItemProperty -LiteralPath $p -Name $s.name -ErrorAction SilentlyContinue }
    return
  }
  if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p -Force | Out-Null }
  $kind = $RegKinds[$s.regType.ToUpperInvariant()]
  if (-not $kind) { throw "Unknown registry type '$($s.regType)'" }
  New-ItemProperty -LiteralPath $p -Name $s.name -PropertyType $kind -Value (Convert-RegValue $s.regType $s.value) -Force | Out-Null
}

function Restore-RegOriginal([string]$path, [string]$name, $orig) {
  $p = Convert-RegPath $path
  if (-not $orig.exists) {
    if (Test-Path -LiteralPath $p) { Remove-ItemProperty -LiteralPath $p -Name $name -ErrorAction SilentlyContinue }
    return
  }
  if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p -Force | Out-Null }
  $kind = [string]$orig.kind
  $val = $orig.value
  if ($kind -eq 'Binary') { $val = Convert-RegValue 'BINARY' $val }
  elseif ($kind -eq 'DWord') { $val = [int32]$val }
  elseif ($kind -eq 'QWord') { $val = [int64]$val }
  elseif ($kind -eq 'MultiString') { $val = [string[]]@($val) }
  New-ItemProperty -LiteralPath $p -Name $name -PropertyType $kind -Value $val -Force | Out-Null
}

# ---------------------------------------------------------------- services (one WMI query, cached)
$script:SvcCache = $null
function Get-SvcStart([string]$name) {
  if ($null -eq $script:SvcCache) {
    $script:SvcCache = @{}
    foreach ($x in @(Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue)) { $script:SvcCache[([string]$x.Name).ToLowerInvariant()] = [string]$x.StartMode }
  }
  $key = $name.ToLowerInvariant()
  if (-not $script:SvcCache.ContainsKey($key)) { return $null }
  $mode = $script:SvcCache[$key]
  if ($mode -eq 'Auto') {
    $d = Get-RegState "HKLM\SYSTEM\CurrentControlSet\Services\$name" 'DelayedAutoStart'
    if ($d.exists -and [int]$d.value -eq 1) { return 'AutomaticDelayed' }
    return 'Automatic'
  }
  return $mode
}
function Set-SvcStart([string]$name, [string]$start) {
  $map = @{ Disabled = 'disabled'; Manual = 'demand'; Automatic = 'auto'; AutomaticDelayed = 'delayed-auto' }
  $sc = $map[$start]
  if (-not $sc) { throw "Unknown service start type '$start'" }
  $out = & sc.exe config $name start= $sc 2>&1
  if ($LASTEXITCODE -ne 0) {
    # Some services refuse sc.exe; the registry Start value is authoritative at next boot.
    $reg = @{ Disabled = 4; Manual = 3; Automatic = 2; AutomaticDelayed = 2 }[$start]
    Set-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$name" -Name Start -Value $reg -Type DWord
    if ($start -eq 'AutomaticDelayed') { Set-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$name" -Name DelayedAutoStart -Value 1 -Type DWord }
    Write-Log "sc.exe refused $name ($out); wrote Start=$reg directly"
  }
  if ($start -eq 'Disabled') { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue }
  $script:SvcCache = $null
}

# ---------------------------------------------------------------- tasks (enumerated once, cached)
$script:TaskCache = $null
function Get-TaskObj([string]$path) {
  if ($null -eq $script:TaskCache) {
    $script:TaskCache = @{}
    foreach ($t in @(Get-ScheduledTask -ErrorAction SilentlyContinue)) { $script:TaskCache[([string]$t.TaskPath + [string]$t.TaskName).ToLowerInvariant()] = $t }
  }
  return $script:TaskCache[$path.ToLowerInvariant()]
}
function Set-TaskState($t, [string]$state) {
  if ($state -eq 'Disabled') { $t | Disable-ScheduledTask | Out-Null } else { $t | Enable-ScheduledTask | Out-Null }
  $script:TaskCache = $null
}

# ---------------------------------------------------------------- bcdedit
$script:BcdCache = $null
function Get-Bcd {
  if ($null -ne $script:BcdCache) { return $script:BcdCache }
  $map = @{}
  try {
    $lines = & bcdedit.exe /enum '{current}' 2>$null
    if ($LASTEXITCODE -eq 0) {
      foreach ($l in $lines) { if ($l -match '^(\S+)\s+(.+)$') { $map[$Matches[1].ToLowerInvariant()] = $Matches[2].Trim() } }
      $script:BcdCache = $map
    }
  } catch {}
  return $script:BcdCache
}
function Test-BcdStep($s) {
  $b = Get-Bcd
  if ($null -eq $b) { return 'unknown' }   # bcdedit needs admin
  $k = ([string]$s.name).ToLowerInvariant()
  if ((Has $s 'delete') -and $s.delete) { return (-not $b.ContainsKey($k)) }
  if (-not $b.ContainsKey($k)) { return $false }
  return ($b[$k].ToLowerInvariant() -eq ([string]$s.value).ToLowerInvariant())
}
function Set-BcdStep($s, [bool]$journal) {
  $b = Get-Bcd
  $k = ([string]$s.name).ToLowerInvariant()
  if ($journal -and $null -ne $b) {
    if ($b.ContainsKey($k)) { Remember "bcd|$k" @{ exists = $true; value = $b[$k] } } else { Remember "bcd|$k" @{ exists = $false } }
  }
  if ((Has $s 'delete') -and $s.delete) {
    if ($null -eq $b -or $b.ContainsKey($k)) { & bcdedit.exe /deletevalue '{current}' $s.name 2>&1 | Out-Null }
  } else {
    $o = & bcdedit.exe /set '{current}' $s.name $s.value 2>&1
    if ($LASTEXITCODE -ne 0) { throw "bcdedit /set $($s.name) $($s.value) failed: $o" }
  }
  $script:BcdCache = $null
}

# ---------------------------------------------------------------- powercfg (active scheme)
function Get-ActiveScheme {
  $o = (& powercfg.exe /getactivescheme) 2>$null
  if ("$o" -match '([0-9a-fA-F-]{36})') { return $Matches[1] }
  return $null
}
function Get-PcfgValue([string]$sub, [string]$setting) {
  $q = (& powercfg.exe /query SCHEME_CURRENT $sub $setting 2>$null | Out-String)
  $ac = $null; $dc = $null
  # Index lines are the last two "0x" values in the block; match by position to stay locale-independent.
  $hits = [regex]::Matches($q, ':\s*0x([0-9a-fA-F]{8})\s*$', 'Multiline')
  if ($hits.Count -ge 2) {
    $ac = [Convert]::ToInt64($hits[$hits.Count - 2].Groups[1].Value, 16)
    $dc = [Convert]::ToInt64($hits[$hits.Count - 1].Groups[1].Value, 16)
  }
  return @{ ac = $ac; dc = $dc }
}
function Get-Scope($s) { if (Has $s 'scope') { return [string]$s.scope } ; return 'both' }
function Test-PcfgStep($s) {
  $v = Get-PcfgValue $s.sub $s.setting
  if ($null -eq $v.ac -and $null -eq $v.dc) { return $null }  # setting not present on this system
  $want = [int64]$s.value
  $scope = Get-Scope $s
  $acOk = ($null -eq $v.ac) -or ($v.ac -eq $want)
  $dcOk = ($null -eq $v.dc) -or ($v.dc -eq $want)
  if ($scope -eq 'ac') { return $acOk }
  if ($scope -eq 'dc') { return $dcOk }
  return ($acOk -and $dcOk)
}
function Set-PcfgStep($s, [bool]$journal) {
  $scheme = Get-ActiveScheme
  if ($journal) { Remember "pcfg|$scheme|$($s.sub)|$($s.setting)" (Get-PcfgValue $s.sub $s.setting) }
  $scope = Get-Scope $s
  if ($scope -ne 'dc') { & powercfg.exe /setacvalueindex SCHEME_CURRENT $s.sub $s.setting $s.value | Out-Null }
  if ($scope -ne 'ac') { & powercfg.exe /setdcvalueindex SCHEME_CURRENT $s.sub $s.setting $s.value 2>$null | Out-Null }
  & powercfg.exe /setactive SCHEME_CURRENT | Out-Null
}

# ---------------------------------------------------------------- network adapters (cached per adapter)
$script:AdapterCache = $null
$script:AdvPropCache = @{}
$script:AdaptersToRestart = @{}
function Get-PhysAdapters {
  if ($null -eq $script:AdapterCache) {
    $script:AdapterCache = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'Not Present' })
  }
  return $script:AdapterCache
}
function Get-AdapterProps([string]$keyword) {
  $res = @()
  foreach ($a in Get-PhysAdapters) {
    if (-not $script:AdvPropCache.ContainsKey($a.Name)) {
      $script:AdvPropCache[$a.Name] = @(Get-NetAdapterAdvancedProperty -Name $a.Name -AllProperties -ErrorAction SilentlyContinue)
    }
    $p = @($script:AdvPropCache[$a.Name] | Where-Object { $_.RegistryKeyword -eq $keyword }) | Select-Object -First 1
    if ($p) { $res += [pscustomobject]@{ adapter = $a; prop = $p } }
  }
  return $res
}
function Test-NetStep($s) {
  $props = @(Get-AdapterProps $s.keyword)
  if ($props.Count -eq 0) { return $null }
  foreach ($x in $props) { if ([string]($x.prop.RegistryValue | Select-Object -First 1) -ne [string]$s.value) { return $false } }
  return $true
}
function Set-NetStep($s, [bool]$journal) {
  foreach ($x in @(Get-AdapterProps $s.keyword)) {
    $cur = [string]($x.prop.RegistryValue | Select-Object -First 1)
    if ($journal) { Remember "net|$($x.adapter.InterfaceGuid)|$($s.keyword)" @{ value = $cur; adapter = $x.adapter.Name } }
    if ($cur -ne [string]$s.value) {
      Set-NetAdapterAdvancedProperty -Name $x.adapter.Name -RegistryKeyword $s.keyword -RegistryValue ([string]$s.value) -NoRestart -ErrorAction Stop
      $script:AdaptersToRestart[$x.adapter.Name] = $true
      $script:AdvPropCache.Remove($x.adapter.Name)
    }
  }
}

# ---------------------------------------------------------------- generic step dispatch
function Invoke-PsScript([string]$code) {
  # Catalog scripts run without the engine's strict mode.
  $sb = [ScriptBlock]::Create("Set-StrictMode -Off`n" + $code)
  $out = & $sb 2>&1 | Out-String
  return $out.Trim()
}

function Test-Step($s) {
  # $true / $false / $null (target not present on this PC) / 'unknown' (cannot be read)
  switch ([string]$s.type) {
    'reg' { return (Test-RegStep $s) }
    'service' {
      $cur = Get-SvcStart $s.name
      if ($null -eq $cur) { return $null }
      return ($cur -eq [string]$s.start)
    }
    'task' {
      $t = Get-TaskObj $s.path
      if (-not $t) { return $null }
      $isDisabled = ([string]$t.State -eq 'Disabled')
      if ([string]$s.state -eq 'Disabled') { return $isDisabled } else { return (-not $isDisabled) }
    }
    'bcd' { return (Test-BcdStep $s) }
    'powercfg' { return (Test-PcfgStep $s) }
    'netadapter' { return (Test-NetStep $s) }
    'ps' {
      if (-not (Has $s 'check') -or -not $s.check) { return $null }
      try { $r = Invoke-PsScript $s.check } catch { return 'unknown' }
      $last = (($r -split "`r?`n") | Where-Object { $_.Trim() } | Select-Object -Last 1)
      if ($null -eq $last) { return 'unknown' }
      $last = $last.Trim().ToLowerInvariant()
      if ($last -eq 'true') { return $true }
      if ($last -eq 'false') { return $false }
      if ($last -eq 'na') { return $null }
      return 'unknown'
    }
    default { return $null }
  }
}

function Invoke-Step($s, [bool]$journal) {
  switch ([string]$s.type) {
    'reg' { Set-RegStep $s $journal }
    'service' {
      $cur = Get-SvcStart $s.name
      if ($null -eq $cur) { return "skipped: service $($s.name) not installed" }
      if ($journal) { Remember "svc|$($s.name)" @{ start = $cur } }
      Set-SvcStart $s.name $s.start
    }
    'task' {
      $t = Get-TaskObj $s.path
      if (-not $t) { return "skipped: task not present ($($s.path))" }
      if ($journal) { Remember "task|$($s.path)" @{ state = [string]$t.State } }
      Set-TaskState $t ([string]$s.state)
    }
    'bcd' { Set-BcdStep $s $journal }
    'powercfg' { Set-PcfgStep $s $journal }
    'netadapter' { Set-NetStep $s $journal }
    'ps' { return (Invoke-PsScript $s.script) }
    default { throw "Unsupported step type '$($s.type)'" }
  }
  return $null
}

function Get-JournalKeys($s) {
  switch ([string]$s.type) {
    'reg' { return @("reg|$($s.path)|$($s.name)") }
    'service' { return @("svc|$($s.name)") }
    'task' { return @("task|$($s.path)") }
    'bcd' { return @("bcd|$(([string]$s.name).ToLowerInvariant())") }
    'powercfg' { $sc = Get-ActiveScheme; return @("pcfg|$sc|$($s.sub)|$($s.setting)") }
    'netadapter' { return @($script:Journal.Keys | Where-Object { $_ -like "net|*|$($s.keyword)" }) }
    default { return @() }
  }
}

function Restore-FromJournal($s) {
  # Returns $true only if every journal key for this step existed and was restored.
  $keys = @(Get-JournalKeys $s)
  if ($keys.Count -eq 0) { return $false }
  foreach ($k in $keys) { if (-not $script:Journal.ContainsKey($k)) { return $false } }
  foreach ($k in $keys) {
    $o = $script:Journal[$k]
    switch ([string]$s.type) {
      'reg' { Restore-RegOriginal $s.path $s.name $o }
      'service' { Set-SvcStart $s.name ([string]$o.start) }
      'task' { $t = Get-TaskObj $s.path; if ($t) { Set-TaskState $t ([string]$o.state) } }
      'bcd' {
        if ($o.exists) { & bcdedit.exe /set '{current}' $s.name $o.value 2>&1 | Out-Null } else { & bcdedit.exe /deletevalue '{current}' $s.name 2>&1 | Out-Null }
        $script:BcdCache = $null
      }
      'powercfg' {
        if ($null -ne $o.ac) { & powercfg.exe /setacvalueindex SCHEME_CURRENT $s.sub $s.setting $o.ac | Out-Null }
        if ($null -ne $o.dc) { & powercfg.exe /setdcvalueindex SCHEME_CURRENT $s.sub $s.setting $o.dc 2>$null | Out-Null }
        & powercfg.exe /setactive SCHEME_CURRENT | Out-Null
      }
      'netadapter' {
        try {
          Set-NetAdapterAdvancedProperty -Name $o.adapter -RegistryKeyword $s.keyword -RegistryValue ([string]$o.value) -NoRestart -ErrorAction Stop
          $script:AdaptersToRestart[[string]$o.adapter] = $true
        } catch { Write-Log "net restore failed: $($_.Exception.Message)" }
      }
    }
    Forget $k
  }
  return $true
}

# ---------------------------------------------------------------- main
$request = Get-Content -LiteralPath $RequestFile -Raw -Encoding UTF8 | ConvertFrom-Json
$mode = [string]$request.mode
$dryRun = (Has $request 'dryRun') -and [bool]$request.dryRun
$isAdmin = Test-Admin
$results = New-Object System.Collections.Generic.List[object]

Write-Log "---- $mode ($(@($request.items).Count) items) admin=$isAdmin dryRun=$dryRun"

foreach ($item in @($request.items)) {
  $r = [ordered]@{ id = [string]$item.id; ok = $true; state = 'unknown'; messages = @() }
  $applySteps = @(); if (Has $item 'apply') { $applySteps = @($item.apply) }
  $revertSteps = @(); if (Has $item 'revert') { $revertSteps = @($item.revert) }

  try {
    if ($mode -eq 'detect') {
      $t = 0; $f = 0; $u = 0
      foreach ($s in $applySteps) {
        $v = $null
        try { $v = Test-Step $s } catch { $v = 'unknown' }
        if ($v -is [string]) { $u++ } elseif ($v -eq $true) { $t++ } elseif ($v -eq $false) { $f++ }
      }
      if ($t -eq 0 -and $f -eq 0) {
        $hasDetectable = @($applySteps | Where-Object { $_.type -ne 'ps' -or ((Has $_ 'check') -and $_.check) }).Count -gt 0
        $r.state = $(if ($u -gt 0 -or -not $hasDetectable) { 'unknown' } else { 'na' })
      }
      elseif ($f -eq 0) { $r.state = 'applied' }
      elseif ($t -eq 0) { $r.state = 'not_applied' }
      else { $r.state = 'partial' }
    }
    elseif ($mode -eq 'apply') {
      if (-not $isAdmin) { throw 'Administrator rights are required to apply changes.' }
      foreach ($s in $applySteps) {
        if ($dryRun) { $r.messages += "[dry-run] would run $($s.type) step"; continue }
        $m = Invoke-Step $s $true
        if ($m) { $r.messages += [string]$m }
      }
      $r.state = 'applied'
    }
    elseif ($mode -eq 'revert') {
      if (-not $isAdmin) { throw 'Administrator rights are required to revert changes.' }
      if ($dryRun) { $r.messages += '[dry-run] would revert' }
      else {
        $journalable = @($applySteps | Where-Object { $_.type -ne 'ps' })
        $restoredAll = $journalable.Count -gt 0
        foreach ($s in $journalable) { if (-not (Restore-FromJournal $s)) { $restoredAll = $false } }
        if ($restoredAll) {
          $r.messages += 'Restored original values from journal.'
          foreach ($s in @($revertSteps | Where-Object { $_.type -eq 'ps' })) { $m = Invoke-Step $s $false; if ($m) { $r.messages += [string]$m } }
        } else {
          foreach ($s in $revertSteps) { $m = Invoke-Step $s $false; if ($m) { $r.messages += [string]$m } }
          foreach ($s in $applySteps) { foreach ($k in @(Get-JournalKeys $s)) { Forget $k } }
        }
      }
      $r.state = 'not_applied'
    }
    else { throw "Unknown mode '$mode'" }
  } catch {
    $r.ok = $false
    $r.messages += $_.Exception.Message
    Write-Log ("{0} {1} FAILED: {2}" -f $mode, $item.id, $_.Exception.Message)
  }
  if ($mode -ne 'detect') { Write-Log ("{0} {1} ok={2} {3}" -f $mode, $item.id, $r.ok, (($r.messages) -join ' | ')) }
  $results.Add([pscustomobject]$r) | Out-Null
}

foreach ($name in @($script:AdaptersToRestart.Keys)) {
  try { Restart-NetAdapter -Name $name -Confirm:$false -ErrorAction Stop } catch { Write-Log "adapter restart failed for ${name}: $($_.Exception.Message)" }
}

try { Save-Journal } catch { Write-Log ("journal save failed: " + $_.Exception.Message) }

$failed = @($results | Where-Object { -not $_.ok }).Count
$out = [pscustomobject]@{ ok = ($failed -eq 0); admin = $isAdmin; mode = $mode; failed = $failed; items = $results; logFile = $LogFile }
$out | ConvertTo-Json -Depth 6 -Compress | Set-Content -LiteralPath $ResultFile -Encoding UTF8
exit 0
