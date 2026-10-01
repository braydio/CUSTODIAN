extends Node2D

## Walks the authored 04→05 connector centerline at fixed world-space steps so
## room alpha is evaluated continuously by the production Awakening controller.
const MOVE_STEP_PX := 8.0
const POINTS := {
	"forward_z05_midpoint": Vector2(0, -2720),
	"forward_z05_threshold": Vector2(0, -2656),
	"forward_c": Vector2(0, -2608),
	"forward_connector_entry": Vector2(0, -2496),
	"forward_b": Vector2(352, -2496),
	"forward_a_approach": Vector2(704, -2496),
	"forward_a": Vector2(704, -2352),
	"forward_z04_threshold": Vector2(704, -2272),
	"forward_z04_midpoint": Vector2(704, -2208),
	"forward_room04": Vector2(704, -2144),
	"reverse_z04_midpoint": Vector2(704, -2208),
	"reverse_z04_threshold": Vector2(704, -2272),
	"reverse_a": Vector2(704, -2352),
	"reverse_a_approach": Vector2(704, -2496),
	"reverse_b": Vector2(352, -2496),
	"reverse_c_approach": Vector2(0, -2496),
	"reverse_c": Vector2(0, -2608),
	"reverse_z05_threshold": Vector2(0, -2656),
	"reverse_z05_midpoint": Vector2(0, -2720),
	"reverse_room05": Vector2(0, -2784),
}

@onready var awakening: Node = $AwakeningFirstReturn
@onready var operator: Node2D = $AwakeningFirstReturn/World/Operator
@onready var camera: Camera2D = $AwakeningFirstReturn/World/Camera2D

var checkpoint := "dust_lung_start"
var _target := Vector2.ZERO
var _target_checkpoint := ""
var _moving := false


func _ready() -> void:
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.global_position = Vector2(0, -2784)
	camera.global_position = operator.global_position


func _physics_process(_delta: float) -> void:
	if _moving:
		operator.global_position = operator.global_position.move_toward(_target, MOVE_STEP_PX)
		camera.global_position = operator.global_position
		if operator.global_position == _target:
			_moving = false
			checkpoint = _target_checkpoint
	awakening.call("_update_zone_art_visibility")


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	if not POINTS.has(command):
		return false
	_target = POINTS[command]
	_target_checkpoint = command
	_moving = operator.global_position != _target
	if not _moving:
		checkpoint = command
	return true


func get_debug_snapshot() -> Dictionary:
	return {
		"checkpoint": checkpoint,
		"moving": _moving,
		"operator_position": operator.global_position,
		"target_position": _target,
	}
