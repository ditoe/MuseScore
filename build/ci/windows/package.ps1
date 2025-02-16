# MuseScore package

Write-Output "MuseScore package"

$ARTIFACTS_DIR = "build.artifacts"

$BUILD_MODE = ""
$TARGET_PROCESSOR_BITS = 64
$TARGET_PROCESSOR_ARCH = "x64"
$BUILD_DIR = "msvc.build_x64"
$INSTALL_DIR = "msvc.install_x64"
$SIGN_CERTIFICATE_ENCRYPT_SECRET = ""
$SIGN_CERTIFICATE_PASSWORD = ""
$BUILD_WIN_PORTABLE = "OFF"
$UPGRADE_UUID = "11111111-1111-1111-1111-111111111111"

$index = 0
while ($index -lt $args.Length) {
    switch ($args[$index]) {
        "-m" {
            $BUILD_MODE = $args[$index + 1]
            $index += 2
        }
        "-b" {
            $TARGET_PROCESSOR_BITS = $args[$index + 1]
            $index += 2
        }
        "--signsecret" {
            $SIGN_CERTIFICATE_ENCRYPT_SECRET = $args[$index + 1]
            $index += 2
        }
        "--signpass" {
            $SIGN_CERTIFICATE_PASSWORD = $args[$index + 1]
            $index += 2
        }
        "--portable" {
            $BUILD_WIN_PORTABLE = $args[$index + 1]
            $index += 2
        }
        "--guid" {
            $UPGRADE_UUID = $args[$index + 1]
            $index += 2
        }
        default {
            $index++
        }
    }
}



function PACK_7z{
    param(
        [string]$BUILD_MODE,
        [string]$BUILD_DATETIME,
        [string]$BUILD_BRANCH,
        [string]$BUILD_REVISION,
        [string]$BUILD_VERSION,
        [string]$TARGET_PROCESSOR_ARCH,
        [string]$INSTALL_DIR,
        [string]$ARTIFACTS_DIR,
        [string]$ARTIFACT_NAME
    )
    Write-Output "Start 7z packing..."
    if ($BUILD_MODE -eq "nightly_build") {
        $ARTIFACT_NAME = "MuseScoreNightly-$BUILD_DATETIME-$BUILD_BRANCH-$BUILD_REVISION-$TARGET_PROCESSOR_ARCH"
    } else {
        $ARTIFACT_NAME = "MuseScore-$BUILD_VERSION-$TARGET_PROCESSOR_ARCH"
    }

    Rename-Item -Path $INSTALL_DIR -NewName $ARTIFACT_NAME
    7z a "$ARTIFACTS_DIR\$ARTIFACT_NAME.7z" $ARTIFACT_NAME

    powershell.exe "& ""./build/ci/tools/make_artifact_name_env.ps1""" $ARTIFACT_NAME

    Write-Output "Finished 7z packing"
    exit 0
}

function PACK_DIR{
    param(
        [string]$INSTALL_DIR,
        [string]$ARTIFACTS_DIR
    )
    Write-Output "Start dir packing..."
    New-Item -ItemType Directory -Force -Path "$($ARTIFACTS_DIR)\MuseScore"
    Copy-Item -Recurse -Force "$INSTALL_DIR\*" "$($ARTIFACTS_DIR)\MuseScore"
    Write-Output "Finished dir packing"
    exit 0
}

function PACK_MSI {
    param(
        [string]$BUILD_MODE,
        [string]$BUILD_DATETIME,
        [string]$BUILD_BRANCH,
        [string]$BUILD_REVISION,
        [string]$BUILD_VERSION,
        [string]$TARGET_PROCESSOR_BITS,
        [string]$TARGET_PROCESSOR_ARCH,
        [string]$INSTALL_DIR,
        [string]$ARTIFACTS_DIR,
        [string]$ARTIFACT_NAME,
        [string]$BUILD_DIR,
        [string]$DO_SIGN,
        [string]$SIGN_CERTIFICATE_ENCRYPT_SECRET,
        [string]$SIGN_CERTIFICATE_PASSWORD,
        [string]$SIGN,
        [string]$WIX_DIR

    )
    Write-Output "Start msi packing..."
    # sign dlls and exe files
    if ($DO_SIGN -eq "ON") {
        cmd /c "$($SIGN)/sign.bat --secret $SIGN_CERTIFICATE_ENCRYPT_SECRET --pass $SIGN_CERTIFICATE_PASSWORD --dir $INSTALL_DIR"
    } else {
        Write-Output "Sign disabled"
    }

    # generate unique GUID
    $PACKAGE_UUID = New-Guid
    Write-Output "PACKAGE_UUID: $PACKAGE_UUID"
    (Get-Content $PSScriptRoot/../../Packaging.cmake) -replace '00000000-0000-0000-0000-000000000000', $PACKAGE_UUID | Set-Content $PSScriptRoot/../../Packaging.cmake
    (Get-Content $PSScriptRoot/../../Packaging.cmake) -replace '11111111-1111-1111-1111-111111111111', $UPGRADE_UUID | Set-Content $PSScriptRoot/../../Packaging.cmake

    $PACKAGE_FILE_ASSOCIATION = "OFF"
    if ($BUILD_MODE -eq "stable_build") {
        $PACKAGE_FILE_ASSOCIATION = "ON"
    }
    Set-Location $PSScriptRoot/../../../$BUILD_DIR
    $BUILD_DIR = Get-Location
    # $BUILD_DIR = "$($PSScriptRoot)\..\..\..\$BUILD_DIR"

    # Set-Location $BUILD_DIR
    cmake -DPACKAGE_FILE_ASSOCIATION="$($PACKAGE_FILE_ASSOCIATION)" ..
    Set-Location $BUILD_DIR/../

    $env:PATH = "$($WIX_DIR);$($env:PATH)"
    powershell.exe "& ""./msvc_build.ps1""" "package" "$TARGET_PROCESSOR_BITS"

    Write-Output "Create logs dir"
    New-Item -ItemType Directory -Force -Path "$($ARTIFACTS_DIR)\logs"
    New-Item -ItemType Directory -Force -Path "$($ARTIFACTS_DIR)\logs\WIX"

    $WIX_LOG_DIR = "win64"
    if ($TARGET_PROCESSOR_BITS -eq 32) {
        $WIX_LOG_DIR = "win32"
    }

    $WIX_LOGS_PATH = "$($BUILD_DIR)\_CPack_Packages\$($WIX_LOG_DIR)\WIX"
    Write-Output "Copy from $($WIX_LOGS_PATH) to $($ARTIFACTS_DIR)\logs\WIX"

    $excludedmsi = "*.msi"
    Copy-Item -Recurse -Force -Exclude $excludedmsi "$($WIX_LOGS_PATH)\*" "$($ARTIFACTS_DIR)\logs\WIX"

    # find the MSI file without the hardcoded version
    $FILEPATH = Get-ChildItem -Path "$BUILD_DIR" -Filter "*.msi" -Recurse | Select-Object -First 1 | ForEach-Object { $_.FullName }

    if ($BUILD_MODE -eq "nightly_build") {
        $ARTIFACT_NAME = "MuseScoreNightly-$($BUILD_DATETIME)-$($BUILD_BRANCH)-$($BUILD_REVISION)-$($TARGET_PROCESSOR_ARCH).msi"
    } else {
        $ARTIFACT_NAME = "MuseScore-$($BUILD_VERSION)-$($TARGET_PROCESSOR_ARCH).msi"
    }

    Write-Output "Copy from $($FILEPATH) to $($ARTIFACT_NAME)"
    Copy-Item -Path $FILEPATH -Destination "$($ARTIFACTS_DIR)\$($ARTIFACT_NAME)" -Force
    $ARTIFACT_PATH = "$($ARTIFACTS_DIR)\$($ARTIFACT_NAME)"

    if ($DO_SIGN -eq "ON") {
        cmd /c "$($SIGN)/sign.bat --secret $($SIGN_CERTIFICATE_ENCRYPT_SECRET) --pass $($SIGN_CERTIFICATE_PASSWORD) --name $($ARTIFACT_NAME) --file $($ARTIFACT_PATH)"
    }

    powershell.exe "& ""./build/ci/tools/make_artifact_name_env.ps1""" $ARTIFACT_NAME

    # DEBUG SYM
    Write-Output "Debug symbols generating.."
    $DEBUG_SYMS_FILE = "musescore_win$($TARGET_PROCESSOR_BITS).sym"
    cmd /c "C:\breakpad_tools\dump_syms.exe $($BUILD_DIR)\main\RelWithDebInfo\MuseScore3.pdb > $DEBUG_SYMS_FILE"
    Copy-Item -Path $DEBUG_SYMS_FILE -Destination "$($ARTIFACTS_DIR)\$(($DEBUG_SYMS_FILE))" -Force
    Write-Output "Finished debug symbols generating"

    exit 0
}

function PACK_PORTABLE {
    param(
        [string]$INSTALL_DIR,
        [string]$ARTIFACTS_DIR,
        [string]$DO_SIGN,
        [string]$SIGN_CERTIFICATE_ENCRYPT_SECRET,
        [string]$SIGN_CERTIFICATE_PASSWORD,
        [string]$SIGN,
        [string]$TARGET_PROCESSOR_ARCH,
        [string]$BUILD_VERSION,
        [string]$ARTIFACT_NAME
    )
    Write-Output "Start portable packing..."

    # sign dlls and exe files
    if ($DO_SIGN -eq "ON") {
        cmd /c "$($SIGN)/sign.bat --secret $SIGN_CERTIFICATE_ENCRYPT_SECRET --pass $SIGN_CERTIFICATE_PASSWORD --dir $INSTALL_DIR"
    } else {
        Write-Output "Sign disabled"
    }

    # Create launcher
    cmd /c "C:\portableappslauncher\Launcher\PortableApps.comLauncherGenerator.exe $PWD\$INSTALL_DIR"
    Write-Output "Finished comLauncherGenerator"

    # Create Installer
    cmd /c "C:\portableappsinstaller\Installer\PortableApps.comInstaller.exe $PWD\$INSTALL_DIR"
    Write-Output "Finished comInstaller"

    # find the paf.exe file
    $FILEPATH = Get-ChildItem -Path "." -Filter "*.paf.exe" -Recurse | Select-Object -First 1
    $ARTIFACT_NAME = "MuseScore-$($BUILD_VERSION)-$($TARGET_PROCESSOR_ARCH).paf.exe"

    Write-Output "Copy from $FILEPATH to $ARTIFACT_NAME"
    Copy-Item -Path $FILEPATH -Destination "$($ARTIFACTS_DIR)\$($ARTIFACT_NAME)" -Force
    $ARTIFACT_PATH = "$($ARTIFACTS_DIR)\$($ARTIFACT_NAME)"

    if ($DO_SIGN -eq "ON") {
        cmd /c "$($SIGN)/sign.bat --secret $SIGN_CERTIFICATE_ENCRYPT_SECRET --pass $SIGN_CERTIFICATE_PASSWORD --name $ARTIFACT_NAME --file $ARTIFACT_PATH"
    }

    powershell.exe "& ""./build/ci/tools/make_artifact_name_env.ps1""" $ARTIFACT_NAME

    Write-Output "Finished portable packing"

    exit 0
}

# Try get from env
if ($BUILD_MODE -eq "") {
    $BUILD_MODE = Get-Content "$ARTIFACTS_DIR\env\build_mode.env"
}

# Check args
if ($BUILD_MODE -eq "") {
    Write-Output "error: not set BUILD_MODE"
    exit 1
}

if ($TARGET_PROCESSOR_BITS -ne 64 -and $TARGET_PROCESSOR_BITS -ne 32) {
    Write-Output "error: not set TARGET_PROCESSOR_BITS, must be 32 or 64, current TARGET_PROCESSOR_BITS: $TARGET_PROCESSOR_BITS"
    exit 1
}

if ($TARGET_PROCESSOR_BITS -eq 32) {
    $TARGET_PROCESSOR_ARCH = "x86"
    $BUILD_DIR = "msvc.build_x86"
    $INSTALL_DIR = "msvc.install_x86"
}

if ("$BUILD_WIN_PORTABLE" -eq "ON") {
    $INSTALL_DIR = "MuseScorePortable"
    $env:BUILD_WIN_PORTABLE = "ON"
}

# Setup package type
switch ($BUILD_MODE) {
    "local_build" { $PACKAGE_TYPE = "msi" }
    "devel_build" { $PACKAGE_TYPE = "7z" }
    "nightly_build" { $PACKAGE_TYPE = "7z" }
    "testing_build" { $PACKAGE_TYPE = "msi" }
    "stable_build" { $PACKAGE_TYPE = "msi" }
    default {
        if ("$BUILD_WIN_PORTABLE" -eq "ON") {
            $PACKAGE_TYPE = "portable"
        } else {
            Write-Output "Unknown BUILD_MODE: $BUILD_MODE"
            exit 1
        }
    }
}

$NEED_SIGN = "OFF"
if ($PACKAGE_TYPE -eq "msi" -or $PACKAGE_TYPE -eq "portable") {
    $NEED_SIGN = "ON"
}

$DO_SIGN = "OFF"
if ($NEED_SIGN -eq "ON") {
    $DO_SIGN = "ON"
    if ($SIGN_CERTIFICATE_ENCRYPT_SECRET -eq "") {
        $DO_SIGN = "OFF"
        Write-Output "warning: not set SIGN_CERTIFICATE_ENCRYPT_SECRET"
    }
    if ($SIGN_CERTIFICATE_PASSWORD -eq "") {
        $DO_SIGN = "OFF"
        Write-Output "warning: not set SIGN_CERTIFICATE_PASSWORD"
    }
}

$BUILD_VERSION = Get-Content "$ARTIFACTS_DIR\env\build_version.env"
$BUILD_DATETIME = Get-Content "$ARTIFACTS_DIR\env\build_datetime.env"
$BUILD_BRANCH = Get-Content "$ARTIFACTS_DIR\env\build_branch.env"
$BUILD_REVISION = Get-Content "$ARTIFACTS_DIR\env\build_revision.env"

Write-Output "BUILD_MODE: $BUILD_MODE"
Write-Output "BUILD_DATETIME: $BUILD_DATETIME"
Write-Output "BUILD_BRANCH: $BUILD_BRANCH"
Write-Output "BUILD_REVISION: $BUILD_REVISION"
Write-Output "BUILD_VERSION: $BUILD_VERSION"
Write-Output "TARGET_PROCESSOR_BITS: $TARGET_PROCESSOR_BITS"
Write-Output "TARGET_PROCESSOR_ARCH: $TARGET_PROCESSOR_ARCH"
Write-Output "BUILD_DIR: $BUILD_DIR"
Write-Output "INSTALL_DIR: $INSTALL_DIR"
Write-Output "PACKAGE_TYPE: $PACKAGE_TYPE"

# Tools
$SIGN = "build\ci\windows" # sign.bat"
$WIX_DIR = $env:WIX

switch ($PACKAGE_TYPE) {
    "portable" { PACK_PORTABLE $INSTALL_DIR $ARTIFACTS_DIR $DO_SIGN $SIGN_CERTIFICATE_ENCRYPT_SECRET $SIGN_CERTIFICATE_PASSWORD $SIGN $TARGET_PROCESSOR_ARCH $BUILD_VERSION $ARTIFACT_NAME }
    "7z" { PACK_7z $BUILD_MODE $BUILD_DATETIME $BUILD_BRANCH $BUILD_REVISION $BUILD_VERSION $TARGET_PROCESSOR_ARCH $INSTALL_DIR $ARTIFACTS_DIR $ARTIFACT_NAME }
    "msi" { PACK_MSI $BUILD_MODE $BUILD_DATETIME $BUILD_BRANCH $BUILD_REVISION $BUILD_VERSION $TARGET_PROCESSOR_BITS $TARGET_PROCESSOR_ARCH $INSTALL_DIR $ARTIFACTS_DIR $ARTIFACT_NAME $BUILD_DIR $DO_SIGN $SIGN_CERTIFICATE_ENCRYPT_SECRET $SIGN_CERTIFICATE_PASSWORD $SIGN $WIX_DIR }
    "dir" { PACK_DIR $INSTALL_DIR $ARTIFACTS_DIR }
    default {
        Write-Output "Unknown package type: $PACKAGE_TYPE"
        exit 1
    }
}