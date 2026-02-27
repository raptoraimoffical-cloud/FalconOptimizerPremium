@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Nvidia_Control_Panel_Download
echo.
setlocal
color A
chcp 65001 >nul 2>&1
mkdir "C:\Oneclick Tools\Nvidia\Nvidia Control Panel" >nul 2>&1
set "FileURL=https://github.com/QuakedK/Oneclick/raw/refs/heads/main/Downloads/V8.0/nvcplui.exe"
set "FileName=nvcplui.exe"
set "DownloadsFolder=C:\Oneclick Tools\Nvidia\Nvidia Control Panel"
curl -s -L "%FileURL%" -o "%DownloadsFolder%\%FileName%"
if exist "%DownloadsFolder%\%FileName%" (  
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel" /v HasLUAShield /t REG_SZ /d "" /f >nul 2>&1
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel" /v MUIVerb /t REG_SZ /d "Nvidia Control Panel" /f >nul 2>&1
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel\command" /ve /t REG_SZ /d "C:\Oneclick Tools\Nvidia\Nvidia Control Panel\nvcplui.exe" /f >nul 2>&1
   reg add "HKCR\Directory\Background\shellex\ContextMenuHandlers\NvCplDesktopContext" /ve /t REG_SZ /d "{}" /f >nul 2>&1
   echo.
   goto :Nvidia_GPU_Tweaks
) else (
   echo.
   goto :Nvidia_Control_Panel_Download_Failed
)
endlocal
echo.
echo [Falcon] Done.
endlocal
exit /b 0