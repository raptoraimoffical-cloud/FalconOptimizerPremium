param(
  [Parameter(Mandatory=$true)][string]$Action,
  [string[]]$InstanceIds = @(),
  [string]$Class = 'Display',
  [switch]$IncludeAudio
)

$ErrorActionPreference = 'Stop'

function Out-Json($obj){ $obj | ConvertTo-Json -Depth 8 -Compress }

function Ensure-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    throw 'Admin privileges required.'
  }
}

function Msi-RegPath([string]$instanceId){
  "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
}

function Affinity-RegPath([string]$instanceId){
  "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters\Interrupt Management\Affinity Policy"
}

function Supports-MSI([string]$instanceId){
  $p = Msi-RegPath $instanceId
  return (Test-Path $p)
}

function List-Targets {
  $targets = @()
  $classes = @($Class)
  if($IncludeAudio){ $classes += 'MEDIA' }
  foreach($c in $classes){
    $devs = @(Get-PnpDevice -PresentOnly -Class $c -ErrorAction SilentlyContinue)
    foreach($d in $devs){
      if(-not $d.InstanceId){ continue }
      if(Supports-MSI $d.InstanceId){
        $targets += [pscustomobject]@{
          instanceId = $d.InstanceId
          name = ($d.FriendlyName | ForEach-Object { $_ })
          pnpClass = $c
        }
      }
    }
  }
  $targets = $targets | Sort-Object instanceId -Unique
  Out-Json @{ ok=$true; devices=$targets }
}

function Resolve-Ids([string[]]$ids){
  if($ids -and $ids.Count -gt 0){ return @($ids) }
  # If no InstanceIds passed, apply to all supported devices for the requested classes.
  $tmp = @()
  $classes = @($Class)
  if($IncludeAudio){ $classes += 'MEDIA' }
  foreach($c in $classes){
    $devs = @(Get-PnpDevice -PresentOnly -Class $c -ErrorAction SilentlyContinue)
    foreach($d in $devs){
      if($d.InstanceId -and (Supports-MSI $d.InstanceId)) { $tmp += $d.InstanceId }
    }
  }
  return @($tmp | Sort-Object -Unique)
}

function Set-MSI([string]$instanceId, [bool]$enable){
  $p = Msi-RegPath $instanceId
  if(-not (Test-Path $p)) { return $false }
  if($enable){
    New-ItemProperty -Path $p -Name 'MSISupported' -PropertyType DWord -Value 1 -Force | Out-Null
  } else {
    Remove-ItemProperty -Path $p -Name 'MSISupported' -ErrorAction SilentlyContinue
  }

  # "Priority: Undefined" in MSI Utility corresponds to not forcing DevicePriority.
  $a = Affinity-RegPath $instanceId
  if(Test-Path $a){
    Remove-ItemProperty -Path $a -Name 'DevicePriority' -ErrorAction SilentlyContinue
  }
  return $true
}

try {
  switch($Action.ToLowerInvariant()){
    'list' { List-Targets; exit 0 }

    'apply' {
      Ensure-Admin
      $ids = Resolve-Ids $InstanceIds
      if(-not $ids -or $ids.Count -eq 0){ throw 'No MSI-capable devices found for the selected class(es).' }
      $ok = @()
      foreach($id in $ids){
        if(Set-MSI $id $true){ $ok += $id }
      }
      Out-Json @{ ok=$true; applied=$ok; requiresReboot=$true }
      exit 0
    }

    'revert' {
      Ensure-Admin
      $ids = Resolve-Ids $InstanceIds
      if(-not $ids -or $ids.Count -eq 0){ throw 'No MSI-capable devices found for the selected class(es).' }
      $ok = @()
      foreach($id in $ids){
        if(Set-MSI $id $false){ $ok += $id }
      }
      Out-Json @{ ok=$true; reverted=$ok; requiresReboot=$true }
      exit 0
    }

    default { throw "Unknown Action: $Action" }
  }
} catch {
  Out-Json @{ ok=$false; error=$_.Exception.Message }
  exit 1
}
