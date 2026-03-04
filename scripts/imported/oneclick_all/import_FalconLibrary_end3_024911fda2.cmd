@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
reg add "%regKeyGP%" /f >nul 2>&1
reg export "%regKeyGP%" "%Oneclick_Backup_Folder%\Priority\GraphicsPreferences.reg" /y >nul 2>&1
reg export "%regKeyPR%" "%Oneclick_Backup_Folder%\Priority\Priority.reg" /y >nul 2>&1
reg export "%regKeyFO%" "%Oneclick_Backup_Folder%\Priority\FSO.reg" /y >nul 2>&1
        reg add "%regKeyGP%" /v "!currentPath!" /t REG_SZ /d "GpuPreference=2" /f >nul 2>&1
        reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f >nul 2>&1
        reg add "%regKeyFO%" /v "!currentPath!" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" /f >nul 2>&1
        reg add "%regKeyGP%" /v "!currentPath!" /t REG_SZ /d "GpuPreference=1" /f >nul 2>&1
        reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "1" /f >nul 2>&1
    reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f >nul 2>&1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
for /f "skip=2 tokens=1*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul') do (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "%%A" /t REG_BINARY /d 0300000000000000 /f >nul
for /f "skip=2 tokens=1*" %%A in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul') do (
        reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "%%A" /t REG_BINARY /d 0300000000000000 /f >nul
for %%F in ("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*") do (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" /v "%%~nxF" /t REG_BINARY /d 0300000000000000 /f >nul
for %%F in ("%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\*") do (
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" /v "%%~nxF" /t REG_BINARY /d 0300000000000000 /f >nul
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
taskkill /f /im msedge.exe /fi "IMAGENAME eq msedge.exe" >nul 2>&1
rd /s /q "C:\Program Files (x86)\Microsoft\Edge" >nul 2>&1
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeCore" >nul 2>&1
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeUpdate" >nul 2>&1
rd /s /q "C:\Program Files (x86)\Microsoft\Temp" >nul 2>&1
del %Appdata%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk >nul 2>&1
del %ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk >nul 2>&1
del %AppData%\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk >nul 2>&1
del "C:\Users\Public\Desktop\Microsoft Edge.lnk" >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f >nul 2>&1
takeown /f "C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient_8wekyb3d8bbwe" /r /d y >nul 2>&1
icacls "C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient_8wekyb3d8bbwe" /grant Administrators:F /t >nul 2>&1
rd /s /q "C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient_8wekyb3d8bbwe" >nul 2>&1
for /f "tokens=1" %%V in ('reg query "%RunKey%" ^| findstr /I "MicrosoftEdge" ^| findstr /V "HKEY_"') do (
    reg delete "%RunKey%" /v "%%V" /f >nul 2>&1
for /f "tokens=2 delims=:" %%S in ('sc query state^= all ^| findstr /i "SERVICE_NAME" ^| findstr /i "Edge"') do (
    sc config "!Svc!" start=disabled >nul 2>&1
    sc delete "!Svc!" >nul 2>&1
taskkill.exe /F /IM "explorer.exe" >nul 2>&1
taskkill.exe /F /IM "OneDrive.exe" >nul 2>&1
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
reg load "hku\Default" "C:\Users\Default\NTUSER.DAT" >nul 2>&1
reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f >nul 2>&1
reg unload "hku\Default" >nul 2>&1
del /f /q "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" >nul 2>&1
start explorer.exe >nul 2>&1
    takeown /F "%LockAppItem%" >nul 2>&1
    icacls "%LockAppItem%" /grant administrators:F >nul 2>&1
    del "%LockAppItem%" /s /f /q >nul 2>&1
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       del "%%~S" /s /f /q >nul 2>&1
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       del "%%~S" /s /f /q >nul 2>&1
        takeown /F "!XboxfileToDelete!" >nul 2>&1
        icacls "!XboxfileToDelete!" /grant administrators:F >nul 2>&1
        del "!XboxfileToDelete!" /s /f /q >nul 2>&1
endlocal
