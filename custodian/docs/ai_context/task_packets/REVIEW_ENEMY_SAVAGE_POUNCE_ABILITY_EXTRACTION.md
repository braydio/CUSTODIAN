# REVIEW: ENEMY SAVAGE POUNCE ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-enemy-savage-pounce-ability-extraction`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `enemy-savage-pounce-ability-extraction`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `enemy-savage-pounce-ability-extraction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md`
- Reviewed main: `c8615e22a85337a5190f50df8587684793da322e`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that Savage pounce has one actor-local lifecycle/tuning authority, preserves current rushdown behavior, and reuses the reviewed Marine/Falcon host-service boundary without creating a generic ability hierarchy.
- Reviewed implementation acceptance: Use the refreshed archived implementation packet's full acceptance contract. Independently prove exact 13-field tuning parity, six-field runtime-state removal, pounce-before-chain ordering, fixed-step/cooldown behavior, launch/contact/one-hit/damage/impact/recovery semantics, cancellation/non-cancellation behavior, typed diagnostics, and zero parallel pounce authority.
- Review evidence: Archived NPA-2 packet/summary; landed pounce ability/config; `enemy.gd` diff; Savage scene tuning; focused pounce/combat validation; reviewed NPA-1 ability-service seam.
- Correction threshold: Parallel pounce state in `enemy.gd`, tuning/behavior drift, generic ability-base invention, private caller leakage, changed chain behavior, or material proof gaps create bounded correction work.
- Focused validation: Reuse implementation evidence where fresh; rerun the narrow pounce/Savage gate, directly selected combat regressions, changed-file closeout, and `git diff --check`.
- Review focus: one mechanic/one authority; exact typed config parity; actor keeps only the pounce enable toggle and generic shared services; ability owns cooldown plus phase/contact state; host integration uses reviewed Marine/Falcon service boundaries without a generic base; chain state/tuning is byte/behavior unchanged; presentation priority asks the ability instead of stale actor fields; validation ownership follows the module; stale NPA-1 ownership prose is corrected; `enemy.gd` shrinks by the removed pounce authority.
- Acceptance: Findings-first fresh-context review with passed receipt or bounded correction pair. Do not patch reviewed implementation code.
- Non-goals: No Savage rebalance, chain extraction, new art, generic ability hierarchy, reaction/loot work, or broad `enemy.gd` cleanup.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: After this review passes, bring the landed pounce ability/config API, review receipt, current Savage chain ownership, and any correction-cycle changes back to this chat before promoting NPA-3. If review finds a material pounce/service-boundary change, keep NPA-3 blocked/manual.

## Handoff

- Next action: Auto-dispatch after `enemy-savage-pounce-ability-extraction` lands.
- Blockers or open questions: none.
