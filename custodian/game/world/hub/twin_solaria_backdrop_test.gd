extends Node2D
class_name TwinSolariaBackdropTest

const EXPECTED_MAP_SIZE := Vector2(3500.0, 3000.0)

@onready var background: Sprite2D = $World/TwinSolariaBackdrop/Background
@onready var operator_ref: Node2D = $World/Operator
@onready var camera: Camera2D = $World/Camera2D

var map_bounds := Rect2()


func _ready() -> void:
	if background.texture == null:
		push_error("TwinSolariaBackdropTest: development background texture is missing")
		return
	var texture_size := Vector2(background.texture.get_size())
	map_bounds = Rect2(-texture_size * 0.5, texture_size)
	if texture_size != EXPECTED_MAP_SIZE:
		push_warning(
			"TwinSolariaBackdropTest: expected %s background, received %s"
			% [EXPECTED_MAP_SIZE, texture_size]
		)
	call_deferred("_apply_camera_bounds")


func _apply_camera_bounds() -> void:
	if camera == null:
		return
	if camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", self)
	else:
		camera.set("map_bounds", map_bounds)
	if camera.has_method("set_follow_target"):
		camera.call("set_follow_target", operator_ref)


func get_camera_bounds() -> Rect2:
	return map_bounds


func get_test_snapshot() -> Dictionary:
	return {
		"map_bounds": map_bounds,
		"map_size": map_bounds.size,
		"operator_position": operator_ref.global_position if operator_ref != null else Vector2.ZERO,
		"development_backdrop": true,
	}
