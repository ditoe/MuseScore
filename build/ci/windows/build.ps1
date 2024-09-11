# MuseScore build
Write-Output "MuseScore build"

$ARTIFACTS_DIR = "build.artifacts"
$BUILD_NUMBER = ""
$TELEMETRY_TRACK_ID = ""
$SENTRY_SERVER_KEY = ""
$TARGET_PROCESSOR_BITS = 64
$BUILD_WIN_PORTABLE = "OFF"
$BUILD_UI_MU4 = "OFF"  # not used, only for easier synchronization and compatibility


$index = 0
while ($index -lt $args.Length) {
    switch ($args[$index]) {
        "-n" {
            $BUILD_NUMBER = $args[$index + 1]
            $index += 2
        }
        "-b" {
            $TARGET_PROCESSOR_BITS = $args[$index + 1]
            $index += 2
        }
        "--telemetry" {
            $TELEMETRY_TRACK_ID = $args[$index + 1]
            $index += 2
        }
        "--sentrykey" {
            $SENTRY_SERVER_KEY = $args[$index + 1]
            $index += 2
        }
        "--portable" {
            $BUILD_WIN_PORTABLE = $args[$index + 1]
            $index += 2
        }
        "--build_mu4" {
            $BUILD_UI_MU4 = $args[$index + 1]
            $index += 2
        }
        default {
            $index++
        }
    }
}

if ($BUILD_NUMBER -eq "") {
    Write-Output "error: not set BUILD_NUMBER"
    exit 1
}

if ($TARGET_PROCESSOR_BITS -ne 64 -and $TARGET_PROCESSOR_BITS -ne 32) {
    Write-Output "error: not set TARGET_PROCESSOR_BITS, must be 32 or 64, current TARGET_PROCESSOR_BITS: $TARGET_PROCESSOR_BITS"
    exit 1
}

$BUILD_MODE = Get-Content "$ARTIFACTS_DIR\env\build_mode.env"
$MUSESCORE_BUILD_CONFIG = "dev"
switch ($BUILD_MODE) {
    "devel_build" { $MUSESCORE_BUILD_CONFIG = "dev" }
    "nightly_build" { $MUSESCORE_BUILD_CONFIG = "dev" }
    "testing_build" { $MUSESCORE_BUILD_CONFIG = "testing" }
    "stable_build" { $MUSESCORE_BUILD_CONFIG = "release" }
    default {
        Write-Output "error: unknown BUILD_MODE: $BUILD_MODE"
        exit 1
    }
}

$URL_IS_SET = 1
if ($SENTRY_SERVER_KEY -eq "" -or $SENTRY_SERVER_KEY -eq "''") {
    $URL_IS_SET = 0
}

if ($URL_IS_SET -eq 1) {
    $CRASH_LOG_SERVER_URL = "https://sentry.musescore.org/api/2/minidump/?sentry_key=$SENTRY_SERVER_KEY"
} else {
    $CRASH_LOG_SERVER_URL = ""
}

Write-Output "MUSESCORE_BUILD_CONFIG: $MUSESCORE_BUILD_CONFIG"
Write-Output "BUILD_NUMBER: $BUILD_NUMBER"
Write-Output "TARGET_PROCESSOR_BITS: $TARGET_PROCESSOR_BITS"
Write-Output "TELEMETRY_TRACK_ID: $TELEMETRY_TRACK_ID"
Write-Output "CRASH_LOG_SERVER_URL: $CRASH_LOG_SERVER_URL"
Write-Output "BUILD_WIN_PORTABLE: $BUILD_WIN_PORTABLE"
Write-Output "BUILD_UI_MU4: $BUILD_UI_MU4"

Copy-Item -Recurse -Force "C:\musescore_dependencies" $PWD
Write-Output "Finished copy dependencies"

$GENERATOR_NAME = "Visual Studio 16 2019"
$MSCORE_STABLE_BUILD = "TRUE"

# TODO We need define paths during image creation
$JACK_DIR = "C:\Program Files (x86)\Jack"
$QT_DIR = "C:\Qt\5.15.2"

if ($TARGET_PROCESSOR_BITS -eq 32) {
    $env:PATH = "$QT_DIR\msvc2015\bin;$JACK_DIR;$env:PATH"
} else {
    $env:PATH = "$QT_DIR\msvc2019_64\bin;$JACK_DIR;$env:PATH"
}

powershell "& ""./build/ci/tools/make_revision_env.ps1"
$MUSESCORE_REVISION = Get-Content "$ARTIFACTS_DIR\env\build_revision.env"
Write-Output "MUSESCORE_REVISION: $MUSESCORE_REVISION"

powershell "& ""./msvc_build.ps1""" relwithdebinfo $TARGET_PROCESSOR_BITS $BUILD_NUMBER
powershell "& ""./msvc_build.ps1""" installrelwithdebinfo $TARGET_PROCESSOR_BITS $BUILD_NUMBER

powershell "& ""./build/ci/tools/make_release_channel_env.ps1""" $MUSESCORE_BUILD_CONFIG
powershell "& ""./build/ci/tools/make_version_env.ps1""" $BUILD_NUMBER
powershell "& ""./build/ci/tools/make_branch_env.ps1"""
powershell "& ""./build/ci/tools/make_datetime_env.ps1"""