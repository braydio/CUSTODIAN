# CORRECTION: OPERATOR 2.5D CANONICAL IDLE WORKBENCH INTAKE

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-canonical-idle-workbench-intake
- Locks: operator-art-agent, operator-source-normalization, operator-workbench-ui, operator-art-generation-schema
- Kind: correction
- Review: auto
- Review stage: post-land
- Review modes: code, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- Review cycle: 1
- Max automatic review cycles: 2
- Reviewed main: e04423a4d030f3abf2e4894aa2e6fd2befede8b6
- Parent implementation: operator-2-5d-canonical-idle-workbench-intake; custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_CANONICAL_IDLE_WORKBENCH_INTAKE.md
- Parent review: review-operator-2-5d-canonical-idle-workbench-intake; custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_CANONICAL_IDLE_WORKBENCH_INTAKE.md
- Findings addressed: R0-01
- Affected acceptance: The accepted source timing remains fps=null/unknown; Workbench editor defaults do not become authored or human-approved timing and cannot authorize review or runtime promotion.
- Current defect/evidence: All eight imported workbench.json files record timeline.fps=8.0 and timing_authority=true. Ingress hardcodes fps=8.0, while timing_payload_from_timeline treats the authority bit as permission to emit a timing payload.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Goal: Keep imported idle Workbench preview timing editable while ensuring the 8 FPS UI default is explicitly non-authoritative until an approved timing value exists.
- Completion boundary: Correct the timing-authority contract for specialized 2.5D import and prove no source pixels, target bindings, legacy/runtime outputs or publication status changed.
- Current measured state: The immutable intake report and live authoring checkout matched all eight original Workbench/Aseprite/session/candidate/source-strip hashes and package bindings. All eight ignored manifests now have `timing_authority=false`; preview remains 8 FPS / 125 ms, documents remain 15×128×128. The correction evidence report records exact original/corrected/backup hashes and unchanged source/runtime hashes. Live receipt directory has 0 receipts; 0/8 directions or families verified and 0 published. The old master path recorded in the original intake report points to a removed ephemeral worktree, but the eight strips, sessions and candidates still match their recorded hashes.
- Evidence: Archived review R0-01 and its closing summary; archived intake packet; the eight physically reviewed manifests and reports; `operator_2_5d_ingress.py::_process_cell/_validate_workbench`; `animation_workbench.py::create_animation`; `animation_workbench_model.py::timing_payload_from_timeline`; `operator_2_5d_review.py::_inspect/current_receipt/make_sandbox_request`; `ui/service.py::review_and_sandbox`; focused ingress, timing, QA and family queue tests.
- Task-specific authority: Archived parent implementation packet acceptance and design/02_features/animation/OPERATOR_2_5D_WORKBENCH_MIGRATION_ROADMAP.md; retain WB25-2 editable-workbench behavior and fail-closed publication rules.
- Work surface: specialized importer `custodian/tools/operator/operator_2_5d_ingress.py`; additive explicit authority option at `custodian/tools/operator/animation_workbench.py::create_animation` (only if necessary); `custodian/tools/operator/operator_2_5d_review.py` for effective verification gating; `animation_workbench_model.py` only if its existing read contract truly needs hardening; focused `operator_2_5d_ingress`, `operator_2_5d_review`, `operator_animation_timing`, production-queue tests and their validation manifest owner; **eight exact ignored workspace `workbench.json` only**, plus a new non-destructive correction evidence report. Do not write arbitrary other Workbench documents or recreate Source Sessions.
- Required correction: Keep visible/physical editing at 8 FPS / 125 ms per frame but bind imported *unknown-source* timing as `timing_authority=false`. Use a narrowly explicit creation argument or typed provenance signal; do not change the default behavior of ordinary legacy or explicitly timed creations. For the eight existing Workbench manifests, perform a strict, idempotent **manifest-only** correction after checking every target binding, package ID, source/candidate/document SHA and current timeline contract. Back up each original `workbench.json`, update only the authority flag (and minimal clearly identified provenance if unavoidable), and verify the Aseprite documents and rendered/source pixels remain byte-identical. Refuse modified/unrecognized input rather than overwriting artist changes. `timing_payload_from_timeline` must continue to return `None` when the flag is false and its existing valid payload for truly authoritative creations. Crucially, `Operator2DReview` currently reads physical durations independently of the timing-authority bit and can set `runtime_verified` after sandbox+QA; close that loophole: non-authoritative timing may support preview/diagnostic review but **must never produce an effective `runtime_verified` leaf, completed family, or WB25-6 promotion proof**, even when QA, human disposition or sandbox reports are green. Do not derive timing approval from Aseprite frame durations, review FPS, a successful sandbox, source hash, or simply the 8.0 numeric value. Retain existing direct explicit-timing success paths.
- Preserve: Exact source/candidate pixels, all eight generation-aware target identities, saved editable Workbench documents, unknown/null source timing, current WB25-4 receipt ownership, no runtime mutation/publication.
- Non-goals: Selecting production FPS, authoring timing, approving any direction, changing animation art, modifying runtime or WB25-6 cohort scope.
- Acceptance: (1) New specialized source intake with unknown FPS creates editable 8 FPS physical Aseprite frames and `preview_fps=8.0` but `timing_authority=false`; the existing timing payload helper yields `None`. (2) Existing explicit timing with authoritative intent continues producing the previous payload; legacy/default creation and published legacy paths do not regress. (3) All eight preexisting intake cells are individually repaired in-place with approved backups and fresh **post-correction** hashes, no changed `.aseprite`/PNG/source hash, no changed Source Session identity/receipt or runtime, no PUBLISHED status. (4) A negative regression provides GREEN or YELLOW QA, a valid human disposition when needed, and a passing sandbox to the review path with `timing_authority=false` and proves `runtime_verified=false`, `family.complete=false`, effective WB25-6 receipt absent, independent of the literal preview FPS. (5) Positive control proves explicitly approved/current timing still permits normal review eligibility when other gates pass; tampered/stale manifest or unknown-provenance repairs refuse rather than invent authority. (6) A fresh reviewer can examine the physical workspace, backups and durable post-correction evidence, not just simulated fixtures.
- Validation: First run focused `operator_2_5d_ingress_smoke.py`, `operator_2_5d_review_smoke.py`, `operator_animation_timing_smoke.py`, `operator_animation_targets_smoke.py`, `operator_workbench_production_queue_smoke.py`, and the relevant `operator_workbench_ui_smoke.py`; register/reconcile validation manifest ownership when code changes. Add real or faithful-contract regression on the preview-vs-approved distinction and the physical manifest reconciliation. Check eight post-correction manifests and their Aseprite/document hash preservation; independently inspect WB25-4 `current_receipt()`/family projections and confirm 0/8 verified leaves for this cohort. Snapshot protected legacy/runtime/catalog/SpriteFrames hashes before/after. Then `python3 custodian/tools/validation/run_validation.py --changed --json`, repository pairing/index/AI-context checks, and `git diff --check`. Serialize Godot sweeps rather than weakening timeouts.
- Task overrides: none
- Deferred: Human timing selection and direction QA remain outside this correction.

## Refresh Planning Authority
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh instruction: Completed 2026-10-10 in the recorded authoring chat. **Decision:** 8 FPS is provisional preview-only and MUST NOT confer timing authority, while explicit approved timing retains existing behavior. This is a bounded correctness repair, not human FPS selection or WB25-6 promotion. `ready/manual` permits an explicitly authorized claim of the existing correction workstream; no local dispatcher lock bypass, project-root checkout reset or independent re-claim of WB25-6.

## Completion Truth

- Completion schema: custodian.task_completion.v1
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Evidence: `custodian/docs/reports/operator_2_5d/idle_relaxed_01_timing_authority_correction_1.json` records 8/8 manifest-only corrections, exact original backups and fresh hashes, preserved Aseprite/source-strip/Source Session/candidate hashes, unchanged protected runtime hashes, 0 effective receipts, and no publication. Focused ingress, review, timing, target, production-queue, and Workbench UI smokes passed. Changed-file validation passed all 26 selected tests with complete coverage; AI-context check and `git diff --check` passed.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first review smoke hit its 90-second Godot timeout because the ephemeral project had no import cache. The source master path in the original intake report points to a deleted worktree, although all per-direction strips, sessions, candidates and Workbench documents remain available and match the baseline hashes.
- Root cause / contributing factors: Fresh worktrees require an initial Godot import before sandbox execution; the intake evidence stored an absolute source-master path inside a disposable worktree.
- Prevention / pipeline improvement: Initialize Godot imports before sandbox smoke in a fresh worktree; prefer durable or checkout-relative source evidence paths in future intake reports.
- Tooling / docs drift discovered: The historical intake report's accepted master path is stale. The correction verified unchanged direction strips and source session/candidate hashes instead and recorded the stale path in the new evidence report.
- Follow-up: review-operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- What worked: Strict all-eight preflight and byte-level comparison made the workspace repair auditable and limited each manifest edit to one boolean token.

## Existing artist workspace and recovery boundary

- Package ID: `6854391909f3dca2ed2b`; accepted source master: SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7aaf175f3`, 541981 PNG bytes, `1920×1024`, RGBA 15×8 @ 128px. Target `operator_2_5d_128:unarmed/posture/idle_relaxed_01/{n,ne,e,se,s,sw,w,nw}/full_body`. Eight Workbench documents live in **ignored artist workspace state**, not the Git-tracked commit. Resolve its actual root explicitly from the intake report and live active workspace; do not assume the current Codex worktree automatically contains those documents.
- The existing `custodian/docs/reports/operator_2_5d/idle_relaxed_01_intake.json` is historical immutable baseline evidence; do not edit it to hide the original defect. Add a separate post-correction report recording exact old/new manifest SHA, unchanged saved document/source strip hashes, paths (workspace-local), binding, count `8/8` and effective review count `0/8`, with any blocked directions and their reason.
- If the current physical workspace cannot be accessed safely, fix and test the code path but report workspace reconciliation as **blocked**, preserve the workstream, and do not land a false eight-manifest completion. Do not reconstruct ignored Aseprite docs from synthetic fixtures or move the artist workspace into a disposable worktree merely to pass review.
- Run under the existing dispatcher claim/lock and ordinary isolated worktree workflow. Do not take locks held by other agents or alter the persistent project-root checkout (which has unrelated changes).

## Next Handoff
- Next workstream: review-operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: Run the fresh-context paired review against the landed correction and physical workspace evidence.
- Blockers or open questions: none; WB25-6 remains draft/manual and unchanged.


## Independent Review

- Status: `passed`
- Review workstream: `review-operator-2-5d-canonical-idle-workbench-intake-review-corrections-1`
- Reviewed on main: `455392871fd95d831feed14d55bd29ee913680bf`
- Reviewed implementation commit: `fa955e5e7`
- Review modes: code, asset-pipeline, workflow
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Blocking defects: 0
- Material evidence gaps: 0
- Non-blocking issues: 0
- Optional improvements: 0
- Prior finding dispositions: R0-01 fixed
- Detailed review summary: `REVIEW_OPERATOR_2_5D_CANONICAL_IDLE_WORKBENCH_INTAKE_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Durable receipt: `custodian/docs/reports/operator_2_5d/idle_relaxed_01_timing_authority_review_1.json`

### Verification Performed

- `operator_2_5d_ingress_smoke.py` — PASS.
- `operator_2_5d_review_smoke.py` — PASS after import-cache initialization; initial cold-cache attempt timed out after 90 seconds.
- `operator_animation_timing_smoke.py` — PASS.
- `operator_workbench_production_queue_smoke.py` — PASS.
- All eight live ignored manifests and original backups independently match the evidence report; physical documents, strips and sessions match expected hashes.
- Protected runtime manifest, animation catalog and SpriteFrames hashes match the intake baseline.
