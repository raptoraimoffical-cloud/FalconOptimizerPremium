@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x2a" /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x00000024" /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x1a" /f >nul 2>&1
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Priority%%20Separation%%20Options.md"
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-6.' -ForegroundColor White -BackgroundColor Red"
endlocal
