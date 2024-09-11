# make_release_channel_env.ps1

param (
    [string]$MUSESCORE_BUILD_CONFIG = "dev"
)

$ARTIFACTS_DIR = "build.artifacts"

$index = 0
while ($index -lt $args.Length) {
    switch ($args[$index]) {
        "-c" { 
            $MUSESCORE_BUILD_CONFIG = $args[$index + 1]
            $index += 2
        }
        "--build_config" {
            $MUSESCORE_BUILD_CONFIG = $args[$index + 1]
            $index += 2
        }
        default {
            Write-Output "Unknown parameter passed: $($args[$index])"
            exit 1
        }
    }
}

if (-not $MUSESCORE_BUILD_CONFIG) {
    Write-Output "error: not set MUSESCORE_BUILD_CONFIG"
    exit 1
}

Write-Output "MUSESCORE_BUILD_CONFIG: $MUSESCORE_BUILD_CONFIG"

$MSCORE_RELEASE_CHANNEL = cmake -DMUSESCORE_BUILD_CONFIG=$MUSESCORE_BUILD_CONFIG -P config.cmake | Select-String -Pattern 'MSCORE_RELEASE_CHANNEL' | ForEach-Object { $_.Line -replace '.*MSCORE_RELEASE_CHANNEL\s*', '' }

$MSCORE_RELEASE_CHANNEL | Out-File -FilePath "$ARTIFACTS_DIR\env\release_channel.env" -Encoding utf8
Get-Content "$ARTIFACTS_DIR\env\release_channel.env"