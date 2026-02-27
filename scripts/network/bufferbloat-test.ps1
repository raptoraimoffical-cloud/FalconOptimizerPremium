param(
  [string]$PingHost = "1.1.1.1",
  [string]$DownloadUrl = "https://speed.hetzner.de/100MB.bin",
  [int]$Seconds = 20
)

$ErrorActionPreference = "Stop"

function Run-PingSample([string]$host, [int]$count){
  $out = & ping.exe -n $count $host 2>&1
  $times = @()
  foreach($ln in $out){
    if($ln -match 'time[=<]\s*(\d+)\s*ms'){
      $times += [int]$Matches[1]
    }
  }
  if($times.Count -eq 0){
    return [pscustomobject]@{ ok=$false; error="Ping returned no time samples"; raw=($out -join "`n") }
  }
  $sorted = $times | Sort-Object
  $avg = ($times | Measure-Object -Average).Average
  $p50 = $sorted[[int][math]::Floor(0.50*($sorted.Count-1))]
  $p90 = $sorted[[int][math]::Floor(0.90*($sorted.Count-1))]
  $p99 = $sorted[[int][math]::Floor(0.99*($sorted.Count-1))]
  $max = ($times | Measure-Object -Maximum).Maximum
  return [pscustomobject]@{ ok=$true; avg=[double]$avg; p50=$p50; p90=$p90; p99=$p99; max=$max; samples=$times }
}

function Start-Download([string]$url, [int]$seconds){
  $tmp = Join-Path $env:TEMP ("falcon-bb-" + [guid]::NewGuid().ToString() + ".bin")
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "powershell.exe"
  $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"try { `$p = Start-Process -FilePath curl.exe -ArgumentList @('-L','-o',`'$tmp`',`'$url`') -PassThru; Start-Sleep -Seconds $seconds; try{ `$p | Stop-Process -Force }catch{} } catch { }`""
  $psi.CreateNoWindow = $true
  $psi.UseShellExecute = $false
  $p = [System.Diagnostics.Process]::Start($psi)
  return [pscustomobject]@{ pid=$p.Id; tempFile=$tmp }
}

if($Seconds -lt 10){ $Seconds = 10 }

$base = Run-PingSample -host $PingHost -count 20
$dl = Start-Download -url $DownloadUrl -seconds $Seconds
Start-Sleep -Milliseconds 500
$loaded = Run-PingSample -host $PingHost -count 40

# cleanup temp file (best effort)
try { if($dl.tempFile -and (Test-Path $dl.tempFile)) { Remove-Item -LiteralPath $dl.tempFile -Force -ErrorAction SilentlyContinue } } catch {}

if(-not $base.ok -or -not $loaded.ok){
  [pscustomobject]@{ ok=$false; baseline=$base; loaded=$loaded } | ConvertTo-Json -Depth 6
  exit 0
}

$deltaAvg = $loaded.avg - $base.avg
$grade = "A"
if($deltaAvg -gt 40){ $grade = "D" }
elseif($deltaAvg -gt 25){ $grade = "C" }
elseif($deltaAvg -gt 15){ $grade = "B" }

$out = [pscustomobject]@{
  ok = $true
  host = $PingHost
  seconds = $Seconds
  downloadUrl = $DownloadUrl
  baseline = $base
  loaded = $loaded
  deltaAvgMs = [double]$deltaAvg
  grade = $grade
  tips = @(
    "If grade is C/D, consider router SQM (cake/fq_codel), disable upload/download saturation, or QoS gaming mode.",
    "Use Ethernet if possible and disable NIC power saving features."
  )
}

$out | ConvertTo-Json -Depth 6
