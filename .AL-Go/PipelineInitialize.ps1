Param([Hashtable] $parameters)

$packageName = "ALCops.Analyzers"
$packageVersion = "0.3.0"
$targetFramework = "net8.0"

$copsFolder = Join-Path $ENV:GITHUB_WORKSPACE ".alcops/$targetFramework"
if (-not (Test-Path $copsFolder)) {
    New-Item -Path $copsFolder -ItemType Directory -Force | Out-Null
    $nupkgUrl = "https://api.nuget.org/v3-flatcontainer/$($packageName.ToLower())/$($packageVersion.ToLower())/$($packageName.ToLower()).$($packageVersion.ToLower()).nupkg"
    $nupkgPath = Join-Path ([System.IO.Path]::GetTempPath()) "$packageName.nupkg"
    
    Invoke-WebRequest -Uri $nupkgUrl -OutFile $nupkgPath -UseBasicParsing
    $extractPath = Join-Path ([System.IO.Path]::GetTempPath()) "$packageName-extract"
    Expand-Archive -Path $nupkgPath -DestinationPath $extractPath -Force
    
    # Copy only the target framework DLLs
    Copy-Item -Path (Join-Path $extractPath "lib/$targetFramework/*") -Destination $copsFolder -Force
    
    # Cleanup
    Remove-Item $nupkgPath, $extractPath -Recurse -Force
}

Write-Host "ALCops DLLs available at: $copsFolder"
Get-ChildItem $copsFolder -Filter "*.dll" | ForEach-Object { Write-Host "  - $($_.Name)" }