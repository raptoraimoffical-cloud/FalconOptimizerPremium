# Falcon Optimizer — v1 audit and v2 rebuild

## What v1 contained

5,657 catalog entries across 130 JSON files, a 9,700-line renderer, a 2,800-line main process,
and ~300 imported batch/PowerShell scripts.

| Finding | Examples |
| --- | --- |
| **~75% duplication** | The same tweak copied into 3–6 files (`__performance.lib.misc`, `hc_…`); 135 identical IDs; `FalconLibrary/` shipped 3 times; `scripts/imported/oneclick*` duplicated twice |
| **Invented registry values** | `nvlddmkm\OptimizeNVIDIAGc6Idle`, `OptimizeNVIDIAFrameScheduling`, `OptimizeGPUIdleThresholds` — the driver never reads them |
| **Placebo** | `TscSyncPolicy` in the registry, `DisablePagingExecutive`, `NonBestEffortLimit` ("20% QoS reservation" myth), MMCSS `Games` task values, disabling already trigger-start services, RAM "cleaners", registry "deep cleaners", 429 auto-generated "Processor policy 31"-style power entries |
| **Fake items** | "Placeholder" cards, "Hint" cards that only printed text, cards that only opened a URL |
| **Outdated / harmful** | TCP auto-tuning off (caps downloads), IPv6 off, forced HPET (`useplatformclock`), global FSO disable, MPO disable in presets (hurts borderless latency), `MouseDataQueueSize` (drops input), page file off, Win7 Media Center tasks, Defender policy keys ignored since 2020 |
| **Mislabeled risk** | Spectre/Meltdown mitigations off and VBS off marked **Safe** |
| **Broken commands** | Speed Boost cleaners used `'$env:TEMP\*'` in single quotes, so PowerShell never expanded the path and most deletes targeted nothing; one deleted Telegram's `tdata` (your login and chats) |
| **Engine issues** | UAC prompt per tweak, UAC-disable steps, NSudo fallbacks, first failure aborted the batch, toggle state came from history instead of the real system |

## What v2 is

- **~60 curated items** + 32 cleaners. Each one is real, documented, version/hardware-gated, has a
  stated evidence level, and is reversible.
- **Real state detection** for every toggle (registry, services, tasks, bcdedit, powercfg, NIC
  properties, custom checks) in a single PowerShell pass.
- **Exact undo**: the original value of everything Falcon touches is journaled before the first
  change; revert restores it (falls back to Windows defaults if no original was recorded).
- **Latency vs FPS** resolved per conflict, plus **Regular vs Extreme** tiers. Regular presets never
  remove Windows functionality; Extreme items each list what breaks and need a typed confirmation.
- **Hardware routing**: dual-CCD X3D (keeps AMD core parking), Intel hybrid, laptops (AC-only),
  Windows 10 vs 11, Wi-Fi vs Ethernet, multi-GPU laptops.
- **Health checks** for the things that matter more than tweaks: XMP/EXPO, refresh rate,
  power plan, forced HPET, VBS, ReBAR, driver age, single-channel RAM, disk space, page file.
- **Modern additions** v1 lacked: windowed-game flip model (Win11), global timer resolution
  requests (Win11), Fault Tolerant Heap off, Delivery Optimization upload off, WU driver-swap block,
  Recall off, game folder Defender exclusions, per-game IFEO priority, Steam/Epic/Riot discovery.
- A 16-test suite guards all of the above, including a ban-list so placebo tweaks cannot return.

## Deliberately not included

Prefetch clearing (slows launches), disabling Defender outright (impossible while Tamper
Protection is on; Falcon lowers scan impact instead), disabling Windows Update services (Windows
repairs them — Falcon uses the official pause), UAC off (breaks Store apps), firewall off (no
performance effect), Process "destroyers" (no measurable gain on modern CPUs).
