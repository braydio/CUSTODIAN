# Review: Operator Idle Retarget Source-Scope Attestation V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-operator-idle-retarget-source-scope-attestation-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: P0
- Depends on: `agent-operator-idle-retarget-source-scope-attestation-v1`
- Locks: `paired-review-source-provenance`
- Kind: `review`
- Review: `none`
- Review target workstream: `agent-operator-idle-retarget-source-scope-attestation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_OPERATOR_IDLE_RETARGET_SOURCE_SCOPE_ATTESTATION_V1.md`
- Reviewed main: `ea1249ce7059487efe3b61aff0999f18c948ba02`
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Authoring handoff: `auto`
- Goal: Independently verify that the one historical source-scope exception is exact, inert before accepted review, and unable to broaden ordinary source-path validation.
- Completion boundary: Review the attestation implementation and real-Git tests only. Do not inspect or judge animation quality, change the original retarget implementation, or alter the preserved review claim.
- Reviewed implementation acceptance: Verify the attestation's exact source archive, target packet blob, two source blobs/modes, approval ancestry, accepted PASS and receipt. Verify rejection before approval and for any identity/path/blob/mode/receipt mismatch. Confirm the old review's pinned SHA/claim remain unchanged and the source span admits no other path.
- Review evidence: Pinned source archive and tree, correction diff, temporary-Git positive and negative tests, exact attestation bytes, canonical correction review receipt, preserved original host-validation recovery evidence.
- Correction threshold: Any path broadening, self-authorizing JSON, bypass of ordinary source-scope checks, wrong historical identity, invalid/missing accepted review proof, or modification of the preserved original implementation/review is blocking.
- Focused validation: Run the source-scope attestation unit tests and `paired_review_runner_unit`; independently inspect source identity and test history construction; verify the pre-approval host validator still rejects the original paths and post-approval recovery plan records only the exact two hashes.
- Acceptance: Record genuine PASS or structured findings. A PASS only authorizes the preserved review's host-validation recovery; it is not the preserved review's technical verdict and is not animation approval.
- Non-goals: No source implementation changes, no animation changes, no dispatcher-policy changes, no visual/art judgment, no main-runtime changes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff
- Next action: On accepted PASS, resume `review-operator-3d-neutral-idle-retarget-fix-v1` using its exact preserved run and a fresh host-recovery plan; otherwise stop with findings.
- Blockers or open questions: none

## Next Handoff
- Next workstream: `review-operator-3d-neutral-idle-retarget-fix-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Refresh reason: none
- Next action: Resume the preserved Task 015 review after the exact scope attestation correction is independently accepted.
- Blockers or open questions: none
