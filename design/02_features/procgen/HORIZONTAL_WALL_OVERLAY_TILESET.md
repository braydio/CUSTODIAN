# Horizontal Wall Overlay Tileset

**Project:** CUSTODIAN  
**Status:** Deprecated / Historical Reference  
**Updated:** 2026-04-20

## Goal

This document is retained as historical reference for the removed marble overlay experiment.
The active procgen runtime no longer builds horizontal or vertical runtime wall overlays.
Current runtime authority is tile-only wall rendering through `dungeon_tileset.tres`.

## Asset Contract

- Source sheet: `custodian/content/tiles/walls/marble_ruined_walls_3x4_96x96.png`
- Runtime atlas: `custodian/content/tiles/walls/runtime/marble_ruined_walls_runtime_3x4_96x96.png`
- Rows are style variants.
- Columns are:
  - column 0 = left cap
  - column 1 = continuous stretch section
  - column 2 = right cap
- Endcap source sheet: `custodian/content/tiles/walls/marble_ruined_walls_96x96_endcaps.png`
- Endcap runtime atlas: `custodian/content/tiles/walls/runtime/marble_ruined_walls_runtime_endcaps_7x1_96x96.png`

## Runtime Integration

- Not active in the current runtime.
- Procgen wall logic remains tile-based and collision-authoritative.
- Wall visuals now come directly from the wall tile atlas and the collision footprint matches the visible tile footprint.

## Non-Goals

- Replacing per-tile wall collision with sprite collision
- Changing procgen layout rules
- Replacing vertical wall-side visuals with this sheet
