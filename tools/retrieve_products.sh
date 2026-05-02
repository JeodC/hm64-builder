#!/bin/bash
# Shared product-retrieval dispatcher (host-side).
#
# Usage: retrieve_products.sh <port-name> <SRCDIR> <DESTDIR>
#
# Each per-port retrieve-products.txt is a one-line wrapper that execs this
# script with its port name. Per-port quirks live in the case arms below.

set -e

# Locate lib_retrieve.sh next to this script (same tools/ dir).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_retrieve.sh"

PORT=$1
shift

retrieve_init "$1" "$2"

case "$PORT" in
    soh)
        copy_binary soh/soh.elf
        copy_o2r soh/soh.o2r
        replace_libs
        package_soh_extractor_zip soh/assets/extractor soh/assets/xml
        ;;

    soh2)
        # 2s2h ships every elf in build/mm/ (multiple binaries: 2s2h.elf, mods, etc.)
        for elf_file in "$PROJECT_BUILD/mm/"*.elf; do
            cp "$elf_file" "$DESTDIR/"
        done
        copy_o2r mm/2ship.o2r
        replace_libs
        package_2ship_extractor_zip mm/assets/extractor mm/assets/xml ZAPD/ZAPD.out
        ;;

    starship)
        copy_binary Starship
        copy_o2r starship.o2r
        copy_extra gamecontrollerdb.txt
        replace_libs
        package_torch_assets assets/
        ;;

    spaghettikart)
        copy_binary Spaghettify
        copy_binary Spaghettify.pdb
        copy_o2r spaghetti.o2r
        # SpaghettiKart's build doesn't produce gamecontrollerdb.txt; fetch upstream.
        wget -O "$DESTDIR/gamecontrollerdb.txt" \
            "https://raw.githubusercontent.com/mdqinc/SDL_GameControllerDB/master/gamecontrollerdb.txt"
        replace_libs
        package_torch_assets yamls/ meta/ include/
        ;;

    sm64-ghostship|ghostship)
        copy_binary Ghostship
        copy_o2r ghostship.o2r
        copy_extra gamecontrollerdb.txt
        replace_libs
        package_torch_assets assets/
        ;;

    paperboat)
        copy_binary Paperboat
        copy_o2r paperboat.o2r
        copy_extra gamecontrollerdb.txt
        replace_libs
        package_torch_assets assets/
        ;;

    *)
        echo "retrieve_products.sh: unknown port '$PORT'"
        exit 1
        ;;
esac

echo "Packaging complete. You will also need to update otrgen by hand."
