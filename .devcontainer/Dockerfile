FROM ubuntu:22.04

# Install common programs for development
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        bash-completion \
        build-essential \
        ca-certificates \
        clang \
        clangd-15 \
        coreutils \
        curl \
        desktop-file-utils \
        ffmpeg \
        fonts-noto \
        gawk \
        gdb \
        git \
        gnupg2 \
        inetutils-ping \
        iproute2 \
        keyboard-configuration \
        lcov \
        libasound2-dev \
        libavcodec-dev \
        libavformat-dev \
        libcups2 \
        libcups2-dev \
        libdbus-1-3 \
        libdbus-1-dev \
        libdrm-dev \
        libegl1-mesa-dev \
        libfontconfig1-dev \
        libfreetype6 \
        libfreetype6-dev \
        libgcrypt20-dev \
        libgl1 \
        libgl1-mesa-dev \
        libglib2.0-0 \
        libglib2.0-dev \
        libgpgme-dev \
        libgtk2.0-dev \
        libjack-dev \
        libmp3lame-dev \
        libnss3-dev \
        libodbc1 \
        libportmidi-dev \
        libpq-dev \
        libpulse-dev \
        librsvg2-dev \
        libsndfile1-dev \
        libswscale-dev \
        libtool \
        libudev-dev \
        libxcb-cursor0 \
        libxcb-icccm4 \
        libxcb-icccm4-dev \
        libxcb-image0 \
        libxcb-image0-dev \
        libxcb-keysyms1 \
        libxcb-keysyms1-dev \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-render-util0-dev \
        libxcb-shape0-dev \
        libxcb-util-dev \
        libxcb-xinerama0 \
        libxcb-xinerama0-dev \
        libxcomposite-dev \
        libxcursor-dev \
        libxi-dev \
        libxkbcommon-x11-0 \
        libxrandr2 \
        libxtst-dev \
        lld \
        lldb \
        locales \
        lsb-release \
        make \
        nano \
        openssh-server \
        p7zip-full \
        portaudio19-dev \
        pulseaudio \
        sed \
        software-properties-common \
        sudo \
        unzip \
        vim \
        wget \
        xauth \
        xcb \
        xvfb \
        zsync && \
    ln -sf /usr/bin/clangd-15 /usr/local/bin/clangd && \
    rm -rf /var/lib/apt/lists/*

# Install additional libraries for runtime
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        alsa-utils \
        libgles2-mesa-dev \
        libodbc2 \
        libopengl-dev \
        libssl-dev \
        libvulkan-dev \
        libxcb-xkb-dev \
        libxkbcommon-dev && \
    rm -rf /var/lib/apt/lists/*


# Setup US locale for correct decimal point handling
RUN locale-gen en_US.UTF-8
