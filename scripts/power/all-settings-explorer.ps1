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

if ($Mode -eq 'scan') {
  if ([string]::IsNullOrWhiteSpace($OutputPath)) { throw 'OutputPath required for scan mode' }
  $aliases = Get-AliasMap
  $qh = (powercfg /qh SCHEME_CURRENT | Out-String)
  $lines = $qh -split "`r?`n"
  $rows = @()
  $sgGuid=''; $sgName=''; $setGuid=''; $setName=''; $desc=''; $min=$null; $max=$null; $inc=$null; $units=''; $ac=$null; $dc=$null
  $enums = @()

  function Flush-Row {
    if (-not [string]::IsNullOrWhiteSpace($setGuid) -and -not [string]::IsNullOrWhiteSpace($sgGuid)) {
      $rows += [pscustomobject]@{
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
      }
    }
    $script:setGuid=''; $script:setName=''; $script:desc=''; $script:min=$null; $script:max=$null; $script:inc=$null; $script:units=''; $script:ac=$null; $script:dc=$null; $script:enums=@()
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
    if($line -match '^\s*Current AC Power Setting Index:\s*(0x[0-9a-fA-F]+|\d+)'){ $ac=$Matches[1]; continue }
    if($line -match '^\s*Current DC Power Setting Index:\s*(0x[0-9a-fA-F]+|\d+)'){ $dc=$Matches[1]; continue }
  }
  Flush-Row
  $dir = Split-Path -Parent $OutputPath
  if(!(Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $rows | ConvertTo-Json -Depth 8 | Out-File -Encoding utf8 $OutputPath
  Write-Output ("OK scan: " + $rows.Count + " settings")
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
