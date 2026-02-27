param(
  [ValidateSet("gpu","usb","network","all")]
  [string]$Target = "gpu",
  [ValidateSet("enable","disable","status")]
  [string]$Action = "enable"
)

$ErrorActionPreference="Stop"

function Set-Msi([string]$instanceId,[int]$msi){
  $base = "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
  if(-not (Test-Path $base)){ New-Item -Path $base -Force | Out-Null }
  New-ItemProperty -Path $base -Name "MSISupported" -Value $msi -PropertyType DWord -Force | Out-Null
}

function Get-Msi([string]$instanceId){
  $base = "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
  try{
    return (Get-ItemProperty -Path $base -Name "MSISupported" -ErrorAction Stop).MSISupported
  }catch{ return $null }
}

function Get-Targets([string]$t){
  $devs = @()
  $classes = @()
  if($t -eq "gpu"){ $classes = @("Display") }
  elseif($t -eq "usb"){ $classes = @("USB") }
  elseif($t -eq "network"){ $classes = @("Net") }
  elseif($t -eq "all"){ $classes = @("Display","USB","Net") }

  foreach($c in $classes){
    try{
      $d = Get-PnpDevice -Class $c -Status OK -ErrorAction SilentlyContinue
      foreach($x in $d){
        if(-not $x.InstanceId){ continue }
        $devs += [pscustomobject]@{
          class=$c
          name=$x.FriendlyName
          instanceId=$x.InstanceId
          msi=(Get-Msi $x.InstanceId)
        }
      }
    }catch{}
  }
  return $devs
}

$targets = Get-Targets $Target

if($Action -eq "status"){
  [pscustomobject]@{ ok=$true; target=$Target; devices=$targets } | ConvertTo-Json -Depth 6
  exit 0
}

$msiVal = ($Action -eq "enable") ? 1 : 0

$changed = @()
$failed = @()
foreach($d in $targets){
  try{
    Set-Msi $d.instanceId $msiVal
    $changed += $d.instanceId
  }catch{
    $failed += [pscustomobject]@{ instanceId=$d.instanceId; error=$_.Exception.Message }
  }
}

[pscustomobject]@{
  ok = ($failed.Count -eq 0)
  target = $Target
  action = $Action
  changedCount = $changed.Count
  failedCount = $failed.Count
  failed = $failed
  rebootRecommended = $true
  note = "MSI Mode is device/driver dependent. Some devices ignore this. Reboot required."
} | ConvertTo-Json -Depth 6
