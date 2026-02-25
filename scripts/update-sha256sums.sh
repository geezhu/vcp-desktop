#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
mkdir -p "${DIST_DIR}"

cd "${DIST_DIR}"
shopt -s nullglob
artifacts=(
  vcpinstaller-*.tar.gz
  vcpinstaller-*.AppImage
  node-runtime-*.tar.xz
  python-runtime-*.tar.gz
  runtime-manifest-*.txt
)

if [ "${#artifacts[@]}" -eq 0 ]; then
  echo "No artifacts found in ${DIST_DIR}" >&2
  exit 1
fi

sha256sum "${artifacts[@]}" > SHA256SUMS
echo "Generated ${DIST_DIR}/SHA256SUMS for ${#artifacts[@]} artifact(s)."
