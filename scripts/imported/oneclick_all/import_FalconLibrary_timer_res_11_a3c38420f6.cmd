@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5000 --no-console" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5040 --no-console" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5070 --no-console" /f >nul 2>&1
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Timer%%20Resolution%%20Options.md"
    rd /s /q "C:\Oneclick Tools\Timer Resolution" >nul 2>&1
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-6.' -ForegroundColor White -BackgroundColor Red"
endlocal
