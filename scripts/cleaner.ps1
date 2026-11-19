<#
  Speed Boost cleaner.

  Request: { "mode": "scan" | "clean", "targets": [ { id, paths[], special? } ] }
  Result:  { ok, mode, targets: [ { id, bytes, files, freed?, skipped? } ], totalBytes, freedBytes }

  Only deletes files *inside* the listed folders (or the listed files themselves); the folders are
  kept so apps never break. Files that are in use are skipped silently.
#>
param(
  [Parameter(Mandatory = $true)][string]$RequestFile,
  [Parameter(Mandatory = $true)][string]$ResultFile
)
$ErrorActionPreference = 'SilentlyContinue'

$req = Get-Content -LiteralPath $RequestFile -Raw -Encoding UTF8 | ConvertFrom-Json
$mode = [string]$req.mode

$steam = $null
try { $steam = ((Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamPath) -replace '/', '\' } catch {}
if (-not $steam) { $steam = Join-Path ${env:ProgramFiles(x86)} 'Steam' }

# Never allow a target to resolve to a drive root, Windows itself or a user profile root.
$forbidden = @($env:SystemDrive + '\', $env:WINDIR, $env:USERPROFILE, $env:APPDATA, $env:LOCALAPPDATA, $env:ProgramData, ${env:ProgramFiles}, ${env:ProgramFiles(x86)}) |
  Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\').ToLowerInvariant() }

function Resolve-Targets([object[]]$paths) {
  $out = @()
  foreach ($p in $paths) {
    $x = [Environment]::ExpandEnvironmentVariables(([string]$p).Replace('{steam}', $steam))
    if ($x -match '%' -or $x -notmatch '^[A-Za-z]:\\.+') { continue }   # unexpanded or not absolute
    foreach ($r in @(Resolve-Path -Path $x -ErrorAction SilentlyContinue)) {
      $full = $r.ProviderPath.TrimEnd('\')
      if ($forbidden -contains $full.ToLowerInvariant()) { continue }
      $out += $full
    }
  }
  return $out | Select-Object -Unique
}

function Get-Files([string]$root) {
  $item = Get-Item -LiteralPath $root -Force
  if (-not $item) { return @() }
  if (-not $item.PSIsContainer) { return @($item) }
  return @(Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue)
}

function Measure-RecycleBin {
  $bytes = 0; $count = 0
  try {
    $shell = New-Object -ComObject Shell.Application
    foreach ($i in $shell.NameSpace(10).Items()) { $bytes += [int64]$i.Size; $count++ }
  } catch {}
  return @{ bytes = $bytes; files = $count }
}

$results = @()
$total = [int64]0; $freedTotal = [int64]0
foreach ($t in @($req.targets)) {
  $r = [ordered]@{ id = [string]$t.id; bytes = [int64]0; files = 0; freed = [int64]0; skipped = 0 }
  if ($t.PSObject.Properties.Name -contains 'special' -and $t.special -eq 'recyclebin') {
    $m = Measure-RecycleBin
    $r.bytes = $m.bytes; $r.files = $m.files
    if ($mode -eq 'clean' -and $m.files -gt 0) {
      Clear-RecycleBin -Force -ErrorAction SilentlyContinue
      $after = Measure-RecycleBin
      $r.freed = [math]::Max(0, $m.bytes - $after.bytes); $r.skipped = $after.files
    }
  } else {
    foreach ($root in Resolve-Targets @($t.paths)) {
      $files = Get-Files $root
      foreach ($f in $files) {
        $r.bytes += [int64]$f.Length; $r.files++
        if ($mode -eq 'clean') {
          try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop; $r.freed += [int64]$f.Length } catch { $r.skipped++ }
        }
      }
      if ($mode -eq 'clean' -and (Test-Path -LiteralPath $root -PathType Container)) {
        # Remove now-empty subfolders, deepest first; keep the root folder itself.
        Get-ChildItem -LiteralPath $root -Recurse -Force -Directory -ErrorAction SilentlyContinue |
          Sort-Object { $_.FullName.Length } -Descending |
          ForEach-Object { if (-not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue)) { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue } }
      }
    }
  }
  $total += $r.bytes; $freedTotal += $r.freed
  $results += [pscustomobject]$r
}

[pscustomobject]@{ ok = $true; mode = $mode; targets = $results; totalBytes = $total; freedBytes = $freedTotal } |
  ConvertTo-Json -Depth 4 -Compress | Set-Content -LiteralPath $ResultFile -Encoding UTF8
exit 0
