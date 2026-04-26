Param([Hashtable] $parameters)

Write-Host "--- PipelineInitialize Parameters ---"
if ($parameters -and $parameters.Count -gt 0) {
    $parameters.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key) = $($_.Value)" }
} else {
    Write-Host "  (none)"
}
Write-Host "---"

Write-Host "--- Resolved artifact URL ---"
    Write-Host $env:artifact
Write-Host "---"

# Configuration
$scriptUrl = "https://raw.githubusercontent.com/ALCops/AL-Go/v1.0.0/scripts/Install-ALCops.ps1"
$packageVersion = "beta"          # "" = latest stable, "alpha", "beta", or "1.2.3"
$targetFramework = ""

# Download and run the installer script
$scriptPath = Join-Path ([System.IO.Path]::GetTempPath()) "Install-ALCops.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing

& $scriptPath `
    -packageVersion $packageVersion `
    -targetFramework $targetFramework