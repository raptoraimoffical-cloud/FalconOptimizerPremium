param(
  [Parameter(Mandatory=$true)][string]$FilePath,
  [string]$Arguments = '',
  [ValidateSet('normal','admin','admin-verify','trustedinstaller')][string]$Tier='normal'
)
$ErrorActionPreference='Stop'
if(-not (Test-Path -LiteralPath $FilePath)){ throw "File not found: $FilePath" }

function Invoke-Checked([scriptblock]$sb){ & $sb; if($LASTEXITCODE -ne 0){ throw "Command failed: $LASTEXITCODE" } }

switch($Tier){
  'normal' {
    Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -NoNewWindow
  }
  'admin' {
    Start-Process -FilePath $FilePath -ArgumentList $Arguments -Verb RunAs -Wait
  }
  'admin-verify' {
    Start-Process -FilePath $FilePath -ArgumentList $Arguments -Verb RunAs -Wait
    Write-Output '{"verify":"manual"}'
  }
  'trustedinstaller' {
    $nsudo = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path 'tools\FalconLibrary\NSudo\NSudoLG.exe'
    if(-not (Test-Path -LiteralPath $nsudo)){ throw 'NSudo missing: tools/FalconLibrary/NSudo/NSudoLG.exe' }
    $arg = "-U:T -P:E `\"$FilePath`\" $Arguments"
    Start-Process -FilePath $nsudo -ArgumentList $arg -Wait -NoNewWindow
  }
}
