# Operator Animation Decision Authority Hardening V1 Review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38

## Findings

### R0-01 — Service helper calls mint timing approval without a Workbench action

- Class: blocking_defect
- Domain: implementation
- Affected acceptance: D, H, I
- Evidence: `custodian/tools/operator/ui/service.py:790-809` and `:818-860` expose `_preview_timing_decision_from_ui()` and `_confirm_timing_decision_from_ui()` as ordinary callable service methods. From an isolated fixture I called those two methods directly with valid saved-input fixtures and obtained `APPROVED TIMING`; `timing_approval_status()` then returned `APPROVED TIMING`. The generated record labels the action `workbench_explicit_user` / `timing-preview-confirm`, but those labels are assigned by the same service method and do not prove the UI observed a user action. The fixture positive path therefore proves a caller can mint the exact authority receipt without invoking the UI. This contradicts the packet's explicit requirement that generic service callers cannot invoke approval and its review focus against arbitrary service helper dispositions.
- Disposition: correction
- Rationale: This permits a non-UI service caller or agent helper to promote preview timing, the exact authority crossing the implementation is intended to prevent. Bind the commit to an unforgeable in-process UI intent capability/event path that cannot be supplied by an arbitrary service caller, and add a negative regression that invokes service-level methods without that capability.

### R0-02 — Required current-receipt/Godot sandbox regression does not complete

- Class: evidence_gap
- Domain: implementation
- Affected acceptance: C, D, I
- Evidence: `python3 custodian/tools/validation/operator_2_5d_review_smoke.py` reached `Operator2DReview.run_sandbox()` and raised `subprocess.TimeoutExpired` after its 90-second Godot invocation (`custodian/tools/operator/operator_2_5d_review.py:519`). The rerun reproduced the timeout; therefore the required positive sandbox and later altered-request controls did not finish, and the smoke's downstream current-receipt/family assertions did not execute. The environment has `/usr/bin/godot`, but this task's headless sandbox scene did not exit within the timeout. The eight-direction ignored Workbench root at `/home/braydenchaffee/Projects/CUSTODIAN/.ai/operator_animation_workbench/operator_2_5d_128/unarmed/posture/idle_relaxed_01` is absent, so no live saved manifests/documents could be checked. This review did not create or alter any physical art claims.
- Disposition: correction
- Rationale: The packet requires an independently reproducible positive/negative end-to-end current receipt after passing QA and sandbox, and the existing smoke fails before reaching its final timing-gating assertions. Resolve the sandbox timeout or provide an equivalent bounded smoke that actually executes those assertions; retain the explicit live-art-unavailable statement unless the physical workspace becomes available.

## Verified evidence

- Landed target commit: `0a0238920a87de637ab281ea484bd8781eee8169`; reviewed main head: `0e3cfa940`.
- Passed: `operator_animation_timing_smoke.py`, `operator_2_5d_ingress_smoke.py`, `operator_animation_targets_smoke.py`, `operator_workbench_production_queue_smoke.py`, `operator_workbench_ui_smoke.py` (optional Textual pilot skipped because its dependencies are absent), `check_ai_context.py`, `task_packet_index.py`, and `git diff --check` for the landed target diff.
- `run_validation.py --changed --json` returned passed with zero changed files and zero selected tests; it supplies no implementation test evidence in this clean review worktree.
- `validate_review_pairing.py` could not run because it attempts `git fetch --prune origin` and the shared git metadata is read-only in this managed review context (`FETCH_HEAD: Read-only file system`).
- Existing ignored artist workspaces were inspected read-only; the exact eight-direction 2.5D path above is unavailable. No timing values were selected, no physical art was changed, and no publication/runtime files were changed.
- `git diff --check` on the target landed diff passed.

## Verdict

Findings. The timing record remains hash-bound to current inputs and legacy timing remains compatible in the passing focused smoke, but the caller boundary is not enforced and the required sandbox/current-receipt proof is incomplete. Do not treat the historical eight idle Workbenches as timing-approved; this review made no human timing decision.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the required Godot sandbox smoke timed out, and repository pairing validation could not fetch because shared git metadata was read-only.
- Root cause / contributing factors: sandbox execution remained open after 90 seconds; this environment's managed filesystem permits writing the worktree but denies writing shared FETCH_HEAD.
- Prevention / pipeline improvement: provide a bounded no-hang sandbox smoke path and a validation mode that consumes already-fetched refs without forcing fetch in restricted review worktrees.
- Tooling / docs drift discovered: none confirmed.
- Follow-up: operator-animation-decision-authority-hardening-v1-review-corrections-1
- What worked: isolated fixtures exposed that service helper invocations can mint an approval without UI interaction.

## Next Handoff
- Next workstream: operator-animation-decision-authority-hardening-v1-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none; create a bounded correction packet from R0-01 and R0-02.
- Next action: author and dispatch the R0-01/R0-02 correction implementation and paired review through the normal packet workflow.
- Blockers or open questions: The corrected service intent boundary and reproducible sandbox/current-receipt evidence must be re-reviewed before this feature passes.
