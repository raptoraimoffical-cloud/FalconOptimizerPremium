'use strict';
// Step builders for catalog items. Every step maps 1:1 to a handler in scripts/engine.ps1.
// Use R`...` (String.raw) for registry paths and PowerShell so backslashes survive.

const R = String.raw;

/** Set a registry value. regType: DWORD | QWORD | SZ | EXPAND_SZ | MULTI_SZ | BINARY */
const regSet = (path, name, regType, value) => ({ type: 'reg', path, name, regType, value });
/** Remove a registry value (Windows default for most policy keys is "not present"). */
const regDel = (path, name) => ({ type: 'reg', path, name, delete: true });
/** start: Disabled | Manual | Automatic | AutomaticDelayed */
const service = (name, start) => ({ type: 'service', name, start });
/** state: Disabled | Enabled */
const task = (path, state) => ({ type: 'task', path, state });
const bcd = (name, value) => ({ type: 'bcd', name, value: String(value) });
const bcdDel = (name) => ({ type: 'bcd', name, delete: true });
/** Power setting on the active scheme. scope: both | ac | dc */
const powercfg = (sub, setting, value, scope = 'both') => ({ type: 'powercfg', sub, setting, value, scope });
/** NIC advanced property (standardized *Keyword or vendor keyword) on every physical adapter that exposes it. */
const netadapter = (keyword, value) => ({ type: 'netadapter', keyword, value: String(value) });
/** Custom PowerShell. `check` must print true/false (or "na" when not applicable). */
const ps = (script, check) => (check ? { type: 'ps', script, check } : { type: 'ps', script });

module.exports = { R, regSet, regDel, service, task, bcd, bcdDel, powercfg, netadapter, ps };
