#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
BUILD_DIR="${ROOT_DIR}/build"
APPDIR="${BUILD_DIR}/AppDir"
TOOLS_DIR="${ROOT_DIR}/.local-build-env/tools"
VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/VERSION")"
APPIMAGE_NAME="vcpinstaller-v${VERSION}-linux-x86_64.AppImage"
APPIMAGETOOL="${TOOLS_DIR}/appimagetool-x86_64.AppImage"
APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"

mkdir -p "${DIST_DIR}" "${TOOLS_DIR}"

if [ ! -x "${APPIMAGETOOL}" ]; then
  echo "Downloading appimagetool to ${APPIMAGETOOL}"
  curl -L -o "${APPIMAGETOOL}" "${APPIMAGETOOL_URL}"
  chmod +x "${APPIMAGETOOL}"
fi

rm -rf "${APPDIR}"
mkdir -p "${APPDIR}/usr/bin" "${APPDIR}/usr/share/vcp-installer" "${APPDIR}/usr/manifests"

install -m 755 "${ROOT_DIR}/bin/vcp-installer" "${APPDIR}/usr/bin/vcp-installer"
install -m 644 "${ROOT_DIR}/VERSION" "${APPDIR}/usr/share/vcp-installer/VERSION"
if compgen -G "${ROOT_DIR}/manifests/*.txt" > /dev/null; then
  install -m 644 "${ROOT_DIR}"/manifests/*.txt "${APPDIR}/usr/manifests/"
fi

cat > "${APPDIR}/AppRun" <<'EOF'
#!/usr/bin/env bash
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SELF_DIR}/usr/bin/vcp-installer" --gui "$@"
EOF
chmod +x "${APPDIR}/AppRun"

cat > "${APPDIR}/vcp-installer.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=VCP Installer GUI
Exec=vcp-installer --gui
Icon=vcp-installer
Categories=Utility;Development;
Terminal=true
EOF

cat > "${APPDIR}/vcp-installer.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect width="256" height="256" rx="24" fill="#1f6feb"/>
  <rect x="56" y="52" width="144" height="152" rx="12" fill="#ffffff"/>
  <rect x="76" y="78" width="104" height="12" fill="#1f6feb"/>
  <rect x="76" y="102" width="104" height="12" fill="#1f6feb"/>
  <rect x="76" y="126" width="70" height="12" fill="#1f6feb"/>
  <path d="M154 150l12 12 26-26" stroke="#1f6feb" stroke-width="10" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
EOF

ln -snf vcp-installer.svg "${APPDIR}/.DirIcon"

ARCH=x86_64 "${APPIMAGETOOL}" --appimage-extract-and-run "${APPDIR}" "${DIST_DIR}/${APPIMAGE_NAME}"

"${ROOT_DIR}/scripts/update-sha256sums.sh"

echo "Generated AppImage: ${DIST_DIR}/${APPIMAGE_NAME}"
ls -lh "${DIST_DIR}/${APPIMAGE_NAME}" "${DIST_DIR}/SHA256SUMS"
