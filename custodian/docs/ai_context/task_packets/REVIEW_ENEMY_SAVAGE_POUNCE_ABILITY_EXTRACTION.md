# REVIEW: ENEMY SAVAGE POUNCE ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-enemy-savage-pounce-ability-extraction`
- Kind: `review`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `enemy-savage-pounce-ability-extraction`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `enemy-savage-pounce-ability-extraction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md`
- Reviewed main: `d2ac337e13`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that Savage pounce has one actor-local lifecycle/tuning authority, preserves current rushdown behavior, and reuses the reviewed Marine/Falcon host-service boundary without creating a generic ability hierarchy.
- Reviewed implementation acceptance: Use the archived implementation packet's full acceptance contract after its post-NPA-1 planning refresh. Require equivalent launch band, commitment/contact, one-hit, damage/knockback, recovery/cooldown, interruption/reset, diagnostics and deterministic behavior.
- Review evidence: Archived NPA-2 packet/summary; landed pounce ability/config; `enemy.gd` diff; Savage scene tuning; focused pounce/combat validation; reviewed NPA-1 ability-service seam.
- Correction threshold: Parallel pounce state in `enemy.gd`, tuning/behavior drift, generic ability-base invention, private caller leakage, changed chain behavior, or material proof gaps create bounded correction work.
- Focused validation: Reuse implementation evidence where fresh; rerun the narrow pounce/Savage gate, directly selected combat regressions, changed-file closeout, and `git diff --check`.
- Review focus: one mechanic/one authority; exact tuning parity; host services stay generic; chain remains untouched; validation ownership follows the extracted module; `enemy.gd` shrinks by the removed pounce authority.
- Acceptance: Findings-first fresh-context review with passed receipt or bounded correction pair. Do not patch reviewed implementation code.
- Non-goals: No Savage rebalance, chain extraction, new art, generic ability hierarchy, reaction/loot work, or broad `enemy.gd` cleanup.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: If review materially changes the pounce service/config seam or exposes shared-service drift, bring the evidence back to this chat before NPA-3 is promoted.

## Handoff

- Next action: Keep this paired review blocked/manual until the passed NPA-1 review is brought to the authoring chat and NPA-2 is remeasured and refreshed to ready/auto.
- Blockers or open questions: NPA-1 paired review and NPA-2 planning refresh are pending.
