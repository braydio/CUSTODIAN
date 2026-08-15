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

Fixtures live under `fixtures/sundered_keep_shorelines/` and contain only a
seed, floor cells, ocean cells, and optional bounds. Captures are written to
`reports/visual_labs/sundered_keep_shoreline/`.
