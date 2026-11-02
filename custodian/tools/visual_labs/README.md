# CUSTODIAN Visual Labs

Visual labs are small Godot `@tool` scenes for art-heavy iteration. They render
directly in the 2D editor and can be run alone with F6. They do not boot the
game, load campaign state, or replace runtime validation.

## Sundered Keep Shoreline

1. Open `res://tools/visual_labs/sundered_keep_shoreline_lab.tscn`.
2. Adjust the exported shoreline, visibility, debug, production-context, seed,
   and fixture controls in the Inspector. The 2D editor rebuilds automatically.
3. Use the Inspector buttons to regenerate, step seeds, reset defaults, save a
   compact fixture, or capture the current viewport.
4. Press F6 only when an interactive standalone view is useful.
5. Run the production procgen smokes and Moment Forge after the composition is
   ready for regression approval.

The lab and `ProcGenTilemap` both use
`SunderedKeepShorelineCompositor`. The lab contains no alternate coastline
renderer or topology resolver. `Cliff Vocabulary` is the controlled review
preset: it includes long cardinal runs, convex/concave corners, a staircase,
and coves so the full existing 15-piece vocabulary can be audited together.

Use the lab in three passes:

1. **Topology microscope:** context `None`, floor/foam hidden as useful, and
   boundary/sample/corner overlays enabled.
2. **Materials bench:** `Ocean Underlay`, using the same cell-authoritative
   storm-ocean mask builder as production. Floor cells remain transparent in
   the underlay mask.
3. **Dress rehearsal:** a production fixture plus `Full Vista`, optionally at
   `Vista Apex`. Full Vista is authoritative only when the fixture includes
   `vista_context`; otherwise the lab warns and falls back to masked ocean.

Production context is view-only. It is a shared passive-art scene instanced by
both the lab and production, and it never participates in compositor plan
generation or cliff transforms.

Most current procgen tile-art regions are 32px, but the shared `TileSet` grid is
currently 16px. Production `ProcGenMap` runs under a 2x world transform, so its
generated TileMap cells are currently 32px apart in world space. The lab
intentionally mirrors that root scale and derives its cell world size from the
live `TileMapLayer` transform; changing either root scale or the TileSet grid
does not require changing compositor constants. `cliff_spacing_px` is a
world-space distance, so its 32px default currently yields one cliff sample per
generated cell. Valid topology corners replace nearby straight samples within
`0.75 * cliff_spacing_px` (24 world px at the default). The Inspector's
`corner_overlap_px` remains serialized through the compositor's legacy
`cliff_overlap_px` option for fixture compatibility; it no longer controls the
topology corner exclusion distance.

Fixtures live under `fixtures/sundered_keep_shorelines/` and contain only a
seed, floor cells, ocean cells, optional bounds, and optional `vista_context`
anchors. Captures are written to `reports/visual_labs/sundered_keep_shoreline/`.
