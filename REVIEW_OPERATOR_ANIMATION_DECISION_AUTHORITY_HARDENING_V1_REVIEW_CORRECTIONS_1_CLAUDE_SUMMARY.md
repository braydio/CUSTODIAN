# Operator Animation Decision Authority Hardening V1 — Correction 1 Review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38

## Findings

### R0-01 — Service-level timing approval authority — fixed

- Class: blocking_defect (original cycle 0)
- Domain: implementation
- Affected acceptance: explicit Workbench confirmation is required to persist timing approval.
- Evidence: Current `WorkbenchService` exposes preview and one-use preview consumption only; `_confirm_timing_decision_from_ui` is absent. `operator_2_5d_review_smoke.py` directly invokes the service preview/consume methods, confirms the timing decision file remains absent and the manifest authority flag remains false, and rejects reuse and changed-input previews. `timing_decision_writer.record_confirmed_timing()` checks the active `Button.Pressed` event against the active confirm button, selected identity, and current saved-input hashes before persistence. The UI source routes only the confirmation button event to this writer. The UI smoke contains a real Textual Preview→Confirm pilot, but this review could not execute it because Textual is not installed and PyPI DNS/network access failed. The implementation summary records that pilot as passed; the review did not treat that summary alone as reproduced runtime evidence.
- Disposition: fixed for the service-authority defect; positive UI-event execution remains the material evidence gap R1-01.

### R0-02 — Godot sandbox/current-receipt evidence — fixed

- Class: evidence_gap (original cycle 0)
- Domain: implementation
- Affected acceptance: a real bounded Godot pass must precede current-receipt assertions, and a stalled child must fail with bounded diagnostics.
- Evidence: After the first import-aware runner attempt encountered a Godot TLS handshake error, retrying `python3 custodian/tools/validation/run_validation.py --test operator_2_5d_review --json` passed: one selected test, one passed, zero failed/timed out, with `operator_2_5d_review_smoke: PASS` in 13.8 seconds. The smoke requires `run_sandbox()` to return `PASSED` with unchanged production files before executing current-receipt positive/negative and family assertions. Its stalled-child control asserts `FAILED`, `timed_out`, the finite 0.05-second deadline, and actionable timeout text. Direct execution of the same smoke also passed.
- Disposition: fixed.

### R1-01 — Actual Workbench Preview→Confirm pilot — resolved during recovery

- Class: evidence_gap
- Domain: implementation
- Affected acceptance: R0-01 requires a positive test that traverses actual Workbench event handling and persists a current decision bound to saved inputs.
- Initial evidence: `operator_workbench_ui_smoke.py` skipped its optional Textual pilot in the review shell because the declared dependency was absent, and PyPI DNS was unavailable. This left the positive click path unverified at that point.
- Recovery evidence: The same smoke was then run from the claimed review worktree with the already installed Textual-enabled environment at `/tmp/custodian-wb25-tui-verify/bin/python`. It completed successfully, including `PASS TIMING UI FLOW: previewed values require a separate confirmation action` and the final `PASS operator_workbench_ui_smoke`. Its pilot uses `pilot.click()` on the actual Preview and Confirm controls, then verifies the exact saved decision and current hash bindings.
- Disposition: fixed during recovery; no implementation change required.
- Rationale: The required positive UI event path was replayed from the independent review worktree after the initial environment limitation was identified. Timing and art decisions remain unchanged.

## Validation evidence

- Passed: `python3 custodian/tools/validation/operator_2_5d_review_smoke.py` (real Godot sandbox, current-receipt assertions, stalled-child timeout control).
- Passed: `python3 custodian/tools/validation/run_validation.py --test operator_2_5d_review --json` (1/1 test; 13.8 seconds).
- Passed: `operator_2_5d_ingress_smoke.py`, `operator_animation_targets_smoke.py`, and `operator_workbench_production_queue_smoke.py`.
- Textual-enabled `operator_workbench_ui_smoke.py`: PASS from the claimed review worktree using the existing `/tmp/custodian-wb25-tui-verify` environment; actual Preview→Confirm pilot executed.
- `run_validation.py --changed --json` selected zero tests after the incidental Godot import artifact was removed; this was not counted as implementation evidence. The focused explicit runner result above is the relevant review smoke evidence.
- `check_ai_context.py`, `task_packet_index.py`, `validate_review_pairing.py`, and `git diff --check`: PASS when rerun from the claimed review checkout after fetching from the coordination checkout.
- Physical eight-direction artwork workspace was not available. No physical art, timing decision, runtime publication, or cohort state was changed.

## Verdict and closeout state

Findings-first verdict: R0-01 and R0-02 are fixed; the initial R1-01 evidence gap was resolved during recovery by replaying the actual Textual UI pilot from the claimed review worktree. Final blocking defects: 0. Final material evidence gaps: 0. New findings: none. No correction cycle 2 is needed.

The paired runner first stopped because the reviewer had written the summary to the wrong checkout path, so it could not find durable review state. The claimed review branch/worktree was preserved. Recovery wrote the summary into the exact claimed worktree, replayed the missing positive UI pilot with the preinstalled environment, and reran review-pairing checks successfully from the coordination-capable shell. The review artifacts can now complete through the normal workstream lifecycle. The temporary venv install attempt failed due unavailable PyPI DNS; it was unnecessary once the existing test environment was located.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The paired runner could not locate a summary written at the wrong worktree path. The reviewer shell initially lacked Textual and its PyPI retry failed; the initial local pairing check also could not update shared `FETCH_HEAD` inside that sandbox.
- Root cause / contributing factors: The reviewer used a non-canonical summary destination, optional UI packages were absent in its isolated Python, external DNS was unavailable, and the sandbox Git common directory was read-only.
- Prevention / pipeline improvement: Keep the summary at the exact claimed worktree root; use the available local Textual environment for replay; run shared-ref pairing checks from the coordination-capable checkout.
- Tooling / docs drift discovered: The runner's recovery check correctly fails closed without a root summary at the claimed worktree. No runner defect confirmed.
- Follow-up: fixed-in-scope
- What worked: Recovery preserved the reviewer branch, replayed the actual UI pilot, and retained the real sandbox/current-receipt evidence.

## Next Handoff

- Next workstream: operator-2-5d-runtime-promotion
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: The fresh correction review passed. Reconcile its final evidence with the existing WB25-6 hold and dependency order; no FPS is approved and runtime promotion remains draft/manual pending its cohort review and human decisions.
- Next action: Bring the landed correction and paired-review receipt to the recorded authoring chat; keep WB25-6 held until the declared cohort dependency review and explicit timing/cohort decisions are resolved.
- Blockers or open questions: WB25-6 remains draft/manual, with no authoritative idle FPS or production cohort approved.
