extends Node2D

const UNDERLAY_DEBUG_SCENE := preload(
	"res://scenes/debug/sundered_keep_production_underlay_debug.tscn"
)
const TILE_MAPPING_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_underlay_gameplay_tiles.json"
)
const UNDERLAY_TEXTURE_PATH := (
	"res://content/masters/sundered_keep/"
	+ "sundered_keep_main_overlay.png"
)
const UNDERLAY_GRID_SIZE := Vector2i(112, 80)
const UNDERLAY_SOURCE_SIZE_PX := Vector2(5048.0, 3500.0)
const MAP_SIZE := Vector2(3584.0, 2560.0)
const TILE_SIZE := 32
const PALETTE_ORIGIN := Vector2(3904.0, 160.0)
const PALETTE_COLUMNS := 11
const PALETTE_ROWS := 9
const PALETTE_CELL_SIZE := Vector2(176.0, 128.0)
const PALETTE_TILE_COUNT := 99
const PALETTE_ROOTS := [
	"res://content/tiles/sundered_keep/floors",
	"res://content/tiles/sundered_keep/walls/gothic_castle",
	"res://content/tiles/sundered_keep/walls/great_hall",
	"res://content/tiles/sundered_keep/walls/ramparts",
]
const PALETTE_EXCLUDED_FILES := {
	"causeway_source.png": true,
	"great_hall_wall_straight_test.png": true,
	"rampart_crenellation_w_source.png": true,
	"rampart_parapet_e_source.png": true,
}
const PALETTE_EXTRA_PATHS := [
	"res://content/runtime/sundered_keep/doors_traversal/gates/main_gate_portcullis_closed.png",
	"res://content/runtime/sundered_keep/doors_traversal/doors/gothic_double_door_closed_n.png",
	"res://content/runtime/sundered_keep/doors_traversal/stairs/stone_stairs_up_n.png",
]

enum PaintSource {
	PALETTE_TILE,
	UNDERLAY_STAMP,
}

@export var zoom_step := 1.15
@export var pan_step := 96.0

@onready var _world: Node2D = $World
@onready var _camera: Camera2D = $World/Camera2D
@onready var _placed_root: Node2D = $World/PlacedGameplayTiles
@onready var _palette_root: Node2D = $World/TilePalette
@onready var _overlay: Node2D = $World/MapperOverlay
@onready var _hud: Label = $CanvasLayer/Help

var _underlay_scene: Node2D
var _underlay_texture: Texture2D
var _palette: Array[Dictionary] = []
var _placements: Array[Dictionary] = []
var _selected_tile_number := 0
var _paint_source: PaintSource = PaintSource.PALETTE_TILE
var _underlay_select_mode := false
var _selecting_underlay_region := false
var _has_underlay_selection := false
var _selection_start_cell := Vector2i.ZERO
var _selection_end_cell := Vector2i.ZERO
var _active_underlay_stamp: Dictionary = {}
var _mouse_world := Vector2.ZERO
var _show_grid := true
var _show_collision := true
var _show_placements := true
var _show_help := true
var _dirty := false


func _ready() -> void:
	_camera.make_current()
	_load_underlay_collision_pair()
	_underlay_texture = load(UNDERLAY_TEXTURE_PATH) as Texture2D
	if _underlay_texture == null:
		push_warning(
			"[SunderedKeepUnderlayGameplayTileMapper] "
			+ "Could not load underlay texture: %s"
			% UNDERLAY_TEXTURE_PATH
		)
	_build_palette()
	_load_mapping_document()
	_rebuild_placement_preview()
	_focus_full_underlay()
	_update_help()
	_overlay.queue_redraw()


func _process(_delta: float) -> void:
	_handle_keyboard_pan()
	var current_mouse := _camera.get_global_mouse_position()
	if not current_mouse.is_equal_approx(_mouse_world):
		_mouse_world = current_mouse
		_update_help()
		_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		var point := _camera.get_global_mouse_position()
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if _underlay_select_mode:
				if mouse.pressed and _is_on_underlay(point):
					_selecting_underlay_region = true
					_has_underlay_selection = true
					_selection_start_cell = _clamped_underlay_cell(point)
					_selection_end_cell = _selection_start_cell
					_overlay.queue_redraw()
					_update_help()
					return
				if not mouse.pressed and _selecting_underlay_region:
					_selection_end_cell = _clamped_underlay_cell(point)
					_selecting_underlay_region = false
					_load_underlay_selection_as_stamp()
					_overlay.queue_redraw()
					_update_help()
					return
			if mouse.pressed:
				_handle_left_click(point)
				return
		if mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			_handle_right_click(point)
			return
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(zoom_step)
			return
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / zoom_step)
			return
	elif event is InputEventMouseMotion:
		if _selecting_underlay_region:
			_selection_end_cell = _clamped_underlay_cell(
				_camera.get_global_mouse_position()
			)
			_overlay.queue_redraw()
			_update_help()
			return
	elif (
		event is InputEventKey
		and (event as InputEventKey).pressed
		and not (event as InputEventKey).echo
	):
		_handle_key(event as InputEventKey)


func _load_underlay_collision_pair() -> void:
	_underlay_scene = UNDERLAY_DEBUG_SCENE.instantiate() as Node2D
	if _underlay_scene == null:
		push_error(
			"[SunderedKeepUnderlayGameplayTileMapper] "
			+ "Could not instantiate the reviewed underlay/collision scene"
		)
		return
	_underlay_scene.name = "ReviewedUnderlayCollisionPair"
	_world.add_child(_underlay_scene)


func _build_palette() -> void:
	var texture_paths: Array[String] = []
	for root_path: String in PALETTE_ROOTS:
		var filenames := Array(DirAccess.get_files_at(root_path))
		filenames.sort()
		for filename_variant: Variant in filenames:
			var filename := str(filename_variant)
			if (
				filename.ends_with(".png")
				and not PALETTE_EXCLUDED_FILES.has(filename)
			):
				texture_paths.append("%s/%s" % [root_path, filename])
	for extra_path: String in PALETTE_EXTRA_PATHS:
		texture_paths.append(extra_path)

	if texture_paths.size() != PALETTE_TILE_COUNT:
		push_error(
			"[SunderedKeepUnderlayGameplayTileMapper] "
			+ "Palette contract expected %d assets, found %d"
			% [PALETTE_TILE_COUNT, texture_paths.size()]
		)

	var count := mini(texture_paths.size(), PALETTE_TILE_COUNT)
	for index in count:
		var number := index + 1
		var texture_path := texture_paths[index]
		var item := {
			"number": number,
			"label": "%02d" % number,
			"asset_id": texture_path.get_file().get_basename(),
			"texture_path": texture_path,
			"category": _category_for_path(texture_path),
			"cell_rect": _palette_cell_rect(index),
		}
		_palette.append(item)
		_add_palette_preview(item)


func _add_palette_preview(item: Dictionary) -> void:
	var texture_path := str(item["texture_path"])
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_warning(
			"[SunderedKeepUnderlayGameplayTileMapper] "
			+ "Could not load palette texture %s" % texture_path
		)
		return
	var rect := item["cell_rect"] as Rect2
	var sprite := Sprite2D.new()
	sprite.name = "Tile_%s_%s" % [
		str(item["label"]),
		str(item["asset_id"]),
	]
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var available := Vector2(
		rect.size.x - 18.0,
		rect.size.y - 34.0
	)
	var texture_size := texture.get_size()
	var preview_scale := minf(
		1.0,
		minf(
			available.x / maxf(1.0, texture_size.x),
			available.y / maxf(1.0, texture_size.y)
		)
	)
	sprite.scale = Vector2.ONE * preview_scale
	sprite.position = rect.position + Vector2(
		rect.size.x * 0.5,
		18.0 + available.y * 0.5
	)
	sprite.set_meta("tile_number", int(item["number"]))
	sprite.set_meta("texture_path", texture_path)
	_palette_root.add_child(sprite)

	var label := Label.new()
	label.name = "Label_%s" % str(item["label"])
	label.position = rect.position + Vector2(5.0, 3.0)
	label.size = Vector2(rect.size.x - 10.0, 22.0)
	label.text = "%s  %s" % [
		str(item["label"]),
		str(item["asset_id"]),
	]
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override(
		"font_color",
		Color(0.94, 0.97, 1.0, 1.0)
	)
	label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.95)
	)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.clip_text = true
	_palette_root.add_child(label)


func _handle_left_click(point: Vector2) -> void:
	var palette_number := _palette_number_at(point)
	if palette_number > 0:
		_selected_tile_number = palette_number
		_paint_source = PaintSource.PALETTE_TILE
		_underlay_select_mode = false
		_selecting_underlay_region = false
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


func _handle_right_click(point: Vector2) -> void:
	if _palette_number_at(point) > 0:
		_selected_tile_number = 0
		_update_help()
		_overlay.queue_redraw()
		return
	if _is_on_underlay(point):
		_remove_top_placement(_world_to_tile(point))


func _place_selected_tile(cell: Vector2i) -> void:
	var item := _palette_item(_selected_tile_number)
	if item.is_empty():
		return
	var category := str(item["category"])
	for index in range(_placements.size() - 1, -1, -1):
		var placement := _placements[index]
		if (
			_placement_cell(placement) == cell
			and str(placement.get("category", "")) == category
		):
			_placements.remove_at(index)
	var placement := {
		"type": "palette_tile",
		"cell": cell,
		"tile_number": _selected_tile_number,
		"category": category,
	}
	_placements.append(placement)
	_dirty = true
	_rebuild_placement_preview()
	_update_help()
	_overlay.queue_redraw()


func _place_underlay_stamp(cell: Vector2i) -> void:
	if _active_underlay_stamp.is_empty():
		return
	var raw_rect := (
		_active_underlay_stamp.get("source_rect_cells", []) as Array
	)
	if raw_rect.size() < 4:
		return
	var stamp_size := Vector2i(int(raw_rect[2]), int(raw_rect[3]))
	if (
		cell.x < 0
		or cell.y < 0
		or cell.x + stamp_size.x > UNDERLAY_GRID_SIZE.x
		or cell.y + stamp_size.y > UNDERLAY_GRID_SIZE.y
	):
		return
	var placement := _active_underlay_stamp.duplicate(true)
	placement["cell"] = [cell.x, cell.y]
	_placements.append(placement)
	_dirty = true
	_rebuild_placement_preview()
	_update_help()
	_overlay.queue_redraw()


func _remove_top_placement(cell: Vector2i) -> void:
	for index in range(_placements.size() - 1, -1, -1):
		var placement := _placements[index]
		var placement_cell := _placement_cell(placement)
		var placement_size := Vector2i.ONE
		if str(placement.get("type", "palette_tile")) == "underlay_stamp":
			var raw_rect := placement.get("source_rect_cells", []) as Array
			if raw_rect.size() >= 4:
				placement_size = Vector2i(
					maxi(1, int(raw_rect[2])),
					maxi(1, int(raw_rect[3]))
				)
		if Rect2i(placement_cell, placement_size).has_point(cell):
			_placements.remove_at(index)
			_dirty = true
			_rebuild_placement_preview()
			_update_help()
			_overlay.queue_redraw()
			return


func _rebuild_placement_preview() -> void:
	for child: Node in _placed_root.get_children():
		child.queue_free()
	for placement: Dictionary in _placements:
		if str(placement.get("type", "palette_tile")) == "underlay_stamp":
			_add_underlay_stamp_preview(placement)
		else:
			_add_palette_tile_preview(placement)
	_placed_root.visible = _show_placements


func _add_palette_tile_preview(placement: Dictionary) -> void:
	var item := _palette_item(int(placement.get("tile_number", 0)))
	if item.is_empty():
		return
	var texture := load(str(item["texture_path"])) as Texture2D
	if texture == null:
		return
	var cell := _placement_cell(placement)
	var sprite := Sprite2D.new()
	sprite.name = "Placed_%02d_%d_%d" % [
		int(item["number"]),
		cell.x,
		cell.y,
	]
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = _placement_anchor(
		cell,
		texture,
		str(item["category"])
	)
	sprite.offset = _placement_offset(
		texture,
		str(item["category"])
	)
	sprite.set_meta("type", "palette_tile")
	sprite.set_meta("tile_number", int(item["number"]))
	sprite.set_meta("cell", cell)
	_placed_root.add_child(sprite)


func _add_underlay_stamp_preview(placement: Dictionary) -> void:
	if _underlay_texture == null:
		return
	var raw_rect := placement.get("source_rect_cells", []) as Array
	if raw_rect.size() < 4:
		return
	var target_cell := _placement_cell(placement)
	var source_rect_cells := Rect2i(
		Vector2i(int(raw_rect[0]), int(raw_rect[1])),
		Vector2i(int(raw_rect[2]), int(raw_rect[3]))
	)
	if source_rect_cells.size.x <= 0 or source_rect_cells.size.y <= 0:
		return
	var source_rect_px := _source_rect_px_from_cells(source_rect_cells)
	var target_size_px := (
		Vector2(source_rect_cells.size) * float(TILE_SIZE)
	)
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
	sprite.set_meta("source_rect_cells", source_rect_cells)
	_placed_root.add_child(sprite)


func _source_cell_size_px() -> Vector2:
	if _underlay_texture == null:
		return Vector2.ONE * float(TILE_SIZE)
	return Vector2(
		UNDERLAY_SOURCE_SIZE_PX.x / float(UNDERLAY_GRID_SIZE.x),
		UNDERLAY_SOURCE_SIZE_PX.y / float(UNDERLAY_GRID_SIZE.y)
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


func _load_underlay_selection_as_stamp() -> void:
	var rect := _normalized_cell_rect(
		_selection_start_cell,
		_selection_end_cell
	)
	rect = rect.intersection(Rect2i(Vector2i.ZERO, UNDERLAY_GRID_SIZE))
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	_has_underlay_selection = true
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
	print(
		"[SunderedKeepUnderlayGameplayTileMapper] "
		+ "Loaded underlay stamp source_rect_cells=%s"
		% [_active_underlay_stamp["source_rect_cells"]]
	)


func _placement_anchor(
	cell: Vector2i,
	_texture: Texture2D,
	category: String
) -> Vector2:
	var origin := Vector2(cell * TILE_SIZE)
	if category == "floor":
		return origin + Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	return origin + Vector2(TILE_SIZE * 0.5, TILE_SIZE)


func _placement_offset(texture: Texture2D, category: String) -> Vector2:
	if category == "floor":
		return Vector2.ZERO
	return Vector2(0.0, -texture.get_height() * 0.5)


func _handle_keyboard_pan() -> void:
	var delta := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		delta.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		delta.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		delta.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		delta.y += 1.0
	if delta == Vector2.ZERO:
		return
	_camera.position += (
		delta.normalized()
		* pan_step
		/ maxf(0.05, _camera.zoom.x)
		* get_process_delta_time()
		* 6.0
	)


func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_C:
			_copy_mapping_to_clipboard()
		KEY_ENTER, KEY_KP_ENTER, KEY_U:
			_write_mapping_document()
		KEY_E:
			_show_collision = not _show_collision
		KEY_F:
			_focus_full_underlay()
		KEY_G:
			_show_grid = not _show_grid
		KEY_H:
			_show_help = not _show_help
			_hud.visible = _show_help
		KEY_L, KEY_R:
			_load_mapping_document()
			_rebuild_placement_preview()
		KEY_P:
			_focus_palette()
		KEY_Q:
			_underlay_select_mode = not _underlay_select_mode
			if _underlay_select_mode:
				_paint_source = PaintSource.UNDERLAY_STAMP
			else:
				_selecting_underlay_region = false
		KEY_S:
			_focus_spawn_causeway()
		KEY_TAB:
			_paint_source = (
				PaintSource.UNDERLAY_STAMP
				if _paint_source == PaintSource.PALETTE_TILE
				else PaintSource.PALETTE_TILE
			)
			if _paint_source == PaintSource.PALETTE_TILE:
				_underlay_select_mode = false
				_selecting_underlay_region = false
		KEY_T:
			_show_placements = not _show_placements
			_placed_root.visible = _show_placements
	_overlay.queue_redraw()
	_update_help()


func _zoom(factor: float) -> void:
	var before := _camera.get_global_mouse_position()
	_camera.zoom = (
		_camera.zoom * factor
	).clamp(Vector2(0.10, 0.10), Vector2(2.5, 2.5))
	var after := _camera.get_global_mouse_position()
	_camera.position += before - after
	_update_help()
	_overlay.queue_redraw()


func _focus_full_underlay() -> void:
	_camera.position = MAP_SIZE * 0.5
	_camera.zoom = Vector2(0.24, 0.24)


func _focus_spawn_causeway() -> void:
	_camera.position = Vector2(MAP_SIZE.x * 0.5, MAP_SIZE.y * 0.78)
	_camera.zoom = Vector2(0.48, 0.48)


func _focus_palette() -> void:
	_camera.position = PALETTE_ORIGIN + Vector2(
		PALETTE_COLUMNS * PALETTE_CELL_SIZE.x,
		PALETTE_ROWS * PALETTE_CELL_SIZE.y
	) * 0.5
	_camera.zoom = Vector2(0.72, 0.72)


func _load_mapping_document() -> void:
	_placements.clear()
	if not FileAccess.file_exists(TILE_MAPPING_DATA_PATH):
		_dirty = false
		return
	var file := FileAccess.open(TILE_MAPPING_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning(
			"[SunderedKeepUnderlayGameplayTileMapper] "
			+ "Invalid gameplay tile mapping JSON"
		)
		return
	var data := parsed as Dictionary
	if str(data.get("schema", "")) != (
		"custodian.sundered_keep.underlay_gameplay_tiles.v1"
	):
		push_warning(
			"[SunderedKeepUnderlayGameplayTileMapper] "
			+ "Unsupported gameplay tile mapping schema"
		)
		return
	for raw_placement: Variant in data.get("placements", []):
		if not (raw_placement is Dictionary):
			continue
		var source := raw_placement as Dictionary
		var placement_type := str(source.get("type", "palette_tile"))
		if placement_type == "underlay_stamp":
			var stamp_cell := source.get("cell", []) as Array
			var stamp_rect := (
				source.get("source_rect_cells", []) as Array
			)
			if stamp_cell.size() < 2 or stamp_rect.size() < 4:
				continue
			var target_cell := Vector2i(
				int(stamp_cell[0]),
				int(stamp_cell[1])
			)
			var source_rect := Rect2i(
				Vector2i(int(stamp_rect[0]), int(stamp_rect[1])),
				Vector2i(int(stamp_rect[2]), int(stamp_rect[3]))
			)
			if (
				source_rect.size.x <= 0
				or source_rect.size.y <= 0
				or not Rect2i(
					Vector2i.ZERO,
					UNDERLAY_GRID_SIZE
				).encloses(source_rect)
				or target_cell.x < 0
				or target_cell.y < 0
				or target_cell.x + source_rect.size.x
					> UNDERLAY_GRID_SIZE.x
				or target_cell.y + source_rect.size.y
					> UNDERLAY_GRID_SIZE.y
			):
				continue
			_placements.append({
				"type": "underlay_stamp",
				"cell": [target_cell.x, target_cell.y],
				"source_rect_cells": [
					source_rect.position.x,
					source_rect.position.y,
					source_rect.size.x,
					source_rect.size.y,
				],
				"tile_size": int(
					source.get("tile_size", TILE_SIZE)
				),
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
	_dirty = false
	_update_help()


func _write_mapping_document() -> bool:
	var document := _mapping_document()
	var file := FileAccess.open(TILE_MAPPING_DATA_PATH, FileAccess.WRITE)
	if file == null:
		push_warning(
			"[SunderedKeepUnderlayGameplayTileMapper] "
			+ "Could not write %s" % TILE_MAPPING_DATA_PATH
		)
		return false
	file.store_string(JSON.stringify(document, "  ") + "\n")
	file.close()
	_dirty = false
	print(
		"[SunderedKeepUnderlayGameplayTileMapper] "
		+ "Saved %d gameplay tile placement(s) to %s"
		% [_placements.size(), TILE_MAPPING_DATA_PATH]
	)
	_update_help()
	return true


func _copy_mapping_to_clipboard() -> void:
	var text := JSON.stringify(_mapping_document(), "  ") + "\n"
	DisplayServer.clipboard_set(text)
	print(
		"[SunderedKeepUnderlayGameplayTileMapper] "
		+ "Copied %d placement(s) to clipboard" % _placements.size()
	)


func _mapping_document() -> Dictionary:
	var palette_document: Array[Dictionary] = []
	for item: Dictionary in _palette:
		palette_document.append({
			"number": int(item["number"]),
			"asset_id": str(item["asset_id"]),
			"texture_path": str(item["texture_path"]),
			"category": str(item["category"]),
		})
	var placement_document: Array[Dictionary] = []
	for placement: Dictionary in _placements:
		var cell := _placement_cell(placement)
		if str(placement.get("type", "palette_tile")) == "underlay_stamp":
			placement_document.append({
				"type": "underlay_stamp",
				"cell": [cell.x, cell.y],
				"source_rect_cells": placement.get(
					"source_rect_cells",
					[0, 0, 1, 1]
				),
				"tile_size": TILE_SIZE,
				"category": "underlay_sample",
			})
		else:
			placement_document.append({
				"type": "palette_tile",
				"cell": [cell.x, cell.y],
				"tile_number": int(placement["tile_number"]),
				"category": str(placement["category"]),
			})
	return {
		"schema": "custodian.sundered_keep.underlay_gameplay_tiles.v1",
		"map_size_pixels": [int(MAP_SIZE.x), int(MAP_SIZE.y)],
		"tile_size": TILE_SIZE,
		"underlay_texture_path": UNDERLAY_TEXTURE_PATH,
		"underlay_grid_size": [
			UNDERLAY_GRID_SIZE.x,
			UNDERLAY_GRID_SIZE.y,
		],
		"underlay_source_size_pixels": [
			int(UNDERLAY_SOURCE_SIZE_PX.x),
			int(UNDERLAY_SOURCE_SIZE_PX.y),
		],
		"palette_count": _palette.size(),
		"palette": palette_document,
		"placements": placement_document,
	}


func _palette_item(number: int) -> Dictionary:
	if number < 1 or number > _palette.size():
		return {}
	return _palette[number - 1]


func _palette_cell_rect(index: int) -> Rect2:
	var column := index % PALETTE_COLUMNS
	var row := index / PALETTE_COLUMNS
	return Rect2(
		PALETTE_ORIGIN + Vector2(
			column * PALETTE_CELL_SIZE.x,
			row * PALETTE_CELL_SIZE.y
		),
		PALETTE_CELL_SIZE
	)


func _palette_number_at(point: Vector2) -> int:
	var local := point - PALETTE_ORIGIN
	if (
		local.x < 0.0
		or local.y < 0.0
		or local.x >= PALETTE_COLUMNS * PALETTE_CELL_SIZE.x
		or local.y >= PALETTE_ROWS * PALETTE_CELL_SIZE.y
	):
		return 0
	var column := floori(local.x / PALETTE_CELL_SIZE.x)
	var row := floori(local.y / PALETTE_CELL_SIZE.y)
	var number := row * PALETTE_COLUMNS + column + 1
	return number if number <= _palette.size() else 0


func _category_for_path(texture_path: String) -> String:
	if "/floors/" in texture_path:
		return "floor"
	if "/stairs/" in texture_path:
		return "traversal"
	if "/doors/" in texture_path or "/gates/" in texture_path:
		return "traversal"
	return "architecture"


func _is_on_underlay(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, MAP_SIZE).has_point(point)


func _world_to_tile(point: Vector2) -> Vector2i:
	return Vector2i(
		floori(point.x / TILE_SIZE),
		floori(point.y / TILE_SIZE)
	)


func _clamped_underlay_cell(point: Vector2) -> Vector2i:
	var cell := _world_to_tile(point)
	return Vector2i(
		clampi(cell.x, 0, UNDERLAY_GRID_SIZE.x - 1),
		clampi(cell.y, 0, UNDERLAY_GRID_SIZE.y - 1)
	)


func _placement_cell(placement: Dictionary) -> Vector2i:
	var raw_cell: Variant = placement.get("cell", Vector2i(-1, -1))
	if raw_cell is Vector2i:
		return raw_cell as Vector2i
	if raw_cell is Array and (raw_cell as Array).size() >= 2:
		var values := raw_cell as Array
		return Vector2i(int(values[0]), int(values[1]))
	return Vector2i(-1, -1)


func _update_help() -> void:
	if _hud == null:
		return
	var selected := _palette_item(_selected_tile_number)
	var selected_text := "none"
	if not selected.is_empty():
		selected_text = "%s — %s" % [
			str(selected["label"]),
			str(selected["asset_id"]),
		]
	var paint_source_text := (
		"UNDERLAY STAMP"
		if _paint_source == PaintSource.UNDERLAY_STAMP
		else "PALETTE"
	)
	var active_stamp_text := "none"
	if not _active_underlay_stamp.is_empty():
		active_stamp_text = str(
			_active_underlay_stamp.get("source_rect_cells", [])
		)
	_hud.text = "\n".join([
		"Sundered Keep Underlay + Collision + Gameplay Tile Mapper",
		"P: numbered 01–99 palette   F: full underlay   S: spawn/causeway",
		"Q: underlay select mode   Drag: sample region   Q off: paint stamp   Tab: palette/stamp source",
		"Left-click palette: select   Left-click underlay: place active source on 32 px grid   Right-click: remove top placement / clear palette selection",
		"WASD/arrows: pan   Wheel/+/-: zoom   G: grid   E: collision rails   T: placed tiles   L/R: reload saved",
		"C: copy mapping JSON   Enter/U: save mapping JSON   H: help",
		"Paint source: %s   Active stamp: source_rect_cells=%s   Source-select: %s" % [
			paint_source_text,
			active_stamp_text,
			"ON" if _underlay_select_mode else "OFF",
		],
		"Selected: %s   placements: %d%s" % [
			selected_text,
			_placements.size(),
			"   UNSAVED" if _dirty else "",
		],
		"Mouse world: (%.1f, %.1f)   cell: %s" % [
			_mouse_world.x,
			_mouse_world.y,
			_world_to_tile(_mouse_world),
		],
	])


func get_gameplay_tile_mapper_state() -> Dictionary:
	var selection_rect := Rect2i()
	if _has_underlay_selection:
		selection_rect = _normalized_cell_rect(
			_selection_start_cell,
			_selection_end_cell
		).intersection(Rect2i(Vector2i.ZERO, UNDERLAY_GRID_SIZE))
	return {
		"underlay_scene": _underlay_scene,
		"map_size": MAP_SIZE,
		"tile_size": TILE_SIZE,
		"palette_origin": PALETTE_ORIGIN,
		"palette_columns": PALETTE_COLUMNS,
		"palette_rows": PALETTE_ROWS,
		"palette_cell_size": PALETTE_CELL_SIZE,
		"palette": _palette,
		"placements": _placements,
		"selected_tile_number": _selected_tile_number,
		"paint_source": (
			"UNDERLAY_STAMP"
			if _paint_source == PaintSource.UNDERLAY_STAMP
			else "PALETTE_TILE"
		),
		"underlay_select_mode": _underlay_select_mode,
		"selection_rect_cells": [
			selection_rect.position.x,
			selection_rect.position.y,
			selection_rect.size.x,
			selection_rect.size.y,
		],
		"active_underlay_stamp": _active_underlay_stamp,
		"underlay_texture_path": UNDERLAY_TEXTURE_PATH,
		"underlay_grid_size": UNDERLAY_GRID_SIZE,
		"mouse_world": _mouse_world,
		"show_grid": _show_grid,
		"show_collision": _show_collision,
		"show_placements": _show_placements,
		"mapping_path": TILE_MAPPING_DATA_PATH,
	}
