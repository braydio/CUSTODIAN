# HUB AWAKENING CONTEXT HANDOFF — H2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-awakening-context-handoff`
- Status: `complete`
- Priority: `P1`
- Depends on: `review-hub-first-set-blockout-v1, review-awakening-handoff-readiness-art-convergence-v1`
- Locks: `hub-runtime, world-lifecycle`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-awakening-context-handoff`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `872f33b8e83c94446dbfb773e759417e6db3dff2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb`

- Goal: Consume the reviewed one-shot Awakening completion seam and enter the reviewed persistent Hub first-set runtime at `Spawn_SouthReach` through one major-context lifecycle authority, without starting a Contract or bypassing the Hub.
- Completion boundary: Establish the smallest production major-context handoff needed for Awakening → Hub. Validate the data-only completion once, freeze outgoing authority transactionally, activate a production Hub host around the reviewed H1 map with a real Operator/camera at `Spawn_SouthReach`, bind camera/navigation before control resumes, and fail/rollback safely. No Forum Contract behavior, Twin traversal, or Campaign deployment.
- Current measured state: Production boot enters Awakening. The internal lower→upper Awakening splice is already complete/reviewed: a real Operator traverses Zone05→06→07→08→10 continuously. The remaining north-end stop is intentional current runtime boundary, not that splice: `AwakeningFirstReturn._build_south_reach_barrier()` builds visible/collidable `SouthReachCollapse` at world `y=-6530`, 66px north of `SOUTH_REACH_COMPLETION_CENTER=(0,-6464)`. The active Awakening convergence workstream owns replacement of legacy blockout completion naming with a production completion seam, but deliberately does not perform the Hub transition. H1 is complete/reviewed and provides the persistent first-set map at `Spawn_SouthReach=(-6,162)`. H2 is therefore the slice that must make a qualified production run continue into Hub rather than terminate against `SouthReachCollapse`. `WORLD_TRANSITION_SYSTEM.md` still describes the major-context manager as future architecture; live `LevelLoader` and `RouteTraversalManager` own authored traversal inside an active context and must not become the major-context owner.
- Evidence: `design/04_architecture/WORLD_TRANSITION_SYSTEM.md`; `AWAKENING_FIRST_RETURN.md`; `HUB_FIRST_SET_BLOCKOUT.md`; active Awakening handoff-readiness packet/review; H1 packet/review; `game/app/boot/runtime_entrypoint.gd`; live camera/navigation/authored-level contracts.
- Task-specific authority: reviewed Awakening completion contract; reviewed H1 map/spawn API; `WORLD_TRANSITION_SYSTEM.md`; runtime world/camera stabilization authority.
- Work surface: Expected major-context lifecycle owner under `custodian/game/systems/world/` or the cleaner landed equivalent; one production Hub runtime host; completion binding; reviewed H1 map; camera/navigation/world binding; focused handoff smoke. The H1 map itself stays Operator/camera-free.
- Change: Implement one authoritative request/state-machine seam sufficient for Awakening → persistent Hub and reusable by H5/H6. Awakening emits completion but does not call `change_scene_to_file()` into Hub. Treat `SouthReachCollapse` as a source-context rollback/failure-safe seal, not the successful-run destination: once the production completion prerequisites are satisfied and the Operator enters the South Reach completion volume, freeze outgoing movement/authority immediately enough that the Operator cannot physically collide with the barricade while a valid handoff is in progress. On success, activate the Hub host and place the Operator exactly at `Spawn_SouthReach`; the player-visible route continues north instead of ending at the barricade. On target-stage/validation failure, restore a playable Awakening source with the barricade intact and report the failure deterministically. Do not simply delete the barricade from Awakening to fake continuity. Resolve persistent-home taxonomy during the claim-time dependency refresh: if live architecture still says COMPOUND while the authored first-set is the Hub home context, keep one canonical context/alias migration instead of parallel HUB and COMPOUND managers. Validate target bindings before input unlock.
- Preserve: default boot into Awakening; reviewed H1 geometry; current startup development modes; generation_count remains zero through H2; RouteTraversalManager/LevelLoader ownership of authored sub-level traversal; deterministic simulation.
- Non-goals: No Dais interaction; no `WorldContractBootstrap.ensure_started()`; no Twin entry; no Port deploy; no Campaign return; no transit polish; no save/resume expansion.
- Acceptance: one reviewed Awakening completion causes at most one successful Hub entry; duplicate/reentrant completion cannot create a second Hub; Awakening contains no direct Hub scene change/bootstrap call; in a fully qualified console+P-9 run the Operator entering the South Reach completion volume never reaches/collides with `SouthReachCollapse` before handoff authority freezes the source; the target is one production Hub host containing the reviewed H1 map with a real Operator exactly at `Spawn_SouthReach`; successful entry therefore has no player-visible dead-end at the current north barricade; source and target are never simultaneously authoritative; camera/navigation/world binding completes before input unlock; forced target-stage/validation failure restores a playable source with its rollback seal intact and reports failure; incomplete qualification still fails closed in Awakening; startup modes remain green; bootstrap generation_count remains zero.
- Validation: Add one focused major-context handoff smoke for success, duplicate suppression, binding order, active-world exclusivity, and rollback. Re-run reviewed Awakening completion/progression tests, H1 blockout smoke, startup-world-entry, directly affected camera/navigation binding smoke, then changed-file closeout and `git diff --check`.
- Task overrides: `none`
- Deferred: H3 Contract selection/prewarm; H4 Twin route; H5 deployment; H6 return; save/resume and transit presentation.

## Agent Handoff / Planning Decisions — 2026-10-09

- User playtest on current main reaches the north end of Awakening and physically collides with the visible South Reach barricade. This is expected **before H2**, because the barrier is an authored temporary seal and H2 has not landed yet.
- Do not reopen the completed 05→06 lower/upper Awakening splice; that route has already passed real-Operator traversal through Zones05/06/07/08/10.
- `awakening-handoff-readiness-art-convergence-v1-r1` deliberately stops at a production completion signal. **H2 owns the actual player continuation into the persistent Hub.**
- The successful-run UX contract is stronger than “a signal emitted”: after console acknowledgement + P-9 recovery, entering the South Reach completion volume must transfer/freeze authority before the Operator can run into `SouthReachCollapse`.
- Keep the barrier as rollback/failure-safe source-state architecture. Do not delete or disable it globally just to satisfy the playtest.
- H1 is already complete/reviewed; use its exact `Spawn_SouthReach=(-6,162)` and reviewed map. Do not invent another Road/Hub registration.

## Context Pack

- Repomix: `recommended`
- Include: `custodian/game/world/awakening/awakening_first_return.gd,custodian/game/world/awakening/awakening_layout.gd,custodian/game/world/hub/first_set/hub_first_set_map.gd,custodian/game/world/hub/first_set/hub_first_set_map.tscn,custodian/game/world/hub/first_set/hub_first_set_layout.gd,custodian/scenes/hub_first_set_blockout_playtest.tscn,custodian/game/app/boot/runtime_entrypoint.gd,custodian/tools/validation/hub_first_set_blockout_smoke.gd,custodian/tools/validation/awakening_first_return_progression_smoke.gd,design/04_architecture/WORLD_TRANSITION_SYSTEM.md,design/04_architecture/AWAKENING_FIRST_RETURN.md,design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md,design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md,REVIEW_HUB_FIRST_SET_BLOCKOUT_V1_CLAUDE_SUMMARY.md`
- Purpose: `exact South Reach completion/barrier authority + reviewed H1 spawn/map + boot/context ownership + validation seams needed for the production Awakening→Hub handoff`

Generate once from the claimed worktree with:

```bash
scripts/ai/pack-context.sh task "<Include value above>" "hub-awakening-context-handoff"
```

Use the persistent-root CRG for baseline architecture orientation only; exact worktree files and diff remain implementation truth.
## Claim-Time Dependency Refresh

This packet is intentionally `ready/auto` while its declared dependencies may still be incomplete. The dispatcher must keep it non-claimable until every `Depends on` workstream is archived `complete`. Once claimed, the execution agent must reconstruct the landed predecessor seams from current `main`, archived implementation/review summaries, and live public APIs before mutation. Reconcile private helper names and bounded implementation drift while preserving this packet's Goal, Completion boundary, Preserve, Non-goals, and Acceptance. Update directly stale packet/docs facts inside the workstream when needed. Do not stop for a ChatGPT/user refresh unless current evidence exposes a genuine unresolved design choice that existing authority cannot answer.
## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Legacy context aliases: `COMPOUND` and `HOME` resolve to canonical runtime context `HUB` in the same manager; no parallel home manager.
- Evidence: `world_transition_handoff`, `awakening_first_return_progression`, `hub_first_set_blockout`, and `startup_world_entry` focused validations passed; changed-file validation and AI-context/pairing/index closeout recorded in the implementation summary.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first handoff smoke exposed unsafe physics-callback collision updates; rollback initially restored the Operator inside the completion volume and could retrigger a failed handoff. An early fresh-checkout scan also generated unrelated `.import` sidecars.
- Root cause / contributing factors: Godot rejects immediate collision-object/process-mode changes during physics callbacks, and the trigger-time position is not a safe rollback point. Fresh editor scans generated cache-adjacent sidecar metadata for unrelated reference art.
- Prevention / pipeline improvement: Defer physics-sensitive source shutdown changes and roll back south of the completion volume. Remove only known validation-generated unrelated sidecars before workstream finish.
- Tooling / docs drift discovered: `WORLD_TRANSITION_SYSTEM.md` still described the major-context manager as future work and used `COMPOUND` as a separate home context; updated to record the H2 foundation and canonical Hub alias.
- Follow-up: none
- What worked: A real Operator volume-entry smoke covers failure rollback and successful transfer without renderer evidence.

## Next Handoff

- Next workstream: `review-hub-awakening-context-handoff`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Run the paired review in a fresh independent reviewer context against the archived packet and landed runtime; preserve any findings as authored correction work.
- Blockers or open questions: none
