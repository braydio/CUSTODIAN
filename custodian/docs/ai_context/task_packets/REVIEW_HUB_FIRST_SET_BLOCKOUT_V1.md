# REVIEW: HUB FIRST SET BLOCKOUT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-first-set-blockout-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `hub-first-set-blockout-v1-recovery-1`
- Locks: `hub-runtime, hub-layout`
- Review: `none`
- Review target workstream: `hub-first-set-blockout-v1-recovery-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_FIRST_SET_BLOCKOUT_V1.md`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the landed Hub first-set blockout is one coherent, navigable spatial authority from South Reach through Forum/branches to Crown Transfer and Continuity Port, without smuggling in campaign/Twin/world-transition behavior.
- Review focus: exact coordinate contract including both Sepulcher connectors; Road presentation reuse with no competing Road collision; first-set grid authority; raw and real-Operator-clearance connectivity; literal Sepulcher circulation loop rather than same-neck backtracking; >=4-cell authored width; valid markers/spawns including Campaign return in the Port west bay; no Operator/camera ownership in production map; inert lifecycle markers; human overview approval; truthful docs.
- Acceptance: Produce a findings-first post-land review. Pass only if the blockout matches `HUB_FIRST_SET_BLOCKOUT.md`, structural/navigation evidence is green, the recorded human overview approval remains valid, and no H2-H6 behavior leaked into H1. Confirm the obsolete active H1 implementation branch/worktree/claim is gone and the preserved donor history remains reachable; lifecycle-only `agent-diagnostics/*` traces are non-executable evidence and are preserved under repository policy. Blocking findings must use the normal bounded correction/re-review flow.
- Non-goals: Do not implement Awakening handoff, Contract prewarm, Twin traversal, Continuity Port deployment, Campaign return, production art, or layout redesign during review.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Checks

1. Recompute every envelope, connector, marker, world bound, grid origin, and grid size against `HUB_FIRST_SET_BLOCKOUT.md`.
2. Verify `Spawn_SouthReach=(-6,162)` is the exact Road-local transform of Awakening's current completion point.
3. Verify all five Road module images retain current local positions/sizes and no second copy of their coordinate truth was invented when a read-only source API was available.
4. Verify Road legacy `CollisionRoot`/`BLOCKER_RECTS` are not active Hub-first-set physical authority.
5. Verify grid/boundary collision and navigation have one connected walkable component.
6. Verify both locked Sepulcher connectors exist and one proof enters through one and exits through the other without requiring the first.
7. Verify >=4-cell authored widths, then re-prove mandatory routes against a clearance view derived from the actual Operator collision shape and active boundary rails.
8. Verify a real Operator can traverse South Reach → Forum → both directions around the Garden loop → Crown Transfer → CampaignExitThreshold.
9. Verify production Hub map owns neither Operator nor gameplay camera.
10. Verify `Spawn_CampaignReturn=(2592,-3008)` is the Continuity Port west return bay, and AdjudicationDais/CrownTransfer/ContinuityPort/CampaignExitThreshold remain inert markers.
11. Verify no `WorldContractBootstrap` call, `game.tscn` handoff, `hub_twin_solaria` load, or world transition was introduced.
12. Reuse the implementation's single full-map overview and durable human approval. Do not perform a second subjective model-vision approval unless implementation changed relevant geometry after that gate.
13. Verify documentation describes only H1 as live and leaves H2-H7 deferred.
14. Audit H1 branch hygiene from current remote truth. Confirm the obsolete active `agent/hub-first-set-blockout-v1` implementation branch, attached worktree, and any live dispatch claim are absent; verify the preserved donor checkpoint/archive remains reachable. Treat `agent-diagnostics/*` refs as lifecycle-only preserved evidence per `branch_hygiene.py`, not as executable branches or cleanup blockers.

## Human Decision Gate

If the user rejects the blockout overview because macro topology, scale, or branch readability feels wrong, mark `human_required` rather than rationalizing the existing coordinates. Spatial taste at this scale is a design decision.

## Handoff

- Next action: after pass, H2 remains `ready/auto` and becomes claimable automatically once both its declared reviews are archived complete.
- Blockers or open questions: none beyond declared dependency completion; no manual queue refresh is required.
