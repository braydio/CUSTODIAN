# Procgen Wall Tile Bridge

Status: implementation-ready

## Purpose

Bridge the generated variable-size wall modules into the live procgen TileMap workflow by producing a fixed-grid,
Godot-ready wall atlas and semantic coordinate mapping.

The current procgen wall runtime expects one wall cell to resolve to one atlas coordinate. This bridge preserves that
contract and does not alter wall placement, destructible wall logic, or collision.

## Active Runtime Context

- Runtime procgen script: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Runtime procgen scene: `custodian/game/world/procgen/proc_gen_map.tscn`
- Runtime TileSet path expected by scene: `custodian/content/tiles/tilesets/dungeon_tileset.tres`
- Existing wall source ID in scene before this bridge: `11`
- Existing source ID `11` atlas region size: `32x32`

## Drift Note

During implementation, `custodian/content/tiles/tilesets/dungeon_tileset.tres` was missing from the worktree while
`proc_gen_map.tscn` still referenced it. A matching copy existed at
`custodian/content/dev/tilesets/dungeon_tileset.tres`. The active TileSet path was recreated from that copy before
adding the generated wall source.

## Inputs

- `custodian/assets/tiles/walls/generated/procgen_wall_source_parts.json`
- `custodian/assets/tiles/walls/generated/procgen_wall_source_atlas.png`
- `tools/tiles/procgen_wall_semantics.json` for optional curated role overrides
- `custodian/content/tiles/walls/source/wall_passages/` for optional `32px`-tall wall passage strips

## Outputs

- `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.png`
- `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.mapping.json`
- Runtime TileSet source ID: `12`

## Builder

`tools/tiles/build_procgen_wall_atlas.py`:

1. Loads extracted part metadata and the packed wall atlas.
2. Loads optional semantic role overrides.
3. Crops each source module from the packed atlas.
4. Trims transparent padding.
5. Slices modules into fixed `32x32` cells.
6. Optionally slices `32px`-tall passage strips from `custodian/content/tiles/walls/source/wall_passages/`.
7. Crops tall modules to the bottom `32px` window by default.
8. Emits a fixed-grid runtime atlas.
9. Emits mapping buckets compatible with `ProcGenTilemap` exported coordinate arrays.

No scaling, stretching, rotation, or resampling is performed.

The resized canonical source plus passage-strip generation emitted `94` runtime cells: `79` cells from `46` extracted
source modules, plus `15` passage cells from four wall passage strips. Twenty-six source modules were taller than
`32px`, so the generated atlas uses the bottom `32px` crop window for those parts. Twenty-eight ambiguous parts are
marked `needs_review` in the mapping JSON.

Passage-strip cells are assigned to:

- `reference_passage_wall_coords`
- `reference_horizontal_hole_bottom_coords`
- `reference_open_left_hole_coords`
- `reference_open_right_hole_coords`
- `reference_cross_hole_coords`

## Semantic Mapping

The mapping JSON contains broad required buckets plus exact current scene property names. The current scene property
names include:

- `reference_horizontal_wall_coords`
- `reference_horizontal_hole_bottom_coords`
- `reference_open_left_wall_coords`
- `reference_open_right_wall_coords`
- `reference_left_terminal_coords`
- `reference_right_terminal_coords`
- `reference_vertical_wall_coords`
- `reference_open_left_corner_coords`
- `reference_open_left_t_coords`
- `reference_open_left_hole_coords`
- `reference_open_right_corner_coords`
- `reference_open_right_t_coords`
- `reference_open_right_hole_coords`
- `reference_cross_wall_coords`
- `reference_cross_hole_coords`
- `reference_north_west_corner_coords`
- `reference_north_east_corner_coords`

Ambiguous pillar/corner-like parts are marked `needs_review`. Fallback buckets are populated from horizontal or cross
fallback cells so the runtime has valid coordinates even before final art curation.

## Godot Integration Plan

1. Add generated atlas as a new `TileSetAtlasSource` in `dungeon_tileset.tres`.
2. Use a new source ID instead of replacing existing source ID `11`.
3. Update both `ProcGenMap` and nested `ProcGen` nodes in `proc_gen_map.tscn` to use the new `walls_source_id`.
4. Update exported reference coordinate arrays from the generated mapping JSON.
5. Keep runtime collision unchanged.

Implementation used source ID `12` for `TileSetAtlasSource_procgen_wall_generated`. `dungeon_tileset.tres` also now
loads the floor atlas from its existing source PNG instead of a stale `.godot/imported` cache path, because the active
TileSet file had been missing and the recreated copy pointed at an unavailable cache artifact.

## Validation

Run:

```bash
python3 tools/tiles/build_procgen_wall_atlas.py --help
python3 tools/tiles/build_procgen_wall_atlas.py \
  --parts-json custodian/assets/tiles/walls/generated/procgen_wall_source_parts.json \
  --atlas custodian/assets/tiles/walls/generated/procgen_wall_source_atlas.png \
  --semantics tools/tiles/procgen_wall_semantics.json \
  --passage-dir custodian/content/tiles/walls/source/wall_passages \
  --out-image custodian/content/tiles/walls/generated/procgen_wall_tiles_32.png \
  --out-json custodian/content/tiles/walls/generated/procgen_wall_tiles_32.mapping.json \
  --tile-size 32
cd custodian && godot --headless --quit
```

Validation result:

- `python3 tools/tiles/build_procgen_wall_atlas.py --help` succeeds.
- Real builder command succeeds and writes the fixed-grid atlas plus mapping JSON.
- `cd custodian && godot --headless --quit` exits `0`.
- Existing project exit warnings remain: ObjectDB leak warning and `14 resources still in use at exit`.
- The latest validation also reports an unrelated runtime scene boot error: `InventoryDisplay` is already parented under
  `DebugPanel`.

## Documentation Drift Check

Checked paths:

- `custodian/game/world/procgen/proc_gen_tilemap.gd` exists.
- `custodian/game/world/procgen/proc_gen_map.tscn` exists.
- `custodian/content/tiles/tilesets/dungeon_tileset.tres` was missing and recreated from `custodian/content/dev/tilesets/dungeon_tileset.tres`.
- `custodian/assets/tiles/walls/generated/procgen_wall_source_parts.json` exists.
- `custodian/assets/tiles/walls/generated/procgen_wall_source_atlas.png` exists.
- `custodian/docs/ai_context/` exists.
- `design/` exists.
