# PIXEL_PLANET_CONTRACT_SYSTEM

Status: in progress
Owner: procgen/runtime
Runtime target: Godot 4 (`custodian/`)

## Purpose

Pair PixelPlanets with `procgen/proc_gen_map` so one deterministic contract seed produces:

1. CUSTODIAN contracted planet
2. CUSTODIAN map instance (plus level data)

## Integration Approach

PixelPlanets scenes are authored with `res://Planets/...` paths. To make those paths resolvable in the CUSTODIAN Godot project:

- `custodian/Planets` is linked to `../PixelPlanets/Planets`

This allows direct loading of PixelPlanets planet scenes from inside CUSTODIAN.

## Runtime Module

### Scene

- `res://procgen/custodian_contract_map.tscn`

### Script

- `res://procgen/custodian_contract_map.gd`

### Main API

- `generate_contract(seed_value: int)`

### Contract Output

Signal emitted: `contract_generated(contract: Dictionary)`

Payload structure:

- `contract_seed`
- `world_profile`
  - `planet_key`
  - `profile_seed`
  - `world_label`
  - `compound_area_ratio`
  - `open_layout_chance`
  - `open_layout_carve_ratio`
  - `foliage_density`
  - `foliage_compound_density_multiplier`
  - `fruit_spawn_chance_shrub`
  - `fruit_spawn_chance_tree`
  - `tile_tint`
  - `wall_tint`
  - `foliage_tint`
  - `critter_tint`
- `planet`
  - `key`
  - `scene_path`
  - `planet_seed`
  - `instance`
- `map`
  - `map_seed`
  - `instance`
  - `level_data`

## Determinism

A single seed initializes one RNG stream, then derives:

- `planet_key`
- `planet_seed`
- `world_profile`
- `map_seed`

This ensures stable planet+map pairing per contract seed.

## Current Planet Library

- `terran_wet` -> `res://Planets/Rivers/Rivers.tscn`
- `terran_dry` -> `res://Planets/DryTerran/DryTerran.tscn`
- `islands` -> `res://Planets/LandMasses/LandMasses.tscn`
- `ice_world` -> `res://Planets/IceWorld/IceWorld.tscn`
- `lava_world` -> `res://Planets/LavaWorld/LavaWorld.tscn`
- `gas_giant` -> `res://Planets/GasPlanet/GasPlanet.tscn`

## Notes

- Planet instance methods are applied when available:
  - `set_seed(...)`
  - `set_rotates(false)`
  - `set_light(...)`
- Procgen map generation uses `ProcGenTilemap.level_data_ready` and forwards resulting level data inside the contract payload.

## Implementation Status

- `custodian/procgen/custodian_contract_map.gd` is implemented and wired.
- `custodian/procgen/custodian_contract_map.tscn` provides `PlanetRoot` + `MapRoot`.
- Single-seed deterministic contract payload validated in headless smoke test.

## Runtime Safety Fixes Included

- `generate_contract(...)` waits for node readiness (`await ready`) so `PlanetRoot`/`MapRoot` are valid.
- Procgen startup race handled by waiting until `procgen_node.is_generating()` is false before map-driven generation.
- Map-level-data await uses a one-shot callback + frame loop guard to avoid missed-signal hangs.

## Active World Wiring

- `res://core/systems/contract_world_loader.gd` now listens to `contract_generated`.
- On generation, it re-parents the contract `ProcGenMap` instance into active world runtime container:
  - `World/ProcGenRuntime`
- Static sector visuals are hidden (systems remain available), and runtime entities are aligned to contract map data:
  - Operator moved to an open walkable tile inside the generated compound, preferring ingress-adjacent courtyard tiles and avoiding wall-locked pockets (fallback `level_data.player_spawn`)
  - Spawn nodes redistributed across `level_data.corridor_spawns` (fallback `rooms_by_distance`)
  - Command terminal snapped to a walkable compound tile instead of unrelated room samples, preventing unreachable terminal placement
  - Legacy sector nodes are rescaled to the procgen tile size before being repositioned onto compound building pads, so their footprint does not spill outside the generated map zone

## Map Feel Controls (Implemented)

- `ProcGenTilemap` now supports deterministic atlas variation for floor/walls:
  - `use_floor_variants`, `floor_variant_coords`
  - `use_wall_variants`, `wall_variant_coords`, `high_wall_variant_coords`
- Added compound-first generation layer inside procgen tile projection:
  - `enable_compound_zone`
  - `compound_area_ratio` (10%–20% supported)
  - bounded min/max compound dimensions
  - perimeter walls + ingress points + internal building blocks
  - building blocks now use fixed sector-like footprint presets (command/power/defense/storage style scales)
  - sealed compound floor pockets that are not reachable from any ingress are converted into explicit hole tiles (`[9,2]`) instead of remaining accidental spawnable floor
- Added layout diversity controls:
  - `open_layout_chance`
  - `open_layout_carve_ratio`
  - prevents cave-like output every run
- Added planet-driven world coupling:
  - `CustodianContractMap` derives a deterministic `world_profile` from the selected contract planet
  - `ProcGenTilemap` consumes that profile before generation so planet choice changes layout, foliage, and tinting
  - `level_data` forwards `world_profile` so runtime systems can stay on the same planet identity contract
- Runtime loader now disables legacy sector collisions when static sectors are hidden, removing invisible-wall artifacts.
- `ProcGenTilemap` can build runtime wall colliders (`build_runtime_wall_collision`) so wall blocking does not depend on TileSet physics metadata.

## Planet <-> Runtime World Coupling

The generated contract planet is the source of truth for the runtime world profile.

This profile is not decorative metadata. It must produce visible and mechanical differences inside the promoted combat world so the player is clearly on the contracted planet rather than on a generic procgen slice.

Current intended consequences:

- compound footprint bias changes by planet
- openness / carved traversal lanes change by planet
- foliage density and fruit spawning change by planet
- floor / wall / foliage tint shifts follow the selected planet palette
- ambient critter tint / pacing can read from the same profile

That keeps the contract preview, promoted map, and runtime ambience bound to one deterministic source instead of drifting into separate systems.

## Validation Command

From repo root:

```bash
godot --headless --path custodian --script /tmp/contract_smoke.gd
```

Expected output includes:

- `contract_seed=<seed>`
- `planet_key=<planet>`
- `planet_seed=<int>`
- `map_seed=<int>`
- `level_data_keys=[...]`
