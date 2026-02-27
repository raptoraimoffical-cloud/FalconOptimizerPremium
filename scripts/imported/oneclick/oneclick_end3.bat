@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: End3
echo.
set "games[0]=%ProgramFilesRobloxPath%"
set "games[1]=%AppDataRobloxPath%"
set "games[2]=C:\Program Files\Epic Games\Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe"
set "games[3]=C:\Program Files\Epic Games\RocketLeague\Binaries\Win64\RocketLeague.exe"
set "games[4]=C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64\cs2.exe"
set "games[5]=C:\Program Files (x86)\Steam\steamapps\common\Tom Clancy's Rainbow Six Siege\RainbowSix.exe"
set "games[6]=C:\Program Files (x86)\Steam\steamapps\common\Overwatch\Overwatch.exe"
set "games[7]=C:\Program Files (x86)\Steam\steamapps\common\Trove\Games\Trove\Live\Trove.exe"
set "games[8]=C:\Program Files (x86)\Steam\steamapps\common\VRChat\VRChat.exe"
set "games[9]=C:\Program Files (x86)\Steam\steamapps\common\FPSAimTrainer\FPSAimTrainer.exe"
set "games[10]=C:\Program Files (x86)\Steam\steamapps\common\Mafia The Old Country\MafiaTheOldCountry\Binaries\Win64\MafiaTheOldCountry.exe"
set "games[11]=C:\Program Files (x86)\Steam\steamapps\common\The Forest\TheForest.exe"
set "games[12]=C:\Program Files (x86)\Steam\steamapps\common\Dying Light 2\ph\work\bin\x64\DyingLightGame_x64_rwdi.exe"
set "games[13]=C:\Program Files (x86)\Steam\steamapps\common\Schedule I\Schedule I.exe"
set "games[14]=C:\Program Files (x86)\Steam\steamapps\common\Far Cry 3\bin\farcry3_d3d11.exe"
set "games[15]=C:\Program Files (x86)\Steam\steamapps\common\Sons Of The Forest\SonsOfTheForest.exe"
set "games[16]=C:\Program Files (x86)\Steam\steamapps\common\Mafia Definitive Edition\mafiadefinitiveedition.exe"
set "games[17]=C:\Program Files (x86)\Steam\steamapps\common\The Outlast Trials\OPP\Binaries\Win64\TOTClient-Win64-Shipping.exe"
set "games[18]=%USERPROFILE%\AppData\Local\osu!\osu!.exe"
set "games[19]=C:\Riot Games\VALORANT\live\VALORANT.exe"
set "games[20]=C:\Program Files\Epic Games\VALORANT\VALORANT.exe"
set "games[21]=C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto V\GTA5.exe"
set "games[22]=C:\Program Files\Epic Games\GTAV\GTAV.exe"
set "games[23]=C:\Program Files\Rockstar Games\Grand Theft Auto V\GTA5.exe"
set "games[24]=C:\Program Files\Epic Games\Apex\Apex.exe"
set "games[25]=C:\Program Files (x86)\Steam\steamapps\common\Apex Legends\Apex Legends.exe"
set "games[26]=C:\Program Files (x86)\Electronic Arts\Apex\Apex.exe"
set "games[27]=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Black Ops\BlackOps.exe"
set "games[28]=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Black Ops II\BlackOps2.exe"
set "games[29]=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Black Ops III\BlackOps3.exe"
set "games[30]=C:\Program Files (x86)\Battle.net\Call of Duty Black Ops 4\BlackOps4.exe"
set "games[31]=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Black Ops Cold War\BlackOpsColdWar.exe"
set "games[32]=C:\Program Files (x86)\Battle.net\Call of Duty Black Ops Cold War\BlackOpsColdWar.exe"
set "games[33]=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Black Ops 6\BlackOps6.exe"
set "games[34]=C:\Program Files (x86)\Battle.net\Call of Duty Black Ops 6\BlackOps6.exe"
set "games[35]=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Modern Warfare\modernwarfare.exe"
set "games[36]=C:\Program Files (x86)\Battle.net\Call of Duty Modern Warfare\modernwarfare.exe"
set "games[37]=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Modern Warfare II\cod22-cod.exe"
set "games[38]=C:\Program Files (x86)\Battle.net\Call of Duty Modern Warfare II\cod22-cod.exe"
set "games[39]=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Modern Warfare III\cod23-cod.exe"
set "games[40]=C:\Program Files (x86)\Battle.net\Call of Duty Modern Warfare III\cod23-cod.exe"
set "games[41]=C:\Program Files\Genshin Impact\Genshin Impact Game\GenshinImpact.exe"
set "games[42]=C:\Program Files\Epic Games\Genshin Impact\Genshin Impact Game\GenshinImpact.exe"
set "games[43]=C:\Program Files (x86)\Steam\steamapps\common\Dead by Daylight\DeadByDaylight\Binaries\Win64\DeadByDaylight-Win64-Shipping.exe"
set "games[44]=C:\Program Files\Epic Games\Dead by Daylight\DeadByDaylight\Binaries\Win64\DeadByDaylight-EGS-Shipping.exe"
set "games[45]=C:\Program Files (x86)\Steam\steamapps\common\Aimlabs\AimLab_tb.exe"
set "games[46]=C:\Program Files\Epic Games\Aimlabs\AimLab_tb.exe"
set "games[47]=C:\Program Files (x86)\Steam\steamapps\common\Tom Clancy's Rainbow Six Siege\RainbowSix.exe"
set "games[48]=C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Tom Clancy's Rainbow Six Siege\RainbowSix.exe"
set "apps[0]=%LatestDiscordPath%"
set "apps[1]=%USERPROFILE%\AppData\Roaming\Spotify\Spotify.exe"
set "apps[2]=C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe"
set "apps[3]=C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
set "apps[4]=C:\Program Files (x86)\Epic Games\Launcher\Engine\Binaries\Win64\EpicWebHelper.exe"
set "apps[5]=C:\Program Files (x86)\Epic Games\Launcher\Engine\Binaries\Win64\CrashReportClient.exe"
set "apps[6]=C:\Program Files (x86)\Steam\Steam.exe"
set "apps[7]=C:\Program Files (x86)\Steam\bin\cef\cef.win7x64\steamwebhelper.exe"
set "apps[8]=C:\Program Files (x86)\Battle.net\Battle.net.exe"
set "apps[9]=C:\Program Files\Core Temp\Core Temp.exe"
set "apps[10]=C:\Program Files (x86)\CapFrameX\CapFrameX.exe"
set "apps[11]=C:\Program Files\CPUID\HWMonitor\HWMonitor.exe"
set "apps[12]=C:\Program Files\VideoLAN\VLC\vlc.exe"
set "apps[13]=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "apps[14]=C:\Program Files\Open-Shell\StartMenu.exe"
set "apps[15]=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
set "apps[16]=%USERPROFILE%\AppData\Local\Programs\Opera GX\launcher.exe"
set "other[0]=Adobe Premiere Pro.exe"
set "other[1]=VegasPro.exe"
set "other[2]=Resolve.exe"
set "other[3]=blender.exe"
set "other[4]=shotcut.exe"
set "other[5]=HandBrake.exe"
set "other[6]=capcut.exe"
set "other[7]=Cinebench.exe"
set "other[8]=3DMark.exe"
set "other[9]=LatMon.exe"
set "other[10]=y-cruncher.exe"
set "other[11]=TM5.exe"
set "other[12]=linpack_xeon64.exe"
set "other[13]=node.exe"
set "other[14]=WinRAR.exe"
set "other[15]=UnRAR.exe"
set "other[16]=Rar.exe"
set "other[17]=7zFM.exe"
set "other[18]=7zG.exe"
set "other[19]=7z.exe"
set regKeyGP=HKCU\SOFTWARE\Microsoft\DirectX\UserGpuPreferences
set regKeyPR=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options
set regKeyFO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers
mkdir "%Oneclick_Backup_Folder%\Priority" >nul 2>&1
reg add "%regKeyGP%" /f >nul 2>&1
reg export "%regKeyGP%" "%Oneclick_Backup_Folder%\Priority\GraphicsPreferences.reg" /y >nul 2>&1
if errorlevel 1 (
) else ( 
)
reg export "%regKeyPR%" "%Oneclick_Backup_Folder%\Priority\Priority.reg" /y >nul 2>&1
if errorlevel 1 (
) else ( 
)
reg export "%regKeyFO%" "%Oneclick_Backup_Folder%\Priority\FSO.reg" /y >nul 2>&1
if errorlevel 1 (
) else ( 
)
for /L %%i in (0, 1, 48) do (
    set "currentPath=!games[%%i]!"
    if defined currentPath if exist "!currentPath!" (
        for %%a in ("!currentPath!") do set "exeName=%%~nxa"
        reg add "%regKeyGP%" /v "!currentPath!" /t REG_SZ /d "GpuPreference=2" /f >nul 2>&1
        reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f >nul 2>&1
        reg add "%regKeyFO%" /v "!currentPath!" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" /f >nul 2>&1
    )
)
for /L %%i in (0, 1, 16) do (
    set "currentPath=!apps[%%i]!"
    if defined currentPath if exist "!currentPath!" (
        for %%a in ("!currentPath!") do set "exeName=%%~nxa"
        reg add "%regKeyGP%" /v "!currentPath!" /t REG_SZ /d "GpuPreference=1" /f >nul 2>&1
        reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "1" /f >nul 2>&1 
    )
)
for /L %%i in (0, 1, 19) do (
    set "exeName=!other[%%i]!"
    reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f >nul 2>&1
)
endlocal
color 9
chcp 65001 >nul 2>&1
chcp 437 >nul
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
Get-AppxPackage *Clipchamp.Clipchamp* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.ApplicationCompatibilityEnhancements* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.AV1VideoExtension* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.AVCEncoderVideoExtension* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.BingNews* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.BingSearch* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.BingWeather* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Copilot* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Edge.GameAssist* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Family* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.GamingApp* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.GamingServices* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.GetHelp* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Getstarted* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.HEIFImageExtension* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.HEVCVideoExtension* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.MicrosoftEdge.Stable* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.MicrosoftOfficeHub* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.MicrosoftSolitaireCollection* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.MicrosoftStickyNotes* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.MPEG2VideoExtension* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.OneDriveSync* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.OutlookForWindows* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Paint* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.People* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.PowerAutomateDesktop* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.RawImageExtension* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.ScreenSketch* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Services.Store.Engagement* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.StartExperiencesApp* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.StorePurchaseApp* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Todos* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.VP9VideoExtensions* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WebMediaExtensions* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WebpImageExtension* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsAlarms* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsCalculator* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsCamera* ^| Remove-AppxPackage; ^
Get-AppxPackage *microsoft.windowscommunicationsapps* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Windows.DevHome* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsFeedbackHub* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsMaps* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsNotepad* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Windows.Photos* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsSoundRecorder* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsStore* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WindowsTerminal* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.Xbox.TCUI* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.XboxGameOverlay* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.XboxGamingOverlay* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.XboxIdentityProvider* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.XboxSpeechToTextOverlay* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.YourPhone* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.ZuneMusic* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.ZuneVideo* ^| Remove-AppxPackage; ^
Get-AppxPackage *MicrosoftCorporationII.MicrosoftFamily* ^| Remove-AppxPackage; ^
Get-AppxPackage *MicrosoftCorporationII.QuickAssist* ^| Remove-AppxPackage; ^
Get-AppxPackage *MicrosoftWindows.CrossDevice* ^| Remove-AppxPackage; ^
Get-AppxPackage *MicrosoftWindows.LKG.TwinSxS* ^| Remove-AppxPackage; ^
Get-AppxPackage *Microsoft.WidgetsPlatformRuntime* ^| Remove-AppxPackage; ^
Get-AppxPackage *MSTeams* ^| Remove-AppxPackage; ^
Get-AppxPackage *MicrosoftWindows.Client.WebExperience* ^| Remove-AppxPackage
chcp 65001 >nul 2>&1
color D
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
for /f "skip=2 tokens=1*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul') do (
    if not "%%A"=="(Default)" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "%%A" /t REG_BINARY /d 0300000000000000 /f >nul
    )
)
for /f "skip=2 tokens=1*" %%A in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul') do (
    if not "%%A"=="(Default)" (
        reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "%%A" /t REG_BINARY /d 0300000000000000 /f >nul
    )
)
for %%F in ("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*") do (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" /v "%%~nxF" /t REG_BINARY /d 0300000000000000 /f >nul
)
for %%F in ("%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\*") do (
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" /v "%%~nxF" /t REG_BINARY /d 0300000000000000 /f >nul
)
endlocal
color 9
chcp 65001 >nul 2>&1
"C:\Oneclick Tools\Edge Remover\setup.exe" --uninstall --system-level --force-uninstall >nul 2>&1
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
setlocal enabledelayedexpansion
set "RunKey=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
for /f "tokens=1" %%V in ('reg query "%RunKey%" ^| findstr /I "MicrosoftEdge" ^| findstr /V "HKEY_"') do (
    reg delete "%RunKey%" /v "%%V" /f >nul 2>&1
)
endlocal
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%S in ('sc query state^= all ^| findstr /i "SERVICE_NAME" ^| findstr /i "Edge"') do (
    set "Svc=%%S"
    set "Svc=!Svc:~1!"
    net stop "!Svc!" >nul 2>&1
    sc config "!Svc!" start=disabled >nul 2>&1
    sc delete "!Svc!" >nul 2>&1
)
endlocal
color D
chcp 65001 >nul 2>&1
taskkill.exe /F /IM "explorer.exe" >nul 2>&1
taskkill.exe /F /IM "OneDrive.exe" >nul 2>&1
winget uninstall --silent --accept-source-agreements Microsoft.OneDrive >nul 2>&1
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
reg load "hku\Default" "C:\Users\Default\NTUSER.DAT" >nul 2>&1
reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f >nul 2>&1
reg unload "hku\Default" >nul 2>&1
del /f /q "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" >nul 2>&1
start explorer.exe >nul 2>&1
color 9
chcp 65001 >nul 2>&1
setlocal
set "LockAppItem=C:\Windows\SystemApps\Microsoft.LockApp_cw5n1h2txyewy\LockApp.exe"
set "LockAppFound=0"
mkdir "%Oneclick_Backup_Folder%\LockApp" >nul 2>&1
if exist "%LockAppItem%" (
    set "LockAppFound=1"
    takeown /F "%LockAppItem%" >nul 2>&1
    icacls "%LockAppItem%" /grant administrators:F >nul 2>&1
    copy /Y "%LockAppItem%" "%Oneclick_Backup_Folder%\LockApp" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
    ) else (
    )
    del "%LockAppItem%" /s /f /q >nul 2>&1
    if not exist "%LockAppItem%" (
    ) else (
    )  
) else (
)
if "%LockAppFound%"=="0" (
) else (
)
endlocal
color D
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
set "SmartscreenItem1=C:\Windows\System32\smartscreen.exe"
set "SmartscreenItem2=C:\Windows\SystemApps\Microsoft.Windows.AppRep.ChxApp_cw5n1h2txyewy\CHXSmartScreen.exe"
set "SmartscreenItemFound=0"
set "NotFoundCount=0"
set "BackupCount=0"
set "DeleteCount=0"
mkdir "%Oneclick_Backup_Folder%\Smartscreen" >nul 2>&1
for %%S in ("%SmartscreenItem1%" "%SmartscreenItem2%") do (
    if exist "%%~S" (
       set /A "SmartscreenItemFound+=1"
       set /A "BackupCount+=1"
       set /A "DeleteCount+=1"
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       copy /Y "%%~S" "%Oneclick_Backup_Folder%\Smartscreen" >nul 2>&1
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
if "%SmartscreenItemFound%"=="0" (
) else if "%SmartscreenItemFound%"=="1" ( 
) else (
)
endlocal
color 9
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
set "SyncItem1=C:\Windows\System32\mobsync.exe"
set "SyncItem2=C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\CrossDeviceResume.exe"
set "SyncItemFound=0"
set "NotFoundCount=0"
set "BackupCount=0"
set "DeleteCount=0"
mkdir "%Oneclick_Backup_Folder%\Sync Programs" >nul 2>&1
for %%S in ("%SyncItem1%" "%SyncItem2%") do (
    if exist "%%~S" (
       set /A "SyncItemFound+=1"
       set /A "BackupCount+=1"
       set /A "DeleteCount+=1"
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       copy /Y "%%~S" "%Oneclick_Backup_Folder%\Sync Programs" >nul 2>&1
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
if "%SyncItemFound%"=="0" (
) else if "%SyncItemFound%"=="1" ( 
) else (
)
endlocal
color D
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
set "XboxPath=C:\Windows\System32"
set "XboxItem1=GameBarPresenceWriter.exe"
set "XboxItem2=GameBarPresenceWriter.proxy.dll"
set "XboxItem3=GameChatOverlayExt.dll"
set "XboxItem4=GameChatTranscription.dll"
set "XboxItem5=GamePanel.exe"
set "XboxItem6=GamePanelExternalHook.dll"
set "XboxItem7=gamestreamingext.dll"
set "XboxItem8=GameSystemToastIcon.contrast-white.png"
set "XboxItem9=GameSystemToastIcon.png"
set "XboxItem10=gameux.dll"
set "XboxItem11=gamingtcui.dll"
set "XboxItem12=XblAuthManager.dll"
set "XboxItem13=XblAuthManagerProxy.dll"
set "XboxItem14=XblAuthTokenBrokerExt.dll"
set "XboxItem15=XblGameSave.dll"
set "XboxItem16=XblGameSaveExt.dll"
set "XboxItem17=XblGameSaveProxy.dll"
set "XboxItem18=XblGameSaveTask.exe"
set "XboxItem19=XboxNetApiSvc.dll"
set "XboxItem20=Windows.Gaming.Preview.dll"
set "XboxItem21=Windows.Gaming.UI.GameBar.dll"
set "XboxItem22=Windows.Gaming.XboxLive.Storage.dll"
set "CopyAttemptCount=0"
set "CopySuccessCount=0"
set "XboxItemFound=0"
set "BackupCount=0"
set "DeleteCount=0"
mkdir "%Oneclick_Backup_Folder%\Xbox Bloat" >nul 2>&1
for /L %%i in (1,1,22) do (
    set "XboxfileToDelete=%XboxPath%\!XboxItem%%i!"
    if exist "!XboxfileToDelete!" (
        set /A "CopyAttemptCount+=1"
        set /A "XboxItemFound+=1"
        set /A "BackupCount+=1"
        set /A "DeleteCount+=1"
        takeown /F "!XboxfileToDelete!" >nul 2>&1
        icacls "!XboxfileToDelete!" /grant administrators:F >nul 2>&1
        copy /Y "!XboxfileToDelete!" "%Oneclick_Backup_Folder%\Xbox Bloat" >nul 2>&1
        if %ERRORLEVEL% equ 0 (
            set /A "CopySuccessCount+=1"
        ) else (
        ) 
        del "!XboxfileToDelete!" /s /f /q >nul 2>&1
        if not exist "!XboxfileToDelete!" (
        ) else (
        )  
    ) else (
    )
)
if "!XboxItemFound!" NEQ "0" (
    if "!CopyAttemptCount!"=="!CopySuccessCount!" (
    ) else (
    )
)
if "%XboxItemFound%"=="0" (
) else (
)
endlocal
echo.
echo [Falcon] Done.
endlocal
exit /b 0