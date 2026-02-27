param(
  [Parameter(Mandatory=$true)][ValidateSet("safe","aggressive")]
  [string]$Mode = "safe"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

function Remove-Path([string]$p) {
  try {
    if (Test-Path -LiteralPath $p) {
      Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    }
  } catch {}
}

# Safe targets
$targets = @(
  "$env:TEMP\*",
  "$env:WINDIR\Temp\*",
  "$env:LOCALAPPDATA\Temp\*"
)

# Aggressive adds prefetch (can increase stutter first launches; optional)
if ($Mode -eq "aggressive") {
  $targets += "$env:WINDIR\Prefetch\*"
}

foreach ($t in $targets) {
  try { Remove-Item $t -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

"OK: Cleanup complete ($Mode)" | Write-Output
