extends Node2D

@onready var _operator: Node2D = $Operator
@onready var _camera: Camera2D = $Camera2D
@onready var _level: Node = $Level


func _ready() -> void:
	_camera.set("operator_ref", _operator)
	_camera.call("set_follow_target", _operator)
	_camera.set("authored_map_bounds", _level.call("get_camera_bounds"))
	_operator.global_position = _level.call("get_spawn_position", &"Spawn_CrownCauseway")
