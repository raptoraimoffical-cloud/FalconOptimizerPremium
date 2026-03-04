@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
del /s /q "%LocalAppData%\Microsoft\Windows\WebCache"
rd /s /q "%LocalAppData%\Microsoft\Windows\WebCache" >nul 2>&1
del /s /q "C:\Windows\Temp"
rd /s /q "C:\Windows\Temp" >nul 2>&1
del /s /q "%Temp%"
rd /s /q "%Temp%" >nul 2>&1
del /s /q "%AppData%\Discord\Cache"
rd /s /q "%AppData%\Discord\Cache" >nul 2>&1
del /s /q "%AppData%\Discord\Code Cache"
rd /s /q "%AppData%\Discord\Code Cache" >nul 2>&1
del /s /q "%LocalAppData%\Spotify\Data"
rd /s /q "%LocalAppData%\Spotify\Data" >nul 2>&1
del /s /q "C:\Windows\Prefetch"
rd /s /q "C:\Windows\Prefetch" >nul 2>&1
del /s /q "%ProgramData%\USOPrivate\UpdateStore"
del /s /q "%ProgramData%\USOShared\Logs"
del /s /q "C:\Windows\System32\SleepStudy"
del /s /q "C:\Windows\Logs"
endlocal
