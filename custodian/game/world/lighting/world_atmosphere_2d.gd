extends CanvasLayer
class_name WorldAtmosphere2D

@export var camera_path: NodePath = NodePath("../World/Camera2D")
@export var lighting_director_path: NodePath = NodePath("../World/WorldLightingDirector")

@onready var post_process: ColorRect = $PostProcess

var _material: ShaderMaterial = null
var _camera: Camera2D = null
var _director: WorldLightingDirector = null
var _missing_nodes_reported: bool = false


func _ready() -> void:
	if post_process != null and post_process.material is ShaderMaterial:
		_material = (post_process.material as ShaderMaterial).duplicate(true) as ShaderMaterial
		post_process.material = _material
	else:
		_report_warning("World atmosphere PostProcess is missing its ShaderMaterial.", {})
	_resolve_runtime_nodes()
	_update_shader_parameters()


func _process(_delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera) \
			or _director == null or not is_instance_valid(_director):
		_resolve_runtime_nodes()
	_update_shader_parameters()


func get_atmosphere_material() -> ShaderMaterial:
	return _material


func _resolve_runtime_nodes() -> void:
	_camera = get_node_or_null(camera_path) as Camera2D
	_director = get_node_or_null(lighting_director_path) as WorldLightingDirector
	if not _missing_nodes_reported and (_camera == null or _director == null):
		_missing_nodes_reported = true
		_report_warning("World atmosphere could not resolve its live camera or lighting director.", {
			"camera_path": str(camera_path),
			"lighting_director_path": str(lighting_director_path),
		})


func _update_shader_parameters() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("viewport_size", get_viewport().get_visible_rect().size)
	if _camera != null:
		_material.set_shader_parameter("camera_world_position", _camera.get_screen_center_position())
		_material.set_shader_parameter("camera_zoom", _camera.zoom)
	if _director == null:
		return
	_material.set_shader_parameter("fog_alpha", _director.fog_alpha)
	_material.set_shader_parameter("cosmic_alpha", _director.cosmic_underlay_alpha)
	var profile := _director.active_profile
	if profile == null:
		return
	var fog_color := profile.ambient_color.lerp(profile.directional_color, 0.18)
	var grade_tint := Color(
		lerpf(1.0, profile.directional_color.r, 0.22),
		lerpf(1.0, profile.directional_color.g, 0.22),
		lerpf(1.0, profile.directional_color.b, 0.22),
		1.0
	)
	_material.set_shader_parameter("fog_color", fog_color)
	_material.set_shader_parameter("grade_tint", grade_tint)


func _report_warning(message: String, data: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("mark_warning"):
		observatory.call("mark_warning", message, data)
	else:
		push_warning(message)
