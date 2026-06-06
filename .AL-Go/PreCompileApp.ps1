Param(
    [ValidateSet('app','testApp')]
    [string] $appType,
    [ref] $compilationParams
)

$ErrorActionPreference = "Stop"

# Skip when not running in GitHub Actions (e.g. localDevEnv.ps1 / local builds)
$githubActions = $env:GITHUB_ACTIONS
if ([string]::IsNullOrWhiteSpace($githubActions) -or $githubActions.Trim().ToLowerInvariant() -eq "false") {
    Write-Host "Not running in GitHub Actions. Skipping ALCops analyzer install."
    return
}

$outputPath = Join-Path $env:GITHUB_WORKSPACE ".alcops"

# PreCompileApp runs once per app group (apps + testApps). Skip the download
# if analyzers are already on disk so we don't re-download for the testApp pass.
$alreadyInstalled = (Test-Path $outputPath) -and
    @(Get-ChildItem -Path $outputPath -Filter '*.dll' -ErrorAction SilentlyContinue).Count -gt 0

if ($alreadyInstalled) {
    Write-Host "ALCops analyzers already present in $outputPath. Skipping download (appType=$appType)."
}
else {
    Write-Host "Installing ALCops analyzers (appType=$appType)..."
    Write-Host "  Output path: $outputPath"
    Write-Host "  Detect using: $env:artifact"

    npx --yes '@alcops/core' download `
        --output $outputPath `
        --detect-using $env:artifact `
        --detect-from bc-artifact

    if ($LASTEXITCODE -ne 0) {
        throw "ALCops download failed with exit code $LASTEXITCODE"
    }

    Write-Host "ALCops analyzers installed successfully."
}

# # https://github.com/microsoft/AL-Go/issues/2235
# # Workaround: altool's --customanalyzers forwards a comma-separated list to
# # alc.exe and only resolves the FIRST entry against the project root. The rest
# # stay as relative paths and alc.exe then resolves them against the per-app
# # project folder, where '.alcops' does not exist.
# # Rewrite CustomAnalyzers in $compilationParams to absolute paths so alc.exe
# # can find every DLL regardless of which project it's compiling.
# if ($compilationParams -and $compilationParams.Value.CustomAnalyzers) {
#     $resolved = @()
#     foreach ($cop in $compilationParams.Value.CustomAnalyzers) {
#         if ([System.IO.Path]::IsPathRooted($cop)) {
#             $resolved += $cop
#             continue
#         }
#         $abs = Join-Path $env:GITHUB_WORKSPACE $cop
#         if (Test-Path $abs) {
#             $resolved += (Resolve-Path -LiteralPath $abs).Path
#         }
#         else {
#             Write-Host "::Warning::Custom analyzer not found at expected path: $abs"
#             $resolved += $abs
#         }
#     }
#     $compilationParams.Value.CustomAnalyzers = $resolved
#     Write-Host "Resolved CustomAnalyzers paths to absolute:"
#     $resolved | ForEach-Object { Write-Host "  $_" }
}