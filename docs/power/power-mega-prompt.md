# Falcon Optimizer — Power Management Hardening Mega Prompt (Repo-Specific)

Copy/paste everything below into Codex/GPT when you want a strict, end-to-end repair of Power Management + Speed Core classification.

---

You are working inside the FalconOptimizerPremium repository.

## Mission
Perform a full, no-hallucination audit and remediation of power-management data, descriptions, UI visibility, and selection logic quality.

This is a **trust and correctness** task, not a cosmetic rewrite.

## Non-negotiable anti-hallucination rules
1. Never invent semantics for undocumented power settings.
2. Never infer meaning from a vague title alone.
3. If GUID mapping cannot be proven, classify as unresolved/undocumented.
4. If apply/verify is unsupported, UI must not pretend it works.
5. Prefer hiding uncertain settings over shipping misleading controls.
6. Keep main UI clean; quarantine uncertain internals.

## Known repo facts you must account for before changes
- Power catalog path: `data/power/power_management_catalog.json`.
- It currently contains a large amount of unresolved content.
- Scan evidence already exists in:
  - `docs/power/power-scan-summary.json`
  - `docs/power/power-scan-summary.md`
- Current scan values (must be revalidated in your run):
  - total entries: 567
  - powercfg_unmapped: 345
  - processor policy placeholders: 39 (`processor_policy_1..39`)
- Speed Core tweak file:
  - `tweaks/speed.boost.json`
- “Apply Latency Registry Baseline” is currently an active optimization bundle (not a neutral reset), so do not mislabel it as a reset unless behavior is changed.

## Questions from product owner that must be answered in deliverables
1. What do “Processor performance history count/length” actually do?
2. What are `processor_policy_1..N` placeholders and should they be user-facing?
3. Which settings are meaningful for FPS/latency vs mostly telemetry/internal?
4. Which settings should be main UI vs advanced vs experimental vs hidden?
5. Why does “Select all non-app optimizations” include app-specific items (Roblox/Minecraft/Adobe), and how is it fixed?
6. Should “Apply Latency Registry Baseline” remain in Speed Core, be renamed, or moved?

## Required output files
Produce/update all of the following:
1. `data/power/power_management_catalog.json`
2. `output/power/power-audit-report.json`
3. `output/power/power-audit-report.md`
4. `output/power/power-unresolved-report.md`
5. `docs/power-badge-system.md`
6. `docs/power-description-style-guide.md`
7. Any code/config files needed to fix non-app selection behavior

## Required field model for every visible power setting
Each visible setting must include:
- `name`
- `shortDescription`
- `longDescription`
- `whatItDoes`
- `whyGamersCare`
- `fpsImpact`
- `latencyImpact`
- `powerImpact`
- `heatImpact`
- `stabilityRisk`
- `recommendedFor`
- `avoidIf`
- `badges`
- `documentationStatus`
- `proofSource`
- `sourceEvidence`
- `maxPerformanceValue`
- `balancedValue`
- `powerSaverValue`
- `rollbackValue`

If unresolved, explicitly say unresolved and do not fake technical certainty.

## Required documentation statuses
Use one of:
- `MICROSOFT_DOCUMENTED`
- `MICROSOFT_HIDDEN_BUT_DOCUMENTED`
- `POWERCFG_ALIAS_CONFIRMED`
- `GUID_CONFIRMED_NO_DOC_PAGE`
- `PLATFORM_SPECIFIC_INFERRED`
- `UNDOCUMENTED_INTERNAL`
- `UNRESOLVED`

## Required proof source taxonomy
Use one of:
- `microsoft_doc`
- `powercfg_alias`
- `powercfg_q`
- `powercfg_qh`
- `subgroup_guid_mapping`
- `registry`
- `repo_placeholder_only`
- `unresolved`

If proof source is `repo_placeholder_only` or `unresolved`, do not keep it in beginner-facing main UI.

## Required badge system
Assign badges from this exact list:
- `MAX_PERFORMANCE`
- `HIGH_POWER_USE`
- `MAX_POWER_USE`
- `POWER_SAVING_DISABLED`
- `LATENCY_RESPONSIVENESS`
- `FPS_CONSISTENCY`
- `BATTERY_NEGATIVE`
- `THERMAL_RISK`
- `SAFE_DEFAULT`
- `ADVANCED`
- `EXPERIMENTAL`
- `UNDOCUMENTED`
- `UNSUPPORTED_ON_THIS_SYSTEM`
- `REQUIRES_REBOOT`
- `LAPTOP_ONLY`
- `DESKTOP_ONLY`
- `APP_SPECIFIC`
- `SYSTEM_WIDE`

Badges must be computed from metadata and support status, not random manual tagging.

## Must-handle weird families (explicit)
You must detect and classify all of the following families:

### Processor performance history
- processor performance history count
- processor performance history length

Rules:
- Explain as scheduler/performance-history behavior.
- Do not market as high-value FPS gain.
- Minimum classification: `ADVANCED`.

### Processor policy placeholders
- `processor_policy_1` … `processor_policy_39`

Rules:
- Treat as unresolved unless exact alias/GUID semantics are proven.
- If unproven: `documentationStatus=UNDOCUMENTED_INTERNAL`, `proofSource=unresolved`, and `ui_visibility=experimental|hidden`.
- Must include badges `UNDOCUMENTED` and `EXPERIMENTAL`.

### CPU scaling / boost / parking / idle / heterogeneous / QoS groups
Include exact handling for:
- min/max processor state
- boost mode
- EPP / perf preference
- increase/decrease thresholds and times
- check interval
- utility floor/ceiling
- preferred cores use policy
- response time sensitivity
- core parking thresholds/hysteresis/min/max cores
- idle demote/promote/min/max state
- latency hint enable + min unparked cores
- heterogeneous scheduling policies
- QoS floor/ceiling

Do not collapse these into generic one-liners.

## UI visibility contract
Each setting must end with one visibility value:
- `main`
- `advanced`
- `experimental`
- `hidden`

Main UI must contain only proven, user-meaningful settings with working apply/verify paths.

## Apply / Verify / Rollback requirements
For any visible setting considered supported:
- Apply must call correct setting path (powercfg GUID pair or valid backend implementation).
- Verify must read current value from live query (`powercfg /query` or `/qh`).
- Rollback must restore previous captured value (not guessed defaults).
- If verification fails, mark failed and log command output.

If setting lacks usable subgroup/setting GUID, it is not normal supported powercfg apply/verify.

## Speed Core decision rule
Inspect `boost.latency_registry_baseline` in `tweaks/speed.boost.json`.

Choose one clean outcome:
- Keep in Speed Core only if Speed Core scope explicitly includes latency/network/scheduler registry optimization, **or**
- Move to dedicated section (e.g., “Latency Core” / “Network & Scheduler”).

Do not relabel as a pure reset unless behavior truly becomes reset behavior.

## Non-app selection bug fix (required)
Fix “Select all non-app optimizations” logic so app-specific items are excluded.

Implement explicit metadata model:
- `isAppSpecific: boolean`
- `isSystemWide: boolean`
- `appTargets: string[]`
- `bulkSelectableGroups: string[]`

Selection rule:
- Include only items where `isSystemWide=true` and `isAppSpecific=false`.
- Do not rely only on category strings.

At minimum, treat Roblox/Minecraft/Adobe/browser/launcher-specific cleanup tweaks as app-specific.

## Completion gates
Task is incomplete unless all are true:
1. No placeholder descriptions remain (e.g., “Live discovered powercfg item.” / “Catalog entry for …”).
2. No unresolved Processor policy placeholders in main UI.
3. Every visible item has full descriptions + badges + trust metadata.
4. Unsupported items are not presented as normal toggles.
5. Non-app bulk selection no longer selects app-specific tweaks.
6. Speed Core baseline item has correct placement and labeling.
7. Final report includes counts: audited/main/advanced/experimental/hidden/rewritten/unsupported quarantined.

## Final report format required from the model
Return:
- Summary table of counts
- Top 20 most impactful validated power settings (with reasons)
- Top unresolved families quarantined (with reasons)
- Exact files changed
- Known risks / follow-up actions

---

End of prompt.
