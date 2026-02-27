param(
  [Parameter(Mandatory=$true)][string]$ServiceFile,
  [Parameter(Mandatory=$false)][bool]$AllowCritical = $false,
  [Parameter(Mandatory=$false)][string]$BackupPath = "$env:ProgramData\FalconOptimizer\service_disabler_backup.json"
)

$ErrorActionPreference = "SilentlyContinue"
if(-not (Test-Path $ServiceFile)){
  Write-Output ("ServiceFile not found: " + $ServiceFile)
  exit 1
}

$Services = Get-Content -LiteralPath $ServiceFile -Raw | ConvertFrom-Json
if($null -eq $Services){ $Services = @() }

$bpDir = Split-Path -Parent $BackupPath
if (-not (Test-Path $bpDir)) { New-Item -ItemType Directory -Path $bpDir -Force | Out-Null }

$backup = @{}
foreach($s in $Services){
  try{
    $svc = Get-CimInstance -ClassName Win32_Service -Filter ("Name='" + ([string]$s).Replace("'","''") + "'")
    if($null -ne $svc){
      $backup[[string]$s] = [string]$svc.StartMode
    }
  }catch{}
}

try{
  if(Test-Path $BackupPath){
    $existingRaw = Get-Content -LiteralPath $BackupPath -Raw
    if(-not [string]::IsNullOrWhiteSpace($existingRaw)){
      $existing = $existingRaw | ConvertFrom-Json
      if($existing){
        foreach($k in $existing.PSObject.Properties.Name){
          if(-not $backup.ContainsKey($k)){ $backup[$k] = [string]$existing.$k }
        }
      }
    }
  }
}catch{}

($backup | ConvertTo-Json -Depth 5) | Out-File -LiteralPath $BackupPath -Encoding UTF8 -Force

$Critical = @(
  'wuauserv','waasmedicsvc','bits','dosvc','cryptsvc','trustedinstaller','msiserver','rpcss','dcomlaunch',
  'winmgmt','eventlog','plugplay','dhcp','dnscache','nlasvc','lanmanworkstation','lanmanserver','samss',
  'securityhealthservice','mpssvc','bfe','wscsvc','wudfsvc','wudfpf','wudfsvc','winrm'
) | ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique

foreach($s in $Services){
  $name = [string]$s
  if([string]::IsNullOrWhiteSpace($name)){ continue }
  if(-not $AllowCritical){ if($Critical -contains $name.ToLowerInvariant()){ continue } }
  try{ Set-Service -Name $name -StartupType Disabled -ErrorAction SilentlyContinue | Out-Null }catch{}
  try{ Stop-Service -Name $name -Force -ErrorAction SilentlyContinue | Out-Null }catch{}
}
Write-Output ("OK. Disabled " + $Services.Count + " services. Backup: " + $BackupPath)
