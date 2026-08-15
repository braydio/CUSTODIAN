# CUSTODIAN Visual Labs

Visual labs are small Godot `@tool` scenes for art-heavy iteration. They render
directly in the 2D editor and can be run alone with F6. They do not boot the
game, load campaign state, or replace runtime validation.

## Sundered Keep Shoreline

1. Open `res://tools/visual_labs/sundered_keep_shoreline_lab.tscn`.
2. Adjust the exported shoreline, visibility, seed, and fixture controls in the
   Inspector. The 2D editor rebuilds automatically.
3. Use the Inspector buttons to regenerate, step seeds, reset defaults, save a
   compact fixture, or capture the current viewport.
4. Press F6 only when an interactive standalone view is useful.
5. Run the production procgen smokes and Moment Forge after the composition is
   ready for regression approval.

The lab and `ProcGenTilemap` both use
`SunderedKeepShorelineCompositor`. The lab contains no alternate coastline
renderer or topology resolver.

Most current procgen tile-art regions are 32px, but the shared `TileSet` grid is
currently 16px. Production `ProcGenMap` runs under a 2x world transform, so its
generated TileMap cells are currently 32px apart in world space. The lab
intentionally mirrors that root scale and derives its cell world size from the
live `TileMapLayer` transform; changing either root scale or the TileSet grid
does not require changing compositor constants. `cliff_spacing_px` is a
world-space distance, so its 32px default currently yields one cliff sample per
generated cell. The Inspector's `corner_overlap_px` control is extra
transition/corner overlap and is passed through the compositor's existing
`cliff_overlap_px` compatibility option.

Fixtures live under `fixtures/sundered_keep_shorelines/` and contain only a
seed, floor cells, ocean cells, and optional bounds. Captures are written to
`reports/visual_labs/sundered_keep_shoreline/`.
