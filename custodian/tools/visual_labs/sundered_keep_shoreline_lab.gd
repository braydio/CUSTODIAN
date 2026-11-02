@tool
extends Node2D

const SHORELINE_COMPOSITOR := preload(
	"res://game/world/procgen/terrain/sundered_keep_shoreline_compositor.gd"
)
const TILESET := preload(
	"res://content/tiles/tilesets/procgen_world_tileset.tres"
)
const OCEAN_MASK_BUILDER := preload(
	"res://game/world/vistas/sundered_keep/sundered_keep_ocean_mask_builder.gd"
)
const VISTA_CONTRACT := preload(
	"res://game/world/procgen/landmarks/sundered_keep/sundered_keep_vista_contract.gd"
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
	CLIFF_VOCABULARY,
}

enum ProductionContextMode { NONE, OCEAN_UNDERLAY, FULL_VISTA }
enum ContextMoment { BASELINE, VISTA_APEX }

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
	"cliff_vocabulary",
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
	"Production Fixture",
	"Cliff Vocabulary"
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

@export_category("Debug Overlays")
@export var show_boundary_polyline := false:
	set(value):
		show_boundary_polyline = value
		_queue_rebuild()
@export var show_cliff_sample_points := false:
	set(value):
		show_cliff_sample_points = value
		_queue_rebuild()
@export var show_corner_markers := false:
	set(value):
		show_corner_markers = value
		_queue_rebuild()
@export var show_shore_distance_bands := false:
	set(value):
		show_shore_distance_bands = value
		_queue_rebuild()

@export_category("Production Context")
@export_enum("None", "Ocean Underlay", "Full Vista") var production_context_mode := 0:
	set(value):
		production_context_mode = clampi(value, 0, 2)
		_queue_rebuild()
@export_range(0.0, 1.0, 0.01) var context_alpha := 1.0:
	set(value):
		context_alpha = value
		_queue_rebuild()
@export var context_show_storm_underlay := true:
	set(value):
		context_show_storm_underlay = value
		_queue_rebuild()
@export var context_show_ruins := true:
	set(value):
		context_show_ruins = value
		_queue_rebuild()
@export var context_show_keep := true:
	set(value):
		context_show_keep = value
		_queue_rebuild()
@export var context_show_fog := true:
	set(value):
		context_show_fog = value
		_queue_rebuild()
@export var context_show_foreground_lip := true:
	set(value):
		context_show_foreground_lip = value
		_queue_rebuild()
@export_enum("Baseline", "Vista Apex") var context_moment := 0:
	set(value):
		context_moment = clampi(value, 0, 1)
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
var _fixture_vista_context: Dictionary = {}
var _context_warning := ""
var _ocean_mask_image: Image = null
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
	show_boundary_polyline = false
	show_cliff_sample_points = false
	show_corner_markers = false
	show_shore_distance_bands = false
	production_context_mode = ProductionContextMode.NONE
	context_alpha = 1.0
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
		"production_context_mode": production_context_mode,
		"context_warning": _context_warning,
		"ocean_mask_configured": _ocean_mask_image != null,
	}


func get_ocean_mask_alpha(cell: Vector2i) -> float:
	if _ocean_mask_image == null or _ocean_mask_image.is_empty():
		return 0.0
	var bounds := _cell_bounds(_floor_cells, _ocean_cells)
	var pixel := cell - bounds.position
	if pixel.x < 0 or pixel.y < 0 \
			or pixel.x >= _ocean_mask_image.get_width() \
			or pixel.y >= _ocean_mask_image.get_height():
		return 0.0
	return _ocean_mask_image.get_pixel(pixel.x, pixel.y).a


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
	_fixture_vista_context = cells.get("vista_context", {}) as Dictionary
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
	_configure_production_context(floor_layer)
	queue_redraw()


func _resolve_world_cell_size(tilemap: TileMapLayer) -> float:
	if tilemap == null:
		return float(TILESET.tile_size.x)
	var origin_local := tilemap.map_to_local(Vector2i.ZERO)
	var right_local := tilemap.map_to_local(Vector2i.RIGHT)
	var origin_world := tilemap.to_global(origin_local)
	var right_world := tilemap.to_global(right_local)
	return origin_world.distance_to(right_world)


func _resolve_world_cell_size_vertical(tilemap: TileMapLayer) -> float:
	if tilemap == null:
		return float(TILESET.tile_size.y)
	var origin_world := tilemap.to_global(tilemap.map_to_local(Vector2i.ZERO))
	var down_world := tilemap.to_global(tilemap.map_to_local(Vector2i.DOWN))
	return origin_world.distance_to(down_world)


func _draw() -> void:
	var preview_root := get_node_or_null("PreviewRoot") as Node2D
	if preview_root == null or _plan.is_empty():
		return
	if show_shore_distance_bands:
		for cell_variant in _floor_cells.keys():
			var cell := cell_variant as Vector2i
			var distance := SHORELINE_COMPOSITOR.ocean_manhattan_distance(
				cell, _ocean_cells, 2
			)
			var color := Color(0.35, 0.35, 0.38, 0.22)
			if distance == 1:
				color = Color(1.0, 0.85, 0.1, 0.34)
			elif distance == 2:
				color = Color(0.15, 1.0, 0.35, 0.28)
			_draw_grid_cell(preview_root, cell, color)
		for cell_variant in _ocean_cells.keys():
			_draw_grid_cell(preview_root, cell_variant as Vector2i, Color(0.12, 0.32, 1.0, 0.18))
	if show_boundary_polyline:
		for run_variant in _plan.get("runs", []):
			var points := PackedVector2Array()
			for point_variant in (run_variant as Dictionary).get("points_grid", []):
				points.append(_preview_grid_to_local(preview_root, point_variant as Vector2))
			if points.size() >= 2:
				draw_polyline(points, Color(0.2, 1.0, 0.75, 0.95), 1.5, false)
	if show_cliff_sample_points or show_corner_markers:
		for entry_variant in _plan.get("cliffs", []):
			var entry := entry_variant as Dictionary
			var kind := String(entry.get("kind", "edge"))
			var point := _preview_grid_to_local(
				preview_root,
				entry.get("position_grid", Vector2.ZERO) as Vector2
			)
			var colors := {
				"edge": Color.WHITE,
				"face_slice": Color.YELLOW,
				"inner_corner": Color.CYAN,
				"outer_corner": Color.MAGENTA,
			}
			if show_cliff_sample_points:
				draw_circle(point, 4.0, colors.get(kind, Color.WHITE))
			if show_corner_markers and kind.ends_with("corner"):
				var label := "%s_%s" % [kind.to_upper(), String(entry.get("asset_key", "")).get_slice("_", 2).to_upper()]
				draw_string(ThemeDB.fallback_font, point + Vector2(6.0, -5.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, colors.get(kind, Color.WHITE))
	if not _context_warning.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(18.0, 28.0), _context_warning, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(1.0, 0.75, 0.2))


func _preview_grid_to_local(preview_root: Node2D, grid: Vector2) -> Vector2:
	return to_local(preview_root.to_global(grid * Vector2(TILESET.tile_size)))


func _draw_grid_cell(preview_root: Node2D, cell: Vector2i, color: Color) -> void:
	var top_left := _preview_grid_to_local(preview_root, Vector2(cell))
	var bottom_right := _preview_grid_to_local(preview_root, Vector2(cell + Vector2i.ONE))
	draw_rect(Rect2(top_left, bottom_right - top_left), color, true)


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
			var kind := String(child.get_meta("kind", "edge"))
			var colors := {
				"edge": Color(1.0, 0.2, 0.2, 0.95),
				"face_slice": Color(1.0, 0.85, 0.1, 0.95),
				"inner_corner": Color(0.1, 1.0, 1.0, 0.95),
				"outer_corner": Color(1.0, 0.1, 0.9, 0.95),
			}
			(child as Sprite2D).modulate = colors.get(kind, Color.WHITE)


func _configure_production_context(floor_layer: TileMapLayer) -> void:
	var context_root := get_node_or_null("ProductionContextRoot") as Node2D
	var ocean_layer := get_node_or_null("PreviewRoot/OceanBase") as TileMapLayer
	if context_root == null:
		return
	context_root.visible = production_context_mode != ProductionContextMode.NONE
	context_root.modulate.a = context_alpha
	if ocean_layer != null:
		ocean_layer.modulate.a = 0.32 if context_root.visible else 1.0
	_context_warning = ""
	if not context_root.visible:
		return
	var bundle := context_root.get_node_or_null("VistaArtBundle") as Node2D
	var storm := context_root.get_node_or_null(
		"VistaArtBundle/ExteriorVistaClip/HorizonPresentation/StormHorizon"
	) as Sprite2D
	var ruins := context_root.get_node_or_null(
		"VistaArtBundle/ExteriorVistaClip/HorizonPresentation/OceanRuinsPresentation"
	) as Node2D
	var keep := context_root.get_node_or_null(
		"VistaArtBundle/ExteriorVistaClip/FortressPresentation"
	) as Node2D
	var fog := context_root.get_node_or_null(
		"VistaArtBundle/ExteriorVistaClip/FortressPresentation/FrontageFog"
	) as Sprite2D
	var lip := context_root.get_node_or_null(
		"VistaArtBundle/ExteriorVistaClip/ForegroundVistaCliffLip"
	) as Sprite2D
	if bundle == null or storm == null:
		return
	storm.visible = context_show_storm_underlay
	var full_requested := production_context_mode == ProductionContextMode.FULL_VISTA
	var full_available := shape_preset == ShapePreset.PRODUCTION_FIXTURE \
		and not _fixture_vista_context.is_empty()
	if full_requested and not full_available:
		_context_warning = "Full Vista requires production fixture vista_context; showing Ocean Underlay."
	var show_full := full_requested and full_available
	ruins.visible = show_full and context_show_ruins
	keep.visible = show_full and context_show_keep
	fog.visible = show_full and context_show_fog
	lip.visible = show_full and context_show_foreground_lip
	var bounds := _cell_bounds(_floor_cells, _ocean_cells)
	var map_size := bounds.size
	var cell_world := Vector2(
		_resolve_world_cell_size(floor_layer),
		_resolve_world_cell_size_vertical(floor_layer)
	)
	var min_center := floor_layer.to_global(floor_layer.map_to_local(bounds.position))
	var mask := OCEAN_MASK_BUILDER.build(
		_floor_cells,
		_ocean_cells,
		map_size,
		min_center - cell_world * 0.5,
		cell_world,
		bounds.position
	)
	_ocean_mask_image = mask.get("image") as Image
	OCEAN_MASK_BUILDER.apply_to_sprite(storm, mask)
	storm.global_position = Vector2(640.0, 360.0)
	if storm.texture != null:
		var coverage := Vector2(map_size) * cell_world
		var texture_size := storm.texture.get_size()
		storm.scale = Vector2(
			coverage.x / maxf(1.0, texture_size.x),
			coverage.y / maxf(1.0, texture_size.y)
		)
	if show_full:
		_apply_full_vista_context(bundle, ruins, keep, fog, lip, floor_layer)


func _apply_full_vista_context(
	_bundle: Node2D,
	ruins: Node2D,
	keep: Node2D,
	fog: Sprite2D,
	lip: Sprite2D,
	floor_layer: TileMapLayer
) -> void:
	var fortress_cell := _context_cell("fortress_anchor")
	var ruins_cell := _context_cell("ruins_anchor")
	var lip_cell := _context_cell("foreground_lip_anchor")
	keep.global_position = floor_layer.to_global(floor_layer.map_to_local(fortress_cell))
	ruins.global_position = floor_layer.to_global(floor_layer.map_to_local(ruins_cell))
	lip.global_position = floor_layer.to_global(floor_layer.map_to_local(lip_cell))
	var route_s := VISTA_CONTRACT.S_VISTA_APEX \
		if context_moment == ContextMoment.VISTA_APEX else VISTA_CONTRACT.S_INFLUENCE_START
	ruins.modulate.a = VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.RUINS_ALPHA_KEYS, route_s)
	keep.modulate.a = VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.KEEP_ALPHA_KEYS, route_s)
	fog.modulate.a = VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.SEAM_FOG_ALPHA_KEYS, route_s)
	lip.modulate.a = VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.FOREGROUND_LIP_ALPHA_KEYS, route_s)


func _context_cell(key: String) -> Vector2i:
	var value: Variant = _fixture_vista_context.get(key, [0, 0])
	if value is Vector2i:
		return value
	if value is Array and (value as Array).size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO


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
		ShapePreset.CLIFF_VOCABULARY:
			var inside := cell.x >= -11 and cell.x <= 11 and cell.y >= -7 and cell.y <= 7
			var north_cove := cell.x >= -6 and cell.x <= -3 and cell.y >= -7 and cell.y <= -4
			var south_cove := cell.x >= 3 and cell.x <= 6 and cell.y >= 4 and cell.y <= 7
			var stair_cut := cell.x >= 7 and cell.y <= cell.x - 14
			return inside and not north_cove and not south_cove and not stair_cut
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


static func _cell_bounds(
	floor_cells: Dictionary,
	ocean_cells: Dictionary
) -> Rect2i:
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
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE) if initialized else Rect2i()
