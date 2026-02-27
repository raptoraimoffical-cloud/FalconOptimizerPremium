param(
  [Parameter(Mandatory=$false)][string]$BackupPath = "$env:ProgramData\FalconOptimizer\service_disabler_backup.json"
)
$ErrorActionPreference = "SilentlyContinue"
if(-not (Test-Path $BackupPath)){
  Write-Output ("No backup file found at: " + $BackupPath)
  exit 0
}
$raw = Get-Content -LiteralPath $BackupPath -Raw
if([string]::IsNullOrWhiteSpace($raw)){
  Write-Output "Backup file empty."
  exit 0
}
$backup = $raw | ConvertFrom-Json
foreach($name in $backup.PSObject.Properties.Name){
  $mode = [string]$backup.$name
  if([string]::IsNullOrWhiteSpace($mode)){ continue }
  $st = "Manual"
  if($mode -match "Auto"){ $st = "Automatic" }
  elseif($mode -match "Disabled"){ $st = "Disabled" }
  elseif($mode -match "Manual"){ $st = "Manual" }
  try{ Set-Service -Name $name -StartupType $st -ErrorAction SilentlyContinue | Out-Null }catch{}
}
Write-Output ("OK. Restored from: " + $BackupPath)
