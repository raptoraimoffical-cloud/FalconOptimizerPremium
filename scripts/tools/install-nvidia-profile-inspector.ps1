param(
  [string]$DestDir = "$env:ProgramData\FalconOptimizer\tools"
)
$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
$exePath = Join-Path $DestDir 'nvidiaProfileInspector.exe'
$zipPath = Join-Path $env:TEMP 'nvidiaProfileInspector.zip'

# Source: Orbmu2k/nvidiaProfileInspector (GitHub releases)
$api = 'https://api.github.com/repos/Orbmu2k/nvidiaProfileInspector/releases/latest'
$rel = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'FalconOptimizer' }
$asset = $rel.assets | Where-Object { $_.name -match '\.zip$' } | Select-Object -First 1
if (-not $asset) { throw 'Could not find a .zip asset in the latest nvidiaProfileInspector release.' }

Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile $zipPath

# Extract and copy exe
$extractDir = Join-Path $env:TEMP ('nvidiaProfileInspector_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

$found = Get-ChildItem -Path $extractDir -Recurse -Filter 'nvidiaProfileInspector.exe' | Select-Object -First 1
if (-not $found) { throw 'nvidiaProfileInspector.exe not found after extracting the release zip.' }

Copy-Item -Force -Path $found.FullName -Destination $exePath

Write-Output "OK: $exePath"
