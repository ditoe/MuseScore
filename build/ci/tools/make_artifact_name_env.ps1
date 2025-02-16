# make_artifact_name_env.ps1

param (
    [string]$ArtifactName,
    [string]$OutDir = ""
)

if (-not $ArtifactName) {
    Write-Output "error: not set ARTIFACT_NAME"
    exit 1
}

$ARTIFACTS_DIR = "build.artifacts" # default output dir

if (-not $OutDir) {
    $OutDir = "$ARTIFACTS_DIR/env"
}

# Ensure the output directory exists
New-Item -ItemType Directory -Force -Path $OutDir

$ArtifactName | Out-File -FilePath "$OutDir/artifact_name.env" -Encoding utf8
Get-Content "$OutDir/artifact_name.env"