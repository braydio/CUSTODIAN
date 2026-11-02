# Ash-Bell Lower Quarter First Playable Blockout

- Status: `complete`
- Authority: `design/05_levels/ASH_BELL_LOWER_QUARTER.md`; `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`; `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`
- Goal: deliver a route-complete, traversal-complete, stateful, FOV-correct procedural blockout for Lower Quarter, West Gate Works, and Station IX.
- Files: route/level registries and definitions; generic ingress definition/spawner; authored blockout helper/components/scenes; focused validation; camera/scale/current-state documentation.
- Constraints: preserve route-manager destination authority, authored-level local-state ownership, the global 24-unit Sector contract, canonical Ash-Bell language, unrelated dirty work, and the no-production-art/no-fake-Penitent boundary.
- Acceptance: exact three-node/six-edge production graph; campaign ingress; validated spawns and exfil paths; local progression gates; idempotent session restoration; opening Station IX composition; focused and route-pipeline validation; documentation drift repaired.
- Completed: active spec; generic custom ingress seam; campaign ingress; exact route/level registries; shared merged-boundary blockout and local interaction components; all three authored scenes; Lower Quarter relay gates and opening composition; West Gate animated/restored closure; Station IX ordered isolation; visible technical blockout labels; pressure markers; focused validation; scale/camera/context drift repair.
- Deferred: production environment art, final Penitent population, final dialogue/cinematics, evidence-reader UX, and later encounter tuning.

## Ownership And Timing

- Owner: Codex
- Agent/session: current shared-worktree implementation
- Created: 2026-08-20
- Last updated: 2026-08-20

## Work Surface

- Read: canonical continuity and Penitent doctrine, route traversal architecture, authored-level/exit/loader/ingress runtime, registries/examples, camera and scale contracts, validation recipes.
- Change: only the Ash-Bell Lower Quarter implementation surface and generic additive ingress-scene support.
- Out of scope: new route/loading architecture, global scale migration, production art, production Penitent archetypes, knowledge gating, and cosmology resolution.

## Plan

1. Lock active design and task packet.
2. Add generic ingress scene-path parsing/validation/instantiation.
3. Register route and three authored levels.
4. Implement shared blockout geometry and interaction components.
5. Build and state-wire all three level scenes.
6. Add focused validation and manifest ownership.
7. Repair camera, scale, and AI-context drift.
8. Run required validation, review, update this packet, and commit scoped files.

## Drift Review

- Primary authority: new active level spec created under `design/05_levels/`.
- `CURRENT_STATE.md`: update after runtime validation.
- `CONTEXT.md`: update only if ownership summary becomes inaccurate.
- `FILE_INDEX.md`: index all new authorities and runtime/validation entrypoints.
- Local routing/readmes: create per-level blockout READMEs.

## Handoff

- Next action: review the blockout in-engine, then scope the production-art and approved Penitent-population pass without changing topology.
- Best starting files: `world_ingress_definition.gd`, `world_ingress_spawner.gd`, route/level registry JSON, and authored Sundered/Ritualant examples.
- Validation run:
  - headless import: PASS
  - `ash_bell_lower_quarter_route_smoke.gd`: PASS (`nodes=3 edges=6`)
  - `ash_bell_lower_quarter_layout_smoke.gd`: PASS (`relays=3 answers=9`, including West Gate closure/restore)
  - `ash_bell_station_ix_state_smoke.gd`: PASS (`assemblies=3 isolated=true`)
  - `world_ingress_spawner_smoke.gd`: PASS
  - historical archive boundary validation: PASS
  - changed-file workflow: all five selected tests PASS; aggregate exit 6 only because unrelated untracked `repomix-map-ai-runtime-fixes.xml` has no manifest owner
  - route pipeline: all route registry/connectivity/transaction/rollback/exfil/cache/state/exit tests pass until the existing unrelated `sundered_keep_world_vista_smoke.gd` camera-weight assertions fail; reproduced individually
  - Moment Forge selection: existing `traversal/ash_bell_lift_exterior_descent` suggested by shared directory only; not run because it exercises the independent Ritualant lift, not Lower Quarter. A reliable Lower Quarter opening fixture is deferred rather than creating misleading evidence.
- Blockers or open questions: no feature blocker. Repository-wide green is externally blocked by the unrelated root XML coverage gap and existing Sundered vista camera smoke failure.
