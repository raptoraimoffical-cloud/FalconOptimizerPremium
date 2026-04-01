# FalconOptimizer Premium Integration Report

## 1.1 FalconLibrary inventory (actual paths)

Scan scope:
- `tools/FalconLibrary/**`
- `FalconLibrary/**`
- `FalconLibrary/FalconLibrary/**`

Classification legend:
- **Integrated**: referenced by at least one `falconlib.run` step.
- **Not linked**: no card references this tool.
- **Linked but broken path**: card reference exists, but target file is missing in that location.
- **Duplicate**: same relative tool appears in multiple FalconLibrary roots.

### Current canonical root (`tools/FalconLibrary/**`)

| Tool path | Status |
|---|---|
| tools/FalconLibrary/Audio Bloat Remover/Audio Bloat Remover V1.0.bat | Integrated |
| tools/FalconLibrary/Autologger Destroyer/FalconLibrary Autologger Destroyer V1.0.bat | Integrated |
| tools/FalconLibrary/Browser Download/Browser Downloader V1.0.bat | Integrated |
| tools/FalconLibrary/DPC Checker/dpclat.exe | Integrated |
| tools/FalconLibrary/Edge Remover/setup.exe | Integrated |
| tools/FalconLibrary/Nvidia/Nvidia Container/Nvidia Container OFF.bat | Integrated |
| tools/FalconLibrary/Nvidia/Nvidia Container/Nvidia Container ON.bat | Integrated |
| tools/FalconLibrary/Nvidia/Nvidia Profile Inspector/nvidiaProfileInspector.exe | Integrated |
| tools/FalconLibrary/NSudo/NSudoLG.exe | Not linked (allowlisted runtime dependency for TI elevation) |
| tools/FalconLibrary/OOshutup10/OOSU10.exe | Integrated |
| tools/FalconLibrary/Process Destroyer/FalconLibrary Process Destroyer Extreme V2.6.bat | Integrated |
| tools/FalconLibrary/Process Destroyer/FalconLibrary Process Destroyer V2.6.bat | Integrated |
| tools/FalconLibrary/Task Destroyer/FalconLibrary Task Destroyer V1.3.bat | Integrated |
| tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe | Integrated |
| tools/FalconLibrary/Update Disabler/FalconLibrary Update Disabler V1.2.bat | Integrated |

### Legacy roots and duplicate status

All executable tools found in `FalconLibrary/**` and `FalconLibrary/FalconLibrary/**` are duplicates of the canonical `tools/FalconLibrary/**` tree.

Examples of required duplicates detected:
- `Timer Resolution/SetTimerResolution.exe` (duplicate roots)
- `DPC Checker/dpclat.exe` (duplicate roots)
- `OOshutup10/OOSU10.exe` (duplicate roots)
- `Nvidia/Nvidia Profile Inspector/nvidiaProfileInspector.exe` (duplicate roots)
- `Edge Remover/setup.exe` (duplicate roots)
- `NSudo/NSudoLG.exe` (duplicate roots)

## 1.2 Tweak engine usage summary

- Total tweak items scanned: **4,795**
- Step type count (top):
  - `ps.run`: 2513
  - `cmd.run`: 1924
  - `registry.set`: 1780
  - `registry.remove`: 1558
  - `service.startup`: 1170
  - `registry.check`: 854
  - `task`: 557

### `falconlib.run` cards (current)

| id | name | category | toolPath | elevation | source file |
|---|---|---|---|---|---|
| falcon.audio.bloat_remover.run | Audio Bloat Remover | Apps / Utilities | tools/FalconLibrary/Audio Bloat Remover/Audio Bloat Remover V1.0.bat | admin | tweaks/utilities.json |
| falcon.timer_resolution.apply | Timer Resolution (Apply) | Apps / Utilities | tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe | admin | tweaks/utilities.json |
| processlab.process_destroyer.standard | Process Destroyer (Standard) | Process Lab | tools/FalconLibrary/Process Destroyer/FalconLibrary Process Destroyer V2.6.bat | trustedinstaller | tweaks/falconlibrary.integration.json |
| processlab.process_destroyer.extreme | Process Destroyer (Extreme) | Process Lab | tools/FalconLibrary/Process Destroyer/FalconLibrary Process Destroyer Extreme V2.6.bat | trustedinstaller | tweaks/falconlibrary.integration.json |
| processlab.task_destroyer.apply | Task Destroyer | Process Lab | tools/FalconLibrary/Task Destroyer/FalconLibrary Task Destroyer V1.3.bat | trustedinstaller | tweaks/falconlibrary.integration.json |
| windows.update_disabler.apply | Update Disabler | Windows Updates | tools/FalconLibrary/Update Disabler/FalconLibrary Update Disabler V1.2.bat | trustedinstaller | tweaks/falconlibrary.integration.json |
| privacy.autologger_destroyer.apply | Autologger Destroyer | Telemetry / Logging | tools/FalconLibrary/Autologger Destroyer/FalconLibrary Autologger Destroyer V1.0.bat | trustedinstaller | tweaks/falconlibrary.integration.json |
| gpu.nvidia_container.off | NVIDIA Container OFF | GPU | tools/FalconLibrary/Nvidia/Nvidia Container/Nvidia Container OFF.bat | trustedinstaller | tweaks/falconlibrary.integration.json |
| gpu.nvidia_container.off (revert) | NVIDIA Container OFF | GPU | tools/FalconLibrary/Nvidia/Nvidia Container/Nvidia Container ON.bat | trustedinstaller | tweaks/falconlibrary.integration.json |
| utilities.browser_downloader.apply | Browser Downloader | Utilities | tools/FalconLibrary/Browser Download/Browser Downloader V1.0.bat | none | tweaks/falconlibrary.integration.json |
| utilities.dpclat.run | DPC Latency Checker | Utilities | tools/FalconLibrary/DPC Checker/dpclat.exe | none | tweaks/falconlibrary.integration.json |
| privacy.oosu10.apply | O&O ShutUp10++ | Privacy / Telemetry | tools/FalconLibrary/OOshutup10/OOSU10.exe | admin | tweaks/falconlibrary.integration.json |
| gpu.nvidia_profile_inspector.apply | NVIDIA Profile Inspector | GPU | tools/FalconLibrary/Nvidia/Nvidia Profile Inspector/nvidiaProfileInspector.exe | none | tweaks/falconlibrary.integration.json |
| debloat.edge_remover.apply | Edge Remover | Debloat / Browsers | tools/FalconLibrary/Edge Remover/setup.exe | admin | tweaks/falconlibrary.integration.json |

## 1.3 Broken links list (explicit)

- **Historical (confirmed in repo before consolidation):**
  - `falcon.timer_resolution.apply` linked to `tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe`, while the executable existed only under `FalconLibrary/FalconLibrary/Timer Resolution/SetTimerResolution.exe`.
- **Now corrected:**
  - Canonical executable exists at `tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe` and link resolves.

- **Historically present but not referenced (now integrated):**
  - `dpclat.exe` (DPC Checker)
  - `OOSU10.exe` (O&O ShutUp10)
  - `nvidiaProfileInspector.exe`
  - `Edge Remover/setup.exe`
  - `SetTimerResolution.exe` (canonicalized + linked)

- **NSudo duplicate note:**
  - `NSudoLG.exe` existed under both `FalconLibrary/NSudo/` and `FalconLibrary/FalconLibrary/NSudo/`.
  - Canonical runtime path is now `tools/FalconLibrary/NSudo/NSudoLG.exe`.
