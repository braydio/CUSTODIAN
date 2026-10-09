# REVIEW: NPA-5 ENEMY REACTION / POSTURE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-5-enemy-reaction-posture-extraction`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `npa-5-enemy-reaction-posture-extraction`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `npa-5-enemy-reaction-posture-extraction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_5_ENEMY_REACTION_POSTURE_EXTRACTION.md`
- Reviewed main: `8817908b1f32a26893785536a9d81ba053ea12c5`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove NPA-5 removed reaction/posture and critical-opportunity mutable state from `enemy.gd` into two focused authorities without changing hit taxonomy, melee/special interruption, paired execution, presentation, or health/death ownership.
- Reviewed implementation acceptance: Use the archived NPA-5 packet's complete Acceptance contract. Require a real two-authority split rather than one new reaction god-object; exact reaction/parry tuning and timing; stable Enemy façade APIs; zero private test mutation; and an intact NPA-6 health/death boundary.
- Review evidence: Archived NPA-5 packet/summary; `EnemyReactionController`/config; `EnemyParryCritical`/config; `enemy.gd` diff; scene config bindings; presentation hook changes; reaction/posture smoke; parry-critical/Falcon/guard/commitment/Savage/Marine/StandardEnemyMelee regressions; changed-file closeout.
- Correction threshold: Duplicate mutable reaction/parry state left in `enemy.gd`; one oversized controller swallowing presentation/health/special behavior; moved or changed `stagger_damage_threshold` semantics; reaction timing/posture/Marine resistance drift; special-commit interruption drift; public paired-execution API break; token/owner/damage-once regression; root/frame/Falcon-Reversal regression; health/death/corpse state moved into parry authority; presentation state owned by simulation; direct private test mutation; or material proof gaps creates bounded correction work.
- Focused validation: Re-run the new reaction/posture smoke, StandardEnemyMelee, commitment, guard flow, Grunt parry-critical, Falcon Reversal, debug spawn modes, Savage pounce/chain/runtime, Marine Dash and lethal/nonlethal paired-execution controls; changed-file validation and `git diff --check`.
- Review focus: one mechanic family / focused owners; ReactionController versus ParryCritical responsibility; hit classifier remains upstream; public façade compatibility; fixed-step priority; semantic cancellation; presentation/health boundaries; no universal NPC abstraction.
- Acceptance: Findings-first fresh-context review with zero blocking defects/material evidence gaps for pass. Reviewer does not patch reviewed implementation. Correction-worthy findings use normal bounded correction/re-review lineage.
- Non-goals: No NPA-6 implementation, corpse/loot redesign, Operator riposte/guard changes, reaction rebalance, VFX/art changes, special-ability redesign or cross-family convergence.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: After this review passes (including bounded correction/re-review), bring the reviewed reaction/parry-critical APIs and the then-current health/death/corpse/loot ownership back here. Remeasure NPA-6 from landed runtime instead of freezing today's life-state/private corpse fields.

## Handoff

- Next workstream: `npa-6-enemy-death-corpse-loot-extraction`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `NPA-6 must be derived from reviewed NPA-5 interruption/critical-execution boundaries and current health/death/corpse/loot ownership`
- Next action: Stop autonomous execution after the passed NPA-5 review. Open the Authoring chat and paste `npa-6-enemy-death-corpse-loot-extraction` for remeasurement and packet authoring.
- Blockers or open questions: `NPA-6 intentionally has no active implementation packet yet`
