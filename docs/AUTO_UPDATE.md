# Auto-Update (Windows via GitHub Releases)

Falcon Optimizer uses `electron-updater` + `electron-builder` to update packaged Windows installs.

> Auto-update **does not** work from commits alone. It pulls update metadata + installers from release assets (for example, GitHub Releases).

## One-time setup

1. Open `package.json` and replace these placeholders in `build.publish`:
   - `<REPLACE_WITH_OWNER>` → your GitHub org/user (example: `FalconTools`)
   - `<REPLACE_WITH_REPO>` → the releases repo name (example: `FalconOptimizerPremium-main`)
2. Ensure Releases are enabled for that repository.

## Release workflow (every update)

1. Bump version in `package.json` (example: `1.4.2` → `1.4.3`).
2. Build distributables:
   ```bash
   npm run dist
   ```
3. Create a GitHub Release with tag `v1.4.3` (tag should match the app version with `v` prefix).
4. Upload files from `dist/` to that release:
   - NSIS installer `.exe`
   - `latest.yml`
   - Any generated `.blockmap` files
5. Publish the release.

After users install a packaged build, the app checks GitHub Releases on startup and every 6 hours, downloads updates automatically, then installs with `quitAndInstall()` when fully downloaded.

## Private repo note

For private repositories, auto-update needs authenticated requests for release assets. For premium/private distribution, use either:

- A public releases repository, or
- A generic HTTPS host you control (with corresponding updater configuration)
