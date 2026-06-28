extends Node
class_name OverlookCameraDirector

enum ViewState {
	MAINLAND_TOPDOWN,
	HILL_REVEAL,
	OVERLOOK_VISTA,
	LATERAL_TRAVERSE,
	RETURN_TOPDOWN,
}

@export_category("Required")
@export var player: Node2D
@export var camera: Camera2D

@export var reveal_start_marker: Node2D
@export var reveal_full_marker: Node2D
@export var traverse_start_marker: Node2D
@export var traverse_end_marker: Node2D
@export var return_topdown_marker: Node2D

@export var vista_root: CanvasItem
@export var occlusion_root: CanvasItem
@export var fog_band: CanvasItem

@export_category("Camera")
@export var normal_offset := Vector2.ZERO
@export var reveal_offset := Vector2(0.0, -140.0)
@export var traverse_offset := Vector2(0.0, -48.0)

@export var normal_zoom := Vector2(1.0, 1.0)
@export var reveal_zoom := Vector2(0.86, 0.86)
@export var traverse_zoom := Vector2(0.96, 0.96)

@export_range(0.1, 20.0, 0.1) var smoothing_speed := 5.0

var state: ViewState = ViewState.MAINLAND_TOPDOWN
var _reveal_t := 0.0
var _camera_offset := Vector2.ZERO
var _camera_zoom := Vector2.ONE


func _ready() -> void:
	_camera_offset = normal_offset
	_camera_zoom = normal_zoom

	if vista_root:
		vista_root.modulate.a = 0.0

	if occlusion_root:
		occlusion_root.modulate.a = 0.0

	if fog_band:
		fog_band.modulate.a = 0.35


func _process(delta: float) -> void:
	if not _is_ready():
		return

	state = _get_state_from_player_position()

	var target_reveal := _get_target_reveal()
	var lerp_weight := 1.0 - exp(-smoothing_speed * delta)

	_reveal_t = lerp(_reveal_t, target_reveal, lerp_weight)

	var target_offset := _get_target_camera_offset()
	var target_zoom := _get_target_camera_zoom()

	_camera_offset = _camera_offset.lerp(target_offset, lerp_weight)
	_camera_zoom = _camera_zoom.lerp(target_zoom, lerp_weight)

	camera.offset = _camera_offset
	camera.zoom = _camera_zoom

	_apply_visuals(_reveal_t, lerp_weight)


func _is_ready() -> bool:
	return (
		player != null
		and camera != null
		and reveal_start_marker != null
		and reveal_full_marker != null
		and traverse_start_marker != null
		and traverse_end_marker != null
		and return_topdown_marker != null
	)


func _get_state_from_player_position() -> ViewState:
	var p := player.global_position

	# Assumption: this approach flows upward/north first, then laterally east.
	# In Godot 2D, lower Y is north/up.
	if p.x >= return_topdown_marker.global_position.x:
		return ViewState.RETURN_TOPDOWN

	if p.x >= traverse_start_marker.global_position.x and p.x < traverse_end_marker.global_position.x:
		return ViewState.LATERAL_TRAVERSE

	if p.y > reveal_start_marker.global_position.y:
		return ViewState.MAINLAND_TOPDOWN

	if p.y <= reveal_start_marker.global_position.y and p.y > reveal_full_marker.global_position.y:
		return ViewState.HILL_REVEAL

	if p.y <= reveal_full_marker.global_position.y and p.x < traverse_start_marker.global_position.x:
		return ViewState.OVERLOOK_VISTA

	return state


func _get_target_reveal() -> float:
	match state:
		ViewState.MAINLAND_TOPDOWN:
			return 0.0
		ViewState.HILL_REVEAL:
			return _progress_between_markers(player.global_position, reveal_start_marker.global_position, reveal_full_marker.global_position)
		ViewState.OVERLOOK_VISTA:
			return 1.0
		ViewState.LATERAL_TRAVERSE:
			return 0.35
		ViewState.RETURN_TOPDOWN:
			return 0.0

	return 0.0


func _get_target_camera_offset() -> Vector2:
	match state:
		ViewState.MAINLAND_TOPDOWN:
			return normal_offset
		ViewState.HILL_REVEAL:
			return normal_offset.lerp(reveal_offset, _reveal_t)
		ViewState.OVERLOOK_VISTA:
			return reveal_offset
		ViewState.LATERAL_TRAVERSE:
			return traverse_offset
		ViewState.RETURN_TOPDOWN:
			return normal_offset

	return normal_offset


func _get_target_camera_zoom() -> Vector2:
	match state:
		ViewState.MAINLAND_TOPDOWN:
			return normal_zoom
		ViewState.HILL_REVEAL:
			return normal_zoom.lerp(reveal_zoom, _reveal_t)
		ViewState.OVERLOOK_VISTA:
			return reveal_zoom
		ViewState.LATERAL_TRAVERSE:
			return traverse_zoom
		ViewState.RETURN_TOPDOWN:
			return normal_zoom

	return normal_zoom


func _apply_visuals(t: float, _lerp_weight: float) -> void:
	# Vista fades in as the hilltop is reached.
	if vista_root:
		vista_root.modulate.a = smoothstep(0.15, 1.0, t)

	# Occluders rise during lateral traverse so the vista disappears behind cliffs/walls.
	if occlusion_root:
		var occlusion_alpha := 0.0
		if state == ViewState.LATERAL_TRAVERSE:
			occlusion_alpha = 0.85
		elif state == ViewState.RETURN_TOPDOWN:
			occlusion_alpha = 1.0
		occlusion_root.modulate.a = lerp(occlusion_root.modulate.a, occlusion_alpha, 0.08)

	# Fog hides the perspective seam.
	if fog_band:
		var fog_alpha: float = lerp(0.35, 0.9, t)
		if state == ViewState.LATERAL_TRAVERSE:
			fog_alpha = 0.7
		if state == ViewState.RETURN_TOPDOWN:
			fog_alpha = 0.45
		fog_band.modulate.a = fog_alpha


func _progress_between_markers(pos: Vector2, start: Vector2, end: Vector2) -> float:
	var path := end - start
	var len_sq := path.length_squared()

	if len_sq <= 0.001:
		return 0.0

	var projected := (pos - start).dot(path) / len_sq
	return clamp(projected, 0.0, 1.0)
