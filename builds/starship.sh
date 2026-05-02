set -euo pipefail
source /root/tools/lib_build.sh

# Project clone — submodules used recursively for vendored deps.
project_clone https://github.com/HarbourMasters/starship.git --recursive

# SDL2 — see soh/build.txt for rationale on building but not shipping it.
build_sdl2

build_libzip
build_json

# spdlog static-linked into the binary; build current version from source.
build_spdlog

# GSL is header-only but find_package'd; install to make headers discoverable.
build_gsl

project_configure_and_build GeneratePortO2R \
    -DUSE_OPENGLES=1 \
    -DBUILD_CROWD_CONTROL=0 \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE:-Release} \
    -DCMAKE_CXX_FLAGS=-ldl

# tinyxml2/spdlog/nlohmann-json/GSL are static-linked, not runtime deps.
# vorbis/ogg are dynamic deps Starship inherits via libSDL2_mixer/etc., shipped
# defensively for handhelds that don't have them in /usr/lib.
stage_libs Starship \
    libz.so.1 \
    libogg.so.0 \
    libvorbis.so.0 \
    libvorbisenc.so.2 \
    libvorbisfile.so.3 \
    libzip.so.5
