# Authored Level Authoring Pipeline

**Project:** CUSTODIAN  
**Created:** 2026-07-19  
**Status:** complete-v1; lifecycle hardening complete; route traversal v1 complete
**Last Updated:** 2026-07-23

## Purpose

Define one deterministic path from a level-scaffold request to a registered, playable authored destination without duplicating the persistent Operator or adding destination-specific placement code to `ContractWorldLoader`.

## Scope

### In Scope

- Production authored-level scene ownership.
- Standalone movement/combat/full playtest wrappers.
- Collision and POI authoring through a reusable mapper.
- Named ingress-spawn resolution.
- Persistent level registry definitions.
- Deterministic procgen ingress placement.
- Safe, CLI-first scaffolding and generated-file ownership.
- Explicit presentation and level-lifecycle policy.
- Atomic entry failure, world return, and ingress re-entry.

### Out of Scope

- Production level art.
- Campaign save serialization.
- A full world-transition-manager migration.
- Editor-dock UI for the scaffold generator.
- Major-context Compound/Campaign transitions.
- Disk/save-file persistence for route sessions.

## Core Ownership Contract

> Production level scenes own level content. The main world owns the persistent Operator. Playtest scenes own temporary test runtime nodes. Registry definitions own ingress identity and named-spawn linkage. The procgen ingress spawner owns deterministic entrypoint placement.

Production scenes must never instantiate an Operator, gameplay camera, or `PlayerController`. A standalone playtest wrapper may instantiate those nodes because it is the temporary world authority for that run.

## System Overview

```text
LevelScaffoldGenerator
  ├─ production level scene + script
  ├─ standalone playtest scene
  ├─ configured authoring scene
  ├─ level definition + levelgen manifest
  ├─ design/readme files
  └─ generated smoke
               │
               v
LevelRegistry → WorldIngressSpawner → WorldIngressSite
                                         │
                                         v
                                    LevelLoader
                                         │
                                named target spawn
                                         │
                                         v
                                  AuthoredLevel2D
```

## Runtime Components

| File | Role |
|---|---|
| `custodian/game/world/levels/authored_level_2d.gd` | Shared production-level contract, markers, boundary rails, connection lifecycle, camera binding, and named spawns. |
| `custodian/game/world/levels/level_loader.gd` | Instantiates registered entry scenes and treats spawn activation as a terminal success/failure boundary. |
| `custodian/game/world/levels/world_ingress_spawner.gd` | Loads world-ingress definitions, sorts them deterministically, creates sites, and reports placement. |
| `custodian/game/world/levels/world_ingress_placement_resolver.gd` | Pure placement policy and spatial validation. |
| `custodian/game/world/levels/level_playtest_bootstrap.gd` | Activates a standalone production-level instance with the wrapper Operator/camera. |
| `custodian/scenes/debug/level_collision_poi_mapper.*` | Generic collision/marker authoring surface. |

## Production Scene Contract

Every generated production scene contains stable editor-visible roots:

```text
AuthoredLevel
├── UnderlayRoot
├── BackgroundRoot
├── PlayableRoot
├── PropsRoot
├── OcclusionRoot
├── Collision
│   └── PathBoundaryCollision
├── Markers
│   ├── Spawn_Main
│   └── Return_Main
├── POIRoot
├── EventMarkers
├── EventRuntime
└── NavigationRoot
```

Required methods are supplied by `AuthoredLevel2D` unless overridden:

```gdscript
configure_connection(main_map, return_world_position)
get_entry_position()
get_spawn_position(spawn_id)
has_spawn(spawn_id)
enter_from_main(actor)
enter_from_main_at_spawn(actor, spawn_id)
return_to_main(actor)
get_camera_bounds()
get_boundary_segments()
get_authoring_markers()
get_authoring_marker_schema()
get_authoring_marker_state()
authoring_to_runtime_point(point)
runtime_to_authoring_point(point)
```

Missing named spawns are activation failures. They must not fall through to `(0, 0)` or a legacy destination.

## Presentation and Lifecycle Contract

Every definition explicitly declares one presentation profile:

- `gameplay`: ordinary gameplay HUD and Operator presentation.
- `vista_approach`: clean authored-vista presentation.
- `cinematic`: presentation-suppressed traversal/cutscene state without claiming vista-specific level identity.

Ingress resolves the registered definition before changing presentation. It snapshots both source world branches, the actor transform, camera state, and prior UI presentation, then isolates the source and activates the requested profile. Any activation failure restores that snapshot atomically.

World return is transactional at the active-node boundary. `LevelLoader` immediately hides and disables the outgoing level before restoring the origin, so the authored level and procgen world cannot both process during the deferred-free frame. Origin restoration preflights required branch, actor, camera, and runtime-map references and returns a structured result. The loader releases the outgoing node and clears active ownership only after a successful restore; otherwise it restores the outgoing node's prior presentation/process state and keeps the route bridge active.

When a valid loader is bound, `AuthoredLevel2D.return_to_main()` fails closed if the loader rejects the request. Its legacy local restoration path is available only when no loader owns the level.

Every definition also declares lifecycle data:

```json
"lifecycle": {
  "cache_policy": "keep_during_route",
  "state_policy": "session"
}
```

`keep_during_route` permits a future route owner to cache the node during an active route. Returning to the world origin ends the current bridge session, so the active instance is released and the loader record is cleared. Generated destinations must support enter, return, and re-entry without duplicate instances or stale ingress state.

## Registry Contract

`custodian.level_definition.v1` remains backward-compatible and gains optional fields for `playtest_scene_path`, `authoring_scene_path`, and `design_doc_path`. Its ingress block owns a required `target_spawn_id` and optional placement dictionary.

Definitions tagged `world_ingress` are eligible for procgen placement. Registry paths are sorted and duplicate paths/IDs are rejected.

Sundered Keep is a registered route with distinct Vista Approach, Return Causeway, and Front Gate levels. Its route definition owns world ingress and production/debug profiles; each scene exposes only generic exits. The Front Gate definition points to the real Keep scene. Generated definitions default to `gameplay`, while the Vista node explicitly selects `vista_approach`.

The production Sundered scenes author their `LevelExit2D` children directly: Vista owns `continue` and `return_world`, Return Causeway owns `continue` and `backtrack`, and Front Gate owns `backtrack` and `exfil`. Runtime scripts locate and position these nodes but do not instantiate them.

`WorldIngressSpawner` combines level-owned and route-owned ingress definitions deterministically and rejects duplicate ingress IDs. Production level-only ingress starts an internal one-node route. `LevelLoader` is the low-level staged-instance service and never owns graph/profile/history logic.

## Ingress Placement

Placement authority is data-driven and deterministic:

1. Load and validate the registry.
2. Sort eligible level IDs.
3. Resolve an anchor from compound ingress or player spawn.
4. Evaluate configured offsets followed by a bounded deterministic search.
5. Reject non-walkable, reserved, or too-close candidates.
6. Instantiate one `WorldIngressSite` per successfully placed level.
7. Apply its ingress definition and configure its registered level ID.

Camera visibility is never placement or simulation authority.

## Authoring Mapper

The generic mapper accepts exported target scene/script paths and asks the target level for its marker schema and coordinate conversion. It preserves the existing mapper helper API and the `approach` state alias for Sundered compatibility.

Writes use a temporary sibling file, verify both authored constants in memory/on disk, and rename only after validation. A failed write leaves the original unchanged.

## Scaffold Safety

The CLI generator is stage-first and validates the complete proposed graph before any write:

```text
normalize/request checks → prepare route mutation → render in memory
→ parse staged and existing definitions → full RouteDefinition validation
→ overwrite preflight → stage files → parse/load validation
→ commit generated files → update registries last → report
```

Rules:

- `--dry-run` performs no repository writes.
- Existing unmanaged paths are never overwritten.
- `--force-generated` may replace only paths listed by the existing `.levelgen.json` manifest.
- Registry mutation happens last and is atomic.
- Alternate output roots support smoke validation without repository mutation.
- No production art is generated; empty levels use a procedural authoring grid.
- Create, append, and dry-run route requests use a validation-only level-registry view containing existing generated definitions plus the staged definition.
- Invalid registry schemas, references, spawns, directions, duplicate IDs/mappings, second world-origin entries, disconnected enabled topology, or reachable nodes without exfil fail before overwrite preflight and leave all files byte-for-byte unchanged.

## Current Runtime Bridge

The aspirational `WorldTransitionManager` in `WORLD_TRANSITION_SYSTEM.md` is not live. Current transition ownership is distributed across:

- `custodian/game/world/levels/level_loader.gd`
- `custodian/game/world/procgen/ingress/world_ingress_site.gd`
- `custodian/game/systems/core/systems/contract_world_loader.gd`

This pipeline improves that bridge without claiming the future manager exists.

## Validation

- Registry contract validates every registered definition, scene, spawn, mapper root, and declared companion path.
- Named-spawn smoke proves success and atomic failure cleanup.
- Mapper smoke proves generic configuration, dynamic markers, compatibility aliases, and non-mutating replacement helpers.
- Generator smoke proves dry-run, creation/append, managed overwrite, unmanaged rejection, sorting, complete route validation, and byte-for-byte immutability on failure.
- Spawner smoke proves deterministic spacing and correct level identity.
- Physics re-entry smoke proves real `Area2D.body_entered` activation can leave and re-enter the same ingress.
- Single-authority return smoke proves the outgoing authored level is hidden and disabled before origin processing resumes.
- Rejected-return and destroyed-origin smokes prove loader ownership cannot be bypassed and partial restoration does not commit.
- Camera-rebind smoke proves runtime-map binding, transform, zoom, target zoom, and presentation framing restore exactly.
- Existing Sundered ingress, mapper, approach, and chain smokes remain required regressions.
- Sundered route graph/state/authored-exit smokes prove the production/reverse/profile graphs, nested Front Gate unload/revisit restoration without repeated side effects, and scene-owned generic exit nodes.

## Deferred Work

- A `DevBootstrap`-style editor dock for level creation.
- Full transition-manager ownership.
- Disk/save-file route serialization and editor graph authoring.
- Abstract placement strategies beyond compound-relative candidates.
- Production art promotion and TileMap authoring workflows.
