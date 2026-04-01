You are patching Falcon Optimizer Premium.

You must perform a full repo audit and then patch the repo so Falcon fully and safely integrates the missing Oneclick V8.4 changes, fixes Speed Core’s false/broken failure reporting, removes stale V8.3-era parity assumptions, and resolves the major architecture/validation/path bugs already identified.

This is not a cosmetic task.
Do not spend the run mainly on warnings, badges, or docs.
Those are secondary.
The primary job is:
1. real V8.4 parity migration
2. real Speed Core diagnosis
3. real Speed Core fix
4. real stale-reference cleanup
5. real bug fixing
6. accurate reporting with no fake success

You do NOT have the original Oneclick-V8.4.bat file.
You MUST reconstruct and implement the V8.4 changes from the instructions below.
Do not hallucinate assets, filenames, paths, success states, or verification.
Audit first, patch second, validate third, then report exactly what changed.

==================================================
NON-NEGOTIABLE RULES
==================================================

1. Do not claim a change was implemented unless the repo actually reflects it.
2. Do not claim an asset exists unless it physically exists.
3. Do not say parity is updated while stale V8.3/V2.5/NovaOS references remain in active current code/docs/manifests.
4. Do not hide behind “safety hardening complete” if the main migration work is still missing.
5. Do not leave Speed Core reporting logic broken.
6. Do not leave launcher-only wrappers pretending to be real verified optimizations.
7. Do not break Electron startup.
8. Do not introduce malformed async/await syntax.
9. Do not introduce malformed spawn()/PowerShell argument arrays.
10. Do not give vague summaries. Give exact file paths, exact stale refs, exact fixes, exact remaining blockers.

==================================================
PRIMARY OBJECTIVES
==================================================

A. FULLY APPLY THE REAL MISSING ONECLICK V8.4 DELTAS
B. DETERMINE WHY SPEED CORE SAYS FAILED
C. DETERMINE WHETHER THOSE FAILURES ARE ACTUALLY TRUE, PARTIALLY TRUE, OR MOSTLY REPORTING BUGS
D. FIX SPEED CORE SO ITS RESULTS ARE HONEST
E. FULLY SCAN THE REPO FOR BUGS FOUND IN THIS PROJECT STATE
F. CLEAN UP STALE INTEGRATION/PARITY/DOC/PATH ISSUES
G. PRODUCE A FINAL REPORT THAT IS SPECIFIC AND IMPOSSIBLE TO MISREAD

==================================================
CONTEXT: WHAT THE LAST PASS DID WRONG
==================================================

A previous pass mainly did risk-label/warning hardening:
- added badges
- warning strips
- typed confirmation
- rollback notes
- quarantined some dangerous legacy writes
- updated docs/reports around safety metadata

That is NOT the main task.
Do not repeat a badge-only or warning-only pass.
Do not waste the run mostly on safety metadata unless it directly supports a required functional fix.

You may preserve that work, but your main job now is the missing functional migration and bug repair.

==================================================
EXACT ONECLICK V8.4 DELTAS THAT MUST BE REPRESENTED
==================================================

These deltas must be implemented everywhere relevant in:
- active tweak manifests
- tool manifests
- FalconLibrary/tool references
- imported parity catalogs
- docs/reports that describe current parity
- helper files
- integration reports

--------------------------------------------------
1. NVIDIA PROFILE INSPECTOR DELTA
--------------------------------------------------

Old parity behavior:
- nvidiaProfileInspector.exe -importProfile ...\NovaOS.nip

Required V8.4 behavior:
- nvidiaProfileInspector.exe -SilentImport ...\QuakedV2.nip

Required actions:
a. Search the entire repo for:
   - NovaOS.nip
   - importProfile
   - -importProfile
   - QuakedV2.nip
   - SilentImport
b. Replace all active current-parity references that still point to NovaOS/current old import mode.
c. Current parity must expect:
   nvidiaProfileInspector.exe -SilentImport "<path>\QuakedV2.nip"
d. If QuakedV2.nip does not exist:
   - do NOT lie
   - create/update MISSING_ASSETS.md
   - list QuakedV2.nip as missing
   - update code/docs/manifests to the correct expected filename anyway
   - mark those actions blocked by missing asset, not functional
e. Any docs that still say NovaOS.nip is current parity must be updated or marked deprecated.

--------------------------------------------------
2. PROCESS DESTROYER DELTA
--------------------------------------------------

Old parity behavior:
- Process Destroyer V2.5
- Process Destroyer Extreme V2.5

Required V8.4 behavior:
- Process Destroyer V2.6
- Process Destroyer Extreme V2.6

Required actions:
a. Search for:
   - Process Destroyer V2.5
   - Process Destroyer Extreme V2.5
   - Process Destroyer V2.6
   - Process Destroyer Extreme V2.6
b. Replace all active current-parity references to V2.5 with V2.6 expectations.
c. Update all relevant tweak manifests/tool manifests/docs/reports/helpers.
d. If V2.6 files do not physically exist:
   - add them to MISSING_ASSETS.md
   - update the repo to expect V2.6 as current parity anyway
   - do not falsely report them working

--------------------------------------------------
3. CROSSDEVICERESUME FIX DELTA
--------------------------------------------------

V8.4 added this exact registry override:

Path:
HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\1387020943

Values:
- EnabledStateOptions = 0
- EnabledState = 1
- Variant = 0
- VariantPayload = 0
- VariantPayloadKind = 0

Required actions:
a. Add a dedicated Falcon-native tweak/card for this fix.
b. Do NOT leave it as only an imported batch assumption.
c. It must have:
   - apply
   - verify
   - revert
   - proper description
   - clear placement in a sensible category
d. Verification must confirm all five values.
e. Revert must cleanly remove or restore the values.
f. Search repo for CrossDeviceResume and 1387020943 and reconcile all references.

--------------------------------------------------
4. SERVICE DELTAS
--------------------------------------------------

Required current parity service behavior:
- AppInfo = demand
- cloudidsvc = disabled
- VacSvc = disabled
- spectrum = disabled

Required actions:
a. Search repo for:
   - AppInfo
   - cloudidsvc
   - VacSvc
   - spectrum
b. Update imported parity and Falcon-native mappings to these exact startup targets.
c. Prefer structured service steps over raw fragile sc config wrappers where possible.
d. Verification must check actual resulting startup mode.
e. Missing services must not hard-fail the whole batch unless the action is explicitly critical.
f. Missing service should produce skip/not-applicable with a logged reason like service-missing.

--------------------------------------------------
5. REMOVE STALE PRE-V8.4 SERVICE PARITY CLAIMS
--------------------------------------------------

The following old hard-disable assumptions are no longer current imported parity:
- AppXSvc disable
- TimeBrokerSvc disable

Required actions:
a. Search for AppXSvc and TimeBrokerSvc in active current imported parity logic.
b. Remove them from current V8.4 parity bundles/claims.
c. If Falcon still wants to expose them, move them to a separate advanced/risky/manual area, not current V8.4 parity.
d. Update docs/reports so they no longer imply these are current parity.

--------------------------------------------------
6. REMOVE STALE POWERTHTROTTLINGOFF IMPORTED PARITY CLAIM
--------------------------------------------------

Old imported parity claim that must no longer remain as current V8.4 parity:
- HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling
  PowerThrottlingOff = 1

Required actions:
a. Search for PowerThrottlingOff.
b. Remove it from current imported V8.4 parity representations.
c. If Falcon still wants a separate Falcon-native power tweak for it, that is allowed, but it must no longer be represented as imported current Oneclick V8.4 parity.
d. Update all docs/reports/manifests accordingly.

--------------------------------------------------
7. UI / MENU PARITY DOC DELTAS
--------------------------------------------------

V8.4 menu/help behavior changed:
- “More Info” became “Learn More”
- GPU Tweaks got a new Learn More option
- GPU Skip moved to option 4

Required actions:
a. Search docs/helpers/reports for old wording.
b. Update current parity docs so they do not describe outdated flow.
c. Do not over-focus on this; it is secondary, but it still must be corrected.

--------------------------------------------------
8. osu! PATH ESCAPING DELTA
--------------------------------------------------

V8.4 corrected path handling around osu! / exclamation marks.

Required actions:
a. Search for osu! and any imported path logic derived from batch.
b. Make sure Falcon does not break on paths containing exclamation marks.
c. Normalize any imported batch-derived handling safely for PowerShell/Electron usage.
d. Add a test note or validation note that paths with ! were checked.

==================================================
DANGEROUS LEGACY WRITES THAT MUST NOT BE BLINDLY RE-IMPORTED
==================================================

The following writes were already correctly identified as risky and must not be silently put back into broad apply/current parity bundles:

1. HKCU\Control Panel\Desktop\UserPreferencesMask
2. HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR\CursorCaptureEnabled = 0

Required actions:
a. Search every active tweak/imported catalog/BoostPack/legacy helper for:
   - UserPreferencesMask
   - CursorCaptureEnabled
b. Make sure they are NOT broad-apply/current parity silent actions.
c. If exposed, they must be hardened Falcon-native risky/manual actions only.
d. Keep them out of broad presets and broad Speed Core bundles.
e. Do not falsely market them as simple FPS tweaks.

==================================================
SPEED CORE: THIS IS THE MOST IMPORTANT DEBUG/FIX SECTION
==================================================

You must fully audit Speed Core.
Do not hand-wave this.
Do not just add badges.
Do not just add warnings.
Find the real cause.

Known project-state findings already identified:
- tweaks/speed.boost.json has 53 items and almost all are launcher-style shell.start wrappers
- tweaks/speed.integrity.json has 8 items and all 8 are shell.start wrappers
- runTweakWithTimeout() uses a hard 90 second timeout
- shell.start launches child processes but does not robustly capture child exit codes
- shell.start has weak/no real verification for many of these actions
- this creates both:
  - false failures
  - false successes
- therefore current Speed Core reporting is not trustworthy

Your job:
1. confirm this in code
2. determine the exact root cause(s)
3. determine whether “everything failed” is actually true or mostly reporting junk
4. patch the code so Speed Core results become accurate and useful

--------------------------------------------------
SPEED CORE REQUIRED AUDIT
--------------------------------------------------

Audit at minimum:
- renderer.js
- main.js
- core/actionRunner.js
- scripts/run-action.ps1
- tweaks/speed.boost.json
- tweaks/speed.integrity.json
- any shared runner/helper that influences Speed Core batch execution, timeout, logging, summary, verify, or toasts

Explicitly answer:
a. Why does Speed Core report failed?
b. Is that failure fully real, partially real, or mostly a reporting issue?
c. Which actions are genuine failures?
d. Which actions are launcher/reporting artifacts?
e. Which actions are timing out?
f. Which actions are missing verification?
g. Which actions should be converted from shell.start to native structured steps?

--------------------------------------------------
SPEED CORE REQUIRED FIXES
--------------------------------------------------

1. Replace shell.start wrappers with native structured steps wherever realistically possible.
   Examples:
   - registry.set / registry.remove
   - service.startup
   - cmd.run
   - ps.run
   - process.kill
   - task actions
   - powercfg/native power steps
   If an action can be expressed natively, do not leave it as shallow shell.start.

2. For actions that still truly need to launch a process:
   - capture actual exit code
   - wait appropriately when the action is intended to complete before reporting
   - log exact reason on failure
   - do not treat “process launched” as “optimization succeeded”

3. Timeout logic:
   - remove naive blanket 90-second failure semantics for heavy actions
   - create per-action or per-category timeout behavior
   - distinguish timeout from hard failure

4. Summary logic:
   - distinguish:
     - success
     - partial success
     - skipped/not applicable
     - timed out
     - failed
   - stop collapsing everything into crude failed/success if it is not that simple

5. Verification:
   - registry actions verify exact values
   - service actions verify actual startup mode
   - tool launches verify file exists before run
   - heavy integrity/repair actions must report honestly if verification is weak or deferred

6. Logging/history:
   - no empty fake-failure or fake-success entries
   - include real reason:
     - timeout
     - missing service
     - missing path
     - access denied/admin required
     - child process nonzero exit
     - verification mismatch

7. Manual/open/helper actions:
   - if a card is open-only/manual/helper, do not poison Speed Core run results as if it were a failed optimization
   - relabel or quarantine them appropriately

--------------------------------------------------
SPEED CORE REQUIRED OUTPUT
--------------------------------------------------

Final report must clearly say:
- exact root cause(s)
- whether failures were real, partial, or mostly reporting artifacts
- exact code-level fix
- exact files changed
- exact remaining limitations if any

==================================================
FULL BUG SCAN REQUIREMENTS
==================================================

You must perform a real full bug pass, not just risk metadata work.

Known bug/state issues already identified that must be checked/fixed:

1. STALE ONECLICK / BOOSTPACK INTEGRATION
- stale NovaOS.nip references
- stale Process Destroyer V2.5 references
- stale docs still describing V8.3-era current parity
- stale imported NPI import mode references

2. TOOL ROOT / PATH DRIFT
Repo mixes:
- tools/FalconLibrary/**
- FalconLibrary/**
- FalconLibrary/FalconLibrary/**
This is bad and causes stale duplicate trees/path confusion.

Required:
a. establish one canonical root
b. update references
c. quarantine/remove stale duplicates where safe
d. preserve packaged runtime expectations

3. OPEN-ONLY / PLACEHOLDER PROBLEM
Static counts already identified:
- openOnlyCount = 718
- actionNamedButOpenOnlyCount = 169
- items_open_only = 948

Required:
a. audit optimization-labeled cards that are really just openers/helpers
b. do not leave misleading action naming
c. helper/manual/open items must not masquerade as true executed optimization

4. DUPLICATE POWER IDS
Fix duplicate IDs:
- pm_gpu_turn_off_display_after
- pm_gpu_panel_self_refresh
- pm_registry_allow_standby_states
- pm_registry_allow_wake_timers
- pm_registry_fast_startup
- pm_registry_connected_standby_policy
- pm_registry_network_connectivity_in_standby
- pm_nic_wake_on_magic_packet
- pm_nic_wake_on_pattern_match

5. CARDS WITH NO EXECUTABLE STEPS
Fix or intentionally quarantine:
- power_management_exhaustive_panel
- power_overview_summary

6. VALIDATION / SCHEMA MISMATCH
Previously observed validator output:
- 766 errors
- 1831 warnings

Major examples already identified:
- Invalid step type: reg.set
- Invalid step type: ps.file
- Invalid step type: reg.del
- Invalid step type: falconlib.run
- Invalid step type: powercfg
- process.start requires 'filePath'
- process.kill requires 'name'
- Invalid step type: file.ensureDir
- Invalid step type: tool.ensure
- Invalid step type: tool.launch
- invalid risk levels silently defaulting

Required:
a. align runtime-supported step vocabulary and validator schema
b. do not leave the validator calling active runtime step types invalid
c. fix naming mismatches
d. normalize riskLevel enums
e. reduce validation noise meaningfully
f. report before/after counts

7. PATH / TOOL RESOLUTION SAFETY
Check canonical resolution for:
- NSudo
- DPC Latency Checker
- Timer Resolution / latency tools
- Nvidia Profile Inspector
- O&O ShutUp10
- Process Destroyer
- Edge remover
- any FalconLibrary-hosted utility
Do not leave path roulette.

==================================================
FILES / AREAS THAT MUST BE AUDITED
==================================================

At minimum audit and patch these if relevant:
- main.js
- renderer.js
- core/actionRunner.js
- scripts/run-action.ps1
- schema-validator.js
- tweaks/speed.boost.json
- tweaks/speed.integrity.json
- tweaks/falconlibrary.integration.json
- tweaks/core.boostpack.registry.json
- tweaks/_performance_library/imported_catalog.json
- tweaks/imported.registry.oneclick.json
- tweaks/processlab.boostpack.json
- tweaks/processlab.services.catalog.json
- tools/tools.manifest.json
- BoostPack/**
- tools/**
- FalconLibrary/**
- docs/**
- any parity/integration/audit report files

==================================================
MANDATORY SEARCH TERMS
==================================================

Search the repo for all of these and resolve intentionally:

- NovaOS.nip
- QuakedV2.nip
- importProfile
- SilentImport
- Process Destroyer V2.5
- Process Destroyer V2.6
- UserPreferencesMask
- CursorCaptureEnabled
- CrossDeviceResume
- 1387020943
- AppInfo
- cloudidsvc
- VacSvc
- spectrum
- AppXSvc
- TimeBrokerSvc
- PowerThrottlingOff
- shell.start
- runTweakWithTimeout
- tools/FalconLibrary
- FalconLibrary/FalconLibrary
- openOnlyCount
- actionNamedButOpenOnlyCount
- power_management_exhaustive_panel
- power_overview_summary

==================================================
IMPLEMENTATION STYLE REQUIREMENTS
==================================================

1. Prefer Falcon-native structured tweaks over raw imported batch blobs.
2. Preserve apply / verify / revert symmetry where realistic.
3. Preserve honest toasts/history/logging.
4. Keep helper/manual/open items from corrupting run summaries.
5. Keep risky UI/cursor writes quarantined away from broad apply.
6. Keep packaged Electron stable.
7. Keep PowerShell quoting safe.
8. Keep async syntax valid.
9. Use exact filenames/paths that really exist, or explicitly report them missing.

==================================================
REPORTING FORMAT REQUIRED
==================================================

After the patch, output all of the following in a structured way:

1. V8.4 DELTA REPORT
- every required delta
- exact status: implemented / blocked by missing asset / intentionally not broad-applied
- exact files changed

2. SPEED CORE ROOT-CAUSE REPORT
- exact reason(s) it was saying failed
- whether failures were real, partial, or mostly reporting artifacts
- exact files changed
- exact summary/timeout/verification changes

3. FULL BUG FIX REPORT
- stale refs fixed
- path/root cleanup done
- duplicate IDs fixed
- no-step cards fixed/quarantined
- open-only misleading items addressed
- validation/schema mismatches addressed

4. MISSING ASSETS REPORT
- exact missing files still needed
- exact code/docs that now expect them

5. VALIDATION REPORT
- before counts
- after counts
- remaining issues
- why anything unresolved remains

6. FINAL HONESTY CHECK
- explicitly list anything still NOT finished
- explicitly list anything blocked by missing files/assets
- explicitly list anything that still needs manual testing

==================================================
ANTI-HALLUCINATION / ANTI-DODGE RULES
==================================================

- Do not dodge the main job by mostly editing badges/warnings/docs.
- Do not say “complete” if the repo still has stale V8.3/V2.5/NovaOS current parity.
- Do not claim QuakedV2.nip exists if it does not.
- Do not claim Process Destroyer V2.6 exists if it does not.
- Do not say Speed Core is fixed if it still relies on shallow shell.start wrappers for most actions.
- Do not report “success” just because a process launched.
- Do not leave open/manual/helper cards polluting optimization result counts.
- Do not leave old AppXSvc/TimeBrokerSvc/PowerThrottlingOff current-parity claims active.
- Do not give vague summaries like “hardening complete” or “repo-wide audit done” without exact concrete evidence.

==================================================
SUCCESS CRITERIA
==================================================

The run is only acceptable if all of the following are true:

1. Falcon no longer presents stale V8.3/V2.5/NovaOS as current parity.
2. V8.4 deltas are represented accurately and safely.
3. CrossDeviceResume fix exists as a real Falcon-native tweak/card.
4. Service deltas are updated to AppInfo demand, cloudidsvc disabled, VacSvc disabled, spectrum disabled.
5. Old AppXSvc / TimeBrokerSvc / PowerThrottlingOff imported current-parity claims are removed.
6. Speed Core no longer gives misleading blanket failure reporting.
7. Speed Core result classification is honest and useful.
8. Launcher-only wrappers are reduced or handled honestly.
9. Canonical tool paths are consistent.
10. Validation quality is meaningfully improved.
11. Docs match the actual repo state.
12. Final report clearly distinguishes implemented, blocked, skipped, risky-manual, and still-unresolved items.

Now do the audit, patch, validation, and final report exactly as specified.
