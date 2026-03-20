# Power Safety Risk Report

Generated: 2026-03-20T07:20:48.401Z

## Totals
- Items scanned: 2782
- Items with at least one new safety badge: 403
- BLUESCREEN_RISK: 85
- BOOT_RISK: 280
- UI_BUG_RISK: 5
- DEVICE_DISCONNECT_RISK: 132

## File breakdown
### data/power/power_management_catalog.json
- Items: 567
- Items with safety badges: 204
- BLUESCREEN_RISK: 15
- BOOT_RISK: 163
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 58
- Sample IDs: powercfg_sleep_after, powercfg_allow_hybrid_sleep, powercfg_hibernate_after, registry_allow_standby_states, powercfg_system_unattended_sleep_timeout, powercfg_require_a_password_on_wake, registry_allow_wake_timers, powercfg_sleep_button_action, registry_fast_startup, registry_connected_standby_policy, registry_network_connectivity_in_standby, nic_wake_on_rtc

### tweaks/power.management.storage_disk.json
- Items: 7
- Items with safety badges: 6
- BLUESCREEN_RISK: 6
- BOOT_RISK: 6
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 0
- Sample IDs: pm_storage_nvme_apst, pm_storage_nvme_idle_timeout, pm_storage_sata_alpm, pm_storage_ahci_hipm, pm_storage_ahci_dipm, pm_storage_storport_link_power_management

### tweaks/power.management.usb.json
- Items: 5
- Items with safety badges: 5
- BLUESCREEN_RISK: 0
- BOOT_RISK: 0
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 5
- Sample IDs: pm_device_usb_selective_suspend, pm_device_usb_3_link_power_management, pm_device_usb_root_hub_selective_suspend, pm_device_hid_idle_timeout, pm_device_camera_device_idle_suspend

### tweaks/power.management.wireless_ethernet.json
- Items: 11
- Items with safety badges: 11
- BLUESCREEN_RISK: 0
- BOOT_RISK: 0
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 11
- Sample IDs: pm_nic_wireless_adapter_power_saving_mode, pm_nic_energy_efficient_ethernet, pm_nic_green_ethernet, pm_nic_power_saving_mode, pm_nic_wake_on_magic_packet, pm_nic_wake_on_pattern_match, pm_nic_arp_offload, pm_nic_ns_offload, pm_nic_dma_coalescing, pm_nic_reduce_speed_on_power_down, pm_nic_auto_disable_gigabit

### tweaks/power.management.sleep_hibernate_modern_standby.json
- Items: 6
- Items with safety badges: 6
- BLUESCREEN_RISK: 0
- BOOT_RISK: 6
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 0
- Sample IDs: pm_registry_allow_standby_states, pm_registry_allow_wake_timers, pm_registry_fast_startup, pm_registry_connected_standby_policy, pm_registry_network_connectivity_in_standby, pm_registry_hibernateenabled

### tweaks/power.management.device_wake.json
- Items: 4
- Items with safety badges: 4
- BLUESCREEN_RISK: 0
- BOOT_RISK: 2
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 2
- Sample IDs: pm_nic_wake_on_magic_packet, pm_nic_wake_on_pattern_match, pm_registry_allow_wake_timers, pm_registry_network_connectivity_in_standby

### tweaks/power.management.buttons_lid.json
- Items: 3
- Items with safety badges: 3
- BLUESCREEN_RISK: 0
- BOOT_RISK: 3
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 0
- Sample IDs: pm_registry_allow_standby_states, pm_registry_fast_startup, pm_registry_connected_standby_policy

### tweaks/power.management.energy_saver.json
- Items: 5
- Items with safety badges: 0
- BLUESCREEN_RISK: 0
- BOOT_RISK: 0
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 0

### tweaks/power.management.hidden_experimental.json
- Items: 429
- Items with safety badges: 91
- BLUESCREEN_RISK: 9
- BOOT_RISK: 51
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 42
- Sample IDs: pm_powercfg_hibernate_after, pm_nic_wake_on_rtc, pm_nic_wake_on_usb, pm_nic_wake_on_lan_sleep_policy, pm_nic_wake_on_keyboard, pm_nic_wake_on_mouse, pm_nic_wake_on_bluetooth, pm_nic_wake_on_pcie_device, pm_nic_wake_on_modem_ring, pm_powercfg_reduce_speed_on_power_down, pm_powercfg_hibernate_policy_1, pm_powercfg_hibernate_policy_2

### tweaks/advanced.msi_mode.json
- Items: 17
- Items with safety badges: 17
- BLUESCREEN_RISK: 17
- BOOT_RISK: 11
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 0
- Sample IDs: adv.msi.disable_all, adv.msi.enable_net, adv.msi.enable_usb, adv.msi.enable_gpu, adv.msi.status, adv.msi.auto_gpu_audio, adv.msi.open_msi_utility_v3, adv.msi.gpu_msi_toggle, adv.msi.gpu_msi_toggle__revert, adv.msi.high_definition_audio_controllers_msi_toggle, adv.msi.high_definition_audio_controllers_msi_toggle__revert, adv.msi.network_adapter_msi_toggle

### tweaks/expansion.boot_timer.bcdedit.json
- Items: 35
- Items with safety badges: 35
- BLUESCREEN_RISK: 35
- BOOT_RISK: 35
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 0
- Sample IDs: exp.boot.disabledynamictick, exp.boot.disabledynamictick__revert, exp.boot.useplatformclock_on, exp.boot.useplatformclock_on__revert, exp.boot.useplatformclock_off, exp.boot.useplatformclock_off__revert, exp.boot.useplatformtick_on, exp.boot.useplatformtick_on__revert, exp.boot.useplatformtick_off, exp.boot.useplatformtick_off__revert, exp.boot.tscsync_legacy, exp.boot.tscsync_legacy__revert

### tweaks/expansion.imported.power_bcd.json
- Items: 3
- Items with safety badges: 3
- BLUESCREEN_RISK: 3
- BOOT_RISK: 3
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 0
- Sample IDs: import.imported.check_plan_import.7a3ff14bd7, import.imported.plan_import_worked.063840f8c8, import.imported.power_plan.d8e9c14aa8

### tweaks/expansion.falcon_new_tweaks.json
- Items: 58
- Items with safety badges: 1
- BLUESCREEN_RISK: 0
- BOOT_RISK: 0
- UI_BUG_RISK: 1
- DEVICE_DISCONNECT_RISK: 0
- Sample IDs: falcon_new_disable_cursor_suppression

### tweaks/hardcore.tweaks.json
- Items: 315
- Items with safety badges: 3
- BLUESCREEN_RISK: 0
- BOOT_RISK: 0
- UI_BUG_RISK: 1
- DEVICE_DISCONNECT_RISK: 2
- Sample IDs: hc_windows.core_core.disable_device_power_saving, hc_hardware.peripherals_usb_disable_selective_suspend, hc_ui_disable_animations__hardcore.tweaks

### tweaks/performance.lib.misc.json
- Items: 1306
- Items with safety badges: 10
- BLUESCREEN_RISK: 0
- BOOT_RISK: 0
- UI_BUG_RISK: 2
- DEVICE_DISCONNECT_RISK: 8
- Sample IDs: perf_apply_all_safe, perf_bundle_registry, core.disable_device_power_saving, power_disable_usb_selective_suspend, power_disable_usb_selective_suspend__revert, exp.power.usb_selective_suspend_off__performance.lib.misc, dpc_usb_selective_suspend_off__performance.lib.misc, hc_windows.core_core.disable_device_power_saving__performance.lib.misc, hc_hardware.peripherals_usb_disable_selective_suspend__performance.lib.misc, input_scan_hid_power__performance.lib.misc

### tweaks/core.boostpack.registry.json
- Items: 1
- Items with safety badges: 1
- BLUESCREEN_RISK: 0
- BOOT_RISK: 0
- UI_BUG_RISK: 1
- DEVICE_DISCONNECT_RISK: 1
- Sample IDs: core.boostpack.registry

### tweaks/controller.lab.json
- Items: 10
- Items with safety badges: 3
- BLUESCREEN_RISK: 0
- BOOT_RISK: 0
- UI_BUG_RISK: 0
- DEVICE_DISCONNECT_RISK: 3
- Sample IDs: controller.usb.selective_suspend, controller.usb.selective_suspend__revert, controller.usb.power_mgmt_checklist

## Legacy duplicate quarantine
- `tweaks/_performance_library/imported_catalog.json` now annotates duplicate `UserPreferencesMask`, `CursorCaptureEnabled`, MSI, and BCD/timer actions as `quarantined_legacy` with `excludeFromBroadPresets=true`.
