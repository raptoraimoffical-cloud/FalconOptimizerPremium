# Runner Engine Notes (`scripts/run-action.ps1`)

## Core guarantees added

- StrictMode-safe service object shape: `Get-ServiceInfoSafe` now always returns:
  - `exists`, `name`, `displayName`, `startMode`, `state`, `status`.
- Log folder creation hardened:
  - primary create/resolve uses `-ErrorAction Stop`.
  - fallback to `%TEMP%\FalconOptimizer\logs` on failure.
- `falconlib.run` path resolution deterministic with explicit missing-file diagnostics (includes attempted paths).
- TrustedInstaller helper (`NSudo`) resolves only from canonical path candidates.
- Removed duplicate execution handlers for `run.exe` and `file.ensureDir` to preserve one handler per step type.

## Service verification behavior

### `service.startup`

Verification rules:
- Missing service + `failIfMissing: false` (default):
  - returns verified + skipped, logs warning semantics.
- Missing service + `failIfMissing: true`:
  - verification fails.
- Existing service:
  - validates start mode (including delayed auto semantics).

This prevents StrictMode crashes from missing properties and ensures missing services are skipped unless explicitly configured to fail.

## Supported step types (implemented)

- `action`
- `bcdedit`
- `button`
- `cmd`
- `cmd.run`
- `falconlib.run`
- `file.ensureDir`
- `live`
- `netsh`
- `nsudo.run`
- `open.file`
- `open.path`
- `open.url`
- `powercfg.check`
- `powercfg.set`
- `process.kill`
- `process.start`
- `ps.file`
- `ps.run`
- `reg.del`
- `reg.set`
- `registry.check`
- `registry.check_absent`
- `registry.remove`
- `registry.set`
- `run.exe`
- `schtasks`
- `service.check`
- `service.disable`
- `service.enable`
- `service.startup`
- `shell.start`
- `task`
- `task.check`
- `timer.reset`
- `timer.set`
- `toggle`
- `tool.ensure`
- `tool.launch`
- `tweak`
- `uac.disable`
- `uac.restore`
