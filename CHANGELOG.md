# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- None.

### Changed

- None.

## v0.1.1 - 2026-02-24

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
