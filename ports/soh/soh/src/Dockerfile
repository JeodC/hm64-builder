FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Base utilities
RUN apt update && apt install -y --no-install-recommends \
    ca-certificates apt-utils \
    wget curl nano whiptail \
    lsb-release gnupg software-properties-common

# Add LLVM apt repository
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 18 && \
    rm llvm.sh

# Build dependencies
RUN apt install -y --no-install-recommends \
    make gcc g++ \
    clang-18 lld-18 \
    libstdc++-10-dev \
    git ninja-build \
    pkg-config \
    libsdl2-dev libsdl2-net-dev \
    libpng-dev libzip-dev \
    zipcmp zipmerge ziptool \
    nlohmann-json3-dev libtinyxml2-dev \
    libboost-dev libopengl-dev \
    libogg-dev libvorbis-dev \
    libopus-dev libopusfile-dev \
    libasound2-dev libpulse-dev

# Newer CMake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.31.3/cmake-3.31.3-linux-$(uname -m).sh && \
    chmod +x cmake-3.31.3-linux-$(uname -m).sh && \
    ./cmake-3.31.3-linux-$(uname -m).sh --prefix=/usr/local --exclude-subdir --skip-license && \
    rm cmake-3.31.3-linux-$(uname -m).sh

# Use clang-18 by default
ENV CC=clang-18
ENV CXX=clang++-18
ENV LD=lld-18

WORKDIR /root
CMD ["bash"]