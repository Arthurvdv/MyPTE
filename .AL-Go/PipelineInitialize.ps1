Param([Hashtable] $parameters)

# Configuration
$scriptUrl = "https://raw.githubusercontent.com/ALCops/AL-Go/v1.0.0/scripts/Install-ALCops.ps1"
$packageName = "ALCops.Analyzers"
$packageVersion = ""          # "" = latest stable, "alpha", "beta", or "1.2.3"
$targetFramework = ""

# Download and run the installer script
$scriptPath = Join-Path ([System.IO.Path]::GetTempPath()) "Install-ALCops.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing

& $scriptPath `
    -packageName $packageName `
    -packageVersion $packageVersion `
    -targetFramework $targetFramework