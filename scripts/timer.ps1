<#
  Falcon timer resolution service.

  install  -Resolution <100ns units>   compile helper, register boot task (SYSTEM), start it
  remove                               stop helper, delete task
  start / stop                         run or stop the helper without touching the task
  status                               JSON: installed, running, resolution, currentMs, minMs, maxMs

  The helper is compiled locally from the C# below (no downloaded binaries). It calls
  NtSetTimerResolution, opts out of Windows 11 timer-resolution throttling for itself, and
  then sleeps forever (~2 MB RAM, 0% CPU). On Windows 11 the request only applies system-wide
  when HKLM\...\Session Manager\kernel\GlobalTimerResolutionRequests = 1.
#>
param(
  [ValidateSet('install', 'remove', 'start', 'stop', 'status')][string]$Action = 'status',
  [ValidateRange(5000, 156250)][int]$Resolution = 5000
)
$ErrorActionPreference = 'Continue'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$Dir = Join-Path $env:ProgramData 'FalconOptimizer'
$Exe = Join-Path $Dir 'FalconTimer.exe'
$TaskName = 'Falcon Timer Resolution'
if (-not (Test-Path -LiteralPath $Dir)) { New-Item -ItemType Directory -Path $Dir -Force | Out-Null }

$Source = @'
using System;
using System.Runtime.InteropServices;
using System.Threading;

public static class FalconTimer
{
    [DllImport("ntdll.dll")] static extern int NtSetTimerResolution(uint desired, bool set, out uint current);

    [StructLayout(LayoutKind.Sequential)]
    struct PowerThrottlingState { public uint Version; public uint ControlMask; public uint StateMask; }

    [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll")] static extern bool SetProcessInformation(IntPtr process, int infoClass, ref PowerThrottlingState info, int size);

    public static void Main(string[] args)
    {
        uint desired = 5000;
        if (args.Length > 0) uint.TryParse(args[0], out desired);

        bool created;
        Mutex single = new Mutex(true, "Global\\FalconTimerResolution", out created);
        if (!created) return;

        // ProcessPowerThrottling (4), PROCESS_POWER_THROTTLING_IGNORE_TIMER_RESOLUTION (0x4), state 0 = never ignore our request.
        PowerThrottlingState s = new PowerThrottlingState { Version = 1, ControlMask = 0x4, StateMask = 0 };
        SetProcessInformation(GetCurrentProcess(), 4, ref s, Marshal.SizeOf(typeof(PowerThrottlingState)));

        uint current;
        NtSetTimerResolution(desired, true, out current);
        Thread.Sleep(Timeout.Infinite);
        GC.KeepAlive(single);
    }
}
'@

$QuerySource = @'
using System;
using System.Runtime.InteropServices;
public static class FalconTimerQuery
{
    [DllImport("ntdll.dll")] public static extern int NtQueryTimerResolution(out uint min, out uint max, out uint current);
}
'@

function Get-HelperProcess { @(Get-Process -Name 'FalconTimer' -ErrorAction SilentlyContinue) }
function Get-Task { Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue }

function Stop-Helper { Get-HelperProcess | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue } }

function Build-Helper {
  Stop-Helper
  if (Test-Path -LiteralPath $Exe) { Remove-Item -LiteralPath $Exe -Force }
  Add-Type -TypeDefinition $Source -OutputAssembly $Exe -OutputType WindowsApplication
}

switch ($Action) {
  'install' {
    Build-Helper
    $act = New-ScheduledTaskAction -Execute $Exe -Argument "$Resolution"
    $trg = New-ScheduledTaskTrigger -AtStartup
    $prn = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable
    Register-ScheduledTask -TaskName $TaskName -Action $act -Trigger $trg -Principal $prn -Settings $set -Description 'Holds a high system timer resolution for lower input/frame latency. Installed by Falcon Optimizer.' -Force | Out-Null
    Start-ScheduledTask -TaskName $TaskName
    "Timer service installed at $([math]::Round($Resolution / 10000, 4)) ms and started."
  }
  'remove' {
    if (Get-Task) { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false }
    Stop-Helper
    if (Test-Path -LiteralPath $Exe) { Remove-Item -LiteralPath $Exe -Force -ErrorAction SilentlyContinue }
    'Timer service removed. Windows default timer behavior restored.'
  }
  'start' { if (Get-Task) { Start-ScheduledTask -TaskName $TaskName; 'Started.' } else { 'Not installed.' } }
  'stop' { Stop-Helper; 'Stopped.' }
  'status' {
    if (-not ('FalconTimerQuery' -as [type])) { Add-Type -TypeDefinition $QuerySource }
    [uint32]$min = 0; [uint32]$max = 0; [uint32]$cur = 0
    [void][FalconTimerQuery]::NtQueryTimerResolution([ref]$min, [ref]$max, [ref]$cur)
    $t = Get-Task
    $res = $null
    if ($t) { try { $res = [int]($t.Actions[0].Arguments) } catch {} }
    [pscustomobject]@{
      installed = [bool]$t
      running = ((Get-HelperProcess).Count -gt 0)
      resolution = $res
      currentMs = [math]::Round($cur / 10000, 4)
      minMs = [math]::Round($min / 10000, 4)   # coarsest (e.g. 15.625)
      maxMs = [math]::Round($max / 10000, 4)   # finest supported (e.g. 0.5)
    } | ConvertTo-Json -Compress
  }
}
