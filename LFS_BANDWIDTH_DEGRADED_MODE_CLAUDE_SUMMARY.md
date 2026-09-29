# LFS BANDWIDTH DEGRADED MODE CLAUDE SUMMARY

Temporary Git LFS conservation mode for the remainder of September 2026.

## Changed

- Agent workstream and landing processes set `GIT_LFS_SKIP_SMUDGE=1` until
  2026-10-01 00:00 America/New_York.
- `custodian/AGENTS.md` documents the temporary operating rule: cached LFS is
  usable; missing payloads may defer only the gate that truly requires them;
  never rewrite LFS assets into ordinary Git to bypass quota.
- Existing GitHub Actions validation remains unchanged because its checkouts
  already omit `lfs: true`, so those jobs do not intentionally download LFS
  payloads.
- A scheduled cleanup workflow removes the temporary instruction block, both
  code guards, and itself after the expiry.

## Negative controls

- No LFS asset paths, attributes, or production files were rewritten.
- No validation test or CI job was disabled.
- No persistent global Git configuration is changed on developer machines.

## Validation

Branch CI is the closeout validation for this workflow-only patch.
