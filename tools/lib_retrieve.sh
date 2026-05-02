# Shared product-retrieval helpers for hm64-builder ports.
#
# Sourced by each port's retrieve-products.txt. Provides:
#   retrieve_init       — set up SRCDIR/DESTDIR/PROJECT_BUILD/PROJECT_SRC
#   copy_binary         — copy the main port binary
#   copy_o2r            — copy the generated .o2r
#   copy_extra          — copy any extra files from build dir (e.g. gamecontrollerdb.txt)
#   replace_libs        — replace DESTDIR/libs with the staged libs/ dir
#   package_extractor_zip  — SoH-style: zip extractor + xml + ZAPD into assets/extractor.zip
#   package_torch_assets   — Torch-style: copy torch binary + config.yml + asset zip
#   strip_gitkeep       — clean up .gitkeep files in DESTDIR
#
# Conventions: input paths come from the build script via $1 ($SRCDIR), $2 ($DESTDIR).
# After the layout normalization, project lives at $SRCDIR/project, build at $SRCDIR/project/build.

set -e

# --------------------------------------------------------------------
# retrieve_init <SRCDIR> <DESTDIR>
#
# Sets globals: SRCDIR, DESTDIR, PROJECT_SRC, PROJECT_BUILD.
# `cd`s into DESTDIR (matches historical behavior of every retrieve-products.txt).
# --------------------------------------------------------------------
retrieve_init() {
    SRCDIR=$1
    DESTDIR=$2
    PROJECT_SRC="$SRCDIR/project"
    PROJECT_BUILD="$PROJECT_SRC/build"

    if [[ -z "$DESTDIR" || ! -d "$DESTDIR" ]]; then
        echo "retrieve_init: DESTDIR not found: $DESTDIR"
        exit 1
    fi
    cd "$DESTDIR"
}

# --------------------------------------------------------------------
# copy_binary <build-relative-path>
#
# Copies a single file from $PROJECT_BUILD/<rel> to $DESTDIR/<basename>.
# The release zip layout has the binary at $DESTDIR/<basename> (e.g. soh.elf,
# Starship), not at the build-tree subpath where cmake produces it.
#
# Example: copy_binary soh/soh.elf  → cp $PROJECT_BUILD/soh/soh.elf $DESTDIR/soh.elf
#          copy_binary Starship     → cp $PROJECT_BUILD/Starship    $DESTDIR/Starship
# --------------------------------------------------------------------
copy_binary() {
    local rel=$1
    local src="$PROJECT_BUILD/$rel"
    if [[ ! -f "$src" ]]; then
        echo "copy_binary: ERROR: $src not found"
        exit 1
    fi
    cp "$src" "$DESTDIR/"
}

# --------------------------------------------------------------------
# copy_o2r <build-relative-path>
# Same shape as copy_binary; warns (does not error) if absent.
# --------------------------------------------------------------------
copy_o2r() {
    local rel=$1
    local src="$PROJECT_BUILD/$rel"
    if [[ -f "$src" ]]; then
        cp "$src" "$DESTDIR/"
    else
        echo "copy_o2r: WARNING: no .o2r at $src"
    fi
}

# --------------------------------------------------------------------
# copy_extra <build-relative-path> [<dest-name>]
# Copy a single extra file from the build dir to DESTDIR. Optional rename.
# --------------------------------------------------------------------
copy_extra() {
    local rel=$1
    local dest=${2:-$(basename "$rel")}
    local src="$PROJECT_BUILD/$rel"
    if [[ ! -f "$src" ]]; then
        echo "copy_extra: ERROR: $src not found"
        exit 1
    fi
    cp "$src" "$DESTDIR/$dest"
}

# --------------------------------------------------------------------
# replace_libs
# Wipe DESTDIR/libs and replace with PROJECT_BUILD/libs.
# --------------------------------------------------------------------
replace_libs() {
    rm -rf "$DESTDIR/libs"
    cp -r "$PROJECT_BUILD/libs" "$DESTDIR/"
}

# --------------------------------------------------------------------
# package_soh_extractor_zip <extractor-src-rel> <xml-src-rel>
#
# SoH-style extractor.zip: contents of <extractor-src> at the zip root +
# the <xml-src> directory itself. No ZAPD inside.
#
# Example: package_soh_extractor_zip soh/assets/extractor soh/assets/xml
# --------------------------------------------------------------------
package_soh_extractor_zip() {
    local extractor_rel=$1 xml_rel=$2
    local extractor_src="$PROJECT_SRC/$extractor_rel"
    local xml_src="$PROJECT_SRC/$xml_rel"

    if [[ ! -d "$extractor_src" || ! -d "$xml_src" ]]; then
        echo "package_soh_extractor_zip: WARNING: extractor or xml dir missing, skipping"
        return 0
    fi

    local stage="$DESTDIR/assets/tmp_zip"
    mkdir -p "$DESTDIR/assets"
    rm -rf "$stage"
    mkdir -p "$stage"

    cp -r "$extractor_src/." "$stage/"
    cp -r "$xml_src" "$stage/"

    (cd "$stage" && zip -r "$DESTDIR/assets/extractor.zip" ./*)
    rm -rf "$stage"
}

# --------------------------------------------------------------------
# package_2ship_extractor_zip <extractor-src-rel> <xml-src-rel> <zapd-build-rel>
#
# 2ship-style extractor.zip: extractor/ subdirectory containing ZAPD.out and
# the contents of <extractor-src>, plus the <xml-src> directory itself at the
# zip root.
#
# Example: package_2ship_extractor_zip mm/assets/extractor mm/assets/xml ZAPD/ZAPD.out
# --------------------------------------------------------------------
package_2ship_extractor_zip() {
    local extractor_rel=$1 xml_rel=$2 zapd_rel=$3
    local extractor_src="$PROJECT_SRC/$extractor_rel"
    local xml_src="$PROJECT_SRC/$xml_rel"
    local zapd_bin="$PROJECT_BUILD/$zapd_rel"

    if [[ ! -d "$extractor_src" || ! -d "$xml_src" ]]; then
        echo "package_2ship_extractor_zip: WARNING: extractor or xml dir missing, skipping"
        return 0
    fi

    local stage="$DESTDIR/assets/tmp_zip"
    mkdir -p "$DESTDIR/assets"
    rm -rf "$stage"
    mkdir -p "$stage/extractor"

    if [[ -f "$zapd_bin" ]]; then
        cp "$zapd_bin" "$stage/extractor/ZAPD.out"
    else
        echo "package_2ship_extractor_zip: WARNING: ZAPD not found at $zapd_bin"
    fi
    cp -r "$extractor_src"/* "$stage/extractor/"
    cp -r "$xml_src" "$stage/"

    (cd "$stage" && zip -r "$DESTDIR/assets/extractor.zip" ./*)
    rm -rf "$stage"
}

# --------------------------------------------------------------------
# package_torch_assets <project-asset-dirs...>
#
# Torch-style: stage tools/torch + tools/config.yml, package one or more project
# asset folders into tools/assets.zip.
#
# Example (starship):           package_torch_assets assets/
# Example (spaghettikart):      package_torch_assets yamls/ meta/ include/
# --------------------------------------------------------------------
package_torch_assets() {
    mkdir -p "$DESTDIR/tools"

    local torch_bin="$PROJECT_BUILD/TorchExternal/src/TorchExternal-build/torch"
    if [[ -f "$torch_bin" ]]; then
        cp "$torch_bin" "$DESTDIR/tools/torch"
    else
        echo "package_torch_assets: WARNING: torch binary not found at $torch_bin"
    fi

    rm -rf "$DESTDIR/tools/assets" "$DESTDIR/tools/yamls"
    rm -f  "$DESTDIR/tools/config.yml"

    if [[ -f "$PROJECT_SRC/config.yml" ]]; then
        cp "$PROJECT_SRC/config.yml" "$DESTDIR/tools/"
    fi

    (cd "$PROJECT_SRC" && zip -r "$DESTDIR/tools/assets.zip" "$@")
}

