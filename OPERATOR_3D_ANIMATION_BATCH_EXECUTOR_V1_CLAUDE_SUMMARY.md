# Operator 3D Animation Batch Executor V1 — Slice A

Workstream: `operator-3d-animation-batch-executor-v1`

## Delivered

Implemented the isolated Godot candidate preview adapter, standalone scene and focused smoke. The adapter verifies the Task 001 candidate receipt and exact source/master/QA identities, all 2,104 direction-frame file and RGBA-pixel hashes, dimensions, order, root registration, and safe path confinement before copying frames only under ignored `custodian/.ai/operator_3d_animation_preview/`.

The dev scene uses the real Operator scene, existing `OperatorBodyPresenter`, full-body renderer, game camera script, Sundered Keep environment and existing shadow. The same one body presenter switches between candidate and approved runtime art. It offers all eight candidate directions, candidate/approved selection, the experimental warning and stationary 30 FPS source-authored playback without granting runtime timing authority. Approved runtime comparison has no full-body diagonal clips, so NE/NW use N and SE/SW use S; that fallback is displayed, not mirrored.

A full in-game loop was captured and encoded as a 960×540 H.264 MP4 at 30 FPS, yuv420p: 263 frames, 8.766667 seconds. A decoded frame confirmed the expected scene, UI and one Operator body. The playable scene itself remains available for inspecting each direction and switching art interactively.

## Verification

- `python3 -m unittest custodian.tools.validation.test_operator_3d_animation_preview_package -v` — 8 passed.
- `python3 -m py_compile custodian/tools/operator/animation_compiler/preview_package.py custodian/tools/validation/test_operator_3d_animation_preview_package.py` — passed.
- Preview package/Godot smoke — passed; all 2,104 frames checked; eight directions, 263 frames each, 30 FPS; canonical root/shadow registration; one visible body owner; production approval and timing authority false.
- `python3 custodian/tools/validation/operator_2_5d_review_smoke.py` — passed.
- `git diff --cached --check` — passed; commit hook filename check passed.
- Review publisher uploaded the compact notes, full-loop MP4 and machine-readable receipts. It omitted the staged PNG frame set.

## Limits and deferred work

The preview establishes technical frame integrity and makes the full motion playable in the actual renderer. It does not establish artistic quality, ground perception or whether the comparison is useful; those remain human decisions. Slice B executor, Slice C multi-clip batch, and Slice D runtime handoff were not started. No production asset, runtime policy, source FBX, Blender master, ITER005 Running action or Operator model asset was changed.

Implementation branch: `agent/operator-3d-animation-batch-executor-v1`

Slice A code commit: `c654481c45afd86faca5b77710c018d46a5c0636`

Visual review manifest: `/CUSTODIAN/visual_review/operator-3d-animation-batch-executor-v1/20261030T013804Z/REVIEW_MANIFEST.json`

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: full 263-frame game capture took about four minutes on the current renderer host
- Root cause / contributing factors: real environment capture at 1280×720 is slower than the headless invariant smoke
- Prevention / pipeline improvement: retain the full loop as optional visual evidence; rely on the per-frame headless smoke for routine integrity validation
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: hash-bound ignored staging and the actual Godot renderer/presenter provided a compact end-to-end proof

## Next Handoff
- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: Required visual judgment of the playable Slice A proof before executor expansion.
- Next action: Review the playable preview and visual handoff; record a decision before resuming this workstream for Slice B.
- Blockers or open questions: Does the idle read naturally at actual game scale? Is direction selection and ground/shadow registration clear? Is the experimental/approved comparison useful without confusing ownership?
