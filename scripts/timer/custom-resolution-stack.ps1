param(
  [ValidateSet('start','stop','verify')]
  [string]$Action = 'verify',
  [int]$ResolutionMicros = 5000,
  [switch]$Persistent,
  [switch]$EnableGlobalTimer,
  [switch]$RevertGlobalTimer
)

$ErrorActionPreference = 'Stop'

function Resolve-ToolPath([string]$name){
  $roots = @($PSScriptRoot, (Join-Path $PSScriptRoot '..'), (Join-Path $PSScriptRoot '..\..'))
  $candidates = @()
  foreach($r in $roots){
    $base = (Resolve-Path -LiteralPath $r).Path
    $candidates += @(
      (Join-Path $base $name),
      (Join-Path $base ("tools/$name")),
      (Join-Path $base ("tools/FalconLibrary/$name"))
    )
  }
  foreach($c in $candidates){ if(Test-Path -LiteralPath $c){ return (Resolve-Path -LiteralPath $c).Path } }
  return $null
}

function Get-RunValue(){
  try { return (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'FalconCustomTimerStack' -ErrorAction Stop).FalconCustomTimerStack } catch { return $null }
}

$setTimer = Resolve-ToolPath 'SetTimerResolution.exe'
$dpclat = Resolve-ToolPath 'dpclat.exe'
$runner = Join-Path $PSHOME 'powershell.exe'
$status = [ordered]@{
  action = $Action
  setTimerExists = [bool]$setTimer
  dpclatExists = [bool]$dpclat
  setTimerPath = $setTimer
  dpclatPath = $dpclat
  setTimerRunning = [bool](Get-Process -Name 'SetTimerResolution' -ErrorAction SilentlyContinue)
  dpclatRunning = [bool](Get-Process -Name 'dpclat' -ErrorAction SilentlyContinue)
  globalTimerResolutionRequests = $null
  startupEnabled = [bool](Get-RunValue)
  configuredResolutionMicros = $ResolutionMicros
}

try {
  $status.globalTimerResolutionRequests = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel' -Name 'GlobalTimerResolutionRequests' -ErrorAction Stop).GlobalTimerResolutionRequests
} catch {}

if($Action -eq 'verify'){
  $status.ok = ($status.setTimerExists -and $status.dpclatExists)
  $status.statusText = if($status.setTimerRunning -and $status.dpclatRunning){ 'Enabled' } elseif($status.setTimerExists -and $status.dpclatExists){ 'Not Enabled' } else { 'Missing tools' }
  $status | ConvertTo-Json -Depth 6
  exit (if($status.ok){0}else{2})
}

if($Action -eq 'start'){
  if(-not $setTimer){ throw 'SetTimerResolution.exe not found' }
  if(-not $dpclat){ throw 'dpclat.exe not found' }

  if($EnableGlobalTimer){
    New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel' -Name 'GlobalTimerResolutionRequests' -Type DWord -Value 1
  }

  if(-not (Get-Process -Name 'dpclat' -ErrorAction SilentlyContinue)){
    Start-Process -FilePath $dpclat -WindowStyle Minimized | Out-Null
  }
  if(-not (Get-Process -Name 'SetTimerResolution' -ErrorAction SilentlyContinue)){
    Start-Process -FilePath $setTimer -ArgumentList "--resolution $ResolutionMicros" -WindowStyle Hidden | Out-Null
  }

  Start-Sleep -Milliseconds 600

  if($Persistent){
    $cmd = "`\"$runner`\" -NoProfile -ExecutionPolicy Bypass -File `\"$PSCommandPath`\" -Action start -ResolutionMicros $ResolutionMicros"
    if($EnableGlobalTimer){ $cmd += ' -EnableGlobalTimer' }
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'FalconCustomTimerStack' -Type String -Value $cmd
  }

  $verify = & $PSCommandPath -Action verify -ResolutionMicros $ResolutionMicros
  Write-Output $verify
  exit 0
}

if($Action -eq 'stop'){
  Get-Process -Name 'SetTimerResolution' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Get-Process -Name 'dpclat' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'FalconCustomTimerStack' -ErrorAction SilentlyContinue
  if($RevertGlobalTimer){
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel' -Name 'GlobalTimerResolutionRequests' -ErrorAction SilentlyContinue
  }
  $verify = & $PSCommandPath -Action verify -ResolutionMicros $ResolutionMicros
  Write-Output $verify
  exit 0
}
