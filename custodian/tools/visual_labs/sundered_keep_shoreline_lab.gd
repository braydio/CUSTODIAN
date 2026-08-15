@tool
extends Node2D

const SHORELINE_COMPOSITOR := preload(
	"res://game/world/procgen/terrain/sundered_keep_shoreline_compositor.gd"
)
const TILESET := preload(
	"res://content/tiles/tilesets/procgen_world_tileset.tres"
)

enum ShapePreset {
	STRAIGHT,
	STAIR_STEP,
	CONVEX_CORNER,
	CONCAVE_COVE,
	PENINSULA,
	NARROW_INLET,
	JAGGED_COAST,
	TINY_ISLAND,
	PRODUCTION_FIXTURE,
}

const PRESET_NAMES := [
	"straight",
	"stair_step",
	"convex_corner",
	"concave_cove",
	"peninsula",
	"narrow_inlet",
	"jagged_coast",
	"tiny_island",
	"production_fixture",
]

const DEFAULT_FIXTURE := (
	"res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_001.json"
)
const CAPTURE_DIRECTORY := "res://../reports/visual_labs/sundered_keep_shoreline"

@export_category("Shoreline")
@export_enum(
	"Straight",
	"Stair Step",
	"Convex Corner",
	"Concave Cove",
	"Peninsula",
	"Narrow Inlet",
	"Jagged Coast",
	"Tiny Island",
	"Production Fixture"
) var shape_preset: int = ShapePreset.CONCAVE_COVE:
	set(value):
		shape_preset = clampi(value, 0, ShapePreset.size() - 1)
		_queue_rebuild()

@export var seed: int = 17:
	set(value):
		seed = value
		_queue_rebuild()

@export_range(16.0, 64.0, 1.0) var cliff_spacing_px := 32.0:
	set(value):
		cliff_spacing_px = value
		_queue_rebuild()

@export_range(0.0, 32.0, 1.0) var corner_overlap_px := 16.0:
	set(value):
		corner_overlap_px = value
		_queue_rebuild()

@export_range(0.05, 0.5, 0.01) var foam_alpha := 0.22:
	set(value):
		foam_alpha = value
		_queue_rebuild()

@export_range(0, 4, 1) var shore_band_width_cells := 2:
	set(value):
		shore_band_width_cells = value
		_queue_rebuild()

@export var cliff_modulate := Color(0.72, 0.77, 0.84, 0.96):
	set(value):
		cliff_modulate = value
		_queue_rebuild()

@export_file("*.json") var production_fixture_path := DEFAULT_FIXTURE:
	set(value):
		production_fixture_path = value
		_queue_rebuild()

@export_category("Visibility")
@export var show_floor := true:
	set(value):
		show_floor = value
		_queue_rebuild()
@export var show_ocean := true:
	set(value):
		show_ocean = value
		_queue_rebuild()
@export var show_foam := true:
	set(value):
		show_foam = value
		_queue_rebuild()
@export var show_cliffs := true:
	set(value):
		show_cliffs = value
		_queue_rebuild()
@export var show_glue_ribbon := true:
	set(value):
		show_glue_ribbon = value
		_queue_rebuild()
@export var false_color_debug := false:
	set(value):
		false_color_debug = value
		_queue_rebuild()

@export_category("Actions")
@export_tool_button("Regenerate") var regenerate_action := regenerate
@export_tool_button("Previous Seed") var previous_seed_action := previous_seed
@export_tool_button("Next Seed") var next_seed_action := next_seed
@export_tool_button("Reset Defaults") var reset_defaults_action := reset_defaults
@export_tool_button("Capture PNG") var capture_png_action := capture_png
@export_tool_button("Save Fixture") var save_fixture_action := save_fixture

var _rebuild_queued := false
var _floor_cells: Dictionary = {}
var _ocean_cells: Dictionary = {}
var _plan: Dictionary = {}
var _dragging := false
var _drag_start := Vector2.ZERO


func _enter_tree() -> void:
	_queue_rebuild()


func _ready() -> void:
	_queue_rebuild()
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	camera.position += direction * 420.0 * delta / maxf(camera.zoom.x, 0.01)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mouse_event.pressed
			_drag_start = mouse_event.position
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.1).clamp(Vector2(0.2, 0.2), Vector2(4.0, 4.0))
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom / 1.1).clamp(Vector2(0.2, 0.2), Vector2(4.0, 4.0))
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		camera.position -= motion.relative / maxf(camera.zoom.x, 0.01)


func regenerate() -> void:
	_queue_rebuild()


func previous_seed() -> void:
	seed -= 1


func next_seed() -> void:
	seed += 1


func reset_defaults() -> void:
	shape_preset = ShapePreset.CONCAVE_COVE
	seed = 17
	cliff_spacing_px = 32.0
	corner_overlap_px = 16.0
	foam_alpha = 0.22
	shore_band_width_cells = 2
	cliff_modulate = Color(0.72, 0.77, 0.84, 0.96)
	show_floor = true
	show_ocean = true
	show_foam = true
	show_cliffs = true
	show_glue_ribbon = true
	false_color_debug = false
	_queue_rebuild()


func capture_png() -> void:
	if not is_inside_tree():
		return
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_warning("Shoreline Lab capture requires a rendered editor or F6 viewport.")
		return
	var absolute_directory := ProjectSettings.globalize_path(CAPTURE_DIRECTORY)
	var error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if error != OK:
		push_error("Could not create shoreline capture directory: %s" % error_string(error))
		return
	var timestamp := Time.get_datetime_string_from_system(false, true).replace(":", "-")
	var filename := "%s_seed_%03d_%s.png" % [
		PRESET_NAMES[shape_preset],
		seed,
		timestamp,
	]
	var output_path := absolute_directory.path_join(filename)
	error = image.save_png(output_path)
	if error != OK:
		push_error("Could not save shoreline capture: %s" % error_string(error))
	else:
		print("[SunderedKeepShorelineLab] capture=%s" % output_path)


func save_fixture() -> void:
	if _floor_cells.is_empty() or _ocean_cells.is_empty():
		return
	var directory := ProjectSettings.globalize_path(
		"res://tools/visual_labs/fixtures/sundered_keep_shorelines"
	)
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		push_error("Could not create fixture directory: %s" % error_string(error))
		return
	var output_path := directory.path_join(
		"%s_seed_%03d.json" % [PRESET_NAMES[shape_preset], seed]
	)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write shoreline fixture: %s" % output_path)
		return
	file.store_string(SHORELINE_COMPOSITOR.fixture_to_json(
		seed,
		_floor_cells,
		_ocean_cells,
		{"preset": PRESET_NAMES[shape_preset]}
	))
	file.close()
	print("[SunderedKeepShorelineLab] fixture=%s" % output_path)


func get_shoreline_plan() -> Dictionary:
	return _plan.duplicate(true)


func get_floor_cells() -> Dictionary:
	return _floor_cells.duplicate(true)


func get_ocean_cells() -> Dictionary:
	return _ocean_cells.duplicate(true)


func get_render_context() -> Dictionary:
	var preview_root := get_node_or_null("PreviewRoot") as Node2D
	var floor_layer := get_node_or_null("PreviewRoot/Floor") as TileMapLayer
	var local_tile_size := Vector2(TILESET.tile_size)
	var preview_root_scale := preview_root.global_transform.get_scale() \
		if preview_root != null else Vector2.ONE
	var world_cell_size := _resolve_world_cell_size(floor_layer)
	return {
		"local_tile_size": local_tile_size,
		"preview_root_scale": preview_root_scale,
		"world_cell_size": world_cell_size,
		"cliff_spacing_world_px": cliff_spacing_px,
		"effective_cliff_samples_per_cell": world_cell_size / cliff_spacing_px,
	}


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return
	var preview_root := get_node_or_null("PreviewRoot") as Node2D
	var ocean_layer := get_node_or_null("PreviewRoot/OceanBase") as TileMapLayer
	var foam_layer := get_node_or_null("PreviewRoot/Foam") as TileMapLayer
	var floor_layer := get_node_or_null("PreviewRoot/Floor") as TileMapLayer
	var extra_foam := get_node_or_null("PreviewRoot/Foam/ExtraFoam") as Node2D
	var cliffs := get_node_or_null("PreviewRoot/CliffPresentation") as Node2D
	if preview_root == null or ocean_layer == null or foam_layer == null \
			or floor_layer == null or extra_foam == null or cliffs == null:
		return
	var cells := _load_or_generate_cells()
	_floor_cells = cells.get("floor_cells", {}) as Dictionary
	_ocean_cells = cells.get("ocean_cells", {}) as Dictionary
	var effective_seed := int(cells.get("seed", seed))
	var world_cell_size := _resolve_world_cell_size(floor_layer)
	_plan = SHORELINE_COMPOSITOR.build_plan(
		_floor_cells,
		_ocean_cells,
		effective_seed,
		{
			"cell_world_size": world_cell_size,
			"cliff_spacing_px": cliff_spacing_px,
			"cliff_overlap_px": corner_overlap_px,
			"foam_alpha": foam_alpha,
			"shore_band_width_cells": shore_band_width_cells,
			"cliff_modulate": cliff_modulate,
		}
	)
	var local_fixture_center := _cell_bounds_center(
		_floor_cells,
		_ocean_cells
	) * Vector2(TILESET.tile_size)
	preview_root.position = Vector2(640.0, 360.0) \
		- preview_root.transform.basis_xform(local_fixture_center)
	ocean_layer.clear()
	floor_layer.clear()
	for cell_variant in _ocean_cells.keys():
		ocean_layer.set_cell(cell_variant as Vector2i, 124, Vector2i.ZERO, 0)
	for cell_variant in _floor_cells.keys():
		floor_layer.set_cell(cell_variant as Vector2i, 129, Vector2i.ZERO, 0)
	SHORELINE_COMPOSITOR.apply_floor_band(_plan, floor_layer)
	SHORELINE_COMPOSITOR.apply_foam(_plan, foam_layer, extra_foam)
	SHORELINE_COMPOSITOR.build_cliff_presentation(
		_plan,
		cliffs,
		Vector2(TILESET.tile_size),
		preview_root.global_transform.get_scale(),
		show_glue_ribbon,
		show_cliffs
	)
	ocean_layer.visible = show_ocean
	floor_layer.visible = show_floor
	foam_layer.visible = show_foam
	cliffs.visible = show_cliffs or show_glue_ribbon
	_apply_false_color(ocean_layer, foam_layer, floor_layer, cliffs)


func _resolve_world_cell_size(tilemap: TileMapLayer) -> float:
	if tilemap == null:
		return float(TILESET.tile_size.x)
	var origin_local := tilemap.map_to_local(Vector2i.ZERO)
	var right_local := tilemap.map_to_local(Vector2i.RIGHT)
	var origin_world := tilemap.to_global(origin_local)
	var right_world := tilemap.to_global(right_local)
	return origin_world.distance_to(right_world)


func _apply_false_color(
	ocean_layer: TileMapLayer,
	foam_layer: TileMapLayer,
	floor_layer: TileMapLayer,
	cliffs: Node2D
) -> void:
	if not false_color_debug:
		ocean_layer.self_modulate = Color.WHITE
		foam_layer.self_modulate = Color(1.0, 1.0, 1.0, foam_alpha)
		floor_layer.self_modulate = Color.WHITE
		return
	ocean_layer.self_modulate = Color(0.15, 0.35, 1.0, 1.0)
	foam_layer.self_modulate = Color(0.0, 1.0, 1.0, 0.85)
	floor_layer.self_modulate = Color(0.15, 1.0, 0.25, 1.0)
	for child in cliffs.get_children():
		if child is Line2D:
			(child as Line2D).default_color = Color(1.0, 0.0, 1.0, 0.95)
		elif child is Sprite2D:
			(child as Sprite2D).modulate = Color(1.0, 0.1, 0.1, 0.95)


func _load_or_generate_cells() -> Dictionary:
	if shape_preset == ShapePreset.PRODUCTION_FIXTURE:
		var file := FileAccess.open(production_fixture_path, FileAccess.READ)
		if file != null:
			return SHORELINE_COMPOSITOR.fixture_from_json(file.get_as_text())
	return _generate_synthetic_cells(shape_preset, seed)


static func _generate_synthetic_cells(preset: int, seed_value: int) -> Dictionary:
	var floor_cells: Dictionary = {}
	var ocean_cells: Dictionary = {}
	for y in range(-10, 11):
		for x in range(-14, 15):
			var cell := Vector2i(x, y)
			var is_floor := _is_floor_for_preset(cell, preset, seed_value)
			if is_floor:
				floor_cells[cell] = true
			else:
				ocean_cells[cell] = true
	return {
		"seed": seed_value,
		"floor_cells": floor_cells,
		"ocean_cells": ocean_cells,
	}


static func _is_floor_for_preset(cell: Vector2i, preset: int, seed_value: int) -> bool:
	match preset:
		ShapePreset.STRAIGHT:
			return cell.y >= 0
		ShapePreset.STAIR_STEP:
			return cell.y >= floor(float(cell.x + 12) / 4.0) - 3
		ShapePreset.CONVEX_CORNER:
			return cell.x >= 0 or cell.y >= 0
		ShapePreset.CONCAVE_COVE:
			return cell.y >= maxi(0, 5 - absi(cell.x))
		ShapePreset.PENINSULA:
			return cell.y >= -maxi(0, 6 - absi(cell.x))
		ShapePreset.NARROW_INLET:
			return cell.y >= (7 if absi(cell.x) <= 2 else 0)
		ShapePreset.JAGGED_COAST:
			var hashed := absi(cell.x * 73856093 ^ seed_value * 83492791)
			return cell.y >= int(hashed % 7) - 3
		ShapePreset.TINY_ISLAND:
			return Vector2(cell).length_squared() <= 30.0
		_:
			var hashed := absi(cell.x * 19349663 ^ seed_value * 83492791)
			return cell.y >= int(hashed % 5) - 1


static func _cell_bounds_center(
	floor_cells: Dictionary,
	ocean_cells: Dictionary
) -> Vector2:
	var initialized := false
	var minimum := Vector2i.ZERO
	var maximum := Vector2i.ZERO
	for cells in [floor_cells, ocean_cells]:
		for cell_variant in (cells as Dictionary).keys():
			var cell := cell_variant as Vector2i
			if not initialized:
				minimum = cell
				maximum = cell
				initialized = true
			else:
				minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
				maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	return (Vector2(minimum) + Vector2(maximum) + Vector2.ONE) * 0.5 \
		if initialized else Vector2.ZERO
