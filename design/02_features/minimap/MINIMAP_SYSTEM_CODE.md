# Minimap System Code Plan

Status: complete

## Files

- `custodian/game/world/procgen/proc_gen_tilemap.gd`
- `custodian/game/ui/minimap/minimap_view.gd`
- `custodian/game/ui/minimap/minimap_controller.gd`
- `custodian/game/ui/minimap/minimap_panel.tscn`
- `custodian/scenes/game.tscn`
- `custodian/game/ui/hud/ui.gd`

## ProcGen Hooks

Add:

```gdscript
signal minimap_tile_changed(tile: Vector2i, terrain_kind: String)
```

Add `ProcGenTilemap` to group `procgen_tilemap` in `_ready()`.

Expose:

```gdscript
func global_to_minimap_tile(global_position: Vector2) -> Vector2i
func minimap_tile_to_global(tile: Vector2i) -> Vector2
```

Add helper:

```gdscript
func _dict_keys_as_vector2i_array(source: Dictionary) -> Array[Vector2i]
```

Extend `get_level_data()` with:

- `tile_size`
- `floor_cells`
- `wall_cells`

Emit `minimap_tile_changed.emit(pos, "floor")` when `damage_wall_tile()` destroys a wall.

## UI

Create `MinimapView` as a `Control` that:

- caches terrain into `ImageTexture`
- draws the cached map into a padded square rect
- draws compound/room overlays
- draws player/enemy/objective pips
- supports targeted tile updates

Create `MinimapController` as a `Control` root that:

- discovers `ProcGenTilemap` by group
- connects `level_data_ready` and `minimap_tile_changed`
- refreshes player/enemy/objective nodes by group
- passes data into `MinimapView`

Create `minimap_panel.tscn` as a compact top-right tactical panel and instance it under `UI` in `game.tscn`.

## HUD Console

Keep existing `toggle_minimap` and `minimap_status` commands, but make status use generic custom minimap methods instead of addon-specific fields.
