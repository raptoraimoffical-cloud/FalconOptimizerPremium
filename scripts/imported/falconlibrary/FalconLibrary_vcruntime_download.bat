@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: VCRuntime_Download
echo.
color C
chcp 65001 >nul 2>&1
mkdir "C:\VC Redist" >nul 2>&1
set "FileURL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "FileName=VC_redist.x64.exe"
set "DownloadsFolder=C:\VC Redist"
curl -s -L "%FileURL%" -o "%DownloadsFolder%\%FileName%"
if exist "%DownloadsFolder%\%FileName%" (
   echo.
   start "" "C:\VC Redist\VC_redist.x64.exe" /install /passive /norestart
   <nul set /p="→ Press any key to continue . . . "
   pause >nul
   rd /s /q "C:\VC Redist" >nul 2>&1
   goto :UCPD_Check
) else (
   rd /s /q "C:\VC Redist" >nul 2>&1
   goto :VCRuntime_Download_Failed
)
endlocal
echo.
echo [Falcon] Done.
endlocal
exit /b 0