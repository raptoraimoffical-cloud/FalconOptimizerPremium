@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Search_Removal
echo.
setlocal
color A
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeWebView" >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView" /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Services\UdkUserSvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
set "SearchItem1=C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\SearchHost.exe"
set "SearchItem2=C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe"
set "SearchItem3=C:\Windows\SystemApps\ShellExperienceHost_cw5n1h2txyewy\ShellExperienceHost.exe"
set "SearchItem4=C:\Windows\System32\taskhostw.exe"
set "SearchItemFound=0"
set "NotFoundCount=0"
set "BackupCount=0"
set "DeleteCount=0"
mkdir "%Oneclick_Backup_Folder%\Search" >nul 2>&1
for %%S in ("%SearchItem1%" "%SearchItem2%" "%SearchItem3%" "%SearchItem4%") do (
    if exist "%%~S" (
       set /A "SearchItemFound+=1"
       set /A "BackupCount+=1"
       set /A "DeleteCount+=1"
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       copy /Y "%%~S" "%Oneclick_Backup_Folder%\Search" >nul 2>&1
       if !ERRORLEVEL! equ 0 (
       ) else (
       )
       del "%%~S" /s /f /q >nul 2>&1
       if not exist "%%~S" (
       ) else (
       )  
    ) else (
        set /A "NotFoundCount+=1"
    )
)
if "%SearchItemFound%"=="0" (
) else if "%SearchItemFound%"=="1" ( 
) else (
)
endlocal
echo.
echo [Falcon] Done.
endlocal
exit /b 0