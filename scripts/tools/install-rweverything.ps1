param(
  [string]$DestDir = "$env:ProgramData\FalconOptimizer\tools"
)
$ErrorActionPreference = 'Stop'

# RWEverything is distributed via rweverything.com; direct file names can change.
# This script opens the official downloads index instead of hardcoding a version.
Start-Process 'https://rweverything.com/downloads/'
