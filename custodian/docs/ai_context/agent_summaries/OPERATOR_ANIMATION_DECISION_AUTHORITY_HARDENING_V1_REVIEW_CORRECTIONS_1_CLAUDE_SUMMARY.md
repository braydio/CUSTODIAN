# Operator Animation Decision Authority Hardening V1 — Correction 1

## Result

Closed review findings R0-01 and R0-02 for `operator-animation-decision-authority-hardening-v1-review-corrections-1`.

Timing approval persistence now sits in a narrow UI writer called from the active Workbench confirmation button event. `WorkbenchService` can preview and consume a one-use hash-bound timing preview but no longer has an approval-writing helper. The writer rechecks the selected animation identity, saved manifest/document/plan/profile/reference hashes, and physical timing before atomically persisting and immediately revalidating the decision. The existing backup and rollback behavior is preserved.

The Textual pilot exercises the actual Preview and Confirm controls. It first proves direct service preview/consume leaves both the manifest authority flag and decision receipt absent, then verifies the button flow writes a current exact-identity decision. The receipt smoke separately verifies the service-only negative path, performs a real Godot sandbox pass before current-receipt and family controls, and proves a stalled Godot child produces a finite actionable failure with stale result files removed.

The cold-worktree timeout was caused by project import/startup preceding the smoke, not a hanging sandbox. The recipe now routes through `run_validation.py --test operator_2_5d_review --json`, which runs the manifest import preflight. The sandbox subprocess retains its 90-second deadline and returns captured output and a durable failure result on timeout.

## Validation and recovery notes

- Textual UI pilot: passed, including `PASS TIMING UI FLOW` and all subsequent live-bridge layer-adoption assertions.
- `run_validation.py --test operator_2_5d_review --json`: passed with real Godot sandbox evidence.
- `run_validation.py --changed --json`: 40 selected, 40 passed, 0 failed, 0 timed out, complete coverage.
- `git diff --check`: passed.
- Two initial test issues were corrected in-scope: the pilot had temporarily redirected the shared service root and thereby altered later live-bridge expectations; the timing smoke expected `TIMING APPROVAL STALE` even though no approval record existed. The fixture now redirects only the decision root, and the no-record status remains `PREVIEW TIMING` while consuming a changed-input preview fails.
- Godot import produced `custodian/tools/validation/npa_showcase_existing_enemy_smoke.gd.uid`; it was removed as unrelated generated output and is not part of this change.

No physical animation workspace was available. The eight saved animation records remain untouched; 8 FPS remains preview-only and no timing was approved. No art publication, runtime promotion, or cohort activation occurred.

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: Two fixture assertions failed before the isolated receipt-root and absent-versus-stale expectation were corrected.
- Root cause / contributing factors: Shared mutable test service state and a regression expectation that conflated missing authority with invalidated authority.
- Prevention / pipeline improvement: Scope test overrides to the one output root they need; distinguish absent decision state from a stale persisted decision.
- Tooling / docs drift discovered: Cold worktrees require Godot import before this renderer smoke; the validation recipe now invokes the import-aware runner. Its manifest-owner mapping selected 40 changed-file tests; all passed.
- Follow-up: fixed-in-scope
- What worked: Real UI interaction, current hash verification, renderer evidence, and timeout behavior are independently exercised.

## Next Handoff

- Next workstream: `review-operator-animation-decision-authority-hardening-v1-review-corrections-1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: Launch the fresh paired post-land review and verify the actual UI event boundary, real sandbox/receipt evidence, timeout diagnostics, and preserved unapproved art state.
- Blockers or open questions: none
