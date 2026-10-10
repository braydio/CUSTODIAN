# CORRECTION: OPERATOR 2.5D WORKBENCH REVIEW AUTOMATION R0-01

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-review-automation-review-corrections-1
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-review-automation
- Locks: operator-workbench-ui, operator-review-automation, operator-runtime-preview
- Kind: correction
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-operator-2-5d-workbench-review-automation-review-corrections-1
- Review cycle: 1
- Max automatic review cycles: 2
- Reviewed main: bede798e744b40f334424998148baac87052b362
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Parent implementation: operator-2-5d-workbench-review-automation; custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md
- Parent review: review-operator-2-5d-workbench-review-automation; custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md
- Findings addressed: R0-01
- Affected acceptance: Parent acceptance item 9 and change item 17: effective `runtime_verified=true` requires objective + required-human + sandbox gates, and a human decision is bound to the exact current review evidence.
- Current defect/evidence: `Operator2DReview.inspect()` accepts a caller-supplied `human_disposition` mapping. `current_receipt()` then treats either `APPROVED` or `NOT_REQUIRED` as satisfying the human gate even when current QA is `NEEDS_HUMAN_REVIEW`. A caller can therefore pass `{"status":"NOT_REQUIRED"}` and obtain `runtime_verified=true` after a passing sandbox without any approval. The paired review recorded this as blocking R0-01.
- Goal: Close WB25-4 R0-01 by making required-human review fail closed unless an explicit Workbench approval is backend-authored and evidence-bound.
- Completion boundary: Correct only the human-disposition producer/consumer boundary, the existing Workbench approval control, and focused regression coverage. Preserve the landed receipt hashing, target/family projection, Sequence v2, sandbox request/proof, production-runtime no-diff and WB25-3 mutation boundaries.
- Current measured state: A `NEEDS_HUMAN_REVIEW` receipt can be caller-labeled `NOT_REQUIRED`; `current_receipt()` accepts that status as sufficient for effective verification. The UI checkbox normally sends `APPROVED`, but no backend contract distinguishes an explicit approval from arbitrary free-form disposition data.
- Evidence: `REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION_CLAUDE_SUMMARY.md`; archived parent review R0-01; live `operator_2_5d_review.py::inspect/current_receipt`; `ui/service.py::review_leaf/review_and_sandbox`; `ui/widgets/polish_panel.py`; `operator_2_5d_review_smoke.py`.
- Task-specific authority: Archived WB25-4 acceptance item 9; live `custodian.operator_art_qa.v2` QA status; `human_review_evidence_sha()` as the exact current evidence binding; Workbench UI as the existing explicit local human-action surface; `VISUAL_REVIEW_HANDOFF.md` only for the broader subjective-review doctrine. Do not depend on the separately queued visual-review Q&A capture tooling for this correction.
- Work surface: `custodian/tools/operator/operator_2_5d_review.py`; `custodian/tools/operator/ui/service.py`; `custodian/tools/operator/ui/widgets/polish_panel.py` and `ui/app.py` only where the explicit approval intent/label must be carried; `custodian/tools/validation/operator_2_5d_review_smoke.py`; directly affected `operator_workbench_ui` validation. Avoid sandbox/presentation/runtime files unless a regression test proves a correction-caused need.
- Required correction:
  1. Remove the free-form human-disposition authority from the ordinary review inspection seam. `inspect()` / `review_leaf()` must derive the baseline human state from current QA rather than accepting arbitrary caller status maps.
  2. The allowed effective human states are exactly `NOT_REQUIRED`, `REQUIRED`, and `APPROVED`. They are semantic results, not caller-selectable enum values.
  3. `GREEN` and `YELLOW` derive `NOT_REQUIRED`. A caller cannot force them to `APPROVED` or use approval data to change objective QA meaning.
  4. `NEEDS_HUMAN_REVIEW` derives `REQUIRED` until the existing explicit Workbench approval action is taken. `NOT_REQUIRED` is invalid for this QA state and must never satisfy effective verification.
  5. `RED` cannot be unblocked by any human-disposition value. Effective verification remains false regardless of approval intent.
  6. Keep one explicit approval entry point. The existing Workbench checkbox/button intent may remain, but the backend must author the actual approval object after re-inspecting the current leaf; callers must not provide a prebuilt `human_review` mapping.
  7. Canonical approval provenance for the currently supported local Workbench path is:
     - `status: APPROVED`
     - `provenance.kind: workbench_explicit_user`
     - `provenance.reviewer: human-user`
     - `provenance.control: polish-human-approved`
     - `evidence_sha256: <human_review_evidence_sha over the exact current identity/Workbench/render/profile/reference/physical timing/findings>`
     Exact private field layout may differ only if it preserves these semantics and remains machine-readable.
  8. The backend, not the caller, computes/injects `evidence_sha256`. Approval is valid only while it equals a freshly recomputed current evidence digest. Any art, Workbench, timing, profile/reference or QA-finding change invalidates it.
  9. `current_receipt()` must derive the gate from current QA plus the validated human record:
     - `GREEN|YELLOW + NOT_REQUIRED + PASSED sandbox` may verify;
     - `NEEDS_HUMAN_REVIEW + valid APPROVED provenance/evidence + PASSED sandbox` may verify;
     - every other combination is non-verified or invalid/stale.
     It must not use a generic `status in {APPROVED, NOT_REQUIRED}` shortcut.
  10. Tighten the UI label so checking it is an unambiguous approval action for the exact current major-finding evidence, not a generic “disposition” toggle. Keep default false and reset after the review action.
  11. Preserve the existing conditional external visual-review doctrine. This correction does not add a new Dropbox decision database or make external tooling a dependency; a user who reviewed evidence externally may still make the explicit local Workbench approval action that records the evidence-bound local provenance.
- Preserve: WB25-4 receipt/file hashing and staleness; `human_review_evidence_sha()`; current QA taxonomy; family derivation; Sequence v1/v2 behavior; sandbox tamper/no-diff proof; Workbench publication-free boundary; WB25-3 fresh proposal re-derivation; production selector/runtime resources; default-false approval UI.
- Non-goals: No WB25-5 queue/brief work; no WB25-6 publication/cutover; no new visual-review/Dropbox decision subsystem; no authentication/security system; no new QA taxonomy; no sandbox/presenter redesign; no art mutation or aesthetic decision by the execution agent.
- Acceptance: (1) direct old-style `human_disposition={"status":"NOT_REQUIRED"}` cannot turn `NEEDS_HUMAN_REVIEW` into a current verified receipt; the old free-form seam is rejected or removed. (2) `NEEDS_HUMAN_REVIEW` with no explicit approval remains `REQUIRED`, does not launch/accept the sandbox as sufficient, and yields `runtime_verified=false`. (3) the explicit Workbench approval path produces only the canonical provenance record above, with backend-computed exact evidence binding; after a passing sandbox the exact unchanged leaf may verify. (4) forged approval provenance, caller-supplied evidence hashes, `NOT_REQUIRED` on human-required QA, stale approval evidence and approval against `RED` all fail closed. (5) `GREEN` and `YELLOW` continue to verify with backend-derived `NOT_REQUIRED` plus a passing sandbox, with no approval required. (6) changing current QA/findings/Workbench/timing/profile/reference/frame evidence makes any prior approval stale. (7) UI default/reset behavior remains safe and its label is explicit. (8) no sandbox, target, family, sequence, publication, runtime or WB25-3 mutation behavior regresses.
- Validation: Start with `python3 custodian/tools/validation/run_validation.py --test operator_2_5d_review --json`. Add adversarial focused cases for free-form `NOT_REQUIRED`, forged `APPROVED` provenance/evidence, `RED + approval`, stale evidence, valid exact approval, and unchanged GREEN/YELLOW no-approval behavior. Then run `python3 custodian/tools/validation/run_validation.py --test operator_workbench_ui --json` and `--test operator_2_5d_polish --json` if touched by imports/QA projection. Run Python compile checks for changed modules, `run_validation.py --changed --json`, task-packet/review-pair validation, and `git diff --check`. Do not require a new visual capture.
- Task overrides: none
- Deferred: structured import of future Dropbox `REVIEW_DECISION` records into Operator review provenance may be added only after that separate tooling authority lands and a real workflow need exists.

## Agent Handoff / Planning Decisions

- R0-01 is an authority-boundary correction, not a request to redesign review UX or human-review policy.
- The explicit local Workbench approval action is the currently supported approval provenance source. Treat the checkbox as approval intent only; the review backend authors and validates the durable receipt fields.
- Do not solve this by merely deleting `NOT_REQUIRED` from one boolean expression. Both producer and consumer must fail closed so another caller cannot recreate the bypass.
- Do not couple this correction to `VISUAL_REVIEW_QUESTION_ANSWER_CAPTURE_V1`; that workstream is independently queued and not a prerequisite for WB25-4 correctness.
- WB25-5 remains blocked until this correction's fresh paired re-review passes.

## Context Pack

- Repomix: recommended
- Include: `custodian/tools/operator/operator_2_5d_review.py,custodian/tools/operator/ui/service.py,custodian/tools/operator/ui/app.py,custodian/tools/operator/ui/widgets/polish_panel.py,custodian/tools/validation/operator_2_5d_review_smoke.py,custodian/tools/validation/operator_workbench_ui_smoke.py,custodian/tools/operator/art_agent/qa.py,custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md,custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md,custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md`
- Purpose: `R0-01 human-gate producer/consumer boundary, current explicit Workbench approval UI, exact evidence binding and focused regressions`

Generate once from the claimed worktree:

```bash
scripts/ai/pack-context.sh task "<Include value above>" "operator-2-5d-workbench-review-automation-review-corrections-1"
```

## Handoff

- Next workstream: review-operator-2-5d-workbench-review-automation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none
- Next action: Claim the correction, close R0-01 with focused adversarial proof, then launch the paired fresh-context re-review.
- Blockers or open questions: none; the approval-provenance contract is fixed above.
