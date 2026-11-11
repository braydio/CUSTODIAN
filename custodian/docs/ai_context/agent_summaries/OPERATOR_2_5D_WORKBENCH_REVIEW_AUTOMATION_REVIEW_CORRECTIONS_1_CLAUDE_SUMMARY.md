# WB25-4 Review Automation Correction 1

Closed paired-review finding R0-01 by removing caller-provided disposition maps from both `Operator2DReview.inspect()` and `WorkbenchService.review_leaf()`. Review inspection now derives `NOT_REQUIRED` for GREEN/YELLOW and `REQUIRED` for NEEDS_HUMAN_REVIEW/RED. The existing Workbench checkbox is labeled as approval of the current NEEDS_HUMAN_REVIEW evidence; only the service path that observes that explicit intent invokes the backend approval writer.

The backend authors the fixed `APPROVED` provenance (`workbench_explicit_user`, `human-user`, `polish-human-approved`) and computes its evidence SHA from the current identity, manifest/document, rendered frame hashes, accepted profile/reference, physical dimensions/frame count/durations, and QA findings. A later inspection preserves approval only when the exact current evidence digest still matches. `current_receipt()` now rechecks the saved physical document contract and findings, validates the complete human record against live QA, recomputes the receipt evidence digest, and verifies effective runtime state only for GREEN/YELLOW with derived `NOT_REQUIRED` or NEEDS_HUMAN_REVIEW with canonical evidence-bound approval and a passing sandbox. Its path guard now resolves bundle-relative frame paths beneath the authorized bundle root, so valid sandbox evidence is accepted while traversal still fails closed. RED, forged provenance, mismatched approval evidence, caller-selected NOT_REQUIRED, and stale records fail closed.

## Evidence

- `operator_2_5d_review`: passed, including real Godot Operator sandbox proof, request tamper refusal, and frame tamper refusal.
- `operator_workbench_ui`: passed. Its optional Textual pilot was skipped because the optional UI dependency is not installed.
- `operator_2_5d_polish`: passed.
- The full changed-file sweep mapped every changed implementation/test file to a validation owner, but its repository-wide `review_pairing_contract` failed on 10 unrelated NPA Showcase packet lifecycle mismatches; the lower-tier-dependent motion-calibration check was consequently skipped. No changed-file implementation check failed. The exact focused 2.5D review, Workbench UI, and polish checks all passed.
- `py_compile` passed for the changed Python modules; `git diff --check` passed.
- Added direct `current_receipt()` positive/negative fixtures for the removed free-form API, `NEEDS_HUMAN_REVIEW + NOT_REQUIRED`, forged provenance/evidence, stale evidence, and `RED + APPROVED`; positive controls cover exact approval and unchanged GREEN/YELLOW behavior. The service regression confirms that a human-required sandbox does not run before approval intent and does run after the backend records the approval.
- No production animation resources, sandbox/presenter, publication, or WB25-3 mutation code changed. No visual capture was needed because acceptance is the receipt/API authority contract and is directly machine-checkable.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: the first real-sandbox smoke timed out during cold Godot project import in the fresh worktree; the new positive current-receipt fixture also exposed that relative sandbox-frame paths were resolved from the process directory instead of their authorized bundle root.
- Root cause / contributing factors: the ephemeral checkout had no `.godot` import/class cache, so the first project scan imported the repository's full asset set before the bounded sandbox process could run; `_under()` did not join relative evidence paths to the supplied authority root.
- Prevention / pipeline improvement: complete one bounded `godot --headless --editor --path custodian --quit` cache warm-up before the first Godot-backed smoke in a cold worktree; keep direct current-receipt positive/negative bundle fixtures so authority-root resolution stays covered.
- Tooling / docs drift discovered: the repository-wide review-pairing validator reports 10 unrelated NPA Showcase lifecycle mismatches; the correction/review pair itself is valid. The UI validation also skips its optional Textual pilot when that package is absent; core UI service checks pass.
- Follow-up: none
- What worked: evidence hashing kept human approval leaf-specific; the focused runner exercised both the direct authority helpers and the Workbench approval/sandbox ordering.

## Next Handoff

- Next workstream: review-operator-2-5d-workbench-review-automation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: launch the exact paired review from its required fresh reviewer context and re-prove the R0-01 negative controls against the landed correction.
- Blockers or open questions: none
