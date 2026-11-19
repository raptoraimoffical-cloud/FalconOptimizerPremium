'use strict';
/**
 * Auto-updater (electron-updater, GitHub releases). Carried over from v1 unchanged apart from
 * this module wrapper — it already handled stale-cache recovery and stalled downloads.
 */
const { app, BrowserWindow, ipcMain, shell } = require('electron');
const fs = require('fs');
const path = require('path');
const https = require('https');

let autoUpdater = null;
function nowIso() { return new Date().toISOString(); }
function safeJsonRead(filePath, fallback) {
  try {
    if (filePath && fs.existsSync(filePath)) return JSON.parse(fs.readFileSync(filePath, 'utf8') || 'null') || fallback;
  } catch (_) {}
  return fallback;
}

let autoUpdateInterval = null;
let updaterDiagnostics = {
  enabled: false,
  owner: "",
  repo: "",
  feedUrl: "",
  source: "package.json",
  tokenConfigured: false,
  configError: null,
  lastCheckResult: "idle",
  lastCheckedAt: null,
  lastError: null,
  latestTagDetected: null,
  cachedTag: null,
  assetUrlUsed: null,
  retryAttempted: false
};
let updaterRecoveryAttempted = false;
let updaterDownloadInProgress = false;
let updaterLastDownloadProgressAt = null;
async function runUpdateCheckUnavailable() {
  throw new Error("Updater is unavailable.");
}
let runUpdateCheck = runUpdateCheckUnavailable;

function isStrictSemver(version) {
  return /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/.test(String(version || "").trim());
}

function ensureAutoUpdaterReady() {
  if (autoUpdater) return { ok: true, updater: autoUpdater };
  try {
    autoUpdater = require("electron-updater").autoUpdater;
    return { ok: true, updater: autoUpdater };
  } catch (e) {
    const message = String((e && e.message) || e || "Failed to initialize updater");
    return { ok: false, message };
  }
}

function detectGithubConfigSource(owner, repo) {
  if (process.env.FALCON_UPDATER_OWNER || process.env.FALCON_UPDATER_REPO) return "env";
  if (process.env.UPDATER_OWNER || process.env.UPDATER_REPO) return "env";
  return "package.json";
}

function extractGithubPublishConfig(pkg) {
  const publish = pkg && pkg.build ? pkg.build.publish : null;
  let selected = null;

  if (Array.isArray(publish)) {
    selected = publish.find((entry) => entry && entry.provider === "github")
      || publish.find((entry) => entry && (!entry.provider) && (entry.owner || entry.repo))
      || publish[0]
      || null;
  } else if (publish && typeof publish === "object") {
    selected = publish;
  }

  return {
    owner: selected && selected.owner ? String(selected.owner).trim() : "",
    repo: selected && selected.repo ? String(selected.repo).trim() : "",
    provider: selected && selected.provider ? String(selected.provider).trim() : "github",
    source: "package.json"
  };
}

function parseSimpleYml(ymlRaw) {
  const out = {};
  const lines = String(ymlRaw || "").split(/\r?\n/);
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const m = line.match(/^([A-Za-z0-9_-]+)\s*:\s*(.*)$/);
    if (!m) continue;
    const key = m[1];
    let value = m[2].trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    out[key] = value;
  }
  return out;
}

function readAppUpdateYmlIfPresent() {
  try {
    const ymlPath = path.join(process.resourcesPath, "app-update.yml");
    if (!fs.existsSync(ymlPath)) return null;
    const parsed = parseSimpleYml(fs.readFileSync(ymlPath, "utf8"));
    const provider = String(parsed.provider || "").trim();
    const owner = String(parsed.owner || "").trim();
    const repo = String(parsed.repo || "").trim();
    const url = String(parsed.url || "").trim();
    if (!provider && !owner && !repo && !url) return null;
    return { provider, owner, repo, url, source: "app-update.yml" };
  } catch (_) {
    return null;
  }
}

function loadUpdaterConfig() {
  const pkgPath = app && app.getAppPath ? path.join(app.getAppPath(), "package.json") : "";
  const pkg = pkgPath ? safeJsonRead(pkgPath, null) : null;
  const pkgCfg = extractGithubPublishConfig(pkg);
  const ymlCfg = app.isPackaged ? readAppUpdateYmlIfPresent() : null;
  const preferredCfg = (ymlCfg && ymlCfg.provider === "github" && ymlCfg.owner && ymlCfg.repo) ? ymlCfg : pkgCfg;

  const owner = String(process.env.FALCON_UPDATER_OWNER || process.env.UPDATER_OWNER || preferredCfg.owner || "").trim();
  const repo = String(process.env.FALCON_UPDATER_REPO || process.env.UPDATER_REPO || preferredCfg.repo || "").trim();
  const source = detectGithubConfigSource(owner, repo) === "env" ? "env" : String(preferredCfg.source || "package.json");
  const provider = String(preferredCfg.provider || "github").trim() || "github";
  return { owner, repo, source, provider, url: preferredCfg.url || "" };
}

function validateUpdaterConfig({ owner, repo }) {
  const issues = [];
  const hasEncodingArtifacts = (value) => /%[0-9a-f]{2}|&(?:amp|lt|gt);/i.test(String(value || ""));
  if (!owner) issues.push("GitHub owner is missing.");
  if (!repo) issues.push("GitHub repo is missing.");
  if (/\s/.test(owner)) issues.push("GitHub owner contains whitespace.");
  if (/\s/.test(repo)) issues.push("GitHub repo contains whitespace.");
  if (hasEncodingArtifacts(owner)) issues.push("GitHub owner appears to include encoded artifacts.");
  if (hasEncodingArtifacts(repo)) issues.push("GitHub repo appears to include encoded artifacts.");
  return { ok: issues.length === 0, issues };
}

function updateUpdaterDiagnostics(patch = {}) {
  updaterDiagnostics = { ...updaterDiagnostics, ...patch };
}

function getUpdaterCacheDir() {
  return path.join(app.getPath("userData"), "pending");
}

function clearUpdaterCache() {
  const dirs = [
    getUpdaterCacheDir(),
    path.join(app.getPath("userData"), "update"),
    path.join(app.getPath("userData"), "updater"),
    path.join(app.getPath("temp"), "falcon-updater")
  ];
  for (const dir of dirs) {
    try {
      if (fs.existsSync(dir)) fs.rmSync(dir, { recursive: true, force: true });
    } catch (_) {}
  }
  updateUpdaterDiagnostics({ cachedTag: null });
}

function detectTagFromString(value) {
  const text = String(value || "");
  const match = text.match(/\/releases\/download\/([^/\s]+)\//i);
  return match ? match[1] : null;
}

function getCachedTagFromError(err) {
  const message = String((err && err.message) || err || "");
  return detectTagFromString(message) || detectTagFromString(err && err.url);
}

function getLatestTagFromInfo(info) {
  if (!info || typeof info !== "object") return null;
  const normalizedVersionTag = normalizeVersionTag(info.version);
  if (normalizedVersionTag) return normalizedVersionTag;
  const files = Array.isArray(info.files) ? info.files : [];
  for (const f of files) {
    const tag = detectTagFromString((f && f.url) || "");
    if (tag) return tag;
  }
  return null;
}

function isVersionTag(tag) {
  return /^v?\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/i.test(String(tag || "").trim());
}

function normalizeVersionTag(version) {
  const v = String(version || "").trim();
  if (!v) return null;
  return v.startsWith("v") ? v : `v${v}`;
}

function resolveUpdateAssetUrl(info, owner, repo) {
  if (!info || typeof info !== "object") return null;
  const files = Array.isArray(info.files) ? info.files : [];
  const fromFileUrl = files.map((f) => String((f && f.url) || "").trim()).find(Boolean) || "";
  const fromPath = String(info.path || "").trim();
  const raw = fromFileUrl || fromPath;
  if (!raw) return null;
  if (/^https?:\/\//i.test(raw)) return raw;
  if (raw.startsWith("/")) return `https://github.com${raw}`;
  if (!owner || !repo) return raw;

  const version = String(info.version || "").trim();
  const tagCandidates = [normalizeVersionTag(version), version].filter(Boolean);
  if (!tagCandidates.length) return raw;
  const fileName = path.basename(raw);
  for (const tag of tagCandidates) {
    if (!tag) continue;
    return `https://github.com/${owner}/${repo}/releases/download/${encodeURIComponent(tag)}/${encodeURIComponent(fileName)}`;
  }
  return raw;
}

function fetchLatestGithubTag(owner, repo, token) {
  return new Promise((resolve) => {
    if (!owner || !repo) return resolve(null);
    const req = https.request({
      hostname: "api.github.com",
      path: `/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/releases/latest`,
      method: "GET",
      headers: {
        "User-Agent": "FalconOptimizer-Updater",
        "Accept": "application/vnd.github+json",
        ...(token ? { Authorization: `Bearer ${token}` } : {})
      }
    }, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk.toString(); });
      res.on("end", () => {
        try {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            const parsed = JSON.parse(data || "{}");
            return resolve(parsed && parsed.tag_name ? String(parsed.tag_name).trim() : null);
          }
        } catch (_) {}
        resolve(null);
      });
    });
    req.on("error", () => resolve(null));
    req.end();
  });
}

function shouldTreatAsStaleMetadataError(err) {
  const message = String((err && err.message) || err || "").toLowerCase();
  const statusCode = err && Number.isFinite(err.statusCode) ? Number(err.statusCode) : null;
  return statusCode === 404
    || message.includes("cannot find latest.yml")
    || message.includes("latest.yml")
    || message.includes("release not found");
}

function classifyUpdaterError(err, tokenConfigured) {
  const rawMessage = String((err && err.message) || err || "Unknown update error");
  const statusCode = err && Number.isFinite(err.statusCode) ? Number(err.statusCode) : null;
  const lower = rawMessage.toLowerCase();
  const latestYml404 = statusCode === 404 && lower.includes("latest.yml");

  if (latestYml404) {
    return {
      lastCheckResult: "latest-yml-missing",
      message: "Release asset missing OR stale cache. Try resetting updater cache."
    };
  }
  if (lower.includes("latest.yml")) {
    return {
      lastCheckResult: "latest-yml-not-attached",
      message: "latest.yml not attached to newest release."
    };
  }
  if (statusCode === 404 && !tokenConfigured) {
    return {
      lastCheckResult: "private-repo-no-token",
      message: "Repo private or owner/repo incorrect. Add GH_TOKEN/GITHUB_TOKEN for private repositories."
    };
  }
  if (statusCode === 404) {
    return {
      lastCheckResult: "repo-not-found",
      message: "Repo private or owner/repo incorrect."
    };
  }
  if (lower.includes("econnrefused") || lower.includes("enotfound") || lower.includes("releases.atom")) {
    return {
      lastCheckResult: "feed-failed",
      message: "Repo private or owner/repo incorrect."
    };
  }
  return { lastCheckResult: "error", message: rawMessage };
}

function broadcastUpdateStatus(status, extra = {}) {
  const payload = { status, ...extra };
  try {
    for (const win of BrowserWindow.getAllWindows()) {
      try {
        win.webContents.send("falcon:update-status", payload);
      } catch (_) {}
    }
  } catch (_) {}
}

async function startUpdateDownload(info) {
  if (!autoUpdater) throw new Error("Updater is unavailable.");
  if (updaterDownloadInProgress) return;
  updaterDownloadInProgress = true;
  updaterLastDownloadProgressAt = Date.now();
  const version = info && info.version ? String(info.version) : null;
  updateUpdaterDiagnostics({ lastCheckResult: "downloading" });
  broadcastUpdateStatus("downloading", { version });
  try {
    await autoUpdater.downloadUpdate();
  } catch (err) {
    updaterDownloadInProgress = false;
    throw err;
  }
}

function setupAutoUpdater() {
  if (!app.isPackaged) {
    console.log("[auto-update] Skipping update checks in development mode.");
    updateUpdaterDiagnostics({ enabled: false, lastCheckResult: "skipped-dev" });
    return;
  }

  const appVersion = app.getVersion();
  if (!isStrictSemver(appVersion)) {
    const message = `Auto-update is disabled: app version must be strict semver (x.y.z), got "${appVersion}".`;
    console.error("[auto-update]", message);
    updateUpdaterDiagnostics({ enabled: false, lastCheckResult: "invalid-app-version", lastError: { message, statusCode: null, url: null, at: nowIso() } });
    broadcastUpdateStatus("error", { message });
    return;
  }

  const updaterInit = ensureAutoUpdaterReady();
  if (!updaterInit.ok) {
    const message = `Auto-update init failed: ${updaterInit.message}`;
    console.error("[auto-update]", message);
    updateUpdaterDiagnostics({ enabled: false, lastCheckResult: "init-failed", lastError: { message, statusCode: null, url: null, at: nowIso() } });
    broadcastUpdateStatus("error", { message });
    runUpdateCheck = runUpdateCheckUnavailable;
    return;
  }

  const { owner, repo, source, provider } = loadUpdaterConfig();
  const validation = validateUpdaterConfig({ owner, repo });
  const tokenConfigured = !!(process.env.GH_TOKEN || process.env.GITHUB_TOKEN || process.env.FALCON_GH_TOKEN);
  const feedUrl = provider === "github" && owner && repo ? `https://github.com/${owner}/${repo}/releases.atom` : "";
  updateUpdaterDiagnostics({
    enabled: true,
    owner,
    repo,
    feedUrl,
    source,
    tokenConfigured,
    configError: validation.ok ? null : validation.issues.join(" "),
    lastCheckResult: "ready"
  });

  if (!validation.ok) {
    const message = `Auto-update is disabled due to invalid publish config (owner=\"${owner || "(missing)"}\" repo=\"${repo || "(missing)"}\"). ${validation.issues.join(" ")}`;
    console.error("[auto-update]", message);
    updateUpdaterDiagnostics({ lastCheckResult: "invalid-config", lastError: { message, url: updaterDiagnostics.feedUrl, statusCode: null, at: nowIso() } });
    broadcastUpdateStatus("error", { message });
    runUpdateCheck = runUpdateCheckUnavailable;
    return;
  }

  if (process.env.FALCON_GH_TOKEN && !process.env.GH_TOKEN) {
    process.env.GH_TOKEN = process.env.FALCON_GH_TOKEN;
  }

  autoUpdater.allowDowngrade = false;
  autoUpdater.autoDownload = false;

  async function runUpdateCheckWithRecovery(sourceLabel) {
    try {
      updateUpdaterDiagnostics({ retryAttempted: updaterRecoveryAttempted });
      await autoUpdater.checkForUpdates();
    } catch (err) {
      const staleError = shouldTreatAsStaleMetadataError(err);
      const cachedTag = getCachedTagFromError(err);
      const ghToken = process.env.GH_TOKEN || process.env.GITHUB_TOKEN || process.env.FALCON_GH_TOKEN || "";
      const newestTag = await fetchLatestGithubTag(owner, repo, ghToken);
      if (cachedTag) updateUpdaterDiagnostics({ cachedTag });
      if (newestTag) {
        updateUpdaterDiagnostics({ latestTagDetected: newestTag });
        if (!isVersionTag(newestTag)) {
          console.warn(`[auto-update] Latest release tag is not version formatted: ${newestTag}. Recommended format: vX.Y.Z`);
        }
      }

      if (staleError && !updaterRecoveryAttempted && cachedTag && newestTag && cachedTag !== newestTag) {
        updaterRecoveryAttempted = true;
        clearUpdaterCache();
        updateUpdaterDiagnostics({
          lastCheckResult: "cache-reset-retry",
          retryAttempted: true,
          lastError: {
            message: `Detected stale updater cache (${cachedTag} -> ${newestTag}). Cache was cleared and update check retried.`,
            statusCode: err && Number.isFinite(err.statusCode) ? Number(err.statusCode) : null,
            url: (err && err.url) || updaterDiagnostics.feedUrl || null,
            at: nowIso()
          }
        });
        broadcastUpdateStatus("cache-reset", { message: "Updater cache was stale and has been refreshed." });
        return await autoUpdater.checkForUpdates();
      }
      throw err;
    }
  }

  runUpdateCheck = runUpdateCheckWithRecovery;

  autoUpdater.on("checking-for-update", () => {
    console.log("[auto-update] checking for update");
    updateUpdaterDiagnostics({ lastCheckResult: "checking", lastCheckedAt: nowIso(), lastError: null });
    broadcastUpdateStatus("checking");
  });
  autoUpdater.on("update-available", (info) => {
    const version = info && info.version ? String(info.version) : null;
    const latestTagDetected = getLatestTagFromInfo(info);
    console.log("[auto-update] update available", version || "");
    if (latestTagDetected && !isVersionTag(latestTagDetected)) {
      console.warn(`[auto-update] Latest release tag is not version formatted: ${latestTagDetected}. Recommended format: vX.Y.Z`);
    }
    const assetUrl = resolveUpdateAssetUrl(info, owner, repo) || updaterDiagnostics.assetUrlUsed;
    updateUpdaterDiagnostics({ lastCheckResult: "available", latestTagDetected: latestTagDetected || updaterDiagnostics.latestTagDetected, assetUrlUsed: assetUrl });
    updaterRecoveryAttempted = false;
    broadcastUpdateStatus("available", { version, latestTagDetected: latestTagDetected || null, assetUrl: assetUrl || null });
    startUpdateDownload(info).catch((err) => {
      const message = String((err && err.message) || err || "Failed to download update");
      console.error("[auto-update] failed to start download", message);
      const statusCode = err && Number.isFinite(err.statusCode) ? Number(err.statusCode) : null;
      updateUpdaterDiagnostics({
        lastCheckResult: "error",
        lastError: { message, statusCode, url: updaterDiagnostics.feedUrl || null, at: nowIso() }
      });
      broadcastUpdateStatus("error", { message, statusCode, url: updaterDiagnostics.feedUrl || null });
    });

    setTimeout(() => {
      if (!updaterDownloadInProgress) return;
      const lastProgressAt = Number(updaterLastDownloadProgressAt || 0);
      if (Date.now() - lastProgressAt < 45000) return;
      const fallbackUrl = resolveUpdateAssetUrl(info, owner, repo) || updaterDiagnostics.assetUrlUsed;
      if (!fallbackUrl || !/^https?:\/\//i.test(fallbackUrl)) return;
      console.warn("[auto-update] download appears stalled; opening installer URL", fallbackUrl);
      updateUpdaterDiagnostics({
        lastCheckResult: "download-stalled",
        assetUrlUsed: fallbackUrl,
        lastError: {
          message: "Download stalled. Opened direct installer URL as fallback.",
          statusCode: null,
          url: fallbackUrl,
          at: nowIso()
        }
      });
      broadcastUpdateStatus("manual-download", { url: fallbackUrl, version });
      shell.openExternal(fallbackUrl).catch(() => {});
      updaterDownloadInProgress = false;
    }, 45000);
  });
  autoUpdater.on("update-not-available", (info) => {
    const version = info && info.version ? String(info.version) : null;
    const latestTagDetected = getLatestTagFromInfo(info);
    console.log("[auto-update] no update available", version || "");
    updateUpdaterDiagnostics({ lastCheckResult: "not-available", latestTagDetected: latestTagDetected || updaterDiagnostics.latestTagDetected });
    updaterRecoveryAttempted = false;
    updaterDownloadInProgress = false;
    broadcastUpdateStatus("not-available", { version });
  });
  autoUpdater.on("download-progress", (progress) => {
    const percent = progress && Number.isFinite(progress.percent) ? Number(progress.percent) : 0;
    updaterLastDownloadProgressAt = Date.now();
    broadcastUpdateStatus("download-progress", { percent });
  });
  autoUpdater.on("update-downloaded", (info) => {
    const version = info && info.version ? String(info.version) : null;
    console.log("[auto-update] update downloaded", version || "");
    updateUpdaterDiagnostics({ lastCheckResult: "downloaded", assetUrlUsed: (info && info.path) || updaterDiagnostics.assetUrlUsed });
    updaterDownloadInProgress = false;
    broadcastUpdateStatus("downloaded", { version });
    try {
      autoUpdater.quitAndInstall();
    } catch (e) {
      console.error("[auto-update] quitAndInstall failed", e);
    }
  });
  autoUpdater.on("error", async (err) => {
    const classified = classifyUpdaterError(err, tokenConfigured);
    const message = String((err && err.message) || err || "Unknown update error");
    const statusCode = err && Number.isFinite(err.statusCode) ? Number(err.statusCode) : null;
    const urlMatch = message.match(/https?:\/\/\S+/i);
    const url = (err && err.url) || (urlMatch ? urlMatch[0] : updaterDiagnostics.feedUrl);
    const cachedTag = getCachedTagFromError(err);
    if (cachedTag) updateUpdaterDiagnostics({ cachedTag, assetUrlUsed: url || updaterDiagnostics.assetUrlUsed });
    updaterDownloadInProgress = false;
    updateUpdaterDiagnostics({
      lastCheckResult: classified.lastCheckResult,
      lastError: { message: classified.message, statusCode, url: url || null, at: nowIso() }
    });
    console.error("[auto-update] error", classified.message);
    broadcastUpdateStatus("error", { message: classified.message, statusCode, url: url || null });
  });

  runUpdateCheckWithRecovery("initial").catch((e) => {
    const message = String((e && e.message) || e || "Failed to check updates");
    console.error("[auto-update] initial check failed", message);
    broadcastUpdateStatus("error", { message });
  });

  autoUpdateInterval = setInterval(() => {
    runUpdateCheckWithRecovery("periodic").catch((e) => {
      const message = String((e && e.message) || e || "Failed to check updates");
      console.error("[auto-update] periodic check failed", message);
      broadcastUpdateStatus("error", { message });
    });
  }, 6 * 60 * 60 * 1000);
}


function registerUpdaterIpc() {
  ipcMain.handle("falcon:checkForUpdates", async () => {
    if (!app.isPackaged) {
      updateUpdaterDiagnostics({ lastCheckResult: "skipped-dev" });
      return { ok: false, message: "Update checks are only available in packaged builds." };
    }
    if (updaterDiagnostics.configError) {
      return { ok: false, message: updaterDiagnostics.configError };
    }
    try {
      updateUpdaterDiagnostics({ lastCheckResult: "manual-check-requested", lastCheckedAt: nowIso() });
      await runUpdateCheck("manual");
      return { ok: true };
    } catch (e) {
      const message = String((e && e.message) || e || "Failed to check updates");
      updateUpdaterDiagnostics({ lastCheckResult: "error", lastError: { message, at: nowIso(), statusCode: null, url: updaterDiagnostics.feedUrl || null } });
      return { ok: false, message };
    }
  });
  
  ipcMain.handle("updater:resetCache", async () => {
    clearUpdaterCache();
    return { ok: true };
  });
  
  ipcMain.handle("updater:getStatus", async () => {
    return { ...updaterDiagnostics };
  });
  
  ipcMain.handle("falcon:getUpdaterDiagnostics", async () => {
    return { ok: true, diagnostics: updaterDiagnostics };
  });
}

function stopUpdater() {
  if (autoUpdateInterval) { clearInterval(autoUpdateInterval); autoUpdateInterval = null; }
}

module.exports = { setupAutoUpdater, registerUpdaterIpc, stopUpdater };
