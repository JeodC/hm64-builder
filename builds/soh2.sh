set -e
source /root/tools/lib_build.sh

# Project clone — fail fast on bad REPO_URL/REF.
project_clone https://github.com/HarbourMasters/2ship2harkinian.git

# SDL2 — see soh/build.txt for the rationale on why we build but don't ship libSDL2.
build_sdl2

build_libzip
build_json
build_bzip2
build_tinyxml2
build_opus
build_opusfile

# 2s2h has stricter warnings; relax a few to keep the build green.
export CFLAGS="-O3 -Wall -Wextra -Wno-return-type -Wno-unused-parameter -Wno-unused-function -Wno-unused-variable -Wno-macro-redefined -Wno-unknown-warning-option"
export CXXFLAGS="$CFLAGS"

project_configure_and_build Generate2ShipOtr \
    -DUSE_OPENGLES=1 \
    -DBUILD_CROWD_CONTROL=0 \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE:-Release}

# 2s2h adds vorbis/spdlog to SoH's set.
stage_libs mm/2s2h.elf \
    libz.so.1 \
    libogg.so.0 \
    libpng16.so.16 \
    libvorbis.so.0 \
    libvorbisenc.so.2 \
    libvorbisfile.so.3 \
    libspdlog.so.1 \
    libbz2.so.1 \
    libzip.so.5 \
    libtinyxml2.so.10 \
    libopus.so.0 \
    libopusfile.so.0
