# FalconLibrary Canonical Layout

Canonical tool root for all `falconlib.run` cards:

- `tools/FalconLibrary/`

## Required executable locations

- `tools/FalconLibrary/NSudo/NSudoLG.exe`
- `tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe`
- `tools/FalconLibrary/DPC Checker/dpclat.exe`
- `tools/FalconLibrary/OOshutup10/OOSU10.exe`
- `tools/FalconLibrary/Nvidia/Nvidia Profile Inspector/nvidiaProfileInspector.exe`
- `tools/FalconLibrary/Edge Remover/setup.exe`

## Companion files copied with tool families

- `tools/FalconLibrary/NSudo/1- What's NSudo.txt`
- `tools/FalconLibrary/Timer Resolution/1- What's SetTimerResolution.txt`
- `tools/FalconLibrary/DPC Checker/1- What's dpclat.txt`
- `tools/FalconLibrary/OOshutup10/FalconOOshutup10 V2.cfg`
- `tools/FalconLibrary/Nvidia/Nvidia Profile Inspector/NovaOS.nip`
- `tools/FalconLibrary/Edge Remover/1- What's Setup.txt`

## Enforcement

- `scripts/run-action.ps1` resolves `falconlib.run.toolPath` strictly against repo root (dev) and `resources/app.asar.unpacked` (packaged).
- `scripts/qa_links.js` fails the build if any `falconlib.run.toolPath` is missing or points to legacy `FalconLibrary/**` roots.
