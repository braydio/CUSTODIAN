# REVIEW Broken Warrant Runtime Actor

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-showcase-broken-warrant-actor`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `npa-showcase-broken-warrant-actor`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `npa-showcase-broken-warrant-actor`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_SHOWCASE_BROKEN_WARRANT_ACTOR.md`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify landed npa-showcase-broken-warrant-actor using the actual archived implementation acceptance and real runtime evidence.
- Reviewed implementation acceptance: Scene instantiates without parse errors, attacks using existing authority, can be parried and killed once, valid corpse loot once, observability and collision work, no mandatory placeholder falsely called finished art.
- Review evidence: Exact landed implementation commit, archived packet, source and final summary, validation manifest, focused test output, art/source provenance if involved, and measured level/actor screenshots only when necessary.
- Correction threshold: Missing live scene/animation binding; shadowed action/identity/relationship authority; broken actual combat, targeting, death, nav or route; wrong/missing Asset V2 sources; false art completion; inadequate coverage; material acceptance-proof gap.
- Focused validation: new npa_broken_warrant_smoke.gd; standard_enemy_melee, enemy_reaction_posture, grunt_parry_critical, lootable_corpse_beacon, scene/manifest/changed checks.
- Review focus: Source-of-truth ownership, authentic actor/scene integration, independent evidence, behavior equivalence, and no test fake.
- Acceptance: Findings-first independent receipt with zero blocking findings and zero material evidence gaps for pass. Use stable cycle R<cycle>-NN IDs and bounded correction/re-review where needed; do not patch the reviewed implementation.
- Non-goals: No opportunistic adjacent fixes, additional actors, global NPC base or reviewer self-approval of subjective art.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff
- Next workstream: `npa-showcase-escort-frame-m7-actor`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: normal live-main API remeasurement
- Next action: Check actual archived review proof before promoting any successor; retain human gates explicitly.
- Blockers or open questions: none
