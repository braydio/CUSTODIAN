extends Node2D
class_name SunderedKeepWorldVista

const GAMEPLAY_ZOOM := Vector2(0.90, 0.90)
const CINEMATIC_ZOOM := Vector2(0.78, 0.78)
const GAMEPLAY_OFFSET := Vector2.ZERO
const CINEMATIC_OFFSET := Vector2(0.0, -120.0)
const DEFAULT_MAP_SIZE := Vector2i(96, 96)
const DEFAULT_TILE_SIZE := Vector2(16.0, 16.0)
const PRESENTATION_COVERAGE := Vector2(2800.0, 1640.0)
const PRESENTATION_WIDTH_SAFETY_MARGIN := 192.0
const MINIMUM_STORM_REGION_SIZE := Vector2(2600.0, 1200.0)
const MINIMUM_CLIFF_LIP_SCALE_X := 1.25

@export var operator_path := NodePath("/root/GameRoot/World/Operator")
@export var camera_path := NodePath("/root/GameRoot/World/Camera2D")

@onready var _horizon_presentation := $HorizonPresentation as Node2D
@onready var _storm_horizon := (
		$HorizonPresentation/StormParallax/StormHorizon as Sprite2D
)
@onready var _distant_keep := (
		$HorizonPresentation/KeepParallax/DistantKeep as Sprite2D
)
@onready var _fog_veil := (
		$HorizonPresentation/FogParallax/FogVeil as Sprite2D
)
@onready var _foreground_cliff_lip := $ForegroundCliffLip as Sprite2D
@onready var _presentation_anchor := (
		$CameraPresentationAnchor as Marker2D
)
@onready var _influence_start := $CameraInfluenceStart as Marker2D
@onready var _camera_apex := $CameraApex as Marker2D
@onready var _return_start := $CameraReturnStart as Marker2D
@onready var _return_complete := $CameraReturnComplete as Marker2D

var _ingress: Node2D
var _map_instance: Node
var _level_data: Dictionary = {}
var _operator: Node2D
var _camera: Camera2D
var _configured := false
var _camera_owned := false
var _outward_direction := Vector2.UP
var _camera_weight := 0.0
var _enter_progress := 0.0
var _return_progress := 0.0
var _presentation_bounds := Rect2()
var _fitted_visible_world_size := Vector2.ZERO
var _fitted_safety_width := 0.0


func _ready() -> void:
	add_to_group("sundered_keep_world_vista")
	_horizon_presentation.modulate.a = 0.0
	_storm_horizon.modulate.a = 1.0
	_distant_keep.modulate.a = 0.08
	_fog_veil.modulate.a = 0.68
	var viewport := get_viewport()
	if (
		viewport != null
		and not viewport.size_changed.is_connected(
			_on_viewport_size_changed
		)
	):
		viewport.size_changed.connect(
			_on_viewport_size_changed
		)
	_resolve_runtime_nodes()
	if _ingress != null:
		_layout_from_ingress()


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
	_resolve_runtime_nodes()
	if is_node_ready() and _ingress != null:
		_layout_from_ingress()


func _process(_delta: float) -> void:
	if not _configured:
		return
	_resolve_runtime_nodes()
	if _operator == null:
		_release_camera()
		return
	_evaluate_envelope()


func _resolve_runtime_nodes() -> void:
	if _operator == null or not is_instance_valid(_operator):
		_operator = get_node_or_null(operator_path) as Node2D
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_node_or_null(camera_path) as Camera2D


func _layout_from_ingress() -> void:
	var map_size := _level_data.get(
		"map_size",
		DEFAULT_MAP_SIZE
	) as Vector2i
	if map_size.x <= 0 or map_size.y <= 0:
		map_size = DEFAULT_MAP_SIZE
	var ingress_tile := _global_to_tile(_ingress.global_position)
	var authored_direction: Variant = _ingress.get_meta(
		"world_ingress_outward_direction",
		Vector2i.ZERO
	)
	if (
		authored_direction is Vector2i
		and authored_direction != Vector2i.ZERO
	):
		_outward_direction = Vector2(authored_direction as Vector2i)
	else:
		_outward_direction = Vector2(
			_nearest_boundary_direction(ingress_tile, map_size)
		)
	var tile_size := _runtime_tile_size()
	var step_px := maxf(
		16.0,
		maxf(tile_size.x, tile_size.y)
	)
	var ingress_position := _ingress.global_position
	_influence_start.global_position = (
		ingress_position - _outward_direction * step_px * 8.0
	)
	_camera_apex.global_position = (
		ingress_position - _outward_direction * step_px * 5.0
	)
	_return_start.global_position = (
		ingress_position - _outward_direction * step_px * 3.0
	)
	_return_complete.global_position = (
		ingress_position - _outward_direction * step_px
	)

	var outward_focus_distance := maxf(240.0, step_px * 8.0)
	_presentation_anchor.global_position = (
		_camera_apex.global_position
		+ _outward_direction * outward_focus_distance
		- Vector2(0.0, 180.0)
	)
	_horizon_presentation.global_position = (
		_presentation_anchor.global_position
	)
	_foreground_cliff_lip.global_position = (
		ingress_position - _outward_direction * step_px * 1.5
	)
	_foreground_cliff_lip.rotation = (
		_outward_direction.angle() + PI * 0.5
	)
	_foreground_cliff_lip.flip_v = _outward_direction.y > 0.5

	_fit_presentation_to_viewport()
	_update_presentation_bounds()
	_configured = true
	if _operator != null:
		_evaluate_envelope()


func _fit_presentation_to_viewport(
	viewport_size_override: Vector2 = Vector2.ZERO
) -> void:
	var viewport_size := viewport_size_override
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_fitted_visible_world_size = Vector2(
		viewport_size.x / maxf(CINEMATIC_ZOOM.x, 0.001),
		viewport_size.y / maxf(CINEMATIC_ZOOM.y, 0.001)
	)
	_fitted_safety_width = (
		_fitted_visible_world_size.x
		+ PRESENTATION_WIDTH_SAFETY_MARGIN
	)
	if _foreground_cliff_lip.texture != null:
		var texture_width := float(
			_foreground_cliff_lip.texture.get_width()
		)
		_foreground_cliff_lip.scale.x = maxf(
			MINIMUM_CLIFF_LIP_SCALE_X,
			_fitted_safety_width
				/ maxf(texture_width, 1.0)
		)
	var region := _storm_horizon.region_rect
	region.size.x = maxf(
		MINIMUM_STORM_REGION_SIZE.x,
		_fitted_safety_width
	)
	region.size.y = maxf(
		MINIMUM_STORM_REGION_SIZE.y,
		region.size.y
	)
	_storm_horizon.region_rect = region


func _update_presentation_bounds() -> void:
	var fitted_coverage := Vector2(
		maxf(
			PRESENTATION_COVERAGE.x,
			_fitted_safety_width
		),
		maxf(
			PRESENTATION_COVERAGE.y,
			_fitted_visible_world_size.y
				+ PRESENTATION_WIDTH_SAFETY_MARGIN
		)
	)
	_presentation_bounds = Rect2(
		_presentation_anchor.global_position
			- fitted_coverage * 0.5,
		fitted_coverage
	).grow(256.0)
	for marker: Marker2D in [
		_influence_start,
		_camera_apex,
		_return_start,
		_return_complete,
	]:
		_presentation_bounds = _presentation_bounds.expand(
			marker.global_position
		)


func _on_viewport_size_changed() -> void:
	if not is_node_ready():
		return
	_fit_presentation_to_viewport()
	if not _configured:
		return
	_update_presentation_bounds()
	if (
		_camera_owned
		and _camera != null
		and _camera.has_method(
			"set_presentation_bounds_override"
		)
	):
		_camera.call(
			"set_presentation_bounds_override",
			_presentation_bounds
		)


func _evaluate_envelope() -> void:
	_enter_progress = _segment_progress(
		_operator.global_position,
		_influence_start.global_position,
		_camera_apex.global_position
	)
	_return_progress = _segment_progress(
		_operator.global_position,
		_return_start.global_position,
		_return_complete.global_position
	)
	var enter_weight := _smootherstep(_enter_progress)
	var return_weight := _smootherstep(_return_progress)
	_camera_weight = enter_weight * (1.0 - return_weight)
	_presentation_anchor.global_position = (
		_operator.global_position.lerp(
			_presentation_anchor_rest_position(),
			_camera_weight
		)
	)
	_apply_visual_weight(_camera_weight)
	_apply_camera_weight(_camera_weight)


func _presentation_anchor_rest_position() -> Vector2:
	var outward_focus_distance := maxf(
		240.0,
		maxf(_runtime_tile_size().x, _runtime_tile_size().y) * 8.0
	)
	return (
		_camera_apex.global_position
		+ _outward_direction * outward_focus_distance
		- Vector2(0.0, 180.0)
	)


func _apply_visual_weight(weight: float) -> void:
	var reveal := _smootherstep_range(0.02, 0.72, weight)
	var keep_reveal := _smootherstep_range(0.14, 0.88, weight)
	_horizon_presentation.modulate.a = reveal
	_storm_horizon.modulate.a = 1.0
	_distant_keep.modulate.a = lerpf(0.08, 0.92, keep_reveal)
	_fog_veil.modulate.a = lerpf(0.68, 0.26, reveal)
	_fog_veil.position = Vector2.ZERO.lerp(
		Vector2(-110.0, 50.0),
		reveal
	)


func _apply_camera_weight(weight: float) -> void:
	if _camera == null:
		return
	var active := weight > 0.001
	if active:
		if not _camera_owned and _camera.has_method("set_follow_target"):
			_camera.call("set_follow_target", _presentation_anchor)
			_camera_owned = true
		if _camera.has_method("set_presentation_bounds_override"):
			_camera.call(
				"set_presentation_bounds_override",
				_presentation_bounds
			)
		if _camera.has_method("set_presentation_framing"):
			_camera.call(
				"set_presentation_framing",
				true,
				GAMEPLAY_OFFSET.lerp(CINEMATIC_OFFSET, weight),
				GAMEPLAY_ZOOM.lerp(CINEMATIC_ZOOM, weight)
			)
	elif _camera_owned:
		_release_camera()


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


func _global_to_tile(point: Vector2) -> Vector2i:
	if (
		_map_instance != null
		and _map_instance.has_method("global_to_minimap_tile")
	):
		return _map_instance.call(
			"global_to_minimap_tile",
			point
		) as Vector2i
	var tile_size := _runtime_tile_size()
	var map_origin := (
		(_map_instance as Node2D).global_position
		if _map_instance is Node2D
		else Vector2.ZERO
	)
	return Vector2i(
		floori((point.x - map_origin.x) / maxf(1.0, tile_size.x)),
		floori((point.y - map_origin.y) / maxf(1.0, tile_size.y))
	)


func _runtime_tile_size() -> Vector2:
	if (
		_map_instance != null
		and _map_instance.has_method("get_runtime_tile_size")
	):
		var value: Variant = _map_instance.call("get_runtime_tile_size")
		if value is Vector2:
			return value as Vector2
	return DEFAULT_TILE_SIZE


func _nearest_boundary_direction(
	tile: Vector2i,
	map_size: Vector2i
) -> Vector2i:
	var distances := [
		tile.x,
		(map_size.x - 1) - tile.x,
		tile.y,
		(map_size.y - 1) - tile.y,
	]
	var best_index := 0
	for index in range(1, distances.size()):
		if int(distances[index]) < int(distances[best_index]):
			best_index = index
	match best_index:
		0:
			return Vector2i.LEFT
		1:
			return Vector2i.RIGHT
		2:
			return Vector2i.UP
		_:
			return Vector2i.DOWN


func _segment_progress(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return 0.0
	return clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)


func _smootherstep(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


func _smootherstep_range(start: float, end: float, value: float) -> float:
	if end <= start:
		return 1.0 if value >= end else 0.0
	return _smootherstep((value - start) / (end - start))


func get_world_vista_debug_state() -> Dictionary:
	return {
		"configured": _configured,
		"camera_owned": _camera_owned,
		"camera_weight": _camera_weight,
		"enter_progress": _enter_progress,
		"return_progress": _return_progress,
		"outward_direction": _outward_direction,
		"presentation_bounds": _presentation_bounds,
		"fitted_visible_world_size": _fitted_visible_world_size,
		"fitted_safety_width": _fitted_safety_width,
		"cliff_lip_world_width": (
			float(_foreground_cliff_lip.texture.get_width())
				* _foreground_cliff_lip.scale.x
			if _foreground_cliff_lip.texture != null
			else 0.0
		),
		"storm_region_size": _storm_horizon.region_rect.size,
		"operator": _operator,
		"camera": _camera,
		"ingress": _ingress,
		"map_instance": _map_instance,
	}
