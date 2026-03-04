# Elevation policy

TrustedInstaller (`NSudo`) required for:
- HKLM protected policy/security edits.
- Protected services startup changes (Defender, update stack, security health).
- Scheduled task changes under Microsoft protected paths.
- System file/driver/boot edits (System32, BCD, kernel mitigation toggles).

Enforcement:
- `falconlib.run` with `elevation:"trustedinstaller"` routes through NSudo automatically.
- `requiresTrustedInstaller:true` cards are authored with TI step-level elevation.
