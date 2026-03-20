# Power Description Style Guide

Visible power cards must include:
shortDescription, longDescription, whatItDoes, whyGamersCare, fpsImpact, latencyImpact, powerImpact, heatImpact, stabilityRisk, recommendedFor, avoidIf.

Trust wording rules:
1. Tier 1: describe behavior as verified with GUID or registry proof source.
2. Tier 2: state conditional hardware discovery requirement in plain language.
3. Tier 3: quarantine only; never present as normal optimization cards.
4. Firmware cards: always mark advisory-only and firmware-only.

## Safety wording rules (required)
1. Do not use vague warnings such as "May be risky".
2. warningText must name the concrete failure mode (BSOD, boot failure, cursor breakage, disconnects).
3. riskNotes must include at least one hardware/driver compatibility statement for BLUESCREEN_RISK and BOOT_RISK.
4. UI_BUG_RISK items must call out cursor/shell side effects.
5. DEVICE_DISCONNECT_RISK items must call out USB/HID/Bluetooth/NIC disconnect and wake behavior.
6. Include rollbackNotes wherever a rollback path exists.
