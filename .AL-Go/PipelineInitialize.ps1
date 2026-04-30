Param([Hashtable] $parameters)

# Configuration
$scriptUrl = "https://raw.githubusercontent.com/ALCops/AL-Go/v1.0.0/scripts/Install-ALCops.ps1"

# Download and run the installer script
$scriptPath = Join-Path ([System.IO.Path]::GetTempPath()) "Install-ALCops.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing

& $scriptPath