Param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('backup','apply_safe','apply_performance','apply_latency','apply_extreme','restore','report','ensure_overrides')]
  [string]$Action
)

$ErrorActionPreference = 'Stop'

# StrictMode-safe global root (set by run-action.ps1, but we also guard here)
if (-not $Global:FalconRoot -or [string]::IsNullOrWhiteSpace($Global:FalconRoot)) {
  try {
    $Global:FalconRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
  } catch {
    $Global:FalconRoot = $PSScriptRoot
  }
}

$pd = Join-Path $env:ProgramData 'FalconOptimizer'
if (!(Test-Path $pd)) { New-Item -Path $pd -ItemType Directory -Force | Out-Null }

$backupFile    = Join-Path $pd 'service_lab_backup.json'
$reportFile    = Join-Path $pd 'service_lab_report.json'
$overridesFile = Join-Path $pd 'service_lab_overrides.json'

# Integrated service target list (merged from imported packs)
$TargetServices = @(
  'AarSvc',
  'ADPSvc',
  'AJRouter',
  'ALG',
  'AppMgmt',
  'AppReadiness',
  'AssignedAccessManagerSvc',
  'autotimesvc',
  'AxInstSV',
  'BcastDVRUserService',
  'BDESVC',
  'BITS',
  'BTAGService',
  'BthAvctpSvc',
  'bthserv',
  'CaptureService',
  'cbdhsvc',
  'CDPSvc',
  'CDPUserSvc',
  'CertPropSvc',
  'CloudBackupRestoreSvc',
  'COMSysApp',
  'ConsentUxUserSvc',
  'cphs',
  'cplspcon',
  'CscService',
  'dcsvc',
  'DeviceAssociationService',
  'DeviceInstall',
  'DevicePickerUserSvc',
  'DevicesFlowUserSvc',
  'DevQueryBroker',
  'diagsvc',
  'DiagTrack',
  'DispBrokerDesktopSvc',
  'DisplayEnhancementService',
  'DmEnrollmentSvc',
  'dmwappushservice',
  'dot3svc',
  'DPS',
  'DSAService',
  'DSAUpdateService',
  'DsmSvc',
  'DsSvc',
  'DusmSvc',
  'Eaphost',
  'edgeupdate',
  'edgeupdatem',
  'EFS',
  'esifsvc',
  'EventLog',
  'fdPHost',
  'FDResPub',
  'fhsvc',
  'FontCache',
  'FrameServer',
  'FrameServerMonitor',
  'GameInputSvc',
  'GraphicsPerfSvc',
  'hpatchmon',
  'HvHost',
  'iaStorAfsService',
  'ibtsiva',
  'icssvc',
  'igccservice',
  'IKEEXT',
  'InstallService',
  'IntelAudioService',
  'InventorySvc',
  'ipfsvc',
  'IpxlatCfgSvc',
  'jhi_service',
  'KtmRm',
  'LanmanServer',
  'LanmanWorkstation',
  'lfsvc',
  'LicenseManager',
  'lltdsvc',
  'lmhosts',
  'LMS',
  'LocalKdc',
  'LxpSvc',
  'MapsBroker',
  'McpManagementService',
  'MessagingService',
  'MicrosoftEdgeElevationService',
  'MSDTC',
  'MSiSCSI',
  'NaturalAuthentication',
  'NcaSvc',
  'NcbService',
  'NcdAutoSetup',
  'Netlogon',
  'Netman',
  'NetSetupSvc',
  'NetTcpPortSharing',
  'NlaSvc',
  'NPSMSvc',
  'OneSyncSvc',
  'p2pimsvc',
  'p2psvc',
  'P9RdrService',
  'PcaSvc',
  'PeerDistSvc',
  'PenService',
  'perceptionsimulation',
  'PerfHost',
  'PhoneSvc',
  'PimIndexMaintenanceSvc',
  'pla',
  'PNRPAutoReg',
  'PNRPsvc',
  'PolicyAgent',
  'PrintDeviceConfigurationService',
  'PrintNotify',
  'PrintScanBrokerService',
  'PushToInstall',
  'QWAVE',
  'RasAuto',
  'RasMan',
  'refsdedupsvc',
  'RemoteAccess',
  'RemoteRegistry',
  'RetailDemo',
  'RmSvc',
  'RpcLocator',
  'RstMwService',
  'SamSs',
  'SCardSvr',
  'ScDeviceEnum',
  'SCPolicySvc',
  'SDRSVC',
  'seclogon',
  'SEMgrSvc',
  'SENS',
  'Sense',
  'SensorDataService',
  'SensorService',
  'SensrSvc',
  'SessionEnv',
  'SharedAccess',
  'SharedRealitySvc',
  'ShellHWDetection',
  'shpamsvc',
  'smphost',
  'SmsRouter',
  'SNMPTrap',
  'Spooler',
  'SSDPSRV',
  'SstpSvc',
  'stisvc',
  'StorSvc',
  'svsvc',
  'SysMain',
  'SystemUsageReportSvc_QUEENCREEK',
  'TapiSrv',
  'TermService',
  'Themes',
  'TieringEngineService',
  'TokenBroker',
  'TrkWks',
  'TroubleshootingSvc',
  'TrustedInstaller',
  'tzautoupdate',
  'UevAgentService',
  'uhssvc',
  'UmRdpService',
  'UnistoreSvc',
  'upnphost',
  'UserDataSvc',
  'UsoSvc',
  'VaultSvc',
  'vds',
  'vmicguestinterface',
  'vmicheartbeat',
  'vmickvpexchange',
  'vmicrdv',
  'vmicshutdown',
  'vmictimesync',
  'vmicvmsession',
  'vmicvss',
  'W32Time',
  'WalletService',
  'WarpJITSvc',
  'wbengine',
  'WbioSrvc',
  'Wcmsvc',
  'wcncsvc',
  'WdiServiceHost',
  'WdiSystemHost',
  'WebClient',
  'webthreatdefsvc',
  'webthreatdefusersvc',
  'Wecsvc',
  'WEPHOSTSVC',
  'wercplsupport',
  'WerSvc',
  'WFDSConMgrSvc',
  'whesvc',
  'WiaRpc',
  'WinRM',
  'wisvc',
  'WlanSvc',
  'wlidsvc',
  'wlpasvc',
  'WManSvc',
  'wmiApSrv',
  'WMIRegistrationService',
  'WMPNetworkSvc',
  'workfolderssvc',
  'WpcMonSvc',
  'WPDBusEnum',
  'WpnService',
  'WpnUserService',
  'WSAIFabricSvc',
  'WSearch',
  'wuauserv',
  'WwanSvc',
  'XblAuthManager',
  'XblGameSave',
  'XboxGipSvc',
  'XboxNetApiSvc'
)

# Services required for Windows Update / driver installs (protected by default)
$UpdateCritical = @(
  'BITS',
  'CryptSvc',
  'DeviceInstall',
  'DsmSvc',
  'DoSvc',
  'InstallService',
  'msiserver',
  'TrustedInstaller',
  'UsoSvc',
  'WaaSMedicSvc',
  'wuauserv'
)

function Ensure-OverridesFile {
  if (!(Test-Path $overridesFile)) {
    $obj = @{
      created = (Get-Date).ToString('o')
      note = 'Set per-service custom overrides here. start: 2=Auto, 3=Manual, 4=Disabled. stop: true/false.'
      services = @{}
    }
    $obj | ConvertTo-Json -Depth 6 | Out-File -FilePath $overridesFile -Encoding UTF8 -Force
  }
}

function Load-Overrides {
  Ensure-OverridesFile
  try {
    return (Get-Content $overridesFile -Raw | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Get-ServiceStartType([string]$Name) {
  try {
    $p = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    $v = (Get-ItemProperty -Path $p -Name Start -ErrorAction Stop).Start
    return [int]$v
  } catch {
    return $null
  }
}

function Set-ServiceStartType([string]$Name, [int]$StartType) {
  $p = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
  if (!(Test-Path $p)) { return $false }
  Set-ItemProperty -Path $p -Name Start -Type DWord -Value $StartType -ErrorAction Stop | Out-Null
  return $true
}

function Stop-ServiceIfRunning([string]$Name) {
  try {
    $svc = Get-Service -Name $Name -ErrorAction Stop
    if ($svc.Status -eq 'Running') {
      Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
    }
  } catch {}
}

function Ensure-RestorePoint {
  try {
    Checkpoint-Computer -Description "FalconOptimizer Service Lab" -RestorePointType "MODIFY_SETTINGS" | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Expand-TargetNames([string]$BaseName) {
  # Handles per-user instance services like CDPUserSvc_1234
  $names = @()
  # exact first
  if (Get-ServiceStartType $BaseName -ne $null) {
    $names += $BaseName
    return $names
  }

  # try registry exact name didn't exist; look for instance names
  try {
    $all = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName
    $prefix = $BaseName + '_'
    $inst = $all | Where-Object { $_.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase) }
    foreach ($n in $inst) {
      $names += $n
    }
  } catch {}

  return $names
}

if ($Action -eq 'ensure_overrides') {
  Ensure-OverridesFile
  Write-Output "Overrides file ensured: $overridesFile"
  exit 0
}

if ($Action -eq 'backup') {
  Ensure-OverridesFile
  $rp = Ensure-RestorePoint
  $snap = [ordered]@{
    created = (Get-Date).ToString('o')
    restorePointAttempted = $true
    restorePointCreated = $rp
    services = @{}
  }

  $count = 0
  foreach ($base in $TargetServices) {
    foreach ($name in (Expand-TargetNames $base)) {
      $st = Get-ServiceStartType $name
      if ($st -ne $null) {
        $snap.services[$name] = $st
        $count++
      }
    }
  }
  $snap | ConvertTo-Json -Depth 6 | Out-File -FilePath $backupFile -Encoding UTF8 -Force
  Write-Output "Backup saved: $backupFile"
  Write-Output ("Captured 0 service start types." -f $count)
  if ($rp) { Write-Output "Restore point created." } else { Write-Output "Restore point not created (System Protection may be off)." }
  exit 0
}

function Apply-Preset([string]$Preset) {
  Ensure-OverridesFile

  if (!(Test-Path $backupFile)) {
    Write-Output "No backup found. Creating one now..."
    & $PSCommandPath -Action backup | Out-Null
  }

  $ov = Load-Overrides
  $ovMap = @{}
  if ($ov -and $ov.services) {
    foreach ($p in $ov.services.PSObject.Properties) {
      $ovMap[$p.Name] = $p.Value
    }
  }

  $safe = ($Preset -ne 'extreme')
  $disabled = 0
  $skippedCritical = 0
  $customApplied = 0
  $errors = 0

  foreach ($base in $TargetServices) {
    $targets = Expand-TargetNames $base
    foreach ($name in $targets) {
      try {
        # Determine desired start type
        $desired = 4

        # Protected services in safe modes
        if ($safe -and ($UpdateCritical -contains $name -or $UpdateCritical -contains $base)) {
          $skippedCritical++
          continue
        }

        # Custom override wins
        if ($ovMap.ContainsKey($name)) {
          $entry = $ovMap[$name]
          if ($entry.start -ne $null) {
            $desired = [int]$entry.start
          }
          if ($entry.stop -eq $true) {
            Stop-ServiceIfRunning $name
          }
          $customApplied++
        } elseif ($ovMap.ContainsKey($base)) {
          $entry = $ovMap[$base]
          if ($entry.start -ne $null) {
            $desired = [int]$entry.start
          }
          if ($entry.stop -eq $true) {
            Stop-ServiceIfRunning $name
          }
          $customApplied++
        } else {
          # Preset start types (currently all disable; future: performance/latency can vary)
          Stop-ServiceIfRunning $name
        }

        $ok = Set-ServiceStartType $name $desired
        if ($ok -and $desired -eq 4) { $disabled++ }
      } catch {
        $errors++
      }
    }
  }

  Write-Output ("Applied Service Preset: 0" -f $Preset)
  Write-Output ("Disabled set: 0" -f $disabled)
  if ($safe) { Write-Output ("Skipped update/driver-critical: 0" -f $skippedCritical) }
  Write-Output ("Custom overrides applied (count): 0" -f $customApplied)
  if ($errors -gt 0) { Write-Output ("Non-fatal errors: 0" -f $errors) }
  Write-Output "Reboot recommended."
}

if ($Action -eq 'apply_safe') {
  Apply-Preset 'update_safe'
  exit 0
}
if ($Action -eq 'apply_performance') {
  Apply-Preset 'performance'
  exit 0
}
if ($Action -eq 'apply_latency') {
  Apply-Preset 'latency'
  exit 0
}
if ($Action -eq 'apply_extreme') {
  Apply-Preset 'extreme'
  exit 0
}

if ($Action -eq 'restore') {
  if (!(Test-Path $backupFile)) {
    Write-Output "No backup file found: $backupFile"
    exit 1
  }
  $snap = Get-Content $backupFile -Raw | ConvertFrom-Json
  $restored = 0
  foreach ($p in $snap.services.PSObject.Properties) {
    $name = $p.Name
    $start = [int]$p.Value
    try {
      $ok = Set-ServiceStartType $name $start
      if ($ok) { $restored++ }
    } catch {}
  }
  Write-Output "Restored start types for $restored services from backup."
  Write-Output "Reboot recommended."
  exit 0
}

if ($Action -eq 'report') {
  Ensure-OverridesFile
  $rep = [ordered]@{ created = (Get-Date).ToString('o'); updateCritical = $UpdateCritical; services = @() }
  foreach ($base in $TargetServices) {
    $targets = Expand-TargetNames $base
    foreach ($s in $targets) {
      $st = Get-ServiceStartType $s
      $status = $null
      try { $status = (Get-Service -Name $s -ErrorAction Stop).Status.ToString() } catch {}
      $rep.services += [ordered]@{ name=$s; base=$base; start=$st; status=$status; protected=([bool]($UpdateCritical -contains $s -or $UpdateCritical -contains $base)) }
    }
  }
  $rep | ConvertTo-Json -Depth 7 | Out-File -FilePath $reportFile -Encoding UTF8 -Force
  Write-Output "Report written: $reportFile"
  Write-Output "Overrides file: $overridesFile"
  exit 0
}

Write-Output "Unknown action: $Action"
exit 1
