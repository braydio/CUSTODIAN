# Sundered Keep Underlay Gameplay Tile Mapper — Implementation Tasks

## Current State

**Live scene:** `custodian/scenes/debug/sundered_keep_underlay_gameplay_tile_mapper.tscn`

Structure:
```text
SunderedKeepUnderlayGameplayTileMapper
├── World
│   ├── PlacedGameplayTiles
│   ├── TilePalette
│   ├── MapperOverlay
│   └── Camera2D
└── CanvasLayer
    └── Help
```

Scripts: `sundered_keep_underlay_gameplay_tile_mapper.gd`, `sundered_keep_underlay_gameplay_tile_mapper_overlay.gd`

The mapper correctly:
- Instantiates the reviewed underlay/collision scene (`sundered_keep_production_underlay_debug.tscn`)
- Writes to `res://content/levels/sundered_keep/sundered_keep_underlay_gameplay_tiles.json`
- Uses `MAP_SIZE = Vector2(3584.0, 2560.0)`, `TILE_SIZE = 32`
- Builds a 99-tile palette from Sundered Keep floor/wall/rampart paths + traversal extras
- Supports click-to-select palette, click-to-place, right-click removal, save/load JSON
- Exposes mapper state (map size, tile size, palette, placements, selected tile, visibility flags) to overlay
- Overlay draws underlay grid, palette grid, collision rails, and cursor cell

**Gap:** `SunderedKeepMap` does not consume `sundered_keep_underlay_gameplay_tiles.json` yet. The mapper is an authoring surface but not a live gameplay tile pipeline.

---

## Task 1: Wire Mapper Output Into Production Runtime

**Target:** `custodian/game/world/sundered_keep/sundered_keep_map.gd`

**Constraints:** No changes to combat, routing, collision mapper, level JSON `ops` pipeline, or TileMapLayer replacement. Gameplay tile mapper document is an authored overlay consumed by SunderedKeepMap.

### 1.1 Add constant

```gdscript
const UNDERLAY_GAMEPLAY_TILE_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_underlay_gameplay_tiles.json"
)
```

Place near `DEFAULT_LEVEL_DATA_PATH`, `UNDERLAY_COLLISION_DATA_PATH`, `SUNDERED_KEEP_ASSETS`.

### 1.2 Add storage field

```gdscript
var _underlay_gameplay_tile_data: Dictionary = {}
```

### 1.3 Load in `_build_from_level_data(data)`

After the level ops loop (`for op in data.get("ops", []): _apply_level_op(op)`), call `_apply_underlay_gameplay_tile_mapping()` before markers/interactables/blockers/stateful gates.

### 1.4 Add loader

```gdscript
func _load_underlay_gameplay_tile_data() -> Dictionary:
	if not ResourceLoader.exists(UNDERLAY_GAMEPLAY_TILE_DATA_PATH):
		return {}

	var file := FileAccess.open(UNDERLAY_GAMEPLAY_TILE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("[SunderedKeep] Could not open underlay gameplay tile mapping: %s" % UNDERLAY_GAMEPLAY_TILE_DATA_PATH)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("[SunderedKeep] Invalid underlay gameplay tile mapping JSON")
		return {}

	var data := parsed as Dictionary
	if str(data.get("schema", "")) != "custodian.sundered_keep.underlay_gameplay_tiles.v1":
		push_warning("[SunderedKeep] Unsupported underlay gameplay tile mapping schema")
		return {}

	var tile_size := int(data.get("tile_size", int(TILE_SIZE)))
	if tile_size != int(TILE_SIZE):
		push_warning("[SunderedKeep] Underlay gameplay tile mapping tile_size=%d does not match runtime TILE_SIZE=%d" % [tile_size, int(TILE_SIZE)])
		return {}

	return data
```

### 1.5 Add application method

```gdscript
func _apply_underlay_gameplay_tile_mapping() -> void:
	_underlay_gameplay_tile_data = _load_underlay_gameplay_tile_data()
	if _underlay_gameplay_tile_data.is_empty():
		return

	var palette_by_number := _underlay_palette_by_number(
		_underlay_gameplay_tile_data.get("palette", []) as Array
	)

	var applied := 0
	for raw_placement: Variant in _underlay_gameplay_tile_data.get("placements", []):
		if not (raw_placement is Dictionary):
			continue

		var placement := raw_placement as Dictionary
		var raw_cell := placement.get("cell", []) as Array
		if raw_cell.size() < 2:
			continue

		var tile_number := int(placement.get("tile_number", 0))
		if not palette_by_number.has(tile_number):
			continue

		var cell := Vector2i(int(raw_cell[0]), int(raw_cell[1]))
		if cell.x < 0 or cell.y < 0 or cell.x >= map_size_tiles.x or cell.y >= map_size_tiles.y:
			continue

		var item := palette_by_number[tile_number] as Dictionary
		if _apply_underlay_gameplay_tile(cell, item):
			applied += 1

	if applied > 0:
		print("[SunderedKeep] Applied %d underlay gameplay tile placement(s)" % applied)
```

### 1.6 Add palette helper

```gdscript
func _underlay_palette_by_number(palette: Array) -> Dictionary:
	var result := {}
	for raw_item: Variant in palette:
		if not (raw_item is Dictionary):
			continue
		var item := raw_item as Dictionary
		var number := int(item.get("number", 0))
		if number > 0:
			result[number] = item
	return result
```

### 1.7 Add tile application helper

```gdscript
func _apply_underlay_gameplay_tile(cell: Vector2i, item: Dictionary) -> bool:
	var asset_id := str(item.get("asset_id", ""))
	var category := str(item.get("category", ""))

	if asset_id.is_empty():
		return false

	match category:
		"floor":
			_add_tile("FloorDetail", asset_id, "floors", cell)
			return true
		"architecture":
			_add_wall_tile(cell, asset_id)
			return true
		"traversal":
			_add_tile("Traversal", asset_id, "traversal", cell)
			if _asset_blocks_movement(asset_id):
				_add_blocker(Rect2i(cell, Vector2i.ONE), "%sUnderlayGameplayBlocker" % asset_id)
			return true
		_:
			_add_tile("FloorDetail", asset_id, _category_for_layer_asset("FloorDetail", asset_id), cell)
			return true
```

Routing: floors → `_add_tile("FloorDetail", ...)`; architecture → `_add_wall_tile(...)` (adds wall sprite + blocker + minimap wall cells); traversal → `_add_tile("Traversal", ...)` with conditional blocker.

### 1.8 Add asset metadata helper

```gdscript
func _asset_blocks_movement(asset_id: String) -> bool:
	var assets: Dictionary = SUNDERED_KEEP_ASSETS.ASSETS
	if not assets.has(asset_id):
		return false
	var entry := assets[asset_id] as Dictionary
	return bool(entry.get("blocks_movement", false))
```

---

## Task 2: Harden the Mapper

### 2.1 Atomic save

Replace `_write_mapping_document()` with atomic write:

```gdscript
func _write_mapping_document() -> bool:
	var document := _mapping_document()
	var absolute := ProjectSettings.globalize_path(TILE_MAPPING_DATA_PATH)
	var text := JSON.stringify(document, "  ") + "\n"

	if not _atomic_write_json_document(absolute, text):
		return false

	_dirty = false
	print(
		"[SunderedKeepUnderlayGameplayTileMapper] "
		+ "Saved %d gameplay tile placement(s) to %s"
		% [_placements.size(), TILE_MAPPING_DATA_PATH]
	)
	_update_help()
	return true
```

```gdscript
func _atomic_write_json_document(path: String, text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("[SunderedKeepUnderlayGameplayTileMapper] Refusing write: generated JSON does not parse")
		return false

	var data := parsed as Dictionary
	if str(data.get("schema", "")) != "custodian.sundered_keep.underlay_gameplay_tiles.v1":
		push_warning("[SunderedKeepUnderlayGameplayTileMapper] Refusing write: generated JSON has wrong schema")
		return false

	var temp_path := "%s.tmp" % path
	var backup_path := "%s.mapper-backup" % path

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("[SunderedKeepUnderlayGameplayTileMapper] Could not write temp file: %s" % temp_path)
		return false
	file.store_string(text)
	file.close()

	file = FileAccess.open(temp_path, FileAccess.READ)
	if file == null or file.get_as_text() != text:
		DirAccess.remove_absolute(temp_path)
		push_warning("[SunderedKeepUnderlayGameplayTileMapper] Temp write verification failed")
		return false
	file.close()

	DirAccess.remove_absolute(backup_path)

	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(path, backup_path) != OK:
			DirAccess.remove_absolute(temp_path)
			push_warning("[SunderedKeepUnderlayGameplayTileMapper] Could not move original mapping to backup")
			return false

	if DirAccess.rename_absolute(temp_path, path) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, path)
		push_warning("[SunderedKeepUnderlayGameplayTileMapper] Could not move temp mapping into place")
		return false

	DirAccess.remove_absolute(backup_path)
	return true
```

### 2.2 Drag painting

Add state:
```gdscript
var _drag_painting := false
var _drag_erasing := false
```

Update `_unhandled_input`:
```gdscript
if event is InputEventMouseButton:
	var mouse := event as InputEventMouseButton

	if mouse.button_index == MOUSE_BUTTON_LEFT:
		_drag_painting = mouse.pressed and Input.is_key_pressed(KEY_SHIFT)
		if mouse.pressed:
			_handle_left_click(_camera.get_global_mouse_position())

	elif mouse.button_index == MOUSE_BUTTON_RIGHT:
		_drag_erasing = mouse.pressed and Input.is_key_pressed(KEY_SHIFT)
		if mouse.pressed:
			_handle_right_click(_camera.get_global_mouse_position())

	elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(zoom_step)

	elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom(1.0 / zoom_step)

elif event is InputEventMouseMotion:
	if _drag_painting:
		_handle_left_click(_camera.get_global_mouse_position())
	elif _drag_erasing:
		_handle_right_click(_camera.get_global_mouse_position())
```

### 2.3 Paint stats in state

Add to `get_gameplay_tile_mapper_state()`:
```gdscript
"dirty": _dirty,
"placement_count": _placements.size(),
"selected_tile": _palette_item(_selected_tile_number),
```

---

## Task 3: Validation Smoke Test

Create: `custodian/tools/validation/sundered_keep_underlay_gameplay_tile_mapper_smoke.gd`

```gdscript
extends SceneTree

const MAPPER_SCENE_PATH := "res://scenes/debug/sundered_keep_underlay_gameplay_tile_mapper.tscn"
const TILE_MAPPING_DATA_PATH := "res://content/levels/sundered_keep/sundered_keep_underlay_gameplay_tiles.json"
const PRODUCTION_SCENE_PATH := "res://game/world/sundered_keep/sundered_keep_map.tscn"

var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	await _validate_mapping_document()
	await _validate_mapper_scene()
	await _validate_production_consumer()
	_finish()

func _validate_mapping_document() -> void:
	var data := _read_json(TILE_MAPPING_DATA_PATH)
	_assert(
		str(data.get("schema", "")) == "custodian.sundered_keep.underlay_gameplay_tiles.v1",
		"underlay gameplay tile mapping schema is invalid"
	)
	_assert(int(data.get("tile_size", 0)) == 32, "underlay gameplay tile mapping tile_size must be 32")
	_assert(int(data.get("palette_count", 0)) == 99, "underlay gameplay tile palette_count must be 99")
	_assert((data.get("palette", []) as Array).size() == 99, "underlay gameplay tile palette must contain 99 entries")
	_assert(data.has("placements"), "underlay gameplay tile mapping missing placements")

func _validate_mapper_scene() -> void:
	var scene := await _instantiate_scene(MAPPER_SCENE_PATH)
	if scene == null:
		return

	_assert(scene.get_node_or_null("World/PlacedGameplayTiles") is Node2D, "gameplay tile mapper missing PlacedGameplayTiles")
	_assert(scene.get_node_or_null("World/TilePalette") is Node2D, "gameplay tile mapper missing TilePalette")
	_assert(scene.get_node_or_null("World/MapperOverlay") is Node2D, "gameplay tile mapper missing MapperOverlay")
	_assert(scene.get_node_or_null("World/Camera2D") is Camera2D, "gameplay tile mapper missing Camera2D")
	_assert(scene.get_node_or_null("CanvasLayer/Help") is Label, "gameplay tile mapper missing Help label")
	_assert(scene.has_method("get_gameplay_tile_mapper_state"), "gameplay tile mapper missing state method")
	_assert(scene.has_method("_mapping_document"), "gameplay tile mapper missing mapping document builder")
	_assert(scene.has_method("_world_to_tile"), "gameplay tile mapper missing world-to-tile helper")

	var state := scene.call("get_gameplay_tile_mapper_state") as Dictionary
	_assert(int(state.get("tile_size", 0)) == 32, "gameplay tile mapper state tile_size must be 32")
	_assert((state.get("palette", []) as Array).size() == 99, "gameplay tile mapper palette should have 99 entries")
	_assert(state.has("placements"), "gameplay tile mapper state missing placements")
	_assert(str(state.get("mapping_path", "")) == TILE_MAPPING_DATA_PATH, "gameplay tile mapper state has wrong mapping path")

	var doc := scene.call("_mapping_document") as Dictionary
	_assert(str(doc.get("schema", "")) == "custodian.sundered_keep.underlay_gameplay_tiles.v1", "mapper mapping document schema invalid")
	_assert(int(doc.get("palette_count", 0)) == 99, "mapper mapping document palette_count invalid")

	scene.queue_free()
	await process_frame

func _validate_production_consumer() -> void:
	var packed := load(PRODUCTION_SCENE_PATH) as PackedScene
	_assert(packed != null, "production Sundered Keep scene did not load")
	if packed == null:
		return

	var scene := packed.instantiate()
	_assert(scene != null, "production Sundered Keep scene did not instantiate")
	if scene == null:
		return

	_assert(scene.has_method("_load_underlay_gameplay_tile_data"), "SunderedKeepMap missing underlay gameplay tile loader")
	_assert(scene.has_method("_apply_underlay_gameplay_tile_mapping"), "SunderedKeepMap missing underlay gameplay tile application")
	_assert(scene.has_method("_apply_underlay_gameplay_tile"), "SunderedKeepMap missing underlay gameplay tile placement helper")

	scene.queue_free()
	await process_frame

func _instantiate_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	_assert(packed != null, "%s did not load" % path)
	if packed == null:
		return null
	var scene := packed.instantiate()
	_assert(scene != null, "%s did not instantiate" % path)
	if scene == null:
		return null
	root.add_child(scene)
	await process_frame
	await process_frame
	return scene

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[SunderedKeepUnderlayGameplayTileMapperSmoke] PASS")
		quit(0)
		return
	print("[SunderedKeepUnderlayGameplayTileMapperSmoke] FAIL failures=%d" % _failures.size())
	quit(1)
```

Run: `cd custodian && godot --headless --script res://tools/validation/sundered_keep_underlay_gameplay_tile_mapper_smoke.gd`

---

## Task 4: Documentation Updates

Update these files:
- `design/02_features/debug_ui/UNDERLAY_GAMEPLAY_TILE_MAPPER.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`

Key note: "Sundered Keep now has a dedicated underlay gameplay tile mapper that writes `sundered_keep_underlay_gameplay_tiles.json`. The production SunderedKeepMap consumes this document as an authored tile overlay. The older collision mapper remains the authority for underlay boundary rails and markers."

---

## Task 5: Underlay Region Stamp Mode

Adds a second paint source: drag-select a rectangular region from the visible underlay, sample it as an active stamp, and place copies onto the gameplay grid.

**Source texture:** `res://content/masters/sundered_keep/sundered_keep_main_overlay.png`
**Gameplay grid:** 112×80 tiles, 32 px/tile, 3584×2560 px
**Source image:** 5048×3500 px → one gameplay cell = (5048/112) × (3500/80) source pixels

### Controls

```text
Q: toggle underlay source-selection mode
Left drag on underlay while source-selection active: define source region
Release left mouse: load selected region as active underlay stamp
Tab: switch active paint source between palette tile and underlay stamp
Left click underlay while stamp source active: place stamp at target cell
Right click: remove top placement at target cell
C: copy full mapping JSON
Enter/U: save mapping JSON
G: grid  E: collision rails  T: placed tiles
P: palette focus  F: full underlay focus  S: spawn/causeway focus
L/R: reload saved
Shift+drag: continuous paint/erase
```

### Data model change

Existing palette placements remain unchanged:
```json
{
  "cell": [56, 76],
  "tile_number": 10,
  "category": "floor"
}
```

New underlay stamp placement:
```json
{
  "type": "underlay_stamp",
  "cell": [56, 76],
  "source_rect_cells": [40, 20, 6, 4],
  "tile_size": 32,
  "category": "underlay_sample"
}
```

New top-level metadata:
```json
{
  "underlay_texture_path": "res://content/masters/sundered_keep/sundered_keep_main_overlay.png",
  "underlay_grid_size": [112, 80]
}
```

### Mapper script changes

File: `custodian/scenes/debug/sundered_keep_underlay_gameplay_tile_mapper.gd`

#### 5.1 Add constants

```gdscript
const UNDERLAY_TEXTURE_PATH := "res://content/masters/sundered_keep/sundered_keep_main_overlay.png"
const UNDERLAY_GRID_SIZE := Vector2i(112, 80)

enum PaintSource {
	PALETTE_TILE,
	UNDERLAY_STAMP,
}
```

#### 5.2 Add state

```gdscript
var _underlay_texture: Texture2D = null
var _paint_source: PaintSource = PaintSource.PALETTE_TILE

var _underlay_select_mode := false
var _selecting_underlay_region := false
var _selection_start_cell := Vector2i.ZERO
var _selection_end_cell := Vector2i.ZERO
var _active_underlay_stamp: Dictionary = {}
```

#### 5.3 Load underlay texture

In `_ready()`, after `_load_underlay_collision_pair()`:
```gdscript
_underlay_texture = load(UNDERLAY_TEXTURE_PATH) as Texture2D
if _underlay_texture == null:
	push_warning("[SunderedKeepUnderlayGameplayTileMapper] Could not load underlay texture: %s" % UNDERLAY_TEXTURE_PATH)
```

#### 5.4 Source-cell conversion helpers

```gdscript
func _source_cell_size_px() -> Vector2:
	if _underlay_texture == null:
		return Vector2.ONE * float(TILE_SIZE)
	return Vector2(
		float(_underlay_texture.get_width()) / float(UNDERLAY_GRID_SIZE.x),
		float(_underlay_texture.get_height()) / float(UNDERLAY_GRID_SIZE.y)
	)

func _source_rect_px_from_cells(source_rect_cells: Rect2i) -> Rect2:
	var source_cell := _source_cell_size_px()
	return Rect2(
		Vector2(source_rect_cells.position) * source_cell,
		Vector2(source_rect_cells.size) * source_cell
	)

func _normalized_cell_rect(a: Vector2i, b: Vector2i) -> Rect2i:
	var min_x := mini(a.x, b.x)
	var min_y := mini(a.y, b.y)
	var max_x := maxi(a.x, b.x)
	var max_y := maxi(a.y, b.y)
	return Rect2i(
		Vector2i(min_x, min_y),
		Vector2i(max_x - min_x + 1, max_y - min_y + 1)
	)
```

#### 5.5 Active stamp creation

```gdscript
func _load_underlay_selection_as_stamp() -> void:
	var rect := _normalized_cell_rect(_selection_start_cell, _selection_end_cell)
	if rect.size.x <= 0 or rect.size.y <= 0:
		return

	_active_underlay_stamp = {
		"type": "underlay_stamp",
		"source_rect_cells": [
			rect.position.x,
			rect.position.y,
			rect.size.x,
			rect.size.y,
		],
		"tile_size": TILE_SIZE,
		"category": "underlay_sample",
	}

	_paint_source = PaintSource.UNDERLAY_STAMP
	_update_help()
	_overlay.queue_redraw()
	print("[SunderedKeepUnderlayGameplayTileMapper] Loaded underlay stamp source_rect_cells=%s" % _active_underlay_stamp["source_rect_cells"])
```

#### 5.6 Mouse input update

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton

		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if _underlay_select_mode and _is_on_underlay(_camera.get_global_mouse_position()):
				if mouse.pressed:
					_selecting_underlay_region = true
					_selection_start_cell = _world_to_tile(_camera.get_global_mouse_position())
					_selection_end_cell = _selection_start_cell
				else:
					_selecting_underlay_region = false
					_selection_end_cell = _world_to_tile(_camera.get_global_mouse_position())
					_load_underlay_selection_as_stamp()
				_overlay.queue_redraw()
				_update_help()
				return

			if mouse.pressed:
				_handle_left_click(_camera.get_global_mouse_position())
				return

		if mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			_handle_right_click(_camera.get_global_mouse_position())
			return

		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(zoom_step)
			return

		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / zoom_step)
			return

	elif event is InputEventMouseMotion:
		if _selecting_underlay_region:
			_selection_end_cell = _world_to_tile(_camera.get_global_mouse_position())
			_overlay.queue_redraw()
			_update_help()
			return

	elif (
		event is InputEventKey
		and (event as InputEventKey).pressed
		and not (event as InputEventKey).echo
	):
		_handle_key(event as InputEventKey)
```

#### 5.7 Placement logic update

```gdscript
func _handle_left_click(point: Vector2) -> void:
	var palette_number := _palette_number_at(point)
	if palette_number > 0:
		_selected_tile_number = palette_number
		_paint_source = PaintSource.PALETTE_TILE
		_update_help()
		_overlay.queue_redraw()
		return

	if not _is_on_underlay(point):
		return

	if _paint_source == PaintSource.UNDERLAY_STAMP:
		_place_underlay_stamp(_world_to_tile(point))
		return

	if _selected_tile_number <= 0:
		return

	_place_selected_tile(_world_to_tile(point))
```

```gdscript
func _place_underlay_stamp(cell: Vector2i) -> void:
	if _active_underlay_stamp.is_empty():
		return

	var placement := _active_underlay_stamp.duplicate(true)
	placement["cell"] = [cell.x, cell.y]
	_placements.append(placement)

	_dirty = true
	_rebuild_placement_preview()
	_update_help()
	_overlay.queue_redraw()
```

#### 5.8 Preview rendering update

```gdscript
func _rebuild_placement_preview() -> void:
	for child: Node in _placed_root.get_children():
		child.queue_free()

	for placement: Dictionary in _placements:
		if str(placement.get("type", "palette_tile")) == "underlay_stamp":
			_add_underlay_stamp_preview(placement)
		else:
			_add_palette_tile_preview(placement)

	_placed_root.visible = _show_placements
```

Palette preview:
```gdscript
func _add_palette_tile_preview(placement: Dictionary) -> void:
	var item := _palette_item(int(placement.get("tile_number", 0)))
	if item.is_empty():
		return
	var texture := load(str(item["texture_path"])) as Texture2D
	if texture == null:
		return
	var cell := placement.get("cell", Vector2i.ZERO) as Vector2i
	var sprite := Sprite2D.new()
	sprite.name = "Placed_%02d_%d_%d" % [int(item["number"]), cell.x, cell.y]
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = _placement_anchor(cell, texture, str(item["category"]))
	sprite.offset = _placement_offset(texture, str(item["category"]))
	sprite.set_meta("tile_number", int(item["number"]))
	sprite.set_meta("cell", cell)
	_placed_root.add_child(sprite)
```

Underlay stamp preview:
```gdscript
func _add_underlay_stamp_preview(placement: Dictionary) -> void:
	if _underlay_texture == null:
		return

	var raw_cell := placement.get("cell", []) as Array
	var raw_rect := placement.get("source_rect_cells", []) as Array
	if raw_cell.size() < 2 or raw_rect.size() < 4:
		return

	var target_cell := Vector2i(int(raw_cell[0]), int(raw_cell[1]))
	var source_rect_cells := Rect2i(
		Vector2i(int(raw_rect[0]), int(raw_rect[1])),
		Vector2i(int(raw_rect[2]), int(raw_rect[3]))
	)

	var source_rect_px := _source_rect_px_from_cells(source_rect_cells)
	var target_size_px := Vector2(source_rect_cells.size) * float(TILE_SIZE)

	var sprite := Sprite2D.new()
	sprite.name = "UnderlayStamp_%d_%d_%d_%d_to_%d_%d" % [
		source_rect_cells.position.x,
		source_rect_cells.position.y,
		source_rect_cells.size.x,
		source_rect_cells.size.y,
		target_cell.x,
		target_cell.y,
	]
	sprite.texture = _underlay_texture
	sprite.region_enabled = true
	sprite.region_rect = source_rect_px
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(target_cell * TILE_SIZE)
	sprite.scale = Vector2(
		target_size_px.x / maxf(1.0, source_rect_px.size.x),
		target_size_px.y / maxf(1.0, source_rect_px.size.y)
	)
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.92)
	sprite.set_meta("type", "underlay_stamp")
	sprite.set_meta("cell", target_cell)
	_placed_root.add_child(sprite)
```

#### 5.9 Mapping JSON builder update

In `_mapping_document()`, add top-level keys:
```gdscript
"underlay_texture_path": UNDERLAY_TEXTURE_PATH,
"underlay_grid_size": [UNDERLAY_GRID_SIZE.x, UNDERLAY_GRID_SIZE.y],
```

Placement serialization:
```gdscript
var placement_document: Array[Dictionary] = []
for placement: Dictionary in _placements:
	if str(placement.get("type", "palette_tile")) == "underlay_stamp":
		placement_document.append({
			"type": "underlay_stamp",
			"cell": placement.get("cell", [0, 0]),
			"source_rect_cells": placement.get("source_rect_cells", [0, 0, 1, 1]),
			"tile_size": TILE_SIZE,
			"category": "underlay_sample",
		})
	else:
		placement_document.append({
			"type": "palette_tile",
			"cell": [
				int((placement["cell"] as Vector2i).x),
				int((placement["cell"] as Vector2i).y),
			],
			"tile_number": int(placement["tile_number"]),
			"category": str(placement["category"]),
		})
```

#### 5.10 Mapping loader update

```gdscript
for raw_placement: Variant in data.get("placements", []):
	if not (raw_placement is Dictionary):
		continue

	var source := raw_placement as Dictionary
	var placement_type := str(source.get("type", "palette_tile"))

	if placement_type == "underlay_stamp":
		var raw_cell := source.get("cell", []) as Array
		var raw_rect := source.get("source_rect_cells", []) as Array
		if raw_cell.size() < 2 or raw_rect.size() < 4:
			continue
		_placements.append({
			"type": "underlay_stamp",
			"cell": [int(raw_cell[0]), int(raw_cell[1])],
			"source_rect_cells": [
				int(raw_rect[0]),
				int(raw_rect[1]),
				int(raw_rect[2]),
				int(raw_rect[3]),
			],
			"tile_size": int(source.get("tile_size", TILE_SIZE)),
			"category": "underlay_sample",
		})
		continue

	var raw_cell := source.get("cell", []) as Array
	var tile_number := int(source.get("tile_number", 0))
	if raw_cell.size() != 2 or _palette_item(tile_number).is_empty():
		continue

	var item := _palette_item(tile_number)
	_placements.append({
		"type": "palette_tile",
		"cell": Vector2i(int(raw_cell[0]), int(raw_cell[1])),
		"tile_number": tile_number,
		"category": str(item["category"]),
	})
```

#### 5.11 Key handling update

Add to `_handle_key()`:
```gdscript
KEY_Q:
	_underlay_select_mode = not _underlay_select_mode
	if _underlay_select_mode:
		_paint_source = PaintSource.UNDERLAY_STAMP
KEY_TAB:
	_paint_source = PaintSource.UNDERLAY_STAMP if _paint_source == PaintSource.PALETTE_TILE else PaintSource.PALETTE_TILE
```

#### 5.12 Help text update

Add:
```text
Q: underlay select mode   Drag underlay: sample visible region as stamp   Tab: palette/stamp source
```

Show:
```text
Paint source: PALETTE / UNDERLAY STAMP
Active stamp: source_rect_cells=[x,y,w,h]
```

### Overlay changes

File: `custodian/scenes/debug/sundered_keep_underlay_gameplay_tile_mapper_overlay.gd`

In `_draw()`:
```gdscript
_draw_underlay_selection(state)
```

Add:
```gdscript
func _draw_underlay_selection(state: Dictionary) -> void:
	if not bool(state.get("underlay_select_mode", false)):
		return

	var tile_size := int(state.get("tile_size", 32))
	var raw_rect := state.get("selection_rect_cells", []) as Array
	if raw_rect.size() < 4:
		return

	var rect := Rect2(
		Vector2(int(raw_rect[0]) * tile_size, int(raw_rect[1]) * tile_size),
		Vector2(int(raw_rect[2]) * tile_size, int(raw_rect[3]) * tile_size)
	)

	draw_rect(rect, Color(1.0, 0.74, 0.18, 0.18), true)
	draw_rect(rect, Color(1.0, 0.84, 0.22, 0.95), false, 3.0)
```

Update `get_gameplay_tile_mapper_state()` to include:
```gdscript
var selection_rect := _normalized_cell_rect(_selection_start_cell, _selection_end_cell)
```

Return:
```gdscript
"paint_source": "UNDERLAY_STAMP" if _paint_source == PaintSource.UNDERLAY_STAMP else "PALETTE_TILE",
"underlay_select_mode": _underlay_select_mode,
"selection_rect_cells": [
	selection_rect.position.x,
	selection_rect.position.y,
	selection_rect.size.x,
	selection_rect.size.y,
],
"active_underlay_stamp": _active_underlay_stamp,
```

### Runtime consumption for underlay stamps

File: `custodian/game/world/sundered_keep/sundered_keep_map.gd`

In the mapping application loop, add before the palette tile branch:
```gdscript
if str(placement.get("type", "palette_tile")) == "underlay_stamp":
	_apply_underlay_stamp_placement(placement, underlay_texture)
	continue
```

Add:
```gdscript
func _apply_underlay_stamp_placement(placement: Dictionary, underlay_texture: Texture2D) -> bool:
	if underlay_texture == null:
		return false

	var raw_cell := placement.get("cell", []) as Array
	var raw_rect := placement.get("source_rect_cells", []) as Array
	if raw_cell.size() < 2 or raw_rect.size() < 4:
		return false

	var target_cell := Vector2i(int(raw_cell[0]), int(raw_cell[1]))
	var source_rect_cells := Rect2i(
		Vector2i(int(raw_rect[0]), int(raw_rect[1])),
		Vector2i(int(raw_rect[2]), int(raw_rect[3]))
	)

	var source_cell := Vector2(
		float(underlay_texture.get_width()) / 112.0,
		float(underlay_texture.get_height()) / 80.0
	)

	var source_rect_px := Rect2(
		Vector2(source_rect_cells.position) * source_cell,
		Vector2(source_rect_cells.size) * source_cell
	)

	var target_size_px := Vector2(source_rect_cells.size) * TILE_SIZE

	var sprite := Sprite2D.new()
	sprite.name = "UnderlayGameplayStamp_%d_%d" % [target_cell.x, target_cell.y]
	sprite.texture = underlay_texture
	sprite.region_enabled = true
	sprite.region_rect = source_rect_px
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = _tile_top_left(target_cell)
	sprite.scale = Vector2(
		target_size_px.x / maxf(1.0, source_rect_px.size.x),
		target_size_px.y / maxf(1.0, source_rect_px.size.y)
	)

	(_layers["FloorDetail"] as Node2D).add_child(sprite)

	for y in range(target_cell.y, target_cell.y + source_rect_cells.size.y):
		for x in range(target_cell.x, target_cell.x + source_rect_cells.size.x):
			if not _minimap_wall_cells.has(Vector2i(x, y)):
				_minimap_floor_cells[Vector2i(x, y)] = true

	return true
```

Underlay stamps are visual/floor-authoring only — no blockers. Collision remains the collision mapper's job.

### Smoke test additions for stamp mode

Add to the smoke test:
```gdscript
_assert(scene.has_method("_source_cell_size_px"), "mapper missing source cell size helper")
_assert(scene.has_method("_source_rect_px_from_cells"), "mapper missing source rect conversion")
_assert(scene.has_method("_load_underlay_selection_as_stamp"), "mapper missing underlay stamp loader")
_assert(scene.has_method("_place_underlay_stamp"), "mapper missing underlay stamp placement")
```

Test without writing:
```gdscript
scene.set("_selection_start_cell", Vector2i(10, 12))
scene.set("_selection_end_cell", Vector2i(13, 15))
scene.call("_load_underlay_selection_as_stamp")

var state := scene.call("get_gameplay_tile_mapper_state") as Dictionary
_assert(str(state.get("paint_source", "")) == "UNDERLAY_STAMP", "paint source did not switch to underlay stamp")
_assert((state.get("active_underlay_stamp", {}) as Dictionary).has("source_rect_cells"), "active underlay stamp missing source rect")

scene.call("_place_underlay_stamp", Vector2i(20, 22))
var doc := scene.call("_mapping_document") as Dictionary
var placements := doc.get("placements", []) as Array
var found_stamp := false
for placement_variant: Variant in placements:
	var placement := placement_variant as Dictionary
	if str(placement.get("type", "")) == "underlay_stamp":
		found_stamp = true
_assert(found_stamp, "mapping document did not serialize underlay_stamp placement")
```
