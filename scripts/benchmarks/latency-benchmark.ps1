param(
  [int]$Seconds = 5,
  [int]$WarmupMs = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

Add-Type -AssemblyName System.Core | Out-Null
$sw = New-Object System.Diagnostics.Stopwatch

# Warmup
Start-Sleep -Milliseconds $WarmupMs

$sw.Start()
$targetTicks = [int64]($Seconds * [System.Diagnostics.Stopwatch]::Frequency)
$last = $sw.ElapsedTicks
$jit = New-Object System.Collections.Generic.List[double]

while ($sw.ElapsedTicks -lt $targetTicks) {
  # tight loop, sample delta
  $now = $sw.ElapsedTicks
  $dt = $now - $last
  $last = $now
  $jit.Add( ($dt * 1000.0) / [System.Diagnostics.Stopwatch]::Frequency )
}

$sw.Stop()

# compute stats
$vals = $jit.ToArray()
[Array]::Sort($vals)

function Percentile([double[]]$a, [double]$p) {
  if ($a.Length -eq 0) { return 0.0 }
  $idx = ($p/100.0) * ($a.Length - 1)
  $lo = [math]::Floor($idx)
  $hi = [math]::Ceiling($idx)
  if ($lo -eq $hi) { return $a[$lo] }
  $w = $idx - $lo
  return $a[$lo] * (1.0 - $w) + $a[$hi] * $w
}

$mean = ($vals | Measure-Object -Average).Average
# stddev
$sumSq = 0.0
foreach ($v in $vals) { $sumSq += ($v - $mean) * ($v - $mean) }
$std = [math]::Sqrt($sumSq / [math]::Max(1, ($vals.Length-1)))

$result = [ordered]@{
  seconds = $Seconds
  samples = $vals.Length
  mean_ms = [math]::Round($mean, 6)
  std_ms = [math]::Round($std, 6)
  p50_ms = [math]::Round((Percentile $vals 50), 6)
  p90_ms = [math]::Round((Percentile $vals 90), 6)
  p99_ms = [math]::Round((Percentile $vals 99), 6)
  max_ms = [math]::Round($vals[$vals.Length-1], 6)
}

$result | ConvertTo-Json -Depth 4
