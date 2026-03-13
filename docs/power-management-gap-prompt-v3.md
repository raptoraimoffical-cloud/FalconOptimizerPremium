# Power Management Completion Audit (Delta v3)

This document captures what is still missing in the current repository and provides a strict follow-up prompt to force completion.

## Verified Remaining Gaps

1. **Catalog is still dominated by placeholder coverage rows**
   - `data/power/power_management_catalog.json` contains many `Master Scope Coverage` style entries using generic placeholder metadata rather than concrete machine-backed setting definitions.

2. **Powercfg integration in normalized catalog remains minimal**
   - The normalized catalog currently includes only a tiny set of `powercfg` source entries, despite generated `output/power/full-powercfg-catalog.*` artifacts existing.

3. **Apply handlers for device/storage/GPU are still pseudo-success branches**
   - `Invoke-ItemApply` currently marks multiple source types as applied with generic runtime text rather than doing concrete item-level apply/readback behavior.

4. **Verification still lacks item-specific logic for key source types**
   - Verification remains robust only for `powercfg` and NIC advanced properties; other source types are handled generically and overcounted as verify-capable.

5. **Master scope import is reduced and does not enforce full 367+ intent**
   - The audit output still reflects a reduced target scope count.

6. **UI row actions are generic and not per-setting**
   - In renderer, row Apply/Verify/Rollback actions trigger global preset/verify paths instead of item-specific handlers.

7. **Coverage report overstates readiness**
   - Coverage currently counts source types as apply/verify capable even where concrete implementation is placeholder-style.

## Copy/Paste Prompt (Delta-only, strict)

```text
You are patching Falcon Optimizer again.

IMPORTANT:
This is a delta completion pass. Keep existing working pieces and only fix remaining incomplete/fake areas.
Do not downgrade any currently working functionality.

CURRENT REPO DEFECTS TO FIX (MANDATORY)
1) Replace placeholder-heavy catalog strategy in data/power/power_management_catalog.json with concrete entries.
2) Expand real powercfg-backed entries in normalized manifest from minimal coverage to broad live-ingested coverage.
3) Remove pseudo-success apply branches for:
   - device_power_flag
   - storage_feature
   - gpu_feature
4) Add concrete verify logic for those same source types.
5) Restore/enforce full 367+ master scope tracking in Import-MasterScopeNames + audit.
6) Fix renderer row actions so apply/verify/rollback execute per-item actions, not global preset shortcuts.
7) Fix coverage accounting so applyCapable/verifyCapable only count truly implemented logic.
8) Ensure gap report is dynamic and maps full target scope vs implemented vs unsupported.

IMPLEMENTATION REQUIREMENTS
A) Catalog normalization
- Build normalized entries from:
  - live powercfg discovery (scripts/power/all-settings-explorer.ps1 output)
  - concrete non-powercfg catalogs (NIC/device/storage/GPU/registry/firmware)
- Keep unsupported machine-dependent items, but tag unsupported honestly.
- Remove generic HKLM:\SOFTWARE\FalconOptimizer\PowerScope placeholder-only rows.

B) Real apply engines
- device_power_flag: implement class-aware read/write where supported (NIC, USB hub/controller, Bluetooth, HID/input), with readback.
- storage_feature: implement concrete logic where supported (powercfg + storage/controller policy paths), with readback or unsupported.
- gpu_feature: Windows-native + vendor-aware detection; no success without confirmed change/readback.
- registry_power: preserve backup-before-write and readback verification.

C) Real verify engines
- Add explicit verifier routines for: device_power_flag, storage_feature, gpu_feature, registry_power.
- Firmware candidates remain recommendation-only and must be marked as such.

D) Full audit + coverage hardening
- Audit must compare:
  - full 367+ target scope
  - discovered powercfg settings
  - normalized manifest
  - handler coverage
  - UI exposure
  - preset references
- Coverage must include:
  - catalogCount
  - supportedCount
  - applyCapableCount
  - verifyCapableCount
  - uiExposedCount
  - presetReferencedCount
  - placeholderCount
  - placeholderRatio
  - realPowercfgCount
  - fullyActionableCount
  - missingApplyHandlers
  - missingVerifyHandlers
  - orphanUIEntries
  - orphanPresetEntries
- Coverage must fail if supported items rely on pseudo-success branches.

E) UI per-item actions
- Add item-level IPC methods and renderer calls:
  - applySetting(id, mode)
  - verifySetting(id)
  - rollbackSetting(id)
- Update row buttons to call item-specific engine modes.
- Keep global preset buttons, but do not reuse them for per-row actions.

F) Preserve architecture
- Keep quick plans intact.
- Exhaustive engine must be source-of-truth for advanced power management.

G) Regenerate artifacts after fixes
- output/power/gap-report.json
- output/power/coverage-report.json
- output/power/full-powercfg-catalog.json
- output/power/full-powercfg-catalog.csv
- output/power/full-powercfg-catalog.pretty.json
- output/power/verification-report.json
- output/power/verification-report.md
- output/power/verification-report.txt

DEFINITION OF DONE (ALL REQUIRED)
1) Catalog is no longer placeholder-dominated.
2) Real powercfg coverage in normalized catalog is broad (not single-digit).
3) device/storage/gpu apply no longer pseudo-success.
4) device/storage/gpu verify is concrete.
5) Full 367+ scope enforced in audit.
6) Per-row UI actions are item-specific.
7) Coverage no longer overstates fake capability.
8) Regenerated reports reflect real handler parity.

FINAL OUTPUT FORMAT
Print:
1. Exact files modified
2. Exact files created
3. Placeholder behaviors removed
4. Final catalogCount
5. Final realPowercfgCount
6. Final placeholderCount
7. Final placeholderRatio
8. Final supportedCount
9. Final fullyActionableCount
10. Final applyCapableCount
11. Final verifyCapableCount
12. Final uiExposedCount
13. Remaining unsupported items by category
14. Remaining real blockers
```
