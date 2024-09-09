#!/usr/bin/env bash

BUILD_NUMBER=1

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