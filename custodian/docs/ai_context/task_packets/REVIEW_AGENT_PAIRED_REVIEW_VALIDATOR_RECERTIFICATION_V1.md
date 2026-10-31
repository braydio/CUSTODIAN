# REVIEW: Trusted Review Validator Recertification V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-validator-recertification-v1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-paired-review-validator-recertification-v1`
- Locks: `workstream-finish-sync-provenance`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review target workstream: `agent-paired-review-validator-recertification-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_VALIDATOR_RECERTIFICATION_V1.md`
- Reviewed main: `ad42f092761ed222b8da2fb0d41a61388f70d5fc`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the new finish-time provenance guard and certify the complete current source-span validator behavior under a fresh review identity.
- Reviewed implementation acceptance: Verify every item in the archived implementation packet, including rejection before publication of an unwitnessed merge, exact lifecycle binding and durable finish-generated evidence, preserved single/multiple-merge behavior, source-path ownership, and unchanged historical findings.
- Review evidence: Reuse the implementation's real-Git finish fixtures and canonical validation report. Independently inspect `paired_review_host_validation.py`, `workstream.py`, `workflow_control.py`, their relevant tests, and the original R0-01 record by its verified hashes. Recompute merge ancestry and deterministic trees in disposable repositories; do not use missing historical events as positive evidence.
- Correction threshold: Create correction work only for a confirmed defect or material acceptance-proof gap in this new implementation. Do not create a correction merely to recover the old historical trace. Record cycle-scoped findings truthfully.
- Focused validation: Run `python3 -m unittest custodian.tools.agent.test_workstream -v`; `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; canonical changed-file validation; targeted packet/category checks; and `git diff --check`. Add independent adversarial real-Git probes only where the durable implementation evidence does not establish an acceptance claim.
- Review focus: Inspect the full current `_split_landing_source_span` implementation and related witness helpers, not just the implementation diff. Verify one- and multi-merge event cardinality/order, exact workstream/run/branch/worktree and parent/tree identities, inherited versus authored paths, no-op and checkpoint/resume forms, post-archive constraints, and fail-closed behavior for absent/forged/reordered evidence. Confirm `finish` blocks unwitnessed source history before pushing/landing and publishes genuine sync evidence before landing. Ensure no code or receipt implies the old R0-01 is passed or that Procession is unblocked.
- Acceptance: Produce a findings-first fresh-context independent review. Record a canonical `passed` receipt or concrete findings. PASS only when the new producer guard and the complete current validator behavior satisfy the archived implementation acceptance and all required validation is complete. Do not edit implementation code. Do not alter or apply any historical recovery plan, release a protected claim, or reclassify old evidence.
- Non-goals: No implementation changes; no historical recovery, event reconstruction, validator redesign, lock release, Procession continuation, or approval of any unrelated workstream.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Start in a fresh reviewer context after implementation completion and reconstruct the task from the archived packet, source, tests, and durable evidence.
2. Independently inspect the full source-span verifier and trace producer; do not accept the implementation summary as proof.
3. Verify the new pre-push positive and negative real-Git cases and falsify missing, reused, malformed, reordered, wrong-parent, and wrong-tree evidence.
4. Confirm the original multi-sync review remains unresolved with R0-01 and that no protected claim, lock, run artifact, or recovery plan was modified.
5. Record the actual review outcome and close only this new review through its ordinary lifecycle.

## Next Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Refresh reason: `none`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Next action: `After this new review is accepted, re-audit all existing review dependencies and claims read-only; do not infer eligibility or continue Procession automatically.`
- Blockers or open questions: `The old multi-sync, coverage-correction, and Procession review claims remain unresolved independently of this review.`
