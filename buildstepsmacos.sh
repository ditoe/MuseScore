#!/usr/bin/env bash

BUILD_NUMBER=1

echo "We need Qt 5.12.12 from here: https://download.qt.io/archive/qt/5.12/5.12.12/"
echo "We need XCode 10.3 from here: https://developer.apple.com/download/all/?q=Xcode%2010.3"

if [[ $PATH == *"$HOME/Qt/5.12.12/5.12.12/clang_64/bin"* ]]; then
  echo "Qt is in $HOME/Qt/5.15.2/5.12.12/clang_64/bin"
else
  echo "Qt is expected here $HOME/Qt/5.15.2/clang_64/bin"
  exit 1
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--number) BUILD_NUMBER="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$BUILD_NUMBER" ]; then echo "error: not set BUILD_NUMBER"; exit 1; fi

# "Configure workflow"
bash ./build/ci/tools/make_build_mode_env.sh -m devel_build
BUILD_MODE=$(cat ./build.artifacts/env/build_mode.env)

# Setup environment
bash ./build/ci/macos/setup_local_env.sh

# Build
T_ID="''" # Telemetry_id
bash ./build/ci/macos/build_local.sh -n "$BUILD_NUMBER" --telemetry $T_ID

# Package
S_S="''"
S_P="''"
bash ./build/ci/macos/package.sh --signpass "$S_P" --signsecret "$S_S"