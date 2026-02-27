# Falcon Optimizer – Process Lab Safe preset (V5 engine)
# Conservative background trimming using the catalog‑driven engine.

$ErrorActionPreference = 'SilentlyContinue'

$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$engine = Join-Path $root 'processlab-run.ps1'

if (Test-Path $engine) {
    & $engine -Mode 'safe'
} else {
    Write-Output 'ProcessLabError=MissingEngine'
}

exit 0
