param(
  [int]$Seconds = 15,
  [int]$IntervalMs = 250
)

$ErrorActionPreference = "Stop"

function Get-CountersSnapshot {
  $obj = $null
  try {
    $obj = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction Stop
  } catch {
    $obj = $null
  }

  $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1 Name, NumberOfLogicalProcessors

  [pscustomobject]@{
    ts = (Get-Date).ToString("o")
    cpu = ($cpu.Name)
    logical = ($cpu.NumberOfLogicalProcessors)
    dpc = [double]($obj.PercentDPCTime)
    isr = [double]($obj.PercentInterruptTime)
    idle = [double]($obj.PercentIdleTime)
  }
}

if ($Seconds -lt 5) { $Seconds = 5 }
if ($IntervalMs -lt 100) { $IntervalMs = 100 }

$iters = [math]::Ceiling(($Seconds*1000) / $IntervalMs)
$samples = New-Object System.Collections.Generic.List[object]
for($i=0; $i -lt $iters; $i++){
  try { $samples.Add((Get-CountersSnapshot)) | Out-Null } catch {}
  Start-Sleep -Milliseconds $IntervalMs
}

$dpcVals = $samples | ForEach-Object { $_.dpc }
$isrVals = $samples | ForEach-Object { $_.isr }

function Stats($vals){
  $arr = @($vals | Where-Object { $_ -ne $null })
  if($arr.Count -eq 0){ return @{ avg=0; max=0; p95=0 } }
  $sorted = $arr | Sort-Object
  $avg = ($arr | Measure-Object -Average).Average
  $max = ($arr | Measure-Object -Maximum).Maximum
  $idx = [int][math]::Floor(0.95 * ($sorted.Count-1))
  $p95 = $sorted[$idx]
  return @{ avg=[double]$avg; max=[double]$max; p95=[double]$p95 }
}

$dpc = Stats $dpcVals
$isr = Stats $isrVals

$recommendations = @()
if($dpc.max -gt 5 -or $isr.max -gt 5){
  $recommendations += "High DPC/Interrupt time detected. Check GPU/audio/network drivers and background services."
}
if($dpc.max -gt 10 -or $isr.max -gt 10){
  $recommendations += "Very high ISR/DPC spikes detected. Consider updating chipset/GPU drivers, disabling extra USB controllers, and checking PCIe power saving."
}

$out = [pscustomobject]@{
  ok = $true
  seconds = $Seconds
  intervalMs = $IntervalMs
  dpc = $dpc
  isr = $isr
  recommendations = $recommendations
  samples = $samples
}

$out | ConvertTo-Json -Depth 6
