param(
  [Parameter(Mandatory=$true)][ValidateSet('scan','set')] [string]$Mode,
  [string]$OutputPath,
  [string]$Subgroup,
  [string]$Setting,
  [string]$AcValue,
  [string]$DcValue
)

$ErrorActionPreference = 'SilentlyContinue'

function Parse-HexOrDec([string]$v) {
  if ([string]::IsNullOrWhiteSpace($v)) { return $null }
  $t = $v.Trim()
  if ($t -match '^0x[0-9a-fA-F]+$') { return [Convert]::ToInt64($t,16) }
  $n = 0
  if ([int64]::TryParse($t,[ref]$n)) { return $n }
  return $t
}

function Get-AliasMap {
  $m = @{}
  $raw = (powercfg /aliases | Out-String)
  foreach($ln in ($raw -split "`r?`n")){
    if($ln -match '^\s*([A-Z0-9_]+)\s+([0-9a-fA-F\-]{36})\s*$'){
      $m[$Matches[2].ToLowerInvariant()] = $Matches[1]
    }
  }
  return $m
}

function Get-Recommendation([object]$row) {
  $name = ([string]$row.settingName).ToLowerInvariant()
  $alias = ([string]$row.settingAlias).ToLowerInvariant()
  $unit = ([string]$row.units).ToLowerInvariant()
  $enumText = ((@($row.enumChoices) -join ' ') + ' ' + $name + ' ' + $alias).ToLowerInvariant()

  $ac = $row.currentAcValue
  $dc = $row.currentDcValue
  $reason = 'Keep current values (no explicit gaming recommendation rule matched).'

  if ($enumText -match 'idle disable') {
    $ac = 1; $dc = 1
    $reason = 'Disable processor idle states when available for lower wake latency.'
  } elseif ($enumText -match 'minimum processor state|min cores|core parking min') {
    $ac = 100
    if ($dc -is [int] -or $dc -is [long]) { $dc = [Math]::Min(100,[Math]::Max(5,$dc)) }
    $reason = 'Prefer fully unparked/high minimum state on AC for latency-sensitive workloads.'
  } elseif ($enumText -match 'maximum processor state|max cores|core parking max') {
    $ac = 100; $dc = 100
    $reason = 'Keep processor ceiling fully unlocked.'
  } elseif ($enumText -match 'boost') {
    if ($row.max -ne $null) { $ac = $row.max; $dc = $row.max }
    $reason = 'Use highest supported boost mode for max performance presets.'
  } elseif ($enumText -match 'energy performance preference|epp') {
    $ac = 0; $dc = 0
    $reason = 'EPP=0 is the performance-biased policy.'
  } elseif ($enumText -match 'link state power management|aspm|pcie') {
    $ac = 0; $dc = 0
    $reason = 'Disable PCIe link power savings to avoid link wake latency.'
  } elseif ($enumText -match 'usb selective suspend|selective suspend') {
    $ac = 0; $dc = 0
    $reason = 'Disable USB selective suspend for latency/compatibility.'
  } elseif ($enumText -match 'sleep after|hibernate after|standby idle') {
    $ac = 0; $dc = 0
    $reason = 'Disable automatic sleep/hibernate for competitive/gaming presets.'
  } elseif ($enumText -match 'wireless|wifi|wlan') {
    if ($row.max -ne $null) { $ac = $row.max; $dc = $row.max }
    $reason = 'Use maximum performance wireless mode.'
  } elseif ($unit -match 'sec|seconds') {
    if (($name -match 'timeout|idle') -or ($alias -match 'timeout|idle')) {
      $ac = 0
      $reason = 'Set timeout to 0 where 0 indicates disabled.'
    }
  }

  return [pscustomobject]@{
    ac = $ac
    dc = $dc
    reason = $reason
  }
}

if ($Mode -eq 'scan') {
  if ([string]::IsNullOrWhiteSpace($OutputPath)) { throw 'OutputPath required for scan mode' }
  $aliases = Get-AliasMap
  $qh = (powercfg /qh SCHEME_CURRENT | Out-String)
  $lines = $qh -split "`r?`n"
  $rows = @()
  $sgGuid=''; $sgName=''; $setGuid=''; $setName=''; $desc=''; $min=$null; $max=$null; $inc=$null; $units=''; $ac=$null; $dc=$null; $hidden = $false
  $enums = @()

  function Flush-Row {
    if (-not [string]::IsNullOrWhiteSpace($setGuid) -and -not [string]::IsNullOrWhiteSpace($sgGuid)) {
      $row = [pscustomobject]@{
        subgroupGuid = $sgGuid
        subgroupAlias = ($aliases[$sgGuid.ToLowerInvariant()] | Out-String).Trim()
        subgroupName = $sgName
        settingGuid = $setGuid
        settingAlias = ($aliases[$setGuid.ToLowerInvariant()] | Out-String).Trim()
        settingName = $setName
        description = $desc
        min = $min
        max = $max
        increment = $inc
        units = $units
        enumChoices = @($enums)
        currentAcValue = (Parse-HexOrDec $ac)
        currentDcValue = (Parse-HexOrDec $dc)
        hiddenOrExposed = $(if($hidden){'hidden'}else{'exposed'})
        supportStatus = 'supported'
        source = 'powercfg'
      }
      $rec = Get-Recommendation $row
      $row | Add-Member -NotePropertyName recommendedGamingAcValue -NotePropertyValue $rec.ac
      $row | Add-Member -NotePropertyName recommendedGamingDcValue -NotePropertyValue $rec.dc
      $row | Add-Member -NotePropertyName recommendationReason -NotePropertyValue $rec.reason
      $rows += $row
    }
    $script:setGuid=''; $script:setName=''; $script:desc=''; $script:min=$null; $script:max=$null; $script:inc=$null; $script:units=''; $script:ac=$null; $script:dc=$null; $script:hidden=$false; $script:enums=@()
  }

  foreach($line in $lines){
    if($line -match '^\s*Subgroup GUID:\s*([0-9a-fA-F\-]{36})\s*\((.*)\)'){ Flush-Row; $sgGuid=$Matches[1]; $sgName=$Matches[2]; continue }
    if($line -match '^\s*Power Setting GUID:\s*([0-9a-fA-F\-]{36})\s*\((.*)\)'){ Flush-Row; $setGuid=$Matches[1]; $setName=$Matches[2]; continue }
    if($line -match '^\s*Possible Setting Friendly Name:\s*(.*)$'){ $enums += $Matches[1].Trim(); continue }
    if($line -match '^\s*Possible Setting Description:\s*(.*)$'){ if([string]::IsNullOrWhiteSpace($desc)){ $desc=$Matches[1].Trim() }; continue }
    if($line -match '^\s*Minimum Possible Setting:\s*(0x[0-9a-fA-F]+|\d+)'){ $min=Parse-HexOrDec $Matches[1]; continue }
    if($line -match '^\s*Maximum Possible Setting:\s*(0x[0-9a-fA-F]+|\d+)'){ $max=Parse-HexOrDec $Matches[1]; continue }
    if($line -match '^\s*Possible Settings increment:\s*(0x[0-9a-fA-F]+|\d+)'){ $inc=Parse-HexOrDec $Matches[1]; continue }
    if($line -match '^\s*Possible Settings units:\s*(.*)$'){ $units=$Matches[1].Trim(); continue }
    if($line -match '^\s*Attributes:\s*(.*)$'){ $hidden = ($Matches[1] -match 'HIDDEN'); continue }
    if($line -match '^\s*Current AC Power Setting Index:\s*(0x[0-9a-fA-F]+|\d+)'){ $ac=$Matches[1]; continue }
    if($line -match '^\s*Current DC Power Setting Index:\s*(0x[0-9a-fA-F]+|\d+)'){ $dc=$Matches[1]; continue }
  }
  Flush-Row

  $dir = Split-Path -Parent $OutputPath
  if(!(Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }

  $rows | ConvertTo-Json -Depth 8 | Out-File -Encoding utf8 $OutputPath

  $prettyPath = [System.IO.Path]::ChangeExtension($OutputPath, '.pretty.json')
  $rows | Sort-Object subgroupName, settingName | ConvertTo-Json -Depth 8 | Out-File -Encoding utf8 $prettyPath

  $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, '.csv')
  $rows | Select-Object subgroupGuid, subgroupAlias, subgroupName, settingGuid, settingAlias, settingName, hiddenOrExposed, min, max, increment, units, currentAcValue, currentDcValue, recommendedGamingAcValue, recommendedGamingDcValue, supportStatus, source | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath

  Write-Output ("OK scan: " + $rows.Count + " settings")
  Write-Output ("JSON=" + $OutputPath)
  Write-Output ("CSV=" + $csvPath)
  Write-Output ("PRETTY=" + $prettyPath)
  exit 0
}

if($Mode -eq 'set') {
  if ([string]::IsNullOrWhiteSpace($Subgroup) -or [string]::IsNullOrWhiteSpace($Setting)) { throw 'Subgroup and Setting required for set mode' }
  if (-not [string]::IsNullOrWhiteSpace($AcValue)) { powercfg -setacvalueindex SCHEME_CURRENT $Subgroup $Setting $AcValue | Out-Null }
  if (-not [string]::IsNullOrWhiteSpace($DcValue)) { powercfg -setdcvalueindex SCHEME_CURRENT $Subgroup $Setting $DcValue | Out-Null }
  powercfg /setactive SCHEME_CURRENT | Out-Null
  $verify = (powercfg /query SCHEME_CURRENT $Subgroup $Setting | Out-String)
  Write-Output 'OK set'
  Write-Output $verify
  exit 0
}
