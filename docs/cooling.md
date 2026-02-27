# Falcon Cooling Guide (practical, performance-first)

## Goals
- **Stable clocks** (avoid thermal throttling)
- **Low input latency** (consistent frame time)
- **Controlled noise** (fan curve that ramps early enough to prevent spikes)

## “On paper” optimal cooling approach
1. **Airflow first**
   - Front/side intake + rear/top exhaust.
   - Keep intakes filtered; clean filters monthly.
   - Avoid negative pressure (too much exhaust) if your case is dusty.

2. **CPU cooling**
   - Re-paste if temps are unstable (good paste, proper mounting pressure).
   - For high-FPS esports: prioritize **fast transient cooling** (fans ramp earlier).
   - If you see spikes: raise mid-range fan % (50–75°C).

3. **GPU cooling**
   - Keep GPU fans from “zero RPM” when gaming (if your model allows).
   - Undervolting often gives **lower temps + same FPS**. Use MSI Afterburner.
   - Keep hotspot (junction) under control: aggressive curve after ~70°C.

4. **Fan curve philosophy**
   - Don’t wait for 80–90°C to ramp; ramp **before** the spike.
   - Use 4–6 points:
     - 30–40°C: quiet baseline
     - 50–65°C: steady ramp (prevents spikes)
     - 70–80°C: strong ramp
     - 85°C+: 100% emergency

5. **Laptop notes**
   - Best “cooling upgrade” is clean vents + raise back of laptop.
   - Use Performance mode **only when plugged in**.
   - If the chassis saturates with heat, reduce boost spikes (Balanced preset).

## Recommended presets (starting points)
- **Quiet curve**: 35°C→15%, 55°C→30%, 70°C→50%, 80°C→70%, 90°C→95%
- **Aggressive curve**: 30°C→25%, 45°C→45%, 60°C→70%, 72°C→90%, 80°C→100%

## Tools
- **FanControl (Rem0o)**: best universal fan control + curves (recommended).
- Vendor tools: ASUS Armoury Crate / MSI Center / Alienware Command Center, etc.

## Troubleshooting
- If temps still climb:
  - Check fan direction
  - Re-seat cooler
  - Reduce dust
  - Verify pump speed (AIO)
  - Consider undervolt / power limit (GPU) for the best perf-per-watt
