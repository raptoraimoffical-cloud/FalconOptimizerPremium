param(
  [switch]$JsonOnly
)

$ErrorActionPreference = "SilentlyContinue"

function Get-Value([string]$path,[string]$name){
  try{
    $v = (Get-ItemProperty -Path $path -Name $name -ErrorAction Stop).$name
    return $v
  }catch{ return $null }
}

function Cmd([string]$c){
  try{ return (& cmd.exe /c $c 2>&1) -join "`n" }catch{ return "" }
}

# Power plan
$activeGuid = ""
try{
  $txt = Cmd "powercfg /getactivescheme"
  if($txt -match 'GUID:\s*([0-9a-fA-F-]{36})'){ $activeGuid = $Matches[1] }
}catch{}

# HAGS (HwSchMode) 2 = on, 1 = default off, 0 = off (varies)
$hags = Get-Value "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode"
# Game Mode
$gameMode = Get-Value "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode"
# Game DVR
$gameDvr = Get-Value "HKCU:\System\GameConfigStore" "GameDVR_Enabled"
# MPO disable
$mpo = Get-Value "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode"

# USB selective suspend
$usbSel = Get-Value "HKLM:\SYSTEM\CurrentControlSet\Services\USB" "DisableSelectiveSuspend"

# Defender realtime
$defRT = Get-Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring"

# NIC power saving (rough): list adapters and power mgmt
$adapters = @()
try{
  $nics = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" }
  foreach($n in $nics){
    $pm = $null
    try{ $pm = Get-NetAdapterPowerManagement -Name $n.Name }catch{}
    $adapters += [pscustomobject]@{
      name=$n.Name; ifDesc=$n.InterfaceDescription; linkSpeed=$n.LinkSpeed;
      allowComputerToTurnOff=$pm.AllowComputerToTurnOffDevice;
      wakeOnMagicPacket=$pm.WakeOnMagicPacket;
      wakeOnPattern=$pm.WakeOnPattern;
    }
  }
}catch{}

# Startup items count
$startupCount = 0
try{
  $runKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
  )
  foreach($k in $runKeys){
    try{
      $props = (Get-ItemProperty -Path $k).psobject.Properties | Where-Object { $_.Name -notmatch '^PS' }
      $startupCount += ($props | Measure-Object).Count
    }catch{}
  }
}catch{}

# Summary scoring (simple)
$flags = @()
if($usbSel -ne 1){ $flags += "USB selective suspend may be enabled (possible input latency spikes)." }
if($mpo -ne 5){ $flags += "MPO may be enabled (can cause stutter on some systems)." }
if($gameDvr -eq 1){ $flags += "Game DVR enabled (can add overhead)." }
if(($adapters | Where-Object { $_.allowComputerToTurnOff -eq "Enabled" }).Count -gt 0){
  $flags += "NIC power saving enabled on an active adapter."
}

$out = [pscustomobject]@{
  ok=$true
  activePowerPlanGuid=$activeGuid
  graphics=@{
    hags=$hags
    gameMode=$gameMode
    gameDvr=$gameDvr
    mpoOverlayTestMode=$mpo
  }
  usb=@{ disableSelectiveSuspend=$usbSel }
  defender=@{ disableRealtimeMonitoring=$defRT }
  network=@{ adapters=$adapters }
  startup=@{ runKeyItemCount=$startupCount }
  notes=$flags
  nextSteps=@(
    "Apply Falcon Competitive or Max FPS plan for reduced parking/power-saving behavior.",
    "Disable USB selective suspend for lower input jitter.",
    "If you get stutters, try disabling MPO (reversible).",
    "For ping/consistency: Ethernet + router SQM (cake/fq_codel) beats Windows tweaks."
  )
}

if($JsonOnly){
  $out | ConvertTo-Json -Depth 8
}else{
  $out | ConvertTo-Json -Depth 8
}
