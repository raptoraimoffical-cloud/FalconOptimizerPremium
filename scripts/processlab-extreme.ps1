# Falcon Optimizer – Process Lab Extreme preset (V5 engine)
# Aggressive background trimming aiming for ~32–38 processes on a dedicated gaming account.

$ErrorActionPreference = 'SilentlyContinue'

$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$engine = Join-Path $root 'processlab-run.ps1'

if (Test-Path $engine) {
    & $engine -Mode 'extreme'
} else {
    Write-Output 'ProcessLabError=MissingEngine'
}

exit 0
