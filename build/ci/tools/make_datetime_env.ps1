# make_datetime_env.ps1

param (
    [string]$DATETIME,
    [string]$OUT_DIR = ""
)

$ARTIFACTS_DIR = "build.artifacts"

if (-not $DATETIME) {
    $DATETIME = Get-Date -Format "yyyyMMddHHmm"
}

if (-not $DATETIME) {
    Write-Output "error: not set DATETIME"
    exit 1
}

if (-not $OUT_DIR) {
    $OUT_DIR = "$ARTIFACTS_DIR/env"
}

$DATETIME | Out-File -FilePath "$OUT_DIR/build_datetime.env" -Encoding utf8
Get-Content "$OUT_DIR/build_datetime.env"