class_name ForlornRitualantSite
extends Node2D

signal encounter_completed(resolution: int)
signal request_dialogue(dialogue_id: StringName, node_id: StringName)
signal request_item_grant(item_id: StringName)
signal request_knowledge_unlock(knowledge_id: StringName)

@export var dialogue_id: StringName = &"ash_bell_forlorn_ritualant"
@export var event_state: AshBellEventState

@export_group("Node Paths")
@export var forlorn_ritualant_path: NodePath
@export var dry_fountain_ghost_path: NodePath
@export var dry_fountain_black_water_path: NodePath
@export var upward_ash_path: NodePath
@export var downward_ash_path: NodePath
@export var unarrived_apparition_path: NodePath
@export var bronze_clapper_pickup_path: NodePath
@export var ghost_procession_path: NodePath
@export var debug_label_path: NodePath
@export var dialogue_label_path: NodePath

@onready var forlorn_ritualant: Node = get_node_or_null(forlorn_ritualant_path)
@onready var dry_fountain_ghost: CanvasItem = get_node_or_null(dry_fountain_ghost_path)
@onready var dry_fountain_black_water: CanvasItem = get_node_or_null(dry_fountain_black_water_path)
@onready var upward_ash: GPUParticles2D = get_node_or_null(upward_ash_path)
@onready var downward_ash: GPUParticles2D = get_node_or_null(downward_ash_path)
@onready var unarrived_apparition: CanvasItem = get_node_or_null(unarrived_apparition_path)
@onready var bronze_clapper_pickup: Area2D = get_node_or_null(bronze_clapper_pickup_path)
@onready var ghost_procession: Node2D = get_node_or_null(ghost_procession_path)
@onready var debug_label: Label = get_node_or_null(debug_label_path)
@onready var dialogue_label: Label = get_node_or_null(dialogue_label_path)

const DIALOGUE := {
	&"proximity_intro": [
		"Do not speak during the toll.",
		"The west gate was shut before the third ringing.",
		"Mothers pressed their children beneath the banners.",
		"And still the ash came.",
	],
	&"first_interaction": [
		"The Fountain should be beneath us.",
		"Dry stone. Black water. Names counted without mouths.",
		"But the basin is gone.",
		"Then the dead are uncounted.",
	],
	&"ask_bell": [
		"There were eight for the living.",
		"One for the misplaced.",
		"The Ninth had no bronze, no rope, no tower.",
		"Yet all knelt when it answered.",
	],
	&"ask_thread": [
		"For the wrist.",
		"For the name.",
		"For the poor child who wakes before her mother is born.",
		"When the thread snaps, Orra knows you are loose.",
	],
	&"ask_orra": [
		"Saint Orra comes late.",
		"After the blade.",
		"After the order.",
		"After the gate is shut.",
		"She blesses only what cannot be saved.",
		"Do not pray for her arrival.",
		"That is how the Bell learns your name.",
	],
	&"attack_response": [
		"Ahh, Custodian.",
		"So fear found you early.",
	],
	&"cut_thread_response": [
		"No.",
		"Not the thread.",
		"The Unarrived will come looking.",
	],
	&"peaceful_exit": [
		"Go gently.",
		"Some gates are closed by footsteps.",
	],
}

var _intro_triggered: bool = false
var _player_inside_fountain: bool = false
var _fountain_stand_time: float = 0.0
var _completed: bool = false
var _dialogue_sequence: int = 0


func _ready() -> void:
	add_to_group("ash_bell_site")
	if event_state == null:
		event_state = AshBellEventState.new()

	event_state.pressure_changed.connect(_on_pressure_changed)
	event_state.fountain_state_changed.connect(_on_fountain_state_changed)
	event_state.resolution_changed.connect(_on_resolution_changed)
	event_state.knowledge_unlocked.connect(_on_knowledge_unlocked)
	request_dialogue.connect(_on_request_dialogue)
	request_item_grant.connect(_on_request_item_grant)
	request_knowledge_unlock.connect(_on_request_knowledge_unlock)

	_set_initial_visibility()
	_update_debug()


func _process(delta: float) -> void:
	if _player_inside_fountain:
		_fountain_stand_time += delta
		if _fountain_stand_time >= 2.0:
			_fountain_stand_time = 0.0
			event_state.add_silence_pressure(1, &"standing_in_dry_fountain")

	_update_debug()


func trigger_intro() -> void:
	if _intro_triggered:
		return

	_intro_triggered = true
	event_state.set_resolution(AshBellEventState.Resolution.SEEN)
	request_dialogue.emit(dialogue_id, &"proximity_intro")


func interact_with_ritualant() -> void:
	event_state.mark_dialogue_seen(&"first_interaction")
	event_state.set_resolution(AshBellEventState.Resolution.SPOKE_TO_RITUALANT)
	event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)
	event_state.unlock_knowledge(&"ash_bell_dry_fountain")
	request_dialogue.emit(dialogue_id, &"first_interaction")


func ask_about_bell() -> void:
	event_state.mark_dialogue_seen(&"ask_bell")
	event_state.unlock_knowledge(&"ash_bell_ninth_bell")
	request_dialogue.emit(dialogue_id, &"ask_bell")


func ask_about_thread() -> void:
	event_state.mark_dialogue_seen(&"ask_thread")
	event_state.unlock_knowledge(&"ash_bell_white_thread")
	request_dialogue.emit(dialogue_id, &"ask_thread")


func ask_about_orra() -> void:
	event_state.mark_dialogue_seen(&"ask_orra")
	event_state.unlock_knowledge(&"ash_bell_unarrived_saint")
	request_dialogue.emit(dialogue_id, &"ask_orra")


func touch_thread() -> void:
	event_state.has_thread_knot = true
	event_state.calm_thread(12)
	event_state.add_silence_pressure(-4, &"thread_touched")
	event_state.set_resolution(AshBellEventState.Resolution.TOUCHED_THREAD)
	event_state.unlock_knowledge(&"ash_bell_white_thread")
	request_item_grant.emit(&"white_thread_knot")

	if event_state.fountain_state == AshBellEventState.FountainState.GHOST:
		event_state.set_fountain_state(AshBellEventState.FountainState.CRACKED_ANCHORED)


func cut_thread() -> void:
	event_state.thread_tension = 100
	event_state.set_resolution(AshBellEventState.Resolution.CUT_THREAD)
	event_state.add_silence_pressure(25, &"thread_cut")
	request_dialogue.emit(dialogue_id, &"cut_thread_response")
	_show_unarrived_apparition()
	_start_hostile_phase()


func take_clapper() -> void:
	if event_state.has_clapper:
		return

	event_state.has_clapper = true
	event_state.set_resolution(AshBellEventState.Resolution.TOOK_CLAPPER)
	event_state.unlock_knowledge(&"ash_bell_ninth_bell")
	request_item_grant.emit(&"bell_clapper_without_bell")

	if bronze_clapper_pickup != null:
		bronze_clapper_pickup.queue_free()


func player_attacked_in_room() -> void:
	event_state.add_silence_pressure(15, &"player_attack")
	if not event_state.ritualant_hostile:
		request_dialogue.emit(dialogue_id, &"attack_response")
		_start_hostile_phase()


func player_fired_weapon_in_room() -> void:
	event_state.add_silence_pressure(22, &"player_firearm")
	if not event_state.ritualant_hostile:
		request_dialogue.emit(dialogue_id, &"attack_response")
		_start_hostile_phase()


func player_crossed_thread(move_kind: StringName) -> void:
	match move_kind:
		&"walk":
			event_state.add_thread_tension(3, &"walk_thread")
		&"run":
			event_state.add_thread_tension(7, &"run_thread")
		&"dodge":
			event_state.add_thread_tension(12, &"dodge_thread")
		_:
			event_state.add_thread_tension(3, &"cross_thread")


func set_player_inside_fountain(is_inside: bool) -> void:
	_player_inside_fountain = is_inside
	if not is_inside:
		_fountain_stand_time = 0.0


func exit_site() -> void:
	if _completed:
		return

	if event_state.resolution == AshBellEventState.Resolution.SPOKE_TO_RITUALANT:
		request_dialogue.emit(dialogue_id, &"peaceful_exit")

	_complete_if_ready()


func stabilize_site() -> void:
	event_state.set_resolution(AshBellEventState.Resolution.SITE_STABILIZED)
	event_state.unlock_knowledge(&"ash_bell_bellfall_containment")
	_complete_if_ready()


func defile_site() -> void:
	event_state.set_resolution(AshBellEventState.Resolution.SITE_DEFILED)
	event_state.add_silence_pressure(100, &"site_defiled")
	_show_unarrived_apparition()
	_complete_if_ready()


func _start_hostile_phase() -> void:
	event_state.ritualant_hostile = true
	event_state.set_resolution(AshBellEventState.Resolution.PROVOKED_RITUALANT)

	if forlorn_ritualant != null and forlorn_ritualant.has_method("become_hostile"):
		forlorn_ritualant.call("become_hostile")

	_set_downward_ash_enabled(true)
	_trigger_ghost_procession()


func _show_unarrived_apparition() -> void:
	event_state.apparition_seen = true
	event_state.unlock_knowledge(&"ash_bell_unarrived_saint")

	if unarrived_apparition == null:
		return

	unarrived_apparition.visible = true
	var tween := create_tween()
	tween.tween_property(unarrived_apparition, "modulate:a", 0.85, 0.15)
	tween.tween_interval(1.35)
	tween.tween_property(unarrived_apparition, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func() -> void:
		if is_instance_valid(unarrived_apparition):
			unarrived_apparition.visible = false
	)


func _trigger_ghost_procession() -> void:
	if ghost_procession == null:
		return

	if ghost_procession.has_method("play_once"):
		ghost_procession.call("play_once")
	else:
		ghost_procession.visible = true


func _set_initial_visibility() -> void:
	if dry_fountain_ghost != null:
		dry_fountain_ghost.visible = false
		dry_fountain_ghost.modulate.a = 0.0

	if dry_fountain_black_water != null:
		dry_fountain_black_water.visible = false
		dry_fountain_black_water.modulate.a = 0.0

	if unarrived_apparition != null:
		unarrived_apparition.visible = false
		unarrived_apparition.modulate.a = 0.0

	if ghost_procession != null:
		ghost_procession.visible = false

	_set_downward_ash_enabled(false)


func _set_downward_ash_enabled(enabled: bool) -> void:
	if upward_ash != null:
		upward_ash.emitting = not enabled

	if downward_ash != null:
		downward_ash.emitting = enabled


func _on_pressure_changed(_silence_pressure: int, _thread_tension: int) -> void:
	if event_state.silence_pressure >= 25 and upward_ash != null:
		upward_ash.speed_scale = 0.55

	if event_state.silence_pressure >= 75:
		_trigger_ghost_procession()

	if event_state.silence_pressure >= 90 and not event_state.ritualant_hostile:
		_start_hostile_phase()


func _on_fountain_state_changed(new_state: int) -> void:
	match new_state:
		AshBellEventState.FountainState.ABSENT:
			_fade_canvas_item(dry_fountain_ghost, false)
			_fade_canvas_item(dry_fountain_black_water, false)
		AshBellEventState.FountainState.GHOST:
			_fade_canvas_item(dry_fountain_ghost, true)
			_fade_canvas_item(dry_fountain_black_water, false)
		AshBellEventState.FountainState.BLACK_WATER:
			_fade_canvas_item(dry_fountain_ghost, true)
			_fade_canvas_item(dry_fountain_black_water, true)
		AshBellEventState.FountainState.CRACKED_ANCHORED:
			_fade_canvas_item(dry_fountain_ghost, true)
			_fade_canvas_item(dry_fountain_black_water, false)


func _fade_canvas_item(item: CanvasItem, show: bool) -> void:
	if item == null:
		return

	item.visible = true
	var target_alpha := 1.0 if show else 0.0
	var tween := create_tween()
	tween.tween_property(item, "modulate:a", target_alpha, 0.45)
	if not show:
		tween.tween_callback(func() -> void:
			if is_instance_valid(item):
				item.visible = false
		)


func _on_resolution_changed(new_resolution: int) -> void:
	match new_resolution:
		AshBellEventState.Resolution.RITUALANT_DISSOLVED, \
		AshBellEventState.Resolution.SITE_STABILIZED, \
		AshBellEventState.Resolution.SITE_DEFILED:
			_complete_if_ready()


func _on_knowledge_unlocked(knowledge_id: StringName) -> void:
	request_knowledge_unlock.emit(knowledge_id)


func _complete_if_ready() -> void:
	if _completed:
		return

	_completed = true
	encounter_completed.emit(event_state.resolution)


func _on_request_dialogue(_dialogue_id: StringName, node_id: StringName) -> void:
	_dialogue_sequence += 1
	var sequence := _dialogue_sequence
	var lines: Array = DIALOGUE.get(node_id, [])
	if lines.is_empty():
		return

	for line_index in range(lines.size()):
		if sequence != _dialogue_sequence:
			return
		_set_dialogue_text("Forlorn-Ritualant: %s" % String(lines[line_index]))
		if line_index < lines.size() - 1:
			await get_tree().create_timer(2.0).timeout


func _on_request_item_grant(item_id: StringName) -> void:
	print("[AshBell] item grant requested: ", item_id)


func _on_request_knowledge_unlock(knowledge_id: StringName) -> void:
	print("[AshBell] knowledge unlock requested: ", knowledge_id)


func _set_dialogue_text(text: String) -> void:
	if dialogue_label != null:
		dialogue_label.text = text
	print("[AshBell] ", text)


func _update_debug() -> void:
	if debug_label == null:
		return

	debug_label.text = "ASH-BELL\npressure=%s\nthread=%s\nfountain=%s\nres=%s" % [
		event_state.silence_pressure,
		event_state.thread_tension,
		event_state.fountain_state,
		event_state.resolution,
	]
