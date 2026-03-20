#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const catalogPath = path.join(root, 'data/power/power_management_catalog.json');
const profilesPath = path.join(root, 'tweaks/power.management.profiles.json');
const auditJsonPath = path.join(root, 'output/power/power-audit-report.json');
const auditMdPath = path.join(root, 'output/power/power-audit-report.md');
const unresolvedMdPath = path.join(root, 'output/power/power-unresolved-report.md');
const badgeDocPath = path.join(root, 'docs/power-badge-system.md');
const descGuidePath = path.join(root, 'docs/power-description-style-guide.md');
const megaPromptPath = path.join(root, 'docs/power-management-mega-prompt.md');

const nowIso = new Date().toISOString();
const data = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));

const ADVANCED_HINTS = [
  'heterogeneous', 'efficiency class', 'class 1', 'qos', 'utility', 'dependency',
  'responsiveness override', 'coordination feedback', 'latency hint', 'autonomous',
  'policy override', 'drips', 'ecoqos'
];

function includesAny(text, hints) {
  const t = String(text || '').toLowerCase();
  return hints.some((h) => t.includes(h));
}

function classify(item) {
  const id = String(item.id || '').toLowerCase();
  const title = String(item.title || item.name || '').toLowerCase();
  const desc = String(item.description || item.longDescription || '').toLowerCase();
  const text = `${id} ${title} ${desc}`;
  const missingGuid = !item.subgroupGuid || !item.settingGuid;
  const unresolved = item.sourceType === 'powercfg_unmapped' || (item.sourceType === 'powercfg' && missingGuid);
  const policyN = /processor_policy_\d+/.test(id) || /core_parking_policy_\d+/.test(id);
  const perfHistory = id.includes('performance_history_count') || id.includes('performance_history_length');

  let resolvedStatus = 'documented_supported';
  let uiVisibility = 'main';
  let documentationStatus = 'POWERCFG_ALIAS_CONFIRMED';
  let proofSource = 'powercfg_qh';
  let reason = 'Documented setting with writable mapping.';

  if (policyN) {
    resolvedStatus = 'undocumented_internal';
    uiVisibility = 'hidden';
    documentationStatus = 'UNDOCUMENTED_INTERNAL';
    proofSource = 'unresolved';
    reason = 'Internal policy placeholder index; no trustworthy alias semantics.';
  } else if (perfHistory) {
    resolvedStatus = unresolved ? 'documented_but_unverified' : 'documented_hidden_supported';
    uiVisibility = unresolved ? 'experimental' : 'advanced';
    documentationStatus = unresolved ? 'UNRESOLVED' : 'MICROSOFT_HIDDEN_BUT_DOCUMENTED';
    proofSource = unresolved ? 'unresolved' : 'powercfg_alias';
    reason = 'Scheduler history behavior, low gaming value, advanced-only.';
  } else if (unresolved) {
    resolvedStatus = missingGuid ? 'unsupported_missing_guid' : 'undocumented_internal';
    uiVisibility = 'experimental';
    documentationStatus = missingGuid ? 'UNRESOLVED' : 'UNDOCUMENTED_INTERNAL';
    proofSource = missingGuid ? 'repo_placeholder_only' : 'unresolved';
    reason = missingGuid ? 'Missing subgroup/setting GUID; apply/verify cannot be trusted.' : 'Undocumented or OEM/internal mapping.';
  } else if (item.sourceType === 'firmware_candidate') {
    resolvedStatus = 'platform_specific';
    uiVisibility = 'advanced';
    documentationStatus = 'PLATFORM_SPECIFIC_INFERRED';
    proofSource = 'subgroup_guid_mapping';
    reason = 'Firmware recommendation only; not directly writable by Falcon.';
  } else if (includesAny(text, ADVANCED_HINTS)) {
    resolvedStatus = 'documented_hidden_supported';
    uiVisibility = 'advanced';
    documentationStatus = 'MICROSOFT_HIDDEN_BUT_DOCUMENTED';
    proofSource = 'powercfg_alias';
    reason = 'Advanced hidden scheduler/power behavior; preserve but not beginner-facing.';
  }

  return { missingGuid, unresolved, policyN, perfHistory, resolvedStatus, uiVisibility, documentationStatus, proofSource, reason };
}

function impacts(text) {
  const t = text.toLowerCase();
  const fps = t.match(/processor|min|max|boost|parking|qos|utility|gpu|display|latency|network/) ? 'Can improve FPS consistency; rarely increases average FPS alone.' : 'Usually negligible FPS impact.';
  const latency = t.match(/latency|parking|idle|boost|responsiveness|network|usb|pcie|storage/) ? 'Can reduce wake/ramp delay and input response variance.' : 'Little direct latency impact.';
  const power = t.match(/disable|maximum|min cores|boost|off|performance/) ? 'Likely increases power draw versus defaults.' : 'Typically neutral or power-saving depending on value.';
  const heat = t.match(/boost|minimum processor|parking|min cores|max performance|disable/i) ? 'Can raise sustained temperatures under load.' : 'Low thermal impact unless paired with aggressive settings.';
  return { fps, latency, power, heat };
}

function detectBadges(item, c) {
  const text = `${item.id || ''} ${item.title || ''} ${item.subcategory || ''}`.toLowerCase();
  const b = new Set(['SYSTEM_WIDE']);

  if (c.uiVisibility === 'advanced') b.add('ADVANCED');
  if (c.uiVisibility === 'experimental') b.add('EXPERIMENTAL');
  if (c.uiVisibility === 'hidden' || c.documentationStatus === 'UNDOCUMENTED_INTERNAL' || c.documentationStatus === 'UNRESOLVED') b.add('UNDOCUMENTED');
  if (c.missingGuid || c.resolvedStatus === 'unsupported_missing_guid') b.add('UNSUPPORTED_ON_THIS_SYSTEM');

  if (text.match(/boost|max|minimum processor|performance floor|performance ceiling|preferred core|unpark|min cores|cooling policy/)) b.add('MAX_PERFORMANCE');
  if (text.match(/boost|minimum processor|idle disable|core parking|min cores|disable|aspm off|usb selective suspend/)) b.add('POWER_SAVING_DISABLED');
  if (text.match(/boost|minimum processor|idle disable|parking|min cores|aspm|usb selective suspend|high performance/)) b.add('HIGH_POWER_USE');
  if (text.match(/minimum processor state|idle disable|max performance|core parking min cores/)) b.add('MAX_POWER_USE');
  if (text.match(/latency|responsiveness|parking|idle|network|usb|storage|pcie/)) b.add('LATENCY_RESPONSIVENESS');
  if (text.match(/processor|min|max|boost|parking|qos|utility|response time|dependency/)) b.add('FPS_CONSISTENCY');

  const bluescreenRisk = /msi|message signaled|platform clock|hpet|timer|dynamic tick|nvme|storage controller|pcie|aspm|ulps|interrupt/.test(text);
  const bootRisk = /platform clock|hpet|bcd|dynamic tick|timer|aspm|storage/.test(text);
  const uiBugRisk = /cursor|userpreferencesmask|desktop composition|visual effects/.test(text);
  const deviceDisconnectRisk = /usb selective suspend|device wake|nic wake|bluetooth|wireless adapter/.test(text);

  if (bluescreenRisk) b.add('BLUESCREEN_RISK');
  if (bootRisk) b.add('BOOT_RISK');
  if (uiBugRisk) b.add('UI_BUG_RISK');
  if (deviceDisconnectRisk) b.add('DEVICE_DISCONNECT_RISK');

  if (text.match(/battery|low battery|reserve battery|dc|power saver|sleep/)) b.add('LAPTOP_ONLY');
  if (text.match(/battery|high_power_use|max_power_use|power_saving_disabled/)) b.add('BATTERY_NEGATIVE');
  if (text.match(/boost|minimum processor|idle disable|core parking|min cores/)) b.add('THERMAL_RISK');
  if (!b.has('EXPERIMENTAL') && !b.has('UNDOCUMENTED') && !b.has('UNSUPPORTED_ON_THIS_SYSTEM')) b.add('SAFE_DEFAULT');

  if (item.requiresReboot) b.add('REQUIRES_REBOOT');
  if (text.match(/desktop|ac only/)) b.add('DESKTOP_ONLY');

  return Array.from(b);
}

function makeDescription(item, c) {
  const title = item.title || item.name || item.id;
  const scope = item.subcategory || item.category || 'Power management';
  const technical = c.unresolved
    ? 'This entry was discovered during catalog expansion but does not have a fully validated GUID mapping on this build.'
    : `Controls ${scope.toLowerCase()} behavior through ${item.sourceType === 'powercfg' ? 'powercfg policy indexes' : 'system power infrastructure'}.`;
  const recommendation = c.uiVisibility === 'main'
    ? 'Suitable for normal tuning profiles once verified on target hardware.'
    : c.uiVisibility === 'advanced'
      ? 'Advanced-only control; leave default unless you are tuning for a specific benchmarked outcome.'
      : c.uiVisibility === 'experimental'
        ? 'Keep outside the main UI. Change only in experimental mode with full rollback.'
        : 'Hidden from normal UI due to unresolved/internal semantics.';
  const imp = impacts(`${item.id} ${title} ${scope}`);

  return {
    shortDescription: c.unresolved
      ? `${title}: unresolved or internal power item; not recommended for standard tuning.`
      : `${title}: tunes ${scope.toLowerCase()} behavior for performance vs efficiency tradeoffs.`,
    longDescription: `${technical} ${recommendation}`,
    whatItDoes: c.perfHistory
      ? 'Changes how much historical CPU performance data Windows retains for internal policy decisions.'
      : c.policyN
        ? 'Internal Windows policy index placeholder. Exact semantics are undocumented in public docs.'
        : c.unresolved
          ? 'Represents a discovered power candidate without complete authoritative mapping.'
          : `Adjusts the active power plan value for ${title.toLowerCase()} using apply/verify/rollback flow.`,
    whyGamersCare: c.perfHistory
      ? 'Mostly irrelevant for FPS; this is scheduler history bookkeeping, not direct performance tuning.'
      : c.policyN
        ? 'You generally should not touch this. Misconfiguration may cause inconsistent boost behavior.'
        : 'Can affect frametime stability, ramp latency, and consistency during burst workloads.',
    fpsImpact: imp.fps,
    latencyImpact: imp.latency,
    powerImpact: imp.power,
    heatImpact: imp.heat,
    stabilityRisk: c.policyN || c.unresolved ? 'Medium to High if forced without mapping proof.' : 'Low to Medium depending on aggressiveness of chosen value.',
    recommendedFor: c.uiVisibility === 'main' ? 'Users optimizing system-wide performance profiles.' : (c.uiVisibility === 'advanced' ? 'Advanced users doing measured A/B testing.' : 'Not recommended for mainstream users.'),
    avoidIf: c.uiVisibility === 'main' ? 'Avoid aggressive values on thermally constrained laptops.' : 'Avoid unless you can validate and rollback safely.',
    documentationStatus: c.documentationStatus,
    proofSource: c.proofSource,
    sourceEvidence: c.reason
  };
}

const auditRows = [];
const unresolvedRows = [];
let rewrittenDescriptions = 0;

const updated = data.map((item) => {
  const c = classify(item);
  const d = makeDescription(item, c);
  const badges = detectBadges(item, c);
  const out = {
    ...item,
    shortDescription: d.shortDescription,
    longDescription: d.longDescription,
    name: item.name || item.title,
    description: d.longDescription,
    whatItDoes: d.whatItDoes,
    whyGamersCare: d.whyGamersCare,
    fpsImpact: d.fpsImpact,
    latencyImpact: d.latencyImpact,
    powerImpact: d.powerImpact,
    heatImpact: d.heatImpact,
    stabilityRisk: d.stabilityRisk,
    recommendedFor: d.recommendedFor,
    avoidIf: d.avoidIf,
    badges,
    documentationStatus: d.documentationStatus,
    proofSource: d.proofSource,
    sourceEvidence: d.sourceEvidence,
    resolvedStatus: c.resolvedStatus,
    uiVisibility: c.uiVisibility,
    verifyMethod: c.missingGuid && item.sourceType === 'powercfg_unmapped' ? 'unsupported (missing subgroupGuid/settingGuid)' : (item.verifyMethod || 'powercfg /query'),
    applyMethod: c.missingGuid && item.sourceType === 'powercfg_unmapped' ? 'unsupported (missing subgroupGuid/settingGuid)' : (item.applyMethod || 'powercfg -setacvalueindex/-setdcvalueindex'),
    rollbackMethod: item.rollbackMethod || 'restore previous stored value'
  };
  rewrittenDescriptions += 1;

  const audit = {
    id: out.id,
    current_title: out.title,
    sourceType: out.sourceType,
    subgroupGuid: out.subgroupGuid || '',
    settingGuid: out.settingGuid || '',
    current_applyMethod: out.applyMethod || '',
    current_verifyMethod: out.verifyMethod || '',
    resolved_status: c.resolvedStatus,
    proof_source: c.proofSource,
    ui_visibility: c.uiVisibility,
    reason: c.reason
  };
  auditRows.push(audit);
  if (c.uiVisibility === 'experimental' || c.uiVisibility === 'hidden') unresolvedRows.push(audit);

  return out;
});

fs.writeFileSync(catalogPath, JSON.stringify(updated, null, 2) + '\n');

const mainIds = updated.filter((x) => x.uiVisibility === 'main').map((x) => x.id);
const profiles = JSON.parse(fs.readFileSync(profilesPath, 'utf8'));
profiles.uiExposedIds = mainIds;
fs.writeFileSync(profilesPath, JSON.stringify(profiles, null, 2) + '\n');

const summary = {
  generatedAt: nowIso,
  totalItems: updated.length,
  mainCount: updated.filter((x) => x.uiVisibility === 'main').length,
  advancedCount: updated.filter((x) => x.uiVisibility === 'advanced').length,
  experimentalCount: updated.filter((x) => x.uiVisibility === 'experimental').length,
  hiddenCount: updated.filter((x) => x.uiVisibility === 'hidden').length,
  rewrittenDescriptions,
  unsupportedUnmapped: updated.filter((x) => x.sourceType === 'powercfg_unmapped').length
};

fs.mkdirSync(path.dirname(auditJsonPath), { recursive: true });
fs.mkdirSync(path.dirname(badgeDocPath), { recursive: true });
fs.writeFileSync(auditJsonPath, JSON.stringify({ summary, rows: auditRows }, null, 2) + '\n');

const mdHeader = `# Power Audit Report\n\nGenerated: ${nowIso}\n\n- Total audited: ${summary.totalItems}\n- Main: ${summary.mainCount}\n- Advanced: ${summary.advancedCount}\n- Experimental: ${summary.experimentalCount}\n- Hidden: ${summary.hiddenCount}\n- Rewritten descriptions: ${summary.rewrittenDescriptions}\n- Unmapped entries: ${summary.unsupportedUnmapped}\n\n`;
const mdTable = ['| id | sourceType | resolved_status | ui_visibility | proof_source | reason |','|---|---|---|---|---|---|']
  .concat(auditRows.map((r) => `| ${r.id} | ${r.sourceType} | ${r.resolved_status} | ${r.ui_visibility} | ${r.proof_source} | ${r.reason.replace(/\|/g, '/')} |`))
  .join('\n');
fs.writeFileSync(auditMdPath, mdHeader + mdTable + '\n');

const unresolvedMd = [
  '# Power Unresolved / Hidden Report',
  '',
  `Generated: ${nowIso}`,
  '',
  'These entries are not shown in the main UI because they are undocumented, unresolved, or unsupported.',
  '',
  '| id | status | visibility | reason |',
  '|---|---|---|---|',
  ...unresolvedRows.map((r) => `| ${r.id} | ${r.resolved_status} | ${r.ui_visibility} | ${r.reason.replace(/\|/g, '/')} |`)
].join('\n');
fs.writeFileSync(unresolvedMdPath, unresolvedMd + '\n');

const badgeDoc = `# Power Badge System\n\nThis project uses deterministic badge assignment for power settings.\n\n## Badges\n- MAX_PERFORMANCE\n- HIGH_POWER_USE\n- MAX_POWER_USE\n- POWER_SAVING_DISABLED\n- LATENCY_RESPONSIVENESS\n- FPS_CONSISTENCY\n- BATTERY_NEGATIVE\n- THERMAL_RISK\n- SAFE_DEFAULT\n- ADVANCED\n- EXPERIMENTAL\n- UNDOCUMENTED\n- UNSUPPORTED_ON_THIS_SYSTEM\n- REQUIRES_REBOOT\n- LAPTOP_ONLY\n- DESKTOP_ONLY\n- APP_SPECIFIC\n- SYSTEM_WIDE\n\n## Rule highlights\n- UNDOCUMENTED/EXPERIMENTAL is automatically set for unresolved placeholders (e.g., policy-N families).\n- UNSUPPORTED_ON_THIS_SYSTEM is set when GUID mapping is missing for powercfg-backed entries.\n- SAFE_DEFAULT is only set when the item is not experimental/undocumented/unsupported.\n- SYSTEM_WIDE is set for power policy entries unless explicitly app-scoped.\n`;
fs.writeFileSync(badgeDocPath, badgeDoc);

const descGuide = `# Power Description Style Guide\n\nEvery visible power item must include:\n- whatItDoes\n- whyGamersCare\n- fpsImpact\n- latencyImpact\n- powerImpact\n- heatImpact\n- stabilityRisk\n- recommendedFor\n- avoidIf\n- documentationStatus\n- proofSource\n\n## Quality rules\n1. No placeholder text (e.g., \"Live discovered powercfg item\").\n2. No fake certainty for undocumented settings.\n3. Unresolved settings must explicitly say they are unresolved/internal.\n4. Keep tradeoffs explicit (performance vs power/heat/stability).\n`;
fs.writeFileSync(descGuidePath, descGuide);

const megaPrompt = `# Falcon Power Management Mega Prompt (Repo-Hardened)\n\nUse this prompt in Codex when doing a full power-management refactor:\n\n---\nYou are auditing and hardening Falcon Optimizer power management end-to-end.\n\n## Hard requirements\n1. Audit every entry in data/power/power_management_catalog.json.\n2. Never invent semantics for undocumented/internal settings.\n3. Hide processor_policy_N and core_parking_policy_N families from main UI unless exact GUID+alias proof exists.\n4. Keep processor performance history count/length as advanced-only at most; do not market as FPS tweaks.\n5. Ensure every visible setting has full descriptions (what/why/fps/latency/power/heat/risk/recommendations).\n6. Ensure every visible supported setting has apply + verify + rollback behavior.\n7. Mark unresolved items as experimental/hidden with UNDOCUMENTED badge.\n8. Update tweaks/power.management.profiles.json uiExposedIds from catalog uiVisibility=main.\n9. Fix Speed Core non-app bulk selection using explicit metadata (isAppSpecific / isSystemWide), not fuzzy name-only checks.\n10. Keep \"Apply Latency Registry Optimization Bundle\" in latency/scheduler grouping (it is not a reset).\n\n## Deliverables\n- Updated data/power/power_management_catalog.json\n- output/power/power-audit-report.json\n- output/power/power-audit-report.md\n- output/power/power-unresolved-report.md\n- docs/power-badge-system.md\n- docs/power-description-style-guide.md\n\n## Anti-hallucination rules\n- Missing GUID = unsupported for normal apply/verify.\n- repo placeholder text is not proof.\n- Prefer hiding dubious entries over exposing misleading toggles.\n---\n`;
fs.writeFileSync(megaPromptPath, megaPrompt);

console.log(JSON.stringify(summary, null, 2));
