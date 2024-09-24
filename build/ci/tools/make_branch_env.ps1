# make_branch_env.ps1
param (
    [string]$BRANCH
)

$ARTIFACTS_DIR = "build.artifacts"

if (-not $BRANCH) {
    $BRANCH = git rev-parse --abbrev-ref HEAD
}

if (-not $BRANCH) {
    Write-Output "error: not set BRANCH"
    exit 1
}

$BRANCH = $BRANCH -replace '/', '_'

$BRANCH | Out-File -FilePath "$ARTIFACTS_DIR\env\build_branch.env" -Encoding utf8
Get-Content "$ARTIFACTS_DIR\env\build_branch.env"