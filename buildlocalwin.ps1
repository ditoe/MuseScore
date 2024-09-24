# MuseScore build script for Windows

$BUILD_NUMBER = 1

Write-Output "We need Qt 5.15.2 from here: https://download.qt.io/archive/qt/5.15/5.15.2/"

$env:Path = 'C:\Qt\5.15.2\msvc2019_64\bin;' + $env:Path

if ($env:PATH -like "*C:\Qt\5.15.2\msvc2019_64\bin*") {
    Write-Output "Qt is in C:\Qt\5.15.2\msvc2019_64\bin"
} else {
    Write-Output "Qt is expected here C:\Qt\5.15.2\msvc2019_64\bin"
    exit 1
}


$index = 0
while ($index -lt $args.Length) {
    switch ($args[$index]) {
        "-n" { 
            $BUILD_NUMBER = $args[$index + 1]
            $index += 2
        }
        "--number" {
            $BUILD_NUMBER = $args[$index + 1]
            $index += 2
        }
        default {
            Write-Output "Unknown parameter passed: $($args[$index])"
            exit 1
        }
    }
}

if (-not $BUILD_NUMBER) {
    Write-Output "error: not set BUILD_NUMBER"
    exit 1
}

# "Configure workflow"
bash ./build/ci/tools/make_build_mode_env.sh -m devel_build
# BUILD_MODE = "devel_build"
$BUILD_MODE = Get-Content ./build.artifacts/env/build_mode.env
Write-Output "BUILD_MODE: devel_build"

# Build
$T_ID = "''" # Telemetry_id
powershell -noexit "& ""./build/ci/windows/build.ps1""" -n "$BUILD_NUMBER" --telemetry $T_ID

# Package
$S_S = "''"
$S_P = "''"
powershell -noexit "& ""./build/ci/macos/package.ps1""" --signpass "$S_P" --signsecret "$S_S"