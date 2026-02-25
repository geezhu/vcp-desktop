#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/VERSION")"
TAG="v${VERSION}"
TAR_NAME="vcpinstaller-${TAG}-linux-x64.tar.gz"

mkdir -p "${DIST_DIR}"

cd "${ROOT_DIR}"
tar -czf "${DIST_DIR}/${TAR_NAME}" \
  VERSION \
  CHANGELOG.md \
  README.md \
  docs/*.md \
  manifests/*.txt \
  bin/vcp-installer \
  scripts/*.sh

"${ROOT_DIR}/scripts/update-sha256sums.sh"

echo "Generated tarball: ${DIST_DIR}/${TAR_NAME}"
ls -lh "${DIST_DIR}/${TAR_NAME}" "${DIST_DIR}/SHA256SUMS"
