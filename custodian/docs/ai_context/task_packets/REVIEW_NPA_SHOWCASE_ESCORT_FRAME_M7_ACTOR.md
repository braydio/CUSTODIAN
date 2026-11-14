# REVIEW Escort Frame M-7 Runtime Actor

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-showcase-escort-frame-m7-actor`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `npa-showcase-escort-frame-m7-actor`
- Locks: `drone-runtime`
- Review: `none`
- Review target workstream: `npa-showcase-escort-frame-m7-actor`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_SHOWCASE_ESCORT_FRAME_M7_ACTOR.md`
- Reviewed main: `b0ff835f8006d5ff6f250e682328512f8aa771d4`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify landed npa-showcase-escort-frame-m7-actor using the actual archived implementation acceptance and real runtime evidence.
- Reviewed implementation acceptance: M-7 and original droid both instantiate; exactly one manager command authority; same target/identity/nav behavior; no unapproved production default replacement; provisional art clearly reported.
- Review evidence: Exact landed implementation commit, archived packet, source and final summary, validation manifest, focused test output, art/source provenance if involved, and measured level/actor screenshots only when necessary.
- Correction threshold: Missing live scene/animation binding; shadowed action/identity/relationship authority; broken actual combat, targeting, death, nav or route; wrong/missing Asset V2 sources; false art completion; inadequate coverage; material acceptance-proof gap.
- Focused validation: new m7_commands_smoke.gd; drone_follower_commands_smoke.gd direct; allied_drone_navigation_walkability, actor_relationship_contract, changed/manifest.
- Review focus: Source-of-truth ownership, authentic actor/scene integration, independent evidence, behavior equivalence, and no test fake.
- Acceptance: Findings-first independent receipt with zero blocking findings and zero material evidence gaps for pass. Use stable cycle R<cycle>-NN IDs and bounded correction/re-review where needed; do not patch the reviewed implementation.
- Non-goals: No opportunistic adjacent fixes, additional actors, global NPC base or reviewer self-approval of subjective art.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff
- Next workstream: `npa-showcase-dev-overlays`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Future reviewed-consumer API reconciliation is execution-agent owned, not a new human design gate.
- Next action: Check actual archived review proof before promoting any successor; retain human gates explicitly.
- Blockers or open questions: Preserve original existing review claims and wait for named archived dependency reviews; do not fabricate a PASS.
