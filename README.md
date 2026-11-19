# Falcon Optimizer 2

Windows gaming optimizer for **minimum input latency and maximum FPS** — every tweak is real,
current (Windows 10 22H2 → Windows 11 25H2), hardware-aware, detects its own state, and can be
undone to the exact original value.

## Run it

**No install:** double-click **`Start Falcon.cmd`**. It asks for administrator rights once,
downloads the app runtime on first launch (needs [Node.js LTS](https://nodejs.org) the first time
only), then opens Falcon.

**Developers:** `npm install` then `npm start` (run the terminal as administrator to avoid a UAC
prompt per change). `npm test` runs the catalog/engine test suite.

**Build:** `npm run dist` builds an installer and a single-file portable `.exe`
(`npm run portable` for the portable one only). Both request administrator rights at launch.

## Presets

| Preset | Mode | Tier | Who it is for |
| --- | --- | --- | --- |
| **Competitive** | Latency | Regular | Lowest input delay; Windows keeps working exactly as before |
| **Everyday Boost** | FPS | Regular | More FPS with zero change to how the PC works |
| **Extreme Latency** | Latency | Extreme | Dedicated gaming PC; strips Windows down — things break on purpose |
| **Extreme FPS** | FPS | Extreme | Same, tuned for maximum frames |
| **Custom** | — | — | Any selection you save from the apply dialog |

- **Latency mode** wins every conflict for input delay (CPU C-states off, NIC interrupt moderation
  off, short fixed scheduler quanta). **FPS mode** keeps C-states for boost headroom; every latency
  tweak that costs no FPS is still applied.
- **Extreme** adds service/app stripping, update pausing and security trade-offs (VBS/HVCI,
  hypervisor, CPU mitigations). Every Extreme item states exactly what breaks, and applying them
  requires typing `EXTREME`.
- Hardware routing: dual-CCD Ryzen X3D keeps AMD core parking, laptops only change "plugged in"
  power settings, Windows 11-only items are marked N/A on Windows 10.

## Pages

- **Dashboard** — presets, one-click apply, and health checks for things no tweak can fix
  (XMP/EXPO off, monitor below max refresh, Power saver plan, forced HPET, old GPU driver, low disk).
- **Tweaks** — the full catalog with live status, how each works, trade-offs and the exact steps.
- **Speed Boost** — ~30 cleaners (temp, update/crash leftovers, browser/launcher/app caches) with
  per-item sizes; only things apps rebuild on their own.
- **Games** — finds Steam/Epic/Riot/Battle.net games (or add any exe): High CPU priority,
  Defender folder exclusion, DSCP QoS, high-performance GPU on hybrid laptops, in-game tips.
- **Tools** — timer resolution service, Falcon NVIDIA profile, trusted measuring/driver tools.
- **History** — every change, plus **Undo all**.

## Layout

```
Start Falcon.cmd     run from the folder, no install
main.js / preload.js Electron main process + IPC bridge
app/                 UI (vanilla JS/CSS, no build step)
catalog/             curated tweak catalog (JS modules, hardware-aware, schema-validated)
scripts/engine.ps1   apply / revert / detect + original-value journal
scripts/*.ps1        system profile, power plans, timer service, cleaner
src/main/            PowerShell runner + elevation, health checks, game discovery, updater
data/                game list, cleaner targets, tool links
tests/               node:test suite (npm test)
```

Changes are journaled to `%ProgramData%\FalconOptimizer\journal.json`; engine logs are in
`%ProgramData%\FalconOptimizer\logs`.
