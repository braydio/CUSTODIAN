# Operator 2.5D canonical idle Workbench intake

## Result

The accepted `unarmed/posture/idle_relaxed_01` master was verified at SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3` (541,981 bytes, RGBA 1920×1024). Its manifest row order was used to extract eight lossless 1920×128 strips (15 frames at 128×128), and reassembly matched the master pixel-for-pixel.

The existing WB25-2 specialized ingress created package `6854391909f3dca2ed2b`. All eight directions reached `EDITABLE_WORKBENCH`, each with a saved 15-frame 128×128 Aseprite document and matching Workbench manifest. Source and candidate pixels match exactly. The durable per-direction hashes and paths are in `custodian/docs/reports/operator_2_5d/idle_relaxed_01_intake.json`.

The current live queue reports 69 families / 552 directions, 8 local canonical directions for this family, and 0 verified leaves or families. The editor inserted 8 FPS / 125 ms durations, but source plan FPS is null. Timing remains unknown and unapproved; none of these records is review-verified or published. WB25-6 remains blocked.

Pre/post checks found no changes to runtime manifest, animation catalog, SpriteFrames, legacy source, generated source, or existing pipeline inbox entries. No effective receipts, sandbox passes, or runtime publication were created.

## Implementation changes

- `SheetConversionRequest` now preserves the crisp converter's unlimited-color default unless a caller explicitly requests a limit.
- Canonical identity crop/scale/placement avoids lossy resampling; zero-offset registration also returns exact source pixels.
- The focused ingress smoke exercises the required `pixelart` alias, default crisp colors above 24 colors, and exact pixel preservation.

## Validation

- `operator_2_5d_ingress_smoke.py`: PASS
- `operator_animation_targets_smoke.py`: PASS
- `operator_workbench_production_queue_smoke.py`: PASS
- `operator_2_5d_review_smoke.py`: PASS after initializing the fresh worktree's Godot import cache; the initial run timed out before imports were initialized.
- `operator_art_registration_profile_smoke.py`: PASS
- `run_validation.py --changed --json`: PASS, 8 selected / 8 passed, complete coverage
- `git diff --check`: PASS

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: the required alias initially used the project-root checkout while verification ran in the claimed worktree; conversion replay also diverged from CLI crisp defaults and unnecessarily resampled identity transforms. A fresh Godot checkout needed its first import pass before sandbox validation.
- Root cause / contributing factors: converter replay omitted crisp palette intent, identity transforms were not short-circuited, and ephemeral worktrees do not carry Godot import caches.
- Prevention / pipeline improvement: pass checkout-specific `CUSTODIAN_REPO` / `CUSTODIAN_GODOT` through the alias; preserve colors by default and avoid identity resampling; initialize Godot imports before sandbox smoke in new worktrees.
- Tooling / docs drift discovered: ingress replay did not match the production CLI's crisp default, and the alias defaults to the persistent checkout.
- Follow-up: fixed-in-scope
- What worked: the existing specialized ingress and the live queue provided hash-bound status without introducing a parallel importer or touching runtime outputs.

## Next Handoff
- Next workstream: review-operator-2-5d-canonical-idle-workbench-intake
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: land intake, then run the fresh paired post-land review
- Blockers or open questions: timing approval and per-direction QA remain deferred; WB25-6 remains blocked
