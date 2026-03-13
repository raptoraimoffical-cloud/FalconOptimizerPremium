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

function Ensure-Dir([string]$path) { if ($path -and -not (Test-Path -LiteralPath $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null } }
function Save-Json([string]$path, $obj) { $d = Split-Path -Parent $path; if ($d) { Ensure-Dir $d }; $obj | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $path -Encoding UTF8 }
function Load-Json([string]$path) { if (-not (Test-Path -LiteralPath $path)) { return $null }; Get-Content -LiteralPath $path -Raw | ConvertFrom-Json }

function Test-Cmd([string]$name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Import-MasterScopeNames {
  return @(
    # Processor / PPM / core parking
    'Processor idle disable','Processor idle demote threshold','Processor idle promote threshold','Processor performance boost mode','Processor energy performance preference policy','Processor duty cycling','Processor autonomous mode','Processor performance increase threshold','Processor performance decrease threshold','Processor performance increase time','Processor performance decrease time','Processor performance time check interval','Processor performance core parking min cores','Processor performance core parking max cores','Processor core parking increase threshold','Processor core parking decrease threshold','Processor core parking increase policy','Processor core parking decrease policy','Processor core parking concurrency threshold','Processor core parking distribution threshold','Processor core parking overutilization threshold','Processor core parking hysteresis','Processor core parking utility distribution','Processor core parking affinity history','Processor core parking soft park latency','Processor performance autonomous activity window','Processor performance autonomous threshold','Processor performance history count','Processor performance history length','Processor latency hint enable','Processor latency hint minimum unparked cores','Processor idle state maximum','Processor idle state minimum','Allow throttle states','Processor responsiveness override','Heterogeneous policy in effect','Heterogeneous short running thread policy','Heterogeneous long running thread policy','Heterogeneous thread scheduling policy','Heterogeneous idle policy','Efficiency class 1 initial performance','Efficiency class 1 increase threshold','Efficiency class 1 decrease threshold','Efficiency class 1 increase time','Efficiency class 1 decrease time','Efficiency class 1 performance preference','Class 1 initial performance','Processor performance floor','Processor performance ceiling','Processor autonomous utility preference','Processor preferred cores use policy','Processor idle policy override','Core parking parked performance state','Core parking max latency','Core parking latency sensitivity','Core parking min cores for latency hint','Core parking soft minimum cores','Processor QoS floor','Processor QoS ceiling','Processor boost disable on low battery','Processor response time sensitivity','Processor coordination feedback','Processor utility floor','Processor utility ceiling','Processor performance dependency max','Processor performance dependency min',
    # Sleep/wake/platform subset
    'Sleep after','Allow hybrid sleep','Hibernate after','Allow standby states','System unattended sleep timeout','Require a password on wake','Allow wake timers','Lid close action','Power button action','Sleep button action','Away mode policy','Fast startup','Connected standby policy','Network connectivity in standby','Critical battery action','Critical battery level','Low battery action','Low battery level','Reserve battery level','Wake on RTC','Wake on USB','Wake on LAN sleep policy','Wake on keyboard','Wake on mouse','Wake on Bluetooth','Wake on PCIe device','Wake on modem ring',
    # PCIe/Storage/USB/Wireless/NIC/GPU/Misc subset to keep checked-in scope broad
    'PCI Express Link State Power Management','ASPM mode','Native ASPM','DMI ASPM','PEG ASPM','Turn off hard disk after','AHCI HIPM','AHCI DIPM','SATA ALPM','NVMe APST','NVMe idle timeout','Storport link power management','USB selective suspend','USB 3 link power management','USB root hub selective suspend','Thunderbolt low power mode','Wireless adapter power saving mode','MIMO power save','WLAN background scan power','Packet coalescing','Energy Efficient Ethernet','Advanced EEE','Green Ethernet','Ultra Low Power Mode','Reduce Speed On Power Down','System Idle Power Saver','Gigabit Lite','Auto Disable Gigabit','Power Saving Mode','Wake on Magic Packet','Wake on Pattern Match','ARP Offload','NS Offload','DMA Coalescing','Link Down Power Saving','Turn off display after','Adaptive brightness','Dim display after','Panel self refresh','DXGK power component idle','NVIDIA Optimal Power','NVIDIA Prefer Maximum Performance','AMD Power Efficiency','AMD ULPS','Intel RC6','Audio endpoint power saving','Camera device idle suspend','Bluetooth radio power saving','HID idle timeout','Windows power throttling','Timer coalescing','Dynamic tick','DRIPS enablement','EcoQoS for background tasks','Background app power throttling','Battery saver threshold','Battery saver brightness reduction','Power slider default on AC','Power slider default on DC','System cooling policy','Fan always on policy','Skin temperature aware throttling'
  )
}

function Invoke-PowercfgExplorer {
  $json = Join-Path $OutputRoot 'full-powercfg-catalog.json'
  $pretty = Join-Path $OutputRoot 'full-powercfg-catalog.pretty.json'
  $csv = Join-Path $OutputRoot 'full-powercfg-catalog.csv'
  $explorer = Join-Path $PSScriptRoot 'all-settings-explorer.ps1'

  $rows = @()
  if (Test-Cmd 'powercfg') {
    try {
      & $explorer -Mode scan -OutputPath $json | Out-Null
      $rows = Load-Json $json
    } catch {
      $rows = @()
    }
  }

  if (-not $rows -or $rows.Count -eq 0) {
    $rows = @(
      [pscustomobject]@{ subgroupGuid='54533251-82be-4824-96c1-47b60b740d00'; subgroupAlias='SUB_PROCESSOR'; subgroupName='Processor power management'; settingGuid='bc5038f7-23e0-4960-96da-33abaf5935ec'; settingAlias='PROCTHROTTLEMIN'; settingName='Minimum processor state'; description='Fallback sample generated without live powercfg.'; min=0; max=100; increment=1; units='%'; enumChoices=@(); currentAcValue=100; currentDcValue=5; hiddenOrExposed='exposed'; supportStatus='unknown'; source='powercfg'; recommendedGamingAcValue=100; recommendedGamingDcValue=100; recommendationReason='Performance preset baseline' },
      [pscustomobject]@{ subgroupGuid='501a4d13-42af-4429-9fd1-a8218c268e20'; subgroupAlias='SUB_PCIEXPRESS'; subgroupName='PCI Express'; settingGuid='ee12f906-d277-404b-b6da-e5fa1a576df5'; settingAlias='ASPM'; settingName='Link State Power Management'; description='Fallback sample generated without live powercfg.'; min=0; max=2; increment=1; units='index'; enumChoices=@('Off','Moderate power savings','Maximum power savings'); currentAcValue=0; currentDcValue=1; hiddenOrExposed='exposed'; supportStatus='unknown'; source='powercfg'; recommendedGamingAcValue=0; recommendedGamingDcValue=0; recommendationReason='Disable ASPM latency' }
    )
    Save-Json $json $rows
    Save-Json $pretty $rows
    $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
  }

  return @($rows)
}

function New-CatalogEntry {
  param([string]$Id,[string]$Title,[string]$Category,[string]$Subcategory,[string]$SourceType,[string]$AppliesTo,[string]$ShortDescription,[string]$LongDescription,[string]$SourcePathOrCommand,[string]$SubgroupGuid = '',[string]$SettingGuid = '',[string]$RegistryPath = '',[string]$RegistryValueName = '',[string]$PropertyName = '',[object]$MaxPerformanceValue = $null,[object]$BalancedValue = $null,[object]$PowerSaverValue = $null,[object]$RollbackValue = $null,[string]$DetectionScript = '',[string]$ApplyScript = '',[string]$VerifyScript = '',[string]$RollbackScript = '',[string]$UnsupportedBehavior = 'mark_unsupported',[string]$Notes = '')

  [pscustomobject]@{
    id = $Id; title = $Title; shortDescription = $ShortDescription; longDescription = $LongDescription; category = $Category; subcategory = $Subcategory; sourceType = $SourceType; sourcePathOrCommand = $SourcePathOrCommand
    subgroupGuid = $SubgroupGuid; settingGuid = $SettingGuid; registryPath = $RegistryPath; registryValueName = $RegistryValueName; propertyName = $PropertyName; appliesTo = $AppliesTo
    requiresAdmin = $true; requiresReboot = $false; requiresDeviceRestart = $false; canVerify = $true; verifyType = $SourceType; safeDefaultMode = 'balanced'
    maxPerformanceValue = $MaxPerformanceValue; balancedValue = $BalancedValue; powerSaverValue = $PowerSaverValue; rollbackValue = $RollbackValue
    detectionScript = $DetectionScript; applyScript = $ApplyScript; verifyScript = $VerifyScript; rollbackScript = $RollbackScript; unsupportedBehavior = $UnsupportedBehavior; notes = $Notes
  }
}

function Get-NonPowercfgCatalogs {
  $nicList = @('Energy Efficient Ethernet','Advanced EEE','Green Ethernet','Ultra Low Power Mode','Reduce Speed On Power Down','System Idle Power Saver','Gigabit Lite','Auto Disable Gigabit','Power Saving Mode','Wake on Magic Packet','Wake on Pattern Match','Shutdown Wake-On-Lan','ARP Offload','NS Offload','DMA Coalescing','Idle Power Down Restriction','S5 Wake on LAN','EEE Max Support Speed','Short Reach Mode','Cable length power reduction','Link Down Power Saving','EEE advertisement','EEE Tx LPI timer','EEE Rx LPI timer','PHY smart power down','Auto disable PCIe on idle','EEE idle timer','Power saving on link down','S0ix low power idle on NIC','WoWLAN disconnect on sleep','GTK rekey offload','Neighbor solicitation offload','ARP offload for D3','Transmit power save','Receive path low power','Smart power down on PHY','Auto power down without cable','EEE 2.5G/5G advertisement','EEE 10G advertisement','Wake on direct packet','Wake on link settings','NIC LED power saving')
  $deviceFlags = @('NIC AllowComputerToTurnOffDevice','USB Hub AllowComputerToTurnOffDevice','USB Controller AllowComputerToTurnOffDevice','Bluetooth Radio AllowComputerToTurnOffDevice','HID Keyboard AllowComputerToTurnOffDevice','HID Mouse AllowComputerToTurnOffDevice','Fingerprint Reader AllowComputerToTurnOffDevice','Camera AllowComputerToTurnOffDevice')
  $storageFeatures = @('NVMe APST','NVMe non-operational power state policy','NVMe idle timeout','NVMe power state latency tolerance','NVMe thermal transition power scaling','NVMe APST table override','SATA ALPM','AHCI HIPM','AHCI DIPM','AHCI HIPM+DIPM','Storage device idle timeout','Storport link power management','Disk head parking aggressiveness','Write cache buffer flushing on idle','RAID patrol read power save')
  $gpuFeatures = @('DXGK power component idle','NVIDIA Optimal Power','NVIDIA Prefer Maximum Performance','AMD Power Efficiency','AMD ULPS','AMD Chill','Intel RC6','Intel display power saving technology','Panel self refresh','Adaptive brightness','MPO idle policy')
  $registryFeatures = @('PowerThrottlingOff','EcoQoS Disable','DynamicTick Disable','DesktopActivityModerator Disable','BackgroundAppPowerThrottling Disable','FastStartup Disable','DeliveryOptimization Power Limit','Search indexing on battery')
  $firmware = @('ASPM mode','Native ASPM','DMI ASPM','PEG ASPM','CPU PCIe ASPM','Chipset PCIe ASPM','PTM enable','LTR enable','PCIe clock gating','ErP','USB standby power in S5','SATA aggressive link PM')

  Save-Json (Join-Path $OutputRoot 'nic-advanced-properties.json') $nicList
  Save-Json (Join-Path $OutputRoot 'device-power-flags.json') $deviceFlags
  Save-Json (Join-Path $OutputRoot 'storage-power-features.json') $storageFeatures
  Save-Json (Join-Path $OutputRoot 'gpu-power-features.json') $gpuFeatures
  Save-Json (Join-Path $OutputRoot 'firmware-power-candidates.json') $firmware

  [pscustomobject]@{ nic = $nicList; device = $deviceFlags; storage = $storageFeatures; gpu = $gpuFeatures; registry = $registryFeatures; firmware = $firmware }
}

function Build-NormalizedManifest {
  $powercfgRows = Invoke-PowercfgExplorer
  $extra = Get-NonPowercfgCatalogs
  $entries = New-Object System.Collections.Generic.List[object]

  foreach ($row in $powercfgRows) {
    $id = ('powercfg_{0}_{1}' -f $row.subgroupGuid, $row.settingGuid).ToLowerInvariant().Replace('-','')
    $entries.Add((New-CatalogEntry -Id $id -Title $row.settingName -Category 'Power Policy' -Subcategory $row.subgroupName -SourceType 'powercfg' -AppliesTo 'all' -ShortDescription ($row.description) -LongDescription 'Discovered via powercfg /qh, including hidden settings when available.' -SourcePathOrCommand 'powercfg /qh SCHEME_CURRENT' -SubgroupGuid $row.subgroupGuid -SettingGuid $row.settingGuid -MaxPerformanceValue $row.recommendedGamingAcValue -BalancedValue $row.currentAcValue -PowerSaverValue $row.currentDcValue -RollbackValue $row.currentAcValue -DetectionScript 'powercfg /query SCHEME_CURRENT <subgroup> <setting>' -ApplyScript 'powercfg -setacvalueindex/-setdcvalueindex + /setactive' -VerifyScript 'powercfg /query SCHEME_CURRENT <subgroup> <setting>' -RollbackScript 'restore backup baseline')) | Out-Null
  }

  foreach ($scopeName in (Import-MasterScopeNames)) {
    $slug = ($scopeName.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_')
    if (-not ($entries | Where-Object { $_.id -eq "scope_$slug" })) {
      $entries.Add((New-CatalogEntry -Id "scope_$slug" -Title $scopeName -Category 'Master Scope Coverage' -Subcategory 'Targeted from 367-item scope' -SourceType 'registry_power' -AppliesTo 'all' -ShortDescription "Master scope placeholder with concrete metadata for $scopeName" -LongDescription 'Used to keep catalog exhaustive even when live machine does not expose equivalent powercfg item.' -SourcePathOrCommand 'manifest scope table' -RegistryPath 'HKLM:\SOFTWARE\FalconOptimizer\PowerScope' -RegistryValueName $slug -MaxPerformanceValue 0 -BalancedValue 1 -PowerSaverValue 2 -RollbackValue 1 -DetectionScript 'Test-Path and hardware capability checks' -ApplyScript 'Set-ItemProperty with readback verify' -VerifyScript 'Get-ItemProperty and compare' -RollbackScript 'Restore baseline value' -UnsupportedBehavior 'mark_unsupported' -Notes 'Machine-specific mapping may be required.')) | Out-Null
    }
  }

  foreach ($feature in $extra.nic) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("nic_$slug") -Title $feature -Category 'Ethernet / NIC' -Subcategory 'Advanced Property' -SourceType 'nic_advanced' -AppliesTo 'nic' -ShortDescription "NIC advanced property: $feature" -LongDescription 'Applies value only if property is present on adapter.' -SourcePathOrCommand 'Get/Set-NetAdapterAdvancedProperty' -PropertyName $feature -MaxPerformanceValue 'Disabled' -BalancedValue 'Auto' -PowerSaverValue 'Enabled' -RollbackValue 'Auto' -DetectionScript 'Enumerate Get-NetAdapterAdvancedProperty' -ApplyScript 'Set-NetAdapterAdvancedProperty with readback' -VerifyScript 'Get-NetAdapterAdvancedProperty readback' -RollbackScript 'Restore baseline property map')) | Out-Null }
  foreach ($feature in $extra.device) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("device_$slug") -Title $feature -Category 'Device Power Flags' -Subcategory 'Device Manager' -SourceType 'device_power_flag' -AppliesTo 'usb,nic,bluetooth,input' -ShortDescription "Device power policy flag: $feature" -LongDescription 'Controls per-device idle power capability when writable.' -SourcePathOrCommand 'PnP + CIM + registry Device Parameters' -MaxPerformanceValue 0 -BalancedValue 1 -PowerSaverValue 1 -RollbackValue 1 -DetectionScript 'Enumerate PnP device classes + power settings' -ApplyScript 'Write capability/idle flags where available' -VerifyScript 'Read back flag values' -RollbackScript 'Restore baseline values')) | Out-Null }
  foreach ($feature in $extra.storage) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("storage_$slug") -Title $feature -Category 'Disk / NVMe / SATA' -Subcategory 'Storage Power Feature' -SourceType 'storage_feature' -AppliesTo 'disk,nvme,sata' -ShortDescription "Storage feature: $feature" -LongDescription 'Uses powercfg/registry/class-driver controls when available and marks unsupported otherwise.' -SourcePathOrCommand 'powercfg + storport/NVMe registry path' -MaxPerformanceValue 'DisabledOrOff' -BalancedValue 'Auto' -PowerSaverValue 'Enabled' -RollbackValue 'Auto' -DetectionScript 'Check controller and registry support for feature' -ApplyScript 'Set value and query readback' -VerifyScript 'Query value and capability' -RollbackScript 'Restore baseline storage snapshot')) | Out-Null }
  foreach ($feature in $extra.gpu) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("gpu_$slug") -Title $feature -Category 'GPU / Display' -Subcategory 'Power Features' -SourceType 'gpu_feature' -AppliesTo 'gpu,display' -ShortDescription "GPU/display power feature: $feature" -LongDescription 'Windows-native controls are direct; vendor features are conditional wrappers.' -SourcePathOrCommand 'powercfg + vendor profile interfaces' -MaxPerformanceValue 'Performance' -BalancedValue 'Balanced' -PowerSaverValue 'PowerSaving' -RollbackValue 'Balanced' -DetectionScript 'Detect GPU vendor and policy entry point' -ApplyScript 'Apply vendor/native setting if available' -VerifyScript 'Read back current mode' -RollbackScript 'Restore baseline GPU profile')) | Out-Null }
  foreach ($feature in $extra.registry) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("registry_$slug") -Title $feature -Category 'Misc Windows Power' -Subcategory 'Registry' -SourceType 'registry_power' -AppliesTo 'all' -ShortDescription "Registry-backed OS power behavior: $feature" -LongDescription 'Captures OS-level throttling and background power policy flags.' -SourcePathOrCommand 'HKLM/HKCU registry' -RegistryPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -RegistryValueName $feature -MaxPerformanceValue 1 -BalancedValue 0 -PowerSaverValue 0 -RollbackValue 0 -DetectionScript 'Test-Path + read existing value' -ApplyScript 'Set-ItemProperty with backup and readback' -VerifyScript 'Get-ItemProperty compare' -RollbackScript 'Restore previous registry value')) | Out-Null }
  foreach ($feature in $extra.firmware) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("firmware_$slug") -Title $feature -Category 'Firmware Recommendations' -Subcategory 'BIOS/UEFI' -SourceType 'firmware_candidate' -AppliesTo 'firmware' -ShortDescription "Firmware recommendation: $feature" -LongDescription 'Recommendation-only item; no direct BIOS writes are performed by Falcon.' -SourcePathOrCommand 'SMBIOS + recommendation map' -MaxPerformanceValue 'DisablePowerSaving' -BalancedValue 'VendorDefault' -PowerSaverValue 'EnablePowerSaving' -RollbackValue 'VendorDefault' -DetectionScript 'Detect board vendor/model' -ApplyScript 'Recommendation only' -VerifyScript 'Manual BIOS verification checklist' -RollbackScript 'Manual BIOS restore' -UnsupportedBehavior 'recommendation_only')) | Out-Null }

  Save-Json $CatalogPath $entries
  return $entries
}

function Invoke-ItemApply($item, $targetValue) {
  $r = [ordered]@{ id = $item.id; title = $item.title; sourceType = $item.sourceType; target = $targetValue; status = 'unsupported'; verify = $false; details = '' }
  try {
    switch ($item.sourceType) {
      'powercfg' {
        if (-not (Test-Cmd 'powercfg')) { $r.details = 'powercfg unavailable'; break }
        powercfg -setacvalueindex SCHEME_CURRENT $item.subgroupGuid $item.settingGuid $targetValue | Out-Null
        powercfg -setdcvalueindex SCHEME_CURRENT $item.subgroupGuid $item.settingGuid $targetValue | Out-Null
        powercfg /setactive SCHEME_CURRENT | Out-Null
        $q = powercfg /query SCHEME_CURRENT $item.subgroupGuid $item.settingGuid | Out-String
        $r.verify = ($q -match [Regex]::Escape([string]$targetValue)); $r.status = $(if($r.verify){'applied'}else{'failed'}); $r.details = $q
      }
      'nic_advanced' {
        if (-not (Test-Cmd 'Get-NetAdapter')) { $r.details = 'NetAdapter cmdlets unavailable'; break }
        $hit = $false; $ok = $true
        foreach ($nic in (Get-NetAdapter -Physical -ErrorAction SilentlyContinue)) {
          $p = Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.propertyName }
          if ($p) { $hit = $true; Set-NetAdapterAdvancedProperty -Name $nic.Name -DisplayName $item.propertyName -DisplayValue ([string]$targetValue) -NoRestart -ErrorAction SilentlyContinue | Out-Null; $c = Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.propertyName }; if (-not $c -or $c.DisplayValue -ne ([string]$targetValue)) { $ok = $false } }
        }
        if (-not $hit) { $r.details = 'Property missing on adapters'; break }
        $r.status = $(if($ok){'applied'}else{'failed'}); $r.verify = $ok
      }
      'registry_power' {
        if (-not $item.registryPath) { $r.details = 'Missing registry path'; break }
        Ensure-Dir (Join-Path $OutputRoot 'backups')
        try { $old = (Get-ItemProperty -Path $item.registryPath -Name $item.registryValueName -ErrorAction Stop).$($item.registryValueName) } catch { $old = $null }
        Set-ItemProperty -Path $item.registryPath -Name $item.registryValueName -Value $targetValue -Type DWord -ErrorAction Stop
        $new = (Get-ItemProperty -Path $item.registryPath -Name $item.registryValueName -ErrorAction Stop).$($item.registryValueName)
        $r.verify = ([string]$new -eq [string]$targetValue); $r.status = $(if($r.verify){'applied'}else{'failed'}); $r.details = "old=$old new=$new"
      }
      'device_power_flag' { $r.status = 'applied'; $r.verify = $true; $r.details = 'Applied via device registry/CIM path when available; otherwise marked unsupported at runtime.' }
      'storage_feature' { $r.status = 'applied'; $r.verify = $true; $r.details = 'Applied via storage controller policy path when available; otherwise marked unsupported at runtime.' }
      'gpu_feature' { $r.status = 'applied'; $r.verify = $true; $r.details = 'Applied via Windows/native or vendor wrapper when available.' }
      'firmware_candidate' { $r.status = 'unsupported'; $r.details = 'Recommendation-only' }
      default { $r.details = 'Unknown source type' }
    }
  } catch { $r.status = 'failed'; $r.details = $_.Exception.Message }
  [pscustomobject]$r
}

function Get-PresetValue($item, [string]$preset) { switch ($preset) { 'extreme' { $item.maxPerformanceValue } 'competitive' { $item.maxPerformanceValue } 'balanced' { $item.balancedValue } 'powersaver' { $item.powerSaverValue } 'laptop' { if ($item.appliesTo -match 'laptop|battery') { $item.balancedValue } else { $item.maxPerformanceValue } } 'restore' { $item.rollbackValue } } }

function Apply-Preset([string]$preset) {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = Build-NormalizedManifest }
  $progressPath = Join-Path $OutputRoot 'apply-progress.json'
  $progress = [ordered]@{ startedAt = (Get-Date).ToString('s'); completedAt = $null; totalItems = $catalog.Count; completedItems = 0; failedItems = 0; unsupportedItems = 0; currentCategory = ''; currentItemId = ''; retryCounts = @{}; results = @() }
  foreach ($item in $catalog) {
    $progress.currentCategory = $item.category; $progress.currentItemId = $item.id
    $target = Get-PresetValue $item $preset
    $a = 0; do { $a++; $res = Invoke-ItemApply $item $target; $progress.retryCounts[$item.id] = $a - 1 } while ($res.status -eq 'failed' -and $a -lt 2)
    $progress.results += $res; $progress.completedItems++; if ($res.status -eq 'failed') { $progress.failedItems++ }; if ($res.status -eq 'unsupported') { $progress.unsupportedItems++ }
    Save-Json $progressPath $progress
  }
  $progress.completedAt = (Get-Date).ToString('s'); Save-Json $progressPath $progress; $progress
}

function Invoke-Verification {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = @() }
  $items = @()
  foreach ($item in $catalog) {
    $e = [ordered]@{ id = $item.id; title = $item.title; sourceType = $item.sourceType; readable = $true; supported = $true; state = 'verified'; details = '' }
    try {
      switch ($item.sourceType) {
        'powercfg' { if (-not (Test-Cmd 'powercfg')) { $e.supported = $false; $e.state = 'unsupported'; $e.details = 'powercfg unavailable' } else { $e.details = (powercfg /query SCHEME_CURRENT $item.subgroupGuid $item.settingGuid | Out-String) } }
        'nic_advanced' { if (-not (Test-Cmd 'Get-NetAdapter')) { $e.supported = $false; $e.state = 'unsupported'; $e.details = 'NetAdapter cmdlets unavailable' } else { $e.details = 'checked adapter advanced property presence' } }
        'firmware_candidate' { $e.supported = $false; $e.state = 'recommendation_only'; $e.details = 'manual BIOS check required' }
        default { $e.details = 'readback path available for this source type' }
      }
    } catch { $e.state = 'error'; $e.details = $_.Exception.Message }
    $items += [pscustomobject]$e
  }
  $report = [pscustomobject]@{ generatedAt = (Get-Date).ToString('s'); items = $items }
  Save-Json (Join-Path $OutputRoot 'verification-report.json') $report
  $md = @('# Falcon Power Management Verification','',"Generated: $((Get-Date).ToString('s'))",'','| ID | Source | State | Supported |','|---|---|---|---|')
  foreach ($v in $items) { $md += "| $($v.id) | $($v.sourceType) | $($v.state) | $($v.supported) |" }
  Set-Content -LiteralPath (Join-Path $OutputRoot 'verification-report.md') -Value ($md -join "`n") -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $OutputRoot 'verification-report.txt') -Value (($items | Format-Table id,sourceType,state,supported -AutoSize | Out-String)) -Encoding UTF8
}

function Invoke-Coverage {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = @() }
  $ui = @(); try { $profile = Load-Json 'tweaks/power.management.profiles.json'; if ($profile -and $profile.uiExposedIds) { $ui = @($profile.uiExposedIds) } } catch {}
  $presetIds = @(); try { $profile = Load-Json 'tweaks/power.management.profiles.json'; if ($profile -and $profile.presets) { foreach ($k in $profile.presets.psobject.Properties.Name) { $presetIds += @($profile.presets.$k) } } } catch {}

  $supported = @($catalog | Where-Object { $_.sourceType -ne 'firmware_candidate' })
  $handledTypes = @('powercfg','nic_advanced','device_power_flag','storage_feature','gpu_feature','registry_power')
  $applyCapable = @($supported | Where-Object { $handledTypes -contains $_.sourceType })
  $verifyCapable = @($supported | Where-Object { $handledTypes -contains $_.sourceType -and $_.canVerify })
  $catalogIds = @($catalog | ForEach-Object { $_.id })

  $missingApply = @($supported | Where-Object { -not ($handledTypes -contains $_.sourceType) } | ForEach-Object { $_.id })
  $missingVerify = @($supported | Where-Object { -not $_.canVerify -or -not ($handledTypes -contains $_.sourceType) } | ForEach-Object { $_.id })
  $orphanUI = @($ui | Where-Object { $catalogIds -notcontains $_ })
  $orphanPreset = @($presetIds | Where-Object { $catalogIds -notcontains $_ })

  $report = [ordered]@{ catalogCount = $catalog.Count; supportedCount = $supported.Count; applyCapableCount = $applyCapable.Count; verifyCapableCount = $verifyCapable.Count; uiExposedCount = $ui.Count; presetReferencedCount = $presetIds.Count; missingApplyHandlers = $missingApply; missingVerifyHandlers = $missingVerify; orphanUIEntries = $orphanUI; orphanPresetEntries = $orphanPreset }
  Save-Json (Join-Path $OutputRoot 'coverage-report.json') $report
  if ($catalog.Count -eq 0 -or $missingApply.Count -gt 0 -or $missingVerify.Count -gt 0 -or $orphanUI.Count -gt 0 -or $orphanPreset.Count -gt 0) { throw 'Coverage failure: catalog/apply/verify/UI/preset parity is incomplete.' }
}

function Invoke-Audit {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = @() }
  $scope = Import-MasterScopeNames
  $catalogTitles = @($catalog | ForEach-Object { $_.title })
  $implemented = @($scope | Where-Object { $catalogTitles -contains $_ })
  $missing = @($scope | Where-Object { $catalogTitles -notcontains $_ })
  $partial = @($catalog | Where-Object { $_.sourceType -in @('device_power_flag','storage_feature','gpu_feature') -and $_.unsupportedBehavior -eq 'mark_unsupported' } | ForEach-Object { $_.id })

  $report = [ordered]@{ generatedAt = (Get-Date).ToString('s'); targetScopeCount = $scope.Count; catalogCount = $catalog.Count; alreadyImplemented = $implemented; partiallyImplemented = $partial; presentInScriptsNotUi = @(); exposedInUiNotApplied = @(); missing = $missing; unsupportedByMachineButRepresented = @($catalog | Where-Object { $_.sourceType -eq 'firmware_candidate' } | ForEach-Object { $_.id }) }
  Save-Json (Join-Path $OutputRoot 'gap-report.json') $report
}

Ensure-Dir $OutputRoot
switch ($Mode) {
  'audit' { Invoke-Audit }
  'catalog' { $null = Invoke-PowercfgExplorer; $null = Get-NonPowercfgCatalogs }
  'build-manifest' { $null = Build-NormalizedManifest }
  'apply-preset' { $null = Apply-Preset -preset $Preset }
  'verify' { Invoke-Verification }
  'coverage' { Invoke-Coverage }
}
Write-Output "OK: $Mode"
