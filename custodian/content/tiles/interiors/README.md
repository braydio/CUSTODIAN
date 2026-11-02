# Interior Tiles

This folder contains the first constructed-interior tile art for procgen warehouse / military-complex regions.

## Runtime Tiles

Runtime-ready Godot TileSet inputs live in:

```text
runtime/
  floor_*_32.png
  floor_grate_32.png
  floor_panel_32.png
  threshold_*_32.png
  doorway_*_32.png
  wall_*_32.png
  wall_*corner*_32.png
```

These are `32x32` PNGs. Add a new runtime tile by saving it with the matching convention, then run:

```bash
cd custodian
python tools/tiles/register_interior_floor_tiles.py
```

The registration script adds missing one-tile sources to `content/tiles/tilesets/procgen_world_tileset.tres` and refreshes `game/world/procgen/proc_gen_map.tscn`.
It also prunes stale interior TileSet sources when their runtime PNG no longer exists, because a missing TileSet texture prevents the procgen map from loading.

- `floor_*_32.png` files are written into `interior_floor_source_ids`.
- `threshold_*_32.png` files are written into `interior_threshold_source_ids`.
- `doorway_*_32.png` files are written into `interior_doorway_source_ids`.
- non-corner `wall_*_32.png` files are written into `interior_wall_source_ids` and the legacy `interior_wall_source_id` fallback.
- `wall_*corner*_32.png` files are treated as corner art; the first sorted match is written into `interior_wall_corner_source_id`.

Use `--dry-run` to preview source IDs without writing files.

Procgen reduces visible floor repetition at placement time. `ProcGenTilemap` groups floor variants into small deterministic patches, adds occasional accent cells, and uses flip/transpose TileSet alternatives for square `32x32` floor art. Tune `interior_floor_patch_size_tiles`, `interior_floor_accent_chance`, or disable `interior_floor_use_transforms` on the procgen node if an authored tile should not be transformed.

## Runtime Props

Interior decorative props can live beside the floor and wall runtime tiles:

```text
runtime/
  props_*.png
  prop_*.png
```

`props_` is the preferred prefix; `prop_` is also accepted for singular legacy names. `ProcGenTilemap` loads these PNGs directly and scatters them as decorative `Sprite2D` nodes on constructed interior floor tiles. They do not need TileSet registration.

Outdoor ruin props are a separate system under `res://content/props/ruins/`; they are intentionally filtered away from indoor region tiles.

## Source Art

Large generated/reference images live in:

```text
source/
```

Several incoming files had `_32` in the filename but were actually `1254x1254`; those are preserved in `source/` and should not be referenced directly by runtime TileSet sources.

## Still Needed

- `wall_military_top_32.png`
- More wall connector pieces if interiors need cleaner corners, T-junctions, and endcaps
- Optional interior props: crates, lockers, consoles, cable clutter, hazard markers
