@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Latency_Tweaks
echo.
color 9
chcp 65001 >nul 2>&1
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.                                 ██╗      █████╗ ████████╗███████╗███╗   ██╗ ██████╗██╗   ██╗       
echo.                                 ██║     ██╔══██╗╚══██╔══╝██╔════╝████╗  ██║██╔════╝╚██╗ ██╔╝       
echo.                                 ██║     ███████║   ██║   █████╗  ██╔██╗ ██║██║      ╚████╔╝        
echo.                                 ██║     ██╔══██║   ██║   ██╔══╝  ██║╚██╗██║██║       ╚██╔╝         
echo.                                 ███████╗██║  ██║   ██║   ███████╗██║ ╚████║╚██████╗   ██║          
echo.                                 ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝ ╚═════╝   ╚═╝          
echo. 
echo.                                  ╔════════════════════════════════════════════════════╗
echo.                                  ║               Running latency Tweaks.              ║       
echo.                                  ╚════════════════════════════════════════════════════╝
echo. 
echo.
echo.
echo.
echo.
echo.
echo.                                                                         
color D
chcp 65001 >nul 2>&1
bcdedit /deletevalue useplatformclock >nul 2>&1
bcdedit /set useplatformtick no >nul 2>&1
bcdedit /set disabledynamictick yes >nul 2>&1
color 9
chcp 65001 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "AllowHibernate" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergySaverState" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EventProcessorEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabledDefault" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "TimerCoalescing" /t REG_BINARY /d "0000000000000000000000000000000000000000000000000000000000000000" /f >nul 2>&1
powercfg /hibernate off >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformAoAcOverride" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformRoleOverride" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "MSDisabled" /t REG_DWORD /d "1" /f >nul 2>&1
chcp 437 >nul
Powershell -Command "Get-WmiObject MSPowerDeviceEnable -Namespace root\wmi | ForEach-Object { $_.Enable = $false; $_.psbase.Put() }" >nul 2>&1
chcp 65001 >nul 2>&1
color D
chcp 65001 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DynamicHeteroCpuPolicyMask" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DefaultDynamicHeteroCpuPolicy" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DynamicHeteroCpuPolicyImportant" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DynamicHeteroCpuPolicyImportantShort" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DynamicHeteroCpuPolicyImportantPriority" /t REG_DWORD /d "8" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "SerializeTimerExpiration" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "EnablePerCpuClockTickScheduling" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "TimerCheckFlags" /t REG_DWORD /d "0" /f > nul 2>&1
echo.
echo [Falcon] Done.
endlocal
exit /b 0