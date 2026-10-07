# CORRECTION: OPERATOR WORKBENCH FX LAYER ADOPTION REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-fx-layer-adoption-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-workbench-fx-layer-adoption`
- Locks: `operator-workbench-publish`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, asset-pipeline, workflow`
- Paired review workstream: `review-operator-workbench-fx-layer-adoption-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `1e62ce7e2ff5dec8e1c76cff1850715f5a1e89dd`
- Parent implementation: `operator-workbench-fx-layer-adoption`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md`
- Parent review: `review-operator-workbench-fx-layer-adoption`; `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md`
- Findings addressed: `R0-01`
- Affected acceptance: Refuse publication if the canonical FX source changes after adoption; preserve canonical bytes on rollback.
- Current defect/evidence: `animation_workbench.publish` checks source freshness before export and transaction setup, then uses an unchecked `os.replace` for REPLACE. A source update in the interval is overwritten; transaction backup may capture that concurrent update and rollback semantics are not tied to the adopted baseline.
- Goal: Prevent Workbench REPLACE publication from overwriting a canonical source changed after its adopted baseline was recorded.
- Completion boundary: Close the source-conflict window from the last freshness check through canonical replacement and rollback, with a deterministic interleaving regression.
- Current measured state: CREATE publication uses an atomic no-overwrite hard-link operation. REPLACE publication does not revalidate the adopted hash when swapping its target.
- Evidence: Parent review finding `R0-01`; `custodian/tools/operator/animation_workbench.py` source freshness, backup, and source-swap path; `custodian/tools/validation/operator_workbench_mirror_publish_smoke.py` changed-source controls.
- Task-specific authority: Archived implementation packet `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md`; design `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; review finding `R0-01`.
- Work surface: `custodian/tools/operator/animation_workbench.py`; focused transactional regression in `custodian/tools/validation/operator_workbench_mirror_publish_smoke.py` or a narrowly scoped companion fixture.
- Required correction: Revalidate the exact REPLACE preimage at the source-swap boundary using the adopted contract and ensure a changed target is never overwritten. Keep rollback from restoring over an external concurrent replacement. Persist sufficient journal state to distinguish transaction-owned changes from external changes.
- Preserve: Existing CREATE collision refusal; successful CREATE/REPLACE; direct-only default and opt-in mirror; runtime generation/import/resource rollback; saved-layer adoption authority and Workbench behavior.
- Non-goals: Do not redesign Workbench publication, add other layer adoption, change gameplay or art, or broadly alter transaction architecture beyond the source-conflict guarantee.
- Acceptance:
  - `R0-01`: A deterministic fixture mutates the canonical REPLACE source after initial freshness validation but before source replacement; publication refuses, preserving the external bytes and recording an unambiguous transaction outcome.
  - `R0-01`: A downstream failure after the transaction has replaced a source restores the original adopted bytes, while a separately injected external replacement is never deleted or overwritten by rollback.
  - Existing CREATE collision, successful REPLACE, REPLACE rollback, and mirrored transaction fixtures remain green.
- Validation: Run `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`, `python3 custodian/tools/validation/operator_animation_workbench_smoke.py`, and smallest changed-file validation with complete coverage. Run `git diff --check`.
- Task overrides: `none`
- Deferred: Parent review finding `R0-02` (modular-defense smoke emits unrelated project/resource diagnostics) remains a separately deferred validation-harness reliability issue.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The first two claim attempts encountered another agent's active local dispatcher lock; bounded retry succeeded without disturbing that claim.
- Root cause / contributing factors: Dispatcher assignment-critical operations share one local lock.
- Prevention / pipeline improvement: Used the documented bounded lock wait; no workflow change needed.
- Tooling / docs drift discovered: none.
- Follow-up: `review-operator-workbench-fx-layer-adoption-review-corrections-1`
- What worked: The transaction journal now records expected source hashes and swap ownership; deterministic interleavings cover both conflict detection and rollback preservation.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The publisher rechecks each REPLACE source against the adopted baseline and backup immediately before source mutation; rollback removes only bytes still matching the transaction output and restores source backups without overwriting occupied paths. `operator_workbench_mirror_publish_smoke.py` injects a source change after transaction preparation and another after source swap, verifies external bytes survive, verifies other swapped sources restore, and requires explicit `RECOVERY_REQUIRED` journal evidence. Existing CREATE/REPLACE/mirror cases pass. Changed-file validation selected 6 checks and passed all 6 with 0 failures, timeouts, skips, or infrastructure errors; the task-packet contract suite passed 23 tests.

## Handoff

- Next action: Run the paired fresh-context review of correction `R0-01`.
- Best starting files: this archived correction packet, `custodian/tools/operator/animation_workbench.py`, and `custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`.
- Blockers or open questions: none.

## Next Handoff

- Next workstream: `review-operator-workbench-fx-layer-adoption-review-corrections-1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none`
- Next action: `Run the paired fresh-context review and report R0-01 as fixed or unresolved.`
- Blockers or open questions: `none`
