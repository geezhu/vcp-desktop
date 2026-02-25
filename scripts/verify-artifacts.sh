#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/VERSION")"
TAR_PATH="${DIST_DIR}/vcpinstaller-v${VERSION}-linux-x64.tar.gz"
APPIMAGE_PATH="${DIST_DIR}/vcpinstaller-v${VERSION}-linux-x86_64.AppImage"
RUNTIME_MANIFEST_PATH="${DIST_DIR}/runtime-manifest-linux-x86_64.txt"
WORK_DIR="${ROOT_DIR}/.local-build-env/artifact-verify-$(date +%s)"

if [ ! -f "${TAR_PATH}" ]; then
  echo "Missing tar artifact: ${TAR_PATH}" >&2
  exit 1
fi

if [ ! -f "${APPIMAGE_PATH}" ]; then
  echo "Missing AppImage artifact: ${APPIMAGE_PATH}" >&2
  exit 1
fi

shopt -s nullglob
node_runtime_files=(${DIST_DIR}/node-runtime-*-linux-x86_64.tar.xz)
python_runtime_files=(${DIST_DIR}/python-runtime-*-linux-x86_64.tar.gz)
shopt -u nullglob

if [ "${#node_runtime_files[@]}" -lt 1 ]; then
  echo "Missing node runtime artifact in ${DIST_DIR}" >&2
  exit 1
fi

if [ "${#python_runtime_files[@]}" -lt 1 ]; then
  echo "Missing python runtime artifact in ${DIST_DIR}" >&2
  exit 1
fi

if [ ! -f "${RUNTIME_MANIFEST_PATH}" ]; then
  echo "Missing runtime manifest artifact: ${RUNTIME_MANIFEST_PATH}" >&2
  exit 1
fi

cd "${DIST_DIR}"
sha256sum -c SHA256SUMS

if [ -f "SHA256SUMS.sig" ] && [ -f "SHA256SUMS.pem" ]; then
  if command -v cosign >/dev/null 2>&1; then
    cosign verify-blob \
      --certificate "SHA256SUMS.pem" \
      --signature "SHA256SUMS.sig" \
      --certificate-identity-regexp "https://github.com/.+/.+/.github/workflows/release.yml@.+" \
      --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
      "SHA256SUMS"
  else
    echo "cosign not found; skipping SHA256SUMS.sig verification in local mode."
  fi
fi

mkdir -p "${WORK_DIR}/tar" "${WORK_DIR}/appimage"

tar -xzf "${TAR_PATH}" -C "${WORK_DIR}/tar"
chmod +x "${WORK_DIR}/tar/bin/vcp-installer"
tar_version="$("${WORK_DIR}/tar/bin/vcp-installer" --version)"
if [ "${tar_version}" != "${VERSION}" ]; then
  echo "tar.gz installer version mismatch: expected ${VERSION}, got ${tar_version}" >&2
  exit 1
fi
VCP_INSTALLER_STATE_DIR="${WORK_DIR}/tar-state" "${WORK_DIR}/tar/bin/vcp-installer" --cli --dry-run >/dev/null
if [ ! -f "${WORK_DIR}/tar/manifests/runtime-manifest-linux-x86_64.txt" ]; then
  echo "tar.gz package missing bundled runtime manifest" >&2
  exit 1
fi

(
  cd "${WORK_DIR}/appimage"
  "${APPIMAGE_PATH}" --appimage-extract >/dev/null
)
chmod +x "${WORK_DIR}/appimage/squashfs-root/usr/bin/vcp-installer"
appimage_version="$("${WORK_DIR}/appimage/squashfs-root/usr/bin/vcp-installer" --version)"
if [ "${appimage_version}" != "${VERSION}" ]; then
  echo "AppImage installer version mismatch: expected ${VERSION}, got ${appimage_version}" >&2
  exit 1
fi
VCP_INSTALLER_STATE_DIR="${WORK_DIR}/appimage-state" "${WORK_DIR}/appimage/squashfs-root/usr/bin/vcp-installer" --cli --dry-run >/dev/null
if [ ! -f "${WORK_DIR}/appimage/squashfs-root/usr/manifests/runtime-manifest-linux-x86_64.txt" ]; then
  echo "AppImage package missing bundled runtime manifest" >&2
  exit 1
fi

echo "Artifact verification passed."
echo "Workspace: ${WORK_DIR}"
