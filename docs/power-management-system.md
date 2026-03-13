# Falcon Exhaustive Power Management Pipeline

This repository now includes a manifest-driven power-management pipeline that is designed to scale to the full discovered power surface on each Windows machine.

## Entry point

- `scripts/power/power-management-engine.ps1`

## Modes

- `audit` – generates `output/power/gap-report.json`
- `catalog` – generates all machine-level catalogs:
  - `output/power/full-powercfg-catalog.json`
  - `output/power/full-powercfg-catalog.csv`
  - `output/power/full-powercfg-catalog.pretty.json`
  - `output/power/nic-advanced-properties.json`
  - `output/power/device-power-flags.json`
  - `output/power/storage-power-features.json`
  - `output/power/gpu-power-features.json`
  - `output/power/firmware-power-candidates.json`
- `build-manifest` – compiles `data/power/power_management_catalog.json`
- `apply-preset` – chunk-safe application with retries + persistent progress (`output/power/apply-progress.json`)
- `verify` – writes:
  - `output/power/verification-report.json`
  - `output/power/verification-report.md`
  - `output/power/verification-report.txt`
- `coverage` – writes `output/power/coverage-report.json` and fails when supported entries miss apply/verify handlers.

## Presets

- `extreme`
- `competitive`
- `balanced`
- `powersaver`
- `laptop`
- `restore`

## Backup and rollback data

Before apply:

- Exports active power scheme to `output/power/backups/active-scheme.pow`
- Captures baseline metadata to `output/power/backups/baseline.json`

## Validation helpers

- `scripts/validation/verify-power-management.ps1`
- `scripts/validation/report-power-management.ps1`
