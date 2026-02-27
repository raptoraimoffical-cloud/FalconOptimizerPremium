const engine = require("./theme-engine.json");

function listThemes() {
  return Object.keys(engine.themes);
}

function getTheme(id) {
  if (id && engine.themes[id]) return engine.themes[id];
  return engine.themes[engine.defaultTheme];
}

function applyThemeToCssVars(theme, root) {
  const target = root || document.documentElement;
  const style = target.style || (target.documentElement && target.documentElement.style);
  if (!style) return;

  Object.entries(theme).forEach(([key, value]) => {
    if (key === "name") return;
    style.setProperty(`--theme-${key}`, String(value));
  });
}

module.exports = {
  engine,
  listThemes,
  getTheme,
  applyThemeToCssVars
};
