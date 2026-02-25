#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${ROOT_DIR}/bin/vcp-installer"
STATE_DIR="${ROOT_DIR}/.local-build-env/smoke-state"
HEADLESS_INIT_HOME="${ROOT_DIR}/.local-build-env/smoke-headless-init-home"
HEADLESS_INIT_STATE="${ROOT_DIR}/.local-build-env/smoke-headless-init-state"
TMP_DIR="${ROOT_DIR}/.local-build-env/smoke-tmp"
RUNTIME_DIR="${ROOT_DIR}/.local-build-env/smoke-runtime"
RUNTIME_ASSETS_DIR="${ROOT_DIR}/.local-build-env/smoke-runtime-assets"
RUNTIME_WORKSPACE="${ROOT_DIR}/.local-build-env/smoke-runtime-workspace"
INSTALLER_HOME="${ROOT_DIR}/.local-build-env/smoke-home"
INSTALL_WORKSPACE="${ROOT_DIR}/.local-build-env/smoke-install-workspace"

if [ ! -x "${INSTALLER}" ]; then
  echo "Installer is not executable: ${INSTALLER}" >&2
  exit 1
fi

rm -rf \
  "${STATE_DIR}" \
  "${TMP_DIR}" \
  "${RUNTIME_DIR}" \
  "${RUNTIME_ASSETS_DIR}" \
  "${RUNTIME_WORKSPACE}" \
  "${HEADLESS_INIT_HOME}" \
  "${HEADLESS_INIT_STATE}" \
  "${INSTALLER_HOME}" \
  "${INSTALL_WORKSPACE}"
mkdir -p \
  "${STATE_DIR}" \
  "${TMP_DIR}" \
  "${RUNTIME_DIR}/backend" \
  "${RUNTIME_DIR}/chat" \
  "${RUNTIME_ASSETS_DIR}" \
  "${RUNTIME_WORKSPACE}/backend" \
  "${RUNTIME_WORKSPACE}/chat" \
  "${HEADLESS_INIT_HOME}" \
  "${HEADLESS_INIT_STATE}"

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

mkdir -p "${RUNTIME_ASSETS_DIR}/node/bin" "${RUNTIME_ASSETS_DIR}/python/bin"
cat > "${RUNTIME_ASSETS_DIR}/node/bin/node" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "v20.99.0-smoke"
EOF
chmod +x "${RUNTIME_ASSETS_DIR}/node/bin/node"

cat > "${RUNTIME_ASSETS_DIR}/python/bin/python3" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Python 3.11.99-smoke"
EOF
chmod +x "${RUNTIME_ASSETS_DIR}/python/bin/python3"

tar -cJf "${RUNTIME_ASSETS_DIR}/node-runtime.tar.xz" -C "${RUNTIME_ASSETS_DIR}/node" .
tar -cJf "${RUNTIME_ASSETS_DIR}/python-runtime.tar.xz" -C "${RUNTIME_ASSETS_DIR}/python" .

node_sha="$(sha256sum "${RUNTIME_ASSETS_DIR}/node-runtime.tar.xz" | awk '{print $1}')"
python_sha="$(sha256sum "${RUNTIME_ASSETS_DIR}/python-runtime.tar.xz" | awk '{print $1}')"
bad_python_sha="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
manifest_active="${TMP_DIR}/runtime-manifest-active.txt"
cat > "${manifest_active}" <<EOF
manifest_version|1
artifact|node|20.99.0|linux-x86_64|file://${RUNTIME_ASSETS_DIR}/node-runtime.tar.xz|-|${node_sha}|-
artifact|python|3.11.99|linux-x86_64|file://${RUNTIME_ASSETS_DIR}/python-runtime.tar.xz|-|${bad_python_sha}|-
EOF

cat > "${RUNTIME_WORKSPACE}/backend/start-backend.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
node --version >/dev/null
sleep 120
EOF
chmod +x "${RUNTIME_WORKSPACE}/backend/start-backend.sh"

cat > "${RUNTIME_WORKSPACE}/chat/start-chat.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 --version >/dev/null
sleep 120
EOF
chmod +x "${RUNTIME_WORKSPACE}/chat/start-chat.sh"

mkdir -p "${INSTALL_WORKSPACE}/VCPToolBox" "${INSTALL_WORKSPACE}/VCPChat"

cat > "${INSTALL_WORKSPACE}/VCPToolBox/config.env.example" <<'EOF'
API_Key=YOUR_API_KEY
API_URL=http://127.0.0.1:3000
PORT=6005
Key=YOUR_KEY
Image_Key=YOUR_IMAGE_KEY
File_Key=YOUR_FILE_KEY
VCP_Key=YOUR_VCP_KEY
AdminUsername=admin
AdminPassword=YOUR_PASSWORD
CALLBACK_BASE_URL=http://127.0.0.1:6005/plugin-callback
EOF

cat > "${INSTALL_WORKSPACE}/VCPToolBox/package.json" <<'EOF'
{
  "name": "vcptoolbox-smoke",
  "version": "0.0.0"
}
EOF

cat > "${INSTALL_WORKSPACE}/VCPChat/package.json" <<'EOF'
{
  "name": "vcpchat-smoke",
  "version": "0.0.0"
}
EOF

mkdir -p "${INSTALL_WORKSPACE}/VCPToolBox/Plugin/ExamplePlugin"
cat > "${INSTALL_WORKSPACE}/VCPToolBox/Plugin/ExamplePlugin/requirements.txt" <<'EOF'
# smoke-test plugin requirements placeholder
EOF

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
VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" init --cli --yes --no-start-after-init \
  --runtime-mode portable \
  --runtime-manifest "${manifest_active}" \
  --workspace-root "${RUNTIME_WORKSPACE}" \
  --backend-cwd "${RUNTIME_WORKSPACE}/backend" \
  --backend-cmd "./start-backend.sh" \
  --chat-cwd "${RUNTIME_WORKSPACE}/chat" \
  --chat-cmd "./start-chat.sh" \
  --startup-delay 0 > "${TMP_DIR}/runtime-init-fail.log" 2>&1
runtime_init_rc=$?
set -e

if [ "${runtime_init_rc}" -eq 0 ]; then
  echo "Expected runtime init to fail on checksum mismatch" >&2
  cat "${TMP_DIR}/runtime-init-fail.log" >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  rg -q "S27_RUNTIME_VERIFY" "${STATE_DIR}"/session-*.json
else
  grep -q "S27_RUNTIME_VERIFY" "${STATE_DIR}"/session-*.json
fi

cat > "${manifest_active}" <<EOF
manifest_version|1
artifact|node|20.99.0|linux-x86_64|file://${RUNTIME_ASSETS_DIR}/node-runtime.tar.xz|-|${node_sha}|-
artifact|python|3.11.99|linux-x86_64|file://${RUNTIME_ASSETS_DIR}/python-runtime.tar.xz|-|${python_sha}|-
EOF

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" resume --cli --yes --no-start-after-init > "${TMP_DIR}/runtime-resume.log"

runtime_wrapper="${INSTALLER_HOME}/runtime/bin/vcp-runtime-exec"
if [ ! -x "${runtime_wrapper}" ]; then
  echo "Expected runtime wrapper missing: ${runtime_wrapper}" >&2
  exit 1
fi

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" start > "${TMP_DIR}/runtime-start.log"

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" status > "${TMP_DIR}/runtime-status.log"

if command -v rg >/dev/null 2>&1; then
  rg -q "RuntimeMode: portable" "${TMP_DIR}/runtime-status.log"
  rg -q "RuntimeHealth: ready" "${TMP_DIR}/runtime-status.log"
  rg -q "backend: RUNNING" "${TMP_DIR}/runtime-status.log"
  rg -q "chat: RUNNING" "${TMP_DIR}/runtime-status.log"
else
  grep -q "RuntimeMode: portable" "${TMP_DIR}/runtime-status.log"
  grep -q "RuntimeHealth: ready" "${TMP_DIR}/runtime-status.log"
  grep -q "backend: RUNNING" "${TMP_DIR}/runtime-status.log"
  grep -q "chat: RUNNING" "${TMP_DIR}/runtime-status.log"
fi

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" stop > "${TMP_DIR}/runtime-stop.log"

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" install --cli --yes \
  --workspace-root "${INSTALL_WORKSPACE}" \
  --components all \
  --skip-node-install \
  --skip-python-install \
  --overwrite-config \
  --vcp-api-url "http://127.0.0.1:3100" \
  --vcp-api-key "sk-test-install" \
  --vcp-port 6100 \
  --vcp-key "test-vcp-key" \
  --chat-server-url "http://127.0.0.1:6100/v1/chat/completions" \
  --chat-api-key "sk-chat-install" > "${TMP_DIR}/install-flow.log"

if [ ! -f "${INSTALL_WORKSPACE}/VCPToolBox/config.env" ]; then
  echo "Expected VCPToolBox config.env to be generated" >&2
  exit 1
fi

if [ ! -f "${INSTALL_WORKSPACE}/VCPChat/AppData/settings.json" ]; then
  echo "Expected VCPChat AppData/settings.json to be generated" >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  rg -q "^API_URL=http://127.0.0.1:3100$" "${INSTALL_WORKSPACE}/VCPToolBox/config.env"
  rg -q "^API_Key=sk-test-install$" "${INSTALL_WORKSPACE}/VCPToolBox/config.env"
  rg -q "^PORT=6100$" "${INSTALL_WORKSPACE}/VCPToolBox/config.env"
  rg -q "\"vcpServerUrl\": \"http://127.0.0.1:6100/v1/chat/completions\"" "${INSTALL_WORKSPACE}/VCPChat/AppData/settings.json"
  rg -q "\"vcpApiKey\": \"sk-chat-install\"" "${INSTALL_WORKSPACE}/VCPChat/AppData/settings.json"
else
  grep -q "^API_URL=http://127.0.0.1:3100$" "${INSTALL_WORKSPACE}/VCPToolBox/config.env"
  grep -q "^API_Key=sk-test-install$" "${INSTALL_WORKSPACE}/VCPToolBox/config.env"
  grep -q "^PORT=6100$" "${INSTALL_WORKSPACE}/VCPToolBox/config.env"
  grep -q "\"vcpServerUrl\": \"http://127.0.0.1:6100/v1/chat/completions\"" "${INSTALL_WORKSPACE}/VCPChat/AppData/settings.json"
  grep -q "\"vcpApiKey\": \"sk-chat-install\"" "${INSTALL_WORKSPACE}/VCPChat/AppData/settings.json"
fi

session_id="$(awk '/Starting new session/ {print $NF; exit}' "${TMP_DIR}/install-flow.log")"
if [ -z "${session_id}" ]; then
  echo "Could not parse session id from install flow log" >&2
  cat "${TMP_DIR}/install-flow.log" >&2
  exit 1
fi

if [ ! -f "${INSTALLER_HOME}/reports/install-report-${session_id}.json" ]; then
  echo "Expected install report JSON missing for session ${session_id}" >&2
  exit 1
fi

if [ ! -f "${INSTALLER_HOME}/reports/install-report-${session_id}.md" ]; then
  echo "Expected install report Markdown missing for session ${session_id}" >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  rg -q "\"global_mutation\"" "${INSTALLER_HOME}/reports/install-report-${session_id}.json"
  rg -q "\"safe_default\": true" "${INSTALLER_HOME}/reports/install-report-${session_id}.json"
else
  grep -q "\"global_mutation\"" "${INSTALLER_HOME}/reports/install-report-${session_id}.json"
  grep -q "\"safe_default\": true" "${INSTALLER_HOME}/reports/install-report-${session_id}.json"
fi

VCP_INSTALLER_HOME="${INSTALLER_HOME}" \
VCP_INSTALLER_STATE_DIR="${STATE_DIR}" \
"${INSTALLER}" install --cli --yes --dry-run \
  --workspace-root "${INSTALL_WORKSPACE}" \
  --components toolbox \
  --skip-node-install \
  --install-plugin-python-deps > "${TMP_DIR}/install-plugin-dryrun.log"

if command -v rg >/dev/null 2>&1; then
  rg -q "plugin requirements file\\(s\\)" "${TMP_DIR}/install-plugin-dryrun.log"
else
  grep -q "plugin requirements file(s)" "${TMP_DIR}/install-plugin-dryrun.log"
fi

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
VCP_INSTALLER_HOME="${HEADLESS_INIT_HOME}" \
VCP_INSTALLER_STATE_DIR="${HEADLESS_INIT_STATE}" \
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
  --runtime-mode system \
  --allow-system-integration \
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
