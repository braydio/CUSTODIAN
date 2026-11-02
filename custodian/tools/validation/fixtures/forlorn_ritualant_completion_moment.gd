extends Node2D

@onready var level: ForlornRitualantUnderground = $ForlornRitualantUnderground
@onready var operator: Node2D = $Operator
@onready var site: ForlornRitualantSite = $ForlornRitualantUnderground/PlayableRoot/ForlornRitualantSite
@onready var ritualant: ForlornRitualantNPC = $ForlornRitualantUnderground/PlayableRoot/ForlornRitualantSite/NPCs/ForlornRitualant
@onready var camera: Camera2D = $Camera2D

var checkpoint := "arrival_lower_lift"
var active_attack := "none"


func _ready() -> void:
	operator.add_to_group("player")
	operator.global_position = level.lower_lift.get_boarding_position()
	camera.position = Vector2(0.0, 180.0)
	ritualant.target = operator


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	match command:
		"approach_reveal":
			checkpoint = command
			camera.position = Vector2.ZERO
			operator.global_position = site.global_position + Vector2(0.0, 126.0)
			site.trigger_intro()
		"first_dialogue":
			checkpoint = command
			operator.global_position = site.global_position + Vector2(40.0, 52.0)
			site.interact_with_ritualant()
		"touch_thread":
			checkpoint = command
			site.dialogue_presenter.cancel()
			site.touch_thread()
			operator.global_position = site.global_position + Vector2(0.0, 58.0)
		"thread_pull":
			_prepare_hostile(command, Vector2(120.0, 0.0))
			ritualant.debug_force_attack(&"thread_pull")
		"ninth_answer":
			_prepare_hostile(command, Vector2(0.0, 72.0))
			ritualant.debug_force_attack(&"ninth_answer")
		"orra_late":
			_prepare_hostile(command, Vector2(80.0, 36.0))
			ritualant.debug_force_attack(&"orra_late")
		"anchor_west":
			_play_anchor_exchange(command, &"west", Vector2(-92.0, 18.0))
		"anchor_north":
			_play_anchor_exchange(command, &"north", Vector2(0.0, -84.0))
		"anchor_east":
			_play_anchor_exchange(command, &"east", Vector2(92.0, 18.0))
		"return_lift":
			checkpoint = command
			active_attack = "none"
			camera.position = Vector2(0.0, 180.0)
			ritualant.phase = ForlornRitualantNPC.Phase.KNEELING
			site.event_state.ritualant_hostile = false
			site.event_state.set_resolution(AshBellEventState.Resolution.SEEN)
			operator.global_position = level.lower_lift.get_boarding_position()
		"begin_return":
			checkpoint = command
			level.begin_lift_departure(
				operator,
				level.get_node("Exits/Exit_ReturnWorld") as InteractableLevelExit2D
			)
		_:
			return false
	return true


func _prepare_hostile(label: String, offset: Vector2) -> void:
	checkpoint = label
	active_attack = label
	site.dialogue_presenter.cancel()
	site.event_state.ritualant_hostile = true
	ritualant.phase = ForlornRitualantNPC.Phase.HOSTILE
	operator.global_position = ritualant.global_position + offset


func _play_anchor_exchange(label: String, anchor_id: StringName, offset: Vector2) -> void:
	_prepare_hostile(label, offset)
	ritualant.debug_force_attack(&"pin_strike")
	await get_tree().create_timer(0.65).timeout
	if site != null and site.event_state.ritualant_hostile:
		site.resolve_thread_anchor(anchor_id)
