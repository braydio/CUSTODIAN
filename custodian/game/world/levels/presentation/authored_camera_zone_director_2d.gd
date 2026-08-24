extends Node
class_name AuthoredCameraZoneDirector2D

const SUBJECT_SAFE_INSET := Vector4(0.06, 0.10, 0.06, 0.16)

@export var subject_path: NodePath
@export var camera_path: NodePath

var _active_zone: AuthoredCameraZone2D = null
var _subject: Node2D = null
var _camera: Camera2D = null


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	_resolve_runtime_nodes()
	if _subject == null or _camera == null:
		return
	var selected := _select_zone(_subject.global_position)
	if selected == _active_zone:
		return
	_active_zone = selected
	_apply_active_zone()


func refresh_now() -> void:
	_active_zone = null
	_process(0.0)


func get_active_profile_id() -> StringName:
	return _active_zone.profile_id if _active_zone != null else &""


func _resolve_runtime_nodes() -> void:
	if _subject == null or not is_instance_valid(_subject):
		_subject = get_node_or_null(subject_path) as Node2D
		if _subject == null and get_tree() != null:
			_subject = get_tree().get_first_node_in_group("player") as Node2D
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_node_or_null(camera_path) as Camera2D
		if _camera == null and get_viewport() != null:
			_camera = get_viewport().get_camera_2d()


func _select_zone(point: Vector2) -> AuthoredCameraZone2D:
	var selected: AuthoredCameraZone2D = null
	for child in get_children():
		var zone := child as AuthoredCameraZone2D
		if zone == null or not zone.contains_global_point(point):
			continue
		if selected == null or zone.priority > selected.priority:
			selected = zone
	return selected


func _apply_active_zone() -> void:
	if _camera == null:
		return
	if _active_zone == null or _active_zone.release_to_gameplay:
		if _camera.has_method("clear_presentation_framing"):
			_camera.call("clear_presentation_framing", true)
		return
	if _camera.has_method("set_presentation_subject_constraint"):
		_camera.call("set_presentation_subject_constraint", _subject, SUBJECT_SAFE_INSET)
	if _camera.has_method("set_presentation_framing_transition"):
		_camera.call(
			"set_presentation_framing_transition",
			_active_zone.framing_offset,
			_active_zone.framing_zoom,
			_active_zone.transition_sec
		)
	elif _camera.has_method("set_presentation_framing"):
		_camera.call(
			"set_presentation_framing",
			true,
			_active_zone.framing_offset,
			_active_zone.framing_zoom
		)
