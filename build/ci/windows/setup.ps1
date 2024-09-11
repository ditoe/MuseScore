# Setup Windows build environment
Write-Output "Setup Windows build environment"

$TARGET_PROCESSOR_BITS = 64
$BUILD_WIN_PORTABLE = "OFF"

# Parse arguments
# param (
#     [string[]]$args
# )

$index = 0
while ($index -lt $args.Length) {
    switch ($args[$index]) {
        "-b" {
            $TARGET_PROCESSOR_BITS = $args[$index + 1]
            $index += 2
        }
        "--portable" {
            $BUILD_WIN_PORTABLE = $args[$index + 1]
            $index += 2
        }
        default {
            $index++
        }
    }
}

if ($TARGET_PROCESSOR_BITS -ne 64 -and $TARGET_PROCESSOR_BITS -ne 32) {
    Write-Output "error: not set TARGET_PROCESSOR_BITS, must be 32 or 64, current TARGET_PROCESSOR_BITS: $TARGET_PROCESSOR_BITS"
    exit 1
}

# Install tools
# if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
#     choco install -y git.install
# }

# if (-not (Get-Command wget -ErrorAction SilentlyContinue)) {
#     choco install -y wget
# }

# if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
#     choco install -y 7zip.install
# }

# Set temp dir
$TEMP_DIR = "C:\TEMP\musescore"
New-Item -ItemType Directory -Force -Path $TEMP_DIR

# Install Qt
# Write-Output "=== Install Qt ==="

# Default for x64
# $Qt_ARCHIVE = "qt599_msvc2017_64.7z"

# if ($TARGET_PROCESSOR_BITS -eq 32) {
#     $Qt_ARCHIVE = "qt599_msvc2015.7z"
# }

# $QT_URL = "https://s3.amazonaws.com/utils.musescore.org/$Qt_ARCHIVE"
$QT_DIR = "C:\Qt\5.15.2"

# Invoke-WebRequest -Uri $QT_URL -OutFile "$TEMP_DIR\$Qt_ARCHIVE"
# 7z x -y "$TEMP_DIR\$Qt_ARCHIVE" -o"$QT_DIR"

# Install dependencies
Write-Output "=== Install dependencies ==="
# Invoke-WebRequest -Uri "https://s3.amazonaws.com/utils.musescore.org/musescore_dependencies_win32.7z" -OutFile "$TEMP_DIR\musescore_dependencies_win32.7z"
# 7z x -y "$TEMP_DIR\musescore_dependencies_win32.7z" -o"$TEMP_DIR\musescore_dependencies_win32"
$JACK_DIR = "C:\Program Files (x86)\Jack"
# Copy-Item -Recurse -Force "$TEMP_DIR\musescore_dependencies_win32\dependencies\Jack" -Destination $JACK_DIR
$env:PATH = "$JACK_DIR;$env:PATH"

# Invoke-WebRequest -Uri "https://s3.amazonaws.com/utils.musescore.org/dependencies.7z" -OutFile "$TEMP_DIR\dependencies.7z"
# 7z x -y "$TEMP_DIR\dependencies.7z" -o"C:\musescore_dependencies"

# breakpad_tools
Write-Output "=== Install breakpad_tools ==="
Invoke-WebRequest -Uri "https://s3.amazonaws.com/utils.musescore.org/dump_syms_32.7z" -OutFile "$TEMP_DIR\dump_syms_32.7z"
7z x -y "$TEMP_DIR\dump_syms_32.7z" -o"C:\breakpad_tools"

if ($BUILD_WIN_PORTABLE -eq "ON") {
    Write-Output "=== Installing PortableApps.com Tools ==="
    Invoke-WebRequest -Uri "https://s3.amazonaws.com/utils.musescore.org/portableappslauncher.zip" -OutFile "$TEMP_DIR\portableappslauncher.zip"
    7z x -y "$TEMP_DIR\portableappslauncher.zip" -o"C:\portableappslauncher"

    Invoke-WebRequest -Uri "https://s3.amazonaws.com/utils.musescore.org/portableappsinstaller.zip" -OutFile "$TEMP_DIR\portableappsinstaller.zip"
    7z x -y "$TEMP_DIR\portableappsinstaller.zip" -o"C:\portableappsinstaller"
}

# Clean
Write-Output "=== Clean ==="
Remove-Item -Recurse -Force "C:\TEMP"

Write-Output "Setup script done"