# Power Description Style Guide

Updated 2026-03-20T03:06:34.561Z.

## Required fields for every visible item
shortDescription, longDescription, whatItDoes, whyGamersCare, fpsImpact, latencyImpact, powerImpact, heatImpact, stabilityRisk, recommendedFor, avoidIf.

## Quality requirements
1. Mention the actual mechanism family (CPU scheduler, sleep/wake, I/O link power, network power, display/GPU power, or registry-backed policy).
2. Include a concrete tradeoff (responsiveness vs power/heat) for that specific item family.
3. Avoid generic clone text and avoid unproven certainty.
4. If semantics are unresolved, explicitly mark the item as advanced/experimental and non-main.

