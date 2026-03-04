# Runner path resolution

- `Resolve-FalconBasePath` resolves repo/app base from `scripts/..`.
- `Get-RunnerDataRoot` redirects packaged `resources\app.asar` to `resources\app.asar.unpacked`.
- `logs/` and `backups/` are created before `Resolve-Path` is called.
- Dev mode resolves under repo root; packaged mode resolves under `app.asar.unpacked`.
