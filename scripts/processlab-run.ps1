param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('safe','competitive','extreme')]
    [string]$Mode,
    [string]$OverridesPath
)

$ErrorActionPreference = 'SilentlyContinue'

# Basic admin check – Process Lab MUST run elevated
try {
    $currentIdentity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Output "ProcessLabError=NotAdmin"
        exit 1
    }
} catch {
    # If the check fails for some reason, continue and let service calls fail gracefully.
}

# Resolve paths
$scriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot

$catalogPath = Join-Path (Join-Path $projectRoot 'tweaks') 'processlab.services.catalog.json'
$modesPath   = Join-Path (Join-Path $projectRoot 'tweaks') 'processlab.modes.json'

if (!(Test-Path $catalogPath) -or !(Test-Path $modesPath)) {
    Write-Output "ProcessLabError=MissingConfig"
    exit 1
}

# Load catalog + mode config
try {
    $catalogJson = Get-Content $catalogPath -Raw
    $catalog     = $catalogJson | ConvertFrom-Json
} catch {
    Write-Output "ProcessLabError=BadCatalogJson"
    exit 1
}

try {
    $modesJson = Get-Content $modesPath -Raw
    $modes     = $modesJson | ConvertFrom-Json
} catch {
    Write-Output "ProcessLabError=BadModesJson"
    exit 1
}

if (-not $catalog.services -or -not $modes.modes) {
    Write-Output "ProcessLabError=EmptyConfig"
    exit 1
}

# Load per-service overrides from JSON file if provided
$overrides = @{}
if ($OverridesPath -and (Test-Path -LiteralPath $OverridesPath)) {
    try {
        $ovRaw = Get-Content -LiteralPath $OverridesPath -Raw
        $ovObj = $ovRaw | ConvertFrom-Json
        if ($ovObj -and $ovObj.overrides) {
            $overrides = $ovObj.overrides
        }
    } catch {
        # ignore override parse errors
    }
}


$modeCfg = $modes.modes | Where-Object { $_.id -eq $Mode } | Select-Object -First 1
if (-not $modeCfg) {
    Write-Output "ProcessLabError=ModeNotFound"
    exit 1
}

# Simple helpers
function Get-IsLaptop {
    try {
        $batt = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        return ($null -ne $batt)
    } catch {
        return $false
    }
}

$svcHostKey = 'HKLM:\SYSTEM\CurrentControlSet\Control'
$svcHostPrev = $null
if (Test-Path $svcHostKey) {
    try {
        $obj = Get-ItemProperty -Path $svcHostKey -Name 'SvcHostSplitThresholdInKB' -ErrorAction SilentlyContinue
        if ($obj) { $svcHostPrev = [int64]$obj.SvcHostSplitThresholdInKB }
    } catch {}
}

# Take a dedicated Process Lab snapshot before touching anything
$backupDir    = Join-Path $projectRoot 'backups'
if (!(Test-Path $backupDir)) {
    try { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null } catch {}
}
$snapshotPath = Join-Path $backupDir 'processlab-services.json'

$svcStates = @()

foreach ($svcCfg in $catalog.services) {
    $name = $svcCfg.serviceName
    if (-not $name) { continue }

    try {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($null -ne $svc) {
            $svcStates += [PSCustomObject]@{
                serviceName = $svc.Name
                startType   = [string]$svc.StartType
                status      = [string]$svc.Status
            }
        }
    } catch {}
}

$snapshotObj = [PSCustomObject]@{
    mode                     = $Mode
    timestamp                = (Get-Date).ToString('s')
    services                 = $svcStates
    svcHostSplitThresholdInKB = $svcHostPrev
}

try {
    $snapshotObj | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $snapshotPath -Encoding UTF8
} catch {
    # If snapshot fails we still attempt to apply, but restore may not fully work.
}

# Helper: simple risk level mapping
function Get-RiskLevelValue([string]$risk) {
    switch ($risk) {
        'Danger'  { return 2 }
        'Warning' { return 1 }
        default   { return 0 }
    }
}

$maxRiskVal = Get-RiskLevelValue ([string]$modeCfg.maxRisk)

# Metrics
$isLaptop = Get-IsLaptop
$sessionId = 0
try {
    $sessionId = (Get-Process -Id $PID).SessionId
} catch {}
$procBefore = 0
try {
    if ($sessionId -ne 0) {
        $procBefore = (Get-Process | Where-Object { $_.SessionId -eq $sessionId }).Count
    } else {
        $procBefore = (Get-Process).Count
    }
} catch {}

$changedCount            = 0
$skippedHighRisk         = 0
$touchedBreaksStore      = 0
$touchedBreaksMsLogin    = 0
$touchedLaptopUnsafe     = 0

foreach ($svcCfg in $catalog.services) {
    $name = $svcCfg.serviceName
    if (-not $name) { continue }

    # Determine desired action for this mode (overrides win)
    $desired = $null

    # If overrides file specified a value for this service, use it
    try {
        if ($overrides -and $overrides.ContainsKey($name)) {
            $desired = [string]$overrides[$name]
        }
    } catch {}

    # Otherwise fall back to mode defaults
    if (-not $desired -and $svcCfg.defaultModes -and $svcCfg.defaultModes.$Mode) {
        $desired = [string]$svcCfg.defaultModes.$Mode
    }

    if (-not $desired -or $desired -eq 'unchanged') {
        continue
    }

    # Risk gating
    $riskVal = Get-RiskLevelValue ([string]$svcCfg.riskLevel)
    if ($riskVal -gt $maxRiskVal) {
        $skippedHighRisk++
        continue
    }

    # Laptop guard rails for non-extreme modes
    if ($isLaptop -and $Mode -ne 'extreme' -and $svcCfg.conditions -and $svcCfg.conditions.laptopUnsafe) {
        $touchedLaptopUnsafe++
        continue
    }

    # Track flags (for summary only – we still apply in competitive/extreme)
    if ($svcCfg.conditions) {
        if ($svcCfg.conditions.breaksMicrosoftStore) {
            $touchedBreaksStore++
        }
        if ($svcCfg.conditions.breaksMicrosoftAccountLogin) {
            $touchedBreaksMsLogin++
        }
        if ($svcCfg.conditions.laptopUnsafe -and $Mode -eq 'extreme') {
            $touchedLaptopUnsafe++
        }
    }

    try {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if (-not $svc) { continue }

        $currentStart = [string]$svc.StartType
        $currentStatus = [string]$svc.Status

        switch ($desired) {
            'disabled' {
                if ($currentStart -ne 'Disabled') {
                    try { Set-Service -Name $name -StartupType Disabled -ErrorAction SilentlyContinue } catch {}
                }
                if ($currentStatus -eq 'Running') {
                    try { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue } catch {}
                }
                $changedCount++
            }
            'manual' {
                if ($currentStart -ne 'Manual') {
                    try { Set-Service -Name $name -StartupType Manual -ErrorAction SilentlyContinue } catch {}
                }
                if ($currentStatus -eq 'Running' -and $Mode -eq 'extreme') {
                    # In extreme mode we also try to stop Manual services for extra trimming
                    try { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue } catch {}
                }
                $changedCount++
            }
            default {
                # future values: nothing for now
            }
        }
    } catch {
        # swallow individual service failures
        continue
    }
}

# Extra: optionally tighten SvcHostSplitThresholdInKB for more svchost merging
try {
    $desiredSvcHost = $null
    if ($Mode -eq 'safe') {
        $desiredSvcHost = 4294967295
    } elseif ($Mode -eq 'competitive') {
        $desiredSvcHost = 4294967295
    } elseif ($Mode -eq 'extreme') {
        $desiredSvcHost = 4294967295
    }

    if ($null -ne $desiredSvcHost) {
        if (-not (Test-Path $svcHostKey)) {
            New-Item -Path $svcHostKey -Force | Out-Null
        }
        New-ItemProperty -Path $svcHostKey -Name 'SvcHostSplitThresholdInKB' -Value $desiredSvcHost -PropertyType DWord -Force | Out-Null
    }
} catch {
    # ignore failures
}

$procAfter = $procBefore
try {
    if ($sessionId -ne 0) {
        $procAfter = (Get-Process | Where-Object { $_.SessionId -eq $sessionId }).Count
    } else {
        $procAfter = (Get-Process).Count
    }
} catch {}

$targetMin = 0
$targetMax = 0
try {
    if ($modeCfg.targetProcessRange -and $modeCfg.targetProcessRange.Count -ge 2) {
        $targetMin = [int]$modeCfg.targetProcessRange[0]
        $targetMax = [int]$modeCfg.targetProcessRange[1]
    }
} catch {}

$summary = @(
    "ProcessLabMode=$Mode",
    "ServicesChanged=$changedCount",
    "SkippedHighRisk=$skippedHighRisk",
    "UserSessionProcessCountBefore=$procBefore",
    "UserSessionProcessCountAfter=$procAfter",
    "TargetMin=$targetMin",
    "TargetMax=$targetMax",
    "TouchedBreaksStore=$touchedBreaksStore",
    "TouchedBreaksAccountLogin=$touchedBreaksMsLogin",
    "LaptopUnsafeTouched=$touchedLaptopUnsafe",
    "SnapshotPath=$snapshotPath"
) -join ';'

Write-Output $summary
exit 0
