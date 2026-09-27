extends Node2D
class_name TwinSolariaV1

@onready var fidelity_underlay: Sprite2D = $FidelityUnderlay

var map_bounds := Rect2()


func _ready() -> void:
	if fidelity_underlay.texture == null:
		push_error("TwinSolariaV1: fidelity underlay texture is missing")
		return
	var master_size := Vector2(fidelity_underlay.texture.get_size())
	map_bounds = Rect2(-master_size * 0.5, master_size)


func get_camera_bounds() -> Rect2:
	return map_bounds


func get_runtime_snapshot() -> Dictionary:
	return {
		"map_bounds": map_bounds,
		"map_size": map_bounds.size,
		"native_scale": scale,
		"development_backdrop": false,
	}
