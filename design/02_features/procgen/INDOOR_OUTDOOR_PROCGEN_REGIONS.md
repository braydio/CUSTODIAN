# Indoor / Outdoor Procgen Regions

Status: first runtime slice implemented

## Purpose

Add region-aware procgen so a generated tactical map can contain both exterior/natural space and constructed interior space without changing scenes or splitting navigation authority.

The first implementation keeps the existing single-map contract flow:

- Natural/exterior terrain is still produced by the current room/cellular procgen path.
- A constructed interior region is stamped into part of the generated map.
- Interior floors, walls, hallway tiles, rooms, bays, and thresholds are recorded as region metadata.
- Runtime wall collision and navigation still derive from normal floor/wall TileMap state.

## First Slice

Runtime file:

- `custodian/game/world/procgen/proc_gen_tilemap.gd`

The first slice adds:

- `interior_region_enabled`
- `interior_region_min_size`
- `interior_region_max_size`
- `interior_region_hallway_width`
- `interior_region_room_count`
- `interior_region_entrance_count`
- `interior_region_debug_logging`
- `interior_use_dedicated_tiles`
- `interior_floor_source_ids`
- `interior_wall_source_ids`
- `interior_wall_source_id`
- `interior_wall_corner_source_id`
- `interior_tile_atlas_coord`
- `interior_floor_use_transforms`
- `interior_floor_patch_size_tiles`
- `interior_floor_accent_chance`

Generation order:

1. Fill natural floor/wall tiles from the base procgen generator.
2. Apply the compound zone.
3. Apply one constructed interior region.
4. Refresh cohesive wall visuals.
5. Capture floor/wall state for streaming, collision, props, and foliage.

The constructed region starts as a wall-filled rectangle, then carves:

- a central hallway spine
- side rooms above and below the hallway
- one larger warehouse-style bay
- one or more threshold openings to the surrounding exterior

## Interior Tile Family

The first dedicated military/warehouse tile family is wired through `custodian_world_tileset.tres` and maintained by:

```bash
cd custodian
python tools/tiles/register_interior_floor_tiles.py
```

Runtime tile naming conventions:

- `res://content/tiles/interiors/runtime/floor_*_32.png`
- `res://content/tiles/interiors/runtime/wall_*_32.png`
- `res://content/tiles/interiors/runtime/wall_*corner*_32.png`

The script preserves existing TileSet source IDs, adds missing one-tile sources, refreshes `interior_floor_source_ids`, refreshes `interior_wall_source_ids`, keeps `interior_wall_source_id` as a fallback to the first wall source, and assigns the first sorted corner wall source to `interior_wall_corner_source_id`.

Interior floor cells pick deterministically from their source ID array using low-frequency patches plus occasional per-cell accent picks, then apply stable flip/transpose TileSet alternatives to reduce obvious repetition without mutating source art. Non-corner wall cells pick deterministically from their wall source ID array. Threshold openings still carve floor connectivity first; final doorway/cap art is deferred until clean runtime tiles exist.

## Interior Runtime Props

Constructed interiors can scatter decorative runtime prop sprites from:

- `res://content/tiles/interiors/runtime/props_*.png`
- `res://content/tiles/interiors/runtime/prop_*.png`

`ProcGenTilemap` loads these PNGs at startup and places bottom-centered `Sprite2D` nodes under `NavigationRegion2D/PropLayer` on deterministic interior floor candidates. Placement uses stable tile-hash ordering, minimum spacing, optional wall clearance, doorway/threshold clearance, and small deterministic jitter. These props are decorative only in this slice; they do not add collision, loot, or interaction authority.

## Region Metadata

`ProcGenTilemap` tracks region data per tile:

- `interior_wall`
- `interior_floor`
- `interior_threshold`
- `exterior_threshold`
- default fallback: `exterior`

Public helpers:

```gdscript
get_region_type_at_tile(tile: Vector2i) -> String
get_region_data_at_tile(tile: Vector2i) -> Dictionary
is_indoor_tile(tile: Vector2i) -> bool
```

`get_level_data()` now includes:

- `interior_region_rect`
- `interior_rooms`
- `interior_thresholds`
- `region_tiles`

## Spawn Filtering

Outdoor dressing is excluded from indoor tiles in this slice:

- foliage does not spawn on indoor region tiles
- ruin props do not spawn on indoor region tiles
- foliage and ruin props also use a small clearance radius around indoor region tiles so large outdoor sprites cannot visually overhang room-border interior cells
- interior runtime props are the indoor-specific decorative pass and use the same region metadata instead of the outdoor ruin prop filters

Future indoor-specific prop/enemy/loot tables should use the same region metadata instead of re-detecting layout from visuals.

## Deferred Work

- Dedicated `wall_military_top_32.png`, `doorway_military_32.png`, and `threshold_metal_32.png` runtime tiles.
- Multiple indoor regions.
- Better region placement rules by world profile and mission archetype.
- Template-authored rooms through Edgar/Tiled.
- Indoor-specific lighting, occlusion, doors, terminals, props, enemies, and loot.
- Region-aware ambient critter behavior beyond existing outdoor spawn exclusion.

## Validation

Ran:

```bash
godot --headless --path custodian --quit
```

Result: completed without new script load errors. Existing exit resource leak warnings remain.
