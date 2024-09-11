# make_revision_env.ps1

param (
    [string]$REVISION
)

$ARTIFACTS_DIR = "build.artifacts"

if (-not $REVISION) {
    $REVISION = git rev-parse --short=7 HEAD
}

if (-not $REVISION) {
    Write-Output "error: not set REVISION"
    exit 1
}

$REVISION | Out-File -FilePath "$ARTIFACTS_DIR\env\build_revision.env" -Encoding utf8
Get-Content "$ARTIFACTS_DIR\env\build_revision.env"