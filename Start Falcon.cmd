@echo off
rem ---------------------------------------------------------------------------
rem  Falcon Optimizer - run straight from this folder, no installer needed.
rem  Double-click. It asks for administrator rights once (Falcon changes
rem  system settings), installs its runtime on first launch, then starts.
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"
title Falcon Optimizer

net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:ComSpec -ArgumentList '/c', ('\"' + '%~f0' + '\"') -Verb RunAs" 2>nul
  if errorlevel 1 (
    echo Administrator approval is required to run Falcon Optimizer.
    pause
  )
  exit /b
)

rem Some terminals (e.g. VS Code) set this, which would make Electron run as plain Node.
set "ELECTRON_RUN_AS_NODE="
set "ELECTRON=%~dp0node_modules\electron\dist\electron.exe"
if not exist "%ELECTRON%" (
  where npm >nul 2>&1
  if errorlevel 1 (
    echo.
    echo  First-time setup needs Node.js ^(LTS^) to download the app runtime.
    echo  Install it from https://nodejs.org and double-click this file again.
    echo.
    start "" "https://nodejs.org/en/download"
    pause
    exit /b 1
  )
  echo.
  echo  First launch: downloading the Falcon runtime ^(one time, about 1-2 minutes^)...
  echo.
  call npm install --no-audit --no-fund
  if not exist "%ELECTRON%" call node "%~dp0node_modules\electron\install.js"
  if not exist "%ELECTRON%" (
    echo Setup failed. Check your internet connection and try again.
    pause
    exit /b 1
  )
)

start "" "%ELECTRON%" "%~dp0."
exit /b 0
