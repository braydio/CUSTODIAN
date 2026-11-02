extends Node2D

@onready var level: AshBellLowerQuarter = $World/AshBellLowerQuarter
@onready var operator: Node2D = $World/Operator
@onready var camera: CameraController = $World/Camera2D
var checkpoint := "arrival"
var real_camera := false
var real_operator := false

func _ready() -> void:
	operator.add_to_group("player")
	operator.global_position = level.cell_center(Vector2i(64, 87))
	camera.operator_ref = operator
	camera.follow_target = operator
	camera.map_bounds = level.camera_bounds
	camera.global_position = operator.global_position
	real_camera = camera is CameraController
	real_operator = operator.get_script() != null and operator.scene_file_path.ends_with("operator.tscn")

func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	match command:
		"direct_line": _move_to("direct_line", Vector2i(64, 78))
		"evacuation_turn": _move_to("evacuation_turn", Vector2i(53, 76))
		"civic_basin": _move_to("civic_basin", Vector2i(66, 43))
		"answers_court": _move_to("answers_court", Vector2i(72, 20))
		"station_threshold": _move_to("station_threshold", Vector2i(78, 64))
		_: return false
	return true

func _move_to(next_checkpoint: String, cell: Vector2i) -> void:
	checkpoint = next_checkpoint
	operator.global_position = level.cell_center(cell)
	camera.global_position = operator.global_position
