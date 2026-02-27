param(
  [Parameter(Mandatory=$true)][string]$Script,
  [Parameter(Mandatory=$true)][string]$JsonFile,
  [Parameter(Mandatory=$true)][string]$ResultFile
)

Set-StrictMode -Version Latest

# Ensure result file is not stale
try { if (Test-Path -LiteralPath $ResultFile) { Remove-Item -LiteralPath $ResultFile -Force } } catch {}

# Build an argument list that runs the target script elevated and writes JSON to ResultFile
$argList = @(
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-File", "`"$Script`"",
  "-JsonFile", "`"$JsonFile`"",
  "-ResultFile", "`"$ResultFile`""
) -join " "

try {
  $p = Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs -WindowStyle Hidden -PassThru
} catch {
  # UAC cancelled or Start-Process failed
  $err = $_.Exception.Message
  $out = @{ ok = $false; errors = @("Elevation required (UAC prompt was cancelled or failed): $err"); warnings=@(); logFile=$null }
  $out | ConvertTo-Json -Compress | Out-File -FilePath $ResultFile -Encoding UTF8 -Force
  exit 0
}

# Wait for the elevated script to finish (up to 3 minutes)
try {
  Wait-Process -Id $p.Id -Timeout 180
} catch {
  # Timeout waiting for elevated process; allow caller to timeout too
}

# If the elevated script didn't write a result, write a fallback
if (!(Test-Path -LiteralPath $ResultFile)) {
  $out = @{ ok = $false; errors = @("Elevated run finished without producing a result."); warnings=@(); logFile=$null }
  $out | ConvertTo-Json -Compress | Out-File -FilePath $ResultFile -Encoding UTF8 -Force
}

exit 0
