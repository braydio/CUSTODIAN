extends Node2D
class_name SunderedKeepProcgenVistaPresentation

const CAMERA_DIRECTOR := preload(
	"res://game/world/procgen/landmarks/sundered_keep/"
	+ "sundered_keep_frontage_camera_director.gd"
)

const GAMEPLAY_ZOOM := Vector2(0.90, 0.90)
const FIRST_REVEAL_ZOOM := Vector2(0.78, 0.78)
const FIRST_REVEAL_OFFSET := Vector2(0.0, -120.0)
const VIEWPORT_SAFETY_MARGIN := Vector2(256.0, 224.0)

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
@onready var _distant_keep := (
	$VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/DistantKeep as Sprite2D
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
@onready var _gate_shadow := (
	$VistaPresentationRoot/ExteriorVistaClip/GateShadow as Sprite2D
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


func _ready() -> void:
	add_to_group("sundered_keep_world_vista")
	_director = CAMERA_DIRECTOR.new()
	_horizon.modulate.a = 0.0
	_fortress.modulate.a = 0.0
	_gate_shadow.modulate.a = 0.0
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


func _process(_delta: float) -> void:
	if not _configured:
		return
	_resolve_runtime_nodes()
	if _operator == null:
		_release_camera()
		return
	_evaluate_camera()


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
	_fortress.global_position = fortress_anchor
	var wall_anchor: Variant = visual.get("wall_run_anchor")
	if wall_anchor is Vector2i:
		_fortress.get_node("OuterWall").global_position = (
			_tile_to_world(wall_anchor as Vector2i)
			+ Vector2(0.0, -80.0)
		)
	var tower_anchor: Variant = visual.get("tower_anchor_a")
	if tower_anchor is Vector2i:
		_fortress.get_node("CentralCitadel").global_position = (
			_tile_to_world(tower_anchor as Vector2i)
			+ Vector2(120.0, -150.0)
		)
	_gate_shadow.global_position = _world_anchors["gate_threshold"]
	_fit_presentation_to_viewport()
	_configure_exterior_clip()
	_update_presentation_bounds()
	_configured = true
	if _operator != null:
		_evaluate_camera()


func _assign_marker(name: String, world_position: Vector2) -> void:
	var marker := get_node_or_null(name) as Marker2D
	if marker != null:
		marker.global_position = world_position


func _evaluate_camera() -> void:
	_camera_state = _director.call(
		"evaluate",
		_operator.global_position,
		_world_anchors
	) as Dictionary
	var first_weight := float(_camera_state.get("first_weight", 0.0))
	var frontage_weight := float(
		_camera_state.get("frontage_weight", 0.0)
	)
	var camera_weight := first_weight
	var focus := _operator.global_position + Vector2(0.0, -220.0)
	_presentation_anchor.global_position = _operator.global_position.lerp(
		focus,
		camera_weight * 0.68
	)
	_apply_visual_state(first_weight, frontage_weight)
	_apply_camera_state(first_weight, frontage_weight)


func _apply_visual_state(
	first_weight: float,
	frontage_weight: float
) -> void:
	var first_visual := float(
		_camera_state.get("first_enter_progress", first_weight)
	)
	var frontage_visual := float(
		_camera_state.get(
			"frontage_enter_progress",
			frontage_weight
		)
	)
	_horizon.modulate.a = _smootherstep_range(
		0.02,
		0.72,
		maxf(first_visual, frontage_visual)
	)
	_storm.modulate.a = 1.0
	_distant_keep.modulate.a = lerpf(
		0.08,
		0.94,
		_smootherstep_range(
			0.12,
			0.86,
			maxf(first_visual, frontage_visual)
		)
	)
	_reveal_fog.modulate.a = lerpf(0.68, 0.24, first_visual)
	_reveal_fog.position = Vector2.ZERO.lerp(
		Vector2(-110.0, 50.0),
		first_visual
	)
	_fortress.modulate.a = _smootherstep_range(
		0.08,
		0.78,
		frontage_visual
	)
	_frontage_fog.modulate.a = lerpf(0.72, 0.30, frontage_visual)
	var gate_progress := float(
		_camera_state.get("frontage_return_progress", 0.0)
	)
	_gate_shadow.modulate.a = _smootherstep_range(
		0.55,
		1.0,
		gate_progress
	)


func _apply_camera_state(
	first_weight: float,
	frontage_weight: float
) -> void:
	if _camera == null:
		return
	var weight := first_weight
	if weight <= 0.001:
		if _camera_owned:
			_release_camera()
		return
	if not _camera_owned and _camera.has_method("set_follow_target"):
		_camera.call("set_follow_target", _presentation_anchor)
		_camera_owned = true
	if _camera.has_method("set_presentation_bounds_override"):
		_camera.call(
			"set_presentation_bounds_override",
			_presentation_bounds
		)
	var target_zoom := GAMEPLAY_ZOOM.lerp(
		FIRST_REVEAL_ZOOM,
		first_weight
	)
	var target_offset := FIRST_REVEAL_OFFSET * first_weight
	if _camera.has_method("set_presentation_framing"):
		_camera.call(
			"set_presentation_framing",
			true,
			target_offset,
			target_zoom
		)


func _release_camera() -> void:
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


func _fit_presentation_to_viewport(
	viewport_size_override: Vector2 = Vector2.ZERO
) -> void:
	var viewport_size := viewport_size_override
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_viewport_coverage = Vector2(
		viewport_size.x / FIRST_REVEAL_ZOOM.x,
		viewport_size.y / FIRST_REVEAL_ZOOM.y
	) + VIEWPORT_SAFETY_MARGIN
	if _storm.texture != null:
		var texture_size := _storm.texture.get_size()
		var cover_scale := maxf(
			_viewport_coverage.x / maxf(1.0, texture_size.x),
			_viewport_coverage.y / maxf(1.0, texture_size.y)
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
	var gate_center := _world_anchors.get("gate_threshold", Vector2.ZERO) as Vector2
	var outward: Vector2i = _frontage.get("fortress_outward_direction", Vector2i.UP)
	var map_size: Vector2i = _level_data.get("map_size", Vector2i(176, 176))
	var map_origin := _tile_to_world(Vector2i.ZERO) - tile_size * 0.5
	var margin := maxf(_viewport_coverage.x, _viewport_coverage.y)
	if outward == Vector2i.UP:
		_vista_clip_bounds = Rect2(
			Vector2(map_origin.x - margin, map_origin.y - margin),
			Vector2(float(map_size.x) * tile_size.x + margin * 2.0, maxf(1.0, gate_center.y - tile_size.y * 0.5 - 0.5 - (map_origin.y - margin)))
		)
	else:
		# Current production frontage faces north. Other directions retain a
		# conservative exterior-only box until their authored mask exists.
		_vista_clip_bounds = Rect2(
			Vector2(map_origin.x - margin, map_origin.y - margin),
			Vector2(float(map_size.x) * tile_size.x + margin * 2.0, maxf(1.0, gate_center.y - tile_size.y * 0.5 - 0.5 - (map_origin.y - margin)))
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


func _runtime_tile_size() -> Vector2:
	if _map_instance != null and _map_instance.has_method("get_runtime_tile_size"):
		return _map_instance.call("get_runtime_tile_size") as Vector2
	return Vector2(16.0, 16.0)


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
		"presentation_bounds": _presentation_bounds,
		"viewport_coverage": _viewport_coverage,
		"vista_clip_bounds": _vista_clip_bounds,
		"playable_floor_bounds": _playable_floor_bounds,
		"vista_root_z_index": _vista_root.z_index,
		"semantic_anchors": _world_anchors.duplicate(true),
		"frontage": _frontage.duplicate(true),
		"operator": _operator,
		"camera": _camera,
		"ingress": _ingress,
		"map_instance": _map_instance,
	}, true)
	return state
