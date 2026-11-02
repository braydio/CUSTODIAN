# WB25-5 Production Queue + Generation Briefs

Implemented WB25-5 on `operator-2-5d-workbench-production-queue`.

## Delivered

- Added a live queue projection built from the 69-family / 552-direction plan, current target projection, exact family review, and effective current receipts. It preserves the authored 4 P0 / 65 P1 ordering and rank, exposes the required filters and deterministic NEXT skip reasons, and keeps plan/source/workspace/QA/verified/publication states separate.
- Repaired `Operator2DReview.family()` to read real `AnimationRecord.coverage_status` and `stale_reference` fields and to check every required plan direction and layer, including missing leaves. Replaced the false-positive fixture with real records and a `WorkbenchService.review_family()` integration regression.
- Added content-addressed local generation briefs with target, plan/profile/reference hashes, exact direction plus adjacent references, registration guide and transparent overlay, explicit unknown timing fields, deterministic reuse, path/tamper/staleness checks, and atomic publication.
- Added optional brief ID + manifest hash validation at the existing WB25-2 ingress seam. Briefed and unbriefed packages retain the existing ingress authority; unresolved frame counts remain rejected.
- Updated the Workbench queue UI, current-state and file-index documentation, WB25 UX roadmap disposition, and validation ownership. Archived the completed packet and refreshed the managed queue index.
- WB25-6 remains the only production publication/promotion authority.

## Measurements and limits

The planning baseline is 69 families / 552 direction slots, 4 P0 / 65 P1, one accepted source family (8 directions), and one resolved / 68 unresolved frame contracts. The supplied snapshot observed 0 current verified leaves/families, 0 2.5D manifests, 0 current receipts, and 0 sandbox passes in the specified populated Operator authoring checkout. Those counts describe that sampled workspace only. A legacy browser scan error is surfaced as `UNAVAILABLE`, not converted into a claim of zero coverage. The prior 96×96 five-frame east idle remains distinct from the accepted 128×128 15-frame source target. No source art or publication state was created.

## Validation

- `operator_animation_targets_smoke.py`: PASS.
- `operator_workbench_production_queue_smoke.py`: PASS; also registered and passed through the validation runner.
- `operator_generation_brief_smoke.py`: PASS, including deterministic repeat, null FPS, unresolved frame contract, stale plan, wrong-direction, tampered bundle, ingress association, and unbriefed compatibility.
- `operator_2_5d_ingress`: PASS.
- `operator_2_5d_review`: PASS, including real-record family projection and review sandbox regression.
- `operator_workbench_ui_smoke.py`: PASS; optional Textual pilot skipped because the optional UI dependency is not installed.
- `run_validation.py --changed --json`: PASS, 36/36 selected, zero failures/timeouts/infrastructure errors, coverage complete.
- Python compile checks, validation-manifest JSON parse, task-packet index check, and `git diff --check`: PASS.
- Targeted packet authoring preflight passed before completion/archive.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Concurrent changed-file sweeps in other worktrees contended for the shared Godot lock. Two queued attempts were stopped; the focused Godot review check and changed-file run passed after serialization. One malformed EDITING-filter expression introduced during hardening was caught by `py_compile` and corrected before final validation.
- Root cause / contributing factors: Multiple active worktrees launch Godot-backed validation against one shared lock; a compact one-line filter expression obscured bracket structure.
- Prevention / pipeline improvement: Serialize Godot-backed sweeps across worktrees, select tests by exact validation-manifest IDs, and keep edited Python expressions multiline before compiling.
- Tooling / docs drift discovered: The named external count-probe script was absent from this checkout; count provenance was retained as workspace-scoped evidence and browser projection failures remain explicitly unavailable.
- Follow-up: review-operator-2-5d-workbench-production-queue
- What worked: Focused domain smokes ran independently of the shared engine lock and provided fast falsification before the complete changed-file pass.

## Next Handoff

- Next workstream: review-operator-2-5d-workbench-production-queue
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: Launch the fresh paired review through paired_review_runner.py after WB25-5 lands.
- Blockers or open questions: none for implementation; WB25-6 remains refresh-gated on reviewed live VERIFIED cohort evidence.
