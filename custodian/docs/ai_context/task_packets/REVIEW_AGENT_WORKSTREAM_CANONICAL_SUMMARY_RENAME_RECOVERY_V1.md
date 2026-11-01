# REVIEW: Canonical summary rename lifecycle recovery

- Packet schema: `custodian.task_packet.v2`
- Authoring handoff: auto
- Workstream: review-agent-workstream-canonical-summary-rename-recovery-v1
- Category: agent-ops
- Kind: review
- Status: `draft`
- Dispatch: `manual`
- Priority: P0
- Depends on: agent-workstream-canonical-summary-rename-recovery-v1
- Locks: workstream-canonical-summary-rename-recovery
- Review: none
- Review target workstream: agent-workstream-canonical-summary-rename-recovery-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_CANONICAL_SUMMARY_RENAME_RECOVERY_V1.md
- Reviewed main: f38d7f405014960072e10feeb93f339e1ba7067e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, workflow
- Review cycle: 0
- Max automatic review cycles: 0
- Review rationale: The producer and consumer must independently authenticate one exact administrative rename between archival and normal landing. Any broader post-archive allowance could bypass source-span, evidence or review protections.
- Goal: Independently verify that the landed lifecycle recovery accepts only the byte-identical canonical summary rename and leaves all other archive, source-span, sync, after-sync, reviewer and teardown checks fail-closed.
- Reviewed implementation acceptance: Verify exact two-path rename topology, old/new regular-file modes, identical Git blob and bytes, unchanged archived packet, canonical destination derivation, one-rename maximum, direct parent order, independent producer/consumer authentication, full adversarial coverage, canonical validation identity/digest, finish trace and teardown.
- Review evidence: Reconstruct from the archived implementation packet, exact source diff, real-Git test fixtures, canonical reports and immutable workstream trace. Treat implementation summary as a claim, not proof.
- Correction threshold: Create a correction only for a confirmed overbroad acceptance, missing falsification, altered existing exception, source-scope violation, incomplete validation or non-genuine lifecycle evidence. Automatic review cycles remain zero.
- Focused validation: Run the declared producer and consumer real-Git regressions; inspect the exact accepted commit chain and negative controls; verify canonical changed-file coverage, report digest, finish/after-sync trace and safe teardown.
- Review focus: Confirm no arbitrary summary creation or metadata change is accepted, no changed summary bytes or extra paths are admitted, no existing RC-119/historical exception changed, and a reviewer can authenticate the lineage from Git objects and the normal trace independently of producer claims.
- Acceptance: Record one authentic findings-first outcome: passed, findings or `human_required`. Pass only if exact scope, positive/negative controls, canonical validation, finish and teardown all verify. Otherwise preserve the claim/lock and report the exact failed invariant. Do not edit reviewed implementation.
- Non-goals: Do not alter the reviewed implementation, timeout implementation, P0, Operator, Ritualant, historical review outcomes or unrelated claims. Do not synthesize a review outcome, bypass source-span/after-sync/landing gates, or authorize arbitrary post-archive edits.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after implementation landing, archive and canonical checkout teardown.
2. Start in a fresh reviewer context; independently reconstruct the exact rename from Git objects and the archived packet.
3. Exercise the real-Git positive chain and every declared adversarial control; verify producer and consumer agree without trusting shared outcome claims.
4. Verify complete canonical validation, exact report digest, source identity, after-sync witness, main reachability and teardown.
5. Record an authentic outcome and finish through the ordinary paired-review lifecycle; no automatic correction cycle is allowed.

## Handoff

- Next workstream: `validation-paired-review-runner-time-budget-v1`
- Next packet state: `dependency-gated until this review accepts`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Refresh reason: `none`
- Next action: Resume the existing timeout claim only after this review records an authentic pass.
- Blockers or open questions: `none`
