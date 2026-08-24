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
		"begin_full_journey":
			_begin_full_journey()
		_:
			return false
	return true


func _begin_full_journey() -> void:
	checkpoint = "journey_northbound"
	var journey := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for point in [Vector2(-192,1120), Vector2(-192,720), Vector2(128,320), Vector2(160,-64), Vector2(64,-448), Vector2(0,-704), Vector2(0,-1120)]:
		journey.tween_property(operator, "global_position", point, 0.75)
	journey.tween_callback(func() -> void: checkpoint = "chapel_gameplay")
	journey.tween_interval(0.6)
	journey.tween_callback(func() -> void: checkpoint = "returning")
	for point in [Vector2(0,-704), Vector2(64,-448), Vector2(160,-64), Vector2(-192,720), Vector2(0,1600)]:
		journey.tween_property(operator, "global_position", point, 0.55)
	journey.tween_callback(_play_review_ascent)


func _play_review_ascent() -> void:
	checkpoint = "lower_lift_ascent"
	level.lower_lift.position = level.LOWER_LIFT_DOCK
	var ascent := create_tween()
	ascent.tween_property(level.lower_lift, "position", level.LOWER_LIFT_ARRIVAL_START, 1.10)
