@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
del "%Temp%\Skip.Loop" >nul 2>&1
start "" /b cmd /c "pause >nul & echo.>"%Temp%\Skip.Loop""
endlocal
