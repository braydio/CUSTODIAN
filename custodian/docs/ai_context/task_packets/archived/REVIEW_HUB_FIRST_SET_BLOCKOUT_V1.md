# REVIEW: HUB FIRST SET BLOCKOUT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-first-set-blockout-v1`
- Kind: `review`
- Status: `complete`
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
- Reviewed main: `96532b7807d789666c95675782c04d6fb5aea1c7`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Authoring chat: `not-recorded`
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

- Next workstream: `hub-awakening-context-handoff`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: H2 becomes auto-claimable after `review-awakening-handoff-readiness-art-convergence-v1` also archives complete; claim H2 then and reconcile its seams against current main.
- Blockers or open questions: H2 remains dependency-gated on the Awakening handoff-readiness review.

## Review Result

- Outcome: `passed`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed on main: `96532b7807d789666c95675782c04d6fb5aea1c7`
- Review modes: `code, architecture, runtime, visual`
- Findings: `R0-01, R0-02` (both `non_blocking_issue`, disposition `deferred`)
- Focused evidence: `hub_first_set_blockout` passed (13,142 walkable cells; 52 boundary rails; 14 markers; 12,160 clearance-safe cells at 25px); `road_of_witnesses_production` passed; `twin_solaria_runtime` passed; a headless real-Operator input traversal passed 7,559 physics frames across South Reach, both directions of the Garden loop, Crown Transfer, Muster, and the Port exit; remote branch/worktree/claim inspection passed; donor tag peels to `720185d45930ff6603bd051676f3ff7cb20a655d`; the existing 2048x2048 overview and recorded 2026-10-05 human approval were reused.
- Review conclusion: `HUB_FIRST_SET_BLOCKOUT.md` coordinates and all 14 marker positions match the runtime layout. The grid and derived rails are the single collision/navigation authority; Road's five registered plate pairs remain presentation-only in this host. Raw/clearance topology and live Operator traversal cover both Garden directions and the required Crown/Muster/Port route. The production map contains no Operator, camera, active interactables, transition handlers, Contract bootstrap, Twin load, or world transition. Current docs leave H2-H7 lifecycle behavior deferred. The obsolete H1 branch, attached implementation worktree, and H1 dispatch claim are absent; the donor archive remains reachable. The recovery diagnostic ref is preserved lifecycle evidence per branch policy. No blocking defect or material evidence gap remains.
- Follow-up workstream: `none` (R0-01 is deferred test-hardening advice; R0-02 is carried into H2's claim-time documentation refresh; no correction packet is required).

### Findings

- `R0-01` — `non_blocking_issue`, disposition `deferred`, area `validation`: the H1 smoke verifies each marker node and walkability against `HubFirstSetLayout.MARKERS`, but the expected dictionary is the same authority under test. It locks only selected marker coordinates independently. All 14 current values were manually compared with `HUB_FIRST_SET_BLOCKOUT.md` in this review. Consider independent expected-value assertions for every marker so future drift is caught automatically.
- `R0-02` — `non_blocking_issue`, disposition `deferred`, area `documentation`: `CONTEXT.md`, `CURRENT_STATE.md`, and the H1 roadmap still say the paired review is next or awaiting completion. This review packet's narrow Task Override limits review edits to its receipt, packet lifecycle/archive metadata, and summary, so those broader authority docs were not changed. H2 already owns a claim-time refresh; it should reconcile those lifecycle sentences while keeping H2-H7 runtime behavior deferred.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The first explicit claim found a malformed override on the stale root checkout; after the requested pull it succeeded. The repository-wide AI-context validator also reported 13 grammar/required-field findings in the unrelated active `ASSET_DOWNLOADS_INTAKE_SWEEP.md` packet.
- Root cause / contributing factors: The root checkout was behind current main at first; the unrelated active packet is malformed in current main.
- Prevention / pipeline improvement: Pull current main before retrying dispatcher metadata failures; route the intake-packet repair through its own workstream.
- Tooling / docs drift discovered: The H1 smoke's all-marker check shares the layout source for many coordinates; recorded as R0-01. `check_ai_context.py` reported no H1 review packet error but does report 13 findings in `ASSET_DOWNLOADS_INTAKE_SWEEP.md`.
- Follow-up: `manual-follow-up` (repair the unrelated intake packet through its own workstream)
- What worked: Independent live Operator traversal directly confirmed both Garden directions and the Port route without adding tracked test artifacts.
