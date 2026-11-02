extends Node2D

const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const LOWER_UPPER_PASSAGE_ID := "lower_upper_spine_05_06"

const CHECKPOINT_POINTS := {
	"locker_interior": Vector2(704, -1984),
	"04_05_a": Vector2(704, -2352),
	"04_05_b": Vector2(352, -2496),
	"04_05_c": Vector2(0, -2608),
	"dust_interior": Vector2(0, -3200),
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
	_show_checkpoint("05_06")

func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	if command == "show_checkpoint":
		var requested_checkpoint := str(_args.get("checkpoint", ""))
		if requested_checkpoint != "05_06" and not CHECKPOINT_POINTS.has(requested_checkpoint):
			return false
		_show_checkpoint(requested_checkpoint)
		return true
	if not command.begins_with("show_"):
		return false
	var checkpoint_name := command.trim_prefix("show_")
	if checkpoint_name.ends_with("_reverse"):
		checkpoint_name = checkpoint_name.trim_suffix("_reverse")
	if checkpoint_name.begins_with("seam_"):
		checkpoint_name = checkpoint_name.trim_prefix("seam_")
	if checkpoint_name == "05_06":
		_show_checkpoint(checkpoint_name)
		return true
	if not CHECKPOINT_POINTS.has(checkpoint_name):
		return false
	_show_checkpoint(checkpoint_name)
	return true

func _show_checkpoint(checkpoint_name: String) -> void:
	checkpoint = checkpoint_name
	var point: Vector2 = Layout.PASSAGES[LOWER_UPPER_PASSAGE_ID].get_center() if checkpoint_name == "05_06" else CHECKPOINT_POINTS[checkpoint_name]
	operator.global_position = point
	camera.global_position = point

func get_debug_snapshot() -> Dictionary:
	return {"checkpoint": checkpoint}
