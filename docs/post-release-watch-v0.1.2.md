# Post-Release Watch Plan v0.1.2

## Owner

`openclaw`

## Watch Window

1. Start: 2026-02-24
2. End: 2026-03-03
3. Duration: 7 days

## Scope

1. Installer startup failures (`bin/vcp-installer`, AppImage launch, tar fallback run).
2. Release asset integrity reports (`SHA256SUMS`, `SHA256SUMS.sig`, `SHA256SUMS.pem`).
3. Linux runtime compatibility issues (Ubuntu/Debian baseline).

## Daily Check Items

1. Review new issues labeled release/regression.
2. Reproduce reported failures using published assets.
3. Record status in issue comments (confirmed, mitigated, unresolved).

## Exit Criteria

1. No Sev-1/Sev-2 unresolved regressions at end of watch window.
2. All known issues linked to follow-up milestones.
