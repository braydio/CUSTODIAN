# REVIEW: CODEBASE AUDIT AUTONOMOUS REVIEW RUNNER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-codebase-audit-autonomous-review-runner`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `codebase-audit-autonomous-review-runner`
- Locks: `agent-workflow`
- Review: `none`
- Review target workstream: `codebase-audit-autonomous-review-runner`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md`
- Reviewed main: `7eddb322aca7871a9146fe4e6952fe265039f8cd`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the new paired-review runner's freshness, claim safety, recovery semantics and successor behavior before it becomes the normal review-launch path.
- Reviewed implementation acceptance: Use the archived implementation packet's entire Acceptance contract. Treat a fresh Codex subprocess as necessary but not sufficient: the review must prove exact packet identity, no transcript/session reuse, durable evidence, fail-closed recovery and unchanged finish/dispatcher authority.
- Review evidence: Archived implementation packet/summary; F11 decision lock; runner source/tests; exact subprocess construction; Git-common-directory run evidence; dispatcher/workstream/review-contract tests; synthetic/docs-only rehearsal; changed-file closeout.
- Correction threshold: Any path that can double-claim/spawn, resume implementation context, review the wrong packet/worktree, lose recovery state after Codex failure, mistake process exit 0 for durable review completion, expose credentials, weaken review edit restrictions/cycle caps, couple `workstream.py finish` to Codex availability, or silently hop the global queue is correction-worthy.
- Focused validation: Re-run runner unit/integration fixtures, dispatcher/workstream/review-contract/queue-stranding suites, any bootstrap rehearsal, changed-file validation and `git diff --check`. Inspect a captured launch record to prove `--ephemeral` and exact cwd/prompt boundary without relying only on mocks.
- Review focus: process freshness; dispatcher remains sole claim authority; wrapper-vs-finish separation; preflight timing; subprocess failure recovery; durable summary verification; correction/re-review routing; human/cycle stop; secret/log hygiene; no daemon/queue creep.
- Acceptance: Findings-first fresh review with zero blocking defects/material evidence gaps for pass. Do not modify reviewed implementation. If a bounded correction is required, author the normal correction packet and require its paired re-review to use a fresh external context.
- Non-goals: No game/runtime changes, no general persistent worker, no model/provider redesign, no performance optimization outside measured runner overhead.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d`
- Refresh reason: `none`
- Next action: If passed, make the runner the default paired-review launch path through the already-updated lifecycle instructions; subsequent same-series work continues normally.
- Blockers or open questions: `none`
