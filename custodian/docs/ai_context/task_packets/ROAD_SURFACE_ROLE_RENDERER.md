# Road Surface Role Renderer

## Packet Status

- Status: complete
- Owner: Codex
- Updated: 2026-07-30

## Outcome

The contract-world road system retains its centerline, connectivity, parking,
vehicle placement, foliage exclusion, and movement-surface semantics. Its
base visual renderer no longer assigns lane-offset roles. Every
`_main_road_tiles` cell is classified from cardinal and diagonal neighbors as
center, cardinal edge, outer corner, or inner corner and receives exactly one
32×32 decal from:

`res://content/tiles/roads_paths/runtime/roads/surface/road_surface_piece_manifest.game32.json`

Footpaths remain independent and continue using connection-bitmask pieces.
Streaming removal/reveal reconstructs the same deterministic surface role.

## Runtime

- `game/world/procgen/proc_gen_tilemap.gd`
- `content/tiles/roads_paths/runtime/roads/surface/`
- `tools/validation/procgen_road_surface_roles_smoke.gd`

## Validation

```bash
godot --headless --path custodian \
  --script res://tools/validation/procgen_road_surface_roles_smoke.gd
```
