# REVIEW: AGENT BOUNDED TASK CONTEXT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-bounded-task-context-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `agent-bounded-task-context-v1`
- Locks: `agent-workflow`
- Review: `none`
- Review target workstream: `agent-bounded-task-context-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_BOUNDED_TASK_CONTEXT_V1.md`
- Reviewed main: `2ffbbec13d55a939096750d059602ea56047cae3`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify Agent Bounded Task Context V1 against the landed code and all numbered implementation acceptance items.
- Reviewed implementation acceptance: 1) Given a claimed packet fixture, card names exact packet, SHA/dirty truth, authoring URL, owners and scoped files without consulting unrelated root summaries; 2) output is bounded/deterministic with explicit truncation and selective expansion; 3) stale packet after upstream fetch is rejected/marked stale; 4) user-authored AGENTS and relevant required source is still reachable and changes invalidate cache; 5) no context/secret disclosure from untrusted packet paths or arbitrary expand input; 6) one fixture simulates >1k irrelevant summaries without increasing output; 7) Next skill no longer has an unconditional repository-wide `rg` or `cat CURRENT_STATE.md` route.
- Review evidence: Two-run fixture payload size measurements, exact SHA/line-range card, modified skill, unknown/dirty/secret negative fixtures.
- Correction threshold: Missing authority, false claim, stale source reported current, sensitive data output or unbounded fallback search requires correction.
- Focused validation: Focused temporary repo test_task_context.py fixtures for exact workstream resolution, AGENTS hash invalidation, multiple packets, dirty checkout, private paths, truncation, pagination and repeat output; task packet parser/dispatch contract regressions; check_ai_context.py --json, pairing and index, run_validation.py --changed --base origin/main --json, git diff --check.
- Review focus: Confirm navigation-only output never impersonates authority, no stale cache, no arbitrary source leaks, real decrease in emitted context while all required references remain accessible.
- Acceptance: Produce a findings-first fresh-context review of exact landed SHA with stable R0-NN IDs for material defects/gaps, bounded corrections and repeat review where required. Complete/archive only this review packet and permitted evidence; never edit implementation.
- Non-goals: No redesign, no implementation fixes during review, no bypass of lifecycle/validation/user gates.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after exact implementation is archived complete on origin/main.
2. Start from fresh independent context with exact archived packet, implementation summary and original accepted SHA; do not carry implementer transient reasoning.
3. Review both positive and negative cases, status/claim/provenance gates and original acceptance contract; reuse immutable evidence only where valid.
4. Record evidence-based R0-NN findings/receipt, complete within bounded review override, never edit reviewed implementation.

## Handoff

- Next workstream: `agent-validation-evidence-freshness-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After accepted review, follow named next workstream if eligible under the invocation budget; otherwise stop with the exact successor.`
- Blockers or open questions: `none`
