"use strict";

function toArray(value) {
  return Array.isArray(value) ? value.filter((x) => typeof x === "string" && x.trim()) : [];
}

function normalizeDetails(details, tweak) {
  const fallbackRisk = `${String((tweak && (tweak.riskLevel || tweak.risk)) || "Safe")} risk. Validate on your hardware.`;
  const revertSteps = tweak && tweak.revert && Array.isArray(tweak.revert.steps) ? tweak.revert.steps : [];
  return {
    recommendedFor: String(details.recommendedFor || "General users who want measurable performance gains with clear rollback options."),
    benefits: toArray(details.benefits).length ? toArray(details.benefits) : ["Performance or responsiveness improvements based on this tweak category."],
    tradeoffs: toArray(details.tradeoffs).length ? toArray(details.tradeoffs) : ["May reduce default Windows convenience or diagnostics."],
    riskNotes: toArray(details.riskNotes).length ? toArray(details.riskNotes) : [fallbackRisk],
    reversible: String(details.reversible || (revertSteps.length ? "Yes. Use Revert for this item." : "No built-in revert steps were found.")),
    requiresReboot: details.requiresReboot !== undefined ? !!details.requiresReboot : !!(tweak && tweak.requiresReboot)
  };
}

function keywordMatches(tweak, matcher) {
  const text = [tweak && tweak.id, tweak && tweak.name, tweak && tweak.description, tweak && tweak.category, ...(Array.isArray(tweak && tweak.tags) ? tweak.tags : [])]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
  const keywords = Array.isArray(matcher && matcher.keywords) ? matcher.keywords : [];
  const categories = Array.isArray(matcher && matcher.categories) ? matcher.categories : [];
  if (categories.length) {
    const category = String((tweak && tweak.category) || "").toLowerCase();
    if (categories.some((c) => category.includes(String(c).toLowerCase()))) return true;
  }
  return keywords.some((kw) => text.includes(String(kw).toLowerCase()));
}

function buildDetails(tweak, templatesDoc) {
  const templates = templatesDoc && Array.isArray(templatesDoc.templates) ? templatesDoc.templates : [];
  for (const tpl of templates) {
    if (!tpl || typeof tpl !== "object") continue;
    if (keywordMatches(tweak, tpl.match || {})) {
      return normalizeDetails(tpl.details || {}, tweak);
    }
  }
  return normalizeDetails({}, tweak);
}

function mergeDetails(tweak, overlayDoc) {
  const out = { ...(tweak || {}) };
  const hasExisting = out.details && typeof out.details === "object";
  const base = hasExisting ? normalizeDetails(out.details, out) : buildDetails(out, overlayDoc || {});
  const overrides = overlayDoc && overlayDoc.overridesById && out.id ? overlayDoc.overridesById[out.id] : null;
  out.details = normalizeDetails({ ...base, ...(overrides && overrides.details ? overrides.details : {}) }, out);
  return out;
}

module.exports = {
  buildDetails,
  mergeDetails
};
