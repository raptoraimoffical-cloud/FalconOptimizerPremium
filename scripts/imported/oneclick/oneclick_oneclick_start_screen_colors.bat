@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Oneclick_Start_Screen_Colors
echo.
set "Colors=201 129 39 51 46 220 214 208 196"
chcp 65001 >nul 2>&1
del "%Temp%\Skip.Loop" >nul 2>&1
start "" /b cmd /c "pause >nul & echo.>"%Temp%\Skip.Loop""
echo.
echo [Falcon] Done.
endlocal
exit /b 0