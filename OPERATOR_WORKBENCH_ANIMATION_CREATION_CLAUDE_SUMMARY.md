# Operator Workbench Animation Creation

## Outcome

Implemented a schema-driven New Animation flow across the Workbench model, CLI, and OPUI. It supports `full_body` and synchronized `lower_body + upper_body` templates, validates semantic identity and canonical paths before session creation, opens blank publishing layers with optional deterministic reference guides, previews saved Aseprite pixels, and publishes through the guarded source/runtime transaction. Successful publication normalizes the manifest to ordinary source-backed editing; newly reachable animations display DORMANT until gameplay wiring exists. Mirror promotion remains explicit and off by default.

The transaction rechecks source/runtime/import/timing collisions immediately before mutation, writes timing authority, rebuilds runtime outputs, and preserves exact rollback receipts. Resource backup files now use stable unique names, avoiding path aliasing when the worktree is relocated.

## Evidence

- `operator_animation_workbench_smoke.py`: passed full-body and modular Aseprite creation, known-pixel preview, contract rejection, post-plan race refusal, successful CREATE and manifest normalization, rollback, frame/canvas migration, and existing compatibility coverage.
- `operator_workbench_ui_smoke.py`: passed reachability projection; optional Textual interactive pilot skipped because Textual is not installed.
- `operator_workbench_mirror_publish_smoke.py`: passed CREATE/REPLACE, mirror, collision, import metadata restore, and rollback.
- `operator_art_worktree_smoke.py`: passed isolated publisher/landing fixture.
- Godot import preflight: passed; no LFS pointers.
- Runtime SpriteFrames import smoke: passed (588 imports).
- Modular layer smoke: passed.
- Strict animation contract report: passed; 63 expected, 60 present, zero required missing, three optional absent.
- `run_validation.py --changed --json`: passed, 22 selected checks, zero failures.
- Python compile checks: passed.

The first closeout sweep found a fixture-specific resource backup alias and an assertion tied to the old backup path shape. Both were corrected; focused transaction smokes and the final sweep passed afterward. No production art was added. Generated pilot reports were disposable validation output and removed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Resource backup paths aliased live paths in a relocated fixture; one existing smoke asserted the prior path format.
- Root cause / contributing factors: Backup destinations were derived from repository-relative source paths instead of a transaction-local unique name.
- Prevention / pipeline improvement: Keep generated-resource backup destinations transaction-local and unique; assert backup existence and uniqueness rather than a serialized path suffix.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Aseprite-backed known-pixel fixtures proved both successful CREATE normalization and rollback.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

## Next Handoff
- Next workstream: review-operator-workbench-animation-creation
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Auto-dispatch the paired post-land review after this implementation packet archives.
- Blockers or open questions: Textual interactive pilot remains unrun because its optional dependency is absent; service/UI projection smoke passed.
