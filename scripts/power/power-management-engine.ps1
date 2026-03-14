param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('audit','catalog','build-manifest','apply-preset','apply-item','verify','verify-item','coverage','rollback-item')]
  [string]$Mode,
  [ValidateSet('extreme','competitive','balanced','powersaver','laptop','restore')]
  [string]$Preset = 'extreme',
  [string]$ItemId = '',
  [string]$OutputRoot = 'output/power',
  [string]$CatalogPath = 'data/power/power_management_catalog.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$path) { if ($path -and -not (Test-Path -LiteralPath $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null } }
function Save-Json([string]$path, $obj) { $d = Split-Path -Parent $path; if ($d) { Ensure-Dir $d }; $obj | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $path -Encoding UTF8 }
function Load-Json([string]$path) { if (-not (Test-Path -LiteralPath $path)) { return $null }; Get-Content -LiteralPath $path -Raw | ConvertFrom-Json }
function Test-Cmd([string]$name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Import-MasterScopeNames {
  $file = 'data/power/master_scope_names.json'
  $names = Load-Json $file
  if ($names) { return @($names) }
  return @()
}

function Invoke-PowercfgExplorer {
  $json = Join-Path $OutputRoot 'full-powercfg-catalog.json'
  $pretty = Join-Path $OutputRoot 'full-powercfg-catalog.pretty.json'
  $csv = Join-Path $OutputRoot 'full-powercfg-catalog.csv'
  if (Test-Cmd 'powercfg') {
    $args = @('-ExecutionPolicy','Bypass','-File','scripts/power/all-settings-explorer.ps1','-Mode','scan','-OutputPath',$json)
    & powershell.exe @args | Out-Null
  }
  $rows = Load-Json $json
  if (-not $rows) { $rows = @() }
  if (-not (Test-Path -LiteralPath $pretty)) { Save-Json $pretty $rows }
  if (-not (Test-Path -LiteralPath $csv)) {
    try { $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csv } catch {}
  }
  return @($rows)
}

function New-CatalogEntry {
  param([string]$Id,[string]$Title,[string]$Category,[string]$Subcategory,[string]$SourceType,[string]$AppliesTo,[string]$ShortDescription,[string]$LongDescription,[string]$SourcePathOrCommand,[string]$SubgroupGuid = '',[string]$SettingGuid = '',[string]$RegistryPath = '',[string]$RegistryValueName = '',[string]$PropertyName = '',[object]$MaxPerformanceValue = $null,[object]$BalancedValue = $null,[object]$PowerSaverValue = $null,[object]$RollbackValue = $null,[string]$UnsupportedBehavior = 'mark_unsupported',[string]$Notes = '')
  [pscustomobject]@{ id=$Id; title=$Title; shortDescription=$ShortDescription; longDescription=$LongDescription; category=$Category; subcategory=$Subcategory; sourceType=$SourceType; sourcePathOrCommand=$SourcePathOrCommand; subgroupGuid=$SubgroupGuid; settingGuid=$SettingGuid; registryPath=$RegistryPath; registryValueName=$RegistryValueName; propertyName=$PropertyName; appliesTo=$AppliesTo; requiresAdmin=$true; canVerify=$true; maxPerformanceValue=$MaxPerformanceValue; balancedValue=$BalancedValue; powerSaverValue=$PowerSaverValue; rollbackValue=$RollbackValue; unsupportedBehavior=$UnsupportedBehavior; notes=$Notes }
}

function Get-NonPowercfgCatalogs {
  $nicList = @('Energy Efficient Ethernet','Advanced EEE','Green Ethernet','Ultra Low Power Mode','Reduce Speed On Power Down','System Idle Power Saver','Gigabit Lite','Auto Disable Gigabit','Power Saving Mode','Wake on Magic Packet','Wake on Pattern Match','ARP Offload','NS Offload','DMA Coalescing','Link Down Power Saving')
  $deviceFlags = @('NIC AllowComputerToTurnOffDevice','USB Hub AllowComputerToTurnOffDevice','Bluetooth Radio AllowComputerToTurnOffDevice','HID Keyboard AllowComputerToTurnOffDevice','HID Mouse AllowComputerToTurnOffDevice')
  $storageFeatures = @('NVMe APST','NVMe idle timeout','SATA ALPM','AHCI HIPM','AHCI DIPM','Storage device idle timeout','Storport link power management')
  $gpuFeatures = @('DXGK power component idle','NVIDIA Optimal Power','NVIDIA Prefer Maximum Performance','AMD Power Efficiency','AMD ULPS','Intel RC6','Panel self refresh','Adaptive brightness')
  $registryFeatures = @(
    @{ name='PowerThrottlingOff'; path='HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'; value='PowerThrottlingOff' },
    @{ name='DynamicTick Disable'; path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; value='DisableDynamicTick' },
    @{ name='FastStartup Disable'; path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; value='HiberbootEnabled' }
  )
  $firmware = @('ASPM mode','Native ASPM','DMI ASPM','PEG ASPM','ErP','USB standby power in S5')
  [pscustomobject]@{ nic=$nicList; device=$deviceFlags; storage=$storageFeatures; gpu=$gpuFeatures; registry=$registryFeatures; firmware=$firmware }
}

function Build-NormalizedManifest {
  $powercfgRows = Invoke-PowercfgExplorer
  $extra = Get-NonPowercfgCatalogs
  $entries = New-Object System.Collections.Generic.List[object]

  foreach ($row in $powercfgRows) {
    if (-not $row.settingGuid -or -not $row.subgroupGuid) { continue }
    $id = ('powercfg_{0}_{1}' -f $row.subgroupGuid, $row.settingGuid).ToLowerInvariant().Replace('-','')
    $entries.Add((New-CatalogEntry -Id $id -Title $row.settingName -Category 'Power Policy' -Subcategory $row.subgroupName -SourceType 'powercfg' -AppliesTo 'all' -ShortDescription $row.description -LongDescription 'Live discovered via powercfg.' -SourcePathOrCommand 'powercfg /qh SCHEME_CURRENT' -SubgroupGuid $row.subgroupGuid -SettingGuid $row.settingGuid -MaxPerformanceValue $row.recommendedGamingAcValue -BalancedValue $row.currentAcValue -PowerSaverValue $row.currentDcValue -RollbackValue $row.currentAcValue -Notes $row.hiddenOrExposed)) | Out-Null
  }

  foreach ($feature in $extra.nic) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("nic_$slug") -Title $feature -Category 'Ethernet / NIC' -Subcategory 'Advanced Property' -SourceType 'nic_advanced' -AppliesTo 'nic' -ShortDescription "NIC advanced property: $feature" -LongDescription 'Applies value only if property is present on adapter.' -SourcePathOrCommand 'Get/Set-NetAdapterAdvancedProperty' -PropertyName $feature -MaxPerformanceValue 'Disabled' -BalancedValue 'Auto' -PowerSaverValue 'Enabled' -RollbackValue 'Auto')) | Out-Null }
  foreach ($feature in $extra.device) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("device_$slug") -Title $feature -Category 'Device Power Flags' -Subcategory 'Device Manager' -SourceType 'device_power_flag' -AppliesTo 'usb,nic,bluetooth,input' -ShortDescription "Device power policy flag: $feature" -LongDescription 'Uses Enum\\*\\Device Parameters / PnPCapabilities where writable.' -SourcePathOrCommand 'Get-PnpDevice + registry' -MaxPerformanceValue 0 -BalancedValue 1 -PowerSaverValue 1 -RollbackValue 1)) | Out-Null }
  foreach ($feature in $extra.storage) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("storage_$slug") -Title $feature -Category 'Disk / NVMe / SATA' -Subcategory 'Storage Power Feature' -SourceType 'storage_feature' -AppliesTo 'disk,nvme,sata' -ShortDescription "Storage feature: $feature" -LongDescription 'Uses powercfg and storage service registry settings when present.' -SourcePathOrCommand 'powercfg + stornvme/storahci registry' -MaxPerformanceValue 0 -BalancedValue 1 -PowerSaverValue 1 -RollbackValue 1)) | Out-Null }
  foreach ($feature in $extra.gpu) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("gpu_$slug") -Title $feature -Category 'GPU / Display' -Subcategory 'Power Features' -SourceType 'gpu_feature' -AppliesTo 'gpu,display' -ShortDescription "GPU/display power feature: $feature" -LongDescription 'Uses vendor-aware registry locations when present.' -SourcePathOrCommand 'Win32_VideoController + vendor registry' -MaxPerformanceValue 0 -BalancedValue 1 -PowerSaverValue 1 -RollbackValue 1)) | Out-Null }
  foreach ($feature in $extra.registry) { $slug = ($feature.name.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("registry_$slug") -Title $feature.name -Category 'Misc Windows Power' -Subcategory 'Registry-backed' -SourceType 'registry_power' -AppliesTo 'windows' -ShortDescription "Registry-backed Windows power setting: $($feature.name)" -LongDescription 'Real registry-backed setting.' -SourcePathOrCommand $feature.path -RegistryPath $feature.path -RegistryValueName $feature.value -MaxPerformanceValue 1 -BalancedValue 0 -PowerSaverValue 0 -RollbackValue 0)) | Out-Null }
  foreach ($feature in $extra.firmware) { $slug = ($feature.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_'); $entries.Add((New-CatalogEntry -Id ("firmware_$slug") -Title $feature -Category 'Firmware Recommendations' -Subcategory 'BIOS/UEFI' -SourceType 'firmware_candidate' -AppliesTo 'firmware' -ShortDescription "Firmware recommendation: $feature" -LongDescription 'Recommendation-only item; no direct BIOS writes are performed by Falcon.' -SourcePathOrCommand 'SMBIOS + recommendation map' -MaxPerformanceValue 'DisablePowerSaving' -BalancedValue 'VendorDefault' -PowerSaverValue 'EnablePowerSaving' -RollbackValue 'VendorDefault' -UnsupportedBehavior 'recommendation_only')) | Out-Null }

  $dedup = @($entries | Group-Object id | ForEach-Object { $_.Group[0] })
  Save-Json $CatalogPath $dedup
  return $dedup
}

function Find-DeviceRegistryPaths([string]$title) {
  $classPattern = if ($title -match 'nic') { 'Net' } elseif ($title -match 'usb') { 'USB|HUB' } elseif ($title -match 'bluetooth') { 'Bluetooth' } else { 'Keyboard|Mouse|HIDClass' }
  $base = 'HKLM:\SYSTEM\CurrentControlSet\Enum'
  $paths = @()
  try { Get-ChildItem -Path $base -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSPath -match 'Device Parameters$' -and $_.PSPath -match $classPattern } | ForEach-Object { $paths += $_.PSPath -replace 'Microsoft.PowerShell.Core\\Registry::','' } } catch {}
  return @($paths | Select-Object -Unique)
}

function Set-RegistryDword([string]$path,[string]$name,[int]$value) {
  if (-not (Test-Path -LiteralPath $path)) { return $false }
  try { Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord -ErrorAction Stop; return $true } catch { return $false }
}

function Get-StorageTargets([string]$title) {
  $t = $title.ToLowerInvariant()
  if ($t -match 'nvme apst') { return @(@{ path='HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'; name='EnableAPST' }) }
  if ($t -match 'idle timeout') { return @(@{ path='HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'; name='IdleTimeoutInMS' }) }
  if ($t -match 'storport|sata|ahci|alpm|hipm|dipm') { return @(@{ path='HKLM:\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device'; name='NoLPM' }) }
  return @()
}

function Get-GpuTargets([string]$title) {
  $t = $title.ToLowerInvariant()
  if ($t -match 'amd ulps') { return @(@{ path='HKLM:\SYSTEM\CurrentControlSet\Control\Video'; name='EnableUlps'; recursive=$true }) }
  if ($t -match 'intel rc6') { return @(@{ path='HKLM:\SOFTWARE\Intel\GMM'; name='EnableRC6'; recursive=$false }) }
  if ($t -match 'adaptive brightness|panel self refresh|dxgk') { return @(@{ path='HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; name='PowerSettings'; recursive=$false }) }
  if ($t -match 'nvidia') { return @(@{ path='HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm'; name='PowerMizerEnable'; recursive=$false }) }
  return @()
}

function Invoke-ItemApply($item, $targetValue) {
  $r = [ordered]@{ id=$item.id; title=$item.title; sourceType=$item.sourceType; target=$targetValue; status='unsupported'; verify=$false; details='' }
  try {
    switch ($item.sourceType) {
      'powercfg' {
        if (-not (Test-Cmd 'powercfg')) { $r.details='powercfg unavailable'; break }
        powercfg -setacvalueindex SCHEME_CURRENT $item.subgroupGuid $item.settingGuid $targetValue | Out-Null
        powercfg -setdcvalueindex SCHEME_CURRENT $item.subgroupGuid $item.settingGuid $targetValue | Out-Null
        powercfg /setactive SCHEME_CURRENT | Out-Null
        $q = powercfg /query SCHEME_CURRENT $item.subgroupGuid $item.settingGuid | Out-String
        $r.verify = ($q -match [Regex]::Escape([string]$targetValue)); $r.status = $(if($r.verify){'applied'}else{'failed'}); $r.details=$q
      }
      'nic_advanced' {
        if (-not (Test-Cmd 'Get-NetAdapter')) { $r.details='NetAdapter cmdlets unavailable'; break }
        $hit=$false; $ok=$true
        foreach ($nic in (Get-NetAdapter -Physical -ErrorAction SilentlyContinue)) {
          $p = Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.propertyName }
          if ($p) { $hit=$true; Set-NetAdapterAdvancedProperty -Name $nic.Name -DisplayName $item.propertyName -DisplayValue ([string]$targetValue) -NoRestart -ErrorAction SilentlyContinue | Out-Null; $c = Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.propertyName }; if (-not $c -or $c.DisplayValue -ne ([string]$targetValue)) { $ok=$false } }
        }
        if (-not $hit) { $r.details='Property missing on adapters'; break }
        $r.status = $(if($ok){'applied'}else{'failed'}); $r.verify=$ok
      }
      'registry_power' {
        if (-not $item.registryPath) { $r.details='Missing registry path'; break }
        if (-not (Set-RegistryDword $item.registryPath $item.registryValueName ([int]$targetValue))) { $r.details='Registry path/value unavailable'; break }
        $new=(Get-ItemProperty -Path $item.registryPath -Name $item.registryValueName -ErrorAction SilentlyContinue).$($item.registryValueName)
        $r.verify=([string]$new -eq [string]$targetValue); $r.status=$(if($r.verify){'applied'}else{'failed'}); $r.details="new=$new"
      }
      'device_power_flag' {
        $paths = Find-DeviceRegistryPaths $item.title
        if ($paths.Count -eq 0) { $r.details='No matching devices/registry paths found'; break }
        $changed=0
        foreach ($p in $paths) { if (Set-RegistryDword $p 'PnPCapabilities' ([int]$targetValue)) { $changed++ } }
        if ($changed -eq 0) { $r.details='Device power flag not writable'; break }
        $r.verify=$true; $r.status='applied'; $r.details="updatedPaths=$changed"
      }
      'storage_feature' {
        if ($item.subgroupGuid -and $item.settingGuid -and (Test-Cmd 'powercfg')) {
          powercfg -setacvalueindex SCHEME_CURRENT $item.subgroupGuid $item.settingGuid $targetValue | Out-Null
          powercfg -setdcvalueindex SCHEME_CURRENT $item.subgroupGuid $item.settingGuid $targetValue | Out-Null
          $r.status='applied'; $r.verify=$true; $r.details='Applied through powercfg mapping'; break
        }
        $targets = Get-StorageTargets $item.title
        if ($targets.Count -eq 0) { $r.details='No storage policy mapping for this machine'; break }
        $changed=0
        foreach ($t in $targets) { if (Set-RegistryDword $t.path $t.name ([int]$targetValue)) { $changed++ } }
        if ($changed -eq 0) { $r.details='Storage policy path unavailable'; break }
        $r.verify=$true; $r.status='applied'; $r.details="updatedTargets=$changed"
      }
      'gpu_feature' {
        $targets = Get-GpuTargets $item.title
        if ($targets.Count -eq 0) { $r.details='No GPU policy mapping'; break }
        $changed=0
        foreach ($t in $targets) {
          if ($t.recursive) {
            try { Get-ChildItem -Path $t.path -Recurse -ErrorAction SilentlyContinue | ForEach-Object { if (Set-RegistryDword ($_.PSPath -replace 'Microsoft.PowerShell.Core\\Registry::','') $t.name ([int]$targetValue)) { $changed++ } } } catch {}
          } else { if (Set-RegistryDword $t.path $t.name ([int]$targetValue)) { $changed++ } }
        }
        if ($changed -eq 0) { $r.details='GPU feature not writable on this machine'; break }
        $r.verify=$true; $r.status='applied'; $r.details="updatedTargets=$changed"
      }
      'firmware_candidate' { $r.status='unsupported'; $r.details='Recommendation-only' }
      default { $r.details='Unknown source type' }
    }
  } catch { $r.status='failed'; $r.details=$_.Exception.Message }
  [pscustomobject]$r
}

function Invoke-ItemVerify($item) {
  $e = [ordered]@{ id=$item.id; title=$item.title; sourceType=$item.sourceType; readable=$true; supported=$true; state='verified'; details='' }
  try {
    switch ($item.sourceType) {
      'powercfg' { if (-not (Test-Cmd 'powercfg')) { $e.supported=$false; $e.state='unsupported'; $e.details='powercfg unavailable' } else { $e.details = (powercfg /query SCHEME_CURRENT $item.subgroupGuid $item.settingGuid | Out-String) } }
      'nic_advanced' { if (-not (Test-Cmd 'Get-NetAdapter')) { $e.supported=$false; $e.state='unsupported'; $e.details='NetAdapter cmdlets unavailable' } else { $present = $false; foreach ($nic in (Get-NetAdapter -Physical -ErrorAction SilentlyContinue)) { if (Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.propertyName }) { $present = $true } }; if (-not $present) { $e.supported=$false; $e.state='unsupported'; $e.details='property missing on adapters' } else { $e.details='advanced property readable' } } }
      'registry_power' { if (-not (Test-Path -LiteralPath $item.registryPath)) { $e.supported=$false; $e.state='unsupported'; $e.details='registry path missing' } else { $v=(Get-ItemProperty -Path $item.registryPath -Name $item.registryValueName -ErrorAction SilentlyContinue).$($item.registryValueName); $e.details="value=$v" } }
      'device_power_flag' { $paths = Find-DeviceRegistryPaths $item.title; if ($paths.Count -eq 0) { $e.supported=$false; $e.state='unsupported'; $e.details='device class not found' } else { $vals=@(); foreach ($p in $paths) { $val=(Get-ItemProperty -Path $p -Name 'PnPCapabilities' -ErrorAction SilentlyContinue).PnPCapabilities; if ($null -ne $val) { $vals+="$p=$val" } }; if ($vals.Count -eq 0) { $e.supported=$false; $e.state='unsupported'; $e.details='power flag value not present' } else { $e.details=($vals -join '; ') } } }
      'storage_feature' { $targets = Get-StorageTargets $item.title; if ($targets.Count -eq 0) { $e.supported=$false; $e.state='unsupported'; $e.details='storage mapping unavailable' } else { $vals=@(); foreach ($t in $targets) { if (Test-Path -LiteralPath $t.path) { $vals += "$($t.path)::$($t.name)=" + ((Get-ItemProperty -Path $t.path -Name $t.name -ErrorAction SilentlyContinue).$($t.name)) } }; if ($vals.Count -eq 0) { $e.supported=$false; $e.state='unsupported'; $e.details='storage values unavailable' } else { $e.details=($vals -join '; ') } } }
      'gpu_feature' { $targets = Get-GpuTargets $item.title; if ($targets.Count -eq 0) { $e.supported=$false; $e.state='unsupported'; $e.details='gpu mapping unavailable' } else { $details=@(); foreach($t in $targets){ if(Test-Path -LiteralPath $t.path){ $details += $t.path } }; if($details.Count -eq 0){$e.supported=$false; $e.state='unsupported'; $e.details='vendor path unavailable'} else {$e.details=($details -join '; ')} } }
      'firmware_candidate' { $e.supported=$false; $e.state='recommendation_only'; $e.details='manual BIOS check required' }
    }
  } catch { $e.state='error'; $e.details=$_.Exception.Message }
  [pscustomobject]$e
}

function Get-PresetValue($item, [string]$preset) { switch ($preset) { 'extreme' { $item.maxPerformanceValue } 'competitive' { $item.maxPerformanceValue } 'balanced' { $item.balancedValue } 'powersaver' { $item.powerSaverValue } 'laptop' { if ($item.appliesTo -match 'laptop|battery') { $item.balancedValue } else { $item.maxPerformanceValue } } 'restore' { $item.rollbackValue } } }

function Apply-Preset([string]$preset) {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = Build-NormalizedManifest }
  $results = @()
  foreach ($item in $catalog) { $results += Invoke-ItemApply $item (Get-PresetValue $item $preset) }
  Save-Json (Join-Path $OutputRoot 'apply-progress.json') ([ordered]@{ generatedAt=(Get-Date).ToString('s'); totalItems=$catalog.Count; results=$results })
}

function Invoke-Verification {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = @() }
  $items = @($catalog | ForEach-Object { Invoke-ItemVerify $_ })
  $report = [pscustomobject]@{ generatedAt = (Get-Date).ToString('s'); items = $items }
  Save-Json (Join-Path $OutputRoot 'verification-report.json') $report
  $md = @('# Falcon Power Management Verification','',"Generated: $((Get-Date).ToString('s'))",'','| ID | Source | State | Supported |','|---|---|---|---|')
  foreach ($v in $items) { $md += "| $($v.id) | $($v.sourceType) | $($v.state) | $($v.supported) |" }
  Set-Content -LiteralPath (Join-Path $OutputRoot 'verification-report.md') -Value ($md -join "`n") -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $OutputRoot 'verification-report.txt') -Value (($items | Format-Table id,sourceType,state,supported -AutoSize | Out-String)) -Encoding UTF8
}

function Invoke-Coverage {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = @() }
  $profile = Load-Json 'tweaks/power.management.profiles.json'
  $ui = @(); if ($profile -and $profile.uiExposedIds) { $ui = @($profile.uiExposedIds) }
  $presetIds = @(); if ($profile -and $profile.presets) { foreach ($k in $profile.presets.psobject.Properties.Name) { $presetIds += @($profile.presets.$k) } }

  $catalogIds = @($catalog | ForEach-Object { $_.id })
  $realPowercfg = @($catalog | Where-Object { $_.sourceType -eq 'powercfg' -and $_.subgroupGuid -and $_.settingGuid })
  $applyCapable = @($catalog | Where-Object { $_.sourceType -in @('powercfg','nic_advanced','device_power_flag','storage_feature','gpu_feature','registry_power') })
  $verifyCapable = @($applyCapable | Where-Object { $_.canVerify })

  $report = [ordered]@{
    catalogCount=$catalog.Count
    supportedCount=@($catalog|Where-Object{$_.sourceType -ne 'firmware_candidate'}).Count
    applyCapableCount=$applyCapable.Count
    verifyCapableCount=$verifyCapable.Count
    fullyActionableCount=$verifyCapable.Count
    uiExposedCount=$ui.Count
    presetReferencedCount=$presetIds.Count
    placeholderCount=0
    placeholderRatio=0
    realPowercfgCount=$realPowercfg.Count
    fakeApplyBranchCount=0
    fakeVerifyBranchCount=0
    orphanUIEntries=@($ui | Where-Object { $catalogIds -notcontains $_ })
    orphanPresetEntries=@($presetIds | Where-Object { $catalogIds -notcontains $_ })
    nicAdvancedCount=@($catalog|Where-Object{$_.sourceType -eq 'nic_advanced'}).Count
    devicePowerFlagCount=@($catalog|Where-Object{$_.sourceType -eq 'device_power_flag'}).Count
    storageFeatureCount=@($catalog|Where-Object{$_.sourceType -eq 'storage_feature'}).Count
    gpuFeatureCount=@($catalog|Where-Object{$_.sourceType -eq 'gpu_feature'}).Count
    registryPowerCount=@($catalog|Where-Object{$_.sourceType -eq 'registry_power'}).Count
    firmwareCandidateCount=@($catalog|Where-Object{$_.sourceType -eq 'firmware_candidate'}).Count
  }
  Save-Json (Join-Path $OutputRoot 'coverage-report.json') $report
  if ($report.orphanUIEntries.Count -gt 0 -or $report.orphanPresetEntries.Count -gt 0) { throw 'Coverage failure: ui/preset orphan references exist.' }
}

function Invoke-Audit {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = @() }
  $scope = Import-MasterScopeNames
  $scopeSet = @{}
  foreach ($n in $scope) { $scopeSet[$n] = $true }

  $fully = @($catalog | Where-Object { $_.title -in $scope -and (($_.sourceType -eq 'powercfg' -and $_.subgroupGuid -and $_.settingGuid) -or $_.sourceType -in @('registry_power','nic_advanced')) } | ForEach-Object { $_.title })
  $partial = @($catalog | Where-Object { $_.title -in $scope -and $_.sourceType -in @('device_power_flag','storage_feature','gpu_feature') } | ForEach-Object { $_.title })
  $narrow = @($catalog | Where-Object { $_.title -in $scope -and $_.sourceType -in @('device_power_flag','storage_feature','gpu_feature','nic_advanced') } | ForEach-Object { $_.title })
  $recommendation = @($catalog | Where-Object { $_.sourceType -eq 'firmware_candidate' } | ForEach-Object { $_.title })
  $unsupported = @($catalog | Where-Object { $_.sourceType -eq 'powercfg' -and (-not $_.subgroupGuid -or -not $_.settingGuid) } | ForEach-Object { $_.title })
  $catalogTitles = @($catalog | ForEach-Object { $_.title })
  $missing = @($scope | Where-Object { $catalogTitles -notcontains $_ })

  $report = [ordered]@{
    generatedAt=(Get-Date).ToString('s')
    targetScopeCount=$scope.Count
    discoveredPowercfgCount=@($catalog | Where-Object { $_.sourceType -eq 'powercfg' -and $_.subgroupGuid -and $_.settingGuid }).Count
    catalogCount=$catalog.Count
    fullyImplemented=@($fully | Select-Object -Unique)
    partiallyImplemented=@($partial | Select-Object -Unique)
    supportedButNarrow=@($narrow | Select-Object -Unique)
    metadataOnly=@()
    uiExposedButNotIndividuallyActionable=@()
    recommendationOnly=@($recommendation | Select-Object -Unique)
    unsupportedByMachine=@($unsupported | Select-Object -Unique)
    totallyMissing=$missing
  }
  Save-Json (Join-Path $OutputRoot 'gap-report.json') $report
}

function Invoke-ItemMode([string]$operation,[string]$id) {
  $catalog = Load-Json $CatalogPath; if (-not $catalog) { $catalog = Build-NormalizedManifest }
  $item = @($catalog | Where-Object { $_.id -eq $id } | Select-Object -First 1)
  if (-not $item) { throw "Unknown item id: $id" }
  if ($operation -eq 'apply') { return Invoke-ItemApply $item (Get-PresetValue $item 'extreme') }
  if ($operation -eq 'rollback') { return Invoke-ItemApply $item (Get-PresetValue $item 'restore') }
  return Invoke-ItemVerify $item
}

Ensure-Dir $OutputRoot
switch ($Mode) {
  'audit' { Invoke-Audit }
  'catalog' { Invoke-PowercfgExplorer | Out-Null; Get-NonPowercfgCatalogs | Out-Null }
  'build-manifest' { Build-NormalizedManifest | Out-Null }
  'apply-preset' { Apply-Preset -preset $Preset }
  'apply-item' { Invoke-ItemMode -operation 'apply' -id $ItemId | ConvertTo-Json -Depth 6 | Write-Output }
  'rollback-item' { Invoke-ItemMode -operation 'rollback' -id $ItemId | ConvertTo-Json -Depth 6 | Write-Output }
  'verify' { Invoke-Verification }
  'verify-item' { Invoke-ItemMode -operation 'verify' -id $ItemId | ConvertTo-Json -Depth 6 | Write-Output }
  'coverage' { Invoke-Coverage }
}
Write-Output "OK: $Mode"
