# VCPInstallerGUI

Linux-first minimal installer baseline for VCP projects, with unified CLI/GUI entry and local-first packaging.

## Current Scope

1. Provide a minimal executable installer entry (`bin/vcp-installer`).
2. Provide local smoke tests and artifact packaging scripts.
3. Keep release flow local-first; trigger GitHub Actions only when needed.

## Quick Start (Local)

```bash
cd VCPInstallerGUI
chmod +x bin/vcp-installer scripts/*.sh
./scripts/smoke-test.sh
```

## CLI Usage

```bash
./bin/vcp-installer --help
./bin/vcp-installer install --cli --yes --components all --workspace-root ~/vcp
./bin/vcp-installer install --cli --yes --components toolbox --install-plugin-python-deps --strict-dependencies
./bin/vcp-installer --cli --dry-run
./bin/vcp-installer resume --cli --dry-run
./bin/vcp-installer --headless --dry-run --simulate-gui-step
./bin/vcp-installer init --cli --yes --workspace-root ~/vcp --backend-cmd "node server.js" --chat-cmd "npm run start"
./bin/vcp-installer start
./bin/vcp-installer status
./bin/vcp-installer stop
```

## First-Run Behavior

1. First launch without config: installer enters initialization wizard and writes launcher profile.
2. After initialization: installer can start backend and VCPChat in the same run.
3. Subsequent launches: installer skips init and directly executes one-click start.
4. Runtime control: use `status`, `stop`, and `reset`.

## Build Artifacts (Local First)

```bash
./scripts/build-tarball.sh
./scripts/build-appimage.sh
./scripts/verify-artifacts.sh
```

By default, local build outputs are generated in `dist/` and temporary AppImage build files in `build/`.

## Notes

1. Installer now covers minimal component install/config flow; full plugin/system dependency coverage remains incremental.
2. AppImage build downloads `appimagetool` into `.local-build-env/tools/`.
3. For headless mode, GUI-required steps must emit a structured block and exit non-zero.
4. Default profile is user-level isolated (`~/.local/share/vcpinstallergui`) to reduce system environment pollution.
5. Use `--install-plugin-python-deps` to include Plugin/**/requirements.txt install.
6. Use `--strict-dependencies` to fail fast when required commands are missing.

## Installer Outputs

1. `VCPToolBox/config.env` is generated from template and patched with minimal runnable keys.
2. `VCPChat/AppData/settings.json` is generated with minimal connection settings.
3. Install reports are exported to `~/.local/share/vcpinstallergui/reports/` (or `VCP_INSTALLER_HOME` override).

## Release Signature

1. Release workflow signs `dist/SHA256SUMS` with `cosign keyless` and publishes:
   - `SHA256SUMS.sig`
   - `SHA256SUMS.pem`
2. Signature is verified in workflow before release upload.
3. Local verification script (`scripts/verify-artifacts.sh`) verifies signature when `cosign` is available.
