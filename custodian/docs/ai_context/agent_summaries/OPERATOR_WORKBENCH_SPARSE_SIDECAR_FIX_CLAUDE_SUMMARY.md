# Operator Workbench Sparse Sidecar Fix

## Summary
- Fixed the persistent Operator art sparse profile so every explicitly selected single-file dependency also materializes an already-tracked Godot `.import` or `.uid` sidecar when one exists at `HEAD`.
- Preserved directory-level sparse entries unchanged; their sidecars were already included by the directory pattern.
- Kept the publication allowlist strict. Unexpected outputs still block instead of being silently staged or discarded.
- Extended `operator_art_worktree_smoke.py` with tracked fixture sidecars and assertions for:
  - `muzzle_flash_yellow.png.import`
  - `Impact Vox Hammer.wav.import`
  - `dev_observatory_overlay.gd.uid`

## Root Cause
The sparse profile intentionally included several one-file Godot dependencies but omitted their tracked metadata sidecars. Godot then regenerated those absent tracked files during Workbench validation, making the dedicated art checkout dirty. The publish firewall correctly rejected those unrelated changes.

## Validation
- Re-fetched live `main` after both code commits and verified the new sidecar expansion logic and all three regression assertions are present.
- Executable `operator_art_worktree_smoke.py` was not run from this GitHub-only session; the local smoke remains the final runtime check after the user's checkout syncs.

## Existing Checkout Recovery
The user's already-dirty `CUSTODIAN-operator-art` checkout is intentionally not reset by this patch. Restore the three generated sidecar changes once, then relaunch `opui`; the normal clean fast-forward path will apply the corrected sparse profile.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: Explicit sparse file dependencies did not carry their tracked Godot metadata sidecars.
- Root cause / contributing factors: Sparse fixture coverage asserted the source files but not their sidecars.
- Prevention / pipeline improvement: Sidecar discovery is now automatic for tracked explicit-file dependencies and regression-covered.
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: The existing publish allowlist failed closed and preserved the unexpected files unstaged.
