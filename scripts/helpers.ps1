function Write-LogLine {
  param([string]$Path, [string]$Line)
  $dir = Split-Path -Parent $Path
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
  Add-Content -Path $Path -Value "[$ts] $Line"
}
function Ensure-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Administrator privileges are required."
  }
}
function Set-RegValue {
  param([string]$Path,[string]$Name,$Value,[string]$Type="DWord")
  if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}
function Remove-RegValue { param([string]$Path,[string]$Name)
  if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue | Out-Null }
}
function Set-ServiceStart { param([string]$Name,[string]$StartType)
  $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
  if ($null -eq $svc) { return }
  Set-Service -Name $Name -StartupType $StartType -ErrorAction SilentlyContinue | Out-Null
}
function Stop-ServiceSafe { param([string]$Name)
  $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
  if ($null -eq $svc) { return }
  if ($svc.Status -ne "Stopped") { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue | Out-Null }
}
function Disable-ScheduledTaskSafe { param([string]$TaskPath,[string]$TaskName)
  try { Disable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop | Out-Null } catch {}
}
function Enable-ScheduledTaskSafe { param([string]$TaskPath,[string]$TaskName)
  try { Enable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop | Out-Null } catch {}
}
function Run-Netsh { param([string[]]$Args) & netsh @Args | Out-String }
function Run-PowerCfg { param([string[]]$Args) & powercfg @Args | Out-String }


function Restart-ExplorerSafe {
  try {
    Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe | Out-Null
  } catch {}
}
