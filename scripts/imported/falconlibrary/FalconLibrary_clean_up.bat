@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Clean_Up
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
echo.                                 ██████╗ ██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗ 
echo.                                 ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗
echo.                                 ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝
echo.                                 ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝ 
echo.                                 ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║     
echo.                                  ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     
echo. 
echo.                                  ╔════════════════════════════════════════════════════╗
echo.                                  ║     Running File Cleanup and Network Cleanup.      ║       
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
del /s /q "%LocalAppData%\Microsoft\Windows\WebCache" 
rd /s /q "%LocalAppData%\Microsoft\Windows\WebCache" >nul 2>&1
mkdir "%LocalAppData%\Microsoft\Windows\WebCache" >nul 2>&1
del /s /q "C:\Windows\Temp"
rd /s /q "C:\Windows\Temp" >nul 2>&1
mkdir "C:\Windows\Temp" >nul 2>&1 
del /s /q "%Temp%" 
rd /s /q "%Temp%" >nul 2>&1
mkdir "%Temp%" >nul 2>&1 
del /s /q "%AppData%\Discord\Cache" 
rd /s /q "%AppData%\Discord\Cache" >nul 2>&1
mkdir "%AppData%\Discord\Cache" >nul 2>&1
del /s /q "%AppData%\Discord\Code Cache" 
rd /s /q "%AppData%\Discord\Code Cache" >nul 2>&1
mkdir "%AppData%\Discord\Code Cache" >nul 2>&1
del /s /q "%LocalAppData%\Spotify\Data"
rd /s /q "%LocalAppData%\Spotify\Data" >nul 2>&1
mkdir "%LocalAppData%\Spotify\Data" >nul 2>&1
del /s /q "C:\Windows\Prefetch"
rd /s /q "C:\Windows\Prefetch" >nul 2>&1
mkdir "C:\Windows\Prefetch" >nul 2>&1 
del /s /q "%ProgramData%\USOPrivate\UpdateStore" 
del /s /q "%ProgramData%\USOShared\Logs" 
del /s /q "C:\Windows\System32\SleepStudy"
del /s /q "C:\Windows\Logs"
color 9
chcp 65001 >nul 2>&1
ipconfig /release
ipconfig /renew
arp -d *
nbtstat -R
nbtstat -RR
ipconfig /flushdns
ipconfig /registerdns >nul 2>&1
echo.
echo [Falcon] Done.
endlocal
exit /b 0