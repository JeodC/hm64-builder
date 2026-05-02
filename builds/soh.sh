set -e
source /root/tools/lib_build.sh

# BUILD_ANCHOR=1 (default, production) → anchor support: build & ship SDL2_net,
# enable BUILD_REMOTE_CONTROL.
# BUILD_ANCHOR=0 (forks) → skip SDL2_net entirely; useful for handheld/test
# builds that don't need anchor multiplayer.
BUILD_ANCHOR=${BUILD_ANCHOR:-1}

# Project clone — fail fast on bad REPO_URL/REF.
project_clone https://github.com/HarbourMasters/Shipwright.git

# SDL2 from source so libzip/tinyxml2/opus/etc link against modern SDL2 at build time.
# We do NOT ship libSDL2-2.0.so.0 — every supported device already provides one,
# often with device-specific patches. Shipping ours via LD_LIBRARY_PATH would
# override those patches and could regress things that currently work.
build_sdl2

# SDL2_net is only required by BUILD_REMOTE_CONTROL=1 (anchor). Devices DO NOT
# reliably provide libSDL2_net-2.0.so.0, so when we link it, we must ship it.
if [[ "$BUILD_ANCHOR" == "1" ]]; then
    build_sdl2_net
fi

build_libzip
build_json
build_bzip2
build_tinyxml2
build_opus
build_opusfile
build_fmt
build_spdlog -DSPDLOG_FMT_EXTERNAL=ON

# Build SoH.
project_configure_and_build GenerateSohOtr \
    -DCMAKE_PREFIX_PATH=/usr/local \
    -DUSE_OPENGLES=1 \
    -DBUILD_REMOTE_CONTROL=$BUILD_ANCHOR \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE:-Release}

# Stage shipped libraries. Filenames MUST match the binary's DT_NEEDED entries
# exactly. stage_libs uses cp -L so each destination is a real file with the
# right name (a symlink would silently fall through to the system library).
# libSDL2 is NOT shipped (device provides it).
SOH_LIBS=(
    libz.so.1
    libogg.so.0
    libvorbis.so.0
    libvorbisenc.so.2
    libvorbisfile.so.3
    libpng16.so.16
    libbz2.so.1
    libzip.so.5
    libtinyxml2.so.10
    libopus.so.0
    libopusfile.so.0
)
if [[ "$BUILD_ANCHOR" == "1" ]]; then
    SOH_LIBS+=(libSDL2_net-2.0.so.0)
fi
stage_libs soh/soh.elf "${SOH_LIBS[@]}"
