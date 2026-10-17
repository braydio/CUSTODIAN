extends Node2D

@onready var level: ForlornRitualantUnderground = $ForlornRitualantUnderground
@onready var operator: Node2D = $Operator
@onready var site: ForlornRitualantSite = $ForlornRitualantUnderground/PlayableRoot/ForlornRitualantSite
@onready var ritualant: ForlornRitualantNPC = $ForlornRitualantUnderground/PlayableRoot/ForlornRitualantSite/NPCs/ForlornRitualant
@onready var camera: Camera2D = $Camera2D

var checkpoint := "arrival_lower_lift"
var active_attack := "none"
var _actor_readability_material: Material


func _ready() -> void:
	operator.add_to_group("player")
	operator.global_position = level.lower_lift.get_boarding_position()
	_camera_follow_operator()
	ritualant.target = operator
	_actor_readability_material = ritualant.animated_sprite.material


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	match command:
		"approach_reveal":
			checkpoint = command
			operator.global_position = site.global_position + Vector2(0.0, 126.0)
			_camera_follow_operator()
			site.trigger_intro()
		"first_dialogue":
			checkpoint = command
			operator.global_position = site.global_position + Vector2(40.0, 52.0)
			_camera_follow_operator()
			site.interact_with_ritualant()
		"touch_thread":
			checkpoint = command
			site.dialogue_presenter.cancel()
			site.touch_thread()
			operator.global_position = site.global_position + Vector2(0.0, 58.0)
			_camera_follow_operator()
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
			operator.global_position = level.lower_lift.get_boarding_position()
			_camera_follow_operator()
			ritualant.phase = ForlornRitualantNPC.Phase.KNEELING
			site.event_state.ritualant_hostile = false
			site.event_state.set_resolution(AshBellEventState.Resolution.SEEN)
			operator.global_position = level.lower_lift.get_boarding_position()
			_camera_follow_operator()
		"silhouette_before":
			checkpoint = command
			active_attack = "none"
			site.dialogue_presenter.cancel()
			operator.global_position = site.global_position + Vector2(0.0, 126.0)
			_camera_follow_operator()
			ritualant.phase = ForlornRitualantNPC.Phase.KNEELING
			ritualant.animated_sprite.play(&"kneel_idle")
			ritualant.animated_sprite.set_frame_and_progress(0, 0.0)
			ritualant.animated_sprite.stop()
			ritualant.animated_sprite.material = null
		"silhouette_after":
			checkpoint = command
			ritualant.animated_sprite.material = _actor_readability_material
			await get_tree().process_frame
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
	_camera_follow_operator()


func _play_anchor_exchange(label: String, anchor_id: StringName, offset: Vector2) -> void:
	_prepare_hostile(label, offset)
	ritualant.debug_force_attack(&"pin_strike")
	await get_tree().create_timer(0.65).timeout
	if site != null and site.event_state.ritualant_hostile:
		site.resolve_thread_anchor(anchor_id)


func _camera_follow_operator() -> void:
	if operator != null and camera != null:
		camera.global_position = operator.global_position
