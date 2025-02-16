# MuseScore build script for Windows

$BUILD_NUMBER = 1
$BUILD_WIN_PORTABLE = "OFF"

Write-Output "We need Qt 5.15 from here: https://download.qt.io/archive/qt/5.15/"
Write-Output "Default Qt-Path is: projectDir\dependencies\windows_x64\Qt\5.15.2\msvc2019_64\bin, if not specified in PATH"

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
        "--portable" {
            $BUILD_WIN_PORTABLE = $args[$index + 1]
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
powershell "& ""./build/ci/tools/make_build_mode_env.ps1""" -m "local_build"
# BUILD_MODE = "devel_build"
$BUILD_MODE = Get-Content ./build.artifacts/env/build_mode.env
Write-Output "BUILD_MODE: $BUILD_MODE"

# Build
powershell "& ""./build/ci/windows/build.ps1""" -n "$BUILD_NUMBER" --portable "$BUILD_WIN_PORTABLE"

# Package
powershell "& ""./build/ci/windows/package.ps1""" --portable "$BUILD_WIN_PORTABLE"