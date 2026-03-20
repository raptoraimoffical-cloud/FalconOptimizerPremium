# Power Badge System

## Trust badges
- TRUSTED: Tier 1 verified (GUID-backed powercfg or registry-backed) or advisory firmware card.
- CONDITIONAL_HARDWARE: Tier 2 hardware-dependent setting that requires live discovery before apply.
- ADVISORY_ONLY + FIRMWARE_ONLY: BIOS/UEFI recommendation cards with no direct Windows write path.
- EXPERIMENTAL + UNDOCUMENTED + UNSUPPORTED_ON_THIS_SYSTEM: Tier 3 unresolved placeholders kept in quarantine only.

## Safety risk badges
- BLUESCREEN_RISK: The tweak can plausibly crash Windows or trigger BSOD on unsupported drivers, hardware, or firmware combinations.
- BOOT_RISK: The tweak can plausibly cause boot failure, black screen, recovery loop, startup failure, resume failure, or broken wake/hibernate/startup behavior.
- UI_BUG_RISK: The tweak can plausibly break cursor visibility, desktop visuals, shell behavior, explorer behavior, or other UI/input presentation behavior.
- DEVICE_DISCONNECT_RISK: The tweak can plausibly cause mouse, keyboard, controller, Bluetooth, USB, network, audio, dongle, or other device disconnect / wake / reconnect instability.

## Rendering requirements
- All four safety badges render as normal badges in tweak cards and power catalog cards.
- A visible warning strip is rendered under badge rows when any safety badge is present.
- BOOT_RISK and BLUESCREEN_RISK tweaks escalate confirmation and can require typed confirmation text.
