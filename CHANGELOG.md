# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

## v0.2.0 - 2026-02-25

### Added

- Real install/config orchestration in `bin/vcp-installer install|resume` for `VCPToolBox` and `VCPChat`.
- Automatic generation of `VCPToolBox/config.env` (template-based patching) and `VCPChat/AppData/settings.json`.
- Install report export (`JSON` + `Markdown`) under installer runtime home `reports/`.
- New installer options for components, config overrides, and dependency-install toggles.
- Optional plugin dependency mode for `Plugin/**/requirements.txt` installation.
- Smoke coverage for install flow (config generation + report generation assertions).
- Confirmed portable-runtime direction: bootstrap private runtime during `init` by default.
- Added portable-runtime design/task documentation for phased execution.
- Synced Linux AIO design with FR-010 portable runtime state machine and acceptance constraints.
- Expanded portable runtime task breakdown with explicit implementation and release gates.
- Portable runtime bootstrap implementation in `init` (`S25/S26/S27/S28`: plan/fetch/verify/prepare).
- Runtime manifest parser, schema validator script, and manifest template (`manifests/runtime-manifest-linux-x86_64.txt`).
- Runtime wrapper generation and start-time isolation (`PATH`/`LD_LIBRARY_PATH`) for portable mode.
- Runtime-aware status/reset/resume paths and install report `global_mutation` gate fields.
- Smoke and regression coverage for checksum-fail -> resume recovery and source fallback scenarios.
- Explicit system-mode confirmation and audit logging (`--allow-system-integration`).
- Runtime asset build script for release publishing (`scripts/build-runtime-assets.sh`).
- Runtime manifest validator/regression scripts and baseline runtime manifest template.

### Changed

- `init` default backend command now uses `node server.js` for VCPToolBox compatibility.
- Dependency precheck now emits package-manager-aware install hints and supports strict failure mode.
- Release workflow now uploads runtime assets and runtime manifest with signed checksum set.
- Artifact checksum generation now includes runtime packages and runtime manifest files.

## v0.1.2 - 2026-02-24

### Added

- Minimal installer executable entry at `bin/vcp-installer` with CLI/GUI mode flags.
- Local smoke test script for startup, resume, and headless GUI-required behavior.
- Local packaging scripts for `tar.gz`, `AppImage`, and `SHA256SUMS`.
- Local artifact verification script for checksum and runnable extraction checks.
- Repository README with local build and usage instructions.
- Post-release watch window plan with explicit owner and observation duration.

### Changed

- Release workflow now runs smoke test and builds artifacts via local scripts.
- Release workflow now signs `SHA256SUMS` using `cosign keyless` and verifies `SHA256SUMS.sig` before publish.

## v0.1.0 - 2026-02-24

### Added

- Initial requirements document for installer scope and constraints.
- Linux AIO design draft created as local working reference.
- Release process checklist and local execution rule draft.
- GitHub release workflow for tag-based packaging and publishing.

### Breaking Changes

- None.

### Known Limitations

- Installer implementation is not started yet (documentation-first phase).
- No runnable installer binary is shipped in this version.
- AppImage artifact is not generated in this version.
