# REVIEW: ENEMY SAVAGE CHAIN ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-enemy-savage-chain-ability-extraction`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `enemy-savage-chain-ability-extraction`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `enemy-savage-chain-ability-extraction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md`
- Reviewed main: `d2ac337e13`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that Savage's two-hit chain has one actor-local lifecycle/tuning authority, preserves existing two-hit cadence and guard pressure, and leaves reviewed pounce ownership plus ordinary generic melee untouched.
- Reviewed implementation acceptance: Use the archived implementation packet's full acceptance contract after its post-NPA-2 planning refresh. Require equivalent first/second hit order, gap/second windup, damage, guard-stamina request, recovery/interruption/reset, attack identity, diagnostics and deterministic fixed-step behavior.
- Review evidence: Archived NPA-3 packet/summary; landed chain ability/config; `enemy.gd` diff; Savage scene tuning; focused chain/guard/combat validation; reviewed NPA-1/NPA-2 service seams.
- Correction threshold: Parallel chain state in `enemy.gd`, tuning/cadence/guard-pressure drift, pounce regression, accidental generic-melee extraction, generic ability-base invention, or material proof gaps create bounded correction work.
- Focused validation: Reuse fresh implementation evidence; rerun the narrow chain/guard/Savage gate, directly selected combat regressions, changed-file closeout, and `git diff --check`.
- Review focus: one mechanic/one authority; exact chain semantics; pounce untouched; ordinary melee still deferred; validation ownership follows the module; after review, Marine Dash, Savage pounce and Savage chain phase machines are all outside `enemy.gd`.
- Acceptance: Findings-first fresh-context review with passed receipt or bounded correction pair. Do not patch reviewed implementation code.
- Non-goals: No ordinary melee extraction, Savage rebalance, new art, Operator guard refactor, reactions/loot work, or generic ability hierarchy.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Refresh instruction: If review materially changes the chain/service boundary, bring the evidence back to this chat before NPA-4 is authored.

## Handoff

- Next action: This review becomes ready/auto only when the refreshed NPA-3 implementation is ready/auto and later lands.
- Blockers or open questions: reviewed NPA-2 must first unlock and refresh NPA-3.