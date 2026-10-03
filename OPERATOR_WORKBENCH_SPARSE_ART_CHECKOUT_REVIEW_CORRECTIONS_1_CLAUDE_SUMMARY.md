# Operator Workbench Sparse Art Checkout Review Corrections 1

The east and west `block_hold_01` FX import sidecars were already repaired on current `main` by `e3d4e7f98` (`operator block hold fx reimport`). At the packet's reviewed baseline (`dfaf9e269`), the east sidecar still had `valid=false`; current main has valid remap paths and destination files in both records. The PNG bytes remain unchanged, so no runtime or art correction was needed in this resumed workstream.

The sparse Operator art checkout initially contained LFS pointers for assets required by validation. I copied 785 Operator and weapon source payloads from the full `~/Projects/CUSTODIAN` checkout into the resumed task branch after verifying each file's SHA-256 against its branch pointer. I used no network LFS fetch. The copied payloads were restored to their original pointer blobs after testing so the task branch remained clean.

Validation evidence:

- Sparse profile LFS preflight: passed.
- Godot 4.7.2 sparse project import: exit 0; no missing-resource or Operator script-parse errors. It logged one unrelated dialog-parenting error.
- `operator_modular_layers_smoke.gd` in the sparse art checkout: passed. The tested Operator runtime files matched `origin/main`.
- `operator_art_worktree_smoke.py`: passed.
- `operator_workbench_ui_smoke.py`: passed in the resumed task branch after source payloads were materialized. Its earlier run from coordination `main` failed because the test expects the task branch's checkout reason.
- `operator_animation_workbench_smoke.py`: passed.
- `operator_workbench_mirror_publish_smoke.py`: passed.
- `operator_compatibility_resources_smoke.py`: passed; all 11 retired compatibility resources remain absent.
- `operator_animation_contract_report.py`: 63 expected, 60 present, 0 missing required, 3 missing optional.
- `git diff --check`: passed; changed-file closeout passed `review_pairing_contract`.

The first project import in the persistent sparse art checkout rewrote 1,561 tracked `.import` sidecars. I restored those generated metadata edits, then used the import preflight before the successful retry. The temporary LFS payloads and generated imports were not committed. The art checkout and root coordination checkout are clean.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first import ran before required LFS payloads were materialized and rewrote tracked `.import` sidecars; the UI smoke was first run from the wrong checkout context.
- Root cause / contributing factors: I treated local LFS availability as cache-only and did not copy matching payloads from the full root checkout; the UI smoke has branch-specific expectations.
- Prevention / pipeline improvement: Verify pointer SHA-256 values and copy matching files from the full project root when needed; run branch-sensitive checks from the claimed task branch; run the import preflight before Godot import.
- Tooling / docs drift discovered: The packet's local-only LFS note did not name the full root checkout as a payload source; the validation step now records exact-hash copying.
- Follow-up: none
- What worked: Exact-hash copying resolved 785 source assets without network access, and the sparse smoke plus Workbench regressions passed.
