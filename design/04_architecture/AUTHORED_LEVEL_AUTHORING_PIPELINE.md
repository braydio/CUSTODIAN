# Authored Level Authoring Pipeline

**Project:** CUSTODIAN  
**Created:** 2026-07-19  
**Status:** active  
**Last Updated:** 2026-07-19

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

### Out of Scope

- Production level art.
- Campaign save serialization.
- A full world-transition-manager migration.
- Editor-dock UI for the scaffold generator.
- Replacing the routed Sundered Keep Vista/Return Causeway chain.

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

## Registry Contract

`custodian.level_definition.v1` remains backward-compatible and gains optional fields for `playtest_scene_path`, `authoring_scene_path`, and `design_doc_path`. Its ingress block owns a required `target_spawn_id` and optional placement dictionary.

Definitions tagged `world_ingress` are eligible for procgen placement. Registry paths are sorted and duplicate paths/IDs are rejected.

Sundered Keep remains a special routed chain: its registry entry points at the Vista Approach, and its later Keep transition remains approach-owned. `target_scene_path` is therefore the registered entry target, not the terminal Keep map.

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

The CLI generator is stage-first:

```text
preflight → normalize → collision checks → stage → parse/load validation
→ commit generated files → update registry last → report
```

Rules:

- `--dry-run` performs no repository writes.
- Existing unmanaged paths are never overwritten.
- `--force-generated` may replace only paths listed by the existing `.levelgen.json` manifest.
- Registry mutation happens last and is atomic.
- Alternate output roots support smoke validation without repository mutation.
- No production art is generated; empty levels use a procedural authoring grid.

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
- Generator smoke proves dry-run, creation, duplicates, managed overwrite, unmanaged rejection, sorting, and rollback.
- Spawner smoke proves deterministic spacing and correct level identity.
- Existing Sundered ingress, mapper, approach, and chain smokes remain required regressions.

## Deferred Work

- A `DevBootstrap`-style editor dock for level creation.
- Full transition-manager ownership.
- Abstract placement strategies beyond compound-relative candidates.
- Production art promotion and TileMap authoring workflows.

