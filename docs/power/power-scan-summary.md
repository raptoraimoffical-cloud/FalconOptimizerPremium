# Power Management Full Scan Summary

- Total entries: **567**
- Unmapped entries (`sourceType=powercfg_unmapped`): **345**
- Missing GUID entries: **564**
- Unsupported apply-method entries: **345**
- Placeholder description entries: **567**
- Processor policy placeholder entries: **39** (`processor_policy_1..39`)

## Source type breakdown

- `powercfg_unmapped`: 345
- `firmware_candidate`: 80
- `nic_advanced`: 45
- `gpu_feature`: 25
- `registry_power`: 24
- `device_power_flag`: 23
- `storage_feature`: 22
- `powercfg`: 3

## High-noise families detected

- `core_parking`: 57
- `heterogeneous_scheduling`: 11
- `latency_hint`: 4
- `performance_history`: 2
- `processor_idle`: 6
- `processor_policy_n`: 39

## Notes

- This summary is data-driven from `data/power/power_management_catalog.json` and is intended to feed cleanup, classification, and description-generation workflows.
