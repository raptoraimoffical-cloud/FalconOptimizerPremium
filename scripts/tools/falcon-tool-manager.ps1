param(
  [Parameter(Mandatory=$true)][ValidateSet("ensure","launch","status")] [string]$Command,
  [Parameter(Mandatory=$true)] [string]$ToolId
)

$ErrorActionPreference = "Stop"

function Get-FalconRoot {
  $here = Split-Path -Parent $MyInvocation.MyCommand.Path
  return (Resolve-Path (Join-Path $here "..\..")).Path
}

$root = Get-FalconRoot
$manifestPath = Join-Path $root "tools\tools.manifest.json"
if(!(Test-Path $manifestPath)){ throw "Missing tools.manifest.json" }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$tool = $manifest.tools | Where-Object { $_.id -eq $ToolId } | Select-Object -First 1
if(-not $tool){ throw "Unknown tool id: $ToolId" }

function Resolve-Rel($p){
  if([string]::IsNullOrWhiteSpace($p)){ return $null }
  if($p -match "^[A-Za-z]:\\"){ return $p }
  return (Join-Path $root $p)
}

$launchPath = Resolve-Rel $tool.launch
$extractTo = Resolve-Rel $tool.extractTo

function Tool-Installed {
  if($launchPath -and (Test-Path $launchPath)){ return $true }
  return $false
}

function Download-File($url, $dest){
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
  Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
}

if($Command -eq "status"){
  $ok = Tool-Installed
  Write-Output (ConvertTo-Json @{ ok=$true; installed=$ok; launch=$launchPath })
  exit 0
}

if($Command -eq "ensure"){
  if(Tool-Installed){
    Write-Output (ConvertTo-Json @{ ok=$true; installed=$true; launch=$launchPath })
    exit 0
  }

  # Local tool: shipped with Falcon (no download step)
  if($tool.kind -eq "local"){
    $installed = Tool-Installed
    Write-Output (ConvertTo-Json @{ ok=$true; installed=$installed; launch=$launchPath })
    exit 0
  }

  $dlDir = Join-Path $root "tools\_downloads"
  New-Item -ItemType Directory -Force -Path $dlDir | Out-Null

  if($tool.kind -eq "zip"){
    $zipFile = Join-Path $dlDir ($ToolId + ".zip")
    Download-File $tool.downloadUrl $zipFile
    if(-not $extractTo){ throw "extractTo required for zip tool" }
    New-Item -ItemType Directory -Force -Path $extractTo | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $extractTo, $true)
  } elseif($tool.kind -eq "exe"){
    # Try direct download url; if it isn't a direct file URL, this may fail. User can still manual place it.
    $exeDir = Join-Path $root ("tools\" + $tool.name)
    New-Item -ItemType Directory -Force -Path $exeDir | Out-Null
    $exeFile = Join-Path $exeDir ($tool.name + ".exe")
    try {
      Download-File $tool.downloadUrl $exeFile
    } catch {
      Write-Output (ConvertTo-Json @{ ok=$false; error="Download failed (site may require manual download). Place the exe at: $exeFile"; launch=$exeFile })
      exit 0
    }
    $launchPath = $exeFile
  } else {
    throw "Unknown kind: $($tool.kind)"
  }

  $installed = Tool-Installed
  Write-Output (ConvertTo-Json @{ ok=$true; installed=$installed; launch=$launchPath })
  exit 0
}

if($Command -eq "launch"){
  if(-not (Tool-Installed)){
    Write-Output (ConvertTo-Json @{ ok=$false; error="Tool not installed"; launch=$launchPath })
    exit 0
  }
$ext = [System.IO.Path]::GetExtension($launchPath).ToLowerInvariant()
  if($ext -eq ".bat" -or $ext -eq ".cmd"){
    Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", "`"$launchPath`"") -WorkingDirectory (Split-Path -Parent $launchPath) | Out-Null
  } elseif($ext -eq ".ps1"){
    Start-Process -FilePath "powershell.exe" -ArgumentList @("-ExecutionPolicy","Bypass","-File","`"$launchPath`"") -WorkingDirectory (Split-Path -Parent $launchPath) | Out-Null
  } else {
    Start-Process -FilePath $launchPath -WorkingDirectory (Split-Path -Parent $launchPath) | Out-Null
  }
  Write-Output (ConvertTo-Json @{ ok=$true; launched=$true; launch=$launchPath })
  exit 0
}