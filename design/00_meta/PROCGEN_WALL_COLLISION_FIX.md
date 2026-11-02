# Procgen Runtime Wall Collision Compaction

**Status:** chunk-body compaction implemented; rectangle-shape merging deferred

## Current Runtime

`ProcGenTilemap` groups visible runtime wall tiles into deterministic streaming-sized chunks. Each chunk owns one `StaticBody2D` (`RuntimeWallChunk`) with per-tile `CollisionShape2D` children and exact tile metadata. The compatibility export `compact_runtime_wall_bodies` can restore legacy one-body-per-tile construction, but compact mode is the default.

Destructible projectile paths pass the impact position to a chunk body. `RuntimeWallChunk` resolves the nearest owned shape, verifies the source tile, and calls `damage_wall_tile(...)` for that tile only. A missing impact position fails closed instead of damaging an arbitrary neighbor.

Streaming reveal creates wall shapes incrementally, suppresses per-tile debug reconstruction, and coalesces overlay, shadow, collision-safety synchronization, and navigation refresh to a bounded interval or queue completion.

## Measurement Contract

Developer Observatory publishes generated wall cells, runtime wall bodies, runtime wall shapes, body peaks, map/generation identity, global node/physics/collision peaks, and loaded world/procgen roots. Body count should track occupied chunks, while shape count tracks visible collidable wall cells.

A representative `96x80` smoke fixture currently produces `585` wall shapes in `28` bodies. This is body compaction, not yet shape compaction.

## Authority Constraints

- Destroying one tile removes only that tile's visual, generated-wall, collision-shape, and navigation authority.
- Projectiles must provide exact contact position when hitting a compact destructible wall body.
- Regeneration and unload must remove empty chunk bodies and must not accumulate stale shapes or roots.
- Camera/screen visibility is not wall collision authority.

## Acceptance

- `compound_wall_smoke.gd` and `procgen_authored_scene_authority_smoke.gd` pass.
- `runtime_wall_collision_compaction_smoke.gd` proves bodies are materially fewer than shapes.
- The compaction smoke destroys the contacted tile and proves a neighboring tile remains a wall with collision.
- Runtime debug reconstruction occurs only when debug drawing is enabled and never once per reveal tile.

## Next Slice

Merge static contiguous tiles into horizontal/rectangular shapes, retaining individual shapes for destructible cells where exact split/rebuild cost would otherwise be unsafe.
