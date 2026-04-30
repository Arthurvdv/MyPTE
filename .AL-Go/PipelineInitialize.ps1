Param([Hashtable] $parameters)

$ErrorActionPreference = "Stop"

$output = Join-Path $env:GITHUB_WORKSPACE ".alcops"
$detectUsing = $env:artifact

Write-Host "Installing ALCops analyzers..."
Write-Host "  Output: $output"
Write-Host "  Detect using: $detectUsing"

npx @alcops/core download --output $output --detect-using $detectUsing
if ($LASTEXITCODE -ne 0) {
    throw "alcops download failed with exit code $LASTEXITCODE"
}