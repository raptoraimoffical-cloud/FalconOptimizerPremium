# Performance Library Import Report
Generated: 2026-02-06T06:28:16.708285Z
## Source hashes
- optimizer_pack: SHA256 `105d57e979bb96c2ea15bd828a1e48d62ee8896095366eca68e187b0c572998f` (3423 lines)
- service_pack: SHA256 `cd92b3e7b15f35f2381ef571f9f3530160bba9a5e69c0225b1f38a7ba4d15d6e` (544 lines)

## Extraction coverage
Actions include all executable commands (registry, services, bcdedit, schtasks, powercfg, netsh, dism, etc.) while UI/menu lines are tracked separately.
- optimizer_pack: 1518 executable actions captured; 530 control-flow/menu lines tracked; 968 UI/output lines tracked.
- service_pack: 353 executable actions captured; 48 control-flow/menu lines tracked; 101 UI/output lines tracked.

## Derived user-choice templates
- Scheduler profiles: FPS / Latency / Balanced / Custom (Win32PrioritySeparation)
- Timer resolution startup presets: 0.500 / 0.504 / 0.507 / Custom (Run\TimerResolution)

## Update/driver-critical services disabled by scripts (must be gated)
- BITS
- DeviceInstall
- DsmSvc
- InstallService
- TrustedInstaller
- UsoSvc
- wuauserv

## Service overlaps with Falcon
- 90 overlapping services (see `tweaks/_performance_library/conflict_map.json`).
