# REVIEW: AGENT PAIRED REVIEW ADVANCED HEAD PASS CLOSEOUT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-advanced-head-pass-closeout-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-paired-review-advanced-head-pass-closeout-v1`
- Locks: `paired-review-advanced-head-pass-closeout`
- Review: `none`
- Review target workstream: `agent-paired-review-advanced-head-pass-closeout-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_ADVANCED_HEAD_PASS_CLOSEOUT_V1.md`
- Reviewed main: `f76854cf22aece96701bb17da14580df6ce879a2`
- Authoring chat: `not-recorded`
- Authoring handoff: `auto`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the exact-run advanced-HEAD recovery can accept only authentic reviewer PASS evidence and land it without rewriting or losing preserved history.
- Reviewed implementation acceptance: Verify every acceptance item in the archived implementation packet, especially exact run/evidence identity, PASS authorship, complete commit ancestry through `94e2a8c7`, bounded artifact changes, target receipt provenance, stale-plan rejection, and race-safe landing.
- Review evidence: Focused positive/negative tests using temporary repositories/remotes; exact plan digest and apply journal; source diff; parser and receipt-verifier results; preserved original run/worktree/branch identities; proof no protected state was mutated by synthetic tests.
- Correction threshold: Any way to infer PASS from validation alone, accept contradictory/malformed reviewer evidence, omit a run hash or ancestry edge, include unapproved commit paths, reuse a stale plan, overwrite another ref, mutate original run evidence, or report accepted review before coordinator verification is blocking.
- Focused validation: Re-run `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v` and dedicated advanced-head cases; independently inspect plan/apply locking and race checks; verify ordinary continuation still rejects advanced local HEAD; verify no force/reset/rebase/delete behavior was introduced; inspect complete changed-file coverage and closeout preflight.
- Review focus: Findings-first inspection of whether reviewer-authored PASS is independently bound to raw session evidence, exact run hashes, pinned target identity, prior target receipt, and the preserved local commit; whether retry/crash/race behavior stays fail-closed; whether this remains exact-run-only rather than becoming a general parser or continuation relaxation.
- Acceptance: Zero blocking findings and zero material evidence gaps. Produce a fresh-context independent passed receipt or stable cycle-scoped findings. Do not execute the historical recovery or apply a live parking transition during this review.
- Non-goals: Re-reviewing the parking implementation itself, completing the historical recovery, authoring a replacement reviewer decision, or changing protected branches/worktrees/run artifacts.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Use `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`. Start from a fresh reviewer context after the implementation lands. Use isolated temporary Git repositories for mutation/race tests. Stop before executing the exact historical recovery; that requires its own fresh plan and separately authorized apply.
