#!/bin/bash
# Shared docker setup. Pulls the base image declared by tools/Dockerfile,
# builds an aarch64 image tagged $NAME, and starts the container.
#
# Usage: docker_setup.sh <name> <dockerfile-dir>
#   <name>            — image + container name (e.g. soh-build)
#   <dockerfile-dir>  — directory containing the Dockerfile to build with
#                       (typically the build-port working dir, which holds the
#                       shared Dockerfile copied in by tools/build_port.sh)

set -e

NAME=$1
DOCKERFILE_DIR=${2:-.}
ARCH=aarch64

RELEASE=$(grep '^FROM ' "$DOCKERFILE_DIR/Dockerfile" | awk '{print $2}')

docker pull --platform linux/${ARCH} "${RELEASE}"
docker build --platform linux/${ARCH} -t "${NAME}" "${DOCKERFILE_DIR}"

if tty -s; then
    # Interactive — open a shell.
    echo INTERACTIVE
    docker run -it -v "$(realpath ..)":/root --name="${NAME}" --hostname="${NAME}" \
        "${NAME}"
else
    # Non-interactive (CI) — start the container detached and idle.
    echo NONINTERACTIVE
    docker run -v "$(realpath ..)":/root --name="${NAME}" --hostname="${NAME}" \
        "${NAME}" /bin/bash -c "sleep infinity" &
fi
