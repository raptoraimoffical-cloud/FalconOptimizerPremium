# Integration Audit

## Scope
This audit validates FalconLibrary tool linking, runner behavior, QA enforcement, and packaging coverage.

## Canonical tool root
- Canonical root: `tools/FalconLibrary/`
- Verified required executables now present:
  - `tools/FalconLibrary/NSudo/NSudoLG.exe`
  - `tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe`
  - `tools/FalconLibrary/DPC Checker/dpclat.exe`
  - `tools/FalconLibrary/OOshutup10/OOSU10.exe`
  - `tools/FalconLibrary/Nvidia/Nvidia Profile Inspector/nvidiaProfileInspector.exe`
  - `tools/FalconLibrary/Edge Remover/setup.exe`

## Tweak link validation
- Manifest scanned: `tweaks/_manifest.json`
- All `falconlib.run` entries resolve to on-disk files under `tools/FalconLibrary/**`.
- No legacy `FalconLibrary/**` references were detected in `falconlib.run.toolPath` entries.

## Runner validation
- `scripts/run-action.ps1` retains one execution handler per actionable type (`registry.set`, `service.startup`) inside the execute switch.
- TrustedInstaller execution resolves NSudo only from canonical path and now throws:
  - `NSudo not found at tools/FalconLibrary/NSudo/NSudoLG.exe`

## Packaging safety
- `package.json` keeps `build.asarUnpack` entries for `tools/**` and `scripts/**`, ensuring runtime access to FalconLibrary tools in packaged builds.

## QA gate
- `scripts/qa_links.js` enforces:
  - every `falconlib.run.toolPath` exists
  - no legacy root prefixes are used
- Latest report: `QA_LINKS_REPORT.txt` (generated from script output).
