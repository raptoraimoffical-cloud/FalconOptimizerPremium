param(
  [Parameter(Mandatory=$false)]
  [string]$Json,
  [Parameter(Mandatory=$false)]
  [string]$JsonFile,
  [Parameter(Mandatory=$false)]
  [string]$ResultFile
)

Set-StrictMode -Version Latest

# Ensure Falcon root is set (avoid StrictMode errors)
if (-not (Test-Path variable:Global:FalconRoot)) {
  try {
    $Global:FalconRoot = (Resolve-Path (Join-Path $PSScriptRoot ".." )).Path
  } catch {
    $Global:FalconRoot = $null
  }
}


if([string]::IsNullOrWhiteSpace($Json) -and -not [string]::IsNullOrWhiteSpace($JsonFile)){
  try {
    $Json = Get-Content -LiteralPath $JsonFile -Raw -ErrorAction Stop
  } catch {
    $out = @{ ok = $false; verified = $false; stdout = ""; stderr = ("Failed to read JsonFile: " + $_.Exception.Message); logFile = $null }
    $out | ConvertTo-Json -Depth 8
    exit 1
  }
}

if([string]::IsNullOrWhiteSpace($Json)){
  $out = @{ ok = $false; verified = $false; stdout = ""; stderr = "Missing -Json or -JsonFile payload."; logFile = $null }
  $out | ConvertTo-Json -Depth 8
  exit 1
}
# ---------------- logging ----------------
$script:Falcon_UAC_Previous = $null

$script:Errors   = New-Object System.Collections.Generic.List[string]
$script:Warnings = New-Object System.Collections.Generic.List[string]
$script:LogLines = New-Object System.Collections.Generic.List[string]

$script:StepResults = New-Object System.Collections.Generic.List[object]
function Log([string]$msg) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $script:LogLines.Add("[$ts] $msg") | Out-Null
}

function Add-StepResult($typeOrObject, [string]$label = "", [bool]$ok = $true, $details = $null) {
  try {
    if ($typeOrObject -is [hashtable] -or $typeOrObject -is [pscustomobject]) {
      $obj = [pscustomobject]$typeOrObject
      $script:StepResults.Add($obj) | Out-Null
      return
    }
    $script:StepResults.Add([pscustomobject]@{
      stepIndex = -1
      type = [string]$typeOrObject
      commandSummary = $label
      exitCode = ($(if($ok){0}else{-1}))
      stdout = ""
      stderr = ""
      ok = $ok
      verified = $false
      verifyDetails = $details
    }) | Out-Null
  } catch {}
}

function Get-ServiceInfoSafe([string]$name) {
  try {
    $svc = Get-CimInstance -ClassName Win32_Service -Filter ("Name='{0}'" -f $name) -ErrorAction Stop
    return [pscustomobject]@{
      exists = $true
      name = $svc.Name
      displayName = $svc.DisplayName
      startMode = $svc.StartMode  # Auto/Manual/Disabled
      state = $svc.State          # Running/Stopped
      status = $svc.Status
    }
  } catch {
    return [pscustomobject]@{ exists = $false; name = $name }
  }
}


function Expand-String([object]$v) {
  if ($null -eq $v) { return "" }
  $s = [Environment]::ExpandEnvironmentVariables([string]$v)
  # Support common batch placeholder used in imported packs
  # IMPORTANT: Do NOT use -replace here; %~dp0\ contains regex escapes and can break under StrictMode.
  if ((Test-Path variable:Global:FalconRoot) -and $Global:FalconRoot) {
    # Literal replacements (batch-style)
    $s = $s.Replace('%~dp0\', ($Global:FalconRoot + '\'))
    $s = $s.Replace('%~dp0/', ($Global:FalconRoot + '\'))
    $s = $s.Replace('%~dp0', $Global:FalconRoot)
  }
  return $s
}

function Normalize-RegPath([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return $p }
  if($p -match '^(HKLM|HKCU|HKCR|HKU|HKCC)\\'){
    return ($p -replace '^(HKLM|HKCU|HKCR|HKU|HKCC)\\', '$1:\')
  }
  return $p
}

function Is-FileSystemPath([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return $false }
  return ($p -match '^[A-Za-z]:\\' -or $p -match '^\\\\')
}

function Is-FolderPath([string]$p){
  try{
    if(Is-FileSystemPath $p){
      return (Test-Path -LiteralPath $p -PathType Container)
    }
  }catch{}
  return $false
}

function Should-AllowExplorer([object]$step){
  try{
    if($step -and $step.PSObject.Properties.Name -contains "allowExplorer"){
      return [bool]$step.allowExplorer
    }
  }catch{}
  return $false
}

# log file location
try {
  $root = Split-Path -Parent $MyInvocation.MyCommand.Path
  $logDir = Join-Path $root "..\logs"
  $logDir = (Resolve-Path -LiteralPath $logDir).Path
} catch {
  $logDir = Join-Path (Get-Location) "logs"
}
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir ("action-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

Log "Falcon run-action.ps1 starting"
try {
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  Log ("IsAdmin: " + $isAdmin)
} catch { }

# ---------------- parse payload ----------------
$payload = $null
try {
  $payload = $Json | ConvertFrom-Json -ErrorAction Stop
} catch {
  Log ("ERROR parsing JSON: " + $_.Exception.Message)
  $script:Errors.Add("Invalid JSON payload: " + $_.Exception.Message) | Out-Null
  $script:LogLines | Out-File -FilePath $logFile -Encoding UTF8 -Force
  [pscustomobject]@{ ok = $false; errors = $script:Errors; warnings = $script:Warnings; logFile = $logFile } | ConvertTo-Json -Compress
  exit 0
}

$steps = @()
if ($payload -and $payload.steps) { $steps = @($payload.steps) }

# ---------------- helpers ----------------


function Get-StepCommandSummary([object]$step) {
  try {
    $t = [string]$step.type
    if ([string]::IsNullOrWhiteSpace($t)) { return "unknown" }
    if ($step.PSObject.Properties.Name -contains "command" -and $step.command) { return ("{0}: {1}" -f $t, (Expand-String $step.command)) }
    if ($step.PSObject.Properties.Name -contains "path" -and $step.path) { return ("{0}: {1}" -f $t, (Expand-String $step.path)) }
    if ($step.PSObject.Properties.Name -contains "name" -and $step.name) { return ("{0}: {1}" -f $t, [string]$step.name) }
    if ($step.PSObject.Properties.Name -contains "guid" -and $step.guid) { return ("{0}: {1}" -f $t, [string]$step.guid) }
    return $t
  } catch { return "unknown" }
}

function Verify-StepOutcome([object]$step) {
  $type = [string]$step.type
  try {
    switch ($type) {
      "registry.set" {
        $p = Normalize-RegPath (Expand-String $step.path)
        $n = [string]$step.name
        $expected = $step.value
        $actual = (Get-ItemProperty -Path $p -Name $n -ErrorAction Stop).$n
        $ok = ([string]$actual -eq [string]$expected)
        return [pscustomobject]@{ verified = $ok; verifyDetails = ("registry value expected={0} actual={1}" -f [string]$expected, [string]$actual) }
      }
      "registry.remove" {
        $p = Normalize-RegPath (Expand-String $step.path)
        $n = [string]$step.name
        $exists = $false
        try {
          $obj = Get-ItemProperty -Path $p -ErrorAction Stop
          $exists = ($obj.PSObject.Properties.Name -contains $n)
        } catch { $exists = $false }
        return [pscustomobject]@{ verified = (-not $exists); verifyDetails = ("registry value removed={0}" -f (-not $exists)) }
      }
      "service.disable" {
        $info = Get-ServiceInfoSafe ([string]$step.name)
        $ok = ($info.exists -and [string]$info.startMode -eq "Disabled")
        return [pscustomobject]@{ verified = $ok; verifyDetails = ("service startMode=" + [string]$info.startMode + " state=" + [string]$info.state) }
      }
      "service.enable" {
        $info = Get-ServiceInfoSafe ([string]$step.name)
        $ok = ($info.exists -and ([string]$info.startMode -eq "Auto" -or [string]$info.startMode -eq "Automatic"))
        return [pscustomobject]@{ verified = $ok; verifyDetails = ("service startMode=" + [string]$info.startMode + " state=" + [string]$info.state) }
      }
      "service.startup" {
        $info = Get-ServiceInfoSafe ([string]$step.name)
        $exp = [string]($step.startupType)
        if ([string]::IsNullOrWhiteSpace($exp)) { $exp = [string]($step.mode) }
        if ([string]::IsNullOrWhiteSpace($exp)) { $exp = [string]($step.value) }
        $ok = $info.exists
        if ($ok -and -not [string]::IsNullOrWhiteSpace($exp)) {
          $actual = [string]$info.startMode
          if ($actual -eq "Auto") { $actual = "Automatic" }
          $ok = ($actual -eq $exp)
        }
        return [pscustomobject]@{ verified = $ok; verifyDetails = ("service startMode=" + [string]$info.startMode + " expected=" + [string]$exp) }
      }
      "task" {
        $tn = [string]$step.name
        $act = [string]$step.action
        $expectedEnabled = $null
        if ($act -eq "disable") { $expectedEnabled = $false }
        if ($act -eq "enable") { $expectedEnabled = $true }
        if ($null -eq $expectedEnabled) { return [pscustomobject]@{ verified = $true; verifyDetails = "task action has no verify target" } }
        $q = schtasks /Query /TN "$tn" /FO LIST /V 2>&1 | Out-String
        $enabled = ($q -match "Scheduled Task State:\s*Enabled")
        return [pscustomobject]@{ verified = ($enabled -eq $expectedEnabled); verifyDetails = ("task enabled=" + $enabled + " expected=" + $expectedEnabled) }
      }
      "powercfg.set" {
        $guid = [string](Expand-String $step.guid)
        if ([string]::IsNullOrWhiteSpace($guid)) { return [pscustomobject]@{ verified = $true; verifyDetails = "powercfg.set had no guid to verify" } }
        $o = (powercfg /GETACTIVESCHEME | Out-String)
        $ok = ($o.ToLowerInvariant().Contains($guid.ToLowerInvariant()))
        return [pscustomobject]@{ verified = $ok; verifyDetails = ("activeScheme=" + $o.Trim()) }
      }
      default { return [pscustomobject]@{ verified = $true; verifyDetails = "verification not required for step type" } }
    }
  } catch {
    return [pscustomobject]@{ verified = $false; verifyDetails = ("verification failed: " + $_.Exception.Message) }
  }
}

function Get-StepLabel([object]$step) {
  try {
    if ($null -eq $step) { return "" }
    if ($step.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$step.id)) { return [string]$step.id }
    if ($step.PSObject.Properties.Name -contains "name" -and -not [string]::IsNullOrWhiteSpace([string]$step.name)) { return [string]$step.name }
  } catch {}
  return ""
}

function Safe-GetService([string]$name) {
  if ([string]::IsNullOrWhiteSpace($name)) { return $null }
  return Get-Service -Name $name -ErrorAction SilentlyContinue
}

function Safe-SetServiceStartup([string]$name, [string]$startType) {
  $svc = Safe-GetService $name
  if ($null -eq $svc) {
    Log "SKIP (service not found): $name"
    $script:Warnings.Add("SKIP service not found: $name") | Out-Null
    return
  }
  try {
    Set-Service -Name $name -StartupType $startType -ErrorAction Stop
    Log "SERVICE STARTUP: $name -> $startType"
  } catch {
    # Retry as TrustedInstaller using NSudo + sc.exe (for protected services)
    try {
      $nsudo = Join-Path $PSScriptRoot "..\tools\NSudoLG.exe"
      if (Test-Path $nsudo) {
        $map = @{ "Automatic"="auto"; "Manual"="demand"; "Disabled"="disabled" }
        $scVal = $map[$startType]
        if (-not $scVal) { $scVal = "demand" }
        $cmd = "cmd /c sc.exe config `"$name`" start= $scVal"
        Start-Process $nsudo -ArgumentList "-U:T -P:E -Wait $cmd" -WindowStyle Hidden -Wait
        Log "SERVICE STARTUP (TI): $name -> $startType"
        return
      }
    } catch {}
    Log ("ERROR Set-Service $name : " + $_.Exception.Message)
    $script:Errors.Add("Set-Service $name : " + $_.Exception.Message) | Out-Null
  }
}

function Safe-TaskChange([string]$tn, [string]$action) {
  if ([string]::IsNullOrWhiteSpace($tn)) {
    $script:Errors.Add("task missing name") | Out-Null
    return
  }
  $exists = $true
  try { schtasks /Query /TN "$tn" | Out-Null } catch { $exists = $false }
  if (-not $exists) {
    Log "SKIP (task not found): $tn"
    $script:Warnings.Add("SKIP task not found: $tn") | Out-Null
    return
  }
  try {
    if ($action -eq "disable") {
      schtasks /Change /TN "$tn" /Disable | Out-Null
      Log "TASK DISABLE: $tn"
    } elseif ($action -eq "enable") {
      schtasks /Change /TN "$tn" /Enable | Out-Null
      Log "TASK ENABLE: $tn"
    } else {
      throw "Unknown task.action '$action'"
    }
  } catch {
    Log ("ERROR task $action $tn : " + $_.Exception.Message)
    $script:Errors.Add("task $action $tn : " + $_.Exception.Message) | Out-Null
  }
}

# ---------------- execute steps ----------------
for ($i = 0; $i -lt $steps.Count; $i++) {
  $s = $steps[$i]
  if ($null -eq $s) { continue }
  $type = [string]$s.type
  if ([string]::IsNullOrWhiteSpace($type)) {
    $script:Errors.Add("Step missing type at index $i") | Out-Null
    continue
  }

  $continueOnError = $false
  try { if ($s.PSObject.Properties.Name -contains "continueOnError") { $continueOnError = [bool]$s.continueOnError } } catch {}
  $stepOk = $true
  $stepExitCode = 0
  $stepStdout = ""
  $stepStderr = ""
  $commandSummary = Get-StepCommandSummary $s
  $verifyResult = [pscustomobject]@{ verified = $true; verifyDetails = "not-verified" }

  try {
    switch ($type) {

      "action" {
        # UI-only/meta step. Ignore at execution time.
        Log ("SKIP action meta-step: " + (Get-StepLabel $s))
      }

      "button" {
        Log ("SKIP button meta-step: " + (Get-StepLabel $s))
      }

      "toggle" {
        Log ("SKIP toggle meta-step: " + (Get-StepLabel $s))
      }

      "tweak" {
        Log ("SKIP tweak meta-step: " + (Get-StepLabel $s))
      }

      "live" {
        Log ("SKIP live meta-step: " + (Get-StepLabel $s))
      }


      "ps.run" {
        $cmd = Expand-String $s.command
        if ([string]::IsNullOrWhiteSpace($cmd)) { throw "ps.run missing command" }
        # Harden: if a command line starts with --- and is piped to Out-File, it must be quoted or PowerShell treats '-' as an operator.
        try {
          $cmd = ($cmd -split "`n") | ForEach-Object {
            if ($_ -match '^\s*---.+---\s*\|\s*Out-File' -and $_ -notmatch '^\s*"---') {
              # wrap the left text chunk in quotes
              $_ -replace '^\s*(---.+---)\s*\|', '"$1" |'
            } else { $_ }
          } | ForEach-Object { $_ } -join "`n"
        } catch {}
        Log "PS.RUN: $cmd"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $cmd | Out-Null
      }

      "ps.file" {
        $rel = Expand-String $s.path
        if ([string]::IsNullOrWhiteSpace($rel)) { throw "ps.file missing path" }
        $scriptPath = $rel
        if (-not (Test-Path -LiteralPath $scriptPath)) {
          # try relative to Falcon root
          if ((Test-Path variable:Global:FalconRoot) -and $Global:FalconRoot) {
            $scriptPath = Join-Path $Global:FalconRoot $rel
          } else {
            $scriptPath = Join-Path (Join-Path $PSScriptRoot "..") $rel
          }
        }
        if (!(Test-Path -LiteralPath $scriptPath)) { throw "ps.file script not found: $scriptPath" }
        $argList = @()
        if ($s.PSObject.Properties.Name -contains "args" -and $null -ne $s.args) {
          # args can be:
          # - array of strings: ["-Flag","Value"]
          # - object map: { Profile:"latency", Action:"start" } -> -Profile latency -Action start
          if ($s.args -is [System.Collections.IEnumerable] -and -not ($s.args -is [pscustomobject]) -and -not ($s.args -is [hashtable]) -and -not ($s.args -is [string])) {
            foreach ($a in $s.args) { $argList += (Expand-String ([string]$a)) }
          } else {
            $pairs = @()
            if ($s.args -is [hashtable]) { $pairs = $s.args.GetEnumerator() }
            else { $pairs = $s.args.PSObject.Properties | ForEach-Object { @{ Name=$_.Name; Value=$_.Value } } }
            foreach ($kv in $pairs) {
              $k = $kv.Name
              $v = $kv.Value
              if ([string]::IsNullOrWhiteSpace($k)) { continue }
              $argList += ("-{0}" -f $k)
              if ($null -ne $v -and [string]$v -ne "") { $argList += (Expand-String ([string]$v)) }
            }
          }
        }
        Log ("PS.FILE: {0} {1}" -f $scriptPath, ($argList -join ' '))
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" {1}" -f $scriptPath, ($argList -join ' '))
        $psi.UseShellExecute = $false
        $p = [System.Diagnostics.Process]::Start($psi)
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) { throw ("ps.file failed ({0}): {1}" -f $p.ExitCode, $scriptPath) }
      }

      "cmd" {
        $cmd = Expand-String $s.command
        if ([string]::IsNullOrWhiteSpace($cmd)) { throw "cmd missing command" }
        Log "CMD: $cmd"
        $outLines = & cmd.exe /c $cmd 2>&1
        $exit = $LASTEXITCODE
        try {
          if ($outLines) {
            $joined = ($outLines -join "`n")
            if ($joined.Length -gt 4000) { $joined = $joined.Substring(0,4000) + "`n...(truncated)" }
            Log $joined
          }
        } catch {}
        Add-StepResult "cmd" $cmd ($exit -eq 0) ([pscustomobject]@{ exitCode = $exit })
        if ($exit -ne 0) { throw ("cmd failed ({0})" -f $exit) }
      }

      "cmd.run" {
        $cmd = Expand-String $s.command
        if ([string]::IsNullOrWhiteSpace($cmd)) { throw "cmd.run missing command" }
        Log "CMD.RUN: $cmd"
        $outLines = & cmd.exe /c $cmd 2>&1
        $exit = $LASTEXITCODE
        try {
          if ($outLines) {
            $joined = ($outLines -join "`n")
            if ($joined.Length -gt 4000) { $joined = $joined.Substring(0,4000) + "`n...(truncated)" }
            Log $joined
          }
        } catch {}
        Add-StepResult "cmd" $cmd ($exit -eq 0) ([pscustomobject]@{ exitCode = $exit })
        if ($exit -ne 0) { throw ("cmd failed ({0})" -f $exit) }
      }


      "reg.set" {
        # alias for registry.set
        $path = Normalize-RegPath (Expand-String $s.path)
        $name = [string]$s.name
        $val  = $s.value
        $vt   = $s.valueType
        if ([string]::IsNullOrWhiteSpace($path)) { throw "reg.set missing path" }
        if ($null -eq $name) { throw "reg.set missing name" }
        if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        if ($vt -and ($vt -eq "DWORD" -or $vt -eq "DWord")) {
          New-ItemProperty -Path $path -Name $name -Value ([int]$val) -PropertyType DWord -Force | Out-Null
        } elseif ($vt -and ($vt -eq "QWORD" -or $vt -eq "QWord")) {
          New-ItemProperty -Path $path -Name $name -Value ([long]$val) -PropertyType QWord -Force | Out-Null
        } else {
          New-ItemProperty -Path $path -Name $name -Value $val -Force | Out-Null
        }
        Log ("REG SET (alias): {0} {1}={2}" -f $path, $name, $val)
      }

      "reg.del" {
        # alias for registry.remove
        $path = Normalize-RegPath (Expand-String $s.path)
        $name = [string]$s.name
        if ([string]::IsNullOrWhiteSpace($path)) { throw "reg.del missing path" }
        if ($null -eq $name) { throw "reg.del missing name" }
        try { Remove-ItemProperty -Path $path -Name $name -ErrorAction Stop | Out-Null } catch {}
        Log ("REG DEL (alias): {0} {1}" -f $path, $name)
      }

      "registry.set" {
        $path = Normalize-RegPath (Expand-String $s.path)
        $name = [string]$s.name
        $val  = $s.value
        $vt   = $s.valueType
        if ([string]::IsNullOrWhiteSpace($path)) { throw "registry.set missing path" }
        if ($null -eq $name) { throw "registry.set missing name" }

        if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        if ($vt -and ($vt -eq "DWORD" -or $vt -eq "DWord")) {
          New-ItemProperty -Path $path -Name $name -Value ([int]$val) -PropertyType DWord -Force | Out-Null
        } elseif ($vt -and ($vt -eq "QWORD" -or $vt -eq "QWord")) {
          New-ItemProperty -Path $path -Name $name -Value ([long]$val) -PropertyType QWord -Force | Out-Null
        } else {
          New-ItemProperty -Path $path -Name $name -Value $val -Force | Out-Null
        }
        Log "REG SET: $path -> $name = $val ($vt)"
      }

      "registry.remove" {
        $path = Normalize-RegPath (Expand-String $s.path)
        $name = [string]$s.name
        if ([string]::IsNullOrWhiteSpace($path)) { throw "registry.remove missing path" }
        if ($null -eq $name) { throw "registry.remove missing name" }
        if (Test-Path $path) {
          try {
            Remove-ItemProperty -Path $path -Name $name -ErrorAction Stop | Out-Null
            Log "REG REMOVE: $path -> $name"
          } catch {
            Log "SKIP (reg value not found): $path -> $name"
            $script:Warnings.Add("SKIP reg value not found: $path\$name") | Out-Null
          }
        } else {
          Log "SKIP (reg key not found): $path"
          $script:Warnings.Add("SKIP reg key not found: $path") | Out-Null
        }
      }

      "service.disable" {
        $svc = [string]$s.name
        if ([string]::IsNullOrWhiteSpace($svc)) { throw "service.disable missing name" }
        if ($null -eq (Safe-GetService $svc)) {
          Log "SKIP (service not found): $svc"
          $script:Warnings.Add("SKIP service not found: $svc") | Out-Null
          break
        }
        try { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
        Safe-SetServiceStartup $svc "Disabled"
      }

      "service.enable" {
        $svc = [string]$s.name
        if ([string]::IsNullOrWhiteSpace($svc)) { throw "service.enable missing name" }
        if ($null -eq (Safe-GetService $svc)) {
          Log "SKIP (service not found): $svc"
          $script:Warnings.Add("SKIP service not found: $svc") | Out-Null
          break
        }
        Safe-SetServiceStartup $svc "Automatic"
        if (($s.PSObject.Properties.Name -contains "start") -and ($s.start -eq $true)) { try { Start-Service -Name $svc -ErrorAction SilentlyContinue | Out-Null } catch {} }
      }


      "uac.disable" {
        if ($script:Falcon_UAC_Previous -eq $null) {
          try { $script:Falcon_UAC_Previous = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction Stop).EnableLUA } catch { $script:Falcon_UAC_Previous = 1 }
        }
        Log "UAC: Disable (EnableLUA=0)"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Type DWord -Value 0 -Force
      }

      "uac.restore" {
        if ($script:Falcon_UAC_Previous -eq $null) { $script:Falcon_UAC_Previous = 1 }
        Log "UAC: Restore (EnableLUA=$script:Falcon_UAC_Previous)"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Type DWord -Value ([int]$script:Falcon_UAC_Previous) -Force
        $script:Falcon_UAC_Previous = $null
      }

      "nsudo.run" {
        $file = Expand-String $s.file
        if ([string]::IsNullOrWhiteSpace($file)) { throw "nsudo.run missing file" }
        $nsudo = Join-Path $PSScriptRoot "..\tools\NSudoLG.exe"
        $scriptPath = Join-Path $PSScriptRoot "..\$file"
        if (!(Test-Path $nsudo)) { throw "NSudo not found at $nsudo" }
        if (!(Test-Path $scriptPath)) { throw "Script not found at $scriptPath" }
        Log "NSUDO RUN (SYSTEM): $scriptPath"
        Start-Process $nsudo -ArgumentList "-U:S -P:E -Wait `"$scriptPath`"" -WindowStyle Hidden -Wait
      }

      "service.startup" {
        $svc = [string]$s.name
        $st  = [string]$s.startType
        if ([string]::IsNullOrWhiteSpace($st) -and ($s.PSObject.Properties.Name -contains "startupType")) { $st = [string]$s.startupType }
        if ([string]::IsNullOrWhiteSpace($st) -and ($s.PSObject.Properties.Name -contains "mode")) { $st = [string]$s.mode }
        if ([string]::IsNullOrWhiteSpace($st) -and ($s.PSObject.Properties.Name -contains "value")) { $st = [string]$s.value }
        if ([string]::IsNullOrWhiteSpace($st) -and ($s.PSObject.Properties.Name -contains "startType")) { $st = [string]$s.startType }
        if ([string]::IsNullOrWhiteSpace($st) -and ($s.PSObject.Properties.Name -contains "start")) { $st = [string]$s.start }
        if ([string]::IsNullOrWhiteSpace($svc)) { throw "service.startup missing name" }
        if ([string]::IsNullOrWhiteSpace($st)) { throw "service.startup missing startType" }
        
        $pre = Get-ServiceInfoSafe $svc
        if (-not $pre.exists) {
          Log "SERVICE NOT FOUND: $svc"
        } else {
          Log ("SERVICE BEFORE: {0} startMode={1} state={2}" -f $svc, $pre.startMode, $pre.state)
        }
Safe-SetServiceStartup $svc $st

        # Optional restart semantics used by Fix modules.
        $doStop = $false
        $doStart = $false
        try {
          if ($s.PSObject.Properties.Name -contains "stop") {
            if ([bool]$s.stop) {
              $doStop = $true
              $doStart = $true
            }
          }
          if ($s.PSObject.Properties.Name -contains "start") {
            if ([bool]$s.start) { $doStart = $true }
            else { $doStop = $true }
          }
        } catch {}

        if ($st -eq "Disabled") { $doStop = $true; $doStart = $false }

        if ($doStop) {
          try { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
        if ($doStart) {
          try { Start-Service -Name $svc -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
        $post = Get-ServiceInfoSafe $svc
        $ok = $true
        if (-not $post.exists) { $ok = $false }
        Add-StepResult "service.startup" $svc $ok ([pscustomobject]@{
          requestedStartType = $st
          before = $pre
          after = $post
        })
        if ($post.exists) {
          Log ("SERVICE AFTER: {0} startMode={1} state={2}" -f $svc, $post.startMode, $post.state)
        }

      }

      "process.kill" {
        $name = [string]$s.name
        if ([string]::IsNullOrWhiteSpace($name)) { throw "process.kill missing name" }
        Log "KILL PROCESS: $name"
        Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
      }

      "process.start" {
        # Special handling for settings URIs and Control Panel applets

        $fp = ""
        if ($s.PSObject.Properties.Name -contains "filePath") { $fp = Expand-String $s.filePath }
        elseif ($s.PSObject.Properties.Name -contains "path") { $fp = Expand-String $s.path }
        $args = ""
        if ($s.PSObject.Properties.Name -contains "arguments") { $args = Expand-String $s.arguments }
        elseif ($s.PSObject.Properties.Name -contains "args") { $args = Expand-String $s.args }
        if ([string]::IsNullOrWhiteSpace($fp)) { throw "process.start missing filePath" }

# Settings URIs (ms-settings:) must be launched via explorer.exe
if ($fp -like "ms-settings:*") {
  Log "PROCESS START (SETTINGS URI): $fp"
  Start-Process -FilePath "explorer.exe" -ArgumentList $fp | Out-Null
  break
}
# Control Panel applets (*.cpl)
if ($fp.ToLower().EndsWith(".cpl")) {
  Log "PROCESS START (CPL): $fp"
  Start-Process -FilePath "control.exe" -ArgumentList $fp | Out-Null
  break
}


        if (Is-FolderPath $fp) {
          if (Should-AllowExplorer $s) {
            Log "PROCESS START (FOLDER ALLOWED): $fp"
            Start-Process -FilePath $fp | Out-Null
          } else {
            Log "SKIP: folder launch blocked (process.start): $fp"
            $script:Warnings.Add("SKIP folder launch blocked: $fp") | Out-Null
          }
          break
        }

        if ([string]::IsNullOrWhiteSpace($args)) {
          Log "PROCESS START: $fp"
          Start-Process -FilePath $fp | Out-Null
        } else {
          Log "PROCESS START: $fp $args"
          Start-Process -FilePath $fp -ArgumentList $args | Out-Null
        }
      }

      "shell.start" {
        $file = Expand-String $s.file
        if ([string]::IsNullOrWhiteSpace($file)) { throw "shell.start missing file" }

        if (Is-FolderPath $file) {
          if (Should-AllowExplorer $s) {
            Log "SHELL START (FOLDER ALLOWED): $file"
            Start-Process -FilePath $file | Out-Null
          } else {
            Log "SKIP: folder launch blocked (shell.start): $file"
            $script:Warnings.Add("SKIP folder launch blocked: $file") | Out-Null
          }
          break
        }

        $args = @()
        if ($s.args -is [System.Array]) { $args = $s.args } elseif ($s.args) { $args = @([string]$s.args) }
        $wait = $false
        if ($s.PSObject.Properties.Name -contains "wait") { $wait = [bool]$s.wait }
        $argLine = ($args -join " ")
        Log "SHELL START: $file $argLine"

        if ($wait) {
          if ([string]::IsNullOrWhiteSpace($argLine)) {
            Start-Process -FilePath $file -Wait | Out-Null
          } else {
            Start-Process -FilePath $file -ArgumentList $argLine -Wait | Out-Null
          }
        } else {
          if ([string]::IsNullOrWhiteSpace($argLine)) {
            Start-Process -FilePath $file | Out-Null
          } else {
            Start-Process -FilePath $file -ArgumentList $argLine | Out-Null
          }
        }
      }

      "open.url" {
        $u = Expand-String $s.url
        if ([string]::IsNullOrWhiteSpace($u)) { throw "open.url missing url" }
        Log "OPEN URL: $u"
        try { Start-Process $u | Out-Null } catch { throw ("Failed to open url: " + $_.Exception.Message) }
      }

      "open.file" {
        $fp = ""
        if ($s.PSObject.Properties.Name -contains "filePath") { $fp = Expand-String $s.filePath }
        elseif ($s.PSObject.Properties.Name -contains "path") { $fp = Expand-String $s.path }
        if ([string]::IsNullOrWhiteSpace($fp)) { throw "open.file missing filePath" }
        Log "OPEN FILE: $fp"
        # Resolve relative paths against Falcon root
        if (-not (Is-FileSystemPath $fp) -and $Global:FalconRoot) {
          $cand = Join-Path $Global:FalconRoot $fp
          if (Test-Path -LiteralPath $cand) { $fp = $cand }
        }
        if (-not (Test-Path -LiteralPath $fp)) { throw ("File not found: " + $fp) }
        try { Start-Process -FilePath $fp | Out-Null } catch { throw ("Failed to open file: " + $_.Exception.Message) }
      }

      "open.path" {
        $p = Expand-String $s.path
        if ([string]::IsNullOrWhiteSpace($p)) { throw "open.path missing path" }
        Log "OPEN PATH: $p"
        # Resolve relative paths against Falcon root FIRST
        if (-not (Is-FileSystemPath $p) -and $Global:FalconRoot) {
          $p = Join-Path $Global:FalconRoot $p
        }
        # If target folder does not exist, create it so Open never silently fails
        try { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } } catch {}
        if (-not (Test-Path -LiteralPath $p)) { throw ("Path not found: " + $p) }
        try { Start-Process -FilePath $p | Out-Null } catch { throw ("Failed to open path: " + $_.Exception.Message) }
      }

      "file.ensureDir" {
        $p = Expand-String $s.path
        if ([string]::IsNullOrWhiteSpace($p)) { throw "file.ensureDir missing path" }
        if (-not (Test-Path -LiteralPath $p)) {
          Log "ENSURE DIR: $p"
          New-Item -ItemType Directory -Force -Path $p | Out-Null
        } else {
          Log "ENSURE DIR (exists): $p"
        }
      }

      "tool.ensure" {
        $id = [string]$s.toolId
        if ([string]::IsNullOrWhiteSpace($id)) { throw "tool.ensure missing toolId" }
        $mgr = Join-Path $Global:FalconRoot "scripts\tools\falcon-tool-manager.ps1"
        if (-not (Test-Path -LiteralPath $mgr)) { throw "Missing tool manager: $mgr" }
        Log "TOOL.ENSURE: $id"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File $mgr -Command ensure -ToolId $id | Out-Null
      }

      "tool.launch" {
        $id = [string]$s.toolId
        if ([string]::IsNullOrWhiteSpace($id)) { throw "tool.launch missing toolId" }
        $mgr = Join-Path $Global:FalconRoot "scripts\tools\falcon-tool-manager.ps1"
        if (-not (Test-Path -LiteralPath $mgr)) { throw "Missing tool manager: $mgr" }
        Log "TOOL.LAUNCH: $id"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File $mgr -Command launch -ToolId $id | Out-Null
      }


      "task" {
        $tn = [string]$s.name
        $act = [string]$s.action
        if ($act) { $act = $act.ToLower() }
        Safe-TaskChange $tn $act
      }

      "powercfg.set" {
        $guid = Expand-String $s.guid
        if ([string]::IsNullOrWhiteSpace($guid)) { throw "powercfg.set missing guid" }
        Log "POWERCFG SET: $guid"
        powercfg /S $guid | Out-Null
      }

      "timer.set" {
        $us = [int]$s.microseconds
        if (-not ($s.PSObject.Properties.Name -contains "microseconds")) { $us = 5000 }
        if ($us -le 0) { $us = 5000 }
        if ($us -le 0) { throw "timer.set invalid microseconds" }
        Log "TIMER.SET: request ${us}us"
        try {
          Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class TimerRes {
  [DllImport("ntdll.dll", SetLastError=true)]
  public static extern uint NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);
}
"@ -ErrorAction SilentlyContinue | Out-Null
          $cur = 0
          [TimerRes]::NtSetTimerResolution([uint32]$us, $true, [ref]$cur) | Out-Null
          Log "TIMER.SET OK (current=$cur)"
        } catch {
          Log ("ERROR timer.set: " + $_.Exception.Message)
          $script:Errors.Add("timer.set: " + $_.Exception.Message) | Out-Null
        }
      }

      "timer.reset" {
        Log "TIMER.RESET"
        try {
          Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class TimerRes2 {
  [DllImport("ntdll.dll", SetLastError=true)]
  public static extern uint NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);
}
"@ -ErrorAction SilentlyContinue | Out-Null
          $cur = 0
          [TimerRes2]::NtSetTimerResolution(0, $false, [ref]$cur) | Out-Null
          Log "TIMER.RESET OK (current=$cur)"
        } catch {
          Log ("ERROR timer.reset: " + $_.Exception.Message)
          $script:Errors.Add("timer.reset: " + $_.Exception.Message) | Out-Null
        }
      }

      "run.exe" {
        $fp = ""
        if ($s.PSObject.Properties.Name -contains "filePath") { $fp = Expand-String $s.filePath }
        elseif ($s.PSObject.Properties.Name -contains "path") { $fp = Expand-String $s.path }
        if ([string]::IsNullOrWhiteSpace($fp)) { throw "run.exe missing filePath" }
        $args = ""
        if ($s.PSObject.Properties.Name -contains "arguments") { $args = Expand-String $s.arguments }
        elseif ($s.PSObject.Properties.Name -contains "args") { $args = Expand-String $s.args }

        if (Is-FolderPath $fp) {
          if (Should-AllowExplorer $s) {
            Log "RUN.EXE (FOLDER ALLOWED): $fp"
            Start-Process -FilePath $fp | Out-Null
          } else {
            Log "SKIP: folder launch blocked (run.exe): $fp"
            $script:Warnings.Add("SKIP folder launch blocked: $fp") | Out-Null
          }
          break
        }

        Log "RUN.EXE: $fp $args"
        if ([string]::IsNullOrWhiteSpace($args)) {
          Start-Process -FilePath $fp | Out-Null
        } else {
          Start-Process -FilePath $fp -ArgumentList $args | Out-Null
        }
      }

"registry.check" {
  $path = Normalize-RegPath (Expand-String $s.path)
  $name = [string]$s.name
  $expect = $s.equals
  $vt = $s.valueType
  $mustExist = $true
  if (($s.PSObject.Properties.Name -contains "exists")) { $mustExist = [bool]$s.exists }

  if ([string]::IsNullOrWhiteSpace($path)) { throw "registry.check missing path" }
  if ($null -eq $name) { throw "registry.check missing name" }

  $exists = $false
  $actual = $null
  try {
    if (Test-Path $path) {
      $p = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
      if ($null -ne $p -and ($p.PSObject.Properties.Name -contains $name)) {
        $exists = $true
        $actual = $p.$name
      }
    }
  } catch {}

  if ($mustExist -and -not $exists) { throw ("registry.check missing value: " + $path + " :: " + $name) }
  if (-not $mustExist -and $exists) { throw ("registry.check expected missing but found: " + $path + " :: " + $name) }

  if ($mustExist) {
    if ($vt -and ($vt -eq "DWORD" -or $vt -eq "DWord")) {
      if ([int]$actual -ne [int]$expect) { throw ("registry.check mismatch (DWORD) " + $path + " :: " + $name + " expected=" + [int]$expect + " actual=" + [int]$actual) }
    } elseif ($vt -and ($vt -eq "QWORD" -or $vt -eq "QWord")) {
      if ([long]$actual -ne [long]$expect) { throw ("registry.check mismatch (QWORD) " + $path + " :: " + $name + " expected=" + [long]$expect + " actual=" + [long]$actual) }
    } else {
      if ([string]$actual -ne [string]$expect) { throw ("registry.check mismatch " + $path + " :: " + $name + " expected=" + [string]$expect + " actual=" + [string]$actual) }
    }
  }
}

      "registry.check_absent" {
        $path = Expand-String $s.path
        $name = Expand-String $s.name
        if ([string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($name)) { throw "registry.check_absent missing path/name" }
        $exists = Test-RegistryValueExists $path $name
        if ($exists) {
          throw "CHECK FAIL: Registry value exists ($path\\$name)"
        } else {
          Log "CHECK OK: Registry value absent ($path\\$name)"
        }
      }


"service.check" {
  $svc = [string]$s.name
  if ([string]::IsNullOrWhiteSpace($svc)) { throw "service.check missing name" }

  $expectStatus = $null
  $expectStart  = $null
  if (($s.PSObject.Properties.Name -contains "status")) { $expectStatus = [string]$s.status }
  if (($s.PSObject.Properties.Name -contains "startMode")) { $expectStart = [string]$s.startMode }

  $gs = Safe-GetService $svc
  if ($null -eq $gs) { throw ("service.check service not found: " + $svc) }

  if ($expectStatus) {
    if ([string]$gs.Status -ne [string]$expectStatus) { throw ("service.check status mismatch " + $svc + " expected=" + $expectStatus + " actual=" + [string]$gs.Status) }
  }

  if ($expectStart) {
    try {
      $c = Get-CimInstance Win32_Service -Filter ("Name='" + $svc.Replace("'", "''") + "'") -ErrorAction SilentlyContinue
      if ($null -eq $c) { throw ("service.check unable to query start mode for: " + $svc) }
      $actualMode = [string]$c.StartMode
      # Normalize to Automatic/Manual/Disabled
      if ($actualMode -eq "Auto") { $actualMode = "Automatic" }
      if ($actualMode -eq "Disabled") { $actualMode = "Disabled" }
      if ($actualMode -eq "Manual") { $actualMode = "Manual" }
      if ($actualMode -ne [string]$expectStart) { throw ("service.check startMode mismatch " + $svc + " expected=" + [string]$expectStart + " actual=" + $actualMode) }
    } catch {
      throw ("service.check startMode query failed for " + $svc + " : " + $_.Exception.Message)
    }
  }
}

"powercfg.check" {
  $guid = Expand-String $s.guid
  if ([string]::IsNullOrWhiteSpace($guid)) { throw "powercfg.check missing guid" }
  $out = ""
  try { $out = (powercfg /GETACTIVESCHEME | Out-String) } catch { $out = "" }
  if ($out -notmatch "([0-9a-fA-F\-]{36})") { throw ("powercfg.check could not parse active scheme: " + $out) }
  $active = $Matches[1]
  if ($active.ToLowerInvariant() -ne $guid.ToLowerInvariant()) { throw ("powercfg.check mismatch expected=" + $guid + " actual=" + $active) }
}


      
      "cmd" {
        $cmd = Expand-String $s.command
        if ([string]::IsNullOrWhiteSpace($cmd)) { throw "cmd missing command" }
        Log "CMD: $cmd"
        cmd.exe /c $cmd | Out-Null
      }

      "powercfg" {
        $args = @()
        if ($s.PSObject.Properties.Name -contains "args" -and $null -ne $s.args) {
          foreach($a in $s.args){ $args += (Expand-String $a) }
        }
        if ($args.Count -lt 1) { throw "powercfg missing args" }
        Log ("POWERCFG: " + ($args -join " "))
        powercfg @args | Out-Null
      }

      "powercfg.set" {
        $args = @()
        if ($s.PSObject.Properties.Name -contains "args" -and $null -ne $s.args) {
          foreach($a in $s.args){ $args += (Expand-String $a) }
        }
        if ($args.Count -lt 1) { throw "powercfg.set missing args" }
        Log ("POWERCFG.SET: " + ($args -join " "))
        powercfg @args | Out-Null
      }

      "registry.set" {
        $path = Expand-String $s.path
        $name = Expand-String $s.name
        $val  = $s.value
        $vt   = Expand-String $s.valueType
        if ([string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($name)) { throw "registry.set missing path/name" }
        if ([string]::IsNullOrWhiteSpace($vt)) { $vt = "DWord" }
        $typeMap = @{
          "dword"="REG_DWORD"; "qword"="REG_QWORD"; "string"="REG_SZ"; "sz"="REG_SZ";
          "expandstring"="REG_EXPAND_SZ"; "multistring"="REG_MULTI_SZ"; "binary"="REG_BINARY"
        }
        $regType = $typeMap[$vt.ToLowerInvariant()]
        if (-not $regType) { $regType = "REG_DWORD" }
        $valStr = ""
        if ($null -ne $val) {
          if ($val -is [bool]) { $valStr = ($(if($val){1}else{0})) }
          else { $valStr = [string]$val }
        }
        Log "REG SET: $path\$name = $valStr ($regType)"
        reg.exe add "$path" /v "$name" /t $regType /d "$valStr" /f | Out-Null
      }

      "registry.remove" {
        $path = Expand-String $s.path
        $name = Expand-String $s.name
        if ([string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($name)) { throw "registry.remove missing path/name" }
        Log "REG DEL: $path\$name"
        reg.exe delete "$path" /v "$name" /f | Out-Null
      }

      "reg.set" {
        # alias
        $path = Expand-String $s.path
        $name = Expand-String $s.name
        $val  = $s.value
        $vt   = Expand-String $s.valueType
        if ([string]::IsNullOrWhiteSpace($vt)) { $vt = "DWord" }
        $s2 = [pscustomobject]@{ path=$path; name=$name; value=$val; valueType=$vt }
        $s = $s2
        # fallthrough is not supported; execute via calling registry.set
        $path = Expand-String $s.path
        $name = Expand-String $s.name
        $val  = $s.value
        $vt   = Expand-String $s.valueType
        $typeMap = @{ "dword"="REG_DWORD"; "qword"="REG_QWORD"; "string"="REG_SZ"; "expandstring"="REG_EXPAND_SZ"; "multistring"="REG_MULTI_SZ"; "binary"="REG_BINARY" }
        $regType = $typeMap[$vt.ToLowerInvariant()]
        if (-not $regType) { $regType = "REG_DWORD" }
        $valStr = ""
        if ($null -ne $val) { $valStr = [string]$val }
        Log "REG SET: $path\$name = $valStr ($regType)"
        reg.exe add "$path" /v "$name" /t $regType /d "$valStr" /f | Out-Null
      }

      "reg.del" {
        $path = Expand-String $s.path
        $name = Expand-String $s.name
        if ([string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($name)) { throw "reg.del missing path/name" }
        Log "REG DEL: $path\$name"
        reg.exe delete "$path" /v "$name" /f | Out-Null
      }

      "service.disable" {
        $svc = Expand-String $s.name
        if ([string]::IsNullOrWhiteSpace($svc)) { throw "service.disable missing name" }
        Log "SERVICE DISABLE: $svc"
        sc.exe stop "$svc" | Out-Null
        sc.exe config "$svc" start= disabled | Out-Null
      }

      "service.enable" {
        $svc = Expand-String $s.name
        if ([string]::IsNullOrWhiteSpace($svc)) { throw "service.enable missing name" }
        $startup = "auto"
        if ($s.PSObject.Properties.Name -contains "startup" -and $s.startup) { $startup = (Expand-String $s.startup) }
        Log "SERVICE ENABLE: $svc (startup=$startup)"
        sc.exe config "$svc" start= $startup | Out-Null
        sc.exe start "$svc" | Out-Null
      }

      "service.startup" {
        # Legacy alias block (keep compatible with older catalogs)
        $svc = Expand-String $s.name
        $st  = Expand-String $s.startup
        if ([string]::IsNullOrWhiteSpace($st) -and ($s.PSObject.Properties.Name -contains "startType")) { $st = Expand-String $s.startType }
        if ([string]::IsNullOrWhiteSpace($st) -and ($s.PSObject.Properties.Name -contains "startupType")) { $st = Expand-String $s.startupType }
        if ([string]::IsNullOrWhiteSpace($st) -and ($s.PSObject.Properties.Name -contains "mode")) { $st = Expand-String $s.mode }
        if ([string]::IsNullOrWhiteSpace($svc) -or [string]::IsNullOrWhiteSpace($st)) { throw "service.startup missing name/startType" }

        Safe-SetServiceStartup $svc $st

        $doStop = $false
        $doStart = $false
        try {
          if ($s.PSObject.Properties.Name -contains "stop") {
            if ([bool]$s.stop) { $doStop = $true; $doStart = $true }
          }
          if ($s.PSObject.Properties.Name -contains "start") {
            if ([bool]$s.start) { $doStart = $true } else { $doStop = $true }
          }
        } catch {}
        if ($st -eq "Disabled") { $doStop = $true; $doStart = $false }
        if ($doStop) { try { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue | Out-Null } catch {} }
        if ($doStart) { try { Start-Service -Name $svc -ErrorAction SilentlyContinue | Out-Null } catch {} }
      }

      "schtasks" {
        $args = @()
        if ($s.PSObject.Properties.Name -contains "args" -and $null -ne $s.args) {
          foreach($a in $s.args){ $args += (Expand-String $a) }
        } elseif ($s.PSObject.Properties.Name -contains "command" -and $s.command) {
          $args = @("/Change") + ((Expand-String $s.command) -split '\s+')
        }
        if ($args.Count -lt 1) { throw "schtasks missing args" }
        Log ("SCHTASKS: " + ($args -join " "))
        schtasks.exe @args | Out-Null
      }

      "task.check" {
        $tn = Expand-String $s.name
        $expected = $true
        if ($s.PSObject.Properties.Name -contains "enabled") { $expected = [bool]$s.enabled }
        if ([string]::IsNullOrWhiteSpace($tn)) { throw "task.check missing name" }
        $taskName = $tn
        $taskPath = "\"
        if ($tn -like "*\*") {
          $last = $tn.LastIndexOf("\")
          if ($last -gt 0) {
            $taskPath = $tn.Substring(0, $last+1)
            $taskName = $tn.Substring($last+1)
          }
        }
        try {
          $t = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
          $en = $t.Settings.Enabled
          if ($en -ne $expected) { throw "CHECK FAIL: Task enabled=$en expected=$expected ($tn)" }
          Log "CHECK OK: Task enabled=$en ($tn)"
        } catch {
          throw "CHECK FAIL: Task not found or unreadable ($tn) $_"
        }
      }


      "bcdedit" {
        $args = @()
        if ($s.PSObject.Properties.Name -contains "args" -and $null -ne $s.args) {
          foreach($a in $s.args){ $args += (Expand-String $a) }
        } elseif ($s.PSObject.Properties.Name -contains "command" -and $s.command) {
          $args = (Expand-String $s.command) -split '\s+'
        }
        if ($args.Count -lt 1) { throw "bcdedit missing args" }
        Log ("BCDEDIT: " + ($args -join " "))
        bcdedit.exe @args | Out-Null
      }

      "netsh" {
        $args = @()
        if ($s.PSObject.Properties.Name -contains "args" -and $null -ne $s.args) {
          foreach($a in $s.args){ $args += (Expand-String $a) }
        } elseif ($s.PSObject.Properties.Name -contains "command" -and $s.command) {
          $args = (Expand-String $s.command) -split '\s+'
        }
        if ($args.Count -lt 1) { throw "netsh missing args" }
        Log ("NETSH: " + ($args -join " "))
        netsh.exe @args | Out-Null
      }

      "run.exe" {
        $exe = Expand-String $s.path
        $args = @()
        if ($s.PSObject.Properties.Name -contains "args" -and $null -ne $s.args) {
          foreach($a in $s.args){ $args += (Expand-String $a) }
        }
        if ([string]::IsNullOrWhiteSpace($exe)) { throw "run.exe missing path" }
        Log ("RUN.EXE: " + $exe + " " + ($args -join " "))
        Start-Process -FilePath $exe -ArgumentList $args -Wait -NoNewWindow
      }

      "file.ensureDir" {
        $p = Expand-String $s.path
        if ([string]::IsNullOrWhiteSpace($p)) { throw "file.ensureDir missing path" }
        Log "ENSURE DIR: $p"
        New-Item -ItemType Directory -Path $p -Force | Out-Null
      }

default {
        Log "WARN unknown step type: $type"
        $script:Warnings.Add("Unknown step type: $type") | Out-Null
      }
    }
    $verifyResult = Verify-StepOutcome $s
    if (-not $verifyResult.verified) {
      $stepOk = $false
      $stepExitCode = 2
      $stepStderr = [string]$verifyResult.verifyDetails
      $script:Errors.Add("$type verification failed: " + [string]$verifyResult.verifyDetails) | Out-Null
      Log ("VERIFY FAIL $type : " + [string]$verifyResult.verifyDetails)
      if (-not $continueOnError) {
        Add-StepResult ([pscustomobject]@{ stepIndex=$i; type=$type; commandSummary=$commandSummary; exitCode=$stepExitCode; stdout=$stepStdout; stderr=$stepStderr; ok=$false; verified=$false; verifyDetails=[string]$verifyResult.verifyDetails })
        break
      }
    }
  } catch {
    $stepOk = $false
    $stepExitCode = -1
    $stepStderr = $_.Exception.Message
    Log ("ERROR step $type : " + $_.Exception.Message)
    $script:Errors.Add("$type : " + $_.Exception.Message) | Out-Null
    if (-not $continueOnError) {
      Add-StepResult ([pscustomobject]@{ stepIndex=$i; type=$type; commandSummary=$commandSummary; exitCode=$stepExitCode; stdout=$stepStdout; stderr=$stepStderr; ok=$false; verified=$false; verifyDetails="not-verified" })
      break
    }
  }

  Add-StepResult ([pscustomobject]@{ stepIndex=$i; type=$type; commandSummary=$commandSummary; exitCode=$stepExitCode; stdout=$stepStdout; stderr=$stepStderr; ok=$stepOk; verified=[bool]$verifyResult.verified; verifyDetails=[string]$verifyResult.verifyDetails })
}

# write log and return
$script:LogLines | Out-File -FilePath $logFile -Encoding UTF8 -Force
$verifyTotal = @($script:StepResults | Where-Object { $_.verified -eq $true }).Count
$failedTotal = @($script:StepResults | Where-Object { $_.ok -eq $false }).Count
$out = [pscustomobject]@{
  ok = ($script:Errors.Count -eq 0)
  errors = $script:Errors
  warnings = $script:Warnings
  logFile = $logFile
  stepResults = $script:StepResults
  verifySummary = [pscustomobject]@{ verified = $verifyTotal; failed = $failedTotal; total = $script:StepResults.Count }
}

if ($ResultFile -and $ResultFile.Trim().Length -gt 0) {
  try {
    $out | ConvertTo-Json -Compress | Out-File -FilePath $ResultFile -Encoding UTF8 -Force
  } catch {
    # ignore
  }
}

$out | ConvertTo-Json -Compress
exit 0