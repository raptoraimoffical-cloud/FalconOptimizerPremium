# BoostPack / OneClick Integration Notes

BoostPack content is represented in tweak libraries and manifest-driven execution.

## Integrated tweak sources
- `tweaks/core.boostpack.registry.json`
- `tweaks/debloat.services.boostpack.json`
- `tweaks/hardware.gpu.boostpack.json`
- `tweaks/processlab.boostpack.json`

These files are included by `tweaks/_manifest.json` and executed by the same runner path (`scripts/run-action.ps1`) as other Falcon tweaks.

## Supported step model
BoostPack conversions operate through standard step types:
- `registry.set`
- `registry.remove`
- `service.startup`
- `ps.run`
- `cmd.run`
- `falconlib.run`

## Process Lab + elevation
Process Lab related tool cards rely on `falconlib.run` and TrustedInstaller elevation via canonical NSudo path under `tools/FalconLibrary/NSudo/NSudoLG.exe`.

## Validation
All BoostPack-associated `falconlib.run` entries are covered by `scripts/qa_links.js` and fail QA when links are missing or legacy roots are used.
