# REVIEW: CUSTODIAN EXECUTION RESET V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-execution-reset-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-execution-reset-v1`
- Locks: `custodian-execution-reset-review`
- Review: `none`
- Review target workstream: `agent-execution-reset-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_EXECUTION_RESET_V1.md`
- Reviewed main: `94b17d41e34fdf4157f26a254e2943a12eb4aa45`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `The reset changes administrative claim state and lock eligibility; independent review must verify identity preservation and fail-closed behavior.`
- Reviewed implementation acceptance: `Verify every acceptance item in the implementation packet and inspect real before/after evidence without treating a passing test suite as review acceptance.`
- Review evidence: `Source diff; temporary bare-remote race tests; checksummed backup inventory; exact claim/ref/worktree/evidence manifests; dispatcher audit before and after; target feature packet claim and landing evidence.`
- Correction threshold: `Any state that can erase or replace a claim, release a live/ambiguous owner, satisfy review acceptance, bypass a lock collision, or declare missing backup/evidence as preserved is blocking.`
- Focused validation: `Run the implementation packet's exact tests; independently exercise two clones racing quarantine/unquarantine, stale refs and generations, active-owner and unknown-owner cases, duplicate identity, lock collision, and dependency evaluation.`
- Review focus: `Administrative disposition semantics; append-only and CAS behavior; backup completeness; dispatcher identity versus lock occupancy; old-run resume fencing; generation handling; scope of packet reconciliation; evidence that actual feature development proceeded.`
- Acceptance: `Zero blocking findings and no material evidence gaps. Quarantine remains explicitly unresolved and never appears as a review PASS. Verify only exact authorized targets changed.`
- Non-goals: `Applying additional live quarantine transitions; releasing any owner; changing historical verdicts; reviewing or approving the game feature's aesthetics.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Start a fresh reviewer context. Use the exact temporary-remote tests and inspect all durable manifests. Treat cross-host ownership as unknown unless the implementation has an independently verifiable fence. Stop before any extra live transition beyond the exact target listed in the implementation summary.

## Handoff

- Next workstream: `operator-motion-foundry-blender-2d-rig-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Continue the existing claimable visual feature through normal dispatch after reset closeout.
- Blockers or open questions: Any unresolved cross-host owner retains its exact lock; no global unlock is implied.
