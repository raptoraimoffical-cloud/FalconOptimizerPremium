param()

$ErrorActionPreference = "Stop"

function Write-Log($msg){
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$ts] $msg"
}

function Remove-RegistryKeySafe([string]$path){
  try {
    if(Test-Path $path){
      Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
      Write-Log "Removed registry key: $path"
    }
  } catch {
    Write-Log "WARN: Failed removing key: $path ($($_.Exception.Message))"
  }
}

function Remove-RegistryValueSafe([string]$path, [string]$name){
  try {
    if(Test-Path $path){
      $p = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
      if($null -ne $p -and ($p.PSObject.Properties.Name -contains $name)){
        Remove-ItemProperty -Path $path -Name $name -Force -ErrorAction Stop
        Write-Log "Removed registry value: $path\$name"
      }
    }
  } catch {
    Write-Log "WARN: Failed removing value: $path\$name ($($_.Exception.Message))"
  }
}

function Set-ServiceStartSafe([string]$svc, [string]$start){
  try {
    sc.exe config $svc start= $start | Out-Null
    Write-Log "Service start configured: $svc -> $start"
  } catch {
    Write-Log "WARN: Failed service config: $svc ($($_.Exception.Message))"
  }
}

function Start-ServiceSafe([string]$svc){
  try {
    Start-Service -Name $svc -ErrorAction Stop
    Write-Log "Started service: $svc"
  } catch {
    Write-Log "WARN: Failed starting service: $svc ($($_.Exception.Message))"
  }
}

function Enable-DefenderTasksSafe(){
  try {
    $paths = @(
      "\Microsoft\Windows\Windows Defender\",
      "\Microsoft\Windows\Windows Defender Cleanup\",
      "\Microsoft\Windows\Windows Defender Cache Maintenance\",
      "\Microsoft\Windows\Windows Defender Verification\"
    )
    foreach($p in $paths){
      try {
        $tasks = Get-ScheduledTask -TaskPath $p -ErrorAction SilentlyContinue
        foreach($t in $tasks){
          try {
            Enable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction Stop | Out-Null
          } catch {}
        }
      } catch {}
    }

    # Common known tasks (older builds)
    $names = @(
      "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan",
      "\Microsoft\Windows\Windows Defender\Windows Defender Verification",
      "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance",
      "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup"
    )
    foreach($n in $names){
      schtasks.exe /Change /TN $n /ENABLE | Out-Null 2>$null
    }
    Write-Log "Defender scheduled tasks: enabled (best-effort)"
  } catch {
    Write-Log "WARN: Scheduled task enable failed ($($_.Exception.Message))"
  }
}

Write-Host "================================"
Write-Host "  Falcon Defender Full Restore"
Write-Host "================================"
Write-Host ""

# Remove policy locks commonly set by Defender-control tools (incl. DefenderControl/DControl)
Write-Log "Removing Defender policy locks..."

$policyRoots = @(
  "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
  "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center",
  "HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection"
)
foreach($k in $policyRoots){ Remove-RegistryKeySafe $k }

# Remove common "disable" values in non-policy locations (best-effort, does not touch exclusions)
$defBase = "HKLM:\SOFTWARE\Microsoft\Windows Defender"
$defRtp  = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection"
$defSpyn = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet"

$valuesToRemove = @(
  @{p=$defBase; n="DisableAntiSpyware"},
  @{p=$defBase; n="DisableAntiVirus"},
  @{p=$defBase; n="DisableRoutinelyTakingAction"},
  @{p=$defRtp;  n="DisableRealtimeMonitoring"},
  @{p=$defRtp;  n="DisableBehaviorMonitoring"},
  @{p=$defRtp;  n="DisableIOAVProtection"},
  @{p=$defRtp;  n="DisableOnAccessProtection"},
  @{p=$defRtp;  n="DisableScanOnRealtimeEnable"},
  @{p=$defSpyn; n="SubmitSamplesConsent"},
  @{p=$defSpyn; n="SpynetReporting"}
)
foreach($v in $valuesToRemove){ Remove-RegistryValueSafe $v.p $v.n }

# Restore core security-related services only (do not touch unrelated services)
Write-Log "Restoring service configurations..."
Set-ServiceStartSafe "SecurityHealthService" "auto"
Set-ServiceStartSafe "wscsvc" "auto"
Set-ServiceStartSafe "WinDefend" "auto"
Set-ServiceStartSafe "WdNisSvc" "demand"

# Start services
Write-Log "Starting services..."
Start-ServiceSafe "SecurityHealthService"
Start-ServiceSafe "wscsvc"
Start-ServiceSafe "WinDefend"

# Scheduled tasks
Write-Log "Re-enabling Defender scheduled tasks..."
Enable-DefenderTasksSafe

# Try to re-enable Defender realtime monitoring via built-in cmdlets (will fail if platform blocks it)
try {
  if(Get-Command Set-MpPreference -ErrorAction SilentlyContinue){
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
    Write-Log "Set-MpPreference: DisableRealtimeMonitoring -> false (best-effort)"
  }
} catch {
  Write-Log "WARN: Set-MpPreference failed ($($_.Exception.Message))"
}

Write-Host ""
Write-Host "================================"
Write-Host "  Restore Complete"
Write-Host "================================"
Write-Host ""
Write-Host "If Defender does not fully return:"
Write-Host "  1) Reboot once"
Write-Host "  2) Open Windows Security and confirm Tamper Protection setting"
Write-Host ""
pause
