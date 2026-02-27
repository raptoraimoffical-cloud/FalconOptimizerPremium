param(
  [string]$DestDir = "$env:ProgramData\FalconOptimizer\tools"
)
$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
$exePath = Join-Path $DestDir 'MSI_Utility_V3.exe'

# Source: https://github.com/Sathango/Msi-Utility-v3
$src = 'https://raw.githubusercontent.com/Sathango/Msi-Utility-v3/main/Msi%20Utility%20v3.exe'

try {
  Invoke-WebRequest -UseBasicParsing -Uri $src -OutFile $exePath
  Write-Output "Downloaded MSI Utility V3 to: $exePath"
} catch {
  Write-Output "Failed to download MSI Utility V3: $($_.Exception.Message)"
  exit 1
}
