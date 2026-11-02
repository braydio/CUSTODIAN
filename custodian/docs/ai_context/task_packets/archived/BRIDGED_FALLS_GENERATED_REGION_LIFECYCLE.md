# BRIDGED FALLS — GENERATED REGION LIFECYCLE FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `bridged-falls-generated-region-lifecycle`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `route-runtime, level-loader, procgen-region-host`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-bridged-falls-generated-region-lifecycle`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `911e8871e77c7505a574334d5ab714b5458c7b94`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `none`
- Goal: Let a normal CUSTODIAN route node host a separately generated procgen region while preserving the existing persistent-Operator, camera, rollback, state, and single-active-authority guarantees.
- Completion boundary: Add the smallest reusable generated-region runtime contract needed for a route node to stage, validate, activate, leave, revisit, and release a generated `ProcGenTilemap`-backed destination. Prove authored -> generated -> authored/back traversal. Do not implement Ash-Bell content, Bridged Falls topology, or a second transition manager.
- Current measured state: `RouteTraversalManager` V1 assumes every declared route node resolves through `LevelRegistry` to a `LevelDefinition` whose entry path is a `PackedScene`; `LevelLoader.stage_level()` instantiates that scene before activation. The existing `@world_origin` endpoint restores the exact captured campaign origin and is not a second generated destination. Current production procgen is owned by `CustodianContractMap` / `ProcGenTilemap`; no registered route node currently proves an authored node can transition into a freshly generated region and then back.
- Evidence: `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`; `custodian/game/world/routes/route_traversal_manager.gd`; `custodian/game/world/levels/level_definition.gd`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/proc_gen_map.tscn`; `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/custodian_contract_map.gd`; existing Sundered/Lower-Quarter route smokes.
- Task-specific authority: `ROUTE_TRAVERSAL_SYSTEM.md` owns route/session semantics; `LevelLoader` owns low-level stage/activate/deactivate/release; `ProcGenTilemap` and existing contract/generation modules own generated gameplay semantics. This packet may add an adapter/resource contract but must not create parallel route, navigation, collision, streaming, or world-generation authority.
- Work surface: route/level definitions and registries; `LevelLoader`; a narrow generated-region host/adapter; focused route lifecycle validation; procgen generation entrypoints needed for deterministic staging.
- Change:
  1. Add an explicit data-level way for a registered route node to declare a generated-region runtime rather than an authored `PackedScene`. Prefer an additive runtime-kind/adapter contract over widening every authored level hook.
  2. Generated-region staging must create a fresh inactive region instance from existing procgen owners, apply an explicit generation/profile request and seed, complete generation/validation before source authority is relinquished, expose named route spawns, and return a stage result compatible with the existing transaction.
  3. Activation must bind the persistent Operator and shared camera to the generated runtime map using the same route transition commit/rollback ordering as authored nodes.
  4. Generated-region deactivation/revisit must respect the existing route cache/state policy contract. Persist only serialization-safe generated-region identity/state required by the chosen policy; never store live Nodes in route state.
  5. A failed generation, missing spawn, invalid generated result, activation failure, or camera-bind failure must roll back to the authored source exactly as current authored transition failures do.
  6. Keep `@world_origin` semantics unchanged. A generated route node is a normal node, not a disguised second world origin.
  7. Add a focused generated-route-node lifecycle regression that exercises authored -> generated -> back, deterministic same-seed regeneration/revisit behavior, single active processing authority, Operator/camera binding, and at least one forced failure rollback.
- Preserve: Existing authored route schemas and production Sundered/Lower-Quarter/Ritualant behavior; `WorldIngressSite` world-origin isolation; current procgen generation semantics, streaming, region frames, spawn validity, navigation and collision authority; route-owned fade behavior.
- Non-goals: No Ash-Bell-specific generated profile. No Ritualant route edit. No Bridged Falls bridge generation. No route-to-route handoff. No save-file persistence. No new WorldTransitionManager. No visual work.
- Acceptance: A registered test route can enter a fresh generated region as a normal node, place the same Operator at a declared generated spawn, bind the camera/runtime map, leave/backtrack safely, and deterministically regenerate/revisit according to the chosen lifecycle; only one route node processes gameplay at once; forced generation/spawn/activation failure restores the authored source and actor/camera identity; `@world_origin` behavior and existing authored routes remain unchanged.
- Validation: Add/run the focused generated-region route lifecycle smoke first. Then run live route-registry/graph coverage through `res://tools/validation/sundered_keep_route_graph_smoke.gd`, `res://tools/validation/ash_bell_lower_quarter_route_smoke.gd`, `res://tools/validation/procgen_intent_graph_smoke.gd`, and the smallest procgen generation/spawn/camera regressions selected by changed files. Finish with changed-file unit/integration validation and `git diff --check`.
- Task overrides: `none`
- Deferred: Concrete `ash_bell_highlands` destination and all Bridged Falls content.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `generated_region_route_lifecycle_smoke.gd PASS; ash_bell_lower_quarter_route_smoke.gd PASS; procgen_intent_graph_smoke.gd PASS; route_forward_backtrack_smoke.gd PASS; route_transition_rollback_smoke.gd PASS; route_registry_contract_smoke.gd PASS; route_single_level_wrapper_smoke.gd PASS; level_registry_contract_smoke.gd PASS; contract_world_playable_region_spawn_validity_smoke.gd PASS. Sundered Keep route graph arrival-guard assertion reproduced on unmodified main@911e8871e; no authored Sundered runtime or exit contract was changed.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `low`
- What went wrong: `The required Sundered Keep route graph smoke reports Front Gate backtrack arrival guard not armed. The same assertion fails on the unmodified root checkout at the implementation base.`
- Root cause / contributing factors: `The failure predates this diff; the exact test/runtime disagreement is outside this generated-region slice and remains unisolated.`
- Prevention / pipeline improvement: `Keep the baseline reproduction in the review receipt so this authored-route failure is not attributed to generated-region staging.`
- Tooling / docs drift discovered: `The graph database was empty and graph initialization timed out; source exploration continued with the repository-prescribed rg fallback.`
- Follow-up: `manual-follow-up`

## Handoff

- Next workstream: `review-bridged-falls-generated-region-lifecycle`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/review/correction/recovery/closeout summary and final Next Handoff.
- Refresh reason: Wait for BF1 to archive complete on main so its paired review can claim.
- Next action: Run the paired review from its required fresh reviewer context; after review, mechanically refresh BF2 against the reviewed live contract.
- Blockers or open questions: The Sundered Keep route graph smoke has the documented baseline arrival-guard failure at implementation base 911e8871e.

## Independent Review

- Status: `findings`
- Review workstream: `review-bridged-falls-generated-region-lifecycle`
- Reviewed on main: `520af6d832a4a79fe2fee110e3424ae1f1083dcd`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Blocking defects: `1`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE_CLAUDE_SUMMARY.md`
- Follow-up workstream: `bridged-falls-generated-region-lifecycle-review-corrections-1`
- Reviewer independence: `The reviewer claimed a fresh paired-review workstream and reconstructed the target from archived packet/summary evidence, active route architecture, live source, and fresh runtime traces. No reviewed runtime files were changed.`
