# Procgen Runtime Wall Collision Compaction

**Status:** collision authority is live; measurement pass implemented, compaction deferred

## Current Runtime

`ProcGenTilemap` currently creates one `StaticBody2D` plus one `CollisionShape2D` for each visible runtime wall tile under `Walls/RuntimeWallCollision`. When `destructible_runtime_walls` is enabled, each body is a `ProcGenRuntimeWallSegment` and retains its exact source tile so projectile damage can call `damage_wall_tile(...)`.

The old diagnosis that procgen had no wall collision is retired. Runtime walls are blocking correctly, but dense maps can create hundreds of bodies and shapes.

## Measurement Contract

Developer Observatory publishes:

- `procgen_generation_id` / `procgen_generation_count`
- `procgen_map_width` / `procgen_map_height`
- `procgen_generated_wall_cells`
- `procgen_runtime_wall_body_count` / `procgen_runtime_wall_body_peak`
- `node_count_peak`, `physics_body_count_peak`, and `collision_shape_count_peak`
- `loaded_world_branch_count` and `loaded_procgen_root_count`

Compare wall-body count with generated wall cells across regeneration and level handoffs. Proportional stable counts indicate architecture cost; increasing body counts with stable wall cells or multiple loaded procgen roots indicate cleanup/ownership leakage.

## Compaction Constraint

Do not merge wall bodies without preserving per-tile destruction authority. A merged rectangle hit must still resolve the struck tile before applying damage. Acceptable implementations include:

1. Horizontal run bodies with one shape per tile and shape-owner-to-tile metadata.
2. Merged rectangles plus contact-point-to-tile resolution validated against `_generated_wall_cells`.
3. Non-destructible merged runs only, retaining per-tile segments for destructible walls.

The first optimization target is horizontal run merging, followed by optional vertical merging of identical runs. Rebuild or split only the affected run when wall authority changes.

## Acceptance Before Enabling Compaction

- Existing compound wall and authored-scene authority smokes still pass.
- Projectiles damage the contacted wall tile, not an adjacent tile in the same run.
- Destroyed walls remove only their intended collision authority.
- Runtime wall bodies fall materially below generated wall-cell count on representative maps.
- Regeneration does not increase bodies, shapes, or loaded procgen roots for equivalent map data.
