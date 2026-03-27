# World Scale Contract

Last updated: 2026-03-07

This document defines canonical world-unit sizing so scene layout, runtime behavior,
and design docs use the same scale assumptions.

## Core Units

- `1 tile = 24 world units (px)`
- Sector dimensions are authored in `size_tiles` and converted by `Sector.TILE_PX = 24`.
- Camera gameplay baseline zoom: `Vector2(1.0, 1.0)`.

## Actor Footprints (Gameplay Targets)

- Operator: approximately `2.0 x 2.0` tiles visual footprint.
- Drone (base): approximately `1.0 x 1.0` tiles.
- Fast drone: approximately `0.75 x 0.75` tiles.
- Heavy drone: approximately `1.4 x 1.4` tiles.
- Turret base: approximately `1.2 x 1.2` tiles.

## Sector Layout Rules

- Sector centers should be placed on multiples of 24 world units.
- Neighboring sectors must not overlap in AABB bounds.
- `COMMAND` can be larger than utility sectors, but should remain in the `24-36` tile band
  for current gameplay slice to preserve readable traversal distances.

## UI/Design Consistency Rules

- Any design doc that references map size/spacing should use tile counts first,
  then derive world units using `24 px/tile`.
- If camera zoom is changed for a feature test, update this file and the active scene notes.
