@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Fixers
echo.
color B
chcp 65001 >nul 2>&1
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.                                       ███████╗██╗██╗  ██╗███████╗██████╗ ███████╗
echo.                                       ██╔════╝██║╚██╗██╔╝██╔════╝██╔══██╗██╔════╝
echo.                                       █████╗  ██║ ╚███╔╝ █████╗  ██████╔╝███████╗
echo.                                       ██╔══╝  ██║ ██╔██╗ ██╔══╝  ██╔══██╗╚════██║
echo.                                       ██║     ██║██╔╝ ██╗███████╗██║  ██║███████║
echo.                                       ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝
echo.
echo.                         ╔═════════════════════════════════════════════════════════════════════╗ 
echo.                         ║                                                                     ║ 
echo.                         ║           [1] Wifi Fixer              [2] Epic Games Fixer          ║
echo.                         ║           [3] Rockstar Games Fixer    [4] Fixer Github              ║
echo.                         ║           [5] Return to Extras        [6] Restart                   ║
echo.                         ║                                                                     ║
echo.                         ╚═════════════════════════════════════════════════════════════════════╝
echo.  
echo.  
echo.
if "%option%"=="1" (
    color A
    chcp 65001 >nul 2>&1
    echo.
    sc config LanmanWorkstation start=demand
    sc config WdiServiceHost start=demand
    sc config NcbService start=demand
    sc config ndu start=demand
    sc config Netman start=demand
    sc config netprofm start=demand
    sc config WwanSvc start=demand
    sc config Dhcp start=auto
    sc config DPS start=auto
    sc config lmhosts start=auto
    sc config NlaSvc start=auto
    sc config nsi start=auto
    sc config RmSvc start=auto
    sc config Wcmsvc start=auto
    sc config Winmgmt start=auto
    sc config WlanSvc start=auto
    reg add "HKLM\Software\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" /v "NoActiveProbe" /t REG_DWORD /d "0" /f
    reg add "HKLM\System\CurrentControlSet\Services\NlaSvc\Parameters\Internet" /v "EnableActiveProbing" /t REG_DWORD /d "1" /f
    reg add "HKLM\System\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "2" /f
    reg add "HKLM\System\CurrentControlSet\Services\Dnscache" /v "Start" /t REG_DWORD /d "2" /f
    reg add "HKLM\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "3" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\vwifibus" /v "Start" /t REG_DWORD /d "3" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "3" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\vwifimp" /v "Start" /t REG_DWORD /d "3" /f
    ipconfig /release
    ipconfig /renew
    arp -d *
    nbtstat -R
    nbtstat -RR
    ipconfig /flushdns
    ipconfig /registerdns >nul 2>&1
    goto :Fixers 
) else if "%option%"=="2" (
    color A
    chcp 65001 >nul 2>&1
    sc config "EpicGamesUpdater" start=auto >nul 2>&1
    sc config "EpicOnlineServices" start=auto >nul 2>&1
    goto :Fixers 
) else if "%option%"=="3" (
    color A
    chcp 65001 >nul 2>&1
    sc config "Rockstar Service" start=auto >nul 2>&1
    goto :Fixers
) else if "%option%"=="4" (
    color A
    chcp 65001 >nul 2>&1
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Oneclick%%20Fixes.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Fixers
) else if "%option%"=="5" (
    goto :Extras
) else if "%option%"=="6" (
    goto :Restart 
) else (
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-6.' -ForegroundColor White -BackgroundColor Red"
    goto :Fixers
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0