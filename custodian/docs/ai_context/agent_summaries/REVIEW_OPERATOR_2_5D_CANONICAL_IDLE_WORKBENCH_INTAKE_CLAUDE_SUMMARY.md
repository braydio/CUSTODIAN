# Review: Operator 2.5D canonical idle Workbench intake

## Result

`findings` on landed implementation `3dc888c44`; current reviewed main ref is `26167ea659057192e12b71288e5a2be793454dd7`. The source and eight direction artifacts reproduce exactly, but the acceptance fails because the editable Workbench manifests make the 8 FPS editor default authoritative although source timing is unknown.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38

## Finding R0-01

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: Preserve `fps=null` as unknown; editor defaults are not authored or human-approved timing and cannot close review or runtime promotion.
- Evidence: Each physical `workbench.json` under the eight reported direction roots records `timeline.fps=8.0` and `timeline.timing_authority=true`. The active ingress builds these records with an unconditional `fps: 8.0`; `animation_workbench.timing_payload_from_timeline` treats `timing_authority` as permission to produce an authoritative timing payload. This conflicts with `idle_relaxed_01_intake.json`'s `UNKNOWN_NOT_APPROVED` statement.
- Disposition: `correction`
- Rationale: The machine-readable Workbench state can authorize timing downstream despite the report correctly describing it as a UI default. Keep the preview default usable while marking timing non-authoritative until explicit timing is authored.
- Follow-up: `operator-2-5d-canonical-idle-workbench-intake-review-corrections-1` (paired review `review-operator-2-5d-canonical-idle-workbench-intake-review-corrections-1`).

## Independent evidence

- Accepted source: 541,981 bytes, 1920x1024 RGBA, SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`.
- All eight 1920x128 RGBA strips independently match the declared master rows; concatenated RGBA pixels equal the master.
- All eight Source Session candidates match their strip pixels and recorded hashes.
- All eight saved Aseprite documents have valid headers, 15 frames, 128x128 canvas, and report-matching hashes. All eight Workbench JSON hashes/target identities match.
- Focused checks passed: `operator_2_5d_ingress_smoke.py`, `operator_animation_targets_smoke.py`, `operator_workbench_production_queue_smoke.py`.
- The landed commit changes converter behavior, the focused smoke and evidence/docs only; it does not modify runtime images, selector, catalog or SpriteFrames. No effective review receipt or publication was found.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: shared Git metadata denied fetch writes in the linked worktree; available refs sufficed for review.
- Root cause / contributing factors: Git common directory is outside this worktree's writable area.
- Prevention / pipeline improvement: provide normal fetch metadata access to paired review runs.
- Tooling / docs drift discovered: none
- Follow-up: operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- What worked: direct source, Source Session, Workbench JSON and Aseprite checks made the proof reproducible without relying on the implementation transcript.

## Next Handoff
- Next workstream: operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: correct the non-authoritative timing contract for imported Workbenches, then execute its paired review.
- Blockers or open questions: correction packets are draft/manual pending normal publication/dispatch authority.
