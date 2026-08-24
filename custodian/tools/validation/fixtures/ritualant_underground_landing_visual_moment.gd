extends Node2D

const LANDING_ART_REVIEW_OFFSET := Vector2(0.0, 1536.0)

@onready var level: ForlornRitualantUnderground = $ForlornRitualantUnderground
@onready var operator: Node2D = $Operator
@onready var camera: Camera2D = $Camera2D

var candidate_id := "CANONICAL"
var candidate_applied := false
var checkpoint := "lift_ready"


func _ready() -> void:
	# The current cavern art stack is authored around local origin. Register that
	# unchanged stack over the authored lower landing for this isolated review.
	level.get_node("UnderlayRoot").position = LANDING_ART_REVIEW_OFFSET
	level.get_node("BackgroundRoot").position = LANDING_ART_REVIEW_OFFSET
	level.lower_lift.z_as_relative = false
	level.lower_lift.z_index = 20
	level.lower_lift.set_depths(20, 31)
	operator.add_to_group("player")
	operator.global_position = level.lower_lift.get_boarding_position()
	camera.position = Vector2(0.0, 1540.0)
	candidate_id = OS.get_environment("CUSTODIAN_RITUALANT_APRON_CANDIDATE").strip_edges().to_upper()
	if candidate_id.is_empty():
		candidate_id = "CANONICAL"
	candidate_applied = level.moment_forge_set_landing_apron_candidate(candidate_id)


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
