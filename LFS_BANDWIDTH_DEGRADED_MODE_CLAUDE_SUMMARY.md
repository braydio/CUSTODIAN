# LFS BANDWIDTH DEGRADED MODE CLAUDE SUMMARY

Temporary Git LFS conservation mode for the remainder of September 2026.

## Changed

- Agent workstream and landing processes set `GIT_LFS_SKIP_SMUDGE=1` until
  2026-10-01 00:00 America/New_York.
- Sourcing `tools/custodian_aliases.sh` now exports the same guard for ordinary
  shell Git operations during the active window; after expiry it unsets only
  the value that this temporary mode managed.
- `custodian/AGENTS.md` documents the temporary operating rule: cached LFS is
  usable; missing payloads may defer only the gate that truly requires them;
  never rewrite LFS assets into ordinary Git to bypass quota.
- Existing GitHub Actions validation remains unchanged because its checkouts
  already omit `lfs: true`, so those jobs do not intentionally download LFS
  payloads.
- A scheduled cleanup workflow removes the temporary instruction block, both
  agent-tool guards, the aliases-file export block, and itself after expiry.

## Negative controls

- No LFS asset paths, attributes, or production files were rewritten.
- No validation test or CI job was disabled.
- No persistent global Git configuration is changed on developer machines;
  the aliases export affects only shells that source the repository helper.

## Validation

- Agent workflow contract tests passed on the first branch run: 7 workflow tests
  plus 28 dispatcher tests.
- The first changed-file gate correctly failed closed because the new cleanup
  workflow lacked validation ownership. Added it to `agent_workflow_contract`;
  the follow-up branch CI is the closeout gate.