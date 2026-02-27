param(
  [string]$DestDir = "$env:ProgramData\FalconOptimizer\tools",
  [string]$Repo = "Orbmu2k/nvidiaProfileInspector"
)
$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

$exePath = Join-Path $DestDir 'nvidiaProfileInspector.exe'
if (Test-Path $exePath) {
  exit 0
}

$api = "https://api.github.com/repos/$Repo/releases/latest"
$headers = @{ 'User-Agent' = 'FalconOptimizer' }
$rel = Invoke-RestMethod -Uri $api -Headers $headers -Method Get

# Pick the first .zip asset
$zipAsset = $rel.assets | Where-Object { $_.name -match '\.zip$' } | Select-Object -First 1
if (-not $zipAsset) { throw "Could not find a ZIP asset in $Repo latest release." }

$tmpZip = Join-Path $env:TEMP $zipAsset.name
Invoke-WebRequest -UseBasicParsing -Uri $zipAsset.browser_download_url -Headers $headers -OutFile $tmpZip

$tmpDir = Join-Path $env:TEMP ('nvpi-' + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force

# Find nvidiaProfileInspector.exe inside the extracted folder
$found = Get-ChildItem -Path $tmpDir -Recurse -Filter 'nvidiaProfileInspector.exe' | Select-Object -First 1
if (-not $found) { throw 'nvidiaProfileInspector.exe not found in the downloaded archive.' }
Copy-Item -Force -Path $found.FullName -Destination $exePath

# Clean up
Remove-Item -Force -ErrorAction SilentlyContinue $tmpZip
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tmpDir
