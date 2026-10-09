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
- Reviewed main: `current-main-at-claim`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that Savage's two-hit chain has one actor-local lifecycle/tuning authority, preserves exact two-hit cadence/guard pressure and pounce-first ordering, and leaves generic ordinary melee deliberately available for NPA-4.
- Reviewed implementation acceptance: Use the archived refreshed NPA-3 packet's entire Acceptance contract. Require six-value chain config parity, three-field runtime-state removal, exact first/second timing/damage/guard pressure, current target-at-hit-time semantics, current generic cadence/contact ownership, pounce-first priority, interruption/commitment behavior, typed diagnostics and zero parallel actor chain state.
- Review evidence: Archived implementation packet/summary; landed `SavageChain`/config/default resource; `enemy.gd` diff; Savage scene binding; NPA-2 review receipt/pounce regression; focused chain/guard/combat/spatial validation; validation-manifest ownership.
- Correction threshold: Parallel chain phase state in `enemy.gd`, copied generic melee contact/cadence tuning in the chain config, first-hit/base-damage drift, chain timing/damage/guard-pressure drift, changed target capture semantics, pounce-priority regression, interruption/commitment regression, accidental generic-melee extraction, direct private hit-gateway reachback, generic ability-base invention, or material proof gaps create bounded correction work.
- Focused validation: Re-run typed chain-equivalence smoke, Savage runtime presentation priority, NPA-2 pounce regression, directly selected guard/spatial/combat controls, changed-file closeout and `git diff --check`.
- Review focus: one mechanic/one authority; six chain-only config values only; three mutable runtime fields only; host retains generic cadence/first-hit/contact authority; pounce untouched and first priority; validation no longer reaches actor-private chain fields; `enemy.gd` loses complete Savage special phase machines.
- Acceptance: Findings-first fresh review with zero blocking defects/material evidence gaps for pass. Reviewer does not patch reviewed implementation; correction-worthy findings use normal bounded correction/re-review lineage.
- Non-goals: No ordinary melee extraction, Savage rebalance, new art, pounce rewrite, Operator guard refactor, reactions/loot work, generic ability hierarchy, or speculative NPA-4 implementation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: After this review passes (including any bounded correction/re-review), bring the reviewed final chain API, the remaining ordinary melee state/callers and current `enemy.gd` shape back to this conversation before authoring/promoting NPA-4.

## Handoff

- Next workstream: `npa-4-standard-enemy-melee-extraction`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `NPA-4 must be derived from the reviewed NPA-3 seam and the then-current ordinary melee ownership rather than frozen from today's actor layout`
- Next action: Stop autonomous execution after passed NPA-3 review. Open the Authoring chat and paste `npa-4-standard-enemy-melee-extraction` for remeasurement and packet authoring.
- Blockers or open questions: `NPA-4 intentionally has no active implementation packet yet`
