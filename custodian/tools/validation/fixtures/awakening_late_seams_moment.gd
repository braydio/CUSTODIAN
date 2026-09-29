extends Node2D

const SEAM_POINTS := {
	"05_06": Vector2(0, -3760),
	"06_07": Vector2(0, -4752),
	"07_08": Vector2(0, -5528),
	"08_10": Vector2(0, -6224),
	"08_09": Vector2(-368, -5800),
}

@onready var operator: Node2D = $AwakeningFirstReturn/World/Operator
@onready var camera: Camera2D = $AwakeningFirstReturn/World/Camera2D

var checkpoint := "ready"

func _ready() -> void:
	operator.set_process(false)
	operator.set_physics_process(false)
	_show_seam("05_06")

func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	if not command.begins_with("show_seam_"):
		return false
	var seam_name := command.trim_prefix("show_seam_")
	if not SEAM_POINTS.has(seam_name):
		return false
	_show_seam(seam_name)
	return true

func _show_seam(seam_name: String) -> void:
	checkpoint = seam_name
	var point: Vector2 = SEAM_POINTS[seam_name]
	operator.global_position = point
	camera.global_position = point

func get_debug_snapshot() -> Dictionary:
	return {"checkpoint": checkpoint}
