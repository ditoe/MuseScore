#!/usr/bin/env bash

echo "Setup MacOS build environment"

trap 'echo Setup failed; exit 1' ERR
SKIP_ERR_FLAG=true

export MACOSX_DEPLOYMENT_TARGET=10.10

WITH_QT_DOWNLOAD=false
WITH_JACK_INSTALL=false
WITH_BOTTLES=false
WITH_SPARKLE=false

export MACOSX_DEPLOYMENT_TARGET=10.15

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --with_qt) WITH_QT_DOWNLOAD="$2"; shift ;;
        --with_jack) WITH_JACK_INSTALL="$2"; shift ;;
        --with_bottles) WITH_BOTTLES="$2"; shift ;;
        --with_sparkle) WITH_SPARKLE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# install dependencies
if [ "$WITH_BOTTLES" = true ] ; then
    echo "Download bottles"
    
    wget -c --no-check-certificate -nv -O bottles.zip https://musescore.org/sites/musescore.org/files/2020-02/bottles-MuseScore-3.0-yosemite.zip
    unzip bottles.zip
fi

# we don't use freetype
rm bottles/freetype* | $SKIP_ERR_FLAG

brew update >/dev/null | $SKIP_ERR_FLAG

# fixing install python 3.9 error (it is a dependency for JACK)
# rm '/usr/local/bin/2to3'

# additional dependencies
if [ "$WITH_JACK_INSTALL" = true ] ; then
    brew install jack lame
fi

BREW_CELLAR=$(brew --cellar)
BREW_PREFIX=$(brew --prefix)

function fixBrewPath {
  DYLIB_FILE=$1
  BREW_CELLAR=$(brew --cellar)
  BREW_PREFIX=$(brew --prefix)
  chmod 644 $DYLIB_FILE
  # change ID
  DYLIB_ID=$(otool -D  $DYLIB_FILE | tail -n 1)
  if [[ "$DYLIB_ID" == *@@HOMEBREW_CELLAR@@* ]]
  then
      PSLASH=$(echo $DYLIB_ID | sed "s,@@HOMEBREW_CELLAR@@,$BREW_CELLAR,g")
      install_name_tool -id $PSLASH $DYLIB_FILE
  fi
  if [[ "$DYLIB_ID" == *@@HOMEBREW_PREFIX@@* ]]
  then
      PSLASH=$(echo $DYLIB_ID | sed "s,@@HOMEBREW_PREFIX@@,$BREW_PREFIX,g")
      install_name_tool -id $PSLASH $DYLIB_FILE
  fi
  # Change dependencies
  for P in `otool -L $DYLIB_FILE | awk '{print $1}'`
  do
    if [[ "$P" == *@@HOMEBREW_CELLAR@@* ]]
    then
        PSLASH=$(echo $P | sed "s,@@HOMEBREW_CELLAR@@,$BREW_CELLAR,g")
        install_name_tool -change $P $PSLASH $DYLIB_FILE
    fi
    if [[ "$P" == *@@HOMEBREW_PREFIX@@* ]]
    then
        PSLASH=$(echo $P | sed "s,@@HOMEBREW_PREFIX@@,$BREW_PREFIX,g")
        install_name_tool -change $P $PSLASH $DYLIB_FILE
    fi
  done
  chmod 444 $DYLIB_FILE
}
export -f fixBrewPath

function installBottleManually {
  brew unlink $1
  rm -rf /usr/local/Cellar/$1
  tar xzvf bottles/$1*.tar.gz -C $BREW_CELLAR
  find $BREW_CELLAR/$1 -type f -name '*.pc' -exec sed -i '' "s:@@HOMEBREW_CELLAR@@:$BREW_CELLAR:g" {} +
  find $BREW_CELLAR/$1 -type f -name '*.dylib' -exec bash -c 'fixBrewPath "$1"' _ {} \;
  brew link $1
}

installBottleManually libogg
installBottleManually libvorbis
installBottleManually flac
installBottleManually libsndfile
installBottleManually portaudio


export QT_SHORT_VERSION=5.15.2
export QT_PATH=$HOME/Qt
export QT_MACOS=$QT_PATH/$QT_SHORT_VERSION/clang_64

# echo "PATH=$PATH" >> $GITHUB_ENV  # we are not on github
if [ "$WITH_QT_DOWNLOAD" = true ] ; then
    export PATH=$PATH:$QT_MACOS/bin
    echo "Download Qt"
    wget -nv -O qt5.zip https://s3.amazonaws.com/utils.musescore.org/Qt5152_mac.zip
    mkdir -p $QT_MACOS
    unzip -qq qt5.zip -d $QT_MACOS
    rm qt5.zip
fi

#install sparkle
export SPARKLE_VERSION=1.20.0
if [ "$WITH_SPARKLE" = true ] ; then
    echo "Download Sparkle"
    mkdir Sparkle-${SPARKLE_VERSION}
    cd Sparkle-${SPARKLE_VERSION}
    wget -nv https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.bz2
    tar jxf Sparkle-${SPARKLE_VERSION}.tar.bz2
    cd ..
    mkdir -p ~/Library/Frameworks
    mv Sparkle-${SPARKLE_VERSION}/Sparkle.framework ~/Library/Frameworks/
    rm -rf Sparkle-${SPARKLE_VERSION}
fi

echo "Setup script done"
