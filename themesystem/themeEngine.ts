import engineJson from "./theme-engine.json";

export type ThemeKey =
  | "bg"
  | "bg2"
  | "card"
  | "card2"
  | "text-main"
  | "text-muted"
  | "accent-main"
  | "accent-secondary"
  | "shadow-1"
  | "shadow-2"
  | "border"
  | "button-bg"
  | "button-fg"
  | "glow-strong"
  | "glow-soft"
  | "panel-gradient"
  | "background-art"
  | "fps-bar-track"
  | "fps-bar-fill";

export interface Theme {
  name: string;
  "bg": string;
  "bg2": string;
  "card": string;
  "card2": string;
  "text-main": string;
  "text-muted": string;
  "accent-main": string;
  "accent-secondary": string;
  "shadow-1": string;
  "shadow-2": string;
  "border": string;
  "button-bg": string;
  "button-fg": string;
  "glow-strong": string;
  "glow-soft": string;
  "panel-gradient": string;
  "background-art": string;
  "fps-bar-track": string;
  "fps-bar-fill": string;
  [key: string]: string;
}

export interface ThemeEngineJson {
  version: number;
  defaultTheme: string;
  themes: Record<string, Theme>;
}

const engine = engineJson as ThemeEngineJson;

export type ThemeId = keyof typeof engine.themes;

export function listThemes(): ThemeId[] {
  return Object.keys(engine.themes) as ThemeId[];
}

export function getTheme(id?: string | null): Theme {
  const chosen = (id && engine.themes[id]) ? engine.themes[id] : engine.themes[engine.defaultTheme];
  return chosen;
}

export function applyThemeToCssVars(theme: Theme, root?: HTMLElement | Document): void {
  const target: any = root ?? document.documentElement;
  const style = "style" in target ? target.style : (target.documentElement?.style ?? null);
  if (!style) return;

  Object.entries(theme).forEach(([key, value]) => {
    if (key === "name") return;
    style.setProperty(`--theme-${key}`, String(value));
  });
}

export default {
  engine,
  listThemes,
  getTheme,
  applyThemeToCssVars
};
