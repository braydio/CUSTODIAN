# Paired-review archived receipt capture recovery

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-archived-receipt-capture-recovery-v1`
- Category: `agent-ops`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-dual-disposition-recovery-v1, agent-paired-review-redacted-final-outcome-recovery-v1`
- Locks: `agent-paired-review-archived-receipt-capture-recovery`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-archived-receipt-capture-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: A coordinator-only recovery will represent an already recorded independent PASS in the missing archived receipt location. Exact-run identity, reviewer provenance, capture transformation, byte preservation and canonical closeout require a fresh independent review.
- Reviewed main: `a696aef8d5aff23e9f2a477c85f1f792da6dcd02`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ea54-f98c-83ea-8582-3ef5bd595199
- Visual review: `none`
- Goal: Safely close an exact paired-review run when the existing canonical reviewer PASS and target receipt are authenticated but the archived packet is missing only its matching Independent Review receipt.
- Completion boundary: Add a read-only exact-run plan and separate explicitly authorized apply that mirrors the already authenticated receipt into the archived packet with clear coordinator provenance, preserves all reviewer evidence, and lands through canonical review closeout. The implementation and its independent review must not apply recovery to the protected run; that requires a later exact-run control.
- Current measured state: At `a696aef8d5aff23e9f2a477c85f1f792da6dcd02`, protected review `review-agent-paired-review-dual-disposition-recovery-v1`, run `20261031T005522Z-c70dd87f67a4`, claim `20261031T005536Z-066de2554c75`, has one completed fresh reviewer turn and an identity-bound canonical PASS outcome in the archived review packet. The target implementation packet's reviewer receipt passes the unchanged canonical receipt-delta validator. The archived packet has no Independent Review receipt; coordinator finish stops with `existing target receipt differs from the archived independent-review receipt`. Its 1,243-character `last-message.txt` and 1,200-character JSONL event match exactly under the source-pinned `safe_output()` transformation. Original reviewer worktree, claim, lock and evidence are preserved. No recovery apply is authorized by this packet.
- Evidence: `custodian/tools/agent/paired_review_runner.py` (`_verify_redacted_final_capture`, `_verified_reviewer_pass`, `coordinator_finish_review`); `custodian/tools/agent/workflow_control.py` (`redact`); `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; preserved host-local evidence at `.git/custodian-review-runs/review-agent-paired-review-dual-disposition-recovery-v1/20261031T005522Z-c70dd87f67a4/` (do not modify or apply against it during this workstream).
- Task-specific authority: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/dispatch.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`.
- Work surface: Primary owner `custodian/tools/agent/paired_review_runner.py`; regression tests in `custodian/tools/agent/test_paired_review_runner.py`; narrowly scoped lifecycle documentation in `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_review_outcome.py`; `custodian/tools/agent/test_paired_review_findings_closeout.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`.
- Change:
  1. Reuse the existing source-pinned capture verifier. Require exact equality to its deterministic sanitized/truncated output; never accept arbitrary prefixes or unapproved truncation.
  2. Verify one completed fresh reviewer turn, exact run/workstream/claim/branch/worktree/target/main/implementation identities, canonical PASS outcome, target receipt via the unchanged canonical validator, host validation, source hashes, original evidence manifests and the held-lock/process/ref state.
  3. Require the missing archived Independent Review receipt to be the sole remaining acceptance-artifact discrepancy. Reject a present, malformed, contradictory or different receipt and any second outcome, finding, error or verdict in available session evidence.
  4. Add a read-only exact-run plan bound by SHA-256 to every inspected reviewer artifact, source identity, claim, lock, path, local/remote ref and intended output. Add a distinct apply requiring explicit authorization and the exact plan digest, with immediate revalidation before the first write.
  5. Preserve original reviewer files byte-for-byte. Derive the archived receipt only from the authenticated canonical PASS and already validated target receipt. Label the mirror coordinator-authored administrative evidence, bind its provenance to the plan and original artifact hashes, and leave the reviewer-authored Review Outcome unchanged.
  6. Journal bounded, fail-closed, idempotent operations. Reject replay under a different plan; changed evidence, source transform, claim, lock or refs; unsafe paths/symlinks; incomplete validation; missing coverage; and interruption states that cannot be proven safe.
  7. Use existing canonical coordinator finish, landing, claim-release and teardown gates only after rechecking all outcomes and receipts. Do not launch another reviewer for the protected run.
  8. Correct the first-run reviewer prompt: treat the active review packet and target as inputs, not a not-yet-created archived packet; require the reviewer to create both canonical matching receipt locations on completion, while preserving independent judgment and non-PASS outcomes.
  9. Add positive and negative synthetic regressions and a narrow lifecycle note. Do not modify protected host-local evidence.
- Preserve: Every original run and reviewer artifact byte; reviewer-authored canonical Review Outcome and target receipt; exact protected claim, lock, branch and worktree; strict global receipt/outcome validation; all other protected reviews and unrelated local work; ordinary reviewer judgment and canonical finish paths.
- Non-goals: Applying recovery to run `20261031T005522Z-c70dd87f67a4`; accepting the original review during implementation or review; launching another reviewer for it; changing reviewer evidence, historical reports, claims, branches, worktrees or locks; weakening global canonical validation; expanding queue or cleanup scope.
- Acceptance:
  1. A read-only exact-run plan proves the source-pinned capture transformation and exact reviewer/session/claim/target identities, all immutable evidence hashes, the existing canonical PASS, the target receipt, lock/ref/process state, and that only the archived receipt is absent.
  2. Missing, malformed, contradictory, forged or wrong-run outcome/receipt evidence fails closed. The canonical target receipt validator remains unchanged.
  3. Apply requires explicit `--apply` and the exact fresh plan digest, rechecks all pinned facts, preserves every original byte, writes only the plan-authorized coordinator-labeled mirror and journal, and is idempotent for the same completed plan.
  4. Forged/replayed/contradictory PASS, tampered final output or JSONL, changed sanitizer source, unapproved truncation, wrong claim/run/target/main, missing validation/coverage, changed refs/lock, unsafe paths, interrupted journals, alternate receipts, early claim release and teardown are rejected by tests.
  5. The reviewer prompt requests both matching receipt locations while treating the archive as an output that may not yet exist. Tests prove no verdict bias and no extra reviewer launch for this recovery.
  6. Canonical finish and landing remain the only closeout authorities. No protected apply, relaunch, claim/lock release or worktree teardown occurs during implementation or its paired review.
  7. Focused suites, canonical changed-file validation with complete coverage, packet authoring/category checks, and `git diff --check` pass.
- Validation: Run `python3 -m unittest custodian.tools.agent.test_paired_review_runner custodian.tools.agent.test_review_outcome custodian.tools.agent.test_paired_review_findings_closeout -v`; inspect all recovery tests; run canonical changed-file validation using `custodian/tools/validation/run_validation.py --changed --base <implementation-parent> --json`; run targeted task-packet authoring and category checks before packet publication; run `git diff --check`. Use synthetic temporary repositories for recovery apply tests only. Never invoke plan/apply against the protected run in this workstream.
- Task overrides: `none`
- Deferred: Exact-run recovery plan/apply requires a separate later coordinator control after this implementation has landed and its fresh-context paired review passes. The host-local evidence owner must then run the read-only plan and submit its exact digest for separate apply authorization. Any missing or changed evidence remains a hard stop.

## Context Pack

- Repomix: `none`
- Purpose: The work surface is bounded to the existing paired-review runner, its tests and lifecycle authority.
