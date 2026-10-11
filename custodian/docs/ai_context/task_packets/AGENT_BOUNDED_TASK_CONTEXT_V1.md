# AGENT BOUNDED TASK CONTEXT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-bounded-task-context-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-agent-next-execution-boundary-v1`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-bounded-task-context-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Independent fresh-context review required for high-impact pipeline safety and resource-use changes`
- Reviewed main: `2ffbbec13d55a939096750d059602ea56047cae3`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Goal: Stop Codex from repeatedly flooding its context with full repository-wide queue search and massive authority-document dumps while preserving accurate task/AGENTS authority and fresh independent review.
- Completion boundary: Add a compact read-only task-context summary generated from the claimed packet and immutable blob hashes, and update the existing CUSTODIAN Next skill to use bounded retrieval; retain direct source reads when a decision requires them.
- Current measured state: The 2026-10-11 Codex log includes `rg` across all root *_CLAUDE_SUMMARY.md Next Handoffs, large dispatcher status text, and `cat AGENTS.md; cat custodian/AGENTS.md; cat CURRENT_STATE.md; cat <packet>`, leading to truncated tool output. Existing `scripts/ai/pack-context.sh` builds opt-in Repomix scope packs and root AGENTS already tells linked worktrees to avoid redundant code-review graph indexing. The global original AGENTS first-read hierarchy is still mandatory and must not be bypassed.
- Evidence: Uploaded 90,686-line 2026-10-11 conversation; `.agents/skills/custodian-next/SKILL.md`; `scripts/ai/pack-context.sh`; root and custodian AGENTS; CURRENT_STATE.md, FILE_INDEX.md; dispatch.py audit/last-claim, task_packet_contract.py, paired_review_runner.py.
- Task-specific authority: Packet and AGENTS source documents remain binding; only task_packet_contract.py/dispatch.py provide packet and claim truth. Bounded loader is a navigation view, not an alternate authority parser or a substitute for source evidence.
- Work surface: Create `custodian/tools/agent/task_context.py` plus focused fixture tests; adjust `.agents/skills/custodian-next/SKILL.md` and minimal documentation for bounded query conventions. Reuse scripts/ai/pack-context.sh when a packet explicitly needs a context pack.
- Change: Add `task_context.py --workstream <id> --json` (or --packet canonical path) that reads only the named on-disk task packet in a verified claimed worktree and emits a bounded navigation card: exact workstream/authoring-chat, source SHA and dirty-tree evidence, semantic Goal/Acceptance/Validation/Handoff fields, relevant design/runtime paths derived from explicit Evidence/Authority/Work surface, local repository AGENTS rules index, direct source blob IDs, current claim state and next named handoff. Display short line-range guidance and 1-pass digests not entire documents. Enforce total output size/line caps with explicit truncation counters and `--expand <whitelisted-path>:<start>:<end>` bounded drilldown; never embed full historical closing-summary corpus. Within one agent session, cache unchanged reference doc headings by blob SHA only; a new fresh reviewer context independently reads required authority. Update Next skill to query dispatcher audit JSON only for queue discrepancies, status filtered/head-limited for routine work and exact archive summary only. No broad root grep or unconditional CURRENT_STATE full dump on routine claims; mandatory AGENTS rules may be read in sections but not skipped or claimed read when not read.
- Preserve: AGENTS and design authority ordering, exact claim identity, V2 asset authoring docs, independent reviewer reads, read-only behavior, deterministic output, no workspace modifications and no sensitive environment/secret-file extraction.
- Non-goals: No blanket replacement of task packets with AI summaries, no generated-model context embeddings, no broad Repomix pack for every task, no new vector database and no changes to gameplay.
- Acceptance: 1) Given a claimed packet fixture, card names exact packet, SHA/dirty truth, authoring URL, owners and scoped files without consulting unrelated root summaries; 2) output is bounded/deterministic with explicit truncation and selective expansion; 3) stale packet after upstream fetch is rejected/marked stale; 4) user-authored AGENTS and relevant required source is still reachable and changes invalidate cache; 5) no context/secret disclosure from untrusted packet paths or arbitrary expand input; 6) one fixture simulates >1k irrelevant summaries without increasing output; 7) Next skill no longer has an unconditional repository-wide `rg` or `cat CURRENT_STATE.md` route.
- Validation: Focused temporary repo test_task_context.py fixtures for exact workstream resolution, AGENTS hash invalidation, multiple packets, dirty checkout, private paths, truncation, pagination and repeat output; task packet parser/dispatch contract regressions; check_ai_context.py --json, pairing and index, run_validation.py --changed --base origin/main --json, git diff --check.
- Task overrides: `none`
- Deferred: CRG rebuilds, vector search, global documentation compression and automatic context pruning across independent Codex model sessions.

## Handoff

- Next workstream: `review-agent-bounded-task-context-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After completed implementation landing/archival, initiate this exact independent fresh-context paired review.`
- Blockers or open questions: `none`
