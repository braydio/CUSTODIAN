# ROUTE TRAVERSAL V1

- Status: `complete-v1`
- Authority: `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`
- Goal: Implement directed transactional intra-campaign traversal and migrate Vista → Return Causeway → Front Gate.
- Files: `game/world/routes/`, authored-level/loader/ingress runtime, Sundered scenes/scripts, `content/{levels,routes}/`, level generator, route validation, CI, architecture/context docs.
- Constraints: Preserve one persistent Operator and one active route-node authority; keep topology out of `LevelLoader` and destinations; preserve unrelated dirty work; do not modify audio, terminal, combat, animation, or unrelated procgen behavior.
- Acceptance: Production/debug/causeway-only profiles, reverse traversal, rollback, exfil, all state/cache policies, single-level wrapper, generator create/append, CI, and synchronized documentation pass the declared suite.
- Completed: Architecture/data model, world-local traversal manager, staged loader APIs, generic exits, combined ingress registry, one-node wrapper, Sundered three-node migration, state/cache policy runtime, rollback/exfil, route-aware generator, focused smokes, CI runner, project import, lifecycle matrix, Sundered regressions, and ownership validation.
- Deferred: Disk save integration, major-context `WorldTransitionManager`, editor route UI, transition-screen polish, additional campaigns.

## Ownership And Timing

- Owner: gameplay/world architecture
- Agent/session: Codex route-traversal complete pass
- Created: 2026-07-21
- Last updated: 2026-07-21

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

## Handoff

- Next action: implement and validate the generic route data model/registry.
- Best starting files: `level_definition.gd`, `level_registry.gd`, `level_loader.gd`, `world_ingress_site.gd`.
- Validation to run: complete route runner plus existing lifecycle/Sundered regressions listed in the authority and user task.
- Blockers or open questions: none; exact current scenes and available marker semantics have been inspected.
