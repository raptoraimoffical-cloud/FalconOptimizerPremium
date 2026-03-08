param(
  [Parameter(Mandatory=$true)][string]$EntryId,
  [ValidateSet('apply','revert','check')][string]$Mode = 'check',
  [string]$Processes = '',
  [string]$Services = '',
  [string]$Tasks = '',
  [string]$StartupTokens = ''
)
$ErrorActionPreference = 'Stop'

function Split-List([string]$v){ if([string]::IsNullOrWhiteSpace($v)){ return @() }; return ($v -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
function Normalize-Proc([string]$n){ $x=$n.Trim(); if($x.ToLower().EndsWith('.exe')){$x=$x.Substring(0,$x.Length-4)}; return $x }

$procList = @(Split-List $Processes | ForEach-Object { Normalize-Proc $_ } | Select-Object -Unique)
$svcList = @(Split-List $Services | Select-Object -Unique)
$taskList = @(Split-List $Tasks | Select-Object -Unique)
$startupList = @(Split-List $StartupTokens | Select-Object -Unique)
if($startupList.Count -eq 0){ $startupList = $procList }

$stateDir = Join-Path $env:ProgramData 'FalconOptimizer\processlab\entries'
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$statePath = Join-Path $stateDir ($EntryId + '.json')

function Capture-StartupValues([string[]]$tokens){
  $out = @()
  foreach($path in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run')){
    try {
      $it = Get-ItemProperty -Path $path -ErrorAction Stop
      foreach($p in $it.PSObject.Properties){
        if($p.Name -in @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider')){ continue }
        $joined = ($p.Name + ' ' + [string]$p.Value).ToLower()
        if($tokens | Where-Object { $joined -like ('*' + $_.ToLower() + '*') }){
          $out += [pscustomobject]@{ path=$path; name=$p.Name; value=[string]$p.Value }
        }
      }
    } catch {}
  }
  return $out
}

function Disable-StartupValues($values){ foreach($v in $values){ try{ Remove-ItemProperty -Path $v.path -Name $v.name -ErrorAction SilentlyContinue }catch{} } }
function Restore-StartupValues($values){ foreach($v in $values){ try{ Set-ItemProperty -Path $v.path -Name $v.name -Type String -Value $v.value -ErrorAction SilentlyContinue }catch{} } }

if($Mode -eq 'apply'){
  $snapshot = [ordered]@{ entryId=$EntryId; capturedAt=(Get-Date).ToString('o'); services=@(); tasks=@(); startupValues=@() }
  foreach($svc in $svcList){
    try {
      $cim = Get-CimInstance Win32_Service -Filter "Name='$svc'" -ErrorAction Stop
      $snapshot.services += [pscustomobject]@{ name=$svc; startMode=$cim.StartMode; state=$cim.State }
      sc.exe config $svc start= disabled | Out-Null
      Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    } catch {}
  }
  foreach($tk in $taskList){
    try {
      $t = Get-ScheduledTask -TaskName $tk -ErrorAction Stop
      $snapshot.tasks += [pscustomobject]@{ name=$tk; enabled=($t.State -ne 'Disabled') }
      Disable-ScheduledTask -TaskName $tk -ErrorAction SilentlyContinue | Out-Null
    } catch {}
  }
  $snapshot.startupValues = @(Capture-StartupValues -tokens $startupList)
  Disable-StartupValues -values $snapshot.startupValues

  foreach($pn in $procList){ Get-Process -Name $pn -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
  $snapshot | ConvertTo-Json -Depth 8 | Set-Content -Path $statePath -Encoding UTF8
}
elseif($Mode -eq 'revert'){
  if(Test-Path -LiteralPath $statePath){
    $snap = Get-Content -Path $statePath -Raw | ConvertFrom-Json
    foreach($svc in @($snap.services)){
      try {
        $mode = [string]$svc.startMode
        $target = if($mode -match 'Auto'){ 'auto' } elseif($mode -match 'Disabled'){ 'disabled' } else { 'demand' }
        sc.exe config $svc.name start= $target | Out-Null
        if([string]$svc.state -eq 'Running'){ Start-Service -Name $svc.name -ErrorAction SilentlyContinue }
      } catch {}
    }
    foreach($tk in @($snap.tasks)){ try { if($tk.enabled){ Enable-ScheduledTask -TaskName $tk.name -ErrorAction SilentlyContinue | Out-Null } } catch {} }
    Restore-StartupValues -values @($snap.startupValues)
  }
}

$running = @($procList | Where-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue })
$servicesDisabled = @($svcList | Where-Object {
  try { $c = Get-CimInstance Win32_Service -Filter "Name='$_'" -ErrorAction Stop; $c.StartMode -eq 'Disabled' } catch { $false }
})
$tasksDisabled = @($taskList | Where-Object {
  try { (Get-ScheduledTask -TaskName $_ -ErrorAction Stop).State -eq 'Disabled' } catch { $true }
})
$startupRemaining = @(Capture-StartupValues -tokens $startupList)

$status = [ordered]@{
  entryId = $EntryId
  mode = $Mode
  runningProcesses = $running
  servicesDisabled = $servicesDisabled
  tasksDisabled = $tasksDisabled
  startupStillPresent = @($startupRemaining | ForEach-Object { $_.name })
  statusText = if($running.Count -eq 0 -and $startupRemaining.Count -eq 0){ 'Enabled' } else { 'Not Enabled' }
}
$status | ConvertTo-Json -Depth 6
if($Mode -eq 'check' -and ($running.Count -gt 0 -or $startupRemaining.Count -gt 0)){ exit 2 }
exit 0
