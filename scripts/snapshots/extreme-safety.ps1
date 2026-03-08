param([ValidateSet('create','restore')][string]$Action='create')
$ErrorActionPreference='Stop'
$root = Join-Path $env:ProgramData 'FalconOptimizer\snapshots'
New-Item -ItemType Directory -Force -Path $root | Out-Null
$svcFile = Join-Path $root 'extreme_services.json'
$taskFile = Join-Path $root 'extreme_tasks.json'
$regFile = Join-Path $root 'extreme_registry.reg'
$bcdFile = Join-Path $root 'extreme_bcd.txt'
$powerFile = Join-Path $root 'extreme_power.pow'

if($Action -eq 'create'){
  Get-CimInstance Win32_Service | Select-Object Name,StartMode,State | ConvertTo-Json -Depth 4 | Set-Content -Path $svcFile -Encoding UTF8
  Get-ScheduledTask | Select-Object TaskName,TaskPath,State | ConvertTo-Json -Depth 4 | Set-Content -Path $taskFile -Encoding UTF8
  reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache" $regFile /y | Out-Null
  bcdedit /enum all > $bcdFile
  powercfg -export $powerFile SCHEME_CURRENT | Out-Null
  Write-Output '{"status":"snapshot-created"}'
  exit 0
}

if(-not (Test-Path $svcFile)){ throw 'No snapshot found.' }
$services = Get-Content -Path $svcFile -Raw | ConvertFrom-Json
foreach($s in @($services)){
  try {
    $target = if($s.StartMode -match 'Auto'){ 'auto' } elseif($s.StartMode -match 'Disabled'){ 'disabled' } else { 'demand' }
    sc.exe config $s.Name start= $target | Out-Null
  } catch {}
}
if(Test-Path $powerFile){ try{ powercfg -import $powerFile | Out-Null } catch {} }
Write-Output '{"status":"snapshot-restore-best-effort"}'
