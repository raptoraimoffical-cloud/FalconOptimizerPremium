:: Made by Quaked
:: TikTok: _Quaked_
:: Discord: https://discord.gg/8NqDSMzYun
:: Code Snippet Credit: ChrisTitusTech, Privacy Is Freedom, Prolix, Majorgeeks, PRDGY Ace, Mathako, p467121.
:: Utility/Program Credit: Kenji Mouri - NSudo, Sordum - Dcontrol, Thesycon - DPC Checker, Amitxv - Timer Resolution, O&O Software GmbH - OOshutup10, Orbmu2k - NVIDIA Profile Inspector, etc.

@echo off

:: Oneclick Version & Title. (Defines the current Oneclick Version, for later use)
set Current_Version=V8.3
title Oneclick %Current_Version%

:: Check for Admin Privileges. (Oneclick requires elevated permissions)
fltmc >nul 2>&1
if not %errorlevel% == 0 (
    Powershell -NoProfile -Command "Write-Host 'Oneclick is required to be run as *Administrator.*' -ForegroundColor White -BackgroundColor Red" 
    Powershell -NoProfile -Command "Write-Host 'Please click *Yes* to the following prompt!' -ForegroundColor White -BackgroundColor Red" 
    timeout 3 > nul
    Powershell -NoProfile Start -Verb RunAs '%0'
    exit /b 0
)

:: Configuring ANSI Colors. (Defines ANSI Foreground colors)
set "Reset=[0m"
set "Black=[30m"
set "DarkRed=[31m"
set "DarkGreen=[32m"
set "DarkYellow=[33m"
set "DarkBlue=[34m"
set "DarkMagenta=[35m"
set "DarkCyan=[36m"
set "Gray=[37m"
set "DarkGray=[90m"
set "Red=[91m"
set "Green=[92m"
set "Yellow=[93m"
set "Blue=[94m"
set "Magenta=[95m"
set "Cyan=[96m"
set "White=[97m"

:: Check for Oneclick Log Folder (User sided logging, that can be sent to receive assistance) 
if not exist "C:\Oneclick Logs\Extra" (
   mkdir "C:\Oneclick Logs\Extra" >nul 2>&1
   call :Oneclick_Log_Start
   echo [%DATE% %TIME%] Oneclick Log Folder Check: Folder Created. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else (
   call :Oneclick_Log_Start
   echo [%DATE% %TIME%] Oneclick Log Folder Check: Folder already exist. >> "C:\Oneclick Logs\Oneclick Log.txt" 
)

:: Check for the Latest Oneclick Version. (Checks The Oneclick Github, for the latest version and defines it)
for /f "tokens=2 delims== " %%A in ('curl -s -L https://raw.githubusercontent.com/QuakedK/Oneclick/main/Version.md ^| findstr /i "Latest_Version"') do (
    set "Latest_Version=%%A"
)

:: Compare Latest and Current Oneclick Version. (Checks if the Latest and Current Version match)
if "%Latest_Version%"=="%Current_Version%" (
   echo [%DATE% %TIME%] Oneclick Version Status: Latest Version Detected >> "C:\Oneclick Logs\Oneclick Log.txt"
   goto :Windows_Version_Check
) else (
   echo [%DATE% %TIME%] Oneclick Version Status: Outdated Version Detected. >> "C:\Oneclick Logs\Oneclick Log.txt"
   goto :Outdated_Oneclick_Version 
   
)

:: Outdated Oneclick Version. (Error Handling for non-matching or outdated Oneclick Versions)
:Outdated_Oneclick_Version
cls
color C
chcp 65001 >nul 2>&1
echo ╔════════════════════════════════════════╗
echo ║ ⚠️ Outdated Oneclick Version Detected. ║
echo ╚════════════════════════════════════════╝
echo ❌ Oneclick %Latest_Version% not detected!
echo. 
echo → Running an outdated Oneclick version can lead to bugs, issues, and unexpected behavior. 
echo However running the Latest Oneclick Version guarantees full support, stability and functionality. 
echo.
echo %White%[Choose an option]
echo %Green%1. Download the Latest Oneclick Version - *Opens the github page*
echo %Red%2. Continue Anyway - *Allows the user to run Oneclick regardless*
echo %DarkYellow%3. Exit - *Closes Oneclick*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] Outdated Oneclick Options: User Chose "Option 1" - Download the Latest Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════════════════════════════════╗
    echo ║ ✅ Opening the Latest Oneclick Version Github Page. ║
    echo ╚═════════════════════════════════════════════════════╝
    echo • The github page will now open in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/releases/latest"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Outdated_Oneclick_Version 
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Dcontrol Download Options: User Chose "Option 2" - Continue Anyway. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔══════════════════════════════╗
    echo ║ ⚠️ Continuing with Oneclick. ║
    echo ╚══════════════════════════════╝
    echo • Now continuing in 2 seconds!
    timeout 2 > nul
    cls
    chcp 437 >nul
    goto :Windows_Version_Check
) else if "%option%"=="3" ( 
    echo [%DATE% %TIME%] Dcontrol Download Options: User Chose "Option 3" - Exit Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    cls
    color A
    echo ╔══════════════════════╗
    echo ║ ✅ Exiting Oneclick. ║
    echo ╚══════════════════════╝
    echo • Now closing Oneclick in 5 seconds!
    timeout 5 > nul
    call :Oneclick_Log_End
    exit
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Outdated_Oneclick_Version
)

:: Check for Windows 11 Version. (Windows 11 21H2-26H1 Supported)
:Windows_Version_Check
setlocal enabledelayedexpansion
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild') do set CurrentBuild=%%A
echo [%DATE% %TIME%] Windows Version Detected: !CurrentBuild! >> "C:\Oneclick Logs\Oneclick Log.txt"
echo !CurrentBuild!> "C:\Oneclick Logs\Extra\WinVersion.txt"
if !CurrentBuild! GEQ 22000 if !CurrentBuild! LEQ 28000 (
    echo [%DATE% %TIME%] Windows Version Status: Supported Version. >> "C:\Oneclick Logs\Oneclick Log.txt"
    call :Global_RegKey
    endlocal & goto :VCRuntime_Check
)
endlocal & goto :Unsupported_WinVer

:: Setup GlobalTimerResolutionRequests Registry Key. (Used for Windows 11)
:Global_RegKey
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d "1" /f >nul 2>&1
if %errorlevel% EQU 0 (
    echo [%DATE% %TIME%] GlobalTimerResolutionRequests Reg Key: Successfully Added. >> "C:\Oneclick Logs\Oneclick Log.txt" 
) else (
    echo [%DATE% %TIME%] GlobalTimerResolutionRequests Reg Key: Failed to Add. >> "C:\Oneclick Logs\Oneclick Log.txt" 
)
exit /b

:: Unsupported Windows Version. (For Windows Versions below Win 11 or above Win 11 26H1)
:Unsupported_WinVer
echo [%DATE% %TIME%] Windows Version Status: Unsupported Version. >> "C:\Oneclick Logs\Oneclick Log.txt"
cls
color C
chcp 65001 >nul 2>&1
echo ╔══════════════════════════════════════════╗
echo ║ ⚠️ Unsupported Windows Version Detected. ║
echo ╚══════════════════════════════════════════╝
echo ❌ Windows 11 *21H2-26H1* not detected!
echo.
echo → Running Oneclick on an unsupported version of Windows can cause issues, bugs and unexpected behavior. 
echo However running Oneclick on a supported version of Windows guarantees full support, stability and functionality. 
echo.
echo %White%[Choose an option]
echo %Green%1. Github - *Explains the supported Windows versions in detail*
echo %Red%2. Continue Anyway - *Allows the user to run Oneclick regardless*
echo %DarkYellow%3. Exit - *Closes Oneclick*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] Unsupported Winver: User Chose "Option 1" - Open Github Page. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔════════════════════════════════════════════╗
    echo ║ ✅ Opening Supported Versions Github Page. ║
    echo ╚════════════════════════════════════════════╝
    echo • The github page will now open in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Supported%%20Windows%%20Versions.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Unsupported_WinVer 
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Unsupported Winver: User Chose "Option 2" - Continue Anyway. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔══════════════════════════════╗
    echo ║ ⚠️ Continuing with Oneclick. ║
    echo ╚══════════════════════════════╝
    echo • Now continuing in 2 seconds!
    timeout 2 > nul
    cls
    chcp 437 >nul
    goto :Win_Server_Check
) else if "%option%"=="3" ( 
    echo [%DATE% %TIME%] Unsupported Winver: User Chose "Option 3" - Exit Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════╗
    echo ║ ✅ Exiting Oneclick. ║
    echo ╚══════════════════════╝
    echo • Now closing Oneclick in 5 seconds!
    timeout 5 > nul
    call :Oneclick_Log_End
    exit
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    cls
    goto :Unsupported_WinVer
)

:: Check for Windows Server Version. (Server Versions can use GlobalTimerResolutionRequests)
:Win_Server_Check 
setlocal enabledelayedexpansion
for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName') do set "ProductName=%%A %%B"
echo !ProductName! | find /i "Server" >nul
if !errorlevel! == 0 (
    echo [%DATE% %TIME%] Detected Windows Server Edition: !ProductName! >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo Server> "C:\Oneclick Logs\Extra\WinServerVersion.txt" 
    call :Global_RegKey
    endlocal & goto :VCRuntime_Check
) else (
    echo [%DATE% %TIME%] Detected Non-Server Windows Edition: !ProductName! >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo NonServer> "C:\Oneclick Logs\Extra\WinServerVersion.txt"
    endlocal & goto :VCRuntime_Check
)

:: Check if Visual C++ 2015-2022 Redistributable (x64) is installed. (Needed for SetTimerResolution, and many other apps, etc)
:VCRuntime_Check
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>&1
if %errorlevel% == 0 (
    echo [%DATE% %TIME%] VCRuntime Check: Visual C++ 2015-2022 Redistributable is installed.  >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :UCPD_Check
) else (
    echo [%DATE% %TIME%] VCRuntime Check: Visual C++ 2015-2022 Redistributable is not installed.  >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :VCRuntime_Download

)

:: Download Visual C++ 2015-2022 Redistributable. (VCRuntimes Download and Automatic Setup)
:VCRuntime_Download
cls
color C
chcp 65001 >nul 2>&1
echo ╔════════════════════════════════════════════════════════╗
echo ║ ⚠️ Visual C++ 2015-2022 Redistributable not installed. ║
echo ╚════════════════════════════════════════════════════════╝
echo • Downloading Runtimes!
mkdir "C:\VC Redist" >nul 2>&1
set "FileURL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "FileName=VC_redist.x64.exe"
set "DownloadsFolder=C:\VC Redist"
curl -s -L "%FileURL%" -o "%DownloadsFolder%\%FileName%"
if exist "%DownloadsFolder%\%FileName%" (
   echo [%DATE% %TIME%] VCRuntime: Downloaded successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
   echo %Green%
   echo 1. Visual C++ 2015-2022 Redistributable downloaded successfully.
   echo 2. Now automatically starting the installer.
   echo.
   start "" "C:\VC Redist\VC_redist.x64.exe" /install /passive /norestart
   <nul set /p="→ Press any key to continue . . . "
   pause >nul
   rd /s /q "C:\VC Redist" >nul 2>&1
   cls
   goto :UCPD_Check
) else (
   echo [%DATE% %TIME%] VCRuntime: Download failed. >> "C:\Oneclick Logs\Oneclick Log.txt"
   rd /s /q "C:\VC Redist" >nul 2>&1
   goto :VCRuntime_Download_Failed
)
endlocal

:: Visual C++ 2015-2022 Redistributable Download Failed. (VCRuntime Download Error Handling)
:VCRuntime_Download_Failed
cls
color C
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════════════════════════════════╗
echo ║ ⚠️ Visual C++ 2015-2022 Redistributable failed to download. ║
echo ╚═════════════════════════════════════════════════════════════╝
echo • Please ensure you're connected to the internet!
echo.
echo %White%[Choose an option]
echo %Green%1. Retry - *Tries to download VCRuntimes again*
echo %Cyan%2. Download Manually - *Open's the Microsoft download page*
echo %DarkYellow%3. Continue Anyway - *Allows the user to run Oneclick regardless*
echo %Red%4. Exit - *Closes Oneclick*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] VCRuntime Options: User Chose "Option 1" - Retry download. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════════════════╗
    echo ║ ✅ Retrying VCRuntimes download. ║
    echo ╚══════════════════════════════════╝
    echo • Attempting download again in 2 seconds!
    timeout 2 > nul
    goto :VCRuntime_Download
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] VCRuntime Options: User Chose "Option 2" - Download manually. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔════════════════════════════╗
    echo ║ ✅ Opening Microsoft Page. ║
    echo ╚════════════════════════════╝
    echo • launching the Microsoft page in 2 seconds!
    timeout 2 > nul
    start "" "https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :VCRuntime_Download_Failed
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] VCRuntime Options: User Chose "Option 3" - Continue anyway. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔══════════════════════════════╗
    echo ║ ⚠️ Continuing with Oneclick. ║
    echo ╚══════════════════════════════╝
    echo • Now continuing in 2 seconds!
    timeout 2 > nul
    cls
    chcp 437 >nul
    goto :UCPD_Check
) else if "%option%"=="4" ( 
    echo [%DATE% %TIME%] VCRuntime Options: User Chose "Option 4" - Exit Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════╗
    echo ║ ✅ Exiting Oneclick. ║
    echo ╚══════════════════════╝
    echo • Now closing Oneclick in 5 seconds!
    timeout 5 > nul
    call :Oneclick_Log_End
    exit
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-4.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :VCRuntime_Download_Failed
)

:: Checking if UCPD is running. (If UCPD is enabled, it may prevent some visual changes)
:UCPD_Check
sc query "ucpd" | find "STATE" | find "RUNNING" >nul
if not errorlevel 1 (
    echo [%DATE% %TIME%] UCPD: Service is running. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    goto :UCPD_Disable
) else (
    echo [%DATE% %TIME%] UCPD: Service is not running. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    goto :TrustedInstaller_Check
)

:: User Choice Protection Driver Disable. (Optional menu to disable or not disable UCPD) 
:UCPD_Disable
cls
color C
chcp 65001 >nul 2>&1
echo ╔══════════════════════════════════════════════════════╗
echo ║ ⚠️ User Choice Protection Driver (UCPD) is ENABLED.  ║
echo ╚══════════════════════════════════════════════════════╝
echo • Some visual changes cannot be applied while (UCPD) is enabled.
echo.
echo → Do you want to disable (UCPD) and restart?
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] UCPD Disabler: User Chose "Yes" - Disabling UCPD. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    cls
    color A
    echo ╔═════════════════════════════════════════════╗
    echo ║ ✅ Disabling User Choice Protection Driver. ║
    echo ╚═════════════════════════════════════════════╝
    echo • Disabling [UCPD] Service. 
    sc config "ucpd" start=disabled >nul 2>&1
    ::
    echo • Disabling [UCPD] Task.
    schtasks /change /disable /tn "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity" >nul 2>&1
    ::
    echo ✔  [UCPD] disabled successfully.
    echo.
    echo %Red%❌ System Restart Required, restarting in 5 seconds!
    call :Autorun_Oneclick  
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] UCPD Disabler: User Chose "No" - Not Disabling UCPD. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    cls
    color C
    echo ╔════════════════════════╗
    echo ║ ❌ Not disabling UCPD. ║
    echo ╚════════════════════════╝
    echo • Continuing with Oneclick.
    timeout 2 > nul
    cls
    chcp 437 >nul
    goto :TrustedInstaller_Check
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    cls
    goto :UCPD_Disable
)

:: Autorun Oneclick After Restart. (Restarts and runs Oneclick upon startup)
:Autorun_Oneclick
set "OneclickPath=%~f0"
echo [%DATE% %TIME%] Autorun Oneclick Path: %OneclickPath% >> "C:\Oneclick Logs\Oneclick Log.txt"
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "AutorunOneclickAfterRestart" /t REG_SZ /d "\"%OneclickPath%\"" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo [%DATE% %TIME%] Autorun Reg Key: Successfully Added. >> "C:\Oneclick Logs\Oneclick Log.txt"
    timeout 5 > nul
    call :Oneclick_Log_End
    shutdown /r /t 0
    exit  
) else (
    echo [%DATE% %TIME%] Autorun Reg Key: Failed to Add. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    cls
    color C
    chcp 65001 >nul 2>&1
    echo ╔════════════════════════════════════╗
    echo ║ ❌ Autorun Reg Key: Failed to Add. ║
    echo ╚════════════════════════════════════╝
    echo • Oneclick will not run on the next startup, please manually open it.
    echo
    echo Restarting regardless in 5 seconds!
    timeout 5 > nul
    call :Oneclick_Log_End
    shutdown /r /t 0
    exit 
)

:: Check if TrustedInstaller is disabled. (TrustedInstaller needs to be enabled for Nsudo)
:TrustedInstaller_Check
sc qc "TrustedInstaller" | find "START_TYPE" | find "DISABLED" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] TrustedInstaller: Service is not disabled. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] TrustedInstaller: Service is disabled, attempting to re-enable. >> "C:\Oneclick Logs\Oneclick Log.txt"
    sc config TrustedInstaller start=auto >nul 2>&1
    net start TrustedInstaller >nul 2>&1
)

:: Checking if Oneclick Tools exist. (Tools folder required for Oneclick to properly run)
if not exist "C:\Oneclick Tools" (
   echo [%DATE% %TIME%] Oneclick Tools Check: Folder doesn't exist. >> "C:\Oneclick Logs\Oneclick Log.txt" 
) else (
   echo [%DATE% %TIME%] Oneclick Tools Check: Folder already exist - Reinstalling. >> "C:\Oneclick Logs\Oneclick Log.txt"
   rd /s /q "C:\Oneclick Tools" >nul 2>&1 
)
goto :Download_Tools

:: Downloading Oneclick Tools at start. (Includes Audio Bloat Remover, Autologger Destroyer, Browser Downloader, DPC Checker, Edge Remover, Nsudo, Nvidia Profile Inspector, Oneclick Wallpaper, OOShutup10, Power Plans, Process Destroyer, Task Destroyer, Timer Resolution, Update Disabler, Winver Logo, etc)
:Download_Tools
setlocal
set "FileURL=https://github.com/QuakedK/Oneclick/raw/refs/heads/main/Downloads/V8.0/OneclickTools.zip"
set "FileName=Oneclick Tools.zip"
set "ExtractFolder=C:\Oneclick Tools"
set "DownloadsFolder=C:\"
curl -s -L "%FileURL%" -o "%DownloadsFolder%\%FileName%"
if %errorlevel% equ 0 (
    echo [%DATE% %TIME%] Oneclick Tools Download: Successfully downloaded. >> "C:\Oneclick Logs\Oneclick Log.txt"
    mkdir "%ExtractFolder%" >nul 2>&1
    pushd "%ExtractFolder%" >nul 2>&1
    tar -xf "%DownloadsFolder%\%FileName%" --strip-components=1 >nul 2>&1
    popd >nul 2>&1
    del /q "C:\Oneclick Tools.zip" >nul 2>&1
    endlocal & goto :Oneclick_Backup_Folder_Check
) else (
    echo [%DATE% %TIME%] Oneclick Tools Download: Failed to download. >> "C:\Oneclick Logs\Oneclick Log.txt"
    endlocal & goto :Tools_Download_Failed
)

:: Oneclick Tools failed to download. (Oneclick Tools Download Error Handling)
:Tools_Download_Failed
cls
color C
chcp 65001 >nul 2>&1
echo ╔══════════════════════════════════════════════╗
echo ║ ⚠️ Oneclick Tools Folder failed to download. ║
echo ╚══════════════════════════════════════════════╝
echo • Please ensure you're connected to the internet!
echo.
echo %White%[Choose an option]
echo %Green%1. Retry - *Tries to download the tools folder again*
echo %Cyan%2. Download Manually - *Open's Github page*
echo %DarkYellow%3. Continue Anyway - *Allows the user to run Oneclick regardless*
echo %Red%4. Exit - *Closes Oneclick*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] Oneclick Tools Options: User Chose "Option 1" - Retry download. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════════════════════╗
    echo ║ ✅ Retrying Oneclick Tools download. ║
    echo ╚══════════════════════════════════════╝
    echo • Attempting download again in 2 seconds!
    timeout 2 > nul
    cls
    chcp 437 >nul
    goto :Download_Tools
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Oneclick Tools Options: User Chose "Option 2" - Download manually. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Github Page. ║
    echo ╚═════════════════════════╝
    echo • Launching Github page in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Oneclick%%20Tools%%20Help.md#2-manual-download"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Tools_Download_Failed
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Oneclick Tools Options: User Chose "Option 3" - Continue Anyway. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔══════════════════════════════╗
    echo ║ ⚠️ Continuing with Oneclick. ║
    echo ╚══════════════════════════════╝
    echo • Now continuing in 2 seconds!
    timeout 2 > nul
    cls
    chcp 437 >nul
    goto :Oneclick_Backup_Folder_Check
) else if "%option%"=="4" ( 
    echo [%DATE% %TIME%] Oneclick Tools Options: User Chose "Option 4" - Exit Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════╗
    echo ║ ✅ Exiting Oneclick. ║
    echo ╚══════════════════════╝
    echo • Now closing Oneclick in 5 seconds!
    timeout 5 > nul
    call :Oneclick_Log_End
    exit
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-4.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Tools_Download_Failed
)

:: Check for Oneclick Backup Folder. (Checks if the backup folder exists to avoid overwriting existing backups)
:Oneclick_Backup_Folder_Check
if not exist "C:\Oneclick Backup" (
   mkdir "C:\Oneclick Backup" >nul 2>&1
   set "Oneclick_Backup_Folder=C:\Oneclick Backup"
   call echo [%DATE% %TIME%] Oneclick Backup Folder Check: Folder doesn't exist - "%%Oneclick_Backup_Folder%%" Created. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else (
   for /f "usebackq delims=" %%A in (`Powershell -NoProfile -Command "Get-Date -Format 'MM-dd-yyyy_HH-mm'"`) do set "CurrentDate=%%A"
   call set "Oneclick_Backup_Folder=C:\Oneclick Backup [%%CurrentDate%%]"
   call mkdir "%%Oneclick_Backup_Folder%%" >nul 2>&1
   call echo [%DATE% %TIME%] Oneclick Backup Folder Check: Folder already exists - "%%Oneclick_Backup_Folder%%" Created. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Check for Windows Defender. (Detects whether or not, Defender is running) 
:Defender_Check
sc query "WinDefend" | find "STATE" | find "RUNNING" >nul
if not errorlevel 1 (
    echo [%DATE% %TIME%] Windows Defender Check: Defender is running. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Disable_Defender
) else ( 
    echo [%DATE% %TIME%] Windows Defender Check: Defender is not running. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Oneclick_Start_Screen_Colors
)

:: Windows Defender Disable. (Optional menu to disable or not disable Defender) 
:Disable_Defender
cls
color C
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════╗
echo ║ ⚠️ Windows Defender is ENABLED. ║
echo ╚═════════════════════════════════╝
echo • It's recommended you temporarily disable Windows Defender.
echo.
echo %White%[Choose an option]
echo %Green%1. Disable - *Disables Windows Defender*
echo %DarkYellow%2. Keep Enabled - *Keeps Windows Defender Enabled*
echo %Cyan%3. Learn More - *Explains Defender Options*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] Windows Defender Options: User Chose "Option 1" - Disable Windows Defender. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═══════════════════════════════╗
    echo ║ ⚠️ Additional Setup Required. ║
    echo ╚═══════════════════════════════╝
    echo • Some Windows Defender settings need to be disabled.
    timeout 2 > nul
    goto :RTP_TPR_Disable     
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Windows Defender Options: User Chose "Option 2" - Keep Windows Defender Enabled. >> "C:\Oneclick Logs\Oneclick Log.txt"  
    cls
    color C
    echo ╔══════════════════════════════════════╗
    echo ║ ⚠️ Keeping Windows Defender Enabled. ║
    echo ╚══════════════════════════════════════╝
    echo • Now continuing with Oneclick.
    echo.
    echo → Disabling Windows Defender Automatic Sample Submission Telementry.
    chcp 437 >nul
    Powershell -NoProfile -Command "Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue" 
    chcp 65001 >nul 2>&1
    timeout 2 > nul
    goto :Oneclick_Start_Screen_Colors 
) else if "%option%"=="3" ( 
    echo [%DATE% %TIME%] Windows Defender Options: User Chose "Option 3" - Learn More. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Github Page. ║
    echo ╚═════════════════════════╝
    echo • Launching the Github page in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Windows%%20Defender%%20Options.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Disable_Defender
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    cls
    goto :Disable_Defender
)

:: Real Time and Tamper Protection disable. (Guides the user to disable defender related settings)
:RTP_TPR_Disable 
cls
color A
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════════════════════╗
echo ║ ✅ Disabling Real Time and Tamper Protection. ║
echo ╚═══════════════════════════════════════════════╝
echo • Required to install and download Dcontrol.
echo. 
echo %White%📌 [Step 1] 
echo %Green%Please click Virus ^& Threat Protection.
echo.
echo %White%📌 [Step 2] 
echo %Green%Then click Manage Settings.
echo.
echo %White%📌 [Step 3] 
echo %Green%Now turn off Real Time Protection and Tamper Protection.
echo.
timeout 2 > nul
start windowsdefender: >nul 2>&1
<nul set /p="%White%Once all steps are completed, Press any key to continue . . . "
pause >nul
taskkill /f /im SecHealthUI.exe >nul 2>&1
goto :Dcontrol_Download

:: Download Dcontrol. (Program that disables Windows Defender) 
:Dcontrol_Download
cls
color A
chcp 65001 >nul 2>&1
echo ╔══════════════════════════╗
echo ║ ✅ Downloading Dcontrol. ║
echo ╚══════════════════════════╝
echo • Allows the user to completely disable Windows Defender.
mkdir "C:\Dcontrol" >nul 2>&1
set "FileURL=https://github.com/QuakedK/Oneclick/raw/refs/heads/main/Downloads/V8.0/dControl.exe"
set "FileName=dControl.exe"
set "DownloadsFolder=C:\Dcontrol"
curl -s -L "%FileURL%" -o "%DownloadsFolder%\%FileName%"
if exist "%DownloadsFolder%\%FileName%" (
   echo [%DATE% %TIME%] Dcontrol: Downloaded successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
   echo.
   echo %White%📌 [Step 1] 
   echo %Green%Please click disable Windows Defender.
   echo.
   echo %White%📌 [Step 2] 
   echo %Green%Then click Menu.
   echo.
   echo %White%📌 [Step 3] 
   echo %Green%Now click add to the Exclusion List.
   timeout 2 > nul
   start "" "C:\Dcontrol\dControl.exe"
   echo.
   <nul set /p="%White%Once all steps are completed, Press any key to continue . . . "
   pause >nul
   taskkill /IM dControl.exe /F >nul 2>&1
   rd /s /q "C:\Dcontrol" >nul 2>&1
   cls
   goto :Dcontrol_Run_Check
) else (
   echo [%DATE% %TIME%] Dcontrol: Download failed. >> "C:\Oneclick Logs\Oneclick Log.txt"
   rd /s /q "C:\Dcontrol" >nul 2>&1
   goto :Dcontrol_Download_Failed
)
endlocal

:: Dcontrol Download Failed. (Dcontrol Download Error Handling)
:Dcontrol_Download_Failed
cls
color C
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════╗
echo ║ ⚠️ Dcontrol failed to download. ║
echo ╚═════════════════════════════════╝
echo • Please ensure you're connected to the internet!
echo.
echo %White%[Choose an option]
echo %Green%1. Retry - *Tries to download Dcontrol again*
echo %Cyan%2. Download Manually - *Open's the Sordum download page*
echo %DarkYellow%3. Continue Anyway - *Allows the user to skip disabling Defender*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] Dcontrol Download Options: User Chose "Option 1" - Retry download. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════════════════╗
    echo ║ ✅ Retrying Dcontrol's download. ║
    echo ╚══════════════════════════════════╝
    echo • Attempting download again in 2 seconds!
    timeout 2 > nul
    goto :Dcontrol_Download
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Dcontrol Download Options: User Chose "Option 2" - Download manually. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Sordum Page. ║
    echo ╚═════════════════════════╝
    echo • Launching the Sordum page in 2 seconds!
    timeout 2 > nul
    start "" "https://www.sordum.org/9480/defender-control-v2-1/"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Dcontrol_Download_Failed
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Dcontrol Download Options: User Chose "Option 3" - Continue anyway. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔══════════════════════════════╗
    echo ║ ⚠️ Continuing with Oneclick. ║
    echo ╚══════════════════════════════╝
    echo • Now continuing in 2 seconds!
    timeout 2 > nul
    cls
    chcp 437 >nul
    goto :Oneclick_Start_Screen_Colors
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Dcontrol_Download_Failed
)

:: Check if Dcontrol ran successfully. (If Dcontrol successfully ran, it will exist in Program Files)
:Dcontrol_Run_Check
if exist "C:\Program Files (x86)\DefenderControl\dControl.exe" (
    echo [%DATE% %TIME%] Dcontrol: Ran successfully.  >> "C:\Oneclick Logs\Oneclick Log.txt"   
) else (
    echo [%DATE% %TIME%] Dcontrol: Didn't Run. >> "C:\Oneclick Logs\Oneclick Log.txt" 
)

:: Check if Windows Defender got disabled. (2nd Defender check to see if Dcontrol successfully disabled Defender)
sc qc "WinDefend" | find "START_TYPE" | find "DISABLED" >nul
if not errorlevel 1 (
    echo [%DATE% %TIME%] Windows Defender Re-Check: Defender successfully disabled. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else (
    echo [%DATE% %TIME%] Windows Defender Re-Check: Defender not disabled. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Disable SecurityHealthService. (NSudo required to delete it)
"C:\Oneclick Tools\NSudo\NSudoLG.exe" -ShowWindowMode:hide -U:T -P:E cmd /c reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d "4" /f
if errorlevel 1 (
    echo [%DATE% %TIME%] SecurityHealthService Disable: Failed to run through Nsudo. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else (
    echo [%DATE% %TIME%] SecurityHealthService Disable: Ran successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Oneclick Start Screen Loop Colors. (Defines the Start Screen colors)
:Oneclick_Start_Screen_Colors
cls
set "Colors=201 129 39 51 46 220 214 208 196"
chcp 65001 >nul 2>&1

:: Oneclick Start Screen Loop Breaker. (Detects any input, to break out of the Start Screen Loop)
del "%Temp%\Skip.Loop" >nul 2>&1
start "" /b cmd /c "pause >nul & echo.>"%Temp%\Skip.Loop""

:: Oneclick Start Screen Loop. (Color changing Start Screen Loop)
:Oneclick_Start_Screen_loop
for %%C in (%Colors%) do (
    if exist "%temp%\Skip.Loop" goto :Restore_Point
    echo [38;5;%%Cm
    echo.
    echo.
    echo.
    echo.
    echo.
    echo.
    echo.
    echo.                             ▒█████   ███▄    █ ▓█████     ▄████▄   ██▓     ██▓ ▄████▄   ██ ▄█▀     
    echo.                            ▒██▒  ██▒ ██ ▀█   █ ▓█   ▀    ▒██▀ ▀█  ▓██▒    ▓██▒▒██▀ ▀█   ██▄█▒      
    echo.                            ▒██░  ██▒▓██  ▀█ ██▒▒███      ▒▓█    ▄ ▒██░    ▒██▒▒▓█    ▄ ▓███▄░      
    echo.                            ▒██   ██░▓██▒  ▐▌██▒▒▓█  ▄    ▒▓▓▄ ▄██▒▒██░    ░██░▒▓▓▄ ▄██▒▓██ █▄      
    echo.                            ░ ████▓▒░▒██░   ▓██░░▒████▒   ▒ ▓███▀ ░░██████▒░██░▒ ▓███▀ ░▒██▒ █▄     
    echo.                            ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░░ ▒░ ░   ░ ░▒ ▒  ░░ ▒░▓  ░░▓  ░ ░▒ ▒  ░▒ ▒▒ ▓▒     
    echo.                              ░ ▒ ▒░ ░ ░░   ░ ▒░ ░ ░  ░     ░  ▒   ░ ░ ▒  ░ ▒ ░  ░  ▒   ░ ░▒ ▒░     
    echo.                            ░ ░ ░ ▒     ░   ░ ░    ░      ░          ░ ░    ▒ ░░        ░ ░░ ░      
    echo.                                ░ ░           ░    ░  ░   ░ ░          ░  ░ ░  ░ ░      ░  ░        
    echo. 
    echo.                                  ╔════════════════════════════════════════════════════╗
    echo.                                  ║              Version 8.3 - By Quaked               ║
    echo.                                  ╚════════════════════════════════════════════════════╝
    echo.
    echo.
    echo.
    echo.
    echo.
    echo. 
    echo.                                                                        
    <nul set /p="→ Press any key to continue . . . " 
    PATHPING 127.0.0.1 -n -q 1 -p 650 >nul
    cls
)
goto :Oneclick_Start_Screen_loop

:: Restore Point. (Optional menu to create or not create a Restore Point)
:Restore_Point
cls
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
echo.                                 ██▀███  ▓█████   ██████ ████████▓ ▒█████   ██▀███  ▓█████ 
echo.                                ▓██ ▒ ██▒▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒▒██▒  ██▒▓██ ▒ ██▒▓█   ▀ 
echo.                                ▓██ ░▄█ ▒▒███   ░ ▓██▄   ▒ ▓██░ ▒░▒██░  ██▒▓██ ░▄█ ▒▒███   
echo.                                ▒██▀▀█▄  ▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ ▒██   ██░▒██▀▀█▄  ▒▓█  ▄ 
echo.                                ░██▓ ▒██▒░▒████▒▒██████▒▒  ▒██▒ ░ ░ ████▓▒░░██▓ ▒██▒░▒████▒
echo.                                ░ ▒▓ ░▒▓░░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░░ ▒░ ░
echo.                                  ░▒ ░ ▒░ ░ ░  ░░ ░▒  ░ ░    ░      ░ ▒ ▒░   ░▒ ░ ▒░ ░ ░  ░
echo.                                  ░░   ░    ░   ░  ░  ░    ░      ░ ░ ░ ▒    ░░   ░    ░   
echo.                                   ░        ░  ░      ░               ░ ░     ░        ░  ░
echo. 
echo.                                  ╔════════════════════════════════════════════════════╗
echo.                                  ║   Create a restore point to undo system changes.   ║
echo.                                  ╚════════════════════════════════════════════════════╝
echo.
echo.
echo.
echo.
echo.
echo.                                                                     
echo %Green%[Highly Recommended]
echo %Blue%→ Do you want to make a restore point?
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] Restore Point Options: User Chose "Yes" - Creating Restore Point. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    goto :Setup_Restore_Point
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] Restore Point Options: User Chose "No" - Not creating a Restore Point. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    goto :No_Restore_Point
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Restore_Point
)

:: System Restore Setup.
:Setup_Restore_Point
color A
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════════╗
echo ║ ✅ Setting Up System Restore Point. ║
echo ╚═════════════════════════════════════╝
echo • Main Windows Drive: 💾 %SystemDrive%
echo. 
echo → Applying System Restore Registry Tweaks.
echo ✅ The operation completed successfully.
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d "0" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SystemRestore" /v "DisableConfig" /f >nul 2>&1
echo.
echo → Enabling System Restore Services.
echo ✅ [SC] ChangeServiceConfig SUCCESS.
sc config VSS start=demand >nul 2>&1
sc config swprv start=demand >nul 2>&1
echo.
echo → Enabling System Protection.
chcp 437 >nul
Powershell -NoProfile -Command "try { $ErrorActionPreference='Stop'; Enable-ComputerRestore -Drive '%SystemDrive%\' ; exit 0 } catch { exit 1 }" >nul 2>&1
set "SP_Error=%ERRORLEVEL%"
chcp 65001 >nul
if %SP_Error% neq 0 (
    echo [%DATE% %TIME%] System Protection: Could not enabled on %SystemDrive% >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo %Red%❌ Could not enable System Protection on 💾 %SystemDrive%
    timeout 2 > nul 
    goto :Restore_Failure
) else (
    echo [%DATE% %TIME%] System Protection: Successfully enabled on %SystemDrive% >> "C:\Oneclick Logs\Oneclick Log.txt" 
    echo ✅ System Protection successfully enabled on 💾 %SystemDrive%
    timeout 2 > nul 
    goto :Create_Restore_Point
)

:: System Restore Point Creation.
:Create_Restore_Point
echo.
echo → Creating System Restore Point.
chcp 437 >nul
Powershell -NoProfile -Command "try { $ProgressPreference='SilentlyContinue'; $ErrorActionPreference='Stop'; Checkpoint-Computer -Description 'Oneclick V8.3 Restore Point'; exit 0 } catch { exit 1 }" >nul 2>&1
set "RP_Error=%ERRORLEVEL%"
chcp 65001 >nul 2>&1
if %RP_Error% neq 0 (
    echo [%DATE% %TIME%] System Restore Point: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    echo %Red%❌ Failed to create System Restore Point.
    timeout 2 > nul
    goto :Restore_Failure
) else (
    echo [%DATE% %TIME%] System Restore Point: Successfully created. >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo ✅ System Restore Point created successfully.
    timeout 2 > nul
    goto :Registry_Backup
)

:: System Protection/Restore Point Failure.
:Restore_Failure
cls
color C
chcp 65001 >nul 2>&1
echo ╔════════════════════════════════════════════════════╗
echo ║ ⚠️ Your System Protection or Restore Point FAILED. ║
echo ╚════════════════════════════════════════════════════╝
echo ❌ You won't be able to easily revert system changes without one!
echo.
echo → Do you still wish to continue? (LAST WARNING)
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] Restore Point Failure Options: User Chose "Yes" - Continue with Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═══════════════════╗
    echo ║ ❌ Not Restoring. ║
    echo ╚═══════════════════╝
    echo • Now continuing with Oneclick.
    timeout 2 > nul
    goto :Registry_Backup
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] Restore Point Failure Options: User Chose "No" - Exit Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════╗
    echo ║ ✅ Exiting Oneclick. ║
    echo ╚══════════════════════╝
    echo • Now closing Oneclick in 5 seconds!
    timeout 5 > nul
    call :Oneclick_Log_End
    exit
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    cls
    goto :Restore_Failure
)

:: No Restore Point Selected.
:No_Restore_Point
cls
color C
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════════════╗
echo ║ ⚠️ Not Creating System Restore Point. ║
echo ╚═══════════════════════════════════════╝
echo ❌ You won't be able to easily revert system changes without one!
echo.
echo → Do you still wish to continue? (LAST WARNING)
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] No Restore Point Options: User Chose "Yes" - Continue with Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═══════════════════╗
    echo ║ ❌ Not Restoring. ║
    echo ╚═══════════════════╝
    echo • Now continuing with Oneclick.
    timeout 2 > nul
    goto :Registry_Backup
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] No Restore Point Options: User Chose "No" - Exit Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════╗
    echo ║ ✅ Exiting Oneclick. ║
    echo ╚══════════════════════╝
    echo • Now closing Oneclick in 2 seconds!
    timeout 2 > nul
    call :Oneclick_Log_End
    exit
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    cls
    goto :No_Restore_Point
)

:: Registry Backup. (Optional menu to create or not create a Registry Backup)
:Registry_Backup
cls
color D
chcp 65001 >nul 2>&1
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.                                ██▀███  ▓█████   ▄████  ██▓  ██████ ▄▄▄█████▓ ██▀███ ▓██   ██▓
echo.                               ▓██ ▒ ██▒▓█   ▀  ██▒ ▀█▒▓██▒▒██    ▒ ▓  ██▒ ▓▒▓██ ▒ ██▒▒██  ██▒
echo.                               ▓██ ░▄█ ▒▒███   ▒██░▄▄▄░▒██▒░ ▓██▄   ▒ ▓██░ ▒░▓██ ░▄█ ▒ ▒██ ██░
echo.                               ▒██▀▀█▄  ▒▓█  ▄ ░▓█  ██▓░██░  ▒   ██▒░ ▓██▓ ░ ▒██▀▀█▄   ░ ▐██▓░
echo.                               ░██▓ ▒██▒░▒████▒░▒▓███▀▒░██░▒██████▒▒  ▒██▒ ░ ░██▓ ▒██▒ ░ ██▒▓░
echo.                               ░ ▒▓ ░▒▓░░░ ▒░ ░ ░▒   ▒ ░▓  ▒ ▒▓▒ ▒ ░  ▒ ░░   ░ ▒▓ ░▒▓░  ██▒▒▒ 
echo.                                 ░▒ ░ ▒░ ░ ░  ░  ░   ░  ▒ ░░ ░▒  ░ ░    ░      ░▒ ░ ▒░▓██ ░▒░ 
echo.                                 ░░   ░    ░   ░ ░   ░  ▒ ░░  ░  ░    ░        ░░   ░ ▒ ▒ ░░  
echo.                                  ░        ░  ░      ░  ░        ░              ░     ░ ░     
echo.                                                       ░ ░     
echo. 
echo.                                 ╔══════════════════════════════════════════════════════╗
echo.                                 ║ Create a registry backup to revert registry changes. ║
echo.                                 ╚══════════════════════════════════════════════════════╝
echo.
echo.
echo.
echo.
echo.
echo.                                                                     
echo %Green%[Highly Recommended]
echo %Magenta%→ Do you want to create a registry backup?
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] Registry Options: User Chose "Yes" - Creating Registry Backup. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    goto :Create_Registry_Backup
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] Registry Options: User Chose "No" - Not creating a Registry Backup. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    goto :No_Registry_Backup
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Registry_Backup
)

:: Registry Backup.
:Create_Registry_Backup
setlocal
cls
color A
chcp 65001 >nul 2>&1
echo ╔═════════════════════════╗
echo ║ ✅ Backing Up Registry. ║
echo ╚═════════════════════════╝
mkdir "%Oneclick_Backup_Folder%\Registry" >nul 2>&1
set "RegBackupFailed=0"
for %%R in (HKLM HKCU HKCR HKU HKCC) do (
    reg export "%%R" "%Oneclick_Backup_Folder%\Registry\%%R.reg" /y >nul 2>&1
    if errorlevel 1 (
        echo [%DATE% %TIME%] %%R Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
        echo • %%R Reg Backup failed to create.
        set "RegBackupFailed=1" 
    ) else (
        echo [%DATE% %TIME%] %%R Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
        echo • %%R Reg Backup created successfully.
    )
)
if "%RegBackupFailed%"=="1" (
    timeout 2 > nul
    goto :Registry_Backup_Failure
) else (
    timeout 2 > nul
    echo.
    echo ✔  All Registry Backups created successfully.
    goto :System_Visual_Perferences
)
endlocal

:: Registry Backup Failure.
:Registry_Backup_Failure
cls
color C
chcp 65001 >nul 2>&1
echo ╔════════════════════════════════════════════╗
echo ║ ⚠️ Your Registry Backups Failed To Create. ║
echo ╚════════════════════════════════════════════╝
echo ❌ You won't be able to easily revert all registry changes without them!
echo.
echo → Do you still wish to continue? (LAST WARNING)
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] Registry Backup Failure Options: User Chose "Yes" - Continue with Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═══════════════════════════════════╗
    echo ║ ❌ Not creating Registry Backups. ║
    echo ╚═══════════════════════════════════╝
    echo • Now continuing with Oneclick.
    timeout 2 > nul
    goto :System_Visual_Perferences
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] Registry Backup Failure Options: User Chose "No" - Exit Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════╗
    echo ║ ✅ Exiting Oneclick. ║
    echo ╚══════════════════════╝
    echo • Now closing Oneclick in 5 seconds!
    timeout 5 > nul
    call :Oneclick_Log_End
    exit
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    cls
    goto :Registry_Backup_Failure
)

:: No Registry Backup Selected.
:No_Registry_Backup
cls
color C
chcp 65001 >nul 2>&1
echo ╔════════════════════════════════════════════╗
echo ║ ⚠️ Your Registry Backups Failed To Create. ║
echo ╚════════════════════════════════════════════╝
echo ❌ You won't be able to easily revert all registry changes without them!
echo.
echo → Do you still wish to continue? (LAST WARNING)
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] No Registry Backup Options: User Chose "Yes" - Continue with Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═══════════════════════════════════╗
    echo ║ ❌ Not creating Registry Backups. ║
    echo ╚═══════════════════════════════════╝
    echo • Now continuing with Oneclick.
    timeout 2 > nul
    goto :System_Visual_Perferences
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] No Registry Backup Options: User Chose "No" - Exit Oneclick. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔══════════════════════╗
    echo ║ ✅ Exiting Oneclick. ║
    echo ╚══════════════════════╝
    echo • Now closing Oneclick in 2 seconds!
    timeout 2 > nul
    call :Oneclick_Log_End
    exit
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    cls
    goto :No_Registry_Backup
)

:: System Visual Perferences. 
:System_Visual_Perferences
cls
color 9
chcp 65001 >nul 2>&1
echo ╔════════════════════════════════════════╗
echo ║ ✅ Changing System Visual Perferences. ║
echo ╚════════════════════════════════════════╝

echo • Enabling Show File Extensions.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Enabling Hidden Files and Folders.
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Removing Home and Gallery.
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f >nul 2>&1 

echo • Disabling Meet Now. 
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Home Page. 
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1

echo • Disabling Web Search.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Search Button.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Widgets Button.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Task View Button.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling News ^& Interests. 
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Transparency Effects.
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize /v "EnableTransparency" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Search Recommendations.
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "HideRecommendedSection" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Education" /v "IsEducationEnvironment" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Changing File Explorer Settings.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v "LaunchTo" /t REG_DWORD /d "1" >nul 2>&1  
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" /v "EnthusiastMode" /t REG_DWORD /d "1" /f >nul 2>&1  
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d "1" /f >nul 2>&1  

echo • Changing Taskbar Alignment.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Changing Display For Performance.
reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "200" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f >nul 2>&1

echo • Changing Right Click Menu to Win 10.
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1

echo • Changing to the (Purple ^& Blue) Oneclick Wallpaper.
chcp 437 >nul
Powershell -NoProfile -Command "[void](Add-Type '[DllImport(\"user32.dll\")]public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);' -Name NativeMethods -Namespace Win32 -PassThru)::SystemParametersInfo(20, 0, 'C:\Oneclick Tools\Oneclick Wallpaper\Oneclick Purple & Blue 4K Wallpaper.jpg', 3)"
reg add "HKCU\Control Panel\Desktop" /V "WallpaperStyle" /T REG_SZ /F /D "10" >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /V "TileWallpaper" /T REG_SZ /F /D "0" >nul 2>&1
chcp 65001 >nul 2>&1

echo • Changing the Winver Branding Logo, to a Custom Oneclick Logo.
setlocal

:: Basebrd Path.
set "BasebrdDLL=C:\Windows\Branding\Basebrd\basebrd.dll"

:: Check if Basebrd.dll exist + Take Ownership.
if exist "%BasebrdDLL%" (
    takeown /F "%BasebrdDLL%" >nul 2>&1
    icacls "%BasebrdDLL%" /grant administrators:F >nul 2>&1
    goto :Backup_Basebrd
) else (
    goto :Replace_Basebrd
)

:: Backup Original Basebrd Dll.
:Backup_Basebrd
copy /Y "C:\Windows\Branding\Basebrd\basebrd.dll" "C:\Oneclick Tools\Winver Logo\DLL Backup" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Winver Logo Backup: Failed to copy Basebrd.dll to the Backup Folder. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else (
    echo [%DATE% %TIME%] Winver Logo Backup: Successfully copied Basebrd.dll to the Backup Folder. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Replace Basebrd Dll. (Changes the Winver Branding Logo)
:Replace_Basebrd
move /Y "C:\Oneclick Tools\Winver Logo\basebrd.dll" "C:\Windows\Branding\Basebrd" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Winver Logo Change: Failed to change the Winver Branding Logo. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else (
    echo [%DATE% %TIME%] Winver Logo Change: Successfully changed the Winver Branding Logo. >> "C:\Oneclick Logs\Oneclick Log.txt"
)
endlocal

echo • Changing the OEM Information.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Manufacturer" /t REG_SZ /d "Quaked Tweaks" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "SupportURL" /t REG_SZ /d "https://discord.gg/8NqDSMzYun" /f >nul 2>&1

echo • Adding Quaked Tweaks Branding Service.
sc create "Quaked Tweaks" binPath="C:\Oneclick.bat" start=disabled >nul 2>&1
sc description "Quaked Tweaks" "This is a dummy service that does nothing and is used for branding and marketing purposes." >nul 2>&1

echo ✔  Visual Perferences changed successfully.
timeout 2 > nul

:: System Settings.
cls
color D
chcp 65001 >nul 2>&1
echo ╔══════════════════════════════╗
echo ║ ✅ Changing System Settings. ║
echo ╚══════════════════════════════╝

:: Update Disabler | Completely disables Windows Updates | (NSudo required to disable them)
echo • Disabling Windows Updates.
"C:\Oneclick Tools\NSudo\NSudoLG.exe" -ShowWindowMode:hide -U:T -P:E "C:\Oneclick Tools\Update Disabler\Oneclick Update Disabler V1.2.bat" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Update Disabler: Failed to run through Nsudo. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

echo • Disabling Notifications.
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Background Apps.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Mouse Acceleration.
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1

echo • Disabling Sticky, Filter ^& Toggle Keys.
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "58" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul 2>&1

echo • Enabling Optimizations for Windowed Games.  
reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "SwapEffectUpgradeEnable=1;" /f >nul 2>&1

echo • Enabling Hardware Accelerated GPU Scheduling.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d "2" /f >nul 2>&1

echo • Disabling GameDVR.
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehavior /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_DSEBehavior /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_EFSEFeatureFlags /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AudioCaptureEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "CursorCaptureEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "MicrophoneCaptureEnabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Gamemode.
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Storage Sense.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling IPv6.
chcp 437 >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d "255" /f >nul 2>&1
Powershell -NoProfile -Command "Disable-NetAdapterBinding -Name '*' -ComponentID ms_tcpip6" >nul 2>&1
chcp 65001 >nul 2>&1

echo • Disabling Teredo.
netsh interface teredo set state disabled >nul 2>&1

echo • Disabling UAC.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Tweaking Multimedia Key.
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "10" /f >nul 2>&1

echo ✔  System Settings changed successfully.
timeout 2 > nul

:: Telemetry
cls
color 9
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════╗
echo ║ ✅ Removing System Telemetry. ║
echo ╚═══════════════════════════════╝

:: Task Destroyer | Deletes all System Task | (NSudo required to delete them)
echo • Running Task Destroyer.
"C:\Oneclick Tools\NSudo\NSudoLG.exe" -ShowWindowMode:hide -U:T -P:E "C:\Oneclick Tools\Task Destroyer\Oneclick Task Destroyer V1.3.bat" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Task Destroyer: Failed to run through Nsudo. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: OOshutup10 | Launches with an optimized config.
echo • Running OOshutup10.
"C:\Oneclick Tools\OOshutup10\OOSU10.exe" "C:\Oneclick Tools\OOshutup10\QuakedOOshutup10 V2.cfg" /quiet
if errorlevel 1 (
    echo [%DATE% %TIME%] OOshutup10: Failed to run. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else (
    echo [%DATE% %TIME%] OOshutup10: Ran successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Autologger Destroyer | Disables all Windows Autologgers | (NSudo required to disable them)
echo • Running Autologger Destroyer.
"C:\Oneclick Tools\NSudo\NSudoLG.exe" -ShowWindowMode:hide -U:T -P:E "C:\Oneclick Tools\Autologger Destroyer\Oneclick Autologger Destroyer V1.0.bat" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Autologger Destroyer: Failed to run through Nsudo. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

echo • Disabling Activity History.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d "0" /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Location Services.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "SensorPermissionState" /t REG_DWORD /d "0" /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" /v "Status" /t REG_DWORD /d "0" /f >nul 2>&1 
reg add "HKLM\SYSTEM\Maps" /v "AutoUpdateEnabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Data Collection.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Driver Searching.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" /v "DisableCoInstallers" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Network Telemetry.
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" /v "Value" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v "Value" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" /v "NoActiveProbe" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Services\NlaSvc\Parameters\Internet" /v "EnableActiveProbing" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Windows Feedback Prompts.
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d "0" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds" /f >nul 2>&1

echo • Disabling Windows Content Delivery Settings.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353698Enabled" /t REG_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Windows Defender Core isolation.
reg add "HKLM\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Windows Defender Smart App Control.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v "VerifiedAndReputablePolicyState" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Virtualization Based Security.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d "0" /f >nul 2>&1

echo ✔  System Telemetry removed successfully.
timeout 2 > nul

:: Windows Services.
cls
color D
chcp 65001 >nul 2>&1
echo ╔════════════════════════════════════╗
echo ║ ✅ Disabling Unnecessary Services. ║
echo ╚════════════════════════════════════╝
timeout 1 > nul

:: Creating Services Backup Folder.
mkdir "%Oneclick_Backup_Folder%\Services" >nul 2>&1

:: Creating Services Reg Backup.
reg export "HKLM\System\CurrentControlSet\Services" "%Oneclick_Backup_Folder%\Services\Services.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Services Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] Services Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Windows Services.
sc config AarSvc start=disabled
sc config ADPSvc start=disabled >nul 2>&1  
sc config AJRouter start=disabled >nul 2>&1
sc config ALG start=disabled
sc config AppMgmt start=disabled >nul 2>&1
sc config AppInfo start=disabled
sc config AppReadiness start=disabled
sc config AssignedAccessManagerSvc start=disabled >nul 2>&1
sc config autotimesvc start=disabled
sc config AxInstSV start=disabled
sc config BcastDVRUserService start=disabled
sc config BDESVC start=disabled
sc config BITS start=disabled 
sc config BluetoothUserService start=disabled 
sc config BTAGService start=disabled
sc config BthAvctpSvc start=disabled
sc config bthserv start=disabled 
sc config CaptureService start=disabled
sc config cbdhsvc start=disabled
sc config CDPUserSvc start=disabled
sc config CDPSvc start=disabled
sc config CertPropSvc start=disabled
sc config CloudBackupRestoreSvc start=disabled >nul 2>&1
sc config cloudidsvc start=demand >nul 2>&1 
sc config COMSysApp start=disabled
sc config ConsentUxUserSvc start=disabled
sc config CscService start=disabled >nul 2>&1
sc config dcsvc start=disabled
sc config defragsvc start=demand 
sc config DeviceAssociationService start=disabled
sc config DeviceInstall start=disabled
sc config DevicePickerUserSvc start=disabled
sc config DevicesFlowUserSvc start=disabled
sc config DevQueryBroker start=disabled
sc config diagnosticshub.standardcollector.service start=disabled >nul 2>&1
sc config DiagTrack start=disabled
sc config diagsvc start=disabled
sc config DispBrokerDesktopSvc start=auto
sc config DisplayEnhancementService start=disabled
sc config DmEnrollmentSvc start=disabled
sc config dmwappushservice start=disabled  
sc config dot3svc start=disabled
sc config DPS start=disabled  
sc config DsmSvc start=disabled
sc config DsSvc start=disabled 
sc config DusmSvc start=disabled  
sc config Eaphost start=disabled
sc config edgeupdate start=disabled
sc config edgeupdatem start=disabled
sc config EFS start=disabled
sc config EventLog start=disabled
sc config EventSystem start=demand
sc config fdPHost start=disabled 
sc config FDResPub start=disabled 
sc config fhsvc start=disabled 
sc config FontCache start=disabled 
sc config FrameServer start=disabled
sc config FrameServerMonitor start=disabled 
sc config GameInputSvc start=disabled >nul 2>&1
sc config GraphicsPerfSvc start=disabled
sc config hpatchmon start=disabled >nul 2>&1
sc config hidserv start=disabled
sc config HvHost start=disabled
sc config icssvc start=disabled 
sc config IKEEXT start=disabled 
sc config InstallService start=disabled  
sc config InventorySvc start=disabled
sc config IpxlatCfgSvc start=disabled
sc config KtmRm start=disabled
sc config LanmanServer start=disabled
sc config LanmanWorkstation start=disabled
sc config lfsvc start=disabled
sc config LocalKdc start=disabled >nul 2>&1
sc config LicenseManager start=disabled 
sc config lltdsvc start=disabled 
sc config lmhosts start=disabled 
sc config LxpSvc start=disabled  
sc config MapsBroker start=disabled  
sc config McpManagementService start=disabled >nul 2>&1 
sc config McmSvc start=disabled >nul 2>&1 
sc config MessagingService start=disabled  
sc config midisrv start=disabled >nul 2>&1  
sc config MSDTC start=disabled
sc config MSiSCSI start=disabled
sc config NaturalAuthentication start=disabled
sc config NcaSvc start=disabled
sc config NcbService start=disabled
sc config NcdAutoSetup start=disabled
sc config Netlogon start=disabled
sc config Netman start=disabled
sc config NetSetupSvc start=disabled
sc config NetTcpPortSharing start=disabled 
sc config NlaSvc start=disabled 
sc config NPSMSvc start=disabled >nul 2>&1 
sc config OneSyncSvc start=disabled 
sc config p2pimsvc start=disabled >nul 2>&1
sc config p2psvc start=disabled >nul 2>&1
sc config P9RdrService start=disabled
sc config PcaSvc start=disabled 
sc config PeerDistSvc start=disabled >nul 2>&1
sc config PenService start=disabled    
sc config perceptionsimulation start=disabled 
sc config PerfHost start=disabled
sc config PhoneSvc start=disabled
sc config PimIndexMaintenanceSvc start=disabled
sc config pla start=disabled 
sc config PNRPAutoReg start=disabled >nul 2>&1
sc config PNRPsvc start=disabled >nul 2>&1
sc config PolicyAgent start=disabled
sc config PrintDeviceConfigurationService start=disabled >nul 2>&1
sc config PrintNotify start=disabled 
sc config PrintScanBrokerService start=disabled >nul 2>&1 
sc config PushToInstall start=disabled
sc config QWAVE start=disabled
sc config RasAuto start=disabled
sc config RasMan start=disabled
sc config refsdedupsvc start=disabled >nul 2>&1 
sc config RemoteAccess start=disabled 
sc config RemoteRegistry start=disabled 
sc config RetailDemo start=disabled 
sc config RmSvc start=disabled    
sc config RpcLocator start=disabled   
sc config SamSs start=disabled
sc config SCardSvr start=disabled
sc config ScDeviceEnum start=disabled     
sc config SCPolicySvc start=disabled
sc config SDRSVC start=disabled
sc config seclogon start=disabled  
sc config SENS start=disabled
sc config Sense start=disabled >nul 2>&1
sc config SensorDataService start=disabled
sc config SensorService start=disabled
sc config SensrSvc start=disabled
sc config SEMgrSvc start=disabled
sc config SessionEnv start=disabled
sc config SharedAccess start=disabled  
sc config SharedRealitySvc start=disabled >nul 2>&1
sc config ShellHWDetection start=disabled 
sc config shpamsvc start=disabled
sc config SmsRouter start=disabled
sc config smphost start=disabled
sc config SNMPTrap start=disabled
sc config Spooler start=disabled
sc config SSDPSRV start=disabled
sc config ssh-agent start=disabled
sc config SstpSvc start=disabled 
sc config stisvc start=disabled
sc config StorSvc start=disabled 
sc config svsvc start=disabled
sc config SysMain start=disabled
sc config TapiSrv start=disabled
sc config TermService start=disabled
sc config Themes start=disabled
sc config TieringEngineService start=disabled 
sc config TokenBroker start=disabled
sc config TrkWks start=disabled 
sc config TroubleshootingSvc start=disabled
sc config tzautoupdate start=disabled
sc config UevAgentService start=disabled >nul 2>&1   
sc config uhssvc start=disabled >nul 2>&1  
sc config UmRdpService start=disabled 
sc config UnistoreSvc start=disabled
sc config upnphost start=disabled
sc config UserDataSvc start=disabled
sc config VacSvc start=demand >nul 2>&1
sc config VaultSvc start=disabled
sc config vds start=disabled
sc config vmicguestinterface start=disabled 
sc config vmicheartbeat start=disabled
sc config vmickvpexchange start=disabled 
sc config vmicrdv start=disabled
sc config vmicshutdown start=disabled
sc config vmictimesync start=disabled
sc config vmicvmsession start=disabled
sc config vmicvss start=disabled 
sc config W32Time start=disabled  
sc config WalletService start=disabled
sc config WarpJITSvc start=disabled
sc config wbengine start=disabled
sc config WbioSrvc start=disabled
sc config Wcmsvc start=disabled
sc config wcncsvc start=disabled  
sc config WdiServiceHost start=disabled
sc config WdiSystemHost start=disabled
sc config WebClient start=disabled
sc config webthreatdefusersvc start=disabled
sc config webthreatdefsvc start=disabled
sc config Wecsvc start=disabled 
sc config WEPHOSTSVC start=disabled
sc config wercplsupport start=disabled
sc config WerSvc start=disabled
sc config WFDSConMgrSvc start=disabled 
sc config whesvc start=disabled >nul 2>&1
sc config WiaRpc start=disabled 
sc config WinRM start=disabled
sc config wisvc start=disabled 
sc config WlanSvc start=disabled
sc config wlidsvc start=disabled
sc config wlpasvc start=disabled
sc config WManSvc start=disabled  
sc config wmiApSrv start=disabled
sc config WMPNetworkSvc start=disabled
sc config workfolderssvc start=disabled
sc config WpcMonSvc start=disabled
sc config WPDBusEnum start=disabled
sc config WpnUserService start=disabled
sc config WpnService start=disabled
sc config wuqisvc start=disabled >nul 2>&1
sc config WSAIFabricSvc start=disabled >nul 2>&1
sc config WSearch start=disabled
sc config WwanSvc start=disabled  
sc config XblAuthManager start=disabled
sc config XblGameSave start=disabled
sc config XboxGipSvc start=disabled
sc config XboxNetApiSvc start=disabled

:: Windows Services Regs.
reg add "HKLM\System\CurrentControlSet\Services\AppIDSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\AppXSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\ClipSVC" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\CredentialEnrollmentManagerUserSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\DeviceAssociationBrokerSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\DoSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\EntAppSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\embeddedmode" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\PrintWorkflowUserSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\SgrmBroker" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\TimeBrokerSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "4" /f

:: Intel Services. 
sc config jhi_service start=disabled >nul 2>&1
sc config WMIRegistrationService start=disabled >nul 2>&1
sc config ipfsvc start=disabled >nul 2>&1
sc config igccservice start=disabled >nul 2>&1
sc config cplspcon start=disabled >nul 2>&1
sc config esifsvc start=disabled >nul 2>&1
sc config LMS start=disabled >nul 2>&1
sc config ibtsiva start=disabled >nul 2>&1
sc config cphs start=disabled >nul 2>&1
sc config DSAService start=disabled >nul 2>&1
sc config DSAUpdateService start=disabled >nul 2>&1
sc config RstMwService start=disabled >nul 2>&1
sc config SystemUsageReportSvc_QUEENCREEK start=disabled >nul 2>&1
sc config iaStorAfsService start=disabled >nul 2>&1

:: Intel igfxCUIService. (Mostly deprecated, but can still exist from driver packages)
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%S in ('sc query state^= all ^| findstr /i "SERVICE_NAME" ^| findstr /i "igfxCUIService"') do (
    set "Svc=%%S"
    set "Svc=!Svc:~1!"
    sc config "!Svc!" start=disabled >nul 2>&1
    echo "!Svc!" >> "C:\Oneclick Logs\Extra\Additional Services Detection.txt"
)
endlocal

:: Check for Additional Intel Services.
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%S in ('sc query state^= all ^| findstr /i "SERVICE_NAME" ^| findstr /i "Intel"') do (
    set "Svc=%%S"
    set "Svc=!Svc:~1!"
    sc config "!Svc!" start=disabled >nul 2>&1
    echo "!Svc!" >> "C:\Oneclick Logs\Extra\Additional Services Detection.txt"
)
endlocal

:: AMD User Experience Program Launcher.
reg query "HKLM\System\CurrentControlSet\Services\AUEPLauncher" >nul 2>&1
if %errorlevel%==0 (
    reg add "HKLM\System\CurrentControlSet\Services\AUEPLauncher" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
)

:: Check for Additional AMD Services.
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%S in ('sc query state^= all ^| findstr /i "SERVICE_NAME" ^| findstr /i "AMD"') do (
    set "Svc=%%S"
    set "Svc=!Svc:~1!"
    reg add "HKLM\System\CurrentControlSet\Services\!Svc!" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    echo "!Svc!" >> "C:\Oneclick Logs\Extra\Additional Services Detection.txt"
)
endlocal

:: Nvidia Services. (Breaks Nvidia Control Panel, Nvidia App, Clipping and Overlays)
sc config NVDisplay.ContainerLocalSystem start=disabled >nul 2>&1
sc config NvContainerLocalSystem start=disabled >nul 2>&1
sc config FvSVC start=disabled >nul 2>&1

:: Check for HP Services.
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%S in ('sc query state^= all ^| findstr /i "SERVICE_NAME" ^| findstr /i "HP"') do (
    set "Svc=%%S"
    set "Svc=!Svc:~1!"
    echo !Svc! | findstr /i "hpatchmon shpamsvc" >nul || (
        sc config "!Svc!" start=disabled >nul 2>&1
        echo "!Svc!" >> "C:\Oneclick Logs\Extra\Additional Services Detection.txt"
    )
)
endlocal

:: Razor Services.
sc config RzActionSvc start=disabled >nul 2>&1
sc config CortexLauncherService start=disabled >nul 2>&1
sc config HapticService start=disabled >nul 2>&1

:: Check for Additional Razor Services.
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%S in ('sc query state^= all ^| findstr /i "SERVICE_NAME" ^| findstr /i "Razer"') do (
    set "Svc=%%S"
    set "Svc=!Svc:~1!"
    sc config "!Svc!" start=disabled >nul 2>&1
    echo "!Svc!" >> "C:\Oneclick Logs\Extra\Additional Services Detection.txt"
)
endlocal

:: Logitech Services.
sc config logi_lamparray_service start=disabled >nul 2>&1
sc config LGHUBUpdaterService start=disabled >nul 2>&1

:: Split SvcHost. (Effectively disables process splitting by using the maximum possible DWORD value)
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "4294967295" /f >nul 2>&1

echo ✔  Services disabled successfully.
timeout 2 > nul

:: Windows Drivers.  
cls
color 9
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════════╗
echo ║ ✅ Disabling Unnecessary Drivers. ║
echo ╚═══════════════════════════════════╝
timeout 1 > nul

:: Unnecessary Drivers.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\1394ohci" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AcpiDev" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\acpipagr" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AcpiPmi" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\acpitime" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\amdsata" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\amdsbs" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\amdxata" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AppvVemgr" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\arcsas" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\atapi" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\b06bdrv" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\bam" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\beep" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\bowser" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BthA2dp" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BthEnum" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BthHFEnum" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BthLEEnum" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BthMini" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BTHMODEM" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BTHPORT" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BTHUSB" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\bttflt" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\cdfs" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\cdrom" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\cht4tiscsi" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\cht4vbd" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\circlass" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\CSC" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\dam" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\ebdrv" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\fdc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\flpydisk" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\gencounter" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\HidBth" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\HidIr" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hvcrash" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hvservice" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hyperkbd" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\HyperVideo" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\ItSas35i" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\MEIx64" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Microsoft_Bluetooth_AvrcpTransport" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NdisCap" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NdisVirtualBus" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\rdpbus" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\RFCOMM" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\scfilter" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\sfloppy" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SgrmAgent" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SpatialGraphFilter" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Synth3dVsc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TsUsbFlt" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TsUsbGD" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\tsusbhub" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\udfs" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UevAgentDriver" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\umbus" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\usbcir" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\usbprint" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Vid" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\vmgid" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\vwifibus" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\vwifimp" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WacomPen" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wanarp" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wanarpv6" /v "Start" /t REG_DWORD /d "4" /f

echo ✔  Drivers disabled successfully.
timeout 2 > nul

:: Graphics Preferences, Priority and FSO.
cls
color D
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════════════════════════════╗
echo ║ ✅ Auto Setting Graphics Preferences, Priority and FSO. ║
echo ╚═════════════════════════════════════════════════════════╝
setlocal enabledelayedexpansion

:: Roblox and Discord paths.
set "ProgramFilesRobloxPath="
set "AppDataRobloxPath="
set "LatestDiscordPath="

:: Program Files Roblox Path.
for /f "delims=" %%R in ('dir "C:\Program Files (x86)\Roblox\Versions\version-*" /ad /b /o:-d 2^>nul') do (
    set "ProgramFilesRobloxPath=C:\Program Files (x86)\Roblox\Versions\%%R\RobloxPlayerBeta.exe"
    goto :End1
)
:End1

:: AppData Roblox Path.
for /f "delims=" %%R in ('dir "%USERPROFILE%\AppData\Local\Roblox\Versions\version-*" /ad /b /o:-d 2^>nul') do (
    set "AppDataRobloxPath=%USERPROFILE%\AppData\Local\Roblox\Versions\%%R\RobloxPlayerBeta.exe"
    goto :End2
)
:End2

:: Discord Path.
for /f "delims=" %%D in ('dir "%USERPROFILE%\AppData\Local\Discord\app-*" /ad /b /o:-d 2^>nul') do (
    set "LatestDiscordPath=%USERPROFILE%\AppData\Local\Discord\%%D\Discord.exe"
    goto :End3
)
:End3

:: Games Paths.
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

:: Apps Paths.
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

:: Other Paths. (Applies Only High Priority)
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

:: Registry Keys.
set regKeyGP=HKCU\SOFTWARE\Microsoft\DirectX\UserGpuPreferences
set regKeyPR=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options
set regKeyFO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers

:: Creating Priority Backup Folder.
mkdir "%Oneclick_Backup_Folder%\Priority" >nul 2>&1

:: Creating Graphics Preferences Reg Backup.
reg add "%regKeyGP%" /f >nul 2>&1
reg export "%regKeyGP%" "%Oneclick_Backup_Folder%\Priority\GraphicsPreferences.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Graphics Preferences Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] Graphics Preferences Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Creating Priority Reg Backup.
reg export "%regKeyPR%" "%Oneclick_Backup_Folder%\Priority\Priority.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Priority Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] Priority Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Creating FSO Reg Backup.
reg export "%regKeyFO%" "%Oneclick_Backup_Folder%\Priority\FSO.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] FSO Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] FSO Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Set Games to High Performance and High Priority.
for /L %%i in (0, 1, 48) do (
    set "currentPath=!games[%%i]!"
    if defined currentPath if exist "!currentPath!" (
        for %%a in ("!currentPath!") do set "exeName=%%~nxa"
        echo [%DATE% %TIME%] GP-Priority-FSO: Adding !exeName!: to High Performance Mode, High Priority and FSO. >> "C:\Oneclick Logs\Extra\GP-Priority-FSO.txt"
        echo ✔  Adding !exeName! to High Performance Mode, High Priority and FSO.
        reg add "%regKeyGP%" /v "!currentPath!" /t REG_SZ /d "GpuPreference=2" /f >nul 2>&1
        reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f >nul 2>&1
        reg add "%regKeyFO%" /v "!currentPath!" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" /f >nul 2>&1
    )
)

:: Set Apps to Power Saving and Low Priority.
for /L %%i in (0, 1, 16) do (
    set "currentPath=!apps[%%i]!"
    if defined currentPath if exist "!currentPath!" (
        for %%a in ("!currentPath!") do set "exeName=%%~nxa"
        echo [%DATE% %TIME%] GP-Priority-FSO: Adding !exeName!: to Power Saving Mode and Low Priority. >> "C:\Oneclick Logs\Extra\GP-Priority-FSO.txt"
        echo ✔  Adding !exeName! to Power Saving Mode and Low Priority.
        reg add "%regKeyGP%" /v "!currentPath!" /t REG_SZ /d "GpuPreference=1" /f >nul 2>&1
        reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "1" /f >nul 2>&1 
    )
)

:: Set Other Paths to High Priority.
for /L %%i in (0, 1, 19) do (
    set "exeName=!other[%%i]!"
    echo [%DATE% %TIME%] GP-Priority-FSO: Adding !exeName!: to High Priority. >> "C:\Oneclick Logs\Extra\GP-Priority-FSO.txt"
    reg add "%regKeyPR%\!exeName!\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f >nul 2>&1
)
endlocal

echo ✔  Graphics Preferences, Priority and FSO applied successfully.
timeout 2 > nul

:: Microsoft Apps. 
cls
color 9
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════╗
echo ║ ✅ Removing Microsoft Apps. ║
echo ╚═════════════════════════════╝
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

echo ✔  Microsoft Apps removed successfully.
timeout 2 > nul

:: Startup Apps.
cls
color D
chcp 65001 >nul 2>&1
echo ╔════════════════════════════╗
echo ║ ✅ Disabling Startup Apps. ║
echo ╚════════════════════════════╝
setlocal enabledelayedexpansion

:: HKCU Run.
for /f "skip=2 tokens=1*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul') do (
    if not "%%A"=="(Default)" (
        echo [%DATE% %TIME%] Startup Apps: Disabling %%A. >> "C:\Oneclick Logs\Extra\Startup Apps Log.txt"
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "%%A" /t REG_BINARY /d 0300000000000000 /f >nul
        echo • Disabling %%A.
    )
)

:: HKLM Run.
for /f "skip=2 tokens=1*" %%A in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul') do (
    if not "%%A"=="(Default)" (
        echo [%DATE% %TIME%] Startup Apps: Disabling %%A. >> "C:\Oneclick Logs\Extra\Startup Apps Log.txt"
        reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "%%A" /t REG_BINARY /d 0300000000000000 /f >nul
        echo • Disabling %%A.
    )
)

:: Appdata Startup Folder.
for %%F in ("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*") do (
    echo [%DATE% %TIME%] Startup Apps: Disabling %%~nxF. >> "C:\Oneclick Logs\Extra\Startup Apps Log.txt"
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" /v "%%~nxF" /t REG_BINARY /d 0300000000000000 /f >nul
    echo • Disabling %%~nxF.
)

:: ProgramData Startup Folder.
for %%F in ("%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\*") do (
    echo [%DATE% %TIME%] Startup Apps: Disabling %%~nxF. >> "C:\Oneclick Logs\Extra\Startup Apps Log.txt"
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" /v "%%~nxF" /t REG_BINARY /d 0300000000000000 /f >nul
    echo • Disabling %%~nxF.
)
endlocal

echo ✔  Startup Apps disabled successfully.
timeout 2 > nul

:: Microsoft Edge
cls
color 9
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════╗
echo ║ ✅ Removing Microsoft Edge. ║
echo ╚═════════════════════════════╝

echo • Removing Edge with Setup File.
"C:\Oneclick Tools\Edge Remover\setup.exe" --uninstall --system-level --force-uninstall >nul 2>&1

echo • Stopping Edge Processes.
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
taskkill /f /im msedge.exe /fi "IMAGENAME eq msedge.exe" >nul 2>&1

echo • Deleting Edge Directories.
rd /s /q "C:\Program Files (x86)\Microsoft\Edge" >nul 2>&1
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeCore" >nul 2>&1
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeUpdate" >nul 2>&1
rd /s /q "C:\Program Files (x86)\Microsoft\Temp" >nul 2>&1

echo • Deleting Edge Shortcuts.
del %Appdata%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk >nul 2>&1
del %ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk >nul 2>&1
del %AppData%\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk >nul 2>&1
del "C:\Users\Public\Desktop\Microsoft Edge.lnk" >nul 2>&1

echo • Deleting Edge Uninstall String.
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f >nul 2>&1

echo • Deleting Edge Dev Tools.
takeown /f "C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient_8wekyb3d8bbwe" /r /d y >nul 2>&1
icacls "C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient_8wekyb3d8bbwe" /grant Administrators:F /t >nul 2>&1
rd /s /q "C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient_8wekyb3d8bbwe" >nul 2>&1

echo • Deleting Edge from startup.
setlocal enabledelayedexpansion
set "RunKey=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
for /f "tokens=1" %%V in ('reg query "%RunKey%" ^| findstr /I "MicrosoftEdge" ^| findstr /V "HKEY_"') do (
    echo Deleting: %%V >nul 2>&1
    reg delete "%RunKey%" /v "%%V" /f >nul 2>&1
)
endlocal

echo • Deleting Edge Services.
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%S in ('sc query state^= all ^| findstr /i "SERVICE_NAME" ^| findstr /i "Edge"') do (
    set "Svc=%%S"
    set "Svc=!Svc:~1!"
    net stop "!Svc!" >nul 2>&1
    sc config "!Svc!" start=disabled >nul 2>&1
    sc delete "!Svc!" >nul 2>&1
)
endlocal

echo ✔  Microsoft Edge deleted successfully.
timeout 2 > nul

:: Microsoft OneDrive
cls
color D
chcp 65001 >nul 2>&1
echo ╔═══════════════════════╗
echo ║ ✅ Removing OneDrive. ║
echo ╚═══════════════════════╝

echo • Stopping Explorer.
taskkill.exe /F /IM "explorer.exe" >nul 2>&1

echo • Stopping OneDrive.
taskkill.exe /F /IM "OneDrive.exe" >nul 2>&1

echo • Removing OneDrive.
winget uninstall --silent --accept-source-agreements Microsoft.OneDrive >nul 2>&1

echo • Removing OneDrive Shortcuts.
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
reg load "hku\Default" "C:\Users\Default\NTUSER.DAT" >nul 2>&1
reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f >nul 2>&1
reg unload "hku\Default" >nul 2>&1
del /f /q "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" >nul 2>&1

echo • Restarting Explorer.
start explorer.exe >nul 2>&1

echo ✔  OneDrive deleted successfully.
timeout 2 > nul

:: LockApp.
cls
color 9
chcp 65001 >nul 2>&1
echo ╔══════════════════════╗
echo ║ ✅ Removing LockApp. ║
echo ╚══════════════════════╝
setlocal

:: LockApp Path & Other Variables.
set "LockAppItem=C:\Windows\SystemApps\Microsoft.LockApp_cw5n1h2txyewy\LockApp.exe"
set "LockAppFound=0"

:: Creating LockApp Backup Folder.
mkdir "%Oneclick_Backup_Folder%\LockApp" >nul 2>&1

:: LockApp Copy & Delete.
if exist "%LockAppItem%" (
    set "LockAppFound=1"
    echo • Removing "%LockAppItem%"
    takeown /F "%LockAppItem%" >nul 2>&1
    icacls "%LockAppItem%" /grant administrators:F >nul 2>&1
    copy /Y "%LockAppItem%" "%Oneclick_Backup_Folder%\LockApp" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo [%DATE% %TIME%] Lockapp Removal Backup: Successfully copied - "%LockAppItem%" >> "C:\Oneclick Logs\Oneclick Log.txt"
    ) else (
        echo [%DATE% %TIME%] Lockapp Removal Backup: Failed to copy - "%LockAppItem%" >> "C:\Oneclick Logs\Oneclick Log.txt"
    )
    del "%LockAppItem%" /s /f /q >nul 2>&1
    if not exist "%LockAppItem%" (
        echo [%DATE% %TIME%] Lockapp Removal: Successfully deleted - "LockApp.exe" >> "C:\Oneclick Logs\Oneclick Log.txt"
    ) else (
        echo [%DATE% %TIME%] Lockapp Removal: Failed to delete - "LockApp.exe" >> "C:\Oneclick Logs\Oneclick Log.txt"
    )  
) else (
    echo [%DATE% %TIME%] LockApp Removal: File not found - "%LockAppItem%" >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo • File not found: "%LockAppItem%"
)

:: LockApp Output Echo.
if "%LockAppFound%"=="0" (
    echo ❌ No LockApp file was found.
) else (
    echo ✔  LockApp was deleted successfully.
)

endlocal
timeout 2 > nul

:: Smartscreen.
cls
color D
chcp 65001 >nul 2>&1
echo ╔══════════════════════════╗
echo ║ ✅ Removing Smartscreen. ║
echo ╚══════════════════════════╝
setlocal enabledelayedexpansion

:: Smartscreen Paths & Other Variables.
set "SmartscreenItem1=C:\Windows\System32\smartscreen.exe"
set "SmartscreenItem2=C:\Windows\SystemApps\Microsoft.Windows.AppRep.ChxApp_cw5n1h2txyewy\CHXSmartScreen.exe"
set "SmartscreenItemFound=0"
set "NotFoundCount=0"
set "BackupCount=0"
set "DeleteCount=0"

:: Creating Smartscreen Backup Folder.
mkdir "%Oneclick_Backup_Folder%\Smartscreen" >nul 2>&1

:: Smartscreen Copy & Delete.
for %%S in ("%SmartscreenItem1%" "%SmartscreenItem2%") do (
    if exist "%%~S" (
       set /A "SmartscreenItemFound+=1"
       set /A "BackupCount+=1"
       set /A "DeleteCount+=1"
       echo • Removing "%%~S"  
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       copy /Y "%%~S" "%Oneclick_Backup_Folder%\Smartscreen" >nul 2>&1
       if !ERRORLEVEL! equ 0 (
           echo [%DATE% %TIME%] Smartscreen Removal Backup !BackupCount!: Successfully copied - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
       ) else (
           echo [%DATE% %TIME%] Smartscreen Removal Backup !BackupCount!: Failed to copy - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
       )
       del "%%~S" /s /f /q >nul 2>&1
       if not exist "%%~S" (
           echo [%DATE% %TIME%] Smartscreen Removal !DeleteCount!: Successfully deleted - "%%~nxS" >> "C:\Oneclick Logs\Oneclick Log.txt"
       ) else (
           echo [%DATE% %TIME%] Smartscreen Removal !DeleteCount!: Failed to delete - "%%~nxS" >> "C:\Oneclick Logs\Oneclick Log.txt"
       )  
    ) else (   
        set /A "NotFoundCount+=1"
        echo [%DATE% %TIME%] Smartscreen Removal !NotFoundCount!: File not found - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
        echo • File not found: "%%~S"
    )
)

:: Smartscreen Output Echo.
if "%SmartscreenItemFound%"=="0" (
    echo ❌ No Smartscreen files were found.
) else if "%SmartscreenItemFound%"=="1" ( 
   echo ⚠️ 1 Smartscreen file was found and deleted.
) else (
    echo ✔  %SmartscreenItemFound% Smartscreen files deleted successfully.
)

endlocal
timeout 2 > nul

:: Sync Programs.
cls
color 9
chcp 65001 >nul 2>&1
echo ╔════════════════════════════╗
echo ║ ✅ Removing Sync Programs. ║
echo ╚════════════════════════════╝
setlocal enabledelayedexpansion

:: Sync Programs Paths & Other Variables.
set "SyncItem1=C:\Windows\System32\mobsync.exe"
set "SyncItem2=C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\CrossDeviceResume.exe"
set "SyncItemFound=0"
set "NotFoundCount=0"
set "BackupCount=0"
set "DeleteCount=0"

:: Creating Sync Programs Backup Folder.
mkdir "%Oneclick_Backup_Folder%\Sync Programs" >nul 2>&1

:: Sync Programs Copy & Delete.
for %%S in ("%SyncItem1%" "%SyncItem2%") do (
    if exist "%%~S" (
       set /A "SyncItemFound+=1"
       set /A "BackupCount+=1"
       set /A "DeleteCount+=1"
       echo • Removing "%%~S"  
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       copy /Y "%%~S" "%Oneclick_Backup_Folder%\Sync Programs" >nul 2>&1
       if !ERRORLEVEL! equ 0 (
           echo [%DATE% %TIME%] Sync Programs Removal Backup !BackupCount!: Successfully copied - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
       ) else (
           echo [%DATE% %TIME%] Sync Programs Removal Backup !BackupCount!: Failed to copy - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
       )
       del "%%~S" /s /f /q >nul 2>&1
       if not exist "%%~S" (
           echo [%DATE% %TIME%] Sync Programs Removal !DeleteCount!: Successfully deleted - "%%~nxS" >> "C:\Oneclick Logs\Oneclick Log.txt"
       ) else (
           echo [%DATE% %TIME%] Sync Programs Removal !DeleteCount!: Failed to delete - "%%~nxS" >> "C:\Oneclick Logs\Oneclick Log.txt"
       )  
    ) else (   
        set /A "NotFoundCount+=1"
        echo [%DATE% %TIME%] Sync Programs Removal !NotFoundCount!: File not found - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
        echo • File not found: "%%~S"
    )
)

:: Sync Programs Output Echo.
if "%SyncItemFound%"=="0" (
    echo ❌ No Sync Programs were found.
) else if "%SyncItemFound%"=="1" ( 
   echo ⚠️ 1 Sync Program was found and deleted.
) else (
    echo ✔  %SyncItemFound% Sync Programs deleted successfully.
)

endlocal
timeout 2 > nul

:: Xbox Bloat.
cls
color D
chcp 65001 >nul 2>&1
echo ╔═════════════════════════╗
echo ║ ✅ Removing Xbox Bloat. ║
echo ╚═════════════════════════╝
setlocal enabledelayedexpansion

:: Xbox Bloat Paths & Other Variables.
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

:: Creating Xbox Bloat Backup Folder.
mkdir "%Oneclick_Backup_Folder%\Xbox Bloat" >nul 2>&1

:: Xbox Bloat Copy & Delete.
for /L %%i in (1,1,22) do (
    set "XboxfileToDelete=%XboxPath%\!XboxItem%%i!"
    if exist "!XboxfileToDelete!" (
        set /A "CopyAttemptCount+=1"
        set /A "XboxItemFound+=1"
        set /A "BackupCount+=1"
        set /A "DeleteCount+=1"
        echo • Removing: "!XboxfileToDelete!"
        takeown /F "!XboxfileToDelete!" >nul 2>&1
        icacls "!XboxfileToDelete!" /grant administrators:F >nul 2>&1
        copy /Y "!XboxfileToDelete!" "%Oneclick_Backup_Folder%\Xbox Bloat" >nul 2>&1
        if %ERRORLEVEL% equ 0 (
            set /A "CopySuccessCount+=1"
            echo [%DATE% %TIME%] Xbox Bloat Removal Backup !BackupCount!: Successfully copied - "!XboxfileToDelete!" >> "C:\Oneclick Logs\Extra\Xbox Bloat Log.txt"
        ) else (
            echo [%DATE% %TIME%] Xbox Bloat Removal Backup !BackupCount!: Failed to copy - "!XboxfileToDelete!" >> "C:\Oneclick Logs\Extra\Xbox Bloat Log.txt"
        ) 
        del "!XboxfileToDelete!" /s /f /q >nul 2>&1
        if not exist "!XboxfileToDelete!" (
            echo [%DATE% %TIME%] Xbox Bloat Removal !DeleteCount!: Successfully deleted - "!XboxfileToDelete!" >> "C:\Oneclick Logs\Extra\Xbox Bloat Log.txt"
        ) else (
            echo [%DATE% %TIME%] Xbox Bloat Removal !DeleteCount!: Failed to delete - "!XboxfileToDelete!" >> "C:\Oneclick Logs\Extra\Xbox Bloat Log.txt"
        )  
    ) else (
        echo • File not found: "!XboxfileToDelete!"
    )
)

:: Xbox Bloat Oneclick Log.
if "!XboxItemFound!" NEQ "0" (
    if "!CopyAttemptCount!"=="!CopySuccessCount!" (
        echo [%DATE% %TIME%] Xbox Bloat Removal Backup: All files copied successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
    ) else (
        echo [%DATE% %TIME%] Xbox Bloat Removal Backup: Some files failed to copy. >> "C:\Oneclick Logs\Oneclick Log.txt"
    )
)

:: Xbox Bloat Output Echo.
if "%XboxItemFound%"=="0" (
    echo [%DATE% %TIME%] Xbox Bloat Removal: No Xbox Bloat files were found. >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo ❌ No Xbox Bloat files were found.
) else (
    echo [%DATE% %TIME%] Xbox Bloat Removal: All files deleted successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo ✔  %XboxItemFound% Xbox Bloat files deleted successfully.
)

endlocal
timeout 2 > nul

:: Search Removal Options.
:Search_Removal_Options
cls
color 9
chcp 65001 >nul 2>&1
echo ╔════════════════════════════╗
echo ║ ✅ Search Removal Options. ║
echo ╚════════════════════════════╝
echo.
chcp 437 >nul
echo %White%[Choose an option]
echo %Green%1. Keep Search - *Allows the user to keep the basic windows search*
echo %DarkYellow%2. Remove Search - *Removes Search, installing a lighter alternative*
echo %Cyan%3. More Info - *Explains Search Options*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] Search Removal Options: User Chose "Option 1" - Keep Search. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔════════════════════╗
    echo ║ ✅ Keeping Search. ║
    echo ╚════════════════════╝
    echo • Continuing in 2 seconds!
    timeout 2 > nul
    goto :GPU_Tweaks
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Search Removal Options: User Chose "Option 2" - Remove Search. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═════════════════════╗
    echo ║ ⚠️ Removing Search. ║
    echo ╚═════════════════════╝
    echo • Now removing search.
    timeout 2 > nul
    goto :Search_Removal
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Search Removal Options: User Chose "Option 3" - More Info. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Github Page. ║
    echo ╚═════════════════════════╝
    echo • Launching the Github page in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Search%%20Removal%%20Options.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Search_Removal_Options
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Search_Removal_Options
)

:: Removing Search.
:Search_Removal
setlocal
cls
color A
chcp 65001 >nul 2>&1
echo ╔═════════════════════╗
echo ║ ✅ Removing Search. ║
echo ╚═════════════════════╝
setlocal enabledelayedexpansion

:: Rest of Edge Removal. (Newer Windows versions rely on WebView2 for Search, so if you remove Search than WebView2 can also be removed without issue)
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeWebView" >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView" /f >nul 2>&1

:: Search Service.
reg add "HKLM\System\CurrentControlSet\Services\UdkUserSvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1

:: Search Paths & Other Variables.
set "SearchItem1=C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\SearchHost.exe"
set "SearchItem2=C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe"
set "SearchItem3=C:\Windows\SystemApps\ShellExperienceHost_cw5n1h2txyewy\ShellExperienceHost.exe"
set "SearchItem4=C:\Windows\System32\taskhostw.exe"
set "SearchItemFound=0"
set "NotFoundCount=0"
set "BackupCount=0"
set "DeleteCount=0"

:: Creating Search Backup Folder.
mkdir "%Oneclick_Backup_Folder%\Search" >nul 2>&1

:: Smartscreen Copy & Delete.
for %%S in ("%SearchItem1%" "%SearchItem2%" "%SearchItem3%" "%SearchItem4%") do (
    if exist "%%~S" (
       set /A "SearchItemFound+=1"
       set /A "BackupCount+=1"
       set /A "DeleteCount+=1"
       echo • Removing "%%~S"  
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       copy /Y "%%~S" "%Oneclick_Backup_Folder%\Search" >nul 2>&1
       if !ERRORLEVEL! equ 0 (
           echo [%DATE% %TIME%] Search Removal Backup !BackupCount!: Successfully copied - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
       ) else (
           echo [%DATE% %TIME%] Search Removal Backup !BackupCount!: Failed to copy - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
       )
       del "%%~S" /s /f /q >nul 2>&1
       if not exist "%%~S" (
           echo [%DATE% %TIME%] Search Removal !DeleteCount!: Successfully deleted - "%%~nxS" >> "C:\Oneclick Logs\Oneclick Log.txt"
       ) else (
           echo [%DATE% %TIME%] Search Removal !DeleteCount!: Failed to delete - "%%~nxS" >> "C:\Oneclick Logs\Oneclick Log.txt"
       )  
    ) else (
        set /A "NotFoundCount+=1"
        echo [%DATE% %TIME%] Search Removal !NotFoundCount!: File not found - "%%~S" >> "C:\Oneclick Logs\Oneclick Log.txt"
        echo • File not found: "%%~S"
    )
)

:: Search Output Message.
if "%SearchItemFound%"=="0" (
    echo ❌ No Search files were found.
) else if "%SearchItemFound%"=="1" ( 
   echo ⚠️ 1 Search file was found and deleted.
) else (
    echo ✔  %SearchItemFound% Search files deleted successfully.
)

endlocal
timeout 2 > nul

:: Download OpenShell.
:OpenShell_Download
setlocal
cls
color A
chcp 65001 >nul 2>&1
echo ╔══════════════════════════╗
echo ║ ✅ Installing OpenShell. ║
echo ╚══════════════════════════╝
echo • Downloading alternative search.
mkdir "C:\Oneclick Tools\OpenShell" >nul 2>&1
set "FileURL1=https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.196/OpenShellSetup_4_4_196.exe"
set "FileName1=OpenShellSetup_4_4_196.exe"
set "FileURL2=https://github.com/QuakedK/Oneclick/raw/refs/heads/main/Downloads/V8.0/OpenShellTheme.xml"
set "FileName2=OpenShellTheme.xml"
set "DownloadsFolder=C:\Oneclick Tools\OpenShell"
curl -s -L "%FileURL1%" -o "%DownloadsFolder%\%FileName1%"
curl -s -L "%FileURL2%" -o "%DownloadsFolder%\%FileName2%"
if exist "%DownloadsFolder%\%FileName1%" (  
   echo [%DATE% %TIME%] OpenShell: Downloaded successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
   echo.
   echo 1. Openshell downloaded successfully.
   echo 2. Now starting the installer.
   echo.
   start "" "C:\Oneclick Tools\OpenShell\OpenShellSetup_4_4_196.exe" /qn ADDLOCAL=StartMenu
   timeout 2 > nul
   "C:\Program Files\Open-Shell\StartMenu.exe" -xml "C:\Oneclick Tools\OpenShell\OpenShellTheme.xml"
   <nul set /p="→ Press any key to continue . . . "
   pause >nul
   rd /s /q "C:\Oneclick Tools\OpenShell" >nul 2>&1
   goto :GPU_Tweaks
) else (
   echo [%DATE% %TIME%] OpenShell: Download failed. >> "C:\Oneclick Logs\Oneclick Log.txt"
   goto :OpenShell_Download_Failed
)
endlocal

:: OpenShell Download Failed.
:OpenShell_Download_Failed
cls
color C
chcp 65001 >nul 2>&1
echo ╔══════════════════════════════════╗
echo ║ ⚠️ OpenShell failed to download. ║
echo ╚══════════════════════════════════╝
echo → Please ensure you're connected to the internet!
echo.
echo %White%[Choose an option]
echo %Green%1. Retry - *Tries to download OpenShell again*
echo %Cyan%2. Download Manually - *Open''s the Github download page*
echo %Red%3. Continue Anyway - *Allows the user to continue with Oneclick regardless*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] OpenShell Download Options: User Chose "Option 1" - Retry download. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════════════╗
    echo ║ ✅ Retrying OpenShell download. ║
    echo ╚═════════════════════════════════╝
    echo • Attempting download again in 2 seconds!
    timeout 2 > nul
    goto :OpenShell_Download
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] OpenShell Download Options: User Chose "Option 2" - Download manually. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Github Page. ║
    echo ╚═════════════════════════╝
    echo • Launching the Github page in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/Open-Shell/Open-Shell-Menu/releases"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :OpenShell_Download_Failed
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] OpenShell Download Options: User Chose "Option 3" - Continue anyway. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔══════════════════════════════╗
    echo ║ ⚠️ Continuing with Oneclick. ║
    echo ╚══════════════════════════════╝
    echo • Now continuing in 2 seconds!
    timeout 2 > nul
    goto :GPU_Tweaks
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :OpenShell_Download_Failed
)

:: GPU Tweaks.
:GPU_Tweaks
cls
color D
chcp 65001 >nul 2>&1
echo.
echo.
echo.
echo.
echo.
echo.                                                ██████╗ ██████╗ ██╗   ██╗             
echo.                                               ██╔════╝ ██╔══██╗██║   ██║             
echo.                                               ██║  ███╗██████╔╝██║   ██║             
echo.                                               ██║   ██║██╔═══╝ ██║   ██║             
echo.                                               ╚██████╔╝██║     ╚██████╔╝             
echo.                                                ╚═════╝ ╚═╝      ╚═════╝              
echo.                                                   
echo.                                  ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗
echo.                                  ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝
echo.                                     ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ ███████╗
echo.                                     ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ╚════██║
echo.                                     ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████║
echo.                                     ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
echo.
echo.                                  ╔════════════════════════════════════════════════════╗
echo.                                  ║              Please select your GPU.               ║       
echo.                                  ╚════════════════════════════════════════════════════╝
echo.
echo.
echo.
echo %White%[Choose an option]
echo %Green%1. Nvidia
echo %Red%2. AMD
echo %Cyan%3. Skip
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] GPU Tweaks: User Chose "Option 1" - Nvidia GPU. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Nvidia_Control_Panel_Download
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] GPU Tweaks: User Chose "Option 2" - AMD GPU. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :AMD_GPU_Tweaks
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] GPU Tweaks: User Chose "Option 3" - Skip. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Latency_Tweaks    
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :GPU_Tweaks
)

:: Download Nvidia Control Panel.
:Nvidia_Control_Panel_Download
setlocal
cls
color A
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════════╗
echo ║ ✅ Installing Nvidia Control Panel. ║
echo ╚═════════════════════════════════════╝
echo • Required to use Control Panel after Oneclick.
mkdir "C:\Oneclick Tools\Nvidia\Nvidia Control Panel" >nul 2>&1
set "FileURL=https://github.com/QuakedK/Oneclick/raw/refs/heads/main/Downloads/V8.0/nvcplui.exe"
set "FileName=nvcplui.exe"
set "DownloadsFolder=C:\Oneclick Tools\Nvidia\Nvidia Control Panel"
curl -s -L "%FileURL%" -o "%DownloadsFolder%\%FileName%"
if exist "%DownloadsFolder%\%FileName%" (  
   echo [%DATE% %TIME%] Nvidia Control Panel: Downloaded successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"

   :: Adding Nvidia Control Panel to Context Menu.
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel" /v HasLUAShield /t REG_SZ /d "" /f >nul 2>&1
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel" /v MUIVerb /t REG_SZ /d "Nvidia Control Panel" /f >nul 2>&1
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel\command" /ve /t REG_SZ /d "C:\Oneclick Tools\Nvidia\Nvidia Control Panel\nvcplui.exe" /f >nul 2>&1

   :: Removing Old Nvidia Control Panel Context Menu 
   reg add "HKCR\Directory\Background\shellex\ContextMenuHandlers\NvCplDesktopContext" /ve /t REG_SZ /d "{}" /f >nul 2>&1
   echo.
   echo ✔  Nvidia Control Panel downloaded successfully.
   timeout 2 > nul
   goto :Nvidia_GPU_Tweaks
) else (
   echo [%DATE% %TIME%] Nvidia Control Panel: Download failed. >> "C:\Oneclick Logs\Oneclick Log.txt"
   echo.
   echo ❌ Nvidia Control Panel download failed.
   timeout 2 > nul 
   goto :Nvidia_Control_Panel_Download_Failed
)
endlocal

:: Nvidia Control Panel Download Failed.
:Nvidia_Control_Panel_Download_Failed
cls
color C
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════════════════╗
echo ║ ⚠️ Nvidia Control Panel failed to download. ║
echo ╚═════════════════════════════════════════════╝
echo → Please ensure you're connected to the internet!
echo.
echo %White%[Choose an option]
echo %Green%1. Retry - *Tries to download Nvidia Control Panel again*
echo %Cyan%2. Download Manually - *Open''s the Github download page*
echo %Red%3. Continue Anyway - *Allows the user to continue with Oneclick regardless*
set /p option="%White%Enter option number: "
chcp 65001 >nul 2>&1
if "%option%"=="1" (
    echo [%DATE% %TIME%] Nvidia Control Panel Download Options: User Chose "Option 1" - Retry download. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔════════════════════════════════════════════╗
    echo ║ ✅ Retrying Nvidia Control Panel download. ║
    echo ╚════════════════════════════════════════════╝
    echo • Attempting download again in 2 seconds!
    timeout 2 > nul
    goto :Nvidia_Control_Panel_Download
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Nvidia Control Panel Download Options: User Chose "Option 2" - Download manually. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Github Page. ║
    echo ╚═════════════════════════╝
    echo • Launching the Github page in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Downloads/V8.0/nvcplui.exe"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Nvidia_Control_Panel_Download_Failed
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Nvidia Control Panel Download Options: User Chose "Option 3" - Continue anyway. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔══════════════════════════════╗
    echo ║ ⚠️ Continuing with Oneclick. ║
    echo ╚══════════════════════════════╝
    echo • Now continuing in 2 seconds!
    timeout 2 > nul
    goto :Nvidia_GPU_Tweaks
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Nvidia_Control_Panel_Download_Failed
)

:: Nvidia GPU Tweaks. (Full Credit to p467121/Nova OS)
:Nvidia_GPU_Tweaks
cls
color A
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════╗
echo ║ ✅ Running Nvidia GPU Tweaks. ║
echo ╚═══════════════════════════════╝
setlocal
timeout 1 > nul

:: Find GPU Device Path Loop.
for /L %%i in (0,1,9) do (
    for /F "tokens=2* skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\000%%i" /v "ProviderName" 2^>nul') do (
	if /i "%%b"=="NVIDIA" (
		set G=000%%i
		)
	)
)

:: Log and Echo Nvidia GPU Reg Path.
echo [%DATE% %TIME%] Nvidia GPU Reg Path: HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G% >> "C:\Oneclick Logs\Oneclick Log.txt"
echo 💻 Nvidia GPU Reg Path: HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G% 
echo.

:: BinaryMask for disabling logging.
Set "BinaryMask=00ffff0f01ffff0f02ffff0f03ffff0f04ffff0f05ffff0f06ffff0f07ffff0f08ffff0f09ffff0f0affff0f0bffff0f0cffff0f0dffff0f0effff0f0fffff0f10ffff0f11ffff0f12ffff0f13ffff0f14ffff0f15ffff0f16ffff0f00ffff1f01ffff1f02ffff1f03ffff1f04ffff1f05ffff1f06ffff1f07ffff1f08ffff1f09ffff1f0affff1f0bffff1f0cffff1f0dffff1f0effff1f0fffff1f00ffff2f01ffff2f02ffff2f03ffff2f04ffff2f05ffff2f06ffff2f07ffff2f08ffff2f09ffff2f0affff2f0bffff2f0cffff2f0dffff2f0effff2f0fffff2f00ffff3f01ffff3f02ffff3f03ffff3f04ffff3f05ffff3f06ffff3f07ffff3f" 

:: Creating GPU Backup Folder.
mkdir "%Oneclick_Backup_Folder%\GPU" >nul 2>&1

:: Creating Nvidia Reg Backup.
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" "%Oneclick_Backup_Folder%\GPU\Nvidia.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Nvidia GPU Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] Nvidia GPU Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

echo • Running Nvidia Profile Inspector.
"C:\Oneclick Tools\Nvidia\Nvidia Profile Inspector\nvidiaProfileInspector.exe" -importProfile "C:\Oneclick Tools\Nvidia\Nvidia Profile Inspector\NovaOS.nip" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Nvidia Profile Inspector: Failed to run and import. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else (
    echo [%DATE% %TIME%] Nvidia Profile Inspector: Ran successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

echo • Adding Nvidia Container Toggle to Context Menu.
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer" /v Icon /t REG_SZ /d "C:\Oneclick Tools\Nvidia\Nvidia Profile Inspector\nvidiaProfileInspector.exe,0" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer" /v MUIVerb /t REG_SZ /d "Nvidia Container" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer" /v Position /t REG_SZ /d "Bottom" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer" /v SubCommands /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\EnableNvContainer" /v HasLUAShield /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\EnableNvContainer" /v MUIVerb /t REG_SZ /d "Enable Container" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\EnableNvContainer\command" /ve /t REG_SZ /d "C:\Oneclick Tools\Nvidia\Nvidia Container\Nvidia Container ON.bat" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\DisableNvContainer" /v HasLUAShield /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\DisableNvContainer" /v MUIVerb /t REG_SZ /d "Disable Container" /f >nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\DisableNvContainer\command" /ve /t REG_SZ /d "C:\Oneclick Tools\Nvidia\Nvidia Container\Nvidia Container OFF.bat" /f >nul 2>&1

echo • Disabling NVIDIA Driver Notification.
reg add "HKCU\SOFTWARE\NVIDIA Corporation\Global\GFExperience" /v "NotifyNewDisplayUpdates" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Enabling NVIDIA Control Panel Developer Settings.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "NvDevToolsVisible" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Hiding NVIDIA Tray Icon.
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvTray" /v "StartOnLogin" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "HideXGpuTrayIcon" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\CoProcManager" /v "ShowTrayIcon" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Display Power Savings.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "DisplayPowerSaving" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\Software\NVIDIA Corporation\Global\NVTweak" /v "DisplayPowerSaving" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Runtime Power Management.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "EnableRuntimePowerManagement" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Enabling GPU Performance Counters for All Users.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling DLSS Indicator.
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NGXCore" /v "ShowDlssIndicator" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling HD Audio D3Cold.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "EnableHDAudioD3Cold" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Hardware Fault Buffer.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableHwFaultBuffer" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Per Intr DPC Queueing.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisablePerIntrDPCQueueing" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Engine Gatings.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElcg" /t REG_DWORD /d "1431655765" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMBlcg" /t REG_DWORD /d "286331153" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElpg" /t REG_DWORD /d "4095" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMSlcg" /t REG_DWORD /d "262131" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMFspg" /t REG_DWORD /d "15" /f >nul 2>&1

echo • Disabling GC6.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGC6Feature" /t REG_DWORD /d "699050" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGC6Parameters" /t REG_DWORD /d "85" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDidleFeatureGC5" /t REG_DWORD /d "44731050" /f >nul 2>&1

echo • Disabling Hot Plug Support.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMHotPlugSupportDisable" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling the Paged DMA mode for FBSR.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrPagedDMA" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Post L2 Compression.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisablePostL2Compression" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Logging.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmRcWatchdog" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLogonRC" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMIntrDetailedLogs" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMCtxswLog" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNvLog" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMSuppressGPIOIntrErrLog" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v "LogDisableMasks" /t REG_BINARY /d "%BinaryMask%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogWarningEntries" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogPagingEntries" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogEventEntries" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogErrorEntries" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling USB-C PMU event logging in RM.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMUsbcDebugMode" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Feature Disablement.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableFeatureDisablement" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling breakpoint on DEBUG resource manager on RC errors.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmBreakonRC" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling SMC on a specific GPU.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDebugSetSMCMode" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling LRC coalescing.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableLRCCoalescing" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling I2C Nanny.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmEnableI2CNanny" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Latency Tolerance.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMPcieLtrOverride" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMPcieLtrL12ThresholdOverride" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDeepL1EntryLatencyUsec" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Pre OS Apps.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisablePreosapps" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Enabling RmPerfLimitsOverride.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPerfLimitsOverride" /t REG_DWORD /d "21" /f >nul 2>&1

echo • Disabling RMGCOffFeature.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGCOffFeature" /t REG_DWORD /d "2" /f >nul 2>&1

echo • Disabling ASPM.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmOverrideSupportChipsetAspm" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableASPMDT" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableGpuASPMFlags" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableASPMAtLoad" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Event Tracer.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableEventTracer" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Error Checks.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SkipSwStateErrChecks" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Advanced Error Reporting.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMAERRForceDisable" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling OPSB Feature.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RM580312" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling WAR.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmWar1760398" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Configuring Low Power Features.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMLpwrArch" /t REG_DWORD /d "349525" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrGrPgSwFilterFunction" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrCtrlMsDifrSwAsrParameters" /t REG_DWORD /d "5461" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrCacheStatsOnD3" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Configuring Paging Features.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPgCtrlParameters" /t REG_DWORD /d "1431655765" /f >nul 2>&1

echo • Disabling MSCG from RM side.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDwbMscg" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling BBX Inform.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableInforomBBX" /t REG_DWORD /d "15" /f >nul 2>&1

echo • Enabling Prefer System Memory Contiguous.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "PreferSystemMemoryContiguous" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "PreferSystemMemoryContiguous" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Configuring SEC2 to not use profile with APM task enabled.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmSec2EnableApm" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Slowdowns.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmOverrideIdleSlowdownSettings" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMClkSlowDown" /t REG_DWORD /d "71303168" /f >nul 2>&1

echo • Disabling bunch of Power features as WAR for Bug.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RM2644249" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling 10 types of ACPI calls from the Resource Manager to the SBIOS.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableACPI" /t REG_DWORD /d "1023" /f >nul 2>&1

echo • Disabling Native PCIE L1.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNativePcieL1WarFlags" /t REG_DWORD /d "16" /f >nul 2>&1

echo • Forcing Disable Clear perfmon and reset level when entering D4 state.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMResetPerfMonD4" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling the WDDM power saving mode for FBSR.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrWDDMMode" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling the File based power saving mode for Linux.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrFileMode" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling EDC replay.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "PerfLevelSrc" /t REG_DWORD /d "8738" /f >nul 2>&1

echo • Disabling LPWR FSMs On Init.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElpgStateOnInit" /t REG_DWORD /d "3" /f >nul 2>&1

echo • Forcing never power off the MIOs.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmMIONoPowerOff" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Optimal Power For Padlink Pll.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableOptimalPowerForPadlinkPll" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling the power-off-dram-pll-when-unused feature.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmClkPowerOffDramPllWhenUnused" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling 6 Power Savings.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMOPSB" /t REG_DWORD /d "10914" /f >nul 2>&1

echo • Forcing P0 State.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Async P-States
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "DisableAsyncPstates" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Slides MCLK.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SlideMCLK" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling UPHY Init sequence.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNvlinkUPHYInitControl" /t REG_DWORD /d "16" /f >nul 2>&1

echo • Disabling Genoa System Power Controller.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmGpsGenoa" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Control Panel Telemetry.
reg add "HKLM\Software\Nvidia Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Telemetry Data.
reg add "HKLM\System\CurrentControlSet\Services\nvlddmkm\Global\Startup" /v "SendTelemetryData" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v EnableRID44231 /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v EnableRID64640 /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v EnableRID66610 /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Registry Caching.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableRegistryCaching" /t REG_DWORD /d "15" /f >nul 2>&1

echo • Enable D3 PC Latency.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "D3PCLatency" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling MS Hybrid.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "EnableMsHybrid" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Illegal Compstat Access.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableIntrIllegalCompstatAccess" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Setting Panel Refresh Rate.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SetPanelRefreshRate" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Non-Contiguous Allocation.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableNoncontigAlloc" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Unrestricting Application Clock Permissions.
nvidia-smi.exe -acp 0 >nul 2>&1

echo • Disabling HDCP.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableHdcp22" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Removing Driver Audio Bloat.
if exist "C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.dll" (
    for %%C in (Display.3DVision Display.Audio Ansel) do (
        Rundll32.exe "C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.dll",UninstallPackage %%C >nul 2>&1
    )
)

echo • Removing NvBackend From Startup.
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "NvBackend" /f >nul 2>&1

echo • Removing Telemetry and Camera Files.
for /d %%F in ("%SystemDrive%\Windows\System32\DriverStore\FileRepository\nv_dispig.inf_amd64_*") do (
    takeown /f "%%F" /r /d Y >nul 2>&1
    icacls "%%F" /grant "%USERNAME%":F /t >nul 2>&1
    del /s /q "%%F\NvTelemetry64.dll" >nul 2>&1
    rd /s /q "%%F\NvCamera" >nul 2>&1
    del /s /q "%%F\Display.NvContainer\plugins\LocalSystem\_DisplayDriverRAS.dll" >nul 2>&1
)

echo • Deleting NVIDIA Corporation Folders.
Takeown /F "C:\Windows\System32\drivers\NVIDIA Corporation" /R /D Y >nul 2>&1
Icacls "C:\Windows\System32\drivers\NVIDIA Corporation" /grant "%USERNAME%":F /T >nul 2>&1
rd /s /q "C:\Windows\System32\drivers\NVIDIA Corporation" >nul 2>&1

echo • Deleting other NVIDIA Folders.
rd /s /q "%SystemDrive%\Program Files\NVIDIA Corporation\Display.NvContainer\plugins\LocalSystem\DisplayDriverRAS" >nul 2>&1
rd /s /q "%SystemDrive%\Program Files\NVIDIA Corporation\DisplayDriverRAS" >nul 2>&1
rd /s /q "%SystemDrive%\ProgramData\NVIDIA Corporation\DisplayDriverRAS" >nul 2>&1
endlocal

echo ✔  Nvidia GPU tweaked successfully.
timeout 2 > nul
goto :Latency_Tweaks

:: AMD GPU Tweaks. (Fulll Credit to p467121/Nova OS)
:AMD_GPU_Tweaks
cls
color C
chcp 65001 >nul 2>&1
echo ╔════════════════════════════╗
echo ║ ✅ Running AMD GPU Tweaks. ║
echo ╚════════════════════════════╝
setlocal
timeout 1 > nul

:: Find GPU Device Path Loop.
for /f "tokens=*" %%c in (
	'reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "Radeon" /t REG_SZ /s 2^>nul ^| findstr /l "}"'
) do (
	set gpu_key=%%c
)

:: Log AMD GPU Reg Path.
echo [%DATE% %TIME%] AMD GPU Reg Path: %gpu_key% >> "C:\Oneclick Logs\Oneclick Log.txt"
echo 💻 AMD GPU Reg Path: %gpu_key%
echo.

:: Creating GPU Backup Folder.
mkdir "%Oneclick_Backup_Folder%\GPU" >nul 2>&1

:: Creating AMD Reg Backup.
reg export "%gpu_key%" "%Oneclick_Backup_Folder%\GPU\AMD.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] AMD GPU Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] AMD GPU Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

echo • Enabling Performance Mode.
reg add "%gpu_key%" /v "PP_Force3DPerformanceMode" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "PP_ForceHighDPMLevel" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Sleep.
reg add "%gpu_key%" /v "DisableGfxCoarseGrainLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxCpLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxMediumGrainLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxRlcLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableDrmLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Radeon Boost.
reg add "%gpu_key%" /v "KMD_RadeonBoostEnabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Clock Gating.
reg add "%gpu_key%" /v "DisableGfx3DCGLS" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxCGTS" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxCGTS_LS" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxMGCGPerfMon" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableDrmdmaMGCG" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableDrmMGCG" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfx3DCGCG" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableUvdClockGating" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableVceSwClockGating" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableGfxClockGatingThruSmu" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableSysClockGatingThruSmu" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "IRQMgrDisableIHClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "swGcClockGatingMask" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "swGcClockGatingOverride" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableRomMediumGrainClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableRomMGCGClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableSamuClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableSysClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableVceClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxCoarseGrainClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxMediumGrainClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableMcMediumGrainClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableNbioMediumGrainClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DalDisableClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DalFineGrainClockGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableAllClockGating" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Power Gating.
reg add "%gpu_key%" /v "DisableGfxPGCondClearStateWA" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableCpPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableAcpPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableDrmdmaPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableDynamicGfxMGPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGDSPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxCGPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGFXPipelinePowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableUVDPowerGatingDynamic" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisablePowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableQuickGfxMGPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableSAMUPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableStaticGfxMGPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableUVDPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableVCEPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableXdmaPowerGating" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableXdmaSclkGating" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Powerdown.
reg add "%gpu_key%" /v "DalPSRSkipCRTCPowerDown" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "PP_GPUPowerDownEnabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling ASPM.
reg add "%gpu_key%" /v "DisableAspmSWL1" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableAspmL0s" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableAspmL1" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableAspmL0s" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableAspmL1" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableAspmL1SS" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "AspmL0sTimeout" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "AspmL1Timeout" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling ClkReq.
reg add "%gpu_key%" /v "DisableClkReqSupport" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling FBC.
reg add "%gpu_key%" /v "DisableFBCSupport" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling UvD.
reg add "%gpu_key%" /v "DisableForceUvdToSclk" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Downgrade.
reg add "%gpu_key%" /v "PipeTilingDowngrade" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "GroupSizeDowngrade" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "RowTilingDowngrade" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "SampleSplitDowngrade" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Spread Spectrum.
reg add "%gpu_key%" /v "EnableSpreadSpectrum" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Power Saver.
reg add "HKCU\Software\AMD\CN" /v "PowerSaverAutoEnable_CUR" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Radeon Chill.
reg add "HKLM\System\CurrentControlSet\Services\amdwddmg" /v "ChillEnabled" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Auto Update.
reg add "HKCU\Software\AMD\CN" /v "AutoUpdateTriggered" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\AMD\CN" /v "AutoUpdate" /t REG_DWORD /d "0" /f >nul 2>&1

echo • Disabling Animations.
reg add "HKCU\Software\AMD\CN" /v "AnimationEffect" /t REG_SZ /d "false" /f >nul 2>&1

echo ✔  AMD GPU tweaked successfully.
timeout 2 > nul
goto :Latency_Tweaks

:: Latency Tweaks.
:Latency_Tweaks
cls
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
timeout 2 > nul

:: BCDEdit Tweaks.
cls
color D
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════╗
echo ║ ✅ Applying BCDEdit Tweaks. ║
echo ╚═════════════════════════════╝

echo • Deleting Platformclock.
bcdedit /deletevalue useplatformclock >nul 2>&1

echo • Disabling Platformtick.
bcdedit /set useplatformtick no >nul 2>&1

echo • Disabling Dynamictick.
bcdedit /set disabledynamictick yes >nul 2>&1

echo ✔  BCDEdit Tweaks applied successfully.
timeout 2 > nul

:: Power Tweaks.
cls
color 9
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════╗
echo ║ ✅ Applying Power Tweaks. ║
echo ╚═══════════════════════════╝

echo • Disabling Hibernation.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "AllowHibernate" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergySaverState" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EventProcessorEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabledDefault" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "TimerCoalescing" /t REG_BINARY /d "0000000000000000000000000000000000000000000000000000000000000000" /f >nul 2>&1
powercfg /hibernate off >nul 2>&1

echo • Disabling Modern Standby.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformAoAcOverride" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformRoleOverride" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "MSDisabled" /t REG_DWORD /d "1" /f >nul 2>&1

echo • Disabling Device Power Management.
chcp 437 >nul
Powershell -Command "Get-WmiObject MSPowerDeviceEnable -Namespace root\wmi | ForEach-Object { $_.Enable = $false; $_.psbase.Put() }" >nul 2>&1
chcp 65001 >nul 2>&1

echo ✔  Power Tweaks applied successfully.
timeout 2 > nul

:: Kernal Tweaks.
cls
color D
chcp 65001 >nul 2>&1
echo ╔════════════════════════════╗
echo ║ ✅ Applying Kernal Tweaks. ║
echo ╚════════════════════════════╝

echo • Adding Hybrid/Heterogeneous CPU Kernal Tweaks.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DynamicHeteroCpuPolicyMask" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DefaultDynamicHeteroCpuPolicy" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DynamicHeteroCpuPolicyImportant" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DynamicHeteroCpuPolicyImportantShort" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DynamicHeteroCpuPolicyImportantPriority" /t REG_DWORD /d "8" /f >nul 2>&1

echo • Adding Timer-Related Kernal Tweaks.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "SerializeTimerExpiration" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "EnablePerCpuClockTickScheduling" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "TimerCheckFlags" /t REG_DWORD /d "0" /f > nul 2>&1

echo ✔  Kernal Tweaks applied successfully.
timeout 2 > nul

:: Priority Separation Tweaks.
:Priority_Separation
cls
color 9
chcp 65001 >nul 2>&1
echo ╔══════════════════════════════════╗
echo ║ ✅ Changing Priority Separation. ║
echo ╚══════════════════════════════════╝
echo • Please choose a preset depending on your use case.
echo.
echo %White%[Choose an option]
echo %Green%1. FPS - 42 Decimal - 2A Hexadecimal
echo %Green%2. Latency - 36 Decimal - 24 Hexadecimal
echo %Green%3. Balanced - 26 Decimal - 1A Hexadecimal
echo %DarkYellow%4. Custom Value.  
echo %Cyan%5. Learn More.
echo %Red%6. Skip. 
set /p option="%White%Enter option number: "
echo %Blue%
if "%option%"=="1" (
    echo [%DATE% %TIME%] Priority Separation Options: User Chose "Option 1" - FPS Preset. >> "C:\Oneclick Logs\Oneclick Log.txt"
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x2a" /f >nul 2>&1 
    echo ✔  FPS Preset selected successfully.
    timeout 2 > nul
    goto :Redetect_WinVer
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Priority Separation Options: User Chose "Option 2" - Latency Preset. >> "C:\Oneclick Logs\Oneclick Log.txt"
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x00000024" /f >nul 2>&1
    echo ✔  Latency Preset selected successfully.
    timeout 2 > nul
    goto :Redetect_WinVer
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Priority Separation Options: User Chose "Option 3" - Balanced Preset. >> "C:\Oneclick Logs\Oneclick Log.txt"
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x1a" /f >nul 2>&1
    echo ✔  Balanced Preset selected successfully.
    timeout 2 > nul
    goto :Redetect_WinVer
) else if "%option%"=="4" (
    echo [%DATE% %TIME%] Priority Separation Options: User Chose "Option 4" - Custom Value. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Custom_Priority_Separation
) else if "%option%"=="5" (
    echo [%DATE% %TIME%] Priority Separation Options: User Chose "Option 5" - Learn More. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Github Page. ║
    echo ╚═════════════════════════╝
    echo • Smart decision, launching the Github page in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Priority%%20Separation%%20Options.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Priority_Separation
) else if "%option%"=="6" (
    echo [%DATE% %TIME%] Priority Separation Options: User Chose "Option 6" - Skip. >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo ✔  Skipping!
    timeout 2 > nul
    goto :Redetect_WinVer
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-6.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Priority_Separation
)

:: Custom Priority Separation Value.
:Custom_Priority_Separation
setlocal
cls
color A
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════╗
echo ║ ✅ Enter your Custom Value. ║
echo ╚═════════════════════════════╝
echo • Value must be entered as Decimal. (Example 36)
echo. 
set /p CustomValue="Enter option number: "
echo [%DATE% %TIME%] Priority Separation Custom Value: User Chose "%CustomValue%" Decimal. >> "C:\Oneclick Logs\Oneclick Log.txt"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "%CustomValue%" /f >nul 2>&1
if %errorlevel%==0 (
   echo ✔  Custom Value applied successfully.
   echo.
   <nul set /p="→ Press any key to continue . . . "
   pause >nul
   goto :Redetect_WinVer
) else (
   echo ❌ Failed to apply custom value.
   timeout 2 > nul
   goto :Priority_Separation
)
endlocal

:: Re-detect Windows Version.
:Redetect_WinVer
cls
setlocal enabledelayedexpansion
set /p CurrentBuild=<"C:\Oneclick Logs\Extra\WinVersion.txt"
if !CurrentBuild! GEQ 22000 (
    rd /s /q "C:\Oneclick Tools\DPC Checker" >nul 2>&1
    endlocal & goto :Timer_Res_11
) else (
    endlocal & goto :Recheck_WinSer
)

:: Re-check for Windows Server Version.
:Recheck_WinSer
setlocal
set /p ServerType=<"C:\Oneclick Logs\Extra\WinServerVersion.txt"
if /i "%ServerType%"=="Server" (
    rd /s /q "C:\Oneclick Tools\DPC Checker" >nul 2>&1
    endlocal & goto :Timer_Res_11
) else (
    endlocal & goto :DPC_Checker
)

:: DPC Checker Setup. (For Windows 10 Users, to fix delta's)
:DPC_Checker
cls
color C
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════════════╗
echo ║ ❌ Windows 10 Detected. (DPC Checker) ║
echo ╚═══════════════════════════════════════╝
echo • Windows 10 versions starting 2004 or 20H1 and above have broken Timer Resolution's.
echo Meaning System Delta's are forced at 15ms, however DPC Checker being open can fix this issue.
echo.
echo → Adding DPC Checker to startup. (Please Keep It Opened ^& Minimized At All Times)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "DPC Checker" /t REG_SZ /d "C:\Oneclick Tools\DPC Checker\dpclat.exe" /f >nul 2>&1
echo ✔  DPC Checker added changed successfully.
echo.
<nul set /p="→ Press any key to continue . . . "
pause >nul

:: Timer Resolution Setup.
:Timer_Res_11
cls
color D
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════╗
echo ║ ✅ Setting Up Timer Resolution. ║
echo ╚═════════════════════════════════╝
echo • Please choose a preset depending on your use case.
echo.
echo %White%[Choose an option]
echo %Green%1. Timer Res 0.500ms  
echo %Green%2. Timer Res 0.504ms
echo %Green%3. Timer Res 0.507ms
echo %DarkYellow%4. Custom Value.
echo %Cyan%5. Learn More.
echo %Red%6. Skip.     
set /p option="%White%Enter option number: "
echo %Magenta%
if "%option%"=="1" (
    echo [%DATE% %TIME%] Timer Resolution Options: User Chose "Option 1" - 0.500ms Resolution. >> "C:\Oneclick Logs\Oneclick Log.txt"
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5000 --no-console" /f >nul 2>&1
    echo ✔  Timer Resolution 0.500ms selected successfully.
    timeout 2 > nul
    goto :Power_Plan
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Timer Resolution Options: User Chose "Option 2" - 0.504ms Resolution. >> "C:\Oneclick Logs\Oneclick Log.txt"
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5040 --no-console" /f >nul 2>&1
    echo ✔  Timer Resolution 0.504ms selected successfully.
    timeout 2 > nul
    goto :Power_Plan
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Timer Resolution Options: User Chose "Option 3" - 0.507ms Resolution. >> "C:\Oneclick Logs\Oneclick Log.txt"
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5070 --no-console" /f >nul 2>&1
    echo ✔  Timer Resolution 0.507ms selected successfully.
    timeout 2 > nul
    goto :Power_Plan
) else if "%option%"=="4" (
    echo [%DATE% %TIME%] Timer Resolution Options: User Chose "Option 4" - Custom Value. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Custom_Timer_Resolution
) else if "%option%"=="5" (
    echo [%DATE% %TIME%] Timer Resolution Options: User Chose "Option 5" - Learn More. >> "C:\Oneclick Logs\Oneclick Log.txt" 
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Github Page. ║
    echo ╚═════════════════════════╝
    echo • Smart decision, launching the Github page in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Timer%%20Resolution%%20Options.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Timer_Res_11
) else if "%option%"=="6" (
    echo [%DATE% %TIME%] Timer Resolution Options: User Chose "Option 6" - Skip. >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo ✔  Skipping!
    rd /s /q "C:\Oneclick Tools\Timer Resolution" >nul 2>&1
    timeout 2 > nul
    goto :Power_Plan
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-6.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Priority_Separation
)

:: Custom Timer Resolution Value.
:Custom_Timer_Resolution
setlocal
cls
color A
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════╗
echo ║ ✅ Enter your Custom Value. ║
echo ╚═════════════════════════════╝
echo • Value must be entered as 4 digits. (Example 5000)
echo. 
set /p CustomValue="Enter option number: "
echo [%DATE% %TIME%] Timer Resolution Custom Value: User Chose "%CustomValue%" Resolution. >> "C:\Oneclick Logs\Oneclick Log.txt"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution %CustomValue% --no-console" /f >nul 2>&1
if %errorlevel%==0 (
   echo ✔  Custom Value applied successfully.
   echo.
   <nul set /p="→ Press any key to continue . . . "
   pause >nul
   goto :Power_Plan
) else (
   echo ❌ Failed to apply custom value.
   timeout 2 > nul
   goto :Timer_Res_11
)
endlocal

:: Power Plan Import.
:Power_Plan
cls
color 9
chcp 65001 >nul 2>&1
echo ╔══════════════════════════╗
echo ║ ✅ Importing Power Plan. ║
echo ╚══════════════════════════╝
echo • Please choose a plan depending on your use case.
echo.
echo %White%[Choose an option]
echo %Green%1. Quaked Ultimate Performance. 
echo %DarkYellow%2. Quaked Ultimate Performance Idle Off.   
echo %Cyan%3. Learn More.  
echo %Red%4. Skip.   
set /p option="%White%Enter option number: "
echo %Blue%
if "%option%"=="1" (
    echo [%DATE% %TIME%] Power Plan Options: User Chose "Option 1" - Quaked Ultimate Performance. >> "C:\Oneclick Logs\Oneclick Log.txt"
    powercfg -import "C:\Oneclick Tools\Power Plans\Quaked Ultimate Performance.pow" >nul 2>&1
    goto :Check_Plan_Import
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Power Plan Options: User Chose "Option 2" - Quaked Ultimate Performance Idle Off. >> "C:\Oneclick Logs\Oneclick Log.txt"
    powercfg -import "C:\Oneclick Tools\Power Plans\Quaked Ultimate Performance Idle Off.pow" >nul 2>&1
    goto :Check_Plan_Import
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Power Plan Options: User Chose "Option 3" - Learn More. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════╗
    echo ║ ✅ Opening Github Page. ║
    echo ╚═════════════════════════╝
    echo • Smart decision, launching the Github page in 2 seconds!
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Power%%20Plan%%20Options.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Power_Plan
) else if "%option%"=="4" (
    echo [%DATE% %TIME%] Power Plan Options: User Chose "Option 4" - Skip. >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo • Skipping!
    timeout 2 > nul
    goto :Clean_Up
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-4.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Power_Plan
)

:: Check If Power Plan Imported.
:Check_Plan_Import
setlocal enabledelayedexpansion

:: Check if Quaked Ultimate Performance exists.
for /f "tokens=2 delims=:(" %%i in ('powercfg /list ^| findstr /C:"Quaked Ultimate Performance"') do (
    set Plan_Guid=%%i
)

:: Check if Quaked Ultimate Performance Idle Off exists.
for /f "tokens=2 delims=:(" %%i in ('powercfg /list ^| findstr /C:"Quaked Ultimate Performance Idle Off"') do (
    set Idle_Off_Plan_Guid=%%i
)

:: Activating Power Plan.
if defined Plan_Guid (
   echo [%DATE% %TIME%] Power Plan: Quaked Ultimate Performance imported successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
   powercfg /setactive %Plan_Guid% >nul 2>&1
   endlocal & goto :Plan_Import_Worked  
) else if defined Idle_Off_Plan_Guid (
   echo [%DATE% %TIME%] Power Plan: Quaked Ultimate Performance Idle Off imported successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
   powercfg /setactive %Idle_Off_Plan_Guid% >nul 2>&1
   endlocal & goto :Plan_Import_Worked  
) else (
   echo [%DATE% %TIME%] Power Plan: Failed to import. >> "C:\Oneclick Logs\Oneclick Log.txt"
   endlocal & goto :Plan_Import_Failed
)

:: Power Plan Import Worked.
:Plan_Import_Worked
cls
color A
chcp 65001 >nul 2>&1
echo ╔══════════════════════════════════════╗
echo ║ ✅ Power Plan Imported Successfully. ║
echo ╚══════════════════════════════════════╝
echo • Opening Power Options.
powercfg.cpl
echo.
<nul set /p="→ Press any key to continue . . . "
pause >nul
taskkill /F /FI "WINDOWTITLE eq Power Options" >nul 2>&1
goto :Clean_Up

:: Power Plan Import Failed.
:Plan_Import_Failed
cls
color C
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════╗
echo ║ ❌ Power Plan Failed to Import. ║
echo ╚═════════════════════════════════╝
echo • Opening Github Page.
timeout 2 > nul
start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Power%%20Plan%%20Options.md#power-plan-import-failed"
echo.
<nul set /p="→ Press any key to continue . . . "
pause >nul
goto :Clean_Up

:: Clean UP.
:Clean_Up
cls
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
timeout 2 > nul

:: File Cleanup.
cls
color D
chcp 65001 >nul 2>&1
echo ╔══════════════════════════╗
echo ║ ✅ Running File Cleanup. ║
echo ╚══════════════════════════╝
timeout 1 > nul

:: Note: Del commands is used along side RD, to show and echo whats being deleted.

:: Windows WebCache.
del /s /q "%LocalAppData%\Microsoft\Windows\WebCache" 
rd /s /q "%LocalAppData%\Microsoft\Windows\WebCache" >nul 2>&1
mkdir "%LocalAppData%\Microsoft\Windows\WebCache" >nul 2>&1

:: Temp.
del /s /q "C:\Windows\Temp"
rd /s /q "C:\Windows\Temp" >nul 2>&1
mkdir "C:\Windows\Temp" >nul 2>&1 

:: Appdata Temp.
del /s /q "%Temp%" 
rd /s /q "%Temp%" >nul 2>&1
mkdir "%Temp%" >nul 2>&1 

:: Discord Cache.
del /s /q "%AppData%\Discord\Cache" 
rd /s /q "%AppData%\Discord\Cache" >nul 2>&1
mkdir "%AppData%\Discord\Cache" >nul 2>&1

:: Discord Code Cache.
del /s /q "%AppData%\Discord\Code Cache" 
rd /s /q "%AppData%\Discord\Code Cache" >nul 2>&1
mkdir "%AppData%\Discord\Code Cache" >nul 2>&1

:: Spotify Cache.
del /s /q "%LocalAppData%\Spotify\Data"
rd /s /q "%LocalAppData%\Spotify\Data" >nul 2>&1
mkdir "%LocalAppData%\Spotify\Data" >nul 2>&1

:: Prefetch
del /s /q "C:\Windows\Prefetch"
rd /s /q "C:\Windows\Prefetch" >nul 2>&1
mkdir "C:\Windows\Prefetch" >nul 2>&1 

:: Windows Update/Logs.
del /s /q "%ProgramData%\USOPrivate\UpdateStore" 
del /s /q "%ProgramData%\USOShared\Logs" 
del /s /q "C:\Windows\System32\SleepStudy"
del /s /q "C:\Windows\Logs"

echo ✔  File Cleanup completed successfully.
timeout 2 > nul

:: Network Cleanup.
cls
color 9
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════╗
echo ║ ✅ Running Network Cleanup. ║
echo ╚═════════════════════════════╝
timeout 1 > nul
ipconfig /release
ipconfig /renew
arp -d *
nbtstat -R
nbtstat -RR
ipconfig /flushdns
ipconfig /registerdns >nul 2>&1

echo ✔  Network Cleanup completed successfully.
timeout 2 > nul

:: Extras Menu. 
:Extras
cls
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
echo.                                     ███████╗██╗  ██╗████████╗██████╗  █████╗ ███████╗
echo.                                     ██╔════╝╚██╗██╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝
echo.                                     █████╗   ╚███╔╝    ██║   ██████╔╝███████║███████╗
echo.                                     ██╔══╝   ██╔██╗    ██║   ██╔══██╗██╔══██║╚════██║
echo.                                     ███████╗██╔╝ ██╗   ██║   ██║  ██║██║  ██║███████║
echo.                                     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
echo.
echo.                         ╔═════════════════════════════════════════════════════════════════════╗ 
echo.                         ║                                                                     ║ 
echo.                         ║           [1] Additional Features     [2] Fixers                    ║
echo.                         ║           [3] Discord Server          [4] Restart                   ║
echo.                         ║                                                                     ║
echo.                         ╚═════════════════════════════════════════════════════════════════════╝
echo.  
echo.  
echo.
echo ____________________
set /p option="Enter option number: "
if "%option%"=="1" (
    echo [%DATE% %TIME%] Extras Menu Options: User Chose "Option 1" - Additional Features. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :AdFeatures
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Extras Menu Options: User Chose "Option 2" - Fixers. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Fixers
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Extras Menu Options: User Chose "Option 3" - Discord Server. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Discord
) else if "%option%"=="4" (
    echo [%DATE% %TIME%] Extras Menu Options: User Chose "Option 4" - Restart. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Restart 
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-4.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Extras
)

:: Fixers Menu. 
:Fixers
cls
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
echo ____________________
set /p option="Enter option number: "
if "%option%"=="1" (
    echo [%DATE% %TIME%] Fixers Menu Options: User Chose "Option 1" - Wifi Fixer. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    chcp 65001 >nul 2>&1
    echo ╔════════════════════════╗
    echo ║ ✅ Running Wifi Fixer. ║
    echo ╚════════════════════════╝
    echo • Requires a Restart.
    timeout 2 > nul
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
    timeout 2 > nul 
    goto :Fixers 
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Fixers Menu Options: User Chose "Option 2" - Epic Games Fixer. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    chcp 65001 >nul 2>&1
    echo ╔══════════════════════════════╗
    echo ║ ✅ Running Epic Games Fixer. ║
    echo ╚══════════════════════════════╝
    echo • Enabling Epic Games Services.
    sc config "EpicGamesUpdater" start=auto >nul 2>&1
    sc config "EpicOnlineServices" start=auto >nul 2>&1
    timeout 2 > nul 
    goto :Fixers 
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Fixers Menu Options: User Chose "Option 3" - Rockstar Games Fixer. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    chcp 65001 >nul 2>&1
    echo ╔══════════════════════════════════╗
    echo ║ ✅ Running Rockstar Games Fixer. ║
    echo ╚══════════════════════════════════╝
    echo • Enabling Rockstar Games Service.
    sc config "Rockstar Service" start=auto >nul 2>&1
    timeout 2 > nul 
    goto :Fixers
) else if "%option%"=="4" (
    echo [%DATE% %TIME%] Fixers Menu Options: User Chose "Option 4" - Fixer Github. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    chcp 65001 >nul 2>&1
    echo ╔══════════════════════════════╗
    echo ║ ✅ Running The Fixer Github. ║
    echo ╚══════════════════════════════╝
    echo • Opening Github Page.
    timeout 2 > nul
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Oneclick%%20Fixes.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Fixers
) else if "%option%"=="5" (
    echo [%DATE% %TIME%] Fixers Menu Options: User Chose "Option 5" - Return to Extras. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Extras
) else if "%option%"=="6" (
    echo [%DATE% %TIME%] Fixers Menu Options: User Chose "Option 6" - Restart. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Restart 
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-6.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Fixers
)

:: Additional Features.
:AdFeatures
cls
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
echo.                           █████╗ ██████╗ ██████╗ ██╗████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     
echo.                          ██╔══██╗██╔══██╗██╔══██╗██║╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██║     
echo.                          ███████║██║  ██║██║  ██║██║   ██║   ██║██║   ██║██╔██╗ ██║███████║██║     
echo.                          ██╔══██║██║  ██║██║  ██║██║   ██║   ██║██║   ██║██║╚██╗██║██╔══██║██║     
echo.                          ██║  ██║██████╔╝██████╔╝██║   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║███████╗
echo.                          ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
echo.                                                                          
echo.                             ███████╗███████╗ █████╗ ████████╗██╗   ██╗██████╗ ███████╗███████╗        
echo.                             ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔════╝██╔════╝        
echo.                             █████╗  █████╗  ███████║   ██║   ██║   ██║██████╔╝█████╗  ███████╗        
echo.                             ██╔══╝  ██╔══╝  ██╔══██║   ██║   ██║   ██║██╔══██╗██╔══╝  ╚════██║        
echo.                             ██║     ███████╗██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗███████║        
echo.                             ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝ 
echo.
echo.                         ╔═════════════════════════════════════════════════════════════════════╗ 
echo.                         ║                                                                     ║ 
echo.                         ║     [1] Process Destroyer           [2] Network Tweaks              ║
echo.                         ║     [3] Process Destroyer Extreme   [4] Disable Optional Features   ║
echo.                         ║     [5] Device Manager Tweaks       [6] Audio Bloat Remover         ║
echo.                         ║     [7] Return to Extras            [8] Restart                     ║
echo.                         ║                                                                     ║
echo.                         ╚═════════════════════════════════════════════════════════════════════╝
echo.  
echo.  
echo.
echo ____________________
set /p option="Enter option number: "
if "%option%"=="1" (
    echo [%DATE% %TIME%] Additional Features Menu Options: User Chose "Option 1" - Process Destroyer. >> "C:\Oneclick Logs\Oneclick Log.txt"
    set "SelectedProcessDestroyer=C:\Oneclick Tools\Process Destroyer\Oneclick Process Destroyer V2.5.bat"
    goto :Process_Destroyer
) else if "%option%"=="2" (
    echo [%DATE% %TIME%] Additional Features Menu Options: User Chose "Option 2" - Network Tweaks. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Network_Tweaks_Warning
) else if "%option%"=="3" (
    echo [%DATE% %TIME%] Additional Features Menu Options: User Chose "Option 3" - Process Destroyer Extreme. >> "C:\Oneclick Logs\Oneclick Log.txt"
    set "SelectedProcessDestroyer=C:\Oneclick Tools\Process Destroyer\Oneclick Process Destroyer Extreme V2.5.bat"
    goto :Process_Destroyer 
) else if "%option%"=="4" (
    echo [%DATE% %TIME%] Additional Features Menu Options: User Chose "Option 4" - Disable Optional Features. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Optional_Features
) else if "%option%"=="5" (
    echo [%DATE% %TIME%] Additional Features Menu Options: User Chose "Option 5" - Device Manager Tweaks. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Device_Manager_Warning
) else if "%option%"=="6" (
    echo [%DATE% %TIME%] Additional Features Menu Options: User Chose "Option 6" - Audio Bloat Remover. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Audio_Bloat_Warning
) else if "%option%"=="7" (
    echo [%DATE% %TIME%] Additional Features Menu Options: User Chose "Option 7" - Return to Extras. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Extras
) else if "%option%"=="8" (
    echo [%DATE% %TIME%] Additional Features Menu Options: User Chose "Option 8" - Restart. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Restart  
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-8.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :AdFeatures
)

:: Process Destroyer.
:Process_Destroyer
cls
color C
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════╗
echo ║ ⚠️ Process Destroyer Warning. ║
echo ╚═══════════════════════════════╝
echo ❌ Read the Process Destroyer Requirements!
echo. 
echo 1. Process Destroyer is required to be ran on a system that installed windows with an offline/Local account.
echo 2. All necessary Apps, Programs, Drivers and Gpu Drivers should be installed before running Process Destroyer.
echo 3. Any failure to met the requirements to be on an offline/Local account, will result in a black screen when logging in.
echo. 
echo Important: Wifi, Windows Search, and many other features aren't supported. (Read the Unsupported List)
echo.
echo → Do you still wish to continue? (LAST WARNING)
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] Process Destroyer Warning: User Chose "Yes" - Run Process Destroyer. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═══════════════════════════════╗
    echo ║ ✅ Running Process Destroyer. ║
    echo ╚═══════════════════════════════╝
    echo • Automatically executing Process Destroyer with NSudo.
    "C:\Oneclick Tools\NSudo\NSudoLG.exe" -ShowWindowMode:Show -U:T -P:E "%SelectedProcessDestroyer%"
    echo Continuing in 3 seconds...
    timeout 3 > nul
    goto :AdFeatures
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] Process Destroyer Warning: User Chose "No" - Skip Process Destroyer. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═══════════════════════════════════╗
    echo ║ ❌ Not Running Process Destroyer. ║
    echo ╚═══════════════════════════════════╝
    echo • Now returning to Additional Features in 2 seconds!
    timeout 2 > nul
    goto :AdFeatures
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Process_Destroyer
)

:: Network Tweaks Warning.
:Network_Tweaks_Warning
cls
color C
chcp 65001 >nul 2>&1
echo ╔════════════════════════════╗
echo ║ ⚠️ Network Tweaks Warning. ║
echo ╚════════════════════════════╝
echo ❌ Read very carefully!
echo. 
echo 1. Usage of the Network Tweaks may negatively impact your networks speed or performance. 
echo 2. You may also lose Network Connection!
echo. 
echo → Do you still wish to continue? (LAST WARNING)
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] Network Tweaks Warning: User Chose "Yes" - Run Network Tweaks. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Network_Tweaks
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] Network Tweaks Warning: User Chose "No" - Skip Network Tweaks. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔════════════════════════════════╗
    echo ║ ❌ Not Running Network Tweaks. ║
    echo ╚════════════════════════════════╝
    echo • Now returning to Additional Features in 2 seconds!
    timeout 2 > nul
    goto :AdFeatures
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Network_Tweaks_Warning
)

:: Network Tweaks (Full Credit to p467121/Nova OS)
:Network_Tweaks
cls
color A
chcp 65001 >nul 2>&1
echo ╔════════════════════════════╗
echo ║ ✅ Running Network Tweaks. ║
echo ╚════════════════════════════╝
setlocal enabledelayedexpansion

:: Creating Network Backup Folder.
mkdir "%Oneclick_Backup_Folder%\Network" >nul 2>&1

:: Detecting Network Adapter.
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /v "*SpeedDuplex" /s ^| findstr "HKEY"') do (
    echo [%DATE% %TIME%] Network Adapter Path: %%a >> "C:\Oneclick Logs\Oneclick Log.txt"
    echo [%DATE% %TIME%] Network Tweaks: Network Adapter Path - %%a >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
    call :Backup_Network "%%a"
    echo 📶 Current Network Adapter Path: %%a
    timeout 2 > nul
    echo.
    for /f %%i in ('reg query "%%a" /v "*ReceiveBuffers" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*ReceiveBuffers" /t REG_SZ /d "2048" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found ReceiveBuffers. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking ReceiveBuffers.
    )
    for /f %%i in ('reg query "%%a" /v "*TransmitBuffers" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TransmitBuffers" /t REG_SZ /d "1024" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found TransmitBuffers. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking TransmitBuffers.
    )
    for /f %%i in ('reg query "%%a" /v "EnablePME" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePME" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnablePME. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnablePME.
    )
    for /f %%i in ('reg query "%%a" /v "*DeviceSleepOnDisconnect" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*DeviceSleepOnDisconnect" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found DeviceSleepOnDisconnect. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking DeviceSleepOnDisconnect.
    )
    for /f %%i in ('reg query "%%a" /v "*EEE" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*EEE" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EEE. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EEE.
    )
    for /f %%i in ('reg query "%%a" /v "*ModernStandbyWoLMagicPacket" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*ModernStandbyWoLMagicPacket" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found ModernStandbyWoLMagicPacket. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking ModernStandbyWoLMagicPacket.
    )
    for /f %%i in ('reg query "%%a" /v "*SelectiveSuspend" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*SelectiveSuspend" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found SelectiveSuspend. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking SelectiveSuspend.
    )
    for /f %%i in ('reg query "%%a" /v "*WakeOnMagicPacket" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*WakeOnMagicPacket" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeOnMagicPacket. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeOnMagicPacket.
    )
    for /f %%i in ('reg query "%%a" /v "*WakeOnPattern" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*WakeOnPattern" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeOnPattern. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeOnPattern.
    )
    for /f %%i in ('reg query "%%a" /v "AutoPowerSaveModeEnabled" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found AutoPowerSaveModeEnabled. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking AutoPowerSaveModeEnabled.
    )
    for /f %%i in ('reg query "%%a" /v "EEELinkAdvertisement" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EEELinkAdvertisement" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EEELinkAdvertisement. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EEELinkAdvertisement.
    )
    for /f %%i in ('reg query "%%a" /v "EeePhyEnable" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EeePhyEnable" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EeePhyEnable. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EeePhyEnable.
    )
    for /f %%i in ('reg query "%%a" /v "EnableGreenEthernet" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnableGreenEthernet. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnableGreenEthernet.
    )
    for /f %%i in ('reg query "%%a" /v "EnableModernStandby" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableModernStandby" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnableModernStandby. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnableModernStandby.
    )
    for /f %%i in ('reg query "%%a" /v "GigaLite" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "GigaLite" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found GigaLite. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking GigaLite.
    )
    for /f %%i in ('reg query "%%a" /v "PnPCapabilities" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "PnPCapabilities" /t REG_DWORD /d "24" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found PnPCapabilities. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking PnPCapabilities.
    )
    for /f %%i in ('reg query "%%a" /v "PowerDownPll" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "PowerDownPll" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found PowerDownPll. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking PowerDownPll.
    )
    for /f %%i in ('reg query "%%a" /v "PowerSavingMode" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "PowerSavingMode" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found PowerSavingMode. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking PowerSavingMode.
    )
    for /f %%i in ('reg query "%%a" /v "ReduceSpeedOnPowerDown" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found ReduceSpeedOnPowerDown. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking ReduceSpeedOnPowerDown.
    )
    for /f %%i in ('reg query "%%a" /v "S5WakeOnLan" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "S5WakeOnLan" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found S5WakeOnLan. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking S5WakeOnLan.
    )
    for /f %%i in ('reg query "%%a" /v "SavePowerNowEnabled" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "SavePowerNowEnabled" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found SavePowerNowEnabled. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking SavePowerNowEnabled.
    )
    for /f %%i in ('reg query "%%a" /v "ULPMode" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "ULPMode" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found ULPMode. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking ULPMode.
    )
    for /f %%i in ('reg query "%%a" /v "WakeOnLink" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeOnLink" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeOnLink. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeOnLink.
    )
    for /f %%i in ('reg query "%%a" /v "WakeOnSlot" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeOnSlot" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeOnSlot. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeOnSlot.
    )
    for /f %%i in ('reg query "%%a" /v "WakeUpModeCap" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeUpModeCap" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeUpModeCap. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeUpModeCap.
    )
    for /f %%i in ('reg query "%%a" /v "WaitAutoNegComplete" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WaitAutoNegComplete" /t REG_SZ /d "0" /f
        echo [%DATE% %TIME%] Network Tweaks: Found WaitAutoNegComplete. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WaitAutoNegComplete.
    )
    for /f %%i in ('reg query "%%a" /v "*FlowControl" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*FlowControl" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found FlowControl. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking FlowControl.
    )
    for /f %%i in ('reg query "%%a" /v "WolShutdownLinkSpeed" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WolShutdownLinkSpeed" /t REG_SZ /d "2" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WolShutdownLinkSpeed. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WolShutdownLinkSpeed.
    )
    for /f %%i in ('reg query "%%a" /v "WakeOnMagicPacketFromS5" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeOnMagicPacketFromS5" /t REG_SZ /d "2" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeOnMagicPacketFromS5. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeOnMagicPacketFromS5.
    )
    for /f %%i in ('reg query "%%a" /v "*PMNSOffload" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*PMNSOffload" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found PMNSOffload. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking PMNSOffload.
    )
    for /f %%i in ('reg query "%%a" /v "*PMARPOffload" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*PMARPOffload" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found PMARPOffload. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking PMARPOffload.
    )
    for /f %%i in ('reg query "%%a" /v "*NicAutoPowerSaver" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*NicAutoPowerSaver" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found NicAutoPowerSaver. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking NicAutoPowerSaver.
    )
    for /f %%i in ('reg query "%%a" /v "*PMWiFiRekeyOffload" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*PMWiFiRekeyOffload" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found PMWiFiRekeyOffload. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking PMWiFiRekeyOffload.
    )
    for /f %%i in ('reg query "%%a" /v "EnablePowerManagement" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePowerManagement" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnablePowerManagement. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnablePowerManagement.
    )
    for /f %%i in ('reg query "%%a" /v "ForceWakeFromMagicPacketOnModernStandby" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "ForceWakeFromMagicPacketOnModernStandby" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found ForceWakeFromMagicPacketOnModernStandby. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking ForceWakeFromMagicPacketOnModernStandby.
    )
    for /f %%i in ('reg query "%%a" /v "WakeFromS5" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeFromS5" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeFromS5. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeFromS5.
    )
    for /f %%i in ('reg query "%%a" /v "WakeOn" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeOn" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeOn. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeOn.
    )
    for /f %%i in ('reg query "%%a" /v "OBFFEnabled" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "OBFFEnabled" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found OBFFEnabled. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking OBFFEnabled.
    )
    for /f %%i in ('reg query "%%a" /v "DMACoalescing" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "DMACoalescing" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found DMACoalescing. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking DMACoalescing.
    )
    for /f %%i in ('reg query "%%a" /v "EnableSavePowerNow" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnableSavePowerNow. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnableSavePowerNow.
    )
    for /f %%i in ('reg query "%%a" /v "EnableD0PHYFlexibleSpeed" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableD0PHYFlexibleSpeed" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnableD0PHYFlexibleSpeed. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnableD0PHYFlexibleSpeed.
    )
    for /f %%i in ('reg query "%%a" /v "EnablePHYWakeUp" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePHYWakeUp" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnablePHYWakeUp. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnablePHYWakeUp.
    )
    for /f %%i in ('reg query "%%a" /v "EnablePHYFlexibleSpeed" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePHYFlexibleSpeed" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnablePHYFlexibleSpeed. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnablePHYFlexibleSpeed.
    )
    for /f %%i in ('reg query "%%a" /v "AllowAllSpeedsLPLU" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "AllowAllSpeedsLPLU" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found AllowAllSpeedsLPLU. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking AllowAllSpeedsLPLU.
    )
    for /f %%i in ('reg query "%%a" /v "*EnableDynamicPowerGating" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*EnableDynamicPowerGating" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnableDynamicPowerGating. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnableDynamicPowerGating.
    )
    for /f %%i in ('reg query "%%a" /v "EnableD3ColdInS0" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableD3ColdInS0" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnableD3ColdInS0. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnableD3ColdInS0.
    )
    for /f %%i in ('reg query "%%a" /v "LatencyToleranceReporting" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "LatencyToleranceReporting" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found LatencyToleranceReporting. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking LatencyToleranceReporting.
    )
    for /f %%i in ('reg query "%%a" /v "EnableAspm" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableAspm" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found EnableAspm. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking EnableAspm.
    )
    for /f %%i in ('reg query "%%a" /v "LTROBFF" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "LTROBFF" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found LTROBFF. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking LTROBFF.
    )
    for /f %%i in ('reg query "%%a" /v "S0MgcPkt" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "S0MgcPkt" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found S0MgcPkt. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking S0MgcPkt.
    )
    for /f %%i in ('reg query "%%a" /v "*TCPChecksumOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found TCPChecksumOffloadIPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking TCPChecksumOffloadIPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*TCPChecksumOffloadIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPChecksumOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found TCPChecksumOffloadIPv6. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking TCPChecksumOffloadIPv6.
    )
    for /f %%i in ('reg query "%%a" /v "*TCPConnectionOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPConnectionOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found TCPConnectionOffloadIPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking TCPConnectionOffloadIPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*TCPConnectionOffloadIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPConnectionOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found TCPConnectionOffloadIPv6. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking TCPConnectionOffloadIPv6.
    )
    for /f %%i in ('reg query "%%a" /v "*TCPUDPChecksumOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPUDPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found TCPUDPChecksumOffloadIPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking TCPUDPChecksumOffloadIPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*TCPUDPChecksumOffloadIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPUDPChecksumOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found TCPUDPChecksumOffloadIPv6. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking TCPUDPChecksumOffloadIPv6.
    )
    for /f %%i in ('reg query "%%a" /v "*UDPChecksumOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UDPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found UDPChecksumOffloadIPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking UDPChecksumOffloadIPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*UDPChecksumOffloadIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UDPChecksumOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found UDPChecksumOffloadIPv6. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking UDPChecksumOffloadIPv6.
    )
    for /f %%i in ('reg query "%%a" /v "*UdpRsc" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UdpRsc" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found UdpRsc. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking UdpRsc.
    )
    for /f %%i in ('reg query "%%a" /v "*UsoIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UsoIPv4" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found UsoIPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking UsoIPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*UsoIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UsoIPv6" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found UsoIPv6. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking UsoIPv6.
    )
    for /f %%i in ('reg query "%%a" /v "*RscIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*RscIPv6" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found RscIPv6. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking RscIPv6.
    )
    for /f %%i in ('reg query "%%a" /v "*RscIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*RscIPv4" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found RscIPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking RscIPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*IPsecOffloadV2IPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*IPsecOffloadV2IPv4" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found IPsecOffloadV2IPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking IPsecOffloadV2IPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*IPsecOffloadV2" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*IPsecOffloadV2" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found IPsecOffloadV2. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking IPsecOffloadV2.
    )
    for /f %%i in ('reg query "%%a" /v "*IPsecOffloadV1IPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*IPsecOffloadV1IPv4" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found IPsecOffloadV1IPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking IPsecOffloadV1IPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*LsoV1IPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*LsoV1IPv4" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found LsoV1IPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking LsoV1IPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*LsoV2IPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*LsoV2IPv4" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found LsoV2IPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking LsoV2IPv4.
    )
    for /f %%i in ('reg query "%%a" /v "*LsoV2IPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*LsoV2IPv6" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found LsoV2IPv6. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking LsoV2IPv6.
    )
    for /f %%i in ('reg query "%%a" /v "*IPChecksumOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*IPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found IPChecksumOffloadIPv4. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking IPChecksumOffloadIPv4.
    )
    for /f %%i in ('reg query "%%a" /v "WakeFromPowerOff" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeFromPowerOff" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found WakeFromPowerOff. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking WakeFromPowerOff.
    )
    for /f %%i in ('reg query "%%a" /v "LogLinkStateEvent" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "LogLinkStateEvent" /t REG_SZ /d "16" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found LogLinkStateEvent. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking LogLinkStateEvent.
    )
    for /f %%i in ('reg query "%%a" /v "*InterruptModeration" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*InterruptModeration" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found InterruptModeration. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking InterruptModeration.
    )
    for /f %%i in ('reg query "%%a" /v "ITR" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "ITR" /t REG_SZ /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Network Tweaks: Found ITR. >> "C:\Oneclick Logs\Extra\Network Tweaks Log.txt"
        echo • Tweaking ITR.
    )
)
endlocal
echo.
<nul set /p="→ Press any key to continue . . . "
pause >nul
goto :AdFeatures

:: Backup Network Settings.
:Backup_Network
set /A "NetworkBackupCounter+=1"
reg export "%~1" "%Oneclick_Backup_Folder%\Network\NetworkBackup%NetworkBackupCounter%.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Network Reg Backup %NetworkBackupCounter%: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] Network Reg Backup %NetworkBackupCounter%: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)
exit /b

:: Optional Features.
:Optional_Features
cls
color A
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════╗
echo ║ ✅ Disabling Optional Features. ║
echo ╚═════════════════════════════════╝
timeout 1 > nul
chcp 437 >nul
Powershell -NoProfile -Command ^
Disable-WindowsOptionalFeature -Online -FeatureName Client-ProjFS -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName DirectPlay -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ASP -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-CGI -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-CustomLogging -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-FTPExtensibility -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-FTPServer -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-FTPSvc -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-HostableWebCore -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionDynamic -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-HttpTracing -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-IIS6ManagementCompatibility -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-IPSecurity -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-LegacyScripts -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-LoggingLibraries -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementScriptingTools -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementService -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-Metabase -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-Performance -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-RequestMonitor -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-Security -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-ServerSideIncludes -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-URLAuthorization -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-WebDAV -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName IIS-WMICompatibility -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName LegacyComponents -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MediaPlayback -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowershellV2 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowershellV2Root -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MSMQ-Container -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MSMQ-DCOMProxy -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MSMQ-HTTP -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MSMQ-Multicast -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MSMQ-Server -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MSMQ-Triggers -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MSRDC-Infrastructure -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName NetFx3 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName Printing-Foundation-Features -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName Printing-Foundation-InternetPrinting-Client -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName Printing-Foundation-LPDPrintService -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName Printing-Foundation-LPRPortMonitor -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName Printing-PrintToPDFServices-Features -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName Printing-XPSServices-Features -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName SimpleTCP -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol-Client -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol-Deprecation -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol-Server -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName TFTP -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName TIFFIFilter -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WAS-ConfigurationAPI -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WAS-NetFxEnvironment -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WAS-ProcessModel -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WAS-WindowsActivationService -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WCF-HTTP-Activation -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WCF-HTTP-Activation45 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WCF-MSMQ-Activation45 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WCF-NonHTTP-Activation -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WCF-Pipe-Activation45 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-Activation45 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName Windows-Identity-Foundation -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName WorkFolders-Client -NoRestart -ErrorAction SilentlyContinue
chcp 65001 >nul 2>&1

echo ✔  Optional Features disabled successfully.
timeout 2 > nul
goto :AdFeatures

:: Device Manager Tweaks Warning.
:Device_Manager_Warning
cls
color C
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════════╗
echo ║ ⚠️ Device Manager Tweaks Warning. ║
echo ╚═══════════════════════════════════╝
echo ❌ Read very carefully!
echo. 
echo 1. Usage of the Device Manager Tweaks may result in bsods, or other unexpected issues. 
echo 2. Devices may behave differently certain computers!
echo. 
echo → Do you still wish to continue? (LAST WARNING)
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] Device Manager Tweaks Warning: User Chose "Yes" - Run Device Manager Tweaks. >> "C:\Oneclick Logs\Oneclick Log.txt"
    goto :Device_Manager
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] Device Manager Tweaks Warning: User Chose "No" - Skip Device Manager Tweaks. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═══════════════════════════════════════╗
    echo ║ ❌ Not Running Device Manager Tweaks. ║
    echo ╚═══════════════════════════════════════╝
    echo • Now returning to Additional Features in 2 seconds!
    timeout 2 > nul
    goto :AdFeatures
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Device_Manager_Warning
)

:: Device Manager.
:Device_Manager
cls
color A
chcp 65001 >nul 2>&1
echo ╔══════════════════════════════════════╗
echo ║ ✅ Disabling Device Manager Devices. ║
echo ╚══════════════════════════════════════╝
setlocal enabledelayedexpansion

:: Emoji Variables.
set "EmojiCheckmark=✔"
set "EmojiX=❌"

:: Device Names.
set "Device[0]=ACPI Processor Aggregator"
set "Device[1]=ACPI Thermal Zone"
set "Device[2]=ACPI Wake Alarm"
set "Device[3]=AMD Controller Emulation"
set "Device[4]=AMD Crash Defender"
set "Device[5]=AMD PSP"
set "Device[6]=Bluetooth Device (Personal Area Network)"
set "Device[7]=Bluetooth Device (RFCOMM Protocol TDI)"
set "Device[8]=Composite Bus Enumerator"
set "Device[9]=Direct memory access controller"
set "Device[10]=High Precision Event Timer"
set "Device[11]=Intel Management Engine"
set "Device[12]=Intel(R) Dynamic Application Loader Host Interface"
set "Device[13]=Intel(R) Management Engine Interface #1"
set "Device[14]=Intel(R) Management Engine WMI Provider"
set "Device[15]=Intel(R) Platform Monitoring Technology Device"
set "Device[16]=Intel(R) SMBus - 7AA3"
set "Device[17]=Intel(R) SPI (Flash) Controller - 7AA4"
set "Device[18]=Intel(R) Wireless Bluetooth(R)"
set "Device[19]=Microsoft Bluetooth Enumerator"
set "Device[20]=Microsoft Bluetooth LE Enumerator"
set "Device[21]=Microsoft Device Association Root Enumerator"
set "Device[22]=Microsoft GS Wavetable Synth"
set "Device[23]=Microsoft Hyper-V Virtualization Infrastructure Driver"
set "Device[24]=Microsoft Hypervisor Service"
set "Device[25]=Microsoft Kernel Debug Network Adapter"
set "Device[26]=Microsoft Print to PDF"
set "Device[27]=Microsoft Radio Device Enumeration Bus"
set "Device[28]=Microsoft RRAS Root Enumerator"
set "Device[29]=Microsoft Virtual Drive Enumerator"
set "Device[30]=Microsoft Windows Management Interface for ACPI"
set "Device[31]=NDIS Virtual Network Adapter Enumerator"
set "Device[32]=NVIDIA High Definition Audio"
set "Device[33]=Numeric Data Processor"
set "Device[34]=Programmable interrupt controller"
set "Device[35]=Remote Desktop Device Redirector Bus"
set "Device[36]=Resource Hub proxy device"
set "Device[37]=Root Print Queue"
set "Device[38]=System Timer"
set "Device[39]=UMBus Root Bus Enumerator"
set "Device[40]=WAN Miniport (IKEv2)"
set "Device[41]=WAN Miniport (IP)"
set "Device[42]=WAN Miniport (IPv6)"
set "Device[43]=WAN Miniport (L2TP)"
set "Device[44]=WAN Miniport (Network Monitor)"
set "Device[45]=WAN Miniport (PPPOE)"
set "Device[46]=WAN Miniport (PPTP)"
set "Device[47]=WAN Miniport (SSTP)"
chcp 437 >nul

:: Get all existing devices in one PS call.
for /f "delims=" %%D in ('Powershell -NoProfile -Command "Get-PnpDevice | Select-Object -ExpandProperty FriendlyName"') do (
    set "Existing[%%D]=1"
    echo [%DATE% %TIME%] Found Device: %%D >> "C:\Oneclick Logs\Extra\Found Device Manager Devices Log.txt"
)

:: Disable existing devices.
for /L %%i in (0,1,47) do (
    if defined Existing[!Device[%%i]!] (
        chcp 437 >nul
        Powershell -NoProfile -Command "try { Get-PnpDevice -FriendlyName '!Device[%%i]!' -ErrorAction Stop | Disable-PnpDevice -Confirm:$false -ErrorAction Stop; exit 0 } catch { exit 1 }"
        if !ERRORLEVEL! EQU 0 (
            echo [%DATE% %TIME%] Device Manager: Successfully Disabled: !Device[%%i]!. >> "C:\Oneclick Logs\Extra\Disable Device Manager Devices Log.txt"
            chcp 65001 >nul 2>&1
            echo !EmojiCheckmark!  Disabled: !Device[%%i]!.
        ) else (
            echo [%DATE% %TIME%] Device Manager: Failed to disable: !Device[%%i]! - May already be disabled. >> "C:\Oneclick Logs\Extra\Disable Device Manager Devices Log.txt"
        )
    )
)
endlocal
chcp 65001 >nul 2>&1

echo ✔  Device Manager tweaked successfully.
timeout 2 > nul
goto :AdFeatures

:: Audio Bloat Remover Warning.
:Audio_Bloat_Warning
cls
color C
chcp 65001 >nul 2>&1
echo ╔═════════════════════════════════╗
echo ║ ⚠️ Audio Bloat Remover Warning. ║
echo ╚═════════════════════════════════╝
echo ❌ Read very carefully!
echo. 
echo 1. Usage of the Audio Bloat Remover may result in Sound or Audio related issues.
echo 2. You may also completely lose System Audio!
echo. 
echo → Do you still wish to continue? (LAST WARNING)
set /p choice=Enter (Y/N): 
if /i "%choice%"=="Y" (
    echo [%DATE% %TIME%] Audio Bloat Remover Warning: User Chose "Yes" - Run Audio Bloat Remover. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color A
    echo ╔═════════════════════════════════╗
    echo ║ ✅ Running Audio Bloat Remover. ║
    echo ╚═════════════════════════════════╝
    echo • Automatically executing Audio Bloat Remover with NSudo.
    "C:\Oneclick Tools\NSudo\NSudoLG.exe" -ShowWindowMode:Show -U:T -P:E "C:\Oneclick Tools\Audio Bloat Remover\Audio Bloat Remover V1.0.bat" >nul 2>&1
    echo Continuing in 3 seconds...
    timeout 3 > nul
    goto :AdFeatures
) else if /i "%choice%"=="N" (
    echo [%DATE% %TIME%] Audio Bloat Remover Warning: User Chose "No" - Skip Audio Bloat Remover. >> "C:\Oneclick Logs\Oneclick Log.txt"
    cls
    color C
    echo ╔═════════════════════════════════════╗
    echo ║ ❌ Not Running Audio Bloat Remover. ║
    echo ╚═════════════════════════════════════╝
    echo • Now returning to Additional Features in 2 seconds!
    timeout 2 > nul
    goto :AdFeatures
) else (
    cls
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    timeout 2 > nul
    goto :Audio_Bloat_Warning
)

:: Discord.
:Discord
cls
color A
chcp 65001 >nul 2>&1
echo ╔══════════════════════════╗
echo ║ ✅ Opening Discord Link. ║
echo ╚══════════════════════════╝
echo • Browser Required!
timeout 2 > nul
start "" "https://discord.gg/8NqDSMzYun"
echo.
<nul set /p="→ Press any key to continue . . . "
pause >nul
goto :Extras

:: Restart.
:Restart
cls
color A
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════════════════════════════╗
echo ║ ✅ Restarting your PC. (Required to apply all tweaks) ║
echo ╚═══════════════════════════════════════════════════════╝
echo • Restarting your PC, in 5 seconds.
sc config TrustedInstaller start=disabled >nul 2>&1
rd /s /q "C:\Oneclick Tools\Edge Remover"
rd /s /q "C:\Oneclick Tools\OOshutup10"
rd /s /q "C:\Oneclick Tools\Power Plans"
call :Oneclick_Log_End
timeout 5 > nul
shutdown /r /t 0
exit 

:: Oneclick Logging Start. (The starting log of Oneclick + Log Header)
:Oneclick_Log_Start
>> "C:\Oneclick Logs\Oneclick Log.txt" 2>&1 (
echo  ▒█████   ███▄    █ ▓█████  ▄████▄   ██▓     ██▓ ▄████▄   ██ ▄█▀
echo ▒██▒  ██▒ ██ ▀█   █ ▓█   ▀ ▒██▀ ▀█  ▓██▒    ▓██▒▒██▀ ▀█   ██▄█▒ 
echo ▒██░  ██▒▓██  ▀█ ██▒▒███   ▒▓█    ▄ ▒██░    ▒██▒▒▓█    ▄ ▓███▄░ 
echo ▒██   ██░▓██▒  ▐▌██▒▒▓█  ▄ ▒▓▓▄ ▄██▒▒██░    ░██░▒▓▓▄ ▄██▒▓██ █▄ 
echo ░ ████▓▒░▒██░   ▓██░░▒████▒▒ ▓███▀ ░░██████▒░██░▒ ▓███▀ ░▒██▒ █▄
echo ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ░▒ ▒  ░░ ▒░▓  ░░▓  ░ ░▒ ▒  ░▒ ▒▒ ▓▒
echo   ░ ▒ ▒░ ░ ░░   ░ ▒░ ░ ░  ░  ░  ▒   ░ ░ ▒  ░ ▒ ░  ░  ▒   ░ ░▒ ▒░
echo ░ ░ ░ ▒     ░   ░ ░    ░   ░          ░ ░    ▒ ░░        ░ ░░ ░ 
echo     ░ ░           ░    ░  ░░ ░          ░  ░ ░  ░ ░      ░  ░   
echo                            ░                    ░               
echo ________________________________________________________________ 
echo.                                                          
echo [%DATE% %TIME%] Oneclick %Current_Version% Started.
)
exit /b

:: Oneclick Logging End. (The end log of Oneclick)
:Oneclick_Log_End
>> "C:\Oneclick Logs\Oneclick Log.txt" 2>&1 (
echo [%DATE% %TIME%] Oneclick %Current_Version% Ended.
echo ________________________________________________________________ 
echo. 
)
exit /b
