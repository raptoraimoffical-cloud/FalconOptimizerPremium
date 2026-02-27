# Falcon Optimizer – Process Lab Competitive preset (V5 engine)
# Uses the catalog‑driven engine with Competitive defaults.

$ErrorActionPreference = 'SilentlyContinue'

$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$engine = Join-Path $root 'processlab-run.ps1'

if (Test-Path $engine) {
    & $engine -Mode 'competitive'
} else {
    Write-Output 'ProcessLabError=MissingEngine'
}

exit 0
