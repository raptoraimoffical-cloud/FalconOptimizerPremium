# Falcon Optimizer Test Plan (Quick)

## 1) JSON + schema
From project root:
- `node tools/schema-validator.js`
Expected:
- prints `{ ok:true, errors:0, warnings:0 }`
- `schema-report.json` exists

## 2) Self-test (in app)
Home → Self-Test
Expected:
- Shows PSVersion, IsAdmin, Windows build
- No crash; returns ok=true

## 3) Runner resiliency (missing components)
Pick any Scheduled Task toggle that is not present on your build.
Expected:
- Log includes `SKIP (task not found)`
- Batch continues; final response ok may still be true unless other errors occurred.

Pick any Service toggle for a service not installed.
Expected:
- Log includes `SKIP (service not found)`
- Batch continues

## 4) Timer resolution
- Run: "Start Timer Resolution Helper (0.500ms)"
Expected:
- No duplicate helpers spawned if clicked twice.
- `Get-CimInstance Win32_Process | ? {$_.CommandLine -like "*timer-helper.ps1*"}` shows a process.

- Run: "Stop Timer Resolution Helper"
Expected:
- helper process gone
- timer.reset executed

## 5) Conflict sanity (power plans)
Run a profile.
Expected:
- If multiple power plans are in the selection pool, log shows conflict skips.
- Only one power plan is applied per batch.

## 6) Game Mode runtime
Run: "Game Mode: Close Common Background Apps"
Expected:
- Doesn't error if apps not running
- Closes any running matching processes (Discord/Chrome/etc.)