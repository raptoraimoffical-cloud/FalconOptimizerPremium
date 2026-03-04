# Fix Semantics

`Fix now` is standardized to behave like `Apply`, but only after a compliance check.

## Flow used by Fix cards

1. Run `check` steps first.
2. If already compliant, return success without running repair.
3. If not compliant, run repair action:
   - `fix.steps` when present.
   - otherwise fallback to regular `apply`.
4. Run `check` again and return success only when repair and post-check both pass.

## Guardrails

- No legacy extras/alternate fix routing is used.
- Missing services during `service.startup` verification are treated as warning+skipped, not hard failure, unless `failIfMissing: true` is set on the step.
- Skipped service checks do not turn Fix into a failed state.
