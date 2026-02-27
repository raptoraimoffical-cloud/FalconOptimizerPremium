$ErrorActionPreference = 'SilentlyContinue'

# Resolve paths
$scriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot

$backupDir    = Join-Path $projectRoot 'backups'
$snapshotPath = Join-Path $backupDir 'processlab-services.json'

if (!(Test-Path $snapshotPath)) {
    Write-Output "ProcessLabRestore=NoSnapshot"
    exit 0
}

try {
    $snapshot = Get-Content $snapshotPath -Raw | ConvertFrom-Json
} catch {
    Write-Output "ProcessLabRestore=InvalidSnapshot"
    exit 1
}

if (-not $snapshot.services) {
    Write-Output "ProcessLabRestore=NoServicesInSnapshot"
    exit 0
}

# Restore service startup types + running state
$restoredCount = 0
foreach ($svcInfo in $snapshot.services) {
    $name      = $svcInfo.serviceName
    $startType = [string]$svcInfo.startType
    $status    = [string]$svcInfo.status

    if (-not $name) { continue }

    try {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if (-not $svc) { continue }

        # Restore startup type if we have a meaningful value
        if ($startType -and $startType -ne '') {
            try {
                switch ($startType) {
                    'Disabled'  { Set-Service -Name $name -StartupType Disabled -ErrorAction SilentlyContinue }
                    'Manual'    { Set-Service -Name $name -StartupType Manual   -ErrorAction SilentlyContinue }
                    'Automatic' { Set-Service -Name $name -StartupType Automatic -ErrorAction SilentlyContinue }
                    default     { }
                }
            } catch {}
        }

        # Restore running / stopped state
        if ($status -eq 'Running') {
            try { Start-Service -Name $name -ErrorAction SilentlyContinue } catch {}
        } elseif ($status -eq 'Stopped') {
            try { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue } catch {}
        }

        $restoredCount++
    } catch {
        # ignore per-service failures
        continue
    }
}

# Restore SvcHostSplitThresholdInKB if we captured it
$svcHostKey = 'HKLM:\SYSTEM\CurrentControlSet\Control'
if ($null -ne $snapshot.svcHostSplitThresholdInKB) {
    try {
        $val = [int64]$snapshot.svcHostSplitThresholdInKB
        if (-not (Test-Path $svcHostKey)) {
            New-Item -Path $svcHostKey -Force | Out-Null
        }
        New-ItemProperty -Path $svcHostKey -Name 'SvcHostSplitThresholdInKB' -Value $val -PropertyType DWord -Force | Out-Null
    } catch {
        # ignore restore errors for this key
    }
}

Write-Output ("ProcessLabRestore=OK;ServicesRestored={0}" -f $restoredCount)
exit 0
