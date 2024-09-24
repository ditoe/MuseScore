# msvc_build.ps1

param (
    [string]$buildType,
    [string]$arch = "64",
    [string]$buildNumber = ""
)

# Default build is 64-bit
# 32-bit compilation is available using "32" as a second parameter when you run msvc_build.ps1
# How to use:
# BUILD 64-bit:
#    "msvc_build.ps1 debug" builds 64-bit Debug version of MuseScore without optimizations
#    "msvc_build.ps1 relwithdebinfo" builds optimized 64-bit version of MuseScore with almost all debug symbols
#    "msvc_build.ps1 release" builds fully optimized 64-bit version of MuseScore without command line output
#
# BUILD 32-bit:
#    "msvc_build.ps1 debug 32" builds 32-bit Debug version of MuseScore
#    "msvc_build.ps1 relwithdebinfo 32" builds 32-bit RelWithDebInfo version of MuseScore
#    "msvc_build.ps1 release 32" builds 32-bit Release version of MuseScore
#
# INSTALL 64-bit:
#    "msvc_build.ps1 install" put all required files of 64-bit Release build to install folder (msvc.install_x64)
#    "msvc_build.ps1 installdebug" put all required files of 64-bit Debug build to install folder (msvc.install_x64)
#    "msvc_build.ps1 installrelwithdebinfo" put all required files of 64-bit RelWithDebInfo build to install folder (msvc.install_x64)
#
# INSTALL 32-bit:
#    "msvc_build.ps1 install 32" put all required files of 32-bit Release build to install folder (msvc.install_x86)
#    "msvc_build.ps1 installdebug 32" put all required files of 32-bit Debug build to install folder (msvc.install_x86)
#    "msvc_build.ps1 installrelwithdebinfo 32" put all required files of 32-bit RelWithDebInfo build to install folder (msvc.install_x86)
#
# PACKAGE:
#    "msvc_build.ps1 package" pack the installer for already built and installed 64-bit Release build (msvc.build_x64/MuseScore-*.msi)
#    "msvc_build.ps1 package 32" pack the installer for already built and installed 32-bit Release build (msvc.build_x86/MuseScore-*.msi)
#
# CLEAN:
#    "msvc_build.ps1 clean" remove all files in msvc.* folders and the folders itself
#
# Windows Portable build is triggered by defining BUILD_WIN_PORTABLE environment variable to "ON" before launching this script, e.g.
# $env:BUILD_WIN_PORTABLE="ON"


function Find-Generator-Version {
    param (
        [string]$vswhere,
        [int]$majorVersion,
        [int]$year
    )

    $version = & $vswhere -version "[$majorVersion,)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion -format value
    if ($version -match "^$majorVersion") {
        $env:GENERATOR_NAME = "Visual Studio $majorVersion $year"
    }
}

function Find-Generator {
    $VSWHERE = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $VSWHERE)) {
        return
    }

    Find-Generator-Version $VSWHERE 16 2019
    if (-not $env:GENERATOR_NAME) {
        Write-Output "Visual Studio 2019 not found. Try to find MSBuild 2019."        
        $MSVC_LIST = Get-ChildItem -Path "C:/Program Files (x86)/Microsoft Visual Studio/20*/*/VC/Tools/MSVC/14.2*/bin/Hostx64/x64/cl.exe" -Recurse
        $MSVC_EXE = $MSVC_LIST[-1].FullName
        if (Test-Path $MSVC_EXE -PathType Leaf) {
            $env:GENERATOR_NAME = "Visual Studio 16 2019"
        }
        else {
            Write-Output "MSBuild 2019 not found."
            return
        }
    }
}


function Build {
    Write-Output "Generator is: $env:GENERATOR_NAME"
    Write-Output "Platform is: $PLATFORM_NAME"
    $BUILD_FOLDER = "$BUILD_FOLDER_$ARCH"
    Write-Output "Build folder is: $BUILD_FOLDER"
    if ($env:BUILD_WIN_PORTABLE -ne "ON") {
        $INSTALL_FOLDER = "$INSTALL_FOLDER_$ARCH"
    }
    Write-Output "Install folder is: $INSTALL_FOLDER"
    if (-not (Test-Path $BUILD_FOLDER)) {
        New-Item -ItemType Directory -Force -Path $BUILD_FOLDER
    }
    if (-not (Test-Path $INSTALL_FOLDER)) {
        New-Item -ItemType Directory -Force -Path $INSTALL_FOLDER
    }

    if ($env:MSCORE_STABLE_BUILD) {
        if ($env:CRASH_LOG_SERVER_URL) {
            if ($env:BUILD_FOR_WINSTORE -eq "OFF") {
                $CRASH_REPORT_URL_OPT = "-DCRASH_REPORT_URL=$env:CRASH_LOG_SERVER_URL -DBUILD_CRASH_REPORTER=ON"
            }
        }

        if ($env:TELEMETRY_TRACK_ID) {
            $TELEMETRY_TRACK_ID_OPT = "-DTELEMETRY_TRACK_ID=$env:TELEMETRY_TRACK_ID"
        }
    }

    if (-not $env:MUSESCORE_BUILD_CONFIG) {
        $env:MUSESCORE_BUILD_CONFIG = "dev"
    }

    $INSTALL_FOLDER = $INSTALL_FOLDER -replace '\\', '/'
    Set-Location $BUILD_FOLDER
    if (Test-Path "CMakeCache.txt") {
        Write-Output "Using existing CMake configuration to save time."
        Write-Output "To force reconfiguration, delete CMakeCache.txt or run 'msvc_build.ps1 clean'."
        Write-Output "You only need to do this if you want to use different build options to before."
    } else {
        Write-Output "Building CMake configuration..."
        cmake -G "$env:GENERATOR_NAME" -A "$PLATFORM_NAME" -DCMAKE_INSTALL_PREFIX=../$INSTALL_FOLDER -DCMAKE_BUILD_TYPE=$CONFIGURATION_STR -DMUSESCORE_BUILD_CONFIG=$env:MUSESCORE_BUILD_CONFIG -DMUSESCORE_REVISION=$env:MUSESCORE_REVISION -DBUILD_FOR_WINSTORE=$env:BUILD_FOR_WINSTORE -DBUILD_64=$env:BUILD_64 -DCMAKE_BUILD_NUMBER=$env:BUILD_NUMBER -DBUILD_AUTOUPDATE=$env:BUILD_AUTOUPDATE $CRASH_REPORT_URL_OPT $TELEMETRY_TRACK_ID_OPT $WIN_PORTABLE_OPT ..
        if ($LASTEXITCODE -ne 0) {
            Remove-Item -Force "CMakeCache.txt"
            exit $LASTEXITCODE
        }
    }
    Write-Output "Building MuseScore..."
    cmake --build . --config $CONFIGURATION_STR --target mscore
    exit 0
}

function Install {
    Set-Location $BUILD_FOLDER
    Write-Output "Installing MuseScore files..."
    cmake --build . --config $CONFIGURATION_STR --target install
    exit 0
}

$ErrorActionPreference = "Stop"

if (-not $env:GENERATOR_NAME) {
    Find-Generator
}

if (-not $env:GENERATOR_NAME) {
    Write-Output "No supported version of Microsoft Visual Studio (2017 or 2019) found."
    exit 1
}

# BUILD_64 and BUILD_FOR_WINSTORE are used in CMakeLists.txt
$env:BUILD_FOR_WINSTORE = "OFF"
$BUILD_FOLDER = "msvc.build"
$INSTALL_FOLDER = "msvc.install"

if ($arch -eq "32") {
    $PLATFORM_NAME = "Win32"
    $ARCH = "x86"
    $env:BUILD_64 = "OFF"
} elseif ($arch -eq "64") {
    $PLATFORM_NAME = "x64"
    $ARCH = "x64"
    $env:BUILD_64 = "ON"
} else {
    Write-Output "Invalid second argument"
    exit 1
}

if ($buildNumber) {
    $env:BUILD_NUMBER = $buildNumber
    $env:BUILD_AUTOUPDATE = "ON"
}

Write-Output "BUILD_WIN_PORTABLE: $env:BUILD_WIN_PORTABLE"
if ($env:BUILD_WIN_PORTABLE -eq "ON") {
    $INSTALL_FOLDER = "MuseScorePortable\App\MuseScore"
    $env:BUILD_AUTOUPDATE = "OFF"
    $WIN_PORTABLE_OPT = "-DBUILD_PORTABLEAPPS=ON"
}

Write-Output "INSTALL_FOLDER: $INSTALL_FOLDER"
Write-Output "WIN_PORTABLE_OPT: $WIN_PORTABLE_OPT"

switch ($buildType.ToLower()) {
    "release" {
        $CONFIGURATION_STR = "release"
        Build
    }
    "debug" {
        $CONFIGURATION_STR = "debug"
        Build
    }
    "relwithdebinfo" {
        $CONFIGURATION_STR = "relwithdebinfo"
        Build
    }
    "install" {
        $BUILD_FOLDER = "$BUILD_FOLDER_$ARCH"
        $CONFIGURATION_STR = "release"
        Install
    }
    "installdebug" {
        $BUILD_FOLDER = "$BUILD_FOLDER_$ARCH"
        $CONFIGURATION_STR = "debug"
        Install
    }
    "installrelwithdebinfo" {
        $BUILD_FOLDER = "$BUILD_FOLDER_$ARCH"
        $CONFIGURATION_STR = "relwithdebinfo"
        Install
    }
    "package" {
        cd "$BUILD_FOLDER_$ARCH"
        cmake --build . --config RelWithDebInfo --target package
        exit 0
    }
    "revision" {
        Write-Output "revisionStep"
        git rev-parse --short=7 HEAD > local_build_revision.env
        exit 0
    }
    "clean" {
        Get-ChildItem -Path . -Filter "msvc.*" -Directory | Remove-Item -Recurse -Force
        Get-ChildItem -Path . -Filter "MuseScorePortable" -Directory | Remove-Item -Recurse -Force
        exit 0
    }
    default {
        Write-Output "No valid parameters are set"
        exit 1
    }
}
