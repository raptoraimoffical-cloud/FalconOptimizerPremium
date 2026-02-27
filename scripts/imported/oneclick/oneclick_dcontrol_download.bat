@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Dcontrol_Download
echo.
color A
chcp 65001 >nul 2>&1
mkdir "C:\Dcontrol" >nul 2>&1
set "FileURL=https://github.com/QuakedK/Oneclick/raw/refs/heads/main/Downloads/V8.0/dControl.exe"
set "FileName=dControl.exe"
set "DownloadsFolder=C:\Dcontrol"
curl -s -L "%FileURL%" -o "%DownloadsFolder%\%FileName%"
if exist "%DownloadsFolder%\%FileName%" (
   echo.
   echo.
   echo.
   start "" "C:\Dcontrol\dControl.exe"
   echo.
   <nul set /p="%White%Once all steps are completed, Press any key to continue . . . "
   pause >nul
   taskkill /IM dControl.exe /F >nul 2>&1
   rd /s /q "C:\Dcontrol" >nul 2>&1
   goto :Dcontrol_Run_Check
) else (
   rd /s /q "C:\Dcontrol" >nul 2>&1
   goto :Dcontrol_Download_Failed
)
endlocal
echo.
echo [Falcon] Done.
endlocal
exit /b 0