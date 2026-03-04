 :: Made by Quaked
:: TikTok: _Quaked_
:: Discord: https://discord.gg/8NqDSMzYun

@echo off
title Process Destroyer V2.5
color B
chcp 65001 >nul 2>&1

:: Creating Process Destroyer Services Reg Backup.
reg export "HKLM\System\CurrentControlSet\Services" "C:\Oneclick Tools\Process Destroyer\Revert\Services_Backup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Process Destroyer Services Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] Process Destroyer Services Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Rename Ctfmon, BackgroundTaskHost, and TextInputHost.
taskkill /f /im ctfmon.exe >nul 2>&1
REN "C:\Windows\System32\ctfmon.exe" "ctfmon.exee" >nul 2>&1
taskkill /f /im backgroundTaskHost.exe >nul 2>&1
REN "C:\Windows\System32\backgroundTaskHost.exe" "backgroundTaskHost.exee" >nul 2>&1
taskkill /f /im TextInputHost.exe >nul 2>&1
REN "C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\TextInputHost.exe" "TextInputHost.exee" >nul 2>&1

:: Services.
echo ✔  Disabling mpssvc.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mpssvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling WpnUserService.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WpnUserService" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling SystemEventsBroker.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SystemEventsBroker" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling EventSystem.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\EventSystem" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling wscsvc.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wscsvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling NgcCtnrSvc.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NgcCtnrSvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling Schedule.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Schedule" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling NgcSvc.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NgcSvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling sppsvc.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\sppsvc" /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1

echo ✔  Disabling WdNisSvc.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling gpsvc.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\gpsvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling PlugPlay.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\PlugPlay" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo ✔  Disabling msiserver.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\msiserver" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

echo Closing in 3 seconds...
timeout 3 > nul
exit
