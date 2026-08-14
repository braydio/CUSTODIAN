extends Node2D
class_name SunderedKeepProcgenVistaPresentation

const CAMERA_DIRECTOR := preload(
	"res://game/world/procgen/landmarks/sundered_keep/"
	+ "sundered_keep_frontage_camera_director.gd"
)
const VISTA_CONTRACT := preload("res://game/world/procgen/landmarks/sundered_keep/sundered_keep_vista_contract.gd")

const VIEWPORT_SAFETY_MARGIN := Vector2(256.0, 224.0)
const VISTA_HORIZONTAL_MARGIN := 320.0
const VISTA_OPERATOR_ACTIVATION_MARGIN := 160.0
const MOONLIGHT_FRAME_SECONDS := 1.0 / 15.0
const MOONLIGHT_FRAME_COUNT := 6

@export var operator_path := NodePath("/root/GameRoot/World/Operator")
@export var camera_path := NodePath("/root/GameRoot/World/Camera2D")

@onready var _vista_root := $VistaPresentationRoot as Node2D
@onready var _exterior_clip := (
	$VistaPresentationRoot/ExteriorVistaClip as Polygon2D
)
@onready var _horizon := (
	$VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation as Node2D
)
@onready var _storm := (
	$VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/StormHorizon as Sprite2D
)
@onready var _ocean_ruins := (
	$VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/OceanRuinsPresentation as Node2D
)
@onready var _reveal_fog := (
	$VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/RevealFog as Sprite2D
)
@onready var _fortress := (
	$VistaPresentationRoot/ExteriorVistaClip/FortressPresentation as Node2D
)
@onready var _frontage_fog := (
	$VistaPresentationRoot/ExteriorVistaClip/FortressPresentation/FrontageFog as Sprite2D
)
@onready var _moonlight_sweep := (
	$VistaPresentationRoot/ExteriorVistaClip/FortressPresentation/MoonlightSweep as Sprite2D
)
@onready var _foreground_cliff_lip := (
	$VistaPresentationRoot/ExteriorVistaClip/ForegroundVistaCliffLip as Sprite2D
)
@onready var _presentation_anchor := (
	$CameraPresentationAnchor as Marker2D
)

var _ingress: Node2D = null
var _map_instance: Node = null
var _level_data: Dictionary = {}
var _frontage: Dictionary = {}
var _operator: Node2D = null
var _camera: Camera2D = null
var _director: RefCounted = null
var _world_anchors: Dictionary = {}
var _configured := false
var _camera_owned := false
var _camera_state: Dictionary = {}
var _presentation_bounds := Rect2()
var _viewport_coverage := Vector2.ZERO
var _vista_clip_bounds := Rect2()
var _playable_floor_bounds := Rect2()
var _ocean_bounds := Rect2()
var _moonlight_elapsed := -1.0
var _moonlight_played := false
var _ocean_mask_texture: ImageTexture = null
var _ocean_mask_image: Image = null
var _ocean_ruins_anchor_cell := Vector2i(-1, -1)
var _centerline_cells: Array = []
var _centerline_world := PackedVector2Array()
var _influence_start_index := 0
var _vista_focus := Vector2.ZERO
var _vista_focus_bounded := Vector2.ZERO
var _cinematic_complete := false


func _ready() -> void:
	add_to_group("sundered_keep_world_vista")
	_director = CAMERA_DIRECTOR.new()
	_horizon.modulate.a = 1.0
	_storm.modulate.a = 1.0
	_reveal_fog.visible = false
	_resolve_runtime_nodes()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(
		_on_viewport_size_changed
	):
		viewport.size_changed.connect(_on_viewport_size_changed)
	if _ingress != null:
		_layout_from_semantic_anchors()


func _exit_tree() -> void:
	_release_camera()


func configure(
	ingress: Node,
	map_instance: Node,
	level_data: Dictionary
) -> void:
	_ingress = ingress as Node2D
	_map_instance = map_instance
	_level_data = level_data.duplicate(true)
	_frontage = (
		_level_data.get("sundered_keep_frontage", {}) as Dictionary
	).duplicate(true)
	_resolve_runtime_nodes()
	if is_node_ready():
		_layout_from_semantic_anchors()


func _process(delta: float) -> void:
	if not _configured:
		return
	_resolve_runtime_nodes()
	if _operator == null:
		_release_camera()
		return
	_evaluate_camera(delta)


func _resolve_runtime_nodes() -> void:
	if _operator == null or not is_instance_valid(_operator):
		_operator = get_node_or_null(operator_path) as Node2D
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_node_or_null(camera_path) as Camera2D


func _layout_from_semantic_anchors() -> void:
	if _frontage.is_empty():
		return
	var semantic: Dictionary = _frontage.get(
		"camera_semantic_anchors",
		{}
	)
	var required_names := [
		"frontage_entry",
		"first_influence_start",
		"first_reveal_apex",
		"first_return_complete",
		"frontage_reveal_start",
		"frontage_apex",
		"vista_apex",
		"vista_apex_plateau_end",
		"moonlight_anchor",
		"gameplay_return",
		"gate_threshold",
	]
	_world_anchors.clear()
	for anchor_name in required_names:
		var tile: Variant = semantic.get(anchor_name)
		if not tile is Vector2i:
			_configured = false
			return
		_world_anchors[anchor_name] = _tile_to_world(tile as Vector2i)
	_assign_marker("FrontageEntry", _world_anchors["frontage_entry"])
	_assign_marker(
		"FirstCameraInfluenceStart",
		_world_anchors["first_influence_start"]
	)
	_assign_marker("FirstRevealApex", _world_anchors["first_reveal_apex"])
	_assign_marker(
		"FirstCameraReturnComplete",
		_world_anchors["first_return_complete"]
	)
	_assign_marker(
		"FrontageRevealStart",
		_world_anchors["frontage_reveal_start"]
	)
	_assign_marker("FrontageApex", _world_anchors["frontage_apex"])
	_assign_marker("GameplayReturn", _world_anchors["gameplay_return"])
	_assign_marker("GateThreshold", _world_anchors["gate_threshold"])
	# Compatibility aliases remain presentation-only and no longer author
	# physical coordinates.
	_assign_marker(
		"CameraInfluenceStart",
		_world_anchors["first_influence_start"]
	)
	_assign_marker("CameraApex", _world_anchors["first_reveal_apex"])
	_assign_marker(
		"CameraReturnStart",
		_world_anchors["first_reveal_apex"]
	)
	_assign_marker(
		"CameraReturnComplete",
		_world_anchors["first_return_complete"]
	)

	var visual: Dictionary = _frontage.get("visual_module_anchors", {})
	var fortress_anchor := _tile_to_world(
		visual.get(
			"fortress_front_anchor",
			semantic["gate_threshold"]
		) as Vector2i
	)
	var horizon_anchor := (
		_world_anchors["first_reveal_apex"] as Vector2
	).lerp(fortress_anchor, 0.55)
	_horizon.global_position = horizon_anchor
	_ocean_ruins_anchor_cell = _select_ocean_ruins_anchor()
	if _ocean_ruins_anchor_cell.x >= 0:
		_ocean_ruins.global_position = _tile_to_world(_ocean_ruins_anchor_cell)
	_fortress.global_position = fortress_anchor
	_centerline_cells = _frontage.get("route_centerline", []) as Array
	_centerline_world = PackedVector2Array()
	for cell_variant in _centerline_cells:
		_centerline_world.append(_tile_to_world(cell_variant as Vector2i))
	var semantic_indices: Dictionary = _frontage.get("camera_semantic_indices", {})
	_influence_start_index = int(semantic_indices.get("first_influence_start", 0))
	var ruins_subject := _ocean_ruins.global_position + Vector2(0.0, -32.0)
	var keep_subject := _fortress.global_position + Vector2(0.0, -96.0)
	_vista_focus = ruins_subject.lerp(keep_subject, 0.56)
	_fit_presentation_to_viewport()
	_configure_exterior_clip()
	_configure_ocean_underlay_mask()
	_update_presentation_bounds()
	_configured = true
	if _operator != null:
		_evaluate_camera(0.0)


func _assign_marker(name: String, world_position: Vector2) -> void:
	var marker := get_node_or_null(name) as Marker2D
	if marker != null:
		marker.global_position = world_position


func _evaluate_camera(delta: float = 0.0) -> void:
	if not _is_operator_inside_frontage_influence():
		_camera_state.clear()
		_apply_visual_state(VISTA_CONTRACT.S_INFLUENCE_START)
		_release_camera()
		_vista_root.visible = false
		return
	_vista_root.visible = true
	_camera_state = _director.call(
		"evaluate",
		_operator.global_position,
		_centerline_cells,
		_centerline_world,
		_influence_start_index
	) as Dictionary
	var route_s := float(_camera_state.get("route_s_cells", -INF))
	var camera_weight := float(_camera_state.get("camera_weight", 0.0))
	if route_s >= VISTA_CONTRACT.S_MOONLIGHT and not _moonlight_played:
		_moonlight_elapsed = 0.0
		_moonlight_played = true
	_update_moonlight(delta)
	var displacement_limit := _runtime_world_cell_size() * VISTA_CONTRACT.MAX_CAMERA_DISPLACEMENT_CELLS
	var focus_vector := _vista_focus - _operator.global_position
	_vista_focus_bounded = _vista_focus
	if focus_vector.length() > displacement_limit:
		_vista_focus_bounded = _operator.global_position + focus_vector.normalized() * maxf(0.0, displacement_limit - 0.01)
	_presentation_anchor.global_position = _operator.global_position.lerp(
		_vista_focus_bounded,
		camera_weight
	)
	_apply_visual_state(route_s)
	if route_s >= VISTA_CONTRACT.S_GAMEPLAY_RETURN:
		_cinematic_complete = true
	_apply_camera_state(camera_weight)


func _update_moonlight(delta: float) -> void:
	if _moonlight_elapsed < 0.0:
		return
	_moonlight_elapsed += delta
	var frame := int(floor(_moonlight_elapsed / MOONLIGHT_FRAME_SECONDS))
	if frame >= MOONLIGHT_FRAME_COUNT:
		_moonlight_sweep.visible = false
		_moonlight_elapsed = -1.0
		return
	_moonlight_sweep.visible = true
	_moonlight_sweep.region_rect = Rect2(
		float(frame * 1024), 0.0, 1024.0, 512.0
	)


func _is_operator_inside_frontage_influence() -> bool:
	if _operator == null or not _playable_floor_bounds.has_area():
		return false
	return _playable_floor_bounds.grow(
		VISTA_OPERATOR_ACTIVATION_MARGIN
	).has_point(_operator.global_position)


func _apply_visual_state(route_s: float) -> void:
	_horizon.modulate.a = 1.0
	_storm.modulate.a = 1.0
	_reveal_fog.visible = false
	_ocean_ruins.modulate.a = VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.RUINS_ALPHA_KEYS, route_s)
	_fortress.modulate.a = VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.KEEP_ALPHA_KEYS, route_s)
	_frontage_fog.modulate.a = VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.SEAM_FOG_ALPHA_KEYS, route_s)
	_foreground_cliff_lip.modulate.a = VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.FOREGROUND_LIP_ALPHA_KEYS, route_s)


func _apply_camera_state(weight: float) -> void:
	if _camera == null:
		return
	if weight <= 0.001 or _cinematic_complete:
		if _camera_owned:
			_release_camera()
		return
	if not _camera_owned:
		if _camera.has_method("set_follow_target"):
			_camera.call("set_follow_target", _presentation_anchor)
		_camera_owned = true
		_set_ingress_presentation_visible(false)
	if _camera.has_method("set_presentation_bounds_override"):
		_camera.call(
			"set_presentation_bounds_override",
			_presentation_bounds
		)
	var zoom_value := float(_camera_state.get("camera_zoom_target", VISTA_CONTRACT.GAMEPLAY_ZOOM))
	var target_zoom := Vector2.ONE * zoom_value
	var target_offset := _camera_state.get("camera_offset_target", Vector2.ZERO) as Vector2
	if _camera.has_method("set_presentation_framing"):
		_camera.call(
			"set_presentation_framing",
			true,
			target_offset,
			target_zoom
		)


func _release_camera() -> void:
	_set_ingress_presentation_visible(true)
	if _camera == null or not is_instance_valid(_camera):
		_camera_owned = false
		return
	if _camera.has_method("clear_presentation_framing"):
		_camera.call("clear_presentation_framing", true)
	elif _operator != null and _camera.has_method("set_follow_target"):
		_camera.call("set_follow_target", _operator)
	if _camera.has_method("clear_presentation_bounds_override"):
		_camera.call("clear_presentation_bounds_override")
	_camera_owned = false


func _set_ingress_presentation_visible(is_visible: bool) -> void:
	if _map_instance != null \
			and is_instance_valid(_map_instance) \
			and _map_instance.has_method(
				"set_sundered_keep_vista_clutter_visible"
			):
		_map_instance.call(
			"set_sundered_keep_vista_clutter_visible",
			is_visible
		)
	if _ingress == null or not is_instance_valid(_ingress):
		return
	if _ingress.has_method("set_ingress_marker_visible"):
		_ingress.call("set_ingress_marker_visible", is_visible)
	else:
		_ingress.visible = is_visible


func _fit_presentation_to_viewport(
	viewport_size_override: Vector2 = Vector2.ZERO
) -> void:
	var viewport_size := viewport_size_override
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_viewport_coverage = Vector2(
		viewport_size.x / VISTA_CONTRACT.VISTA_APEX_ZOOM,
		viewport_size.y / VISTA_CONTRACT.VISTA_APEX_ZOOM
	) + VIEWPORT_SAFETY_MARGIN
	if _foreground_cliff_lip.texture != null:
		var visible_world_width := viewport_size.x / VISTA_CONTRACT.VISTA_APEX_ZOOM
		var required_lip_width := visible_world_width + 192.0
		var lip_texture_size := _foreground_cliff_lip.texture.get_size()
		_foreground_cliff_lip.scale = Vector2(
			maxf(1.0, required_lip_width / maxf(1.0, lip_texture_size.x)),
			0.80
		)
		var visible_world_height := viewport_size.y / VISTA_CONTRACT.VISTA_APEX_ZOOM
		_foreground_cliff_lip.global_position = Vector2(
			_vista_focus.x,
			_vista_focus.y + visible_world_height * 0.27 + lip_texture_size.y * 0.40
		).round()
	if _storm.texture != null:
		var required_coverage := _viewport_coverage
		if not _world_anchors.is_empty():
			var storm_center := _storm.global_position
			var subject_offset := Vector2(
				absf(_vista_focus.x - storm_center.x),
				absf(_vista_focus.y - storm_center.y)
			)
			required_coverage += subject_offset * 2.0
		var texture_size := _storm.texture.get_size()
		var cover_scale := maxf(
			required_coverage.x / maxf(1.0, texture_size.x),
			required_coverage.y / maxf(1.0, texture_size.y)
		)
		_storm.scale = Vector2.ONE * cover_scale


func _update_presentation_bounds() -> void:
	if _world_anchors.is_empty():
		return
	_presentation_bounds = Rect2(
		_world_anchors["frontage_entry"] as Vector2,
		Vector2.ONE
	)
	for world_position in _world_anchors.values():
		_presentation_bounds = _presentation_bounds.expand(
			world_position as Vector2
		)
	_presentation_bounds = _presentation_bounds.grow(
		maxf(_viewport_coverage.x, _viewport_coverage.y) * 0.6
	)


func _configure_exterior_clip() -> void:
	var floor_cells: Dictionary = _frontage.get("floor_cells", {})
	_playable_floor_bounds = Rect2()
	var first_floor := true
	var tile_size := _runtime_tile_size()
	for cell_variant in floor_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var center := _tile_to_world(cell_variant as Vector2i)
		var cell_rect := Rect2(center - tile_size * 0.5, tile_size)
		if first_floor:
			_playable_floor_bounds = cell_rect
			first_floor = false
		else:
			_playable_floor_bounds = _playable_floor_bounds.merge(cell_rect)
	_ocean_bounds = _cell_world_bounds(
		_frontage.get("ocean_cells", {}) as Dictionary,
		tile_size
	)
	var gate_center := _world_anchors.get("gate_threshold", Vector2.ZERO) as Vector2
	var outward: Vector2i = _frontage.get("fortress_outward_direction", Vector2i.UP)
	var map_origin := _tile_to_world(Vector2i.ZERO) - tile_size * 0.5
	var geographic_bounds := (
		_ocean_bounds if _ocean_bounds.has_area() else _playable_floor_bounds
	)
	var frontage_visual_bounds := geographic_bounds.grow(VISTA_HORIZONTAL_MARGIN)
	var exterior_top := map_origin.y - maxf(_viewport_coverage.y, 512.0)
	var exterior_bottom := gate_center.y - tile_size.y * 0.5 - 0.5
	if outward == Vector2i.UP:
		_vista_clip_bounds = Rect2(
			Vector2(frontage_visual_bounds.position.x, exterior_top),
			Vector2(frontage_visual_bounds.size.x, maxf(1.0, exterior_bottom - exterior_top))
		)
	else:
		# Current production frontage faces north. Other directions retain a
		# conservative exterior-only box until their authored mask exists.
		_vista_clip_bounds = Rect2(
			Vector2(frontage_visual_bounds.position.x, exterior_top),
			Vector2(frontage_visual_bounds.size.x, maxf(1.0, exterior_bottom - exterior_top))
		)
	var local_rect := Rect2(
		_exterior_clip.to_local(_vista_clip_bounds.position),
		_vista_clip_bounds.size
	)
	_exterior_clip.polygon = PackedVector2Array([
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0.0),
		local_rect.end,
		local_rect.position + Vector2(0.0, local_rect.size.y),
	])


func _cell_world_bounds(cells: Dictionary, tile_size: Vector2) -> Rect2:
	var bounds := Rect2()
	var first := true
	for cell_variant in cells.keys():
		if not cell_variant is Vector2i:
			continue
		var center := _tile_to_world(cell_variant as Vector2i)
		var cell_rect := Rect2(center - tile_size * 0.5, tile_size)
		if first:
			bounds = cell_rect
			first = false
		else:
			bounds = bounds.merge(cell_rect)
	return bounds


func _runtime_tile_size() -> Vector2:
	if _map_instance != null and _map_instance.has_method("get_runtime_tile_size"):
		return _map_instance.call("get_runtime_tile_size") as Vector2
	return Vector2(16.0, 16.0)


func _runtime_world_cell_size() -> float:
	return _tile_to_world(Vector2i.RIGHT).distance_to(_tile_to_world(Vector2i.ZERO))


func _configure_ocean_underlay_mask() -> void:
	var map_size: Vector2i = _level_data.get("map_size", Vector2i.ZERO)
	var ocean_cells: Dictionary = _frontage.get("ocean_cells", {})
	if map_size.x <= 0 or map_size.y <= 0 or ocean_cells.is_empty():
		_set_ocean_mask_enabled(false)
		return
	_ocean_mask_image = Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	_ocean_mask_image.fill(Color.TRANSPARENT)
	for cell_variant in ocean_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y:
			_ocean_mask_image.set_pixel(cell.x, cell.y, Color.WHITE)
	_ocean_mask_texture = ImageTexture.create_from_image(_ocean_mask_image)
	var material := _storm.material as ShaderMaterial
	if material == null:
		return
	var tile_size := _runtime_tile_size()
	material.set_shader_parameter("ocean_mask", _ocean_mask_texture)
	material.set_shader_parameter("mask_world_origin", _tile_to_world(Vector2i.ZERO) - tile_size * 0.5)
	material.set_shader_parameter("mask_world_size", Vector2(map_size) * tile_size)
	material.set_shader_parameter("mask_grid_size", Vector2(map_size))
	material.set_shader_parameter("mask_enabled", true)


func _set_ocean_mask_enabled(enabled: bool) -> void:
	var material := _storm.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("mask_enabled", enabled)


func _select_ocean_ruins_anchor() -> Vector2i:
	var ocean_cells: Dictionary = _frontage.get("ocean_cells", {})
	var floor_cells := _floor_cell_dictionary()
	var semantic: Dictionary = _frontage.get("camera_semantic_anchors", {})
	var apex: Vector2i = semantic.get("vista_apex", Vector2i.ZERO)
	var outward: Vector2i = _frontage.get("fortress_outward_direction", Vector2i.UP)
	var tangent_right := Vector2i(-outward.y, outward.x)
	var target := apex + outward * 9 - tangent_right * 10
	var best := Vector2i(-1, -1)
	var best_score := INF
	for cell_variant in ocean_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if floor_cells.has(cell):
			continue
		var floor_distance := _nearest_floor_distance(cell, floor_cells, 12)
		if floor_distance < 6:
			continue
		var score := cell.distance_squared_to(target) * 100.0 + absf(float(floor_distance - 9)) * 18.0
		var stable_before := cell.y < best.y or (cell.y == best.y and cell.x < best.x)
		if score < best_score or (is_equal_approx(score, best_score) and stable_before):
			best_score = score
			best = cell
	return best


func _floor_cell_dictionary() -> Dictionary:
	var result: Dictionary = (_frontage.get("floor_cells", {}) as Dictionary).duplicate()
	for cell_variant in _level_data.get("floor_cells", []):
		if cell_variant is Vector2i:
			result[cell_variant] = true
	return result


func _nearest_floor_distance(cell: Vector2i, floor_cells: Dictionary, limit: int) -> int:
	var best := limit + 1
	for floor_variant in floor_cells.keys():
		if not floor_variant is Vector2i:
			continue
		var floor_cell := floor_variant as Vector2i
		var distance := absi(cell.x - floor_cell.x) + absi(cell.y - floor_cell.y)
		best = mini(best, distance)
		if best <= 1:
			break
	return best


func get_ocean_mask_alpha(cell: Vector2i) -> float:
	if _ocean_mask_image == null or _ocean_mask_image.is_empty():
		return 0.0
	if cell.x < 0 or cell.y < 0 or cell.x >= _ocean_mask_image.get_width() or cell.y >= _ocean_mask_image.get_height():
		return 0.0
	return _ocean_mask_image.get_pixel(cell.x, cell.y).a


func _on_viewport_size_changed() -> void:
	if not is_node_ready():
		return
	_fit_presentation_to_viewport()
	if not _configured:
		return
	_configure_exterior_clip()
	_update_presentation_bounds()
	if _camera_owned and _camera != null \
			and _camera.has_method("set_presentation_bounds_override"):
		_camera.call(
			"set_presentation_bounds_override",
			_presentation_bounds
		)


func _tile_to_world(tile: Vector2i) -> Vector2:
	if _map_instance != null \
			and _map_instance.has_method("minimap_tile_to_global"):
		return _map_instance.call("minimap_tile_to_global", tile) as Vector2
	if _map_instance is ProcGenTilemap:
		var procgen_map := _map_instance as ProcGenTilemap
		if procgen_map.floor_tilemap != null:
			return procgen_map.floor_tilemap.to_global(
				procgen_map.floor_tilemap.map_to_local(tile)
			)
	var tile_size := Vector2(16.0, 16.0)
	if _map_instance != null \
			and _map_instance.has_method("get_runtime_tile_size"):
		tile_size = _map_instance.call("get_runtime_tile_size") as Vector2
	var origin := (
		(_map_instance as Node2D).global_position
		if _map_instance is Node2D
		else Vector2.ZERO
	)
	return origin + Vector2(tile) * tile_size


func _smootherstep_range(
	start: float,
	end: float,
	value: float
) -> float:
	if end <= start:
		return 1.0 if value >= end else 0.0
	var t := clampf((value - start) / (end - start), 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


func get_world_vista_debug_state() -> Dictionary:
	var state := _camera_state.duplicate(true)
	state.merge({
		"configured": _configured,
		"camera_owned": _camera_owned,
		"camera_weight": float(_camera_state.get("camera_weight", 0.0)),
		"route_s_cells": float(_camera_state.get("route_s_cells", 0.0)),
		"camera_zoom_target": float(_camera_state.get("camera_zoom_target", VISTA_CONTRACT.GAMEPLAY_ZOOM)),
		"camera_offset_target": _camera_state.get("camera_offset_target", Vector2.ZERO),
		"vista_focus": _vista_focus,
		"vista_focus_unclamped": _vista_focus,
		"vista_focus_bounded": _vista_focus_bounded,
		"camera_operator_distance": _operator.global_position.distance_to(_vista_focus_bounded) if _operator != null else 0.0,
		"camera_displacement_limit": _runtime_world_cell_size() * VISTA_CONTRACT.MAX_CAMERA_DISPLACEMENT_CELLS,
		"ruins_alpha": _ocean_ruins.modulate.a,
		"keep_alpha": _fortress.modulate.a,
		"seam_fog_alpha": _frontage_fog.modulate.a,
		"foreground_cliff_alpha": _foreground_cliff_lip.modulate.a,
		"foreground_cliff_position": _foreground_cliff_lip.global_position,
		"foreground_cliff_scale": _foreground_cliff_lip.scale,
		"moonlight_triggered": _moonlight_played,
		"cinematic_complete": _cinematic_complete,
		"cinematic_route_arc_total": float(_frontage.get("cinematic_route_arc_total", 0.0)),
		"distance_to_gate_cells": VISTA_CONTRACT.S_GATE - float(_camera_state.get("route_s_cells", 0.0)),
		"presentation_bounds": _presentation_bounds,
		"viewport_coverage": _viewport_coverage,
		"vista_clip_bounds": _vista_clip_bounds,
		"playable_floor_bounds": _playable_floor_bounds,
		"ocean_bounds": _ocean_bounds,
		"ocean_cell_count": (
			_frontage.get("ocean_cells", {}) as Dictionary
		).size(),
		"ocean_mask_configured": _ocean_mask_texture != null,
		"ocean_ruins_anchor_cell": _ocean_ruins_anchor_cell,
		"vista_root_z_index": _vista_root.z_index,
		"semantic_anchors": _world_anchors.duplicate(true),
		"frontage": _frontage.duplicate(true),
		"operator": _operator,
		"camera": _camera,
		"ingress": _ingress,
		"map_instance": _map_instance,
	}, true)
	return state
