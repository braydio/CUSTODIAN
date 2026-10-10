# REVIEW: NPA-6 ENEMY DEATH, CORPSE AND LOOT LIFECYCLE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-6-enemy-death-corpse-loot-extraction`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `npa-6-enemy-death-corpse-loot-extraction`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `npa-6-enemy-death-corpse-loot-extraction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_6_ENEMY_DEATH_CORPSE_LOOT_EXTRACTION.md`
- Reviewed main: `dd17a65e7`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that NPA-6 moved Enemy health and death/corpse lifecycle state behind one focused owner while preserving public combat, loot, reification and host-integration behavior.
- Reviewed implementation acceptance: Use the archived NPA-6 packet's complete Acceptance contract. Require one mutable lifecycle authority, stable Enemy façade APIs without shadow state, exact damage-result/death semantics, single payload transfer and reward, authored config parity, correct corpse cleanup, intact NPA-5 paired-execution host boundary, and validation ownership.
- Review evidence: Archived NPA-6 packet and implementation summary; lifecycle/config source; Enemy façade/callback diff; scene config bindings; corpse loot/carrier components; reification and loot consumers; focused lifecycle, death, paired-execution and changed-file validation reports.
- Correction threshold: Duplicate health/death/corpse state on Enemy; broken damage-result fields/order or lethal paths; repeated death/payload/reward; table-fallback or authored-config drift; invalid collector/reward behavior; cleanup threshold/camera geometry drift; reification API break; NPA-5 damage callback or token regression; lifecycle authority absorbing presentation, BSM or global reward policy; private mutation remaining in tests/callers; or material validation gaps creates bounded correction work.
- Focused validation: Re-run the NPA-6 lifecycle smoke, `lootable_corpse_beacon`, `authored_vault_grunt_loot_marine`, world-simulation actor reification handoff, NPA-5 reaction/parry-critical and paired-execution lethal controls; run changed-file validation and `git diff --check`.
- Review focus: one coherent health/death/corpse owner; facade delegation with no second mutable source; host callbacks and ordering; existing collector/carrier boundaries; typed authored config parity; death observability and paired execution; reification restoration; minimum/offscreen/hard corpse cleanup; no health-system or universal NPC superclass.
- Acceptance: Findings-first fresh-context review with zero blocking defects/material evidence gaps for pass. Record stable cycle-scoped finding IDs and evidence. Correction-worthy findings use normal bounded correction/re-review lineage. Do not patch reviewed implementation.
- Non-goals: No loot economy or balance changes; no corpse art/VFX/audio redesign; no general actor health abstraction; no persistence schema, spawn/wave, Operator death/campaign, or cross-family changes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `npa-7-commanded-ally-contracts-planning`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `NPA-7 has only a roadmap outcome; remeasure reviewed standard-agent lifecycle APIs and real commanded-ally consumers before defining shared contracts.`
- Next action: `After this review passes, stop and refresh NPA-7 planning in the Authoring chat from reviewed live runtime.`
- Blockers or open questions: `NPA-7 implementation boundary remains intentionally unauthored.`
