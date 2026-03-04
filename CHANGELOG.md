## 1.5.3
- Added catalog QA script (`scripts/qa_catalog.js`) and generated `QA_REPORT.txt` for manifest/schema/duplicate validation.
- Hardened `scripts/run-action.ps1` registry handling for DWORD/QWORD unsigned values and REG_BINARY write/verify support.
- Added centralized FalconLibrary tool execution (`falconlib.run`) with elevation routing (none/admin/trustedinstaller via NSudo).
- Improved `service.startup` strict-mode-safe parsing and missing-service warning behavior (`failIfMissing` supported).
- Normalized risk labels to canonical enum (Safe/Warning/Danger/Extreme) in renderer with explicit normalization logging.
- Added Danger/Extreme confirmation body content with change + revert details before run.
- Fixed Fixes route semantics to run check/apply/re-check or dedicated fix sequence.
- Added FalconLibrary cards for Audio Bloat Remover and Timer Resolution apply/stop/status in `tweaks/utilities.json`.
- Fixed malformed tweak metadata causing unnamed/misgrouped cards in security/controller/services catalogs.

# CHANGELOG

## Falcon Optimizer 1.2 (Phase 2: UI Safety + Profiles + Undo + Validation)

### Added
- UI safety gating modal for High/Critical or snapshot/explicit-confirm actions.
- Simulation Mode (dry-run): logs planned steps instead of executing.
- Profiles system (Safe Competitive, Aggressive Competitive, All In Risky) loaded from tweaks/profiles.json.
- Apply profile workflow with snapshot preflight if any selected items require it.
- Applied history tracking per-session (applied-history.json in userData).
- Undo workflows:
  - Undo last session (reverts applied actions from current session in reverse order)
  - Undo all (reverts all recorded applied actions in reverse order)
- Built-in tweak schema validator + migrator:
  - tools/schema-validator.js
  - npm scripts: validate:tweaks / validate:tweaks:report
  - UI button on Home to validate + migrate

### Modified
- main.js: added IPC endpoints runTweak, dryRunSteps, validateTweaks, history, undo.
- preload.js: exposed new APIs to renderer.
- renderer.js: enforced safety gating, snapshot enforcement, simulation mode, profiles, undo, validation UI.
- index.html/styles.css: added modal overlay styling.

### Validator run (this build)
- Report-only output: {"ok":false,"errors":273,"warnings":48,"report":"schema-report.json"}
- Fix/migrate output: {"ok":false,"errors":273,"warnings":48,"report":"schema-report.json"}



## Falcon Optimizer 1.3 (Phase 3: Expansion Library)

### Added (New Tweaks)
- Expansion / Background Apps: 99 new toggles
- Expansion / Scheduled Tasks: 122 new toggles
- Expansion / Services: 95 new toggles
- Expansion / Registry (Latency, UX, Power): 78 new toggles
- Expansion / NVIDIA (Tools): 44 new actions (launchers/settings shortcuts)

Total new items added in Phase 3: 438

- Removed duplicate legacy tweak files (apps.utilities.json, gaming.*.json) to eliminate id collisions.
- Updated schema validator (v2) to auto-fill missing item fields and normalize task.action case.


## Falcon Optimizer 1.4 (Stability + Common Sense Pass)

### Removed
- Removed **Disable Intel Mitigation Controls (Alt)** (`cpu_disable_spectre_mitigations`) per request.

### Fixed
- Timer resolution runner now requests **0.500ms (5000)** instead of 0.507ms.
- Added **persistent timer helper** actions:
  - Start Timer Resolution Helper (0.500ms)
  - Stop Timer Resolution Helper (resets request)
- SystemResponsiveness minimum corrected to **10** (was 0) everywhere it appears.
- Power plan conflicts: power plan tweaks now declare `conflictGroup: powerplan` and batch/profile runs skip conflicting duplicates (keeps first per group).

### UI/UX
- Added **batch progress bar** for profile runs (shows progress and current item).

### Runner resiliency
- Services: existence checks + per-step try/catch; missing services are logged as SKIP (non-fatal).
- Tasks: checks task exists via `schtasks /Query`; missing tasks are logged as SKIP (non-fatal).
- Runner now returns structured JSON:
  `{ ok, errors:[], warnings:[], logFile }` and continues through batches.


## 1.4.2 (Hotfix: Registry paths + UI output)
- Fixed registry path normalization (HKLM\... -> HKLM:\...) so registry tweaks actually apply.
- Fixed preload.js corruption so renderer IPC calls work reliably.
- Added Run Status panel to show per-action OK/FAILED, errors/warnings, and open log.
