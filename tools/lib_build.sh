# Shared dependency-build helpers for hm64-builder ports.
#
# Sourced by each port's build.txt. Provides:
#   project_clone   — clone the port repo (honors REPO_URL/REF/FORCE_HEAD), into $PROJECT_DIR
#   project_configure_and_build — cmake configure + GeneratePort target + main build
#   build_<dep>     — clone, configure, build, and `cmake --install` a common dep
#   stage_libs      — copy host libraries into $PROJECT_DIR/build/libs and verify NEEDED
#
# Conventions:
#   PROJECT_URL       (env, optional) — fork URL to clone; default: caller-provided
#   REF               (env, optional) — branch/tag/SHA to check out
#   FORCE_HEAD        (env, optional) — "true" to skip latest-tag fallback and stay on HEAD
#   PROJECT_DIR=/root/build-port/project
#   DEPS_DIR=/root/build-port/deps
#   PROJECT_BUILD_DIR=$PROJECT_DIR/build
#
# All helpers use absolute paths and never rely on the caller's cwd.

set -e

PROJECT_DIR=${PROJECT_DIR:-/root/build-port/project}
DEPS_DIR=${DEPS_DIR:-/root/build-port/deps}
PROJECT_BUILD_DIR=${PROJECT_BUILD_DIR:-$PROJECT_DIR/build}

mkdir -p "$DEPS_DIR"

# --------------------------------------------------------------------
# Project clone
# --------------------------------------------------------------------

# project_clone <default-url> [--recursive]
#   default-url   — fallback if REPO_URL is unset
#   --recursive   — pass --recursive to git clone (also init submodules recursively below)
project_clone() {
    local default_url=$1
    local clone_flags=""
    local sm_flags="--init"
    if [[ "${2:-}" == "--recursive" ]]; then
        clone_flags="--recursive"
        sm_flags="--init --recursive"
    fi

    local url=${REPO_URL:-$default_url}
    echo ">>> project_clone: $url -> $PROJECT_DIR"
    git clone $clone_flags "$url" "$PROJECT_DIR"

    git -C "$PROJECT_DIR" fetch --tags

    if [[ -n "${REF:-}" ]]; then
        echo ">>> project_clone: checking out explicit ref $REF"
        git -C "$PROJECT_DIR" checkout "$REF"
    elif [[ "${FORCE_HEAD:-false}" == "true" ]]; then
        echo ">>> project_clone: FORCE_HEAD=true, staying on default branch HEAD"
    else
        local latest_tag
        latest_tag=$(git -C "$PROJECT_DIR" describe --tags "$(git -C "$PROJECT_DIR" rev-list --tags --max-count=1)")
        echo ">>> project_clone: checking out latest tag $latest_tag"
        git -C "$PROJECT_DIR" checkout "$latest_tag"
    fi

    git -C "$PROJECT_DIR" submodule update $sm_flags
}

# --------------------------------------------------------------------
# Project build
# --------------------------------------------------------------------

# project_configure_and_build <generate-target> [extra cmake -D args...]
#   <generate-target>  — name of the asset-generation target (e.g. GenerateSohOtr,
#                        Generate2ShipOtr, GeneratePortO2R, GenerateO2R), or "" to skip
project_configure_and_build() {
    local gen_target=$1
    shift
    local cmake_args=("$@")

    # Pick clang-18 if available, else fall back to plain clang
    if command -v clang-18 >/dev/null 2>&1; then
        export CC=clang-18
        export CXX=clang++-18
    else
        export CC=clang
        export CXX=clang++
    fi

    echo ">>> project_configure_and_build: configuring"
    cmake -S "$PROJECT_DIR" -B "$PROJECT_BUILD_DIR" -GNinja "${cmake_args[@]}"

    if [[ -n "$gen_target" ]]; then
        echo ">>> project_configure_and_build: building asset target $gen_target"
        cmake --build "$PROJECT_BUILD_DIR" --target "$gen_target" -j"$(nproc)"
    fi

    echo ">>> project_configure_and_build: building main"
    cmake --build "$PROJECT_BUILD_DIR" -j"$(nproc)"
}

# --------------------------------------------------------------------
# Generic dep builder
# --------------------------------------------------------------------

# _build_dep <name> <git-url> <ref> [extra cmake -D args...]
#   Clones into $DEPS_DIR/<name>, checks out <ref>, configures into <name>/build,
#   builds, installs into /usr/local. Skips if already installed (idempotent across
#   re-runs of the same script).
_build_dep() {
    local name=$1 url=$2 ref=$3
    shift 3
    local extra_args=("$@")

    local src="$DEPS_DIR/$name"
    local build="$src/build"

    if [[ -d "$src/.git" ]]; then
        echo ">>> _build_dep $name: already cloned, skipping fetch"
    else
        echo ">>> _build_dep $name: cloning $url"
        git clone "$url" "$src"
    fi

    echo ">>> _build_dep $name: checking out $ref"
    git -C "$src" checkout "$ref"

    # We never run dep test suites in CI. Disable them by default; helpers can
    # still override per-project test names (json, opus, fmt, spdlog use their
    # own variable names instead of the standard BUILD_TESTING).
    echo ">>> _build_dep $name: configuring"
    cmake -S "$src" -B "$build" \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_TESTING=OFF \
        "${extra_args[@]}"

    echo ">>> _build_dep $name: building"
    cmake --build "$build" -j"$(nproc)"

    echo ">>> _build_dep $name: installing"
    cmake --install "$build"
}

# --------------------------------------------------------------------
# Common deps — pinned versions matching prior build.txt files.
# --------------------------------------------------------------------

build_sdl2() {
    _build_dep SDL https://github.com/libsdl-org/SDL.git release-2.32.0 \
        -DBUILD_SHARED_LIBS=ON \
        -DSDL_TEST=OFF \
        "$@"
}

build_sdl2_net() {
    _build_dep SDL_net https://github.com/libsdl-org/SDL_net.git release-2.2.0 \
        -DBUILD_SHARED_LIBS=ON "$@"
}

build_libzip() {
    _build_dep libzip https://github.com/nih-at/libzip.git \
        0581df510597b46c28509e9d4b5998cf5fecb636 \
        -DBUILD_TOOLS=OFF \
        -DBUILD_REGRESS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_DOC=OFF \
        "$@"
}

build_json() {
    _build_dep json https://github.com/nlohmann/json.git \
        f3dc4684b40a124cabc8554967c2cd8db54f15dd \
        -DJSON_BuildTests=OFF \
        "$@"
}

build_bzip2() {
    _build_dep bzip2 https://github.com/libarchive/bzip2.git \
        1ea1ac188ad4b9cb662e3f8314673c63df95a589 "$@"
}

# tinyxml2 has a wrinkle: after install, its cmake config file is renamed so that
# downstream find_package(tinyxml2) falls through to a different mechanism (some
# ports' libultraship pulls tinyxml2 differently and the installed config conflicts).
# This matches the historical behavior of every port's build.txt that uses tinyxml2.
build_tinyxml2() {
    _build_dep tinyxml2 https://github.com/leethomason/tinyxml2.git \
        57ec94127bda7979282315b7d4b0059eeb6f3b5d \
        -DBUILD_SHARED_LIBS=ON "$@"
    # `git checkout .` was historically run between the ref checkout and the build;
    # it's a no-op unless the working tree was dirty, which it never is here. Skipped.
    local cfg="$DEPS_DIR/tinyxml2/cmake/tinyxml2-config.cmake"
    if [[ -f "$cfg" ]]; then
        mv "$cfg" "$cfg.disabled"
    fi
}

build_opus() {
    _build_dep opus https://github.com/xiph/opus.git v1.5.2 \
        -DBUILD_SHARED_LIBS=ON \
        -DOPUS_BUILD_TESTING=OFF \
        "$@"
}

# opusfile uses autotools, not cmake — it predates the shared-cmake dep convention.
# Keep it as an inline helper so callers still write `build_opusfile`.
build_opusfile() {
    local src="$DEPS_DIR/opusfile"
    if [[ ! -d "$src/.git" ]]; then
        echo ">>> build_opusfile: cloning"
        git clone https://github.com/xiph/opusfile.git "$src"
    fi
    cd "$src"
    ./autogen.sh
    env -u LD PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
        ./configure --prefix=/usr/local \
            --disable-examples \
            --enable-shared --disable-static
    env -u LD make -j"$(nproc)"
    env -u LD make install
    cd - >/dev/null
}

build_fmt() {
    _build_dep fmt https://github.com/fmtlib/fmt.git 10.1.1 \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DFMT_TEST=OFF \
        -DFMT_DOC=OFF \
        "$@"
}

build_spdlog() {
    _build_dep spdlog https://github.com/gabime/spdlog.git \
        3335c380a08c5e0f5117a66622df6afdb3d74959 \
        -DSPDLOG_BUILD_TESTS=OFF \
        -DSPDLOG_BUILD_EXAMPLE=OFF \
        "$@"
}

build_gsl() {
    _build_dep GSL https://github.com/microsoft/GSL.git \
        2828399820ef4928cc89b65605dca5dc68efca6e \
        -DBUILD_SHARED_LIBS=ON \
        -DGSL_TEST=OFF \
        "$@"
}

# --------------------------------------------------------------------
# Library staging + verification
# --------------------------------------------------------------------

# stage_libs <binary-relative-to-PROJECT_BUILD_DIR> <lib1> [lib2 ...]
#   Each <libN> is either:
#     - "src=dest"  copy that absolute src to libs/<dest>
#     - "name"      shorthand: tries /usr/lib/aarch64-linux-gnu/<name>, then /usr/local/lib/<name>
#
#   After copying, runs readelf on <binary> and asserts that every staged lib appears in NEEDED,
#   and every staged lib file is present.
stage_libs() {
    local binary_rel=$1; shift
    local libs_dir="$PROJECT_BUILD_DIR/libs"
    local binary="$PROJECT_BUILD_DIR/$binary_rel"

    if [[ ! -f "$binary" ]]; then
        echo "stage_libs: ERROR: binary not found at $binary"
        exit 1
    fi

    mkdir -p "$libs_dir"

    local staged=()
    for entry in "$@"; do
        local src dest
        if [[ "$entry" == *"="* ]]; then
            src=${entry%%=*}
            dest=${entry#*=}
        else
            dest=$entry
            if [[ -f "/usr/lib/aarch64-linux-gnu/$entry" ]]; then
                src="/usr/lib/aarch64-linux-gnu/$entry"
            elif [[ -f "/usr/local/lib/$entry" ]]; then
                src="/usr/local/lib/$entry"
            else
                echo "stage_libs: ERROR: cannot locate $entry in /usr/lib/aarch64-linux-gnu or /usr/local/lib"
                exit 1
            fi
        fi
        cp -L "$src" "$libs_dir/$dest"
        staged+=("$dest")
    done

    local needed
    needed=$(readelf -d "$binary" | awk -F'[][]' '/NEEDED/ {print $2}')
    echo "Binary NEEDED:"; echo "$needed"
    echo "Staged:"; ls "$libs_dir"

    for lib in "${staged[@]}"; do
        if ! echo "$needed" | grep -qx "$lib"; then
            echo "ERROR: staged $lib but binary does not NEED it"; exit 1
        fi
        if [[ ! -f "$libs_dir/$lib" ]]; then
            echo "ERROR: $lib missing from libs/"; exit 1
        fi
    done
}
