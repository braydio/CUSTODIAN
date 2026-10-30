# Review: Paired-review redacted final-outcome recovery

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-redacted-final-outcome-recovery-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `agent-paired-review-redacted-final-outcome-recovery-v1`
- Locks: `agent-paired-review-redacted-final-outcome-recovery`
- Kind: `review`
- Review: `none`
- Review target workstream: `agent-paired-review-redacted-final-outcome-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_REDACTED_FINAL_OUTCOME_RECOVERY_V1.md`
- Reviewed main: `09b09ee30727242f69c0d6aeb617b97795f9868a`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae29a85-767c-83ea-90bd-eebcc4b1f086
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that exact-run redacted-final recovery cannot misidentify, fabricate, or weaken a paired-review outcome and cannot mutate preserved reviewer evidence.
- Reviewed implementation acceptance: Verify every acceptance claim in the implementation packet. Falsify capture transformation mismatches, unknown source versions, forged/replayed/contradictory verdicts, bad claim/run/target/source-span identity, missing evidence/coverage, incomplete session metadata, changed remote refs/locks, path escapes, and post-plan tampering. Confirm the apply is distinct from plan, requires exact digest authorization, preserves original bytes, writes a labeled coordinator-authored administrative outcome, and closes through the canonical finish gate.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_review_outcome.py`; `custodian/tools/agent/test_paired_review_findings_closeout.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`.
- Review evidence: Fresh implementation commit and exact diff; all recovery regression tests and canonical coverage report; existing `paired_review_runner.py`, `workflow_control.py`, `review_outcome.py`, `review_receipt_delta.py`, `paired_review_host_validation.py`, and lifecycle tests. Use synthetic run fixtures for destructive/adversarial tests. Do not apply recovery to host-private or protected review runs.
- Correction threshold: Any acceptance from a prefix-only match, unpinned transform, reviewer message alone, host validation alone, altered/missing receipt, missing contradictory-evidence scan, changed claim/ref, mutable reviewer artifact, mislabeled administrative outcome, or bypassed finish gate is blocking. Any recovery apply or protected claim/lock mutation during review is blocking.
- Focused validation: Run `python3 -m unittest custodian.tools.agent.test_paired_review_runner custodian.tools.agent.test_review_outcome custodian.tools.agent.test_paired_review_findings_closeout -v`; inspect every new positive and negative test; inspect the exact changed-file coverage report; verify no protected run directory, reviewer worktree, claim, branch, or lock was modified.
- Review focus: Reconstruct the contract from the archived implementation packet, pinned reviewed-main sources, source diff, tests, and exact plan/apply artifacts. Treat redacted operational logs as transformed capture; do not equate them with raw reviewer text. Verify the only accepted administrative outcome is a byte-preserving, independently corroborated reconciliation for the exact plan/run.
- Acceptance: Record a canonical findings-first fresh-context verdict. PASS only if all implementation acceptance claims and adversarial cases hold, the validation report is complete, and no recovery was applied. Never accept the original protected review or launch a reviewer for either protected run as part of this review.
- Non-goals: Execute a recovery plan/apply; accept or close any protected review; launch another reviewer for either held run; modify reviewer evidence, historical reports, target receipt, claims, branches, worktrees, or locks.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only its durable review receipt, review packet lifecycle/archive metadata, required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure
1. Claim only after the implementation lands complete and the dispatcher confirms this exact review is eligible.
2. Start a fresh independent context and reconstruct the target from the archived packet, exact commit, source-pinned capture contract, tests, and validation evidence.
3. Run focused suites and inspect all recovery gates, positive fixtures, adversarial tests, ref/lock checks, and byte-preservation assertions.
4. Record PASS or concrete cycle-scoped findings; do not run plan/apply against protected host evidence.
5. Close through the canonical paired-review lifecycle.

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae29a85-767c-83ea-90bd-eebcc4b1f086
- Refresh reason: `none`
- Next action: After a PASS review, await a separate coordinator decision before applying recovery to any preserved run.
- Blockers or open questions: The host-private target evidence remains external to Git and must be inspected only by its owner-controlled local workflow.
