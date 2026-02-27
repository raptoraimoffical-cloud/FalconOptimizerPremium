@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: AMD_GPU_Tweaks
echo.
color C
chcp 65001 >nul 2>&1
setlocal
for /f "tokens=*" %%c in (
	'reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "Radeon" /t REG_SZ /s 2^>nul ^| findstr /l "}"'
) do (
	set gpu_key=%%c
)
echo.
mkdir "%Oneclick_Backup_Folder%\GPU" >nul 2>&1
reg export "%gpu_key%" "%Oneclick_Backup_Folder%\GPU\AMD.reg" /y >nul 2>&1
if errorlevel 1 (
) else ( 
)
reg add "%gpu_key%" /v "PP_Force3DPerformanceMode" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "PP_ForceHighDPMLevel" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxCoarseGrainLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxCpLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxMediumGrainLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableGfxRlcLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableDrmLightSleep" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "KMD_RadeonBoostEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
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
reg add "%gpu_key%" /v "DalPSRSkipCRTCPowerDown" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "PP_GPUPowerDownEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableAspmSWL1" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableAspmL0s" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableAspmL1" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableAspmL0s" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableAspmL1" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableAspmL1SS" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "AspmL0sTimeout" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "AspmL1Timeout" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableClkReqSupport" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableFBCSupport" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "DisableForceUvdToSclk" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "%gpu_key%" /v "PipeTilingDowngrade" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "GroupSizeDowngrade" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "RowTilingDowngrade" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "SampleSplitDowngrade" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "%gpu_key%" /v "EnableSpreadSpectrum" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\AMD\CN" /v "PowerSaverAutoEnable_CUR" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Services\amdwddmg" /v "ChillEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\AMD\CN" /v "AutoUpdateTriggered" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\AMD\CN" /v "AutoUpdate" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\AMD\CN" /v "AnimationEffect" /t REG_SZ /d "false" /f >nul 2>&1
goto :Latency_Tweaks
echo.
echo [Falcon] Done.
endlocal
exit /b 0