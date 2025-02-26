#!/usr/bin/env bash

BUILD_NUMBER=1

echo "We need Qt 5.12.12 from here: https://download.qt.io/archive/qt/5.12/5.12.12/"

qt_path="$HOME/Qt/5.12.12/5.12.12/gcc_64"


##########################################################################
# GET DEPENDENCIES
##########################################################################

# DISTRIBUTION PACKAGES

# These are installed by default on Travis CI, but not on Docker
apt_packages_basic=(
  # Alphabetical order please!
  file
  git
  pkg-config
  software-properties-common # installs `add-apt-repository`
  unzip
  p7zip-full
  )

# These are the same as on Travis CI
apt_packages_standard=(
  # Alphabetical order please!
  curl
  libasound2-dev 
  libfontconfig1-dev
  libfreetype6-dev
  libfreetype6
  libgl1-mesa-dev
  libjack-dev
  libmp3lame-dev
  libnss3-dev
  libportmidi-dev
  libpulse-dev
  libsndfile1-dev
  make
  portaudio19-dev
  wget
  )

# MuseScore compiles without these but won't run without them
apt_packages_runtime=(
  # Alphabetical order please!
  libcups2
  libdbus-1-3
  libegl1-mesa-dev
  libodbc1
  libpq-dev
  libssl3
  libxcomposite-dev
  libxcursor-dev
  libxi-dev
  libxkbcommon-x11-0
  libxrandr2
  libxtst-dev
  libdrm-dev
  )

sudo apt-get update # no package lists in Docker image
sudo apt-get install -y --no-install-recommends \
  "${apt_packages_basic[@]}" \
  "${apt_packages_standard[@]}" \
  "${apt_packages_runtime[@]}"

# wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
# sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb

# rm -f libssl1.1_1.1.0g-2ubuntu4_amd64.deb

# Qt

if [[ $PATH == *"${qt_path}/bin"* ]]; then
  echo "Qt is in $HOME/Qt/5.15.2/5.12.12/gcc_64/bin"
elif [[ -d "$qt_path" ]]; then
  echo "Qt is in $HOME/Qt/5.15.2/5.12.12/gcc_64/bin"
  export PATH="${qt_path}/bin:${PATH}"
  export LD_LIBRARY_PATH="${qt_path}/lib:\${LD_LIBRARY_PATH}"
  export QT_PATH="${qt_path}"
  export QT_PLUGIN_PATH="${qt_path}/plugins"
  export QML2_IMPORT_PATH="${qt_path}/qml"
else
  echo "Qt is expected here $HOME/Qt/5.12.2/5.12.12/gcc_64/bin"
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

# Build
T_ID="''" # Telemetry_id
bash ./build/ci/linux/build.sh -n "$BUILD_NUMBER" --telemetry $T_ID --build_mu4 OFF --build_mode $BUILD_MODE

# Package
bash ./build/ci/linux/package.sh

rm -rf ./appimagetool ./appimageupdatetool ./linuxdeploy