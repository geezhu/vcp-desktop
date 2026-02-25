#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${ROOT_DIR}/bin/vcp-installer"
WORK_DIR="${ROOT_DIR}/.local-build-env/runtime-regression-$(date +%s)"
HOME_DIR="${WORK_DIR}/home"
STATE_DIR="${WORK_DIR}/state"
ASSET_DIR="${WORK_DIR}/assets"
WS_DIR="${WORK_DIR}/workspace"
MANIFEST_GOOD="${WORK_DIR}/manifest-good.txt"
MANIFEST_ACTIVE="${WORK_DIR}/manifest-active.txt"

mkdir -p "${HOME_DIR}" "${STATE_DIR}" "${ASSET_DIR}/node/bin" "${ASSET_DIR}/python/bin" "${WS_DIR}/backend" "${WS_DIR}/chat"

cat > "${ASSET_DIR}/node/bin/node" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
echo "v20.88.0-regression"
SCRIPT
chmod +x "${ASSET_DIR}/node/bin/node"

cat > "${ASSET_DIR}/python/bin/python3" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
echo "Python 3.11.88-regression"
SCRIPT
chmod +x "${ASSET_DIR}/python/bin/python3"

tar -cJf "${ASSET_DIR}/node-runtime.tar.xz" -C "${ASSET_DIR}/node" .
tar -cJf "${ASSET_DIR}/python-runtime.tar.xz" -C "${ASSET_DIR}/python" .

node_sha="$(sha256sum "${ASSET_DIR}/node-runtime.tar.xz" | awk '{print $1}')"
python_sha="$(sha256sum "${ASSET_DIR}/python-runtime.tar.xz" | awk '{print $1}')"

cat > "${WS_DIR}/backend/start-backend.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
node --version >/dev/null
sleep 5
SCRIPT
chmod +x "${WS_DIR}/backend/start-backend.sh"

cat > "${WS_DIR}/chat/start-chat.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
python3 --version >/dev/null
sleep 5
SCRIPT
chmod +x "${WS_DIR}/chat/start-chat.sh"

cat > "${MANIFEST_GOOD}" <<EOF_MANIFEST
manifest_version|1
artifact|node|20.88.0|linux-x86_64|http://127.0.0.1:9/node-runtime.tar.xz|file://${ASSET_DIR}/node-runtime.tar.xz|${node_sha}|-
artifact|python|3.11.88|linux-x86_64|http://127.0.0.1:9/python-runtime.tar.xz|file://${ASSET_DIR}/python-runtime.tar.xz|${python_sha}|-
EOF_MANIFEST

cp "${MANIFEST_GOOD}" "${MANIFEST_ACTIVE}"

VCP_INSTALLER_HOME="${HOME_DIR}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" init --cli --yes --no-start-after-init \
  --runtime-mode portable \
  --runtime-manifest "${MANIFEST_ACTIVE}" \
  --workspace-root "${WS_DIR}" \
  --backend-cwd "${WS_DIR}/backend" \
  --backend-cmd "./start-backend.sh" \
  --chat-cwd "${WS_DIR}/chat" \
  --chat-cmd "./start-chat.sh" \
  --startup-delay 0 >/dev/null

if [ ! -x "${HOME_DIR}/runtime/bin/vcp-runtime-exec" ]; then
  echo "Regression check failed: runtime wrapper missing after mirror fallback init" >&2
  exit 1
fi

VCP_INSTALLER_HOME="${HOME_DIR}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" reset --reset-runtime >/dev/null

cat > "${MANIFEST_ACTIVE}" <<'EOF_MANIFEST'
manifest_version|1
artifact|node|20.88.0|linux-x86_64|http://127.0.0.1:9/node-runtime.tar.xz|-|aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa|-
artifact|python|3.11.88|linux-x86_64|http://127.0.0.1:9/python-runtime.tar.xz|-|bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb|-
EOF_MANIFEST

set +e
VCP_INSTALLER_HOME="${HOME_DIR}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" init --cli --yes --no-start-after-init \
  --runtime-mode portable \
  --runtime-manifest "${MANIFEST_ACTIVE}" \
  --workspace-root "${WS_DIR}" \
  --backend-cwd "${WS_DIR}/backend" \
  --backend-cmd "./start-backend.sh" \
  --chat-cwd "${WS_DIR}/chat" \
  --chat-cmd "./start-chat.sh" \
  --startup-delay 0 >/dev/null 2>&1
fail_rc=$?
set -e

if [ "${fail_rc}" -eq 0 ]; then
  echo "Regression check failed: expected offline init failure" >&2
  exit 1
fi

cp "${MANIFEST_GOOD}" "${MANIFEST_ACTIVE}"

VCP_INSTALLER_HOME="${HOME_DIR}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" resume --cli --yes --no-start-after-init >/dev/null

if [ ! -x "${HOME_DIR}/runtime/bin/vcp-runtime-exec" ]; then
  echo "Regression check failed: runtime wrapper missing after resume" >&2
  exit 1
fi

echo "Runtime regression checks passed."
echo "Workspace: ${WORK_DIR}"
