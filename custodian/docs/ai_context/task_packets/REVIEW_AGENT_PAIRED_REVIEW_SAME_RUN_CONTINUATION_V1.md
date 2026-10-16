# REVIEW AGENT PAIRED REVIEW SAME-RUN CONTINUATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-same-run-continuation-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-same-run-continuation-v1`
- Locks: `agent-workflow`
- Review: `none`
- Review target workstream: `agent-paired-review-same-run-continuation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_SAME_RUN_CONTINUATION_V1.md`
- Reviewed main: `4a88985f8b6d3c2f56c45b147d527c7288c57af9`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify exact-claim reviewer continuation against old-run integrity, original reviewer disposition, Codex sandbox confinement and coordinator-only review closeout.
- Reviewed implementation acceptance: All ten numbered implementation requirements, including explicit fresh-context authorization rather than falsely resuming `--ephemeral`, exact-run fencing, no new claims, byte-preservation, independent verdict, idempotence and failure recovery.
- Review evidence: Source diff against pinned main; literal original `post_exit_recovery` metadata/claim contract; temporary synthetic Git common-dir/worktree + branch fixture; existing `test_paired_review_runner.py`, `review_receipt_delta.py`, `workstream.py`; immutable protected ambient run specification; Godot cache-access reviewed seam.
- Correction threshold: Any chance of writing PASS on coordinator JSON alone; lost original notes, altered review target, new dispatcher claim, unbounded git mutation, stale/wrong claim, duplicate reviewer or receipt, unverified summary move, bypass of existing Code review gate, or an absent real reviewer disposition is blocking.
- Focused validation: Existing paired-review-runner tests extended to reject forged metadata, wrong branch/worktree, mismatched implementation, already-completed and ambiguous phases, duplicate run, noncanonical summary, unauthorized changes; mock real Codex subprocess launch and coordinator closeout with fault injection; run unaffected delta/finish/cache tests and changed-file validation.
- Review focus: Independent code archaeology of provenance and branch pinning; test the original `--ephemeral` context loss; reviewer-only authorship of disposition; no `--no-godot-lock`; no shared .git write; preserve original run evidence and dirty persistent checkout. Distinguish successful continuation from mere green coordinator reports.
- Acceptance: Findings-first fresh-context review with zero blocking defects/material gaps and the full exact review receipt only if all guards and fault tests pass. If runtime continuation cannot safely be authorized, record findings and leave protected run unclaimed by a new dispatcher and unpassed.
- Non-goals: No editor/runtime procgen changes, no reviewer-fabricated PASS, no generic orphan branch parking or altering Godot cache ownership.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Publication Gate
- Do not claim until implementation completes/archives and targeted authoring promotion confirms ready/auto on current main. The ambient review remains a distinct protected run and does not automatically pass when this tool passes.

## Next Handoff
- Next workstream: `review-procgen-ambient-real-world-spawn-recovery-v1`
- Next packet state: `preserved-claimed-recovery`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `operator must explicitly authorize new fresh reviewer context inside original preserved run; original ephemeral session is not resumable`
- Next action: `Use the independently reviewed same-run continuation tool only on original ambient run ID 20261015T224943Z-5a721f81880e; obtain authentic independent reviewer disposition; then coordinator-owned bounded closeout.`
- Blockers or open questions: `Do not mark ambient review passed from coordinator validation alone.`
