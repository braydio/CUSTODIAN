# REVIEW: NPA-4 STANDARD ENEMY MELEE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-4-standard-enemy-melee-extraction`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `npa-4-standard-enemy-melee-extraction`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `npa-4-standard-enemy-melee-extraction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_4_STANDARD_ENEMY_MELEE_EXTRACTION.md`
- Reviewed main: `dd61bca01cf7572136aac397993cdc053e83bd3c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove ordinary standard-enemy melee now has one focused lifecycle authority without changing combat feel, special-ability ordering, reaction ownership, spatial truth or procgen variant behavior.
- Reviewed implementation acceptance: Use the archived NPA-4 packet's full Acceptance contract. Require one-owner melee lifecycle/context/recovery state, exact authored timing/contact parity, semantic commitment/cancellation APIs, unchanged shared hit/engagement/presentation ownership, and no silent activation of variant attack_cooldown.
- Review evidence: Archived implementation packet/summary; StandardEnemyMelee/config files/resources; `enemy.gd` diff; Grunt/Marine/Savage/Pursuit bindings; reviewed NPA-3 seam; focused standard-melee smoke; cadence/spatial/commitment/guard/special regressions; changed-file closeout.
- Correction threshold: Any duplicate ordinary-melee mutable state left in `enemy.gd`; changed timing/contact/strong-opening behavior; special-priority regression; reaction/presentation modules mutating melee internals; module ownership of shared hit/target/behavior/reaction systems; changed variant cooldown behavior; attack-ID telemetry drift; Savage chain first-hit regression; or material proof gaps creates bounded correction work.
- Focused validation: Re-run standard melee lifecycle smoke, grunt cadence, spatial telemetry, commitment, guard flow, Falcon, Marine Dash, Savage/NPA-3, variant negative control, changed-file validation and `git diff --check`.
- Review focus: one mechanic/one authority; config parity; semantic commitment/cancel boundaries; host services remain narrow; variant-cooldown non-change; `damage_interval` not misclassified as ordinary melee; no universal combat abstraction.
- Acceptance: Findings-first fresh-context review with zero blocking defects/material evidence gaps for pass. Reviewer does not patch reviewed implementation. Any correction-worthy finding uses bounded correction/re-review lineage.
- Non-goals: No NPA-5 implementation, reaction retune, variant rebalance, special-ability redesign, art/audio work or cross-family convergence.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: After this review passes (including bounded correction/re-review), bring the reviewed ordinary-melee API and remaining reaction/posture/parry-critical state/callers back here. Remeasure NPA-5 rather than pre-authoring against today's private fields.

## Handoff

- Next workstream: `npa-5-enemy-reaction-posture-extraction`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `NPA-5 must be derived from the reviewed ordinary-melee interruption seam and current reaction/posture/parry-critical ownership`
- Next action: Stop autonomous execution after the passed NPA-4 review. Open the Authoring chat and paste `npa-5-enemy-reaction-posture-extraction` for remeasurement and packet authoring.
- Blockers or open questions: `NPA-5 intentionally has no active implementation packet yet`
