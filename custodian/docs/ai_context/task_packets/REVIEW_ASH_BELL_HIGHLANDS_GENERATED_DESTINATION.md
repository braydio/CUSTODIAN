# REVIEW: ASH-BELL HIGHLANDS — GENERATED DESTINATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-ash-bell-highlands-generated-destination`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `ash-bell-highlands-generated-destination`
- Locks: `ash-bell-highlands, procgen-region-profile`
- Review: `none`
- Review target workstream: `ash-bell-highlands-generated-destination`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ASH_BELL_HIGHLANDS_GENERATED_DESTINATION.md`
- Reviewed main: `435c422d6cb5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the registered Highlands generated destination against its archived contract.
- Reviewed implementation acceptance: Verify deterministic generated-region activation, required route beats/spawns, explicit frame selection, local-biome independence, scale, and cross-seed variation.
- Review evidence: Archived packet/summary; live Highlands definition/profile/intent output; deterministic snapshots from multiple fixed seeds.
- Correction threshold: Only confirmed acceptance defects or material proof gaps become corrections; subjective environment-art taste is deferred to BF6/human review.
- Focused validation: Re-run the landed Highlands smoke, BF1 generated-region lifecycle proof, `res://tools/validation/procgen_intent_graph_smoke.gd`, and `res://tools/validation/procgen_region_frame_smoke.gd`.
- Review focus: Hidden starting-region mutation, biome->frame inference, missing required terminal/reveal, seed instability, generated spawn invalidity, or route-node lifecycle divergence.
- Acceptance: Findings-first fresh review with stable IDs; do not patch reviewed runtime.
- Non-goals: Do not implement bridges, north egress, art or Lower Quarter integration.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff
- Next workstream: `ritualant-north-egress-and-chapel-vista`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: BF3 must use reviewed live Highlands entry/spawn behavior and preserve the locked Ritualant presentation.
- Next action: Bring BF2 review evidence to the authoring chat and refresh BF3.
- Blockers or open questions: none unless review finds a correction-worthy defect.
