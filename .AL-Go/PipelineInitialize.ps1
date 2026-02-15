Param([Hashtable] $parameters)

function Resolve-PackageVersion {
    param(
        [string]$PackageName,
        [string]$Channel
    )
    
    $indexUrl = "https://api.nuget.org/v3-flatcontainer/$($PackageName.ToLower())/index.json"
    Write-Host "Fetching available versions for $PackageName from NuGet..."
    
    try {
        $response = Invoke-RestMethod -Uri $indexUrl -UseBasicParsing -ErrorAction Stop
        $allVersions = $response.versions
        
        if (-not $allVersions -or $allVersions.Count -eq 0) {
            throw "No versions found for package $PackageName"
        }
        
        Write-Host "Found $($allVersions.Count) total versions"
        
        # Parse all versions as SemVer objects
        $parsedVersions = @()
        foreach ($ver in $allVersions) {
            try {
                $semver = [System.Management.Automation.SemanticVersion]::new($ver)
                $parsedVersions += [PSCustomObject]@{
                    Original = $ver
                    SemVer   = $semver
                }
            }
            catch {
                Write-Warning "Failed to parse version '$ver' as SemVer: $_"
            }
        }
        
        # Filter based on channel
        $candidates = switch ($Channel.ToLower()) {
            { $_ -eq "stable" -or $_ -eq "" } {
                Write-Host "Channel: Stable (only stable releases)"
                $parsedVersions | Where-Object { [string]::IsNullOrEmpty($_.SemVer.PreReleaseLabel) }
            }
            "alpha" {
                Write-Host "Channel: Alpha (stable + alpha pre-releases)"
                $parsedVersions | Where-Object { 
                    [string]::IsNullOrEmpty($_.SemVer.PreReleaseLabel) -or 
                    $_.SemVer.PreReleaseLabel -like "alpha*"
                }
            }
            "beta" {
                Write-Host "Channel: Beta (stable + beta pre-releases)"
                $parsedVersions | Where-Object { 
                    [string]::IsNullOrEmpty($_.SemVer.PreReleaseLabel) -or 
                    $_.SemVer.PreReleaseLabel -like "beta*"
                }
            }
            default {
                throw "Unknown channel: $Channel. Valid channels are: Stable, Alpha, Beta"
            }
        }
        
        if (-not $candidates -or $candidates.Count -eq 0) {
            throw "No versions found matching channel '$Channel'"
        }
        
        Write-Host "Found $($candidates.Count) versions matching channel criteria"
        
        # Sort by SemVer and pick the highest
        $sorted = $candidates | Sort-Object { $_.SemVer }
        $latest = $sorted[-1]
        
        Write-Host "Resolved version: $($latest.Original)"
        return $latest.Original
    }
    catch {
        throw "Failed to resolve package version: $_"
    }
}

$packageName = "ALCops.Analyzers"
$packageVersion = "stable"
$targetFramework = "net8.0"

# Resolve version if channel name is provided, otherwise use explicit version
if ($packageVersion -notmatch '^\d') {
    # It's a channel name, resolve it
    $packageVersion = Resolve-PackageVersion -PackageName $packageName -Channel $packageVersion
}
else {
    Write-Host "Using explicit version: $packageVersion"
}

$copsFolder = Join-Path $ENV:GITHUB_WORKSPACE ".alcops/$targetFramework"
if (-not (Test-Path $copsFolder)) {
    New-Item -Path $copsFolder -ItemType Directory -Force | Out-Null
    $nupkgUrl = "https://api.nuget.org/v3-flatcontainer/$($packageName.ToLower())/$($packageVersion.ToLower())/$($packageName.ToLower()).$($packageVersion.ToLower()).nupkg"
    $nupkgPath = Join-Path ([System.IO.Path]::GetTempPath()) "$packageName.nupkg"
    
    Invoke-WebRequest -Uri $nupkgUrl -OutFile $nupkgPath -UseBasicParsing
    $extractPath = Join-Path ([System.IO.Path]::GetTempPath()) "$packageName-extract"

    if (-not ("System.IO.Compression.ZipFile" -as [type])) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($nupkgPath, $extractPath, $true)

    # Copy only the target framework DLLs
    Copy-Item -Path (Join-Path $extractPath "lib/$targetFramework/*") -Destination $copsFolder -Force
    
    # Cleanup
    Remove-Item $nupkgPath, $extractPath -Recurse -Force
}

Write-Host "ALCops DLLs available at: $copsFolder"
Get-ChildItem $copsFolder -Filter "*.dll" | ForEach-Object { Write-Host "  - $($_.Name)" }