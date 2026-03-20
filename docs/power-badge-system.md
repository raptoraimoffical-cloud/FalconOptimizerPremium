# Power Badge System

## Trust badges
- TRUSTED: Tier 1 verified (GUID-backed powercfg or registry-backed) or advisory firmware card.
- CONDITIONAL_HARDWARE: Tier 2 hardware-dependent setting that requires live discovery before apply.
- ADVISORY_ONLY + FIRMWARE_ONLY: BIOS/UEFI recommendation cards with no direct Windows write path.
- EXPERIMENTAL + UNDOCUMENTED + UNSUPPORTED_ON_THIS_SYSTEM: Tier 3 unresolved placeholders kept in quarantine only.

All visible power cards still render badge row, support, documentation status, and proof source metadata in the renderer UI.
