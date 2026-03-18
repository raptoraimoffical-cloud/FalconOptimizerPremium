# Power Management: Unknown/Weird Setting Explanations (Operator Guide)

## Direct answers to your reported confusing items

### Processor performance history count (`powercfg_processor_performance_history_count`)
- **What it is:** A history-depth knob used by Windows processor power/scheduling logic to keep prior performance samples.
- **Practical effect:** Usually negligible for FPS and input latency compared with real controls like min/max processor state, boost mode, and core parking.
- **Risk:** Low direct risk; changing it can make behavior less predictable across hardware/firmware.
- **Recommendation:** Keep out of main UI. If retained, put in **Advanced/Experimental** with explicit warning.

### Processor performance history length (`powercfg_processor_performance_history_length`)
- **What it is:** Time-window style setting for historical performance sampling.
- **Practical effect:** Not a direct “higher FPS” switch.
- **Risk:** Low-to-moderate confusion risk (users expect immediate gain but typically get none).
- **Recommendation:** Same handling as history count (advanced/experimental only).

### Processor policy 1..39 (`powercfg_processor_policy_1` ... `_39`)
- **What it is:** Placeholder/unresolved policy index names in your current catalog, not reliable end-user labels.
- **Practical effect:** Unknown unless exact GUID/alias mapping is proven per item.
- **Risk:** High trust risk if shown as normal settings; can be no-op, ignored, or platform-dependent.
- **Recommendation:** Hide from main UI. Keep only in **Experimental** with UNDOCUMENTED warning until proven.

## Badge intent model (use consistently across all power settings)

- `MAX_PERFORMANCE`: pushes system to higher sustained performance behavior.
- `HIGH_POWER_USE`: increases wattage materially.
- `MAX_POWER_USE`: one of the most aggressive power-usage choices.
- `POWER_SAVING_DISABLED`: disables/weakens a power-saving feature.
- `LATENCY_RESPONSIVENESS`: likely to reduce wake/ramp delays.
- `FPS_CONSISTENCY`: likely to reduce frame-time variance from downclock/parking.
- `BATTERY_NEGATIVE`: hurts battery life.
- `THERMAL_RISK`: can increase heat significantly.
- `SAFE_DEFAULT`: low-risk setting for broad usage.
- `ADVANCED`: not beginner-friendly.
- `EXPERIMENTAL`: uncertain gain and/or platform dependence.
- `UNDOCUMENTED`: not fully documented/proven.
- `UNSUPPORTED_ON_THIS_SYSTEM`: detected but not valid to apply/verify here.
- `REQUIRES_REBOOT`: reboot needed for reliable effect.
- `LAPTOP_ONLY`: relevant mainly on battery-capable systems.
- `DESKTOP_ONLY`: mostly relevant on AC/non-battery systems.
- `APP_SPECIFIC`: only relevant to named app(s).
- `SYSTEM_WIDE`: affects Windows globally.

## Main-UI inclusion rule
A power setting may appear in main UI only if all are true:
1. Proven mapping (GUID/alias/docs) exists.
2. Apply path is real and stable.
3. Verify path can read live value.
4. Rollback can restore previous captured value.
5. User-facing description is specific (no placeholders).

Anything failing one of these should move to advanced/experimental/hidden.
