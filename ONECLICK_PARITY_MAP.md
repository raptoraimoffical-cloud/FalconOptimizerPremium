# ONECLICK → Premium parity map

## 1) Oneclick inventory (BoostPack 8.3 menu-derived)

- Download the Latest Oneclick Version - *Opens the github page*
- Continue Anyway - *Allows the user to run Oneclick regardless*
- Exit - *Closes Oneclick*
- Github - *Explains the supported Windows versions in detail*
- Retry - *Tries to download VCRuntimes again*
- Download Manually - *Open's the Microsoft download page*
- Retry - *Tries to download the tools folder again*
- Download Manually - *Open's Github page*
- Disable - *Disables Windows Defender*
- Keep Enabled - *Keeps Windows Defender Enabled*
- Learn More - *Explains Defender Options*
- Retry - *Tries to download Dcontrol again*
- Download Manually - *Open's the Sordum download page*
- Continue Anyway - *Allows the user to skip disabling Defender*
- Keep Search - *Allows the user to keep the basic windows search*
- Remove Search - *Removes Search, installing a lighter alternative*
- More Info - *Explains Search Options*
- Retry - *Tries to download OpenShell again*
- Download Manually - *Open''s the Github download page*
- Continue Anyway - *Allows the user to continue with Oneclick regardless*
- Nvidia
- AMD
- Skip
- Retry - *Tries to download Nvidia Control Panel again*
- FPS - 42 Decimal - 2A Hexadecimal
- Latency - 36 Decimal - 24 Hexadecimal
- Balanced - 26 Decimal - 1A Hexadecimal
- Custom Value.
- Learn More.
- Skip.
- Timer Res 0.500ms
- Timer Res 0.504ms
- Timer Res 0.507ms
- Quaked Ultimate Performance.
- Quaked Ultimate Performance Idle Off.

## 2) Premium inventory

Total cards parsed: 4788

### FalconLibrary files under tools/FalconLibrary

- `tools/FalconLibrary/Autologger Destroyer/FalconLibrary Autologger Destroyer V1.0.bat`
- `tools/FalconLibrary/Autologger Destroyer/1- What's Autologger Destroyer.txt`
- `tools/FalconLibrary/Audio Bloat Remover/Audio Bloat Remover V1.0.bat`
- `tools/FalconLibrary/Audio Bloat Remover/1- What's Audio Bloat Remover.txt`
- `tools/FalconLibrary/Wallpaper Lab/1- What's FalconLibrary Wallpaper.txt`
- `tools/FalconLibrary/Wallpaper Lab/Place Wallpapers Here/README.txt`
- `tools/FalconLibrary/Process Destroyer/1- What's Process Destroyer.txt`
- `tools/FalconLibrary/Process Destroyer/FalconLibrary Process Destroyer V2.5.bat`
- `tools/FalconLibrary/Process Destroyer/FalconLibrary Process Destroyer Extreme V2.5.bat`
- `tools/FalconLibrary/ISO Logo Changer/1- What's Basebrd.txt`
- `tools/FalconLibrary/Browser Download/Browser Downloader V1.0.bat`
- `tools/FalconLibrary/Browser Download/1- What's Browser Downloader.txt`
- `tools/FalconLibrary/Nvidia/Nvidia Container/Nvidia Container OFF.bat`
- `tools/FalconLibrary/Nvidia/Nvidia Container/1- What's Nvidia Container.txt`
- `tools/FalconLibrary/Nvidia/Nvidia Container/Nvidia Container ON.bat`
- `tools/FalconLibrary/Nvidia/Nvidia Profile Inspector/NovaOS.nip`
- `tools/FalconLibrary/Nvidia/Nvidia Profile Inspector/1- What's Nvidia Profile Inspector.txt`
- `tools/FalconLibrary/OOshutup10/FalconOOshutup10 V2.cfg`
- `tools/FalconLibrary/OOshutup10/1- What's OOSU10.txt`
- `tools/FalconLibrary/Edge Remover/1- What's Setup.txt`
- `tools/FalconLibrary/Power Plans/Falcon Ultimate Performance.pow`
- `tools/FalconLibrary/Power Plans/Falcon Ultimate Performance Idle Off.pow`
- `tools/FalconLibrary/Power Plans/1- What's Ultimate Performance Pows.txt`
- `tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe`
- `tools/FalconLibrary/Timer Resolution/1- What's SetTimerResolution.txt`
- `tools/FalconLibrary/Update Disabler/FalconLibrary Update Disabler V1.2.bat`
- `tools/FalconLibrary/Update Disabler/1- What's Update Disabler.txt`
- `tools/FalconLibrary/Task Destroyer/1- What's Task Destroyer.txt`
- `tools/FalconLibrary/Task Destroyer/FalconLibrary Task Destroyer V1.3.bat`
- `tools/FalconLibrary/DPC Checker/1- What's dpclat.txt`
- `tools/FalconLibrary/NSudo/1- What's NSudo.txt`
- `tools/FalconLibrary/NSudo/NSudoLG.exe`

## 3) Parity table (core FalconLibrary tool parity)

| Oneclick Feature | Oneclick tool/script | Premium destination | Premium tweak id | Elevation | Verification |
|---|---|---|---|---|---|
| Process Destroyer | Process-Destroyer-V2.5.bat | Process Lab | processlab.process_destroyer.standard | trustedinstaller | cmd.run tasklist sanity check |
| Process Destroyer Extreme | Process-Destroyer-Extreme-V2.5.bat | Process Lab | processlab.process_destroyer.extreme | trustedinstaller | cmd.run tasklist sanity check |
| Task Destroyer | FalconLibrary Task Destroyer V1.3.bat | Process Lab | processlab.task_destroyer.apply | trustedinstaller | task.check on core appraiser task disabled |
| Update Disabler | FalconLibrary Update Disabler V1.2.bat | Windows Updates | windows.update_disabler.apply | trustedinstaller | service.startup verify (wuauserv Disabled) |
| Autologger Destroyer | FalconLibrary Autologger Destroyer V1.0.bat | Telemetry / Logging | privacy.autologger_destroyer.apply | trustedinstaller | registry.check Start=0 (continueOnError) |
| Nvidia Container OFF/ON | Nvidia Container OFF.bat / ON.bat | GPU | gpu.nvidia_container.off | trustedinstaller | service.startup verify on NVDisplay.ContainerLocalSystem |
| Browser Downloader | Browser Downloader V1.0.bat | Utilities | utilities.browser_downloader.apply | none | tool launch success (exit code) |
| Timer Resolution | SetTimerResolution.exe | Utilities | utility.timerres.apply__utilities | none | process check by status card + path corrected |

No core FalconLibrary tool is left unmapped in Premium cards after this pass.
