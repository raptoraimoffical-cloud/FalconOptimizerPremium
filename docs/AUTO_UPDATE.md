# Auto-Update (Windows via GitHub Releases)

Falcon Optimizer uses `electron-updater` + `electron-builder` to update packaged Windows installs.

> Auto-update only runs from packaged builds. Dev (`electron .`) intentionally skips updater checks.

## Publish config used by updater

`package.json` contains the default release feed target:

- `build.publish[0].owner`
- `build.publish[0].repo`

Runtime overrides are also supported for testing/build pipelines:

- `FALCON_UPDATER_OWNER` (or `UPDATER_OWNER`)
- `FALCON_UPDATER_REPO` (or `UPDATER_REPO`)

The app validates owner/repo on startup and reports clear diagnostics in the **Updater** page.

## Public vs private GitHub repo behavior

### Public repo
- No token is required.
- Feed URL should resolve: `https://github.com/<owner>/<repo>/releases.atom`

### Private repo
- Unauthenticated requests can return HTTP 404.
- You must provide `GH_TOKEN` or `GITHUB_TOKEN` (runtime `FALCON_GH_TOKEN` is also accepted and mapped to `GH_TOKEN`).
- If updater sees 404, diagnostics surface: **"Repo appears private or not found"**.

## Release workflow (every update)

1. Bump `version` in `package.json`.
2. Build distributables:
   ```bash
   npm run dist
   ```
3. Create GitHub Release tag `v<version>`.
4. Upload `dist/` assets:
   - NSIS installer `.exe`
   - `latest.yml`
   - generated `.blockmap` files
5. Publish release.

Packaged installs check updates at startup and every 6 hours.
