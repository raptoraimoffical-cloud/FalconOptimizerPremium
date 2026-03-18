# Power Badge System

This project uses deterministic badge assignment for power settings.

## Badges
- MAX_PERFORMANCE
- HIGH_POWER_USE
- MAX_POWER_USE
- POWER_SAVING_DISABLED
- LATENCY_RESPONSIVENESS
- FPS_CONSISTENCY
- BATTERY_NEGATIVE
- THERMAL_RISK
- SAFE_DEFAULT
- ADVANCED
- EXPERIMENTAL
- UNDOCUMENTED
- UNSUPPORTED_ON_THIS_SYSTEM
- REQUIRES_REBOOT
- LAPTOP_ONLY
- DESKTOP_ONLY
- APP_SPECIFIC
- SYSTEM_WIDE

## Rule highlights
- UNDOCUMENTED/EXPERIMENTAL is automatically set for unresolved placeholders (e.g., policy-N families).
- UNSUPPORTED_ON_THIS_SYSTEM is set when GUID mapping is missing for powercfg-backed entries.
- SAFE_DEFAULT is only set when the item is not experimental/undocumented/unsupported.
- SYSTEM_WIDE is set for power policy entries unless explicitly app-scoped.
