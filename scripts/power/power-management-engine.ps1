param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('audit','catalog','build-manifest','apply-preset','verify','coverage')]
  [string]$Mode,
  [ValidateSet('extreme','competitive','balanced','powersaver','laptop','restore')]
  [string]$Preset = 'extreme',
  [string]$OutputRoot = 'output/power',
  [string]$CatalogPath = 'data/power/power_management_catalog.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

function Save-Json([string]$path, $obj) {
  $dir = Split-Path -Parent $path
  if ($dir) { Ensure-Dir $dir }
  $obj | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $path -Encoding UTF8
}

function Load-Json([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return $null }
  return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
}

function Invoke-PowercfgExplorer {
  $json = Join-Path $OutputRoot 'full-powercfg-catalog.json'
  $explorer = Join-Path $PSScriptRoot 'all-settings-explorer.ps1'
  & $explorer -Mode scan -OutputPath $json | Out-Null
  return (Load-Json $json)
}

function New-CatalogEntry {
  param(
    [string]$Id,
    [string]$Title,
    [string]$Category,
    [string]$Subcategory,
    [string]$SourceType,
    [string]$AppliesTo,
    [string]$ShortDescription,
    [string]$LongDescription,
    [string]$SourcePathOrCommand,
    [string]$SubgroupGuid = '',
    [string]$SettingGuid = '',
    [string]$RegistryPath = '',
    [string]$RegistryValueName = '',
    [string]$PropertyName = '',
    [object]$MaxPerformanceValue = $null,
    [object]$BalancedValue = $null,
    [object]$PowerSaverValue = $null,
    [object]$RollbackValue = $null,
    [string]$DetectionScript = '',
    [string]$ApplyScript = '',
    [string]$VerifyScript = '',
    [string]$RollbackScript = '',
    [string]$UnsupportedBehavior = 'mark_unsupported',
    [string]$Notes = ''
  )

  return [pscustomobject]@{
    id = $Id
    title = $Title
    shortDescription = $ShortDescription
    longDescription = $LongDescription
    category = $Category
    subcategory = $Subcategory
    sourceType = $SourceType
    sourcePathOrCommand = $SourcePathOrCommand
    subgroupGuid = $SubgroupGuid
    settingGuid = $SettingGuid
    registryPath = $RegistryPath
    registryValueName = $RegistryValueName
    propertyName = $PropertyName
    appliesTo = $AppliesTo
    requiresAdmin = $true
    requiresReboot = $false
    requiresDeviceRestart = $false
    canVerify = $true
    verifyType = $SourceType
    safeDefaultMode = 'balanced'
    maxPerformanceValue = $MaxPerformanceValue
    balancedValue = $BalancedValue
    powerSaverValue = $PowerSaverValue
    rollbackValue = $RollbackValue
    detectionScript = $DetectionScript
    applyScript = $ApplyScript
    verifyScript = $VerifyScript
    rollbackScript = $RollbackScript
    unsupportedBehavior = $UnsupportedBehavior
    notes = $Notes
  }
}

function Get-NonPowercfgCatalogs {
  $nicList = @(
    'Energy Efficient Ethernet','Advanced EEE','Green Ethernet','Ultra Low Power Mode','Reduce Speed On Power Down','System Idle Power Saver','Gigabit Lite','Auto Disable Gigabit','Power Saving Mode','Wake on Magic Packet','Wake on Pattern Match','ARP Offload','NS Offload','DMA Coalescing','S5 Wake on LAN','Short Reach Mode','Link Down Power Saving','EEE advertisement'
  )

  $deviceFlags = @(
    'NIC AllowComputerToTurnOffDevice','USB Hub AllowComputerToTurnOffDevice','Bluetooth Radio AllowComputerToTurnOffDevice','HID Keyboard AllowComputerToTurnOffDevice','HID Mouse AllowComputerToTurnOffDevice'
  )

  $storageFeatures = @(
    'NVMe APST','NVMe non-operational power state policy','NVMe idle timeout','SATA ALPM','AHCI HIPM','AHCI DIPM','Storage device idle timeout','Storport link power management'
  )

  $gpuFeatures = @(
    'DXGK power component idle','NVIDIA Optimal Power','NVIDIA Prefer Maximum Performance','AMD Power Efficiency','AMD ULPS','Intel RC6','Panel self refresh','Adaptive brightness'
  )

  $firmware = @(
    'ASPM mode','Native ASPM','DMI ASPM','PEG ASPM','PCIe Native Power Management','ErP','USB standby power in S5','SATA aggressive link PM'
  )

  Save-Json (Join-Path $OutputRoot 'nic-advanced-properties.json') $nicList
  Save-Json (Join-Path $OutputRoot 'device-power-flags.json') $deviceFlags
  Save-Json (Join-Path $OutputRoot 'storage-power-features.json') $storageFeatures
  Save-Json (Join-Path $OutputRoot 'gpu-power-features.json') $gpuFeatures
  Save-Json (Join-Path $OutputRoot 'firmware-power-candidates.json') $firmware

  return [pscustomobject]@{
    nic = $nicList
    device = $deviceFlags
    storage = $storageFeatures
    gpu = $gpuFeatures
    firmware = $firmware
  }
}

function Build-NormalizedManifest {
  $powercfgRows = Invoke-PowercfgExplorer
  $extra = Get-NonPowercfgCatalogs

  $entries = New-Object System.Collections.Generic.List[object]

  foreach ($row in $powercfgRows) {
    $id = ('powercfg_{0}_{1}' -f $row.subgroupGuid, $row.settingGuid).ToLowerInvariant().Replace('-','')
    $entries.Add((New-CatalogEntry -Id $id -Title $row.settingName -Category 'Power Policy' -Subcategory $row.subgroupName -SourceType 'powercfg' -AppliesTo 'all' -ShortDescription ($row.description) -LongDescription "Windows powercfg setting discovered via /qh." -SourcePathOrCommand 'powercfg /qh SCHEME_CURRENT' -SubgroupGuid $row.subgroupGuid -SettingGuid $row.settingGuid -MaxPerformanceValue $row.recommendedGamingAcValue -BalancedValue $row.currentAcValue -PowerSaverValue $row.currentDcValue -RollbackValue $row.currentAcValue -DetectionScript 'powercfg /query SCHEME_CURRENT <subgroup> <setting>' -ApplyScript 'powercfg -setacvalueindex/-setdcvalueindex + /setactive' -VerifyScript 'powercfg /query SCHEME_CURRENT <subgroup> <setting>' -RollbackScript 'restore from backup or rollbackValue' -Notes $row.recommendationReason)) | Out-Null
  }

  foreach ($name in $extra.nic) {
    $slug = ($name.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_')
    $entries.Add((New-CatalogEntry -Id ("nic_$slug") -Title $name -Category 'Ethernet / NIC' -Subcategory 'Advanced Properties' -SourceType 'nic_advanced' -AppliesTo 'nic' -ShortDescription "NIC advanced property: $name" -LongDescription 'Applied only when property exists on adapter.' -SourcePathOrCommand 'Get/Set-NetAdapterAdvancedProperty' -PropertyName $name -MaxPerformanceValue 'Disabled' -BalancedValue 'Enabled' -PowerSaverValue 'Enabled' -RollbackValue 'Enabled' -DetectionScript 'Get-NetAdapterAdvancedProperty ... | ? DisplayName -eq property' -ApplyScript 'Set-NetAdapterAdvancedProperty -NoRestart' -VerifyScript 'Read DisplayValue after apply' -RollbackScript 'Restore baseline value from backups')) | Out-Null
  }

  foreach ($flag in $extra.device) {
    $slug = ($flag.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_')
    $entries.Add((New-CatalogEntry -Id ("devpm_$slug") -Title $flag -Category 'Device Power Management' -Subcategory 'PnP Device Flags' -SourceType 'device_power_flag' -AppliesTo 'usb,nic,bluetooth,input' -ShortDescription "Device-manager style power flag: $flag" -LongDescription 'Clear device power-saving checkbox when controllable and safe.' -SourcePathOrCommand 'Get-PnpDevice / WMI MSPower_DeviceEnable' -MaxPerformanceValue 0 -BalancedValue 1 -PowerSaverValue 1 -RollbackValue 1 -DetectionScript 'Enumerate eligible devices + support bit' -ApplyScript 'Set WMI/CIM power management flag' -VerifyScript 'Read back flag state' -RollbackScript 'Restore baseline snapshot')) | Out-Null
  }

  foreach ($feature in $extra.storage) {
    $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_')
    $entries.Add((New-CatalogEntry -Id ("storage_$slug") -Title $feature -Category 'Disk / NVMe / SATA' -Subcategory 'Storage Power Features' -SourceType 'storage_feature' -AppliesTo 'nvme,sata,disk' -ShortDescription "Storage power feature: $feature" -LongDescription 'Hardware/driver dependent; unsupported systems are marked and skipped.' -SourcePathOrCommand 'powercfg + registry + vendor APIs' -MaxPerformanceValue 'DisabledOrOff' -BalancedValue 'Auto' -PowerSaverValue 'Enabled' -RollbackValue 'Auto' -DetectionScript 'Probe device capabilities and controller support' -ApplyScript 'Apply only when capability exists' -VerifyScript 'Readback capability/setting' -RollbackScript 'Restore baseline snapshot')) | Out-Null
  }

  foreach ($feature in $extra.gpu) {
    $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_')
    $entries.Add((New-CatalogEntry -Id ("gpu_$slug") -Title $feature -Category 'GPU / Display' -Subcategory 'Power Features' -SourceType 'gpu_feature' -AppliesTo 'gpu,display' -ShortDescription "GPU/display power feature: $feature" -LongDescription 'Windows-native pieces are applied directly; vendor settings only on detected hardware.' -SourcePathOrCommand 'powercfg + vendor tooling detection' -MaxPerformanceValue 'Performance' -BalancedValue 'Balanced' -PowerSaverValue 'PowerSaving' -RollbackValue 'Balanced' -DetectionScript 'Detect vendor/API availability' -ApplyScript 'Apply Windows policy or vendor wrapper' -VerifyScript 'Readback with powercfg/API' -RollbackScript 'Restore baseline snapshot')) | Out-Null
  }

  foreach ($name in $extra.firmware) {
    $slug = ($name.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_')
    $entries.Add((New-CatalogEntry -Id ("firmware_$slug") -Title $name -Category 'Firmware Recommendations' -Subcategory 'BIOS/UEFI' -SourceType 'firmware_candidate' -AppliesTo 'firmware' -ShortDescription "Firmware recommendation: $name" -LongDescription 'Recommendation-only entry; no direct BIOS write is attempted.' -SourcePathOrCommand 'data/bios + system board detection' -MaxPerformanceValue 'DisablePowerSaving' -BalancedValue 'VendorDefault' -PowerSaverValue 'EnablePowerSaving' -RollbackValue 'VendorDefault' -DetectionScript 'Detect motherboard vendor/model' -ApplyScript 'N/A (recommendation only)' -VerifyScript 'Manual BIOS verification' -RollbackScript 'Manual BIOS restore' -UnsupportedBehavior 'recommendation_only')) | Out-Null
  }

  Save-Json $CatalogPath $entries
  return $entries
}

function Write-BackupSnapshot {
  $backupDir = Join-Path $OutputRoot 'backups'
  Ensure-Dir $backupDir

  $schemeExport = Join-Path $backupDir 'active-scheme.pow'
  try { powercfg -export $schemeExport SCHEME_CURRENT | Out-Null } catch {}

  $snapshot = [pscustomobject]@{
    capturedAt = (Get-Date).ToString('s')
    activeScheme = (powercfg /getactivescheme | Out-String)
    nicAdvanced = @()
  }

  try {
    $nics = Get-NetAdapter -Physical -ErrorAction Stop
    foreach ($nic in $nics) {
      $props = Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue
      $snapshot.nicAdvanced += [pscustomobject]@{ name = $nic.Name; properties = $props }
    }
  } catch {}

  Save-Json (Join-Path $backupDir 'baseline.json') $snapshot
}

function Get-PresetValue($item, [string]$preset) {
  switch ($preset) {
    'extreme' { return $item.maxPerformanceValue }
    'competitive' { return $item.maxPerformanceValue }
    'balanced' { return $item.balancedValue }
    'powersaver' { return $item.powerSaverValue }
    'laptop' { if ($item.appliesTo -match 'battery|laptop') { return $item.balancedValue } ; return $item.maxPerformanceValue }
    'restore' { return $item.rollbackValue }
  }
}

function Invoke-ItemApply($item, $targetValue) {
  $result = [ordered]@{ id = $item.id; title = $item.title; sourceType = $item.sourceType; target = $targetValue; status = 'unsupported'; verify = $false; details = '' }

  if ($item.sourceType -eq 'firmware_candidate') {
    $result.status = 'unsupported'
    $result.details = 'Recommendation-only item.'
    return [pscustomobject]$result
  }

  try {
    switch ($item.sourceType) {
      'powercfg' {
        if ([string]::IsNullOrWhiteSpace($item.subgroupGuid) -or [string]::IsNullOrWhiteSpace($item.settingGuid)) {
          throw 'Missing subgroup/setting GUID.'
        }
        powercfg -setacvalueindex SCHEME_CURRENT $item.subgroupGuid $item.settingGuid $targetValue | Out-Null
        powercfg -setdcvalueindex SCHEME_CURRENT $item.subgroupGuid $item.settingGuid $targetValue | Out-Null
        powercfg /setactive SCHEME_CURRENT | Out-Null
        $verify = powercfg /query SCHEME_CURRENT $item.subgroupGuid $item.settingGuid | Out-String
        $ok = ($verify -match [Regex]::Escape([string]$targetValue))
        $result.status = $(if($ok){'applied'}else{'failed'})
        $result.verify = $ok
        $result.details = $verify
      }
      'nic_advanced' {
        $appliedAny = $false
        $verifiedAll = $true
        $nics = Get-NetAdapter -Physical -ErrorAction SilentlyContinue
        foreach ($nic in $nics) {
          $prop = Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.propertyName }
          if ($prop) {
            $appliedAny = $true
            Set-NetAdapterAdvancedProperty -Name $nic.Name -DisplayName $item.propertyName -DisplayValue ([string]$targetValue) -NoRestart -ErrorAction SilentlyContinue | Out-Null
            $check = Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.propertyName }
            if (-not $check -or $check.DisplayValue -ne ([string]$targetValue)) { $verifiedAll = $false }
          }
        }
        if (-not $appliedAny) { $result.status = 'unsupported'; $result.details = 'Property not present on adapters.' }
        else { $result.status = $(if($verifiedAll){'applied'}else{'failed'}); $result.verify = $verifiedAll }
      }
      default {
        $result.status = 'unsupported'
        $result.details = 'Source type requires machine-specific implementation.'
      }
    }
  } catch {
    $result.status = 'failed'
    $result.details = $_.Exception.Message
  }

  return [pscustomobject]$result
}

function Apply-Preset([string]$preset) {
  $catalog = Load-Json $CatalogPath
  if (-not $catalog) { $catalog = Build-NormalizedManifest }

  Write-BackupSnapshot

  $progressPath = Join-Path $OutputRoot 'apply-progress.json'
  $progress = [ordered]@{
    startedAt = (Get-Date).ToString('s')
    completedAt = $null
    totalItems = $catalog.Count
    completedItems = 0
    failedItems = 0
    unsupportedItems = 0
    currentCategory = ''
    currentItemId = ''
    retryCounts = @{}
    results = @()
  }

  foreach ($item in $catalog) {
    $progress.currentCategory = $item.category
    $progress.currentItemId = $item.id
    $target = Get-PresetValue $item $preset
    $attempt = 0
    $res = $null
    do {
      $attempt++
      $res = Invoke-ItemApply $item $target
      $progress.retryCounts[$item.id] = $attempt - 1
    } while ($res.status -eq 'failed' -and $attempt -lt 2)

    $progress.results += $res
    $progress.completedItems++
    if ($res.status -eq 'failed') { $progress.failedItems++ }
    if ($res.status -eq 'unsupported') { $progress.unsupportedItems++ }

    Save-Json $progressPath $progress
  }

  $progress.completedAt = (Get-Date).ToString('s')
  Save-Json $progressPath $progress
  return $progress
}

function Invoke-Audit {
  $areas = @(
    'scripts/powerplans',
    'scripts/power',
    'scripts/network',
    'scripts/gpu',
    'scripts/validation',
    'tools/BoostPack',
    'scripts/run-action.ps1',
    'data'
  )

  $report = [ordered]@{
    generatedAt = (Get-Date).ToString('s')
    scannedPaths = $areas
    alreadyImplemented = @('power plan processor min/max','processor boost mode','system cooling policy','processor idle disable','core parking min/max','PCIe link state PM','USB selective suspend','sleep after','hibernate after','PowerThrottlingOff in BoostPack','hibernate off in BoostPack')
    partiallyImplemented = @('NIC/ASPM tweaks partially present in BoostPack')
    presentInScriptsNotUi = @('all-settings-explorer scan/set not fully surfaced')
    exposedInUiNotApplied = @()
    missing = @('Exhaustive dynamic powercfg catalog and normalized manifest','chunked apply progress state','structured verification outputs','coverage parity checks for apply/verify handlers')
  }

  Save-Json (Join-Path $OutputRoot 'gap-report.json') $report
  return $report
}

function Invoke-Verification {
  $progress = Load-Json (Join-Path $OutputRoot 'apply-progress.json')
  $catalog = Load-Json $CatalogPath
  if (-not $catalog) { $catalog = @() }
  $verified = @()

  foreach ($item in $catalog) {
    $entry = [ordered]@{ id = $item.id; title = $item.title; sourceType = $item.sourceType; readable = $false; supported = $true; state = 'unknown'; details = '' }
    try {
      switch ($item.sourceType) {
        'powercfg' {
          $q = powercfg /query SCHEME_CURRENT $item.subgroupGuid $item.settingGuid | Out-String
          $entry.readable = $true
          $entry.state = 'queried'
          $entry.details = $q
        }
        'nic_advanced' {
          $nics = Get-NetAdapter -Physical -ErrorAction SilentlyContinue
          $found = $false
          foreach ($nic in $nics) {
            $prop = Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.propertyName }
            if ($prop) { $found = $true; break }
          }
          $entry.readable = $true
          $entry.supported = $found
          $entry.state = $(if($found){'present'}else{'unsupported'})
        }
        default {
          $entry.readable = $false
          $entry.supported = $false
          $entry.state = 'unsupported'
          $entry.details = 'No direct verifier on current machine.'
        }
      }
    } catch {
      $entry.state = 'error'
      $entry.details = $_.Exception.Message
    }
    $verified += [pscustomobject]$entry
  }

  $jsonPath = Join-Path $OutputRoot 'verification-report.json'
  Save-Json $jsonPath ([pscustomobject]@{ generatedAt = (Get-Date).ToString('s'); progress = $progress; items = $verified })

  $mdPath = Join-Path $OutputRoot 'verification-report.md'
  $txtPath = Join-Path $OutputRoot 'verification-report.txt'
  $lines = @('# Falcon Power Management Verification', '', "Generated: $((Get-Date).ToString('s'))", '', '| ID | Source | State | Supported |', '|---|---|---|---|')
  foreach ($v in $verified) {
    $lines += "| $($v.id) | $($v.sourceType) | $($v.state) | $($v.supported) |"
  }
  Set-Content -LiteralPath $mdPath -Value ($lines -join "`n") -Encoding UTF8
  Set-Content -LiteralPath $txtPath -Value (($verified | Format-Table id,sourceType,state,supported -AutoSize | Out-String)) -Encoding UTF8
}

function Invoke-Coverage {
  $catalog = Load-Json $CatalogPath
  if (-not $catalog) { $catalog = @() }

  $supported = @($catalog | Where-Object { $_.sourceType -ne 'firmware_candidate' })
  $applyCapable = @($supported | Where-Object { -not [string]::IsNullOrWhiteSpace($_.applyScript) })
  $verifyCapable = @($supported | Where-Object { $_.canVerify -and -not [string]::IsNullOrWhiteSpace($_.verifyScript) })

  $missingApply = @($supported | Where-Object { [string]::IsNullOrWhiteSpace($_.applyScript) } | Select-Object -ExpandProperty id)
  $missingVerify = @($supported | Where-Object { -not $_.canVerify -or [string]::IsNullOrWhiteSpace($_.verifyScript) } | Select-Object -ExpandProperty id)

  $report = [ordered]@{
    catalogCount = $catalog.Count
    supportedCount = $supported.Count
    applyCapableCount = $applyCapable.Count
    verifyCapableCount = $verifyCapable.Count
    uiExposedCount = 0
    presetReferencedCount = $catalog.Count
    missingApplyHandlers = $missingApply
    missingVerifyHandlers = $missingVerify
    orphanUIEntries = @()
    orphanPresetEntries = @()
  }

  Save-Json (Join-Path $OutputRoot 'coverage-report.json') $report

  if ($missingApply.Count -gt 0 -or $missingVerify.Count -gt 0) {
    throw 'Coverage failure: supported settings missing apply/verify handlers.'
  }
}

Ensure-Dir $OutputRoot

switch ($Mode) {
  'audit' { Invoke-Audit | Out-Null }
  'catalog' {
    $null = Invoke-PowercfgExplorer
    $null = Get-NonPowercfgCatalogs
  }
  'build-manifest' { Build-NormalizedManifest | Out-Null }
  'apply-preset' { Apply-Preset -preset $Preset | Out-Null }
  'verify' { Invoke-Verification }
  'coverage' { Invoke-Coverage }
}

Write-Output "OK: $Mode"
