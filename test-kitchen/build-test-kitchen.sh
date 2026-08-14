#!/bin/bash
set -euo pipefail

# Build an arm64 / Apple-silicon image of the Wikimedia `test-kitchen` service.
#
# set TK_REF to pin a branch, tag, or commit of the service source.
# Default is the upstream default branch (tracks the `latest-dev` image).

export DOCKER_BUILDKIT=1

REGISTRY=docker-registry.wikimedia.org
TK_REPO="https://gitlab.wikimedia.org/repos/data-engineering/test-kitchen.git"
TK_REF="${TK_REF:-}"                    # optional pin (branch/tag/commit)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/src"             # gitignored clone of the service source
BASE_WMF="${REGISTRY}/nodejs22-slim"    # amd64-only WMF base (the root cause)
BASE_ARM="node:22-slim"                 # multi-arch base that replaces it
tkImg="${REGISTRY}/repos/data-engineering/test-kitchen"
tkTag="latest-dev-arm1"

## Clone or update the service source
if [ -d "${SRC_DIR}/.git" ]; then
    echo "Updating test-kitchen source in ${SRC_DIR}"
    git -C "${SRC_DIR}" fetch --depth 1 origin "${TK_REF:-HEAD}"
    git -C "${SRC_DIR}" checkout -f FETCH_HEAD
elif [ -n "${TK_REF}" ]; then
    echo "Cloning test-kitchen source (ref ${TK_REF}) into ${SRC_DIR}"
    git clone --depth 1 --branch "${TK_REF}" "${TK_REPO}" "${SRC_DIR}"
else
    echo "Cloning test-kitchen source into ${SRC_DIR}"
    git clone --depth 1 "${TK_REPO}" "${SRC_DIR}"
fi

## Submodules are required (upstream CI uses GIT_SUBMODULE_STRATEGY: normal)
git -C "${SRC_DIR}" submodule update --init --depth 1

echo "Building from test-kitchen commit $(git -C "${SRC_DIR}" rev-parse --short HEAD)"

## Make the arm Blubber config: upstream config with the base swapped
ARM_YAML="${SRC_DIR}/.pipeline/blubber.arm.yaml"
sed "s#${BASE_WMF}#${BASE_ARM}#g" \
    "${SRC_DIR}/.pipeline/blubber.yaml" > "${ARM_YAML}"
if ! grep -q "${BASE_ARM}" "${ARM_YAML}"; then
    echo "WARNING: base ${BASE_WMF} not found in upstream blubber.yaml." \
         "The upstream base may have changed. Check ${ARM_YAML} before use." >&2
fi

## Remove old image (silently ignore if it does not exist)
docker rmi "${tkImg}:${tkTag}" 2>/dev/null || true

## Build the native arm64 development image
echo "Building arm64 test-kitchen image ${tkImg}:${tkTag}"
docker build --platform=linux/arm64 --target development \
    -f "${ARM_YAML}" -t "${tkImg}:${tkTag}" "${SRC_DIR}"

echo "Done. Built $(docker image inspect "${tkImg}:${tkTag}" \
    --format '{{.Architecture}}') image ${tkImg}:${tkTag}"
