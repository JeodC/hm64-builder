set -e
source /root/tools/lib_build.sh

project_clone https://github.com/HarbourMasters/Ghostship.git

build_sdl2
build_libzip
build_json
build_tinyxml2
build_gsl
build_spdlog

project_configure_and_build GeneratePortO2R \
    -DUSE_OPENGLES=1 \
    -DBUILD_CROWD_CONTROL=0 \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE:-Release} \
    -DCMAKE_EXE_LINKER_FLAGS="-ldl -pthread"

# Ghostship only NEEDs zip and tinyxml2 — vorbis/ogg/z previously staged here
# were ghost baggage (binary never loaded them).
stage_libs Ghostship \
    libzip.so.5 \
    libtinyxml2.so.10
