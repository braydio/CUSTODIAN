# Operator Animation Decision Authority Hardening V1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38

Implemented the 2.5D timing-authorization boundary. Workbench POLISH now requires the artist to enter FPS, loop/once, and every frame-duration multiplier, preview the exact physical timing, and make a separate confirmation. No FPS is prefilled. Confirmation writes a backed-up manifest update and an atomic timing-decision record under the ignored review-receipt root. The record binds generation/target identity, exact manifest and saved Aseprite bytes, physical canvas/frame durations, current target-plan hash, profile/reference hashes, parameter digest, action provenance, and confirmation time.

`Operator2DReview.current_receipt()` now requires that current decision and includes its digest in receipt authority. Editing the manifest Boolean alone, copying a decision to another target, or changing document, physical timing, target plan, profile, or reference leaves timing ineffective. Generic 2.5D `create_animation(..., timing_authority=True)` now remains non-authoritative. Legacy timing payloads and sidecar behavior remain unchanged.

Added the accepted-decision matrix to the existing 2.5D visual contract, documented the Workbench control and stale behavior, updated `CURRENT_STATE.md` and `FILE_INDEX.md`, and registered the new authority module with the existing validation owners. Tests cover explicit preview/confirm, missing preview, one-use confirmation, generic Boolean promotion, copied target identity, stale physical/document/plan/profile/reference inputs, receipt gating after QA and sandbox, and legacy compatibility. The timing fixture tests use isolated temporary roots; the eight real idle manifests and physical Aseprite documents were not modified. No FPS was selected and no runtime art was published.

## Validation

- Changed-file validation: 48 selected checks passed; ownership coverage complete; 0 failed or timed out.
- Focused timing, ingress, review/sandbox, target, production-queue, Workbench UI, and canonical visual-contract smokes passed. The UI pilot ran with the optional Textual dependencies installed in a temporary verification environment.
- `check_ai_context.py`, paired-review validation (62 auto-review pairs), task-packet index validation, Python compile checks, and `git diff --check` passed.
- The runtime manifest/catalog/SpriteFrames, selector, source strips, and accepted design/reference assets are absent from the diff. WB25-6 remains `draft/manual`; current timing and runtime publication remain unapproved.

The first UI pilot run exposed a missing `Input` import. After that was fixed, the stale `PilotService` fixture blocked browser refresh because it lacked the queue and timeline-duration methods used by the current UI; those fixture methods and an explicit preview/confirm UI-flow assertion are now in the smoke. A Godot import during review validation generated an unrelated `.gd.uid`; it was removed from this worktree and is not included.

The persistent project-root checkout still has unrelated dirty NPA files and is behind `origin/main`. It was not synchronized, reset, stashed, or otherwise changed. Safe root synchronization remains pending until that checkout is independently clean and only behind.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: initial UI pilot composition failed on a missing widget import; the existing pilot fake also lacked current queue/timeline service methods.
- Root cause / contributing factors: optional Textual coverage was skipped by the base interpreter, leaving panel composition unexercised; its fake lagged production service additions.
- Prevention / pipeline improvement: installed optional UI requirements in a temporary environment, restored fake-service parity, and asserted the complete preview/confirm interaction.
- Tooling / docs drift discovered: stale `PilotService` contract in `operator_workbench_ui_smoke.py`; fixed in-scope.
- Follow-up: fixed-in-scope
- What worked: isolated fixtures proved both the positive explicit decision and stale/copy rejection without touching the artist workspace.

## Next Handoff

- Next workstream: review-operator-animation-decision-authority-hardening-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: run `paired_review_runner.py review-operator-animation-decision-authority-hardening-v1` from the coordination checkout for a fresh independent review.
- Blockers or open questions: none for implementation; FPS, verified art, and WB25-6 runtime promotion remain intentionally unapproved.
