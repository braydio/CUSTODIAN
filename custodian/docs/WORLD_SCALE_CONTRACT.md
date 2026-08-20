# World Scale Contract

Last updated: 2026-08-20

This document distinguishes runtime grids so scene layout, runtime behavior, and
design docs do not collapse several valid local scales into one ambiguous
global “tile.”

## Core Units

- Sector logical tiles remain `24` world units.
- Sector dimensions are authored in `size_tiles` and converted by `Sector.TILE_PX = 24`.
- Live camera base zoom: `Vector2(0.84, 0.84)` in `game/world/camera.gd`;
  contextual move/combat profiles may override it.

## Local Authored Cells

Authored landmark and level pipelines may declare their own local authored-cell
scale. This is not a global scale migration and must not change `Sector.TILE_PX`.

- Sundered Keep/game32 content uses 32-world-unit authored cells where its
  active design/runtime explicitly declares that grid.
- Ash-Bell Lower Quarter, West Gate Works, and Station IX use
  `AUTHORING_CELL_SIZE_WORLD = 32.0`.
- Procgen and Sector systems may continue using 24-world-unit logical tiles
  where their runtime contracts say so.

Design and code must say “Sector tile,” “procgen tile,” or “authored cell” and
name the conversion rather than referring to a supposedly universal tile.

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

- Any design doc that references map size/spacing must identify the owning grid,
  state its world-unit conversion, and use its cell/tile counts first.
- If camera zoom is changed for a feature test, update this file and the active scene notes.
