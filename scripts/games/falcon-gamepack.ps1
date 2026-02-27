param(
  [Parameter(Mandatory=$true)][ValidateSet(
    'fortnite','valorant','cs2','apex','cod','overwatch2','rocketleague','gta5','league','geforcenow'
  )]
  [string]$Game,

  [Parameter(Mandatory=$true)][ValidateSet(
    'EnableQoS','DisableQoS',
    'EnableLauncherQoS','DisableLauncherQoS',
    'SetGpuPref','RemoveGpuPref',
    'DisableFSO','EnableFSO',
    'DisableDPI','EnableDPI',
    'StartTimer500us','StopTimer',
    'SetHighPriorityNow','SetNormalPriorityNow',
    'ApplyConfigBaseline','RestoreConfigBaseline',
    'ClearCaches',
    'CloseOverlays'
  )]
  [string]$Action
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string]$m){ Write-Output ("[FalconGamePack] $m") }

function Ensure-Dir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Backup-File([string]$src,[string]$backupId){
  if([string]::IsNullOrWhiteSpace($src) -or !(Test-Path -LiteralPath $src -PathType Leaf)){
    return $null
  }
  $root = Join-Path $env:ProgramData 'FalconOptimizer'
  $bdir = Join-Path $root (Join-Path 'backups' $Game)
  Ensure-Dir $bdir
  $safeId = ($backupId -replace '[^a-zA-Z0-9_.-]','_')
  $dst = Join-Path $bdir ("$safeId.bak")
  Copy-Item -LiteralPath $src -Destination $dst -Force
  return $dst
}

function Restore-File([string]$src,[string]$backupId){
  $root = Join-Path $env:ProgramData 'FalconOptimizer'
  $bdir = Join-Path $root (Join-Path 'backups' $Game)
  $safeId = ($backupId -replace '[^a-zA-Z0-9_.-]','_')
  $bak = Join-Path $bdir ("$safeId.bak")
  if(Test-Path -LiteralPath $bak -PathType Leaf){
    Copy-Item -LiteralPath $bak -Destination $src -Force
    Write-Info "Restored backup -> $src"
    return $true
  }
  return $false
}

function Get-SteamCommonDirs{
  $dirs = @()
  $pf = $env:ProgramFiles
  $pfx86 = ${env:ProgramFiles(x86)}
  foreach($base in @($pfx86,$pf)){
    if([string]::IsNullOrWhiteSpace($base)){ continue }
    $cand = Join-Path $base 'Steam\steamapps\common'
    if(Test-Path -LiteralPath $cand -PathType Container){ $dirs += $cand }
  }
  return ($dirs | Select-Object -Unique)
}

function Find-FirstExisting([string[]]$paths){
  foreach($p in $paths){
    if([string]::IsNullOrWhiteSpace($p)){ continue }
    try{ if(Test-Path -LiteralPath $p){ return $p } }catch{}
  }
  return $null
}

function Get-GameExeCandidates{
  $pf = $env:ProgramFiles
  $pfx86 = ${env:ProgramFiles(x86)}
  $lad = $env:LOCALAPPDATA
  $steamCommons = Get-SteamCommonDirs

  switch($Game){
    'fortnite' {
      return @(
        (Join-Path $pf   'Epic Games\Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe'),
        (Join-Path $pfx86 'Epic Games\Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe')
      )
    }
    'valorant' {
      return @(
        (Join-Path $pf   'Riot Games\VALORANT\live\ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe'),
        (Join-Path $pfx86 'Riot Games\VALORANT\live\ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe')
      )
    }
    'cs2' {
      $cands = @()
      foreach($sc in $steamCommons){
        $cands += (Join-Path $sc 'Counter-Strike Global Offensive\game\bin\win64\cs2.exe')
        $cands += (Join-Path $sc 'Counter-Strike 2\game\bin\win64\cs2.exe')
      }
      return $cands
    }
    'apex' {
      $cands = @()
      foreach($sc in $steamCommons){ $cands += (Join-Path $sc 'Apex Legends\r5apex.exe') }
      $cands += (Join-Path $pf   'EA Games\Apex Legends\r5apex.exe')
      $cands += (Join-Path $pfx86 'EA Games\Apex Legends\r5apex.exe')
      $cands += (Join-Path $pf   'Origin Games\Apex\r5apex.exe')
      $cands += (Join-Path $pfx86 'Origin Games\Apex\r5apex.exe')
      return $cands
    }
    'cod' {
      # CoD paths vary a lot (Battle.net / Steam). Use QoS by wildcard and only do exe-scoped actions if found.
      $cands = @()
      foreach($sc in $steamCommons){
        $cands += (Join-Path $sc 'Call of Duty HQ\cod.exe')
        $cands += (Join-Path $sc 'Call of Duty\cod.exe')
      }
      $cands += (Join-Path $pf 'Call of Duty\_retail_\cod.exe')
      $cands += (Join-Path $pf 'Battle.net\Battle.net.exe')
      return $cands
    }
    'overwatch2' {
      return @(
        (Join-Path $pf 'Overwatch\_retail_\Overwatch.exe'),
        (Join-Path $pf 'Overwatch 2\_retail_\Overwatch.exe'),
        (Join-Path $pf 'Battle.net\Battle.net.exe')
      )
    }
    'rocketleague' {
      $cands = @()
      foreach($sc in $steamCommons){ $cands += (Join-Path $sc 'rocketleague\Binaries\Win64\RocketLeague.exe') }
      $cands += (Join-Path $pf 'Epic Games\rocketleague\Binaries\Win64\RocketLeague.exe')
      $cands += (Join-Path $pfx86 'Epic Games\rocketleague\Binaries\Win64\RocketLeague.exe')
      return $cands
    }
    'gta5' {
      $cands = @()
      foreach($sc in $steamCommons){ $cands += (Join-Path $sc 'Grand Theft Auto V\GTA5.exe') }
      $cands += (Join-Path $pf 'Rockstar Games\Grand Theft Auto V\GTA5.exe')
      $cands += (Join-Path $pfx86 'Rockstar Games\Grand Theft Auto V\GTA5.exe')
      return $cands
    }
    'league' {
      return @(
        (Join-Path $pf   'Riot Games\League of Legends\LeagueClient.exe'),
        (Join-Path $pfx86 'Riot Games\League of Legends\LeagueClient.exe')
      )
    }
    'geforcenow' {
      return @(
        (Join-Path $pf 'NVIDIA Corporation\NVIDIA GeForce NOW\GeForceNOW.exe'),
        (Join-Path $pfx86 'NVIDIA Corporation\NVIDIA GeForce NOW\GeForceNOW.exe')
      )
    }
  }
}

function Get-ExistingGameExePaths{
  $cands = Get-GameExeCandidates
  $found = @()
  foreach($p in $cands){
    try{ if(Test-Path -LiteralPath $p -PathType Leaf){ $found += (Resolve-Path -LiteralPath $p).Path } }catch{}
  }
  return ($found | Select-Object -Unique)
}

function Set-QoS([string]$policyName,[string]$exeWildcard){
  Write-Info "QoS create: $policyName for $exeWildcard"
  try{ New-NetQosPolicy -Name $policyName -AppPathNameMatchCondition $exeWildcard -DSCPAction 46 -PolicyStore ActiveStore -ErrorAction SilentlyContinue | Out-Null }catch{}
}

function Remove-QoS([string]$policyName){
  Write-Info "QoS remove: $policyName"
  try{ Remove-NetQosPolicy -Name $policyName -PolicyStore ActiveStore -Confirm:$false -ErrorAction SilentlyContinue | Out-Null }catch{}
}

function Set-AppCompatLayer([string]$exePath,[string]$layerValue){
  $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
  if(!(Test-Path $key)){ New-Item -Path $key -Force | Out-Null }
  New-ItemProperty -Path $key -Name $exePath -Value $layerValue -PropertyType String -Force | Out-Null
  Write-Info "AppCompat: $exePath -> $layerValue"
}

function Remove-AppCompatLayer([string]$exePath){
  $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
  try{ Remove-ItemProperty -Path $key -Name $exePath -ErrorAction SilentlyContinue | Out-Null }catch{}
  Write-Info "AppCompat removed: $exePath"
}

function Set-GpuPreference([string]$exePath,[int]$pref){
  $key = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
  if(!(Test-Path $key)){ New-Item -Path $key -Force | Out-Null }
  $val = "GpuPreference=$pref;"
  New-ItemProperty -Path $key -Name $exePath -Value $val -PropertyType String -Force | Out-Null
  Write-Info "GPU Pref: $exePath -> $val"
}

function Remove-GpuPreference([string]$exePath){
  $key = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
  try{ Remove-ItemProperty -Path $key -Name $exePath -ErrorAction SilentlyContinue | Out-Null }catch{}
  Write-Info "GPU Pref removed: $exePath"
}

function Start-Timer500us{
  $timer = Join-Path $PSScriptRoot '..\timer-helper.ps1'
  $timer = (Resolve-Path -LiteralPath $timer).Path
  Write-Info "Starting timer-helper at 500us (0.5ms)"
  Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', $timer, '-Resolution','5000') -WindowStyle Hidden
}

function Stop-Timer{
  Write-Info "Stopping timer-helper processes"
  try{
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -like '*timer-helper.ps1*' } |
      ForEach-Object { try{ Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }catch{} }
  }catch{}
}

function Set-PriorityNow([string[]]$procNames,[string]$prio){
  $setAny = $false
  foreach($n in $procNames){
    $p = Get-Process -Name $n -ErrorAction SilentlyContinue
    foreach($pp in @($p)){
      try{ $pp.PriorityClass = $prio; $setAny = $true; Write-Info "Priority: $($pp.ProcessName) -> $prio" }catch{}
    }
  }
  if(-not $setAny){ throw "Game process not running" }
}

function Get-GameProcNames{
  switch($Game){
    'fortnite' { return @('FortniteClient-Win64-Shipping') }
    'valorant' { return @('VALORANT-Win64-Shipping') }
    'cs2' { return @('cs2') }
    'apex' { return @('r5apex') }
    'cod' { return @('cod') }
    'overwatch2' { return @('Overwatch') }
    'rocketleague' { return @('RocketLeague') }
    'gta5' { return @('GTA5') }
    'league' { return @('League of Legends','LeagueClientUx','LeagueClient') }
    'geforcenow' { return @('GeForceNOW') }
  }
}

function Ensure-LineInFile([string]$path,[string]$line){
  Ensure-Dir (Split-Path -Parent $path)
  if(!(Test-Path -LiteralPath $path)){
    Set-Content -LiteralPath $path -Value $line -Encoding UTF8
    return
  }
  $txt = Get-Content -LiteralPath $path -ErrorAction SilentlyContinue
  if($txt -notcontains $line){ Add-Content -LiteralPath $path -Value $line -Encoding UTF8 }
}

function Upsert-IniKV([string]$path,[string]$key,[string]$value){
  Ensure-Dir (Split-Path -Parent $path)
  if(!(Test-Path -LiteralPath $path)){
    Set-Content -LiteralPath $path -Value ("$key=$value") -Encoding UTF8
    return
  }
  $c = Get-Content -LiteralPath $path -ErrorAction SilentlyContinue
  $re = '^' + [Regex]::Escape($key) + '\s*='
  $found = $false
  $out = foreach($l in $c){
    if($l -match $re){ $found = $true; "$key=$value" } else { $l }
  }
  if(-not $found){ $out += "$key=$value" }
  Set-Content -LiteralPath $path -Value $out -Encoding UTF8
}

function Apply-ConfigBaseline{
  switch($Game){
    'fortnite' {
      $cfg = Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini'
      Backup-File $cfg 'GameUserSettings.ini' | Out-Null
      Upsert-IniKV $cfg 'bUseVSync' 'False'
      Upsert-IniKV $cfg 'FrameRateLimit' '0.000000'
      Upsert-IniKV $cfg 'bShowGrass' 'False'
      Upsert-IniKV $cfg 'bMotionBlur' 'False'
      Write-Info "Patched Fortnite GameUserSettings.ini (baseline)"
    }
    'cs2' {
      $exe = (Get-ExistingGameExePaths | Select-Object -First 1)
      if(-not $exe){ throw 'CS2 not found (Steam path not detected)'
      }
      $root = Split-Path -Parent (Split-Path -Parent $exe) # ...\game\bin\win64 -> ...\game\bin
      $gameDir = Split-Path -Parent (Split-Path -Parent $root) # ...\game
      $cfgDir = Join-Path $gameDir 'csgo\cfg'
      $auto = Join-Path $cfgDir 'autoexec.cfg'
      Backup-File $auto 'autoexec.cfg' | Out-Null
      Ensure-Dir $cfgDir
      $lines = @(
        'fps_max 0',
        'fps_max_ui 0',
        'rate 786432',
        'cl_showfps 0'
      )
      Set-Content -LiteralPath $auto -Value $lines -Encoding ASCII
      Write-Info "Wrote CS2 autoexec.cfg baseline"
    }
    'apex' {
      $auto = Join-Path $env:USERPROFILE 'Saved Games\Respawn\Apex\local\autoexec.cfg'
      Backup-File $auto 'autoexec.cfg' | Out-Null
      $lines = @(
        'fps_max 0',
        'cl_showfps 0',
        'mat_queue_mode 2'
      )
      Set-Content -LiteralPath $auto -Value $lines -Encoding ASCII
      Write-Info "Wrote Apex autoexec.cfg baseline"
    }
    'rocketleague' {
      $ini = Join-Path $env:USERPROFILE 'Documents\My Games\Rocket League\TAGame\Config\TASystemSettings.ini'
      Backup-File $ini 'TASystemSettings.ini' | Out-Null
      Upsert-IniKV $ini 'AllowPerFrameSleep' 'False'
      Upsert-IniKV $ini 'bSmoothFrameRate' 'False'
      Write-Info "Patched Rocket League TASystemSettings.ini baseline"
    }
    'overwatch2' {
      $ini = Join-Path $env:USERPROFILE 'Documents\Overwatch\Settings\Settings_v0.ini'
      Backup-File $ini 'Settings_v0.ini' | Out-Null
      Upsert-IniKV $ini 'UseGPUClockForRendering' '1'
      Upsert-IniKV $ini 'ReduceInputLatency' '1'
      Write-Info "Patched Overwatch settings baseline"
    }
    default {
      throw 'No file baseline defined for this game yet (by design to avoid wrong config writes).'
    }
  }
}

function Restore-ConfigBaseline{
  switch($Game){
    'fortnite' {
      $cfg = Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini'
      if(-not (Restore-File $cfg 'GameUserSettings.ini')){ throw 'No Fortnite backup found' }
    }
    'cs2' {
      $exe = (Get-ExistingGameExePaths | Select-Object -First 1)
      if(-not $exe){ throw 'CS2 not found (Steam path not detected)' }
      $root = Split-Path -Parent (Split-Path -Parent $exe)
      $gameDir = Split-Path -Parent (Split-Path -Parent $root)
      $auto = Join-Path $gameDir 'csgo\cfg\autoexec.cfg'
      if(-not (Restore-File $auto 'autoexec.cfg')){ throw 'No CS2 autoexec backup found' }
    }
    'apex' {
      $auto = Join-Path $env:USERPROFILE 'Saved Games\Respawn\Apex\local\autoexec.cfg'
      if(-not (Restore-File $auto 'autoexec.cfg')){ throw 'No Apex autoexec backup found' }
    }
    'rocketleague' {
      $ini = Join-Path $env:USERPROFILE 'Documents\My Games\Rocket League\TAGame\Config\TASystemSettings.ini'
      if(-not (Restore-File $ini 'TASystemSettings.ini')){ throw 'No Rocket League backup found' }
    }
    'overwatch2' {
      $ini = Join-Path $env:USERPROFILE 'Documents\Overwatch\Settings\Settings_v0.ini'
      if(-not (Restore-File $ini 'Settings_v0.ini')){ throw 'No Overwatch backup found' }
    }
    default { throw 'No restore defined for this game.' }
  }
}

function Clear-Caches{
  $targets = @()
  switch($Game){
    'fortnite' { $targets += (Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\WebCaches') }
    'cs2' { $targets += (Join-Path $env:LOCALAPPDATA 'D3DSCache') }
    'apex' { $targets += (Join-Path $env:LOCALAPPDATA 'D3DSCache') }
    'valorant' { $targets += (Join-Path $env:LOCALAPPDATA 'VALORANT\Saved\Logs') }
    'cod' { $targets += (Join-Path $env:LOCALAPPDATA 'D3DSCache') }
    'overwatch2' { $targets += (Join-Path $env:LOCALAPPDATA 'D3DSCache') }
    'rocketleague' { $targets += (Join-Path $env:LOCALAPPDATA 'D3DSCache') }
    'gta5' { $targets += (Join-Path $env:LOCALAPPDATA 'D3DSCache') }
    'league' { $targets += (Join-Path $env:LOCALAPPDATA 'D3DSCache') }
    'geforcenow' { $targets += (Join-Path $env:LOCALAPPDATA 'NVIDIA\GfnRuntimeSdk\logs') }
  }
  foreach($t in ($targets | Select-Object -Unique)){
    if(Test-Path -LiteralPath $t){
      try{ Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }catch{}
      Write-Info "Cleared: $t"
    } else {
      Write-Info "Skip (not found): $t"
    }
  }
}

function Close-Overlays{
  # Best-effort close common overlay processes. This is manual and not auto-restored.
  $procNames = @(
    'Discord','DiscordPTB','DiscordCanary',
    'GameBar','XboxGameBar','XboxGameBarWidgets','GamingServices',
    'NVIDIA Share','NVIDIA Web Helper','nvsphelper64',
    'Overwolf','OverwolfBrowser',
    'SteelSeriesEngine','GG',
    'medal','Medal',
    'obs64','obs32'
  )
  foreach($p in $procNames){
    try{
      Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }catch{}
  }
  Write-Info 'Closed common overlay processes (best-effort).'
}

# ---- dispatch ----
$exePaths = Get-ExistingGameExePaths

switch($Action){
  'EnableQoS' {
    $nameMap = @{
      fortnite='Falcon Fortnite DSCP46'; valorant='Falcon Valorant DSCP46'; cs2='Falcon CS2 DSCP46'; apex='Falcon Apex DSCP46';
      cod='Falcon CoD DSCP46'; overwatch2='Falcon OW2 DSCP46'; rocketleague='Falcon RocketLeague DSCP46'; gta5='Falcon GTA5 DSCP46';
      league='Falcon LoL DSCP46'; geforcenow='Falcon GeForceNOW DSCP46'
    }
    $wildMap = @{
      fortnite='*FortniteClient-Win64-Shipping.exe'; valorant='*VALORANT-Win64-Shipping.exe'; cs2='*cs2.exe'; apex='*r5apex.exe';
      cod='*cod*.exe'; overwatch2='*Overwatch.exe'; rocketleague='*RocketLeague.exe'; gta5='*GTA5.exe'; league='*League*'; geforcenow='*GeForceNOW.exe'
    }
    Set-QoS $nameMap[$Game] $wildMap[$Game]
  }
  'EnableLauncherQoS' {
    $nameMap = @{ fortnite='Falcon Epic DSCP46'; valorant='Falcon RiotClient DSCP46'; cs2='Falcon Steam DSCP46'; apex='Falcon Steam DSCP46'; cod='Falcon BattleNet DSCP46'; overwatch2='Falcon BattleNet DSCP46'; rocketleague='Falcon Epic DSCP46'; gta5='Falcon RockstarLauncher DSCP46'; league='Falcon RiotClient DSCP46'; geforcenow='Falcon GeForceNOW DSCP46' }
    $wildMap = @{ fortnite='*EpicGamesLauncher.exe'; valorant='*RiotClientServices.exe'; cs2='*steam.exe'; apex='*steam.exe'; cod='*Battle.net.exe'; overwatch2='*Battle.net.exe'; rocketleague='*EpicGamesLauncher.exe'; gta5='*Launcher.exe'; league='*RiotClientServices.exe'; geforcenow='*GeForceNOW.exe' }
    Set-QoS $nameMap[$Game] $wildMap[$Game]
  }
  'DisableQoS' {
    $nameMap = @{
      fortnite='Falcon Fortnite DSCP46'; valorant='Falcon Valorant DSCP46'; cs2='Falcon CS2 DSCP46'; apex='Falcon Apex DSCP46';
      cod='Falcon CoD DSCP46'; overwatch2='Falcon OW2 DSCP46'; rocketleague='Falcon RocketLeague DSCP46'; gta5='Falcon GTA5 DSCP46';
      league='Falcon LoL DSCP46'; geforcenow='Falcon GeForceNOW DSCP46'
    }
    Remove-QoS $nameMap[$Game]
  }
  'DisableLauncherQoS' {
    $nameMap = @{ fortnite='Falcon Epic DSCP46'; valorant='Falcon RiotClient DSCP46'; cs2='Falcon Steam DSCP46'; apex='Falcon Steam DSCP46'; cod='Falcon BattleNet DSCP46'; overwatch2='Falcon BattleNet DSCP46'; rocketleague='Falcon Epic DSCP46'; gta5='Falcon RockstarLauncher DSCP46'; league='Falcon RiotClient DSCP46'; geforcenow='Falcon GeForceNOW DSCP46' }
    Remove-QoS $nameMap[$Game]
  }
  'SetGpuPref' {
    if(-not $exePaths -or $exePaths.Count -eq 0){ throw 'No executable detected for this game on this machine.' }
    foreach($e in $exePaths){ Set-GpuPreference $e 2 }
  }
  'RemoveGpuPref' {
    if(-not $exePaths -or $exePaths.Count -eq 0){ throw 'No executable detected for this game on this machine.' }
    foreach($e in $exePaths){ Remove-GpuPreference $e }
  }
  'DisableFSO' {
    if(-not $exePaths -or $exePaths.Count -eq 0){ throw 'No executable detected for this game on this machine.' }
    foreach($e in $exePaths){ Set-AppCompatLayer $e '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' }
  }
  'EnableFSO' {
    if(-not $exePaths -or $exePaths.Count -eq 0){ throw 'No executable detected for this game on this machine.' }
    foreach($e in $exePaths){ Remove-AppCompatLayer $e }
  }
  'DisableDPI' {
    if(-not $exePaths -or $exePaths.Count -eq 0){ throw 'No executable detected for this game on this machine.' }
    foreach($e in $exePaths){ Set-AppCompatLayer $e '~ HIGHDPIAWARE' }
  }
  'EnableDPI' {
    if(-not $exePaths -or $exePaths.Count -eq 0){ throw 'No executable detected for this game on this machine.' }
    foreach($e in $exePaths){ Remove-AppCompatLayer $e }
  }
  'StartTimer500us' { Start-Timer500us }
  'StopTimer' { Stop-Timer }
  'SetHighPriorityNow' { Set-PriorityNow (Get-GameProcNames) 'High' }
  'SetNormalPriorityNow' { Set-PriorityNow (Get-GameProcNames) 'Normal' }
  'ApplyConfigBaseline' { Apply-ConfigBaseline }
  'RestoreConfigBaseline' { Restore-ConfigBaseline }
  'ClearCaches' { Clear-Caches }
  'CloseOverlays' { Close-Overlays; Write-Info 'Closed common overlay processes (best-effort).' }
  default { throw "Unknown action: $Action" }
}

Write-Info "Done."
