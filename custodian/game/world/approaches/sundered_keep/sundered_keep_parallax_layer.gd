extends Node2D
class_name SunderedKeepParallaxLayer

@export var camera_path := NodePath(
	"/root/GameRoot/World/Camera2D"
)

@export var follow_ratio := Vector2(
	0.12,
	0.04
)

@export var drift_amplitude := Vector2.ZERO
@export var drift_speed := 0.0

var _camera: Camera2D
var _origin := Vector2.ZERO
var _camera_origin := Vector2.ZERO
var _elapsed := 0.0


func _ready() -> void:
	add_to_group("sundered_keep_parallax_layer")
	_origin = position
	_resolve_camera()
	rebase()


func _process(delta: float) -> void:
	_elapsed += maxf(delta, 0.0)

	if _camera == null or not is_instance_valid(_camera):
		_resolve_camera()

	if _camera == null:
		return

	var camera_delta := _camera.global_position - _camera_origin
	var drift := Vector2(
		sin(_elapsed * drift_speed),
		cos(_elapsed * drift_speed * 0.73)
	) * drift_amplitude

	position = _origin + Vector2(
		camera_delta.x * follow_ratio.x,
		camera_delta.y * follow_ratio.y
	) + drift


func rebase() -> void:
	_origin = position

	if _camera != null:
		_camera_origin = _camera.global_position


func _resolve_camera() -> void:
	_camera = get_node_or_null(camera_path) as Camera2D
