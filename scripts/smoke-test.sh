#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${ROOT_DIR}/bin/vcp-installer"
STATE_DIR="${ROOT_DIR}/.local-build-env/smoke-state"
TMP_DIR="${ROOT_DIR}/.local-build-env/smoke-tmp"

if [ ! -x "${INSTALLER}" ]; then
  echo "Installer is not executable: ${INSTALLER}" >&2
  exit 1
fi

rm -rf "${STATE_DIR}" "${TMP_DIR}"
mkdir -p "${STATE_DIR}" "${TMP_DIR}"

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

if ! rg -q "GUI_REQUIRED" "${TMP_DIR}/headless.log"; then
  echo "Expected GUI_REQUIRED marker not found in headless log" >&2
  cat "${TMP_DIR}/headless.log" >&2
  exit 1
fi

echo "Smoke test passed."
echo "Logs:"
ls -lh "${TMP_DIR}"
