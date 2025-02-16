# make_build_mode_env.ps1

$build_event = ""
$BuildMode = ""



$ARTIFACTS_DIR = "build.artifacts"


$index = 0
while ($index -lt $args.Length) {
    switch ($args[$index]) {
        "-e" { 
            $build_event = $args[$index + 1]
            $index += 2
        }
        "--event" {
            $build_event = $args[$index + 1]
            $index += 2
        }
        "-m" {
            $BuildMode = $args[$index + 1]
            $index += 2
        }
        "--mode" {
            $BuildMode = $args[$index + 1]
            $index += 2
        }
        default {
            Write-Output "Unknown parameter passed: $($args[$index])"
            exit 1
        }
    }
}

if (-not $BuildMode) {
    if (-not $build_event) {
        Write-Output "error: not set EVENT"
        exit 1
    }

    switch ($build_event) {
        "pull_request" { $BuildMode = "devel_build" }
        "schedule" { $BuildMode = "nightly_build" }
        "workflow_dispatch" {
            Write-Output "error: event workflow_dispatch, but not set BUILD_MODE"
            exit 1
        }
    }
}

Write-Output "EVENT: $build_event"

$ModeIsValid = $false
switch ($BuildMode) {
    "local_build" { $ModeIsValid = $true }
    "devel_build" { $ModeIsValid = $true }
    "nightly_build" { $ModeIsValid = $true }
    "testing_build" { $ModeIsValid = $true }
    "stable_build" { $ModeIsValid = $true }
}

if (-not $ModeIsValid) {
    Write-Output "error: Not valid build mode: $BuildMode"
    Write-Output "valid modes: "
    Write-Output "  local_build - build for developers, usually builds for local testing"
    Write-Output "  devel_build - build for developers, usually builds on pull request"
    Write-Output "  nightly_build - build for testing current development, usually builds once a day"
    Write-Output "  testing_build - build for testing before release (alpha, beta, rc), usually builds manually"
    Write-Output "  stable_build - build for release, usually builds manually"
    exit 1
}

New-Item -ItemType Directory -Force -Path "$ARTIFACTS_DIR"
New-Item -ItemType Directory -Force -Path "$ARTIFACTS_DIR/env"

$BuildMode | Out-File -FilePath "$ARTIFACTS_DIR/env/build_mode.env" -Encoding utf8
Write-Output "BUILD_MODE: $(Get-Content $ARTIFACTS_DIR/env/build_mode.env)"
return 0