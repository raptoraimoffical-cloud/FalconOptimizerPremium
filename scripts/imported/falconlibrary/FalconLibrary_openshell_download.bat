@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: OpenShell_Download
echo.
setlocal
color A
chcp 65001 >nul 2>&1
mkdir "C:\FalconLibrary Tools\OpenShell" >nul 2>&1
set "FileURL1=https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.196/OpenShellSetup_4_4_196.exe"
set "FileName1=OpenShellSetup_4_4_196.exe"
set "FileURL2=https://github.com/FalconK/FalconLibrary/raw/refs/heads/main/Downloads/V8.0/OpenShellTheme.xml"
set "FileName2=OpenShellTheme.xml"
set "DownloadsFolder=C:\FalconLibrary Tools\OpenShell"
curl -s -L "%FileURL1%" -o "%DownloadsFolder%\%FileName1%"
curl -s -L "%FileURL2%" -o "%DownloadsFolder%\%FileName2%"
if exist "%DownloadsFolder%\%FileName1%" (  
   echo.
   echo.
   start "" "C:\FalconLibrary Tools\OpenShell\OpenShellSetup_4_4_196.exe" /qn ADDLOCAL=StartMenu
   "C:\Program Files\Open-Shell\StartMenu.exe" -xml "C:\FalconLibrary Tools\OpenShell\OpenShellTheme.xml"
   <nul set /p="→ Press any key to continue . . . "
   pause >nul
   rd /s /q "C:\FalconLibrary Tools\OpenShell" >nul 2>&1
   goto :GPU_Tweaks
) else (
   goto :OpenShell_Download_Failed
)
endlocal
echo.
echo [Falcon] Done.
endlocal
exit /b 0