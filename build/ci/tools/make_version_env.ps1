# make_version_env.ps1

param (
    [string]$BUILD_NUMBER,
    [string]$OUT_DIR = ""
)

if (-not $BUILD_NUMBER) {
    Write-Output "error: not set BUILD_NUMBER"
    exit 1
}

$ARTIFACTS_DIR = "build.artifacts" # default output dir

if (-not $OUT_DIR) {
    $OUT_DIR = "$ARTIFACTS_DIR/env"
}

$MUSESCORE_VERSION = & cmake -P config.cmake | Select-String -Pattern 'MUSESCORE_VERSION_FULL' | ForEach-Object { $_.Line -replace '.*MUSESCORE_VERSION_FULL\s*', '' }

$MUSESCORE_VERSION_FULL = "$MUSESCORE_VERSION.$BUILD_NUMBER"

$MUSESCORE_VERSION_FULL | Out-File -FilePath "$OUT_DIR/build_version.env" -Encoding utf8
Get-Content "$OUT_DIR/build_version.env"