# CORRECTION: OPERATOR ANIMATION DECISION AUTHORITY HARDENING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-animation-decision-authority-hardening-v1-review-corrections-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-animation-decision-authority-hardening-v1`
- Locks: `operator-workbench-ui, operator-art-generation-schema, operator-art-agent`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-animation-decision-authority-hardening-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `0e3cfa940`
- Parent implementation: `operator-animation-decision-authority-hardening-v1`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_ANIMATION_DECISION_AUTHORITY_HARDENING_V1.md`
- Parent review: `review-operator-animation-decision-authority-hardening-v1`; `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_ANIMATION_DECISION_AUTHORITY_HARDENING_V1.md`
- Findings addressed: `R0-01, R0-02`
- Affected acceptance: `H` (explicit approval requires a trusted Workbench user action); `D` and `I` (only current, reproducible evidence can yield a verified receipt)
- Current defect/evidence: The fresh paired review called `WorkbenchService._preview_timing_decision_from_ui()` and `_confirm_timing_decision_from_ui()` directly and obtained effective `APPROVED TIMING` without a Workbench UI action (R0-01). The required `operator_2_5d_review_smoke.py` repeatedly exceeded its 90-second Godot sandbox timeout before downstream `current_receipt()` controls ran, leaving required receipt evidence unproven (R0-02). The ignored physical eight-direction workspace was unavailable; no live-art or approval claims were made.
- Goal: Ensure only a real explicit Workbench confirmation can persist timing approval and make the timing/current-receipt controls reproducible under a bounded Godot sandbox run.
- Completion boundary: Correct the service/UI approval boundary and close the required current-receipt/sandbox evidence gap; add targeted negative and positive regressions. Keep the original eight art records untouched and timing unapproved.
- Current measured state: Review at `0e3cfa940` found one blocking implementation defect and one material proof gap. Direct service helper calls mint timing approval. The review smoke's sandbox subprocess timed out after 90 seconds twice. Five focused smokes passed; the optional Textual pilot did not run in the reviewer environment. No 2.5D artist workspace was present.
- Evidence: Archived implementation review receipt and `REVIEW_OPERATOR_ANIMATION_DECISION_AUTHORITY_HARDENING_V1_CLAUDE_SUMMARY.md`; `custodian/tools/operator/ui/service.py`; `custodian/tools/operator/ui/app.py`; `custodian/tools/operator/operator_2_5d_review.py`; `custodian/tools/validation/operator_2_5d_review_smoke.py`; `custodian/tools/validation/operator_workbench_ui_smoke.py`.
- Task-specific authority: The parent archived packet's timing provenance contract; `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`; existing Workbench UI/service and `Operator2DReview.current_receipt()` remain the sole decision and verification authorities.
- Work surface: Workbench UI event handling and service boundary; bounded Godot sandbox runner/review smoke; focused timing, receipt, and UI tests; validation manifest ownership only if paths change.
- Required correction:
  1. Remove timing-decision persistence authority from callable generic service preview/confirm helpers. A caller-supplied disposition, Boolean, or method name must not authorize a write. Route persistence through an explicit, observed Workbench confirmation event with a narrow one-use in-process UI intent; keep preview/read/validation operations non-authoritative. Preserve exact saved-input hash binding and all prior timing gates.
  2. Add a negative regression that invokes service-level preview/confirm APIs without an observed UI event and proves no approval record is created and `current_receipt()` cannot verify. Add a positive test that drives the actual Workbench Preview then Confirm controls through the UI event/pilot path and proves the exact current input decision can be recorded. A test that calls the service writer directly is not positive UI evidence.
  3. Diagnose and resolve the real Godot sandbox timeout in `operator_2_5d_review_smoke.py`, including cold-worktree import/startup needs. Keep a finite subprocess deadline and useful failure diagnostics; do not hide a timeout, skip the sandbox, or report a synthetic sandbox pass as real renderer evidence.
  4. Ensure the review smoke reaches and asserts the downstream current-receipt positive/negative controls after real sandbox `PASSED` evidence. If needed, split deterministic receipt controls from the real sandbox launch so the assertions still execute independently, while retaining a separate required real sandbox pass. No fake sandbox status may satisfy the real sandbox acceptance.
  5. Record review feedback that the physical artist workspace was unavailable; do not claim those eight records were inspected or approved.
- Preserve: Existing hash-bound decision record format and stale-input rejection; legacy timing and sidecar behavior; 8 FPS as preview only; all eight physical Aseprite/Workbench records, their manifests and original hashes; QA/sandbox/human-art approval as separate gates; no runtime publication or cohort activation.
- Non-goals: Choosing an FPS; editing or normalizing animation art; approving existing art; changing runtime generation, publication, cohort policy, or WB25-6; changing design authority; adding broad validation infrastructure unrelated to these two findings.
- Acceptance:
  - `R0-01`: Direct generic service/helper calls cannot create, persist, or imply an approved timing decision. An actual UI Preview→Confirm interaction can record a decision bound to current saved inputs. Mutations after that interaction make it stale. Existing legacy timing behavior remains intact.
  - `R0-02`: From a fresh claimed worktree, the documented initialization plus `operator_2_5d_review_smoke.py` terminates within its explicit deadline with a real Godot sandbox `PASSED` result and executes the positive current-receipt and unapproved/stale negative controls. A deliberately stalled child is terminated with actionable diagnostics; no test substitutes a fake sandbox pass.
  - Required test evidence includes a UI-driven positive path, service-call negative path, and independently reproducible current-receipt controls. The absent physical workspace remains a stated limitation, and no artist timing or publication claim is made.
- Validation: Focused timing, review/sandbox, UI, ingress, targets, and production-queue smokes; targeted UI pilot with the actual controls; cold-worktree Godot import then `operator_2_5d_review_smoke.py`; bounded-timeout negative control; `run_validation.py --changed --json`; `check_ai_context.py`; `validate_review_pairing.py`; `task_packet_index.py`; `git diff --check`. Do not run a broad Godot sweep.
- Task overrides: `none`
- Deferred: Human FPS selection, physical eight-direction inspection, first real verified family, and WB25-6 release/cohort approval.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `<exact correction execution failures or none>`
- Root cause / contributing factors: `<concise cause or none>`
- Prevention / pipeline improvement: `<small repeatable improvement or none>`
- Tooling / docs drift discovered: `<exact drift or none>`
- Follow-up: `<none | fixed-in-scope | workstream-id | manual-follow-up>`
- What worked: `<optional, one short line>`

## Handoff

- Next workstream: `review-operator-animation-decision-authority-hardening-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38`
- Summary backlink: `include the exact Authoring chat URL in every durable summary and final Next Handoff`
- Refresh reason: `none`
- Next action: `After this correction lands and archives complete, dispatch its fresh paired review.`
- Blockers or open questions: `none`
