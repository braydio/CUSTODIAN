extends Node2D

const PRODUCTION_LEVEL_SCENE := preload(
	"res://game/world/sundered_keep/sundered_keep_map.tscn"
)
const LEVEL_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_front_gate_large.json"
)
const COLLISION_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_underlay_collision.json"
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
const MAX_UNDO_STATES := 100
const DEFAULT_RAIL_RADIUS := 18.0
const MARKER_KINDS := [
	"spawn",
	"return_causeway",
	"gatehouse_key",
	"main_gate",
	"level_exit",
	"enemy_spawn_west",
	"enemy_spawn_gate",
]
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

enum AuthoringMode {
	TILES,
	COLLISION,
	MARKERS,
	FEATURES,
}

@export var zoom_step := 1.15
@export var pan_step := 96.0

@onready var _world: Node2D = $World
@onready var _camera: Camera2D = $World/Camera2D
@onready var _placed_root: Node2D = $World/PlacedGameplayTiles
@onready var _active_stamp_preview: Sprite2D = $World/ActiveStampPreview
@onready var _palette_root: Node2D = $World/TilePalette
@onready var _overlay: Node2D = $World/MapperOverlay
@onready var _hud: Label = $CanvasLayer/Help

var _underlay_scene: Node2D
var _underlay_texture: Texture2D
var _level_document: Dictionary = {}
var _collision_document: Dictionary = {}
var _palette: Array[Dictionary] = []
var _placements: Array[Dictionary] = []
var _draft_points: Array[Vector2] = []
var _draft_markers: Dictionary = {}
var _feature_entries: Array[Dictionary] = []
var _authoring_mode := AuthoringMode.TILES
var _selected_marker_index := 0
var _selected_feature_index := 0
var _selected_tile_number := 0
var _paint_source: PaintSource = PaintSource.PALETTE_TILE
var _underlay_select_mode := false
var _selecting_underlay_region := false
var _has_underlay_selection := false
var _selection_start_cell := Vector2i.ZERO
var _selection_end_cell := Vector2i.ZERO
var _active_underlay_stamp: Dictionary = {}
var _paint_drag_active := false
var _paint_drag_last_cell := Vector2i(-1, -1)
var _undo_stack: Array = []
var _redo_stack: Array = []
var _mouse_world := Vector2.ZERO
var _show_grid := true
var _show_collision := true
var _show_placements := true
var _show_help := true
var _dirty := false


func _ready() -> void:
	_camera.make_current()
	_load_level_document()
	_load_collision_document()
	_load_underlay_collision_pair()
	_underlay_texture = load(UNDERLAY_TEXTURE_PATH) as Texture2D
	if _underlay_texture == null:
		push_warning(
			"[SunderedKeepMapper] "
			+ "Could not load underlay texture: %s"
			% UNDERLAY_TEXTURE_PATH
		)
	_build_palette()
	_load_mapping_document()
	_rebuild_placement_preview()
	_refresh_active_stamp_preview()
	_focus_full_underlay()
	_update_help()
	_overlay.queue_redraw()


func _process(_delta: float) -> void:
	_handle_keyboard_pan()
	var current_mouse := _camera.get_global_mouse_position()
	if not current_mouse.is_equal_approx(_mouse_world):
		_mouse_world = current_mouse
		_refresh_active_stamp_preview()
		_update_help()
		_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		var point := _camera.get_global_mouse_position()
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(zoom_step)
			return
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / zoom_step)
			return
		if _authoring_mode != AuthoringMode.TILES and mouse.pressed:
			if mouse.button_index == MOUSE_BUTTON_LEFT:
				_handle_authoring_left_click(point)
			elif mouse.button_index == MOUSE_BUTTON_RIGHT:
				_handle_authoring_right_click()
			return
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
					_refresh_active_stamp_preview()
					_overlay.queue_redraw()
					_update_help()
					return
			if not mouse.pressed and _paint_drag_active:
				_finish_paint_drag()
				return
			if mouse.pressed:
				if mouse.shift_pressed and _is_on_underlay(point):
					_begin_paint_drag(point)
					return
				_handle_left_click(point)
				return
		if mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			_handle_right_click(point)
			return
	elif event is InputEventMouseMotion:
		if _selecting_underlay_region:
			_selection_end_cell = _clamped_underlay_cell(
				_camera.get_global_mouse_position()
			)
			_overlay.queue_redraw()
			_update_help()
			return
		if _paint_drag_active:
			_continue_paint_drag(
				_camera.get_global_mouse_position()
			)
			return
	elif (
		event is InputEventKey
		and (event as InputEventKey).pressed
		and not (event as InputEventKey).echo
	):
		_handle_key(event as InputEventKey)


func _load_underlay_collision_pair() -> void:
	_underlay_scene = PRODUCTION_LEVEL_SCENE.instantiate() as Node2D
	if _underlay_scene == null:
		push_error(
			"[SunderedKeepMapper] Could not instantiate the production Keep level"
		)
		return
	_underlay_scene.name = "ProductionSunderedKeepPreview"
	_world.add_child(_underlay_scene)


func _load_level_document() -> void:
	_level_document = _read_json_dictionary(LEVEL_DATA_PATH)
	if str(_level_document.get("schema", "")) != (
		"custodian.sundered_keep.level_tilemap.v1"
	):
		push_error("[SunderedKeepMapper] Unsupported or missing level document")
		_level_document = {}
	_feature_entries = _collect_feature_entries()


func _load_collision_document() -> void:
	_collision_document = _read_json_dictionary(COLLISION_DATA_PATH)
	if str(_collision_document.get("schema", "")) != (
		"custodian.sundered_keep.underlay_collision.v1"
	):
		push_error("[SunderedKeepMapper] Unsupported or missing collision document")
		_collision_document = {
			"schema": "custodian.sundered_keep.underlay_collision.v1",
			"map_size_pixels": [int(MAP_SIZE.x), int(MAP_SIZE.y)],
			"rail_radius": DEFAULT_RAIL_RADIUS,
			"segments": [],
			"markers": {},
		}


func _read_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SunderedKeepMapper] Missing authoring document: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	push_error("[SunderedKeepMapper] Invalid JSON: %s" % path)
	return {}


func _handle_authoring_left_click(point: Vector2) -> void:
	match _authoring_mode:
		AuthoringMode.COLLISION:
			_draft_points.append(point)
		AuthoringMode.MARKERS:
			_draft_markers[_selected_marker_id()] = point
		AuthoringMode.FEATURES:
			_move_selected_feature(_world_to_tile(point))
	_dirty = true
	_update_help()
	_overlay.queue_redraw()


func _handle_authoring_right_click() -> void:
	match _authoring_mode:
		AuthoringMode.COLLISION:
			if not _draft_points.is_empty():
				_draft_points.pop_back()
		AuthoringMode.MARKERS:
			_draft_markers.erase(_selected_marker_id())
	_update_help()
	_overlay.queue_redraw()


func _selected_marker_id() -> String:
	if MARKER_KINDS.is_empty():
		return ""
	return MARKER_KINDS[clampi(
		_selected_marker_index,
		0,
		MARKER_KINDS.size() - 1
	)]


func _cycle_authoring_mode(direction: int = 1) -> void:
	_authoring_mode = wrapi(
		_authoring_mode + direction,
		0,
		AuthoringMode.size()
	)
	_underlay_select_mode = false
	_selecting_underlay_region = false
	_refresh_active_stamp_preview()


func _cycle_active_authoring_item(direction: int) -> void:
	if _authoring_mode == AuthoringMode.MARKERS:
		_selected_marker_index = wrapi(
			_selected_marker_index + direction,
			0,
			MARKER_KINDS.size()
		)
	elif _authoring_mode == AuthoringMode.FEATURES and not _feature_entries.is_empty():
		_selected_feature_index = wrapi(
			_selected_feature_index + direction,
			0,
			_feature_entries.size()
		)


func _collect_feature_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var spatial_sections := [
		"ops",
		"interactables",
		"markers",
		"elevation_regions",
		"underpass_regions",
		"shore_walk_regions",
		"interior_occlusion_regions",
		"layout_zones",
		"blockers",
	]
	for section_variant: Variant in spatial_sections:
		var section := str(section_variant)
		var records: Array = _level_document.get(section, [])
		for index in records.size():
			var record := records[index] as Dictionary
			if not _record_has_spatial_authority(record):
				continue
			entries.append({
				"section": section,
				"index": index,
				"label": _feature_label(section, record, index),
			})
	var siege := _level_document.get("siege", {}) as Dictionary
	for index in (siege.get("objectives", []) as Array).size():
		var objective := (siege.get("objectives", []) as Array)[index] as Dictionary
		entries.append({
			"section": "siege.objectives",
			"index": index,
			"label": "siege/objective/%s" % str(objective.get("id", index)),
		})
	for index in (siege.get("spawns", []) as Array).size():
		entries.append({
			"section": "siege.spawns",
			"index": index,
			"label": "siege/spawn/%02d" % index,
		})
	if siege.has("defense_turret"):
		entries.append({
			"section": "siege.defense_turret",
			"index": 0,
			"label": "siege/defense_turret",
		})
	return entries


func _record_has_spatial_authority(record: Dictionary) -> bool:
	for key in [
		"tile",
		"origin",
		"rect",
		"cells",
		"interior_rect",
		"roof_rect",
	]:
		if record.has(key):
			return true
	return false


func _feature_label(section: String, record: Dictionary, index: int) -> String:
	for key in ["id", "name", "asset_id", "module_id", "type"]:
		if record.has(key) and not str(record[key]).is_empty():
			return "%s/%s" % [section, str(record[key])]
	return "%s/%03d" % [section, index]


func _selected_feature() -> Dictionary:
	if _feature_entries.is_empty():
		return {}
	return _feature_entries[clampi(
		_selected_feature_index,
		0,
		_feature_entries.size() - 1
	)]


func _move_selected_feature(target_tile: Vector2i) -> void:
	var entry := _selected_feature()
	if entry.is_empty():
		return
	var section := str(entry.get("section", ""))
	var index := int(entry.get("index", -1))
	if section.begins_with("siege."):
		_move_selected_siege_feature(section, index, target_tile)
		return
	var records: Array = _level_document.get(section, [])
	if index < 0 or index >= records.size():
		return
	var record := (records[index] as Dictionary).duplicate(true)
	var delta := target_tile - _record_anchor(record)
	_translate_record(record, delta)
	records[index] = record
	_level_document[section] = records
	_feature_entries = _collect_feature_entries()


func _move_selected_siege_feature(
	section: String,
	index: int,
	target_tile: Vector2i
) -> void:
	var siege := (_level_document.get("siege", {}) as Dictionary).duplicate(true)
	var record: Dictionary
	if section == "siege.defense_turret":
		record = (siege.get("defense_turret", {}) as Dictionary).duplicate(true)
	else:
		var key := section.get_slice(".", 1)
		var records := (siege.get(key, []) as Array).duplicate(true)
		if index < 0 or index >= records.size():
			return
		record = (records[index] as Dictionary).duplicate(true)
		var old_offset := _array_to_vector2i(
			record.get("tile_offset", [0, 0])
		)
		var base := _siege_anchor_from_document(
			str(record.get("tile_offset_from", "main_gate"))
		)
		var new_offset := target_tile - base
		record["tile_offset"] = [new_offset.x, new_offset.y]
		if record.has("repair_tile_offset"):
			var repair := _array_to_vector2i(
				record.get("repair_tile_offset", [0, 0])
			)
			var delta := new_offset - old_offset
			record["repair_tile_offset"] = [
				repair.x + delta.x,
				repair.y + delta.y,
			]
		records[index] = record
		siege[key] = records
		_level_document["siege"] = siege
		return
	var base := _siege_anchor_from_document(
		str(record.get("tile_offset_from", "main_gate"))
	)
	var offset := target_tile - base
	record["tile_offset"] = [offset.x, offset.y]
	siege["defense_turret"] = record
	_level_document["siege"] = siege


func _siege_anchor_from_document(anchor_id: String) -> Vector2i:
	var marker_id := anchor_id
	if anchor_id == "return_mooring_origin":
		marker_id = "return_mooring"
	elif anchor_id == "entrance":
		marker_id = "spawn"
	for marker_variant: Variant in _level_document.get("markers", []):
		var marker := marker_variant as Dictionary
		if str(marker.get("id", "")) != marker_id:
			continue
		return _array_to_vector2i(marker.get("tile", [0, 0]))
	return Vector2i.ZERO


func _array_to_vector2i(value: Variant) -> Vector2i:
	var array := value as Array
	if array.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(array[0]), int(array[1]))


func _record_anchor(record: Dictionary) -> Vector2i:
	for key in ["tile", "origin"]:
		var value := record.get(key, []) as Array
		if value.size() >= 2:
			return Vector2i(int(value[0]), int(value[1]))
	for key in ["rect", "interior_rect", "roof_rect"]:
		var value := record.get(key, []) as Array
		if value.size() >= 2:
			return Vector2i(int(value[0]), int(value[1]))
	var cells := record.get("cells", []) as Array
	if not cells.is_empty() and cells[0] is Array:
		var cell := cells[0] as Array
		if cell.size() >= 2:
			return Vector2i(int(cell[0]), int(cell[1]))
	return Vector2i.ZERO


func _translate_record(record: Dictionary, delta: Vector2i) -> void:
	for key in ["tile", "origin"]:
		var value := record.get(key, []) as Array
		if value.size() >= 2:
			record[key] = [int(value[0]) + delta.x, int(value[1]) + delta.y]
	for key in ["rect", "interior_rect", "roof_rect"]:
		var value := record.get(key, []) as Array
		if value.size() >= 4:
			record[key] = [
				int(value[0]) + delta.x,
				int(value[1]) + delta.y,
				int(value[2]),
				int(value[3]),
			]
	if record.has("cells"):
		var translated_cells: Array = []
		for cell_variant: Variant in record.get("cells", []):
			var cell := cell_variant as Array
			if cell.size() >= 2:
				translated_cells.append([
					int(cell[0]) + delta.x,
					int(cell[1]) + delta.y,
				])
		record["cells"] = translated_cells


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
			"[SunderedKeepMapper] "
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
			"[SunderedKeepMapper] "
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
		_refresh_active_stamp_preview()
		_update_help()
		_overlay.queue_redraw()
		return
	if not _is_on_underlay(point):
		return
	_paint_active_source_at(_world_to_tile(point))


func _handle_right_click(point: Vector2) -> void:
	if _palette_number_at(point) > 0:
		_selected_tile_number = 0
		_update_help()
		_overlay.queue_redraw()
		return
	if _is_on_underlay(point):
		_remove_top_placement(_world_to_tile(point))


func _place_selected_tile(
	cell: Vector2i,
	record_undo := true
) -> bool:
	var item := _palette_item(_selected_tile_number)
	if item.is_empty():
		return false
	if not Rect2i(Vector2i.ZERO, UNDERLAY_GRID_SIZE).has_point(cell):
		return false
	if record_undo:
		_push_undo_state()
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
	return true


func _place_underlay_stamp(
	cell: Vector2i,
	record_undo := true
) -> bool:
	if _active_underlay_stamp.is_empty():
		return false
	var raw_rect := (
		_active_underlay_stamp.get("source_rect_cells", []) as Array
	)
	if raw_rect.size() < 4:
		return false
	var stamp_size := Vector2i(int(raw_rect[2]), int(raw_rect[3]))
	if (
		cell.x < 0
		or cell.y < 0
		or cell.x + stamp_size.x > UNDERLAY_GRID_SIZE.x
		or cell.y + stamp_size.y > UNDERLAY_GRID_SIZE.y
	):
		return false
	if record_undo:
		_push_undo_state()
	var placement := _active_underlay_stamp.duplicate(true)
	placement["cell"] = [cell.x, cell.y]
	_placements.append(placement)
	_dirty = true
	_rebuild_placement_preview()
	_update_help()
	_overlay.queue_redraw()
	return true


func _paint_active_source_at(
	cell: Vector2i,
	record_undo := true
) -> bool:
	if _paint_source == PaintSource.UNDERLAY_STAMP:
		return _place_underlay_stamp(cell, record_undo)
	if _selected_tile_number <= 0:
		return false
	return _place_selected_tile(cell, record_undo)


func _begin_paint_drag(point: Vector2) -> void:
	var cell := _world_to_tile(point)
	if not _can_paint_active_source_at(cell):
		return
	_push_undo_state()
	_paint_drag_active = true
	_paint_drag_last_cell = cell
	_paint_active_source_at(cell, false)


func _continue_paint_drag(point: Vector2) -> void:
	if not _paint_drag_active or not _is_on_underlay(point):
		return
	var cell := _world_to_tile(point)
	if cell == _paint_drag_last_cell:
		return
	var delta := cell - _paint_drag_last_cell
	var steps := maxi(absi(delta.x), absi(delta.y))
	var start := _paint_drag_last_cell
	for step in range(1, steps + 1):
		var ratio := float(step) / float(steps)
		var next_cell := Vector2i(
			roundi(lerpf(float(start.x), float(cell.x), ratio)),
			roundi(lerpf(float(start.y), float(cell.y), ratio))
		)
		_paint_active_source_at(next_cell, false)
	_paint_drag_last_cell = cell


func _finish_paint_drag() -> void:
	_paint_drag_active = false
	_paint_drag_last_cell = Vector2i(-1, -1)
	_update_help()
	_overlay.queue_redraw()


func _can_paint_active_source_at(cell: Vector2i) -> bool:
	if _paint_source == PaintSource.PALETTE_TILE:
		return (
			_selected_tile_number > 0
			and Rect2i(
				Vector2i.ZERO,
				UNDERLAY_GRID_SIZE
			).has_point(cell)
		)
	if _active_underlay_stamp.is_empty():
		return false
	var raw_rect := (
		_active_underlay_stamp.get("source_rect_cells", []) as Array
	)
	if raw_rect.size() < 4:
		return false
	var stamp_size := Vector2i(int(raw_rect[2]), int(raw_rect[3]))
	return Rect2i(Vector2i.ZERO, UNDERLAY_GRID_SIZE).encloses(
		Rect2i(cell, stamp_size)
	)


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
			_push_undo_state()
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


func _refresh_active_stamp_preview() -> void:
	if _active_stamp_preview == null:
		return
	_active_stamp_preview.visible = false
	if (
		_underlay_texture == null
		or _underlay_select_mode
		or _paint_source != PaintSource.UNDERLAY_STAMP
		or not _is_on_underlay(_mouse_world)
	):
		return
	var raw_rect := (
		_active_underlay_stamp.get("source_rect_cells", []) as Array
	)
	if raw_rect.size() < 4:
		return
	var source_rect_cells := Rect2i(
		Vector2i(int(raw_rect[0]), int(raw_rect[1])),
		Vector2i(int(raw_rect[2]), int(raw_rect[3]))
	)
	var target_cell := _world_to_tile(_mouse_world)
	if not Rect2i(Vector2i.ZERO, UNDERLAY_GRID_SIZE).encloses(
		Rect2i(target_cell, source_rect_cells.size)
	):
		return
	var source_rect_px := _source_rect_px_from_cells(source_rect_cells)
	var target_size_px := Vector2(source_rect_cells.size * TILE_SIZE)
	_active_stamp_preview.texture = _underlay_texture
	_active_stamp_preview.region_enabled = true
	_active_stamp_preview.region_rect = source_rect_px
	_active_stamp_preview.centered = false
	_active_stamp_preview.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	_active_stamp_preview.position = Vector2(target_cell * TILE_SIZE)
	_active_stamp_preview.scale = Vector2(
		target_size_px.x / maxf(1.0, source_rect_px.size.x),
		target_size_px.y / maxf(1.0, source_rect_px.size.y)
	)
	_active_stamp_preview.visible = true


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
	_underlay_select_mode = false
	_selecting_underlay_region = false
	_refresh_active_stamp_preview()
	_update_help()
	_overlay.queue_redraw()
	print(
		"[SunderedKeepMapper] "
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
	if event.ctrl_pressed:
		if event.keycode == KEY_Z:
			if event.shift_pressed:
				_redo()
			else:
				_undo()
			return
		if event.keycode == KEY_Y:
			_redo()
			return
	match event.keycode:
		KEY_C:
			_copy_mapping_to_clipboard()
		KEY_ENTER, KEY_KP_ENTER, KEY_U:
			_write_mapping_document()
		KEY_K:
			_cycle_authoring_mode(-1 if event.shift_pressed else 1)
		KEY_BRACKETLEFT:
			_cycle_active_authoring_item(-1)
		KEY_BRACKETRIGHT:
			_cycle_active_authoring_item(1)
		KEY_E:
			_show_collision = not _show_collision
		KEY_F:
			_focus_full_underlay()
		KEY_G:
			_show_grid = not _show_grid
		KEY_H:
			_show_help = not _show_help
			_hud.visible = _show_help
		KEY_F6, KEY_L, KEY_R:
			_reload_mapping_document()
		KEY_P:
			_focus_palette()
		KEY_Q:
			_underlay_select_mode = not _underlay_select_mode
			if _underlay_select_mode:
				_paint_source = PaintSource.UNDERLAY_STAMP
			else:
				_selecting_underlay_region = false
			_refresh_active_stamp_preview()
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
			_refresh_active_stamp_preview()
		KEY_T:
			_show_placements = not _show_placements
			_placed_root.visible = _show_placements
		KEY_DELETE:
			if _authoring_mode == AuthoringMode.TILES:
				_clear_placements()
			elif _authoring_mode == AuthoringMode.COLLISION:
				_draft_points.clear()
			elif _authoring_mode == AuthoringMode.MARKERS:
				_draft_markers.clear()
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
	if _level_document.is_empty():
		_dirty = false
		return
	for raw_placement: Variant in _level_document.get(
		"mapper_placements",
		[]
	):
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


func _reload_mapping_document() -> void:
	_push_undo_state()
	_load_level_document()
	_load_collision_document()
	_load_mapping_document()
	_rebuild_placement_preview()
	_refresh_active_stamp_preview()
	_overlay.queue_redraw()


func _clear_placements() -> void:
	if _placements.is_empty():
		return
	_push_undo_state()
	_placements.clear()
	_dirty = true
	_rebuild_placement_preview()
	_update_help()
	_overlay.queue_redraw()


func _push_undo_state() -> void:
	_undo_stack.append(_placements.duplicate(true))
	if _undo_stack.size() > MAX_UNDO_STATES:
		_undo_stack.pop_front()
	_redo_stack.clear()


func _undo() -> void:
	if _undo_stack.is_empty():
		return
	_redo_stack.append(_placements.duplicate(true))
	_restore_placements(_undo_stack.pop_back() as Array)


func _redo() -> void:
	if _redo_stack.is_empty():
		return
	_undo_stack.append(_placements.duplicate(true))
	if _undo_stack.size() > MAX_UNDO_STATES:
		_undo_stack.pop_front()
	_restore_placements(_redo_stack.pop_back() as Array)


func _restore_placements(snapshot: Array) -> void:
	_placements.clear()
	for raw_placement: Variant in snapshot:
		if raw_placement is Dictionary:
			_placements.append(
				(raw_placement as Dictionary).duplicate(true)
			)
	_dirty = true
	_rebuild_placement_preview()
	_update_help()
	_overlay.queue_redraw()


func _write_mapping_document() -> bool:
	if _level_document.is_empty():
		return false
	_level_document["mapper_schema"] = "custodian.sundered_keep.mapper.v1"
	_level_document["layout_generator"] = (
		"res://scenes/debug/sundered_keep_mapper.tscn"
	)
	_level_document["mapper_placements"] = _placement_document()
	_apply_collision_drafts()
	if not _write_json_dictionary(LEVEL_DATA_PATH, _level_document):
		return false
	if not _write_json_dictionary(COLLISION_DATA_PATH, _collision_document):
		return false
	_dirty = false
	print(
		"[SunderedKeepMapper] Saved %d mapped placement(s), %d collision "
		+ "segments, and production feature authority"
		% [
			_placements.size(),
			(_collision_document.get("segments", []) as Array).size(),
		]
	)
	_update_help()
	return true


func _copy_mapping_to_clipboard() -> void:
	var text := JSON.stringify({
		"level": _level_document,
		"collision": _collision_document,
		"mapper_placements": _placement_document(),
	}, "  ") + "\n"
	DisplayServer.clipboard_set(text)
	print(
		"[SunderedKeepMapper] "
		+ "Copied %d placement(s) to clipboard" % _placements.size()
	)


func _placement_document() -> Array[Dictionary]:
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
			var item := _palette_item(int(placement["tile_number"]))
			placement_document.append({
				"type": "palette_tile",
				"cell": [cell.x, cell.y],
				"tile_number": int(placement["tile_number"]),
				"category": str(placement["category"]),
				"asset_id": str(item.get("asset_id", "")),
				"texture_path": str(item.get("texture_path", "")),
			})
	return placement_document


func _mapping_document() -> Dictionary:
	return {
		"schema": "custodian.sundered_keep.mapper.v1",
		"level_data_path": LEVEL_DATA_PATH,
		"collision_data_path": COLLISION_DATA_PATH,
		"placements": _placement_document(),
	}


func _write_json_dictionary(path: String, document: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("[SunderedKeepMapper] Could not write %s" % path)
		return false
	file.store_string(JSON.stringify(document, "  ") + "\n")
	file.close()
	return true


func _apply_collision_drafts() -> void:
	if _draft_points.size() >= 2:
		var segments: Array = _collision_document.get("segments", [])
		for index in range(_draft_points.size() - 1):
			var a := _draft_points[index]
			var b := _draft_points[index + 1]
			segments.append([[a.x, a.y], [b.x, b.y]])
		_collision_document["segments"] = segments
		_draft_points.clear()
	var markers: Dictionary = _collision_document.get("markers", {})
	for marker_id: String in _draft_markers.keys():
		var point := _draft_markers[marker_id] as Vector2
		var marker: Dictionary = markers.get(marker_id, {})
		marker["kind"] = str(marker.get("kind", marker_id))
		marker["label"] = str(marker.get("label", marker_id.to_upper()))
		marker["position"] = [point.x, point.y]
		markers[marker_id] = marker
	_collision_document["markers"] = markers
	_draft_markers.clear()


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
		var raw_stamp_rect := (
			_active_underlay_stamp.get(
				"source_rect_cells",
				[]
			) as Array
		)
		if raw_stamp_rect.size() >= 4:
			var stamp_width := int(raw_stamp_rect[2])
			var stamp_height := int(raw_stamp_rect[3])
			active_stamp_text = (
				"%dx%d cells / %dx%d gameplay pixels"
				% [
					stamp_width,
					stamp_height,
					stamp_width * TILE_SIZE,
					stamp_height * TILE_SIZE,
				]
			)
	_hud.text = "\n".join([
		"Sundered Keep Production Level Mapper — mode %s"
			% AuthoringMode.keys()[_authoring_mode],
		"K / Shift+K: cycle tiles, collision, markers, features   [ ]: selected marker/feature",
		"P: numbered 01–99 palette   F: full underlay   S: spawn/causeway",
		"Tile mode — Q: sample underlay   Tab: palette/stamp   Left: place   Shift-drag: repeat",
		"Collision mode — Left: append rail point   Right: undo point",
		"Marker mode — Left: move marker   Feature mode — Left: move complete authored record",
		"Right-click underlay: remove top placement   Ctrl+Z: undo   Ctrl+Y/Ctrl+Shift+Z: redo",
		"WASD/arrows: pan   Wheel: zoom   G: grid   E: collision rails   T: placed tiles",
		"C: copy unified JSON   Enter/U: save production data   F6/L/R: reload   H: help",
		"Paint source: %s   Active stamp: %s   Source-select: %s" % [
			paint_source_text,
			active_stamp_text,
			"ON" if _underlay_select_mode else "OFF",
		],
		"Selected: %s   placements: %d%s" % [
			selected_text,
			_placements.size(),
			"   UNSAVED" if _dirty else "",
		],
		"Marker: %s   Feature: %s   mapped feature records: %d" % [
			_selected_marker_id(),
			str(_selected_feature().get("label", "none")),
			_feature_entries.size(),
		],
		"Mouse world: (%.1f, %.1f)   cell: %s" % [
			_mouse_world.x,
			_mouse_world.y,
			_world_to_tile(_mouse_world),
		],
	])


func get_sundered_keep_mapper_state() -> Dictionary:
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
		"active_stamp_preview": _active_stamp_preview,
		"undo_count": _undo_stack.size(),
		"redo_count": _redo_stack.size(),
		"paint_drag_active": _paint_drag_active,
		"mapping_path": LEVEL_DATA_PATH,
		"collision_path": COLLISION_DATA_PATH,
		"authoring_mode": AuthoringMode.keys()[_authoring_mode],
		"draft_points": _draft_points,
		"draft_markers": _draft_markers,
		"selected_marker": _selected_marker_id(),
		"collision_document": _collision_document,
		"feature_count": _feature_entries.size(),
		"selected_feature": _selected_feature(),
	}


func get_gameplay_tile_mapper_state() -> Dictionary:
	return get_sundered_keep_mapper_state()
