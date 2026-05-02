FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Base utilities + LLVM apt repo prerequisites.
RUN apt update && apt install -y --no-install-recommends \
    ca-certificates apt-utils \
    wget curl nano whiptail \
    lsb-release gnupg software-properties-common

# Pin clang-18 via the upstream llvm.sh script. Apt's clang-18 in Focal lags
# upstream point releases; using llvm.sh keeps every port on the same toolchain.
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 18 && \
    rm llvm.sh

# Build essentials + autotools (opusfile uses autoreconf).
RUN apt install -y --no-install-recommends \
    build-essential make gcc g++ \
    libstdc++-10-dev \
    git ninja-build pkg-config \
    autoconf automake libtool

# Common dev libraries used across the various ports' deps and the ports
# themselves.
#
# Notes on what's intentionally absent:
#   - libsdl2-dev / libsdl2-net-dev: every port builds modern SDL2 from source
#     via build_sdl2/build_sdl2_net into /usr/local so the binary links against
#     newer SDL2 headers; at runtime the device's system SDL2 satisfies the
#     SONAME via its own libSDL2-2.0.so.0.
#   - libopus-dev / libopusfile-dev: same reasoning — built from source via
#     build_opus / build_opusfile so the binary picks up the source-built
#     /usr/local copies. Leftover apt-shipped .la / pkg-config files were
#     interfering with libtool's path resolution during opusfile install.
#
# libssl-dev is required by opusfile's ./configure (HTTPS URL fetching support).
RUN apt install -y --no-install-recommends \
    libpng-dev libzip-dev \
    libogg-dev libvorbis-dev \
    libssl-dev \
    libboost-dev libopengl-dev \
    nlohmann-json3-dev libtinyxml2-dev libspdlog-dev \
    zipcmp zipmerge ziptool

# SDL2 source-build deps (the universe of audio/video/input headers SDL2's
# configure walks). Installing them all keeps source builds reproducible
# regardless of which subset a given port actually exercises.
RUN apt install -y --no-install-recommends \
    libasound2-dev libpulse-dev libaudio-dev libjack-dev libsndio-dev \
    libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev \
    libxi-dev libxss-dev libxkbcommon-dev \
    libdrm-dev libgbm-dev libgl1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev \
    libdbus-1-dev libibus-1.0-dev libudev-dev fcitx-libs-dev libwayland-dev \
    gnome-desktop-testing

# Newer CMake than Focal's apt provides. Required by some downstream ports.
RUN wget https://github.com/Kitware/CMake/releases/download/v3.31.3/cmake-3.31.3-linux-$(uname -m).sh && \
    chmod +x cmake-3.31.3-linux-$(uname -m).sh && \
    ./cmake-3.31.3-linux-$(uname -m).sh --prefix=/usr/local --exclude-subdir --skip-license && \
    rm cmake-3.31.3-linux-$(uname -m).sh

ENV CC=clang-18
ENV CXX=clang++-18
ENV LD=lld-18

WORKDIR /root
CMD ["bash"]
