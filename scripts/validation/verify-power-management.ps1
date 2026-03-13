param(
  [string]$OutputRoot = 'output/power',
  [string]$CatalogPath = 'data/power/power_management_catalog.json'
)

$engine = Join-Path $PSScriptRoot '..\power\power-management-engine.ps1'
& $engine -Mode verify -OutputRoot $OutputRoot -CatalogPath $CatalogPath
