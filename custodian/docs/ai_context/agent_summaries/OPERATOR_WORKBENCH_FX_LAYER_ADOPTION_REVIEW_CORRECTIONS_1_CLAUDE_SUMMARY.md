# Operator Workbench FX Layer Adoption — R0-01 Correction

## Result

Closed the REPLACE source-conflict window identified by review finding `R0-01`. Publication now records each source's expected preimage hash, then rechecks both the live source and its transaction backup immediately before replacement. A mismatch aborts the transaction. The journal records whether a source was swapped by this transaction.

Rollback now removes a source only while its bytes still match the transaction output. It restores the old source using a no-overwrite hard link, and only when the transaction actually removed its original path. If an external writer changed the source, rollback preserves those bytes and marks the transaction `RECOVERY_REQUIRED` with the affected canonical path.

## Evidence

- Added a deterministic REPLACE interleaving control that mutates canonical FX after the `PREPARED` journal is written, after initial freshness validation and source backup. Publication rejects it; previously swapped body sources are restored, external FX bytes remain exact, and the journal identifies the unresolved FX source.
- Added a downstream-failure control that mutates FX after the transaction swap. Rollback preserves the external bytes instead of deleting or replacing them, restores other transaction-owned sources, and records `RECOVERY_REQUIRED` for the external path.
- Existing CREATE/REPLACE success and failure, collision refusal, explicit mirror CREATE/REPLACE, and transaction rollback cases remain green.
- `operator_workbench_mirror_publish_smoke.py`: PASS.
- `operator_animation_workbench_smoke.py`: PASS.
- Changed-file validation: 6 selected, 6 passed, 0 failed, 0 timed out, 0 skipped, 0 infrastructure errors (`/tmp/operator-workbench-fx-correction-validation-final.json`), including review-pairing and visual-review handoff checks.
- Task-packet contract unit suite: 23 tests passed; isolated correction/re-review pairing metadata check passed.
- Python compilation and `git diff --check`: PASS.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The first two claim attempts encountered another agent's active local dispatcher lock; bounded retry succeeded without disturbing that claim.
- Root cause / contributing factors: Dispatcher assignment-critical operations share one local lock.
- Prevention / pipeline improvement: Used the documented bounded lock wait; no workflow change needed.
- Tooling / docs drift discovered: none.
- Follow-up: `review-operator-workbench-fx-layer-adoption-review-corrections-1`
- What worked: Test hooks exercise both conflict timing and rollback ownership using byte-level assertions and transaction journal state.

## Next Handoff

- Next workstream: `review-operator-workbench-fx-layer-adoption-review-corrections-1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: `none`
- Next action: Claim the paired fresh-context review and verify both interleaving regressions against the source-swap/rollback implementation.
- Blockers or open questions: `none`
