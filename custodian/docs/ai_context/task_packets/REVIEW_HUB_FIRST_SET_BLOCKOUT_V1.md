# REVIEW: HUB FIRST SET BLOCKOUT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-first-set-blockout-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `hub-first-set-blockout-v1`
- Locks: `hub-runtime, hub-layout`
- Review: `none`
- Review target workstream: `hub-first-set-blockout-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_FIRST_SET_BLOCKOUT_V1.md`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the landed Hub first-set blockout is one coherent, navigable spatial authority from South Reach through Forum/branches to Crown Transfer and Continuity Port, without smuggling in campaign/Twin/world-transition behavior.
- Review focus: exact coordinate contract; Road presentation reused without competing Road collision; first-set grid as sole blockout walkability authority; full connectivity and >=4-cell route width; valid named markers/spawns; production map free of Operator/camera ownership; inert lifecycle markers; minimal human overview approval; truthful Hub docs.
- Acceptance: Produce a findings-first post-land review. Pass only if the blockout matches `HUB_FIRST_SET_BLOCKOUT.md`, structural/navigation evidence is green, the recorded human overview approval remains valid, and no H2-H6 behavior leaked into H1. Blocking findings must use the normal bounded correction/re-review flow.
- Non-goals: Do not implement Awakening handoff, Contract prewarm, Twin traversal, Continuity Port deployment, Campaign return, production art, or layout redesign during review.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Checks

1. Recompute every envelope, connector, marker, world bound, grid origin, and grid size against `HUB_FIRST_SET_BLOCKOUT.md`.
2. Verify `Spawn_SouthReach=(-6,162)` is the exact Road-local transform of Awakening's current completion point.
3. Verify all five Road module images retain current local positions/sizes and no second copy of their coordinate truth was invented when a read-only source API was available.
4. Verify Road legacy `CollisionRoot`/`BLOCKER_RECTS` are not active Hub-first-set physical authority.
5. Verify grid/boundary collision and navigation have one connected walkable component.
6. Verify all mandatory route bottlenecks are at least 4 cells/128px.
7. Verify a real Operator can traverse the standalone playtest from South Reach to Forum, Garden loop, Crown Transfer, and CampaignExitThreshold.
8. Verify production Hub map owns neither Operator nor gameplay camera.
9. Verify AdjudicationDais/CrownTransfer/ContinuityPort/CampaignExitThreshold remain inert markers.
10. Verify no `WorldContractBootstrap` call, `game.tscn` handoff, `hub_twin_solaria` load, or world transition was introduced.
11. Reuse the implementation's single full-map overview and durable human approval. Do not perform a second subjective model-vision approval unless implementation changed relevant geometry after that gate.
12. Verify documentation describes only H1 as live and leaves H2-H7 deferred.

## Human Decision Gate

If the user rejects the blockout overview because macro topology, scale, or branch readability feels wrong, mark `human_required` rather than rationalizing the existing coordinates. Spatial taste at this scale is a design decision.

## Handoff

- Next action: after pass, author/execute H2 Awakening -> Hub context handoff against the reviewed spawn/layout API.
- Blockers or open questions: blocked only by `hub-first-set-blockout-v1`.
