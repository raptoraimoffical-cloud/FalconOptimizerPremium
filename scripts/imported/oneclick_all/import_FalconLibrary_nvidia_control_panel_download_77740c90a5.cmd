@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel" /v HasLUAShield /t REG_SZ /d "" /f >nul 2>&1
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel" /v MUIVerb /t REG_SZ /d "Nvidia Control Panel" /f >nul 2>&1
   reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\Nvidia Control Panel\command" /ve /t REG_SZ /d "C:\Oneclick Tools\Nvidia\Nvidia Control Panel\nvcplui.exe" /f >nul 2>&1
   reg add "HKCR\Directory\Background\shellex\ContextMenuHandlers\NvCplDesktopContext" /ve /t REG_SZ /d "{}" /f >nul 2>&1
endlocal
