# Fix Semantics

`Fix` follows deterministic repair flow and mirrors Apply/Verify behavior.

## Execution contract
1. Run `check`.
2. If compliant, return success (no repair).
3. If non-compliant, run `fix.steps` when present; otherwise run `apply.steps`.
4. Re-run verification and return success only if post-repair verification succeeds.

## Service-specific behavior
- `Get-ServiceInfoSafe()` returns a stable object shape with keys:
  - `exists`, `name`, `startMode`, `state`, `status`
- Missing service behavior during verification:
  - default: warning + skipped verification
  - hard-fail only when `failIfMissing: true`

## Guardrails
- No legacy one-off fix scripts are required for standard Fix behavior.
- Skipped missing services do not convert Fix into failure unless explicitly configured.
