param(
  [ValidateSet("competitive","balanced","extreme","revert")]
  [string]$Profile = "competitive"
)

$ErrorActionPreference="Stop"

function Set-Reg([string]$path,[string]$name,[object]$value,[string]$type="DWord"){
  if(-not (Test-Path $path)){ New-Item -Path $path -Force | Out-Null }
  New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force | Out-Null
}

function Del-Reg([string]$path,[string]$name){
  try{ Remove-ItemProperty -Path $path -Name $name -Force -ErrorAction SilentlyContinue }catch{}
}

# Backup keys (best-effort)
$bkDir = Join-Path $PSScriptRoot "..\..\backups\gpu"
if(-not (Test-Path $bkDir)){ New-Item -ItemType Directory -Force -Path $bkDir | Out-Null }
$bk = Join-Path $bkDir ("gpu-latency-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".reg")
try{
  reg.exe export "HKLM\SOFTWARE\Microsoft\Windows\Dwm" $bk /y | Out-Null
}catch{}

if($Profile -eq "revert"){
  # Revert: remove our known keys (doesn't touch others)
  Del-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode"
  Del-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode"
  Del-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled"
  Del-Reg "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode"
  Del-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled"
  [pscustomobject]@{ ok=$true; profile="revert"; note="Reverted common GPU/overlay keys. Reboot recommended." } | ConvertTo-Json -Depth 4
  exit 0
}

# Base for all
# Disable Game DVR capture
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
# Game Mode on
Set-Reg "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1

if($Profile -eq "balanced"){
  # HAGS default/off
  Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1
  # MPO default (remove override)
  Del-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode"
}
elseif($Profile -eq "competitive"){
  # HAGS off (often reduces latency variance on some rigs; user can test)
  Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1
  # Disable MPO (can fix stutter/alt-tab lag on some systems)
  Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5
}
elseif($Profile -eq "extreme"){
  # Force HAGS on (benefit varies)
  Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
  # Disable MPO
  Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5
}

[pscustomobject]@{
  ok=$true
  profile=$Profile
  rebootRecommended=$true
  applied=@(
    "Game DVR capture disabled",
    "Game Mode enabled",
    "HAGS set via HwSchMode",
    "MPO override via OverlayTestMode (if profile Competitive/Extreme)"
  )
  backupReg=$bk
  note="These are OS-side latency presets (not NVIDIA Control Panel per-profile). Reboot for full effect."
} | ConvertTo-Json -Depth 6
