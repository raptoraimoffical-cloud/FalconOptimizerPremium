Falcon Theme System – Premium Presets

This package gives you a drop-in universal theme engine for desktop apps
(Electron / Tauri / webview / browser).

Files:
- theme-engine.json
    Raw theme data (all themes + variables).

- themeEngine.ts
    TypeScript helper: typed Theme, ThemeId, getTheme, listThemes, applyThemeToCssVars.

- themeEngine.js
    Plain JS helper with the same API as themeEngine.ts (without types).

Integration (JS / TS, Electron-style):

    const { getTheme, applyThemeToCssVars, listThemes } = require("./themeEngine");
    // or in TS/ESM:
    // import { getTheme, applyThemeToCssVars, listThemes } from "./themeEngine";

    const ids = listThemes();              // ['christmasFrosted', 'blackRedGamer', ...]
    const current = getTheme("futuristicWhiteGlass");

    // Apply to CSS variables on :root (or a specific container element)
    applyThemeToCssVars(current);

You can then use the CSS variables in your styles:

    body {
      background: var(--theme-bg);
      color: var(--theme-text-main);
    }

    .sidebar {
      background: var(--theme-bg2);
      border-right: 1px solid var(--theme-border);
    }

    .card {
      background: var(--theme-card);
      box-shadow: 0 18px 45px var(--theme-shadow-1);
    }

    .card-elevated {
      background: var(--theme-card2);
      box-shadow: 0 24px 75px var(--theme-shadow-2);
    }

    .btn-primary {
      background: var(--theme-button-bg);
      color: var(--theme-button-fg);
    }

    .fps-bar-track {
      background: var(--theme-fps-bar-track);
    }

    .fps-bar-fill {
      background: var(--theme-fps-bar-fill);
    }

Use `background-art` as a token to decide what procedural / image background
to render (nebula, frost, topo, glow, noise, etc.).

All themes are tuned for:
- High contrast and readability
- Professional gaming dashboards / optimizers
- Clean, consistent surfaces and accents
