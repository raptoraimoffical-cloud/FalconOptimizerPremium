# FalconLibrary Canonical Layout

## Canonical root

`tools/FalconLibrary/` is the only supported FalconLibrary runtime root.

## Why

Previous builds contained three roots (`tools/FalconLibrary`, `FalconLibrary`, and `FalconLibrary/FalconLibrary`) which caused nondeterministic path resolution and broken runtime links in packaged/dev environments.

## Final canonical tool tree

- tools/FalconLibrary/Audio Bloat Remover/Audio Bloat Remover V1.0.bat
- tools/FalconLibrary/Autologger Destroyer/FalconLibrary Autologger Destroyer V1.0.bat
- tools/FalconLibrary/Browser Download/Browser Downloader V1.0.bat
- tools/FalconLibrary/DPC Checker/dpclat.exe
- tools/FalconLibrary/Edge Remover/setup.exe
- tools/FalconLibrary/Nvidia/Nvidia Container/Nvidia Container OFF.bat
- tools/FalconLibrary/Nvidia/Nvidia Container/Nvidia Container ON.bat
- tools/FalconLibrary/Nvidia/Nvidia Profile Inspector/nvidiaProfileInspector.exe
- tools/FalconLibrary/NSudo/NSudoLG.exe
- tools/FalconLibrary/OOshutup10/OOSU10.exe
- tools/FalconLibrary/Process Destroyer/FalconLibrary Process Destroyer Extreme V2.5.bat
- tools/FalconLibrary/Process Destroyer/FalconLibrary Process Destroyer V2.5.bat
- tools/FalconLibrary/Task Destroyer/FalconLibrary Task Destroyer V1.3.bat
- tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe
- tools/FalconLibrary/Update Disabler/FalconLibrary Update Disabler V1.2.bat

## Legacy roots

`FalconLibrary/**` and `FalconLibrary/FalconLibrary/**` are treated as legacy/ignored for resolution.

Runner changes enforce deterministic lookup to:
1) absolute path (if provided),
2) `<repoRoot>/<toolPath>`,
3) `<dataRoot>/<toolPath>`.

No silent fallback probing of legacy FalconLibrary roots remains.
