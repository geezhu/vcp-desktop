# VCPInstallerGUI Release Notes v0.1.2

**Release Date**: 2026-02-24  
**Release Owner**: openclaw

## Summary

This release publishes the first executable Linux artifacts for the installer baseline and enables signed checksum verification.

## Included in This Release

1. Minimal executable installer entry (`bin/vcp-installer`) with CLI/GUI mode support.
2. Linux packaging outputs:
   - `vcpinstaller-v0.1.2-linux-x64.tar.gz`
   - `vcpinstaller-v0.1.2-linux-x86_64.AppImage`
3. Integrity and signing outputs:
   - `SHA256SUMS`
   - `SHA256SUMS.sig`
   - `SHA256SUMS.pem`
4. Workflow hardening:
   - smoke test before release packaging
   - checksum signature generation and verification before publish

## Breaking Changes

None.

## Known Limitations

1. Installer still provides a minimal baseline flow (`dry-run`-oriented), not full component deployment.
2. Gitee mirror publishing is not included in this release.

## Post-Release Watch Window

1. Owner: `openclaw`
2. Window: 7 days
3. Start: 2026-02-24 (release publish date)
4. End: 2026-03-03
