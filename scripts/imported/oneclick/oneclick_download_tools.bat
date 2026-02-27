@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Download_Tools
echo.
setlocal
set "FileURL=https://github.com/QuakedK/Oneclick/raw/refs/heads/main/Downloads/V8.0/OneclickTools.zip"
set "FileName=Oneclick Tools.zip"
set "ExtractFolder=C:\Oneclick Tools"
set "DownloadsFolder=C:\"
curl -s -L "%FileURL%" -o "%DownloadsFolder%\%FileName%"
if %errorlevel% equ 0 (
    mkdir "%ExtractFolder%" >nul 2>&1
    pushd "%ExtractFolder%" >nul 2>&1
    tar -xf "%DownloadsFolder%\%FileName%" --strip-components=1 >nul 2>&1
    popd >nul 2>&1
    del /q "C:\Oneclick Tools.zip" >nul 2>&1
    endlocal & goto :Oneclick_Backup_Folder_Check
) else (
    endlocal & goto :Tools_Download_Failed
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0