#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${ROOT_DIR}/bin/vcp-installer"
STATE_DIR="${ROOT_DIR}/.local-build-env/smoke-state"
TMP_DIR="${ROOT_DIR}/.local-build-env/smoke-tmp"
RUNTIME_DIR="${ROOT_DIR}/.local-build-env/smoke-runtime"
INSTALLER_HOME="${ROOT_DIR}/.local-build-env/smoke-home"

if [ ! -x "${INSTALLER}" ]; then
  echo "Installer is not executable: ${INSTALLER}" >&2
  exit 1
fi

rm -rf "${STATE_DIR}" "${TMP_DIR}" "${RUNTIME_DIR}" "${INSTALLER_HOME}"
mkdir -p "${STATE_DIR}" "${TMP_DIR}" "${RUNTIME_DIR}/backend" "${RUNTIME_DIR}/chat"

cat > "${RUNTIME_DIR}/backend/start-backend.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sleep 120
EOF
chmod +x "${RUNTIME_DIR}/backend/start-backend.sh"

cat > "${RUNTIME_DIR}/chat/start-chat.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sleep 120
EOF
chmod +x "${RUNTIME_DIR}/chat/start-chat.sh"

"${INSTALLER}" --help >/dev/null
expected_version="$(tr -d '[:space:]' < "${ROOT_DIR}/VERSION")"
actual_version="$("${INSTALLER}" --version)"
if [ "${actual_version}" != "${expected_version}" ]; then
  echo "Installer version mismatch: expected ${expected_version}, got ${actual_version}" >&2
  exit 1
fi
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" "${INSTALLER}" --cli --dry-run > "${TMP_DIR}/cli.log"
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" "${INSTALLER}" resume --cli --dry-run > "${TMP_DIR}/resume.log"

set +e
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" "${INSTALLER}" --headless --dry-run --simulate-gui-step > "${TMP_DIR}/headless.log" 2>&1
headless_rc=$?
set -e

if [ "${headless_rc}" -ne 30 ]; then
  echo "Expected headless GUI-required exit code 30, got ${headless_rc}" >&2
  cat "${TMP_DIR}/headless.log" >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  if ! rg -q "GUI_REQUIRED" "${TMP_DIR}/headless.log"; then
    echo "Expected GUI_REQUIRED marker not found in headless log" >&2
    cat "${TMP_DIR}/headless.log" >&2
    exit 1
  fi
else
  if ! grep -q "GUI_REQUIRED" "${TMP_DIR}/headless.log"; then
    echo "Expected GUI_REQUIRED marker not found in headless log" >&2
    cat "${TMP_DIR}/headless.log" >&2
    exit 1
  fi
fi

set +e
VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" --headless > "${TMP_DIR}/headless-init-required.log" 2>&1
headless_init_rc=$?
set -e

if [ "${headless_init_rc}" -ne 31 ]; then
  echo "Expected headless init-required exit code 31, got ${headless_init_rc}" >&2
  cat "${TMP_DIR}/headless-init-required.log" >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  if ! rg -q "INIT_REQUIRED" "${TMP_DIR}/headless-init-required.log"; then
    echo "Expected INIT_REQUIRED marker not found in headless init log" >&2
    cat "${TMP_DIR}/headless-init-required.log" >&2
    exit 1
  fi
else
  if ! grep -q "INIT_REQUIRED" "${TMP_DIR}/headless-init-required.log"; then
    echo "Expected INIT_REQUIRED marker not found in headless init log" >&2
    cat "${TMP_DIR}/headless-init-required.log" >&2
    exit 1
  fi
fi

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" --cli --yes \
  --workspace-root "${RUNTIME_DIR}" \
  --backend-cwd "${RUNTIME_DIR}/backend" \
  --backend-cmd "./start-backend.sh" \
  --chat-cwd "${RUNTIME_DIR}/chat" \
  --chat-cmd "./start-chat.sh" \
  --startup-delay 0 > "${TMP_DIR}/auto-first-run.log"

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" status > "${TMP_DIR}/status-running.log"

if command -v rg >/dev/null 2>&1; then
  rg -q "backend: RUNNING" "${TMP_DIR}/status-running.log"
  rg -q "chat: RUNNING" "${TMP_DIR}/status-running.log"
else
  grep -q "backend: RUNNING" "${TMP_DIR}/status-running.log"
  grep -q "chat: RUNNING" "${TMP_DIR}/status-running.log"
fi

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" stop > "${TMP_DIR}/stop.log"

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" status > "${TMP_DIR}/status-stopped.log"

if command -v rg >/dev/null 2>&1; then
  rg -q "backend: STOPPED" "${TMP_DIR}/status-stopped.log"
  rg -q "chat: STOPPED" "${TMP_DIR}/status-stopped.log"
else
  grep -q "backend: STOPPED" "${TMP_DIR}/status-stopped.log"
  grep -q "chat: STOPPED" "${TMP_DIR}/status-stopped.log"
fi

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" > "${TMP_DIR}/auto-second-run.log"

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" status > "${TMP_DIR}/status-running-second.log"

if command -v rg >/dev/null 2>&1; then
  rg -q "backend: RUNNING" "${TMP_DIR}/status-running-second.log"
  rg -q "chat: RUNNING" "${TMP_DIR}/status-running-second.log"
else
  grep -q "backend: RUNNING" "${TMP_DIR}/status-running-second.log"
  grep -q "chat: RUNNING" "${TMP_DIR}/status-running-second.log"
fi

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" stop > "${TMP_DIR}/stop-second.log"

echo "Smoke test passed."
echo "Logs:"
ls -lh "${TMP_DIR}"
