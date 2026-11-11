# Operator 2.5D Idle Intake Timing Authority Correction 1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38

## Result

Closed R0-01 for `operator-2-5d-canonical-idle-workbench-intake-review-corrections-1`.

New unknown-timing 2.5D imports keep the editable 8 FPS / 125 ms preview but pass `timing_authority=false` through an additive `create_animation()` option. Existing default and explicit timing creation behavior remains authoritative. The ingress validator requires non-authoritative timing for this specialized source intake. `Operator2DReview.current_receipt()` now refuses effective 2.5D verification unless timing authority is true and the existing timing-payload helper yields a valid payload.

The regression covers default preview-only import, an explicit authoritative creation control, an approval-plus-passing-sandbox negative control, and an eight-direction fully covered family that remains incomplete when the effective receipt is rejected.

## Physical Workspace Reconciliation

The live artist workspace matched the archived intake evidence for all eight directions before mutation: package `6854391909f3dca2ed2b`, exact target identity, original manifest hash, Aseprite hash, Source Session hash, reviewed-candidate hash, and direction-strip hash. Each original manifest was backed up under:

`/home/braydenchaffee/Projects/CUSTODIAN-operator-art/.ai/operator_animation_workbench/recovery/idle_relaxed_01_timing_authority_r0_01/original_manifests/`

Only the literal `"timing_authority": true` changed to false in each manifest. Preview remains 8 FPS, physical frame durations remain 15 × 125 ms, and Aseprite/source/session/candidate hashes remain unchanged. The correction receipt is `custodian/docs/reports/operator_2_5d/idle_relaxed_01_timing_authority_correction_1.json`; the immutable original intake report was not edited. Current review-receipt directory contains zero receipts, leaving 0/8 verified leaves, 0 verified families, and 0 published directions.

The archived intake report's accepted-master path pointed into a deleted ephemeral worktree. The master file was unavailable there, but all eight direction strips, Source Sessions, reviewed candidates, and saved Workbench documents were present and matched their intake hashes. This limitation is recorded in the new receipt; no source or runtime data was changed.

## Validation

- `operator_2_5d_ingress_smoke.py`: passed.
- `operator_2_5d_review_smoke.py`: passed after initializing Godot's import cache. The first attempt timed out at the existing 90-second sandbox limit.
- `operator_animation_timing_smoke.py`: passed.
- `operator_animation_targets_smoke.py`: passed.
- `operator_workbench_production_queue_smoke.py`: passed.
- `operator_workbench_ui_smoke.py`: passed; optional Textual pilot skipped because Textual is not installed.
- `run_validation.py --changed --json`: 26/26 passed, complete coverage. Existing warning-producing expected rollback diagnostics in one route smoke remained non-failing.
- `check_ai_context.py`: passed.
- `git diff --check`: passed.
- Protected runtime manifest, catalog, and SpriteFrames hashes matched the pre-correction intake report.

No timing value was approved, no direction was reviewed or published, and WB25-6 remains draft/manual.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: the fresh Godot worktree timed out before import initialization; the original intake report's absolute master path is stale.
- Root cause / contributing factors: isolated worktrees start without project import cache; source evidence used a disposable checkout path.
- Prevention / pipeline improvement: import the project before sandbox smokes and prefer durable/relative source paths in intake reports.
- Tooling / docs drift discovered: historical source-master path is stale; per-direction integrity evidence remains complete.
- Follow-up: review-operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- What worked: strict preflight plus one-token manifest edits preserved and proved the physical artist assets.

## Next Handoff
- Next workstream: review-operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: Run the fresh-context paired review.
- Blockers or open questions: none; WB25-6 remains blocked and untouched.
