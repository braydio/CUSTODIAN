# ROUTE TRAVERSAL V1

- Status: `complete-v1`
- Authority: `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`
- Goal: Implement directed transactional intra-campaign traversal and migrate Vista → Return Causeway → Front Gate.
- Files: `game/world/routes/`, authored-level/loader/ingress runtime, Sundered scenes/scripts, `content/{levels,routes}/`, level generator, route validation, CI, architecture/context docs.
- Constraints: Preserve one persistent Operator and one active route-node authority; keep topology out of `LevelLoader` and destinations; preserve unrelated dirty work; do not modify audio, terminal, combat, animation, or unrelated procgen behavior.
- Acceptance: Production/debug/causeway-only profiles, reverse traversal, rollback, exfil, all state/cache policies, single-level wrapper, generator create/append, CI, and synchronized documentation pass the declared suite.
- Completed: Architecture/data model, world-local traversal manager, staged loader APIs, generic authored exits, combined ingress registry, one-node wrapper, Sundered three-node migration, state/cache policy runtime, rollback/exfil, route-aware generator, focused smokes, CI runner, project import, lifecycle matrix, Sundered regressions, ownership validation, post-commit entry rollback cleanup, symmetric Front Gate nested state, disconnected-profile rejection, and full generator validation before writes.
- Deferred: Disk save integration, major-context `WorldTransitionManager`, editor route UI, transition-screen polish, additional campaigns.

## Ownership And Timing

- Owner: gameplay/world architecture
- Agent/session: Codex route-traversal complete pass
- Created: 2026-07-21
- Last updated: 2026-07-23

## Work Surface

- Read: repository/local primers, authored pipeline, world transition architecture, current/context/index/validation docs, current level/ingress/Sundered/generator/CI runtime.
- Change: only the route, authored-level lifecycle integration, Sundered route ownership, route-aware generator/validation/CI, and required docs.
- Out of scope: audio, terminal, combat, animation, unrelated procgen, save files, major context transitions.

## Plan

1. Add route data model, registry, session, state store, and contract validation.
2. Add generic exits, staged loader APIs, route hooks, manager, ingress integration, and state/cache behavior.
3. Register/migrate the three Sundered nodes and all profiles; remove scene-owned topology.
4. Add generator integration, route suite/CI, run regressions, and synchronize documentation.

## Drift Review

- Primary authority: new route document plus existing authored pipeline and world-transition boundary.
- `CURRENT_STATE.md`: currently describes Sundered as approach-owned and route traversal as deferred; must change only after runtime validation.
- `CONTEXT.md`: same stale ownership statement must be updated after validation.
- `FILE_INDEX.md`: must index new route runtime/data/validation ownership.
- Local routing/readmes: `VALIDATION_RECIPES.md`, authoring code doc, and existing authoring task packet require synchronization.

## Completion Handoff

- Implemented production graph: `@world_origin → vista_approach → return_causeway → front_gate`; reverse graph: `front_gate → return_causeway → vista_approach → @world_origin`; Front Gate also has direct `exfil`.
- Profiles: `production`, `debug_direct_keep`, and `causeway_only`.
- Hardened guarantees: initial-entry post-commit rollback clears loader authority synchronously; Front Gate capture/restore is symmetric for scalar, siege-objective, and Great Hall ambush state; enabled profile topology rejects disconnected participants; scaffold route changes run full `RouteDefinition` validation before writing; and all production Sundered exits are authored scene nodes.
- Validation boundary: run `tools/validation/run_route_pipeline_suite.sh`, the authored-level lifecycle matrix in `.github/workflows/godot-level-pipeline.yml`, project import, and `git diff --check`.
- Blockers or open questions: none for V1; deferred work remains limited to the list above.
