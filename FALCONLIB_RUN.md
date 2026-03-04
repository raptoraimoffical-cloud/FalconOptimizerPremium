# falconlib.run

Schema:
- `toolPath` (required)
- `args` (array/string)
- `workingDir` (optional)
- `elevation`: `none|admin|trustedinstaller`
- `wait` (default true)
- `timeoutSec`
- `successExitCodes` (default `[0]`)

Behavior:
- Resolves paths for dev and packaged layouts.
- Validates executable existence and reports clear error when missing.
- TrustedInstaller flow uses NSudo (`NSudoLG.exe`) resolved across FalconLibrary paths.
- Logs resolved path + elevation mode.
