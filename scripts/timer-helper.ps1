param(
  [int]$Resolution = 5000
)

# Prevent duplicates: if another timer-helper is running, exit
try {
  $procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*timer-helper.ps1*" }
  if ($procs -and $procs.Count -ge 1) { exit 0 }
} catch {}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class TimerRes {
  [DllImport("ntdll.dll", SetLastError=true)]
  public static extern uint NtSetTimerResolution(uint Desired, bool Set, out uint Current);
}
"@

$cur = 0
[TimerRes]::NtSetTimerResolution([uint32]$Resolution, $true, [ref]$cur) | Out-Null

# Keep the process alive so the resolution request remains active
while ($true) { Start-Sleep -Seconds 5 }