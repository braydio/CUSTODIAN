# Operator Workbench Sparse Art Checkout Review Corrections 1

The east and west `block_hold_01` FX import sidecars were already repaired on current `main` by `e3d4e7f98` (`operator block hold fx reimport`). At the packet's reviewed baseline (`dfaf9e269`), the east sidecar still had `valid=false`; current main has valid remap paths and destination files in both records. The PNG bytes remain unchanged. No runtime correction was needed in this resumed workstream.

Validation evidence:

- `operator_modular_layers_smoke.gd`: passed in the clean full checkout at current `main`.
- `operator_art_worktree_smoke.py`: passed.
- `operator_animation_workbench_smoke.py`: passed.
- `operator_workbench_mirror_publish_smoke.py`: passed.
- `operator_compatibility_resources_smoke.py`: passed; all 11 retired compatibility resources remain absent.
- `operator_animation_contract_report.py`: 63 expected, 60 present, 0 missing required, 3 missing optional.
- `git diff --check`: passed.
- `operator_workbench_ui_smoke.py`: failed its real-checkout assertion because it expects the old `workbench/operator-art` wording; current `publish_preview()` blocks publish from coordination `main` with the newer `Launch OPUI ... isolated art checkout` message.
- Fresh sparse modular-layer validation remains unproven. The dedicated sparse checkout had valid `block_hold_01` PNGs, but Godot could not compile the autoload graph while other LFS-backed resources were pointer files. A local-only `git lfs checkout` attempt was interrupted after several minutes. No network LFS fetch was used.

The Godot import attempt used Godot 4.7.2 in the persistent sparse art checkout and regenerated 1,561 tracked `.import` sidecars. All generated sidecar edits were restored; that checkout returned clean. The local LFS hydration attempt also temporarily materialized 232 pointer files, which were restored to their initial pointer contents. The full project root and resumed task worktree remained free of tracked modifications during validation.

The task is checkpointed as blocked because its sparse-checkout acceptance still needs a run with the required local LFS dependencies, and the UI smoke has a stale message assertion. The code repair itself is present on main and the same modular-layer smoke passes in the full checkout.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: Sparse Godot import rewrote tracked `.import` metadata before exposing missing LFS dependencies; all generated changes were restored. The UI smoke assertion expects stale wording.
- Root cause / contributing factors: Godot 4.7 import ran in a persistent sparse checkout without all required local LFS objects; the UI smoke does not track the current publish-block message.
- Prevention / pipeline improvement: Use a disposable, version-matched checkout with needed local LFS objects for import validation; update the UI smoke in its owning task.
- Tooling / docs drift discovered: Sparse profile lacked required LFS resources; UI smoke expectation is stale.
- Follow-up: manual-follow-up
- What worked: Current main already contains both import repairs, and focused full-checkout validation passed.
