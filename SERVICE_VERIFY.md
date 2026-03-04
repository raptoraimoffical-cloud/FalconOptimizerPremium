# service.startup verification logic

- Accepts `startType`, `startupType`, `startup`, `mode`, or `value`.
- Uses `Get-CimInstance Win32_Service` to read `StartMode`.
- Missing service returns `verified=true`, `skipped=true`, `reason=service-missing` (no throw).
- Normalizes Auto→Automatic.
- `AutomaticDelayedStart` verifies both Automatic StartMode and `DelayedAutoStart=1` registry flag.
- StrictMode-safe: no direct missing-property assumptions.
