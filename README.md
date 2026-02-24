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
./bin/vcp-installer --cli --dry-run
./bin/vcp-installer resume --cli --dry-run
./bin/vcp-installer --headless --dry-run --simulate-gui-step
```

## Build Artifacts (Local First)

```bash
./scripts/build-tarball.sh
./scripts/build-appimage.sh
./scripts/verify-artifacts.sh
```

By default, local build outputs are generated in `dist/` and temporary AppImage build files in `build/`.

## Notes

1. This baseline does not yet implement full component installation logic.
2. AppImage build downloads `appimagetool` into `.local-build-env/tools/`.
3. For headless mode, GUI-required steps must emit a structured block and exit non-zero.
