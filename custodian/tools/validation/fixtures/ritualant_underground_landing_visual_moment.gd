extends Node2D

@onready var level: ForlornRitualantUnderground = $ForlornRitualantUnderground
@onready var operator: Node2D = $Operator
@onready var camera: Camera2D = $Camera2D

var canonical_apron_loaded := false
var checkpoint := "lift_ready"


func _ready() -> void:
	level.lower_lift.z_as_relative = false
	level.lower_lift.z_index = 20
	level.lower_lift.set_depths(20, 31)
	operator.add_to_group("player")
	operator.global_position = level.lower_lift.get_boarding_position()
	camera.position = Vector2(0.0, 1540.0)
	var apron := level.get_node("BackgroundRoot/LandingShelfApron") as Sprite2D
	canonical_apron_loaded = apron != null and apron.texture != null and apron.texture.resource_path.ends_with("ritualant_underground__overlay__landing_shelf_apron_01__768x512.png")


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	match command:
		"begin_landing_descent":
			checkpoint = "descending"
			level.call("_begin_arrival_sequence", operator)
		"hold_apron_center":
			checkpoint = "apron_center"
			operator.global_position = Vector2(0.0, 1600.0)
		"begin_north_walk":
			checkpoint = "walking_north"
			var walk := create_tween().set_trans(Tween.TRANS_LINEAR)
			walk.tween_property(operator, "global_position", Vector2(0.0, 1328.0), 3.5)
		_:
			return false
	return true
