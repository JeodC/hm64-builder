#!/bin/bash
# Orchestrate a port build.
#
# Usage: build_port.sh <port-name>
#
# <port-name> must match a recipe at builds/<port-name>.sh and is also the
# name of the assembly directory created at the repo root, which becomes the
# top-level directory in the released zip (e.g. "soh", "sm64-ghostship").
#
# Honors env vars: FORCE_HEAD, REPO_URL, REF (forwarded into the container).

set -e

HOSTROOT=`pwd`
DOCKERROOT=/root

PORTNAME=$1
BUILDSCRIPT=$HOSTROOT/builds/$PORTNAME.sh
SETUPSCRIPT=$HOSTROOT/tools/docker_setup.sh
PRODUCTSCRIPT=$HOSTROOT/tools/retrieve_products.sh
DOCKERFILE=$HOSTROOT/tools/Dockerfile

chmod +x "$SETUPSCRIPT" "$PRODUCTSCRIPT" 2>/dev/null || true

BUILDDIR=build-port            # transient docker build context
ASSEMBLYDIR=$HOSTROOT/$PORTNAME # zip top-level dir (created fresh each build)

if [[ -z "$PORTNAME" ]]; then
    echo "build_port.sh: ERROR: port name required"
    exit 1
fi
if [[ ! -f "$BUILDSCRIPT" ]]; then
    echo "build_port.sh: ERROR: $BUILDSCRIPT not found"
    exit 1
fi

# Fresh assembly dir for retrieve_products to populate, and a fresh build
# context for docker.
rm -rf "$ASSEMBLYDIR" "$HOSTROOT/$BUILDDIR"
mkdir -p "$ASSEMBLYDIR" "$HOSTROOT/$BUILDDIR"

cd $HOSTROOT/$BUILDDIR

# Stage the port's build script and the shared Dockerfile that docker_setup.sh
# will build from.
cp $BUILDSCRIPT ./build.sh
cp $DOCKERFILE .

bash $SETUPSCRIPT $PORTNAME-build .

sleep 5

docker exec \
  -e FORCE_HEAD=${FORCE_HEAD:-false} \
  -e REPO_URL="${REPO_URL:-}" \
  -e REF="${REF:-}" \
  -e BUILD_ANCHOR="${BUILD_ANCHOR:-}" \
  -e BUILD_TYPE="${BUILD_TYPE:-}" \
  $PORTNAME-build /bin/bash -c "cd $BUILDDIR && bash $DOCKERROOT/$BUILDDIR/build.sh"

bash $PRODUCTSCRIPT $PORTNAME $HOSTROOT/$BUILDDIR $ASSEMBLYDIR