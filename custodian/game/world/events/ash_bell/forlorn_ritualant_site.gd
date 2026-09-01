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
@export var stilling_pin_pickup_path: NodePath
@export var ghost_procession_path: NodePath
@export var debug_label_path: NodePath
@export var dialogue_label_path: NodePath

@export_group("Optional Stagecraft Paths")
@export var silence_veil_path: NodePath
@export var pressure_halo_path: NodePath
@export var thread_visual_path: NodePath
@export var fountain_ring_path: NodePath
@export var bell_shadow_path: NodePath

@export_group("Encounter Tuning")
@export var fountain_pressure_tick_seconds: float = 2.0
@export var fountain_pressure_per_tick: int = 1
@export var fountain_stabilize_seconds: float = 4.5
@export var peaceful_exit_requires_thread_touch: bool = false

@onready var forlorn_ritualant: Node = get_node_or_null(forlorn_ritualant_path)
@onready var dry_fountain_ghost: CanvasItem = get_node_or_null(dry_fountain_ghost_path)
@onready var dry_fountain_black_water: CanvasItem = get_node_or_null(dry_fountain_black_water_path)
@onready var upward_ash: GPUParticles2D = get_node_or_null(upward_ash_path)
@onready var downward_ash: GPUParticles2D = get_node_or_null(downward_ash_path)
@onready var unarrived_apparition: CanvasItem = get_node_or_null(unarrived_apparition_path)
@onready var stilling_pin_pickup: Area2D = get_node_or_null(stilling_pin_pickup_path)
@onready var ghost_procession: Node2D = get_node_or_null(ghost_procession_path)
@onready var debug_label: Label = get_node_or_null(debug_label_path)
@onready var dialogue_label: Label = get_node_or_null(dialogue_label_path)
@onready var dialogue_presenter: ForlornRitualantDialoguePresenter = (
	get_node_or_null("DialogueOverlay/DialoguePresentation")
)

@onready var silence_veil: CanvasItem = get_node_or_null(silence_veil_path)
@onready var pressure_halo: CanvasItem = get_node_or_null(pressure_halo_path)
@onready var thread_visual: CanvasItem = get_node_or_null(thread_visual_path)
@onready var fountain_ring: CanvasItem = get_node_or_null(fountain_ring_path)
@onready var bell_shadow: CanvasItem = get_node_or_null(bell_shadow_path)

var _intro_triggered: bool = false
var _player_inside_fountain: bool = false
var _fountain_stand_time: float = 0.0
var _fountain_total_stand_time: float = 0.0
var _completed: bool = false
var _dialogue_sequence: int = 0
var _resolution_sequence_running := false
var _deferred_hostility_reason: StringName = &""
var _debug_last_hostility_reason: StringName = &""

var _fountain_stabilize_time: float = 0.0
var _thread_snap_handled := false
var _resolved_thread_anchors: Dictionary = {}
const THREAD_ANCHOR_ORDER: Array[StringName] = [&"west", &"north", &"east"]
var _thread_anchor_stage := 0
var _hostile_attack_epoch := 0
var _anchor_unlock_epoch := 1

const TOPIC_KNOWLEDGE := {
	&"ask_bell": &"ash_bell_ninth_answer",
	&"ask_unarrival": &"ash_bell_open_interval",
	&"ask_thread": &"ash_bell_white_thread",
	&"ask_thread_breaks": &"ash_bell_white_thread",
	&"ask_orra": &"ash_bell_unarrived_saint",
	&"ask_orra_late": &"ash_bell_unarrived_saint",
	&"ask_orra_judgement": &"ash_bell_unarrived_saint",
}
const CORE_DIALOGUE_TOPICS: Array[StringName] = [
	&"ask_bell", &"ask_thread", &"ask_orra",
]


func _ready() -> void:
	add_to_group("ash_bell_site")
	if event_state == null:
		event_state = AshBellEventState.new()
	var ledger := get_node_or_null("/root/ResourceLedger")
	event_state.has_thread_knot = (
		ledger != null and int(ledger.call("get_amount", "white_thread_knot")) > 0
	)

	event_state.pressure_changed.connect(_on_pressure_changed)
	event_state.fountain_state_changed.connect(_on_fountain_state_changed)
	event_state.resolution_changed.connect(_on_resolution_changed)
	event_state.knowledge_unlocked.connect(_on_knowledge_unlocked)
	event_state.thread_snapped.connect(_handle_thread_snap_once)
	event_state.hostility_requested.connect(_request_hostile_phase)
	request_dialogue.connect(_on_request_dialogue)
	if forlorn_ritualant != null and forlorn_ritualant.has_signal("attack_started"):
		forlorn_ritualant.attack_started.connect(_on_ritualant_attack_started)
	if dialogue_presenter != null:
		dialogue_presenter.topic_requested.connect(_on_dialogue_topic_requested)
		dialogue_presenter.sequence_finished.connect(_on_dialogue_sequence_finished)
	request_item_grant.connect(_on_request_item_grant)
	request_knowledge_unlock.connect(_on_request_knowledge_unlock)

	_set_initial_visibility()
	_update_event_atmosphere()
	_update_debug()


func _process(delta: float) -> void:
	if not _deferred_hostility_reason.is_empty() \
	and not is_dialogue_input_captured():
		var deferred_reason := _deferred_hostility_reason
		_deferred_hostility_reason = &""
		_start_hostile_phase(deferred_reason)
	if suppresses_encounter_hazards():
		_fountain_stand_time = 0.0
		_fountain_stabilize_time = 0.0
		_update_event_atmosphere()
		_update_debug()
		return
	if _player_inside_fountain:
		_fountain_stand_time += delta
		_fountain_total_stand_time += delta
		if _fountain_total_stand_time >= 1.0:
			_request_dialogue_once(&"fountain_zone_warning")
		if _fountain_total_stand_time >= 3.0:
			_request_dialogue_once(&"fountain_zone_linger")

		if _fountain_stand_time >= fountain_pressure_tick_seconds:
			_fountain_stand_time = 0.0
			event_state.add_silence_pressure(fountain_pressure_per_tick, &"standing_in_dry_fountain")

		if event_state.has_thread_knot \
				and not event_state.ritualant_hostile \
				and event_state.fountain_state == AshBellEventState.FountainState.CRACKED_ANCHORED:
			_fountain_stabilize_time += delta
			if _fountain_stabilize_time >= fountain_stabilize_seconds:
				stabilize_site()
		else:
			_fountain_stabilize_time = 0.0
	else:
		_fountain_stand_time = 0.0
		_fountain_total_stand_time = 0.0
		_fountain_stabilize_time = 0.0

	_update_event_atmosphere()
	_update_debug()


func trigger_intro() -> void:
	if _intro_triggered:
		return

	_intro_triggered = true
	event_state.set_resolution(AshBellEventState.Resolution.SEEN)
	request_dialogue.emit(dialogue_id, &"proximity_intro")


func interact_with_ritualant() -> void:
	if not can_speak_to_ritualant():
		return
	if dialogue_presenter != null and dialogue_presenter.blocks_world_interaction():
		return
	var actor := _get_dialogue_actor()
	if event_state.has_seen_dialogue(&"first_interaction"):
		if dialogue_presenter == null:
			return
		if has_completed_core_dialogue():
			var synopsis := (
				&"core_synopsis_pin_taken"
				if event_state.has_stilling_pin
				else &"core_synopsis_pin_waiting"
			)
			dialogue_presenter.start(synopsis, actor)
		else:
			dialogue_presenter.open_menu(&"ritualant_root", actor)
		return
	event_state.set_resolution(AshBellEventState.Resolution.SPOKE_TO_RITUALANT)
	event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)
	event_state.unlock_knowledge(&"ash_bell_dry_fountain")
	request_dialogue.emit(dialogue_id, &"first_interaction")


func ask_about_bell() -> void:
	event_state.set_resolution(AshBellEventState.Resolution.SPOKE_TO_RITUALANT)
	event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)
	_start_topic_or_recap(&"ask_bell", &"ask_bell_recap")


func ask_about_thread() -> void:
	_start_topic_or_recap(&"ask_thread", &"ask_thread_recap")


func ask_about_orra() -> void:
	_start_topic_or_recap(&"ask_orra", &"ask_orra_recap")


func _start_topic_or_recap(
	topic_id: StringName,
	recap_id: StringName
) -> bool:
	var node_id := recap_id if event_state.has_seen_dialogue(topic_id) else topic_id
	return _start_topic_dialogue(node_id, &"")

func _on_dialogue_topic_requested(node_id: StringName, return_menu_id: StringName) -> void:
	if not _start_topic_dialogue(node_id, return_menu_id):
		if dialogue_presenter != null:
			dialogue_presenter.force_close()

func _start_topic_dialogue(node_id: StringName, return_menu_id: StringName) -> bool:
	if not can_speak_to_ritualant() or dialogue_presenter == null:
		return false
	return dialogue_presenter.start(node_id, _get_dialogue_actor(), return_menu_id)

func _on_dialogue_sequence_finished(node_id: StringName) -> void:
	event_state.mark_dialogue_seen(node_id)
	var knowledge_variant: Variant = TOPIC_KNOWLEDGE.get(node_id, &"")
	if knowledge_variant is StringName and knowledge_variant != &"":
		event_state.unlock_knowledge(knowledge_variant)


func has_completed_core_dialogue() -> bool:
	if event_state == null or not event_state.has_seen_dialogue(&"first_interaction"):
		return false
	for topic_id in CORE_DIALOGUE_TOPICS:
		if not event_state.has_seen_dialogue(topic_id):
			return false
	return true

func _get_dialogue_actor() -> Node2D:
	var actor := get_tree().get_first_node_in_group("player") as Node2D
	if actor == null: actor = get_tree().get_first_node_in_group("operator") as Node2D
	return actor

func is_dialogue_input_captured() -> bool:
	return dialogue_presenter != null and dialogue_presenter.blocks_world_interaction()


func is_terminal_resolution() -> bool:
	if event_state == null:
		return false
	return event_state.resolution in [
		AshBellEventState.Resolution.RITUALANT_DISSOLVED,
		AshBellEventState.Resolution.SITE_STABILIZED,
		AshBellEventState.Resolution.SITE_DEFILED,
	]


func is_encounter_resolving() -> bool:
	return _resolution_sequence_running


func suppresses_encounter_hazards() -> bool:
	return (
		is_dialogue_input_captured()
		or is_encounter_resolving()
		or is_terminal_resolution()
	)


func can_speak_to_ritualant() -> bool:
	return (
		not _resolution_sequence_running
		and not is_terminal_resolution()
		and event_state != null
		and not event_state.ritualant_hostile
		and forlorn_ritualant != null
		and is_instance_valid(forlorn_ritualant)
	)

func _request_dialogue_once(node_id: StringName) -> void:
	if is_terminal_resolution() or _resolution_sequence_running:
		return
	if not event_state.has_seen_dialogue(node_id):
		request_dialogue.emit(dialogue_id, node_id)


func touch_thread() -> void:
	if _resolution_sequence_running or is_terminal_resolution():
		return
	event_state.calm_thread(12)
	event_state.add_silence_pressure(-4, &"thread_touched")
	event_state.set_resolution(AshBellEventState.Resolution.TOUCHED_THREAD)
	event_state.unlock_knowledge(&"ash_bell_white_thread")
	_request_dialogue_once(&"thread_touch_response")

	if event_state.fountain_state == AshBellEventState.FountainState.GHOST:
		event_state.set_fountain_state(AshBellEventState.FountainState.CRACKED_ANCHORED)


func cut_thread() -> void:
	if _resolution_sequence_running or is_terminal_resolution() \
			or event_state.ritualant_hostile:
		return

	event_state.set_resolution(AshBellEventState.Resolution.CUT_THREAD)
	event_state.set_thread_tension(99, &"thread_cut_pending")
	request_dialogue.emit(dialogue_id, &"cut_thread_response")
	if dialogue_presenter != null and _get_dialogue_actor() != null:
		await dialogue_presenter.wait_for_node_end(&"cut_thread_response")
	event_state.set_thread_tension(100, &"thread_cut")
	event_state.add_silence_pressure(25, &"thread_cut")


func take_stilling_pin() -> void:
	if event_state.has_stilling_pin \
			or not has_completed_core_dialogue() \
			or event_state.ritualant_hostile:
		return

	event_state.has_stilling_pin = true
	event_state.set_resolution(AshBellEventState.Resolution.TOOK_STILLING_PIN)
	event_state.unlock_knowledge(&"ash_bell_ninth_answer")
	request_item_grant.emit(&"stilling_pin")
	_request_dialogue_once(&"take_stilling_pin_response")

	if stilling_pin_pickup != null:
		stilling_pin_pickup.queue_free()


func inspect_dry_fountain() -> void:
	if event_state.has_stilling_pin:
		return
	if event_state.fountain_state == AshBellEventState.FountainState.ABSENT:
		event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)

	event_state.add_silence_pressure(3, &"fountain_touched")
	event_state.unlock_knowledge(&"ash_bell_dry_fountain")
	request_dialogue.emit(dialogue_id, &"inspect_fountain")


func set_stilling_pin() -> void:
	if not can_set_stilling_pin():
		return

	event_state.set_resolution(AshBellEventState.Resolution.SET_STILLING_PIN)
	event_state.set_fountain_state(AshBellEventState.FountainState.CRACKED_ANCHORED)
	request_dialogue.emit(dialogue_id, &"set_stilling_pin_pre")
	if dialogue_presenter != null: await dialogue_presenter.wait_for_node_end(&"set_stilling_pin_pre")
	_show_unarrived_apparition()
	_trigger_ghost_procession()
	await get_tree().create_timer(1.15).timeout
	request_dialogue.emit(dialogue_id, &"set_stilling_pin_resolve")
	if dialogue_presenter != null:
		await dialogue_presenter.wait_for_node_end(&"set_stilling_pin_resolve")
	stabilize_site()


func can_set_stilling_pin() -> bool:
	return (
		event_state != null
		and event_state.has_stilling_pin
		and event_state.has_thread_knot
		and has_completed_core_dialogue()
		and not event_state.ritualant_hostile
		and not _resolution_sequence_running
		and not is_terminal_resolution()
		and event_state.resolution >= AshBellEventState.Resolution.TOOK_STILLING_PIN
		and event_state.resolution != AshBellEventState.Resolution.SET_STILLING_PIN
	)


func player_attacked_in_room() -> void:
	event_state.add_silence_pressure(15, &"player_attack")
	if not event_state.ritualant_hostile:
		request_dialogue.emit(dialogue_id, &"attack_response")
		_request_hostile_phase(&"player_melee")


func player_fired_weapon_in_room() -> void:
	event_state.add_silence_pressure(22, &"player_firearm")
	if not event_state.ritualant_hostile:
		request_dialogue.emit(dialogue_id, &"attack_response")
		_request_hostile_phase(&"player_firearm")


func player_crossed_thread(move_kind: StringName) -> void:
	if _resolution_sequence_running or is_terminal_resolution():
		return
	match move_kind:
		&"walk":
			event_state.add_thread_tension(3, &"walk_thread")
		&"run":
			event_state.add_thread_tension(7, &"run_thread")
		&"dodge":
			event_state.add_thread_tension(12, &"dodge_thread")
		_:
			event_state.add_thread_tension(3, &"cross_thread")
	_request_dialogue_once(&"thread_cross_warning")

func warn_thread_approach() -> void:
	if _resolution_sequence_running or is_terminal_resolution():
		return
	_request_dialogue_once(&"thread_warning")


func set_player_inside_fountain(is_inside: bool) -> void:
	_player_inside_fountain = is_inside
	if not is_inside:
		_fountain_stand_time = 0.0
		_fountain_total_stand_time = 0.0


func exit_site() -> void:
	if _completed:
		return

	if event_state.ritualant_hostile:
		return

	request_dialogue.emit(dialogue_id, &"peaceful_exit")
	_complete_if_ready()


func can_depart_site() -> bool:
	if _resolution_sequence_running:
		return false
	if is_terminal_resolution():
		return true
	return event_state != null and not event_state.ritualant_hostile


func play_departure_epilogue() -> void:
	if event_state.resolution == AshBellEventState.Resolution.SITE_DEFILED \
			or event_state.resolution == AshBellEventState.Resolution.RITUALANT_DISSOLVED:
		await get_tree().create_timer(1.0).timeout
		return
	var node_id := (
		&"stabilized_exit"
		if event_state.resolution == AshBellEventState.Resolution.SITE_STABILIZED
		else &"peaceful_exit"
	)
	request_dialogue.emit(dialogue_id, node_id)
	if dialogue_presenter != null and dialogue_presenter.is_active():
		await dialogue_presenter.sequence_finished


func get_departure_lines() -> Array[String]:
	if event_state == null \
			or not event_state.has_seen_dialogue(&"first_interaction"):
		return []
	if event_state.resolution == AshBellEventState.Resolution.SITE_DEFILED \
			or event_state.resolution == AshBellEventState.Resolution.RITUALANT_DISSOLVED:
		return []
	if event_state.resolution == AshBellEventState.Resolution.SITE_STABILIZED:
		return []
	return ["Go gently.", "Some gates are closed by footsteps."]


func resolve_thread_anchor(anchor_id: StringName) -> void:
	if not can_resolve_thread_anchor(anchor_id):
		return
	_resolved_thread_anchors[anchor_id] = true
	_thread_anchor_stage += 1
	event_state.calm_thread(18)
	event_state.add_silence_pressure(-8, &"thread_anchor")
	_anchor_unlock_epoch = _hostile_attack_epoch + 1
	if _thread_anchor_stage >= THREAD_ANCHOR_ORDER.size():
		stabilize_site()


func can_resolve_thread_anchor(anchor_id: StringName) -> bool:
	if event_state == null or not event_state.ritualant_hostile:
		return false
	if _thread_anchor_stage >= THREAD_ANCHOR_ORDER.size():
		return false
	if anchor_id != THREAD_ANCHOR_ORDER[_thread_anchor_stage]:
		return false
	return _hostile_attack_epoch >= _anchor_unlock_epoch


func _on_ritualant_attack_started() -> void:
	if event_state != null and event_state.ritualant_hostile and not _resolution_sequence_running:
		_hostile_attack_epoch += 1


func debug_get_resolved_thread_anchor_count() -> int:
	return _resolved_thread_anchors.size()


func is_thread_anchor_resolved(anchor_id: StringName) -> bool:
	return _resolved_thread_anchors.has(anchor_id)


func debug_get_last_hostility_reason() -> StringName:
	return _debug_last_hostility_reason


func capture_encounter_state() -> Dictionary:
	return {
		"event_state": event_state.capture_state() if event_state != null else {},
		"intro_triggered": _intro_triggered,
		"encounter_completed": _completed,
		"resolved_thread_anchor_ids": _resolved_thread_anchors.keys(),
		"thread_anchor_stage": _thread_anchor_stage,
		"hostile_attack_epoch": _hostile_attack_epoch,
		"anchor_unlock_epoch": _anchor_unlock_epoch,
		"thread_snap_handled": _thread_snap_handled,
		"last_hostility_reason": String(_debug_last_hostility_reason),
	}


func restore_encounter_state(state: Dictionary) -> bool:
	if state.is_empty() or event_state == null:
		return false
	var event_snapshot := state.get("event_state", {}) as Dictionary
	if not event_state.restore_state(event_snapshot, false):
		return false
	_intro_triggered = bool(state.get("intro_triggered", false))
	_completed = bool(state.get("encounter_completed", false))
	_thread_snap_handled = bool(state.get("thread_snap_handled", false))
	_debug_last_hostility_reason = StringName(str(state.get("last_hostility_reason", "")))
	_resolved_thread_anchors.clear()
	for anchor_id: Variant in state.get("resolved_thread_anchor_ids", []):
		_resolved_thread_anchors[StringName(str(anchor_id))] = true
	_thread_anchor_stage = int(state.get("thread_anchor_stage", _resolved_thread_anchors.size()))
	_hostile_attack_epoch = int(state.get("hostile_attack_epoch", _thread_anchor_stage))
	_anchor_unlock_epoch = int(state.get("anchor_unlock_epoch", _thread_anchor_stage + 1))
	_apply_restored_encounter_state()
	return true


func _apply_restored_encounter_state() -> void:
	_set_initial_visibility()
	_on_fountain_state_changed(event_state.fountain_state)
	_on_resolution_changed(event_state.resolution)
	_update_event_atmosphere()
	_update_debug()
	if event_state.apparition_seen and unarrived_apparition != null:
		unarrived_apparition.visible = false
	if event_state.has_stilling_pin and stilling_pin_pickup != null:
		stilling_pin_pickup.visible = false
		stilling_pin_pickup.monitoring = false
	if event_state.ritualant_hostile \
			and forlorn_ritualant != null \
			and forlorn_ritualant.has_method("become_hostile"):
		forlorn_ritualant.call("become_hostile")


func _handle_thread_snap_once() -> void:
	if _thread_snap_handled:
		return
	_thread_snap_handled = true
	_request_hostile_phase(&"thread_snap")


func stabilize_site() -> void:
	if _resolution_sequence_running or is_terminal_resolution():
		return
	_resolution_sequence_running = true
	event_state.ritualant_hostile = false
	event_state.set_resolution(AshBellEventState.Resolution.SITE_STABILIZED)
	event_state.unlock_knowledge(&"ash_bell_open_interval")
	if dialogue_presenter != null:
		dialogue_presenter.force_close()
	if forlorn_ritualant != null \
			and is_instance_valid(forlorn_ritualant) \
			and forlorn_ritualant.has_method("interrupt_for_stabilization"):
		forlorn_ritualant.call("interrupt_for_stabilization")
	if thread_visual != null:
		thread_visual.visible = true
		thread_visual.modulate.a = 0.0
		var thread_tween := create_tween()
		thread_tween.set_trans(Tween.TRANS_SINE)
		thread_tween.set_ease(Tween.EASE_OUT)
		thread_tween.tween_property(thread_visual, "modulate:a", 1.0, 0.35)
	await get_tree().create_timer(0.35).timeout
	await get_tree().create_timer(0.55).timeout
	if forlorn_ritualant != null \
			and is_instance_valid(forlorn_ritualant) \
			and forlorn_ritualant.has_method("begin_stabilized_resolution"):
		forlorn_ritualant.call("begin_stabilized_resolution")
	event_state.set_silence_pressure(0, &"site_stabilized")
	event_state.calm_thread(100)
	_set_downward_ash_enabled(false)
	await get_tree().create_timer(0.70).timeout
	request_dialogue.emit(dialogue_id, &"stabilized_exit")
	if dialogue_presenter != null \
			and dialogue_presenter.get_active_node() == &"stabilized_exit":
		await dialogue_presenter.wait_for_node_end(&"stabilized_exit")
	await get_tree().create_timer(0.25).timeout
	if forlorn_ritualant != null \
			and is_instance_valid(forlorn_ritualant) \
			and forlorn_ritualant.has_method("dissolve"):
		forlorn_ritualant.call("dissolve")
	if dialogue_presenter != null \
			and dialogue_presenter.get_active_node() == &"stabilized_exit":
		await dialogue_presenter.wait_for_node_end(&"stabilized_exit")
	_resolution_sequence_running = false
	_complete_if_ready()


func defile_site() -> void:
	event_state.set_resolution(AshBellEventState.Resolution.SITE_DEFILED)
	event_state.add_silence_pressure(100, &"site_defiled")
	_show_unarrived_apparition()
	_complete_if_ready()


func _request_hostile_phase(reason: StringName) -> void:
	if is_terminal_resolution() or is_encounter_resolving():
		return
	if is_dialogue_input_captured():
		_deferred_hostility_reason = reason
		return
	_start_hostile_phase(reason)


func _start_hostile_phase(reason: StringName) -> void:
	if is_terminal_resolution() or _resolution_sequence_running:
		return
	_debug_last_hostility_reason = reason
	if dialogue_presenter != null:
		dialogue_presenter.force_close()
	if reason == &"thread_snap":
		_show_unarrived_apparition()
	_thread_anchor_stage = 0
	_hostile_attack_epoch = 0
	_anchor_unlock_epoch = 1
	_resolved_thread_anchors.clear()
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


func begin_ninth_answer_lane(lane_world_x: float) -> void:
	if ghost_procession == null:
		return
	ghost_procession.global_position.x = lane_world_x
	ghost_procession.visible = true
	ghost_procession.modulate = Color(0.75, 0.82, 1.0, 0.28)


func end_ninth_answer_lane() -> void:
	if ghost_procession != null:
		ghost_procession.visible = false


func begin_orra_late(behind_world_position: Vector2) -> void:
	if unarrived_apparition == null:
		return
	unarrived_apparition.global_position = behind_world_position
	unarrived_apparition.visible = true
	unarrived_apparition.modulate.a = 0.35


func resolve_orra_late(caught: bool) -> void:
	if caught:
		event_state.add_silence_pressure(10, &"orra_misplaced")
	_show_unarrived_apparition()


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


func _update_event_atmosphere() -> void:
	if event_state == null:
		return

	var pressure := clampf(float(event_state.silence_pressure) / 100.0, 0.0, 1.0)
	var tension := clampf(float(event_state.thread_tension) / 100.0, 0.0, 1.0)

	if silence_veil != null:
		silence_veil.visible = pressure > 0.02
		silence_veil.modulate.a = lerpf(0.0, 0.45, pressure)

	if pressure_halo != null:
		pressure_halo.visible = pressure > 0.02
		pressure_halo.modulate.a = lerpf(0.0, 0.85, pressure)

	if thread_visual != null:
		thread_visual.visible = event_state.resolution >= AshBellEventState.Resolution.SEEN
		thread_visual.modulate.a = lerpf(0.25, 1.0, tension)

	if fountain_ring != null:
		fountain_ring.visible = (
			event_state.fountain_state
			== AshBellEventState.FountainState.CRACKED_ANCHORED
		)
		if fountain_ring.visible:
			fountain_ring.modulate = Color(0.95, 0.82, 0.42, 0.80)

	if bell_shadow != null:
		bell_shadow.visible = true
		bell_shadow.modulate.a = lerpf(0.25, 0.75, pressure)

	if upward_ash != null:
		upward_ash.amount_ratio = lerpf(0.25, 1.0, pressure)
		upward_ash.speed_scale = lerpf(0.22, 0.62, pressure)

	if downward_ash != null and downward_ash.emitting:
		downward_ash.amount_ratio = lerpf(0.35, 1.0, pressure)

	if ghost_procession != null and ghost_procession.visible:
		ghost_procession.modulate.a = lerpf(0.25, 0.72, pressure)


func _set_downward_ash_enabled(enabled: bool) -> void:
	if upward_ash != null:
		upward_ash.emitting = not enabled

	if downward_ash != null:
		downward_ash.emitting = enabled


func _on_pressure_changed(_silence_pressure: int, _thread_tension: int) -> void:
	_update_event_atmosphere()

	if event_state.silence_pressure >= 25 and upward_ash != null:
		upward_ash.speed_scale = 0.55

	if event_state.silence_pressure >= 75:
		_trigger_ghost_procession()

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
			_retire_terminal_interactions()
			if not _resolution_sequence_running:
				_complete_if_ready()


func _retire_terminal_interactions() -> void:
	for path in [
		NodePath("NPCs/RitualantInteract"),
		NodePath("NPCs/TouchThreadInteract"),
		NodePath("NPCs/CutThreadInteract"),
		NodePath("Props/StillingPinPickup"),
		NodePath("Props/DryFountainInteract"),
		NodePath("Props/SetStillingPinInteract"),
		NodePath("Props/ThreadAnchorWest"),
		NodePath("Props/ThreadAnchorNorth"),
		NodePath("Props/ThreadAnchorEast"),
	]:
		var interactable := get_node_or_null(path) as AshBellInteractable
		if interactable != null:
			interactable.retire()


func _on_knowledge_unlocked(knowledge_id: StringName) -> void:
	request_knowledge_unlock.emit(knowledge_id)


func _complete_if_ready() -> void:
	if _completed:
		return

	_completed = true
	encounter_completed.emit(event_state.resolution)


func _on_request_dialogue(_dialogue_id: StringName, node_id: StringName) -> void:
	if dialogue_presenter == null:
		return
	if node_id == &"stabilized_exit":
		if forlorn_ritualant != null and is_instance_valid(forlorn_ritualant):
			dialogue_presenter.start(node_id, _get_dialogue_actor())
		return
	if is_terminal_resolution():
		return
	if forlorn_ritualant == null or not is_instance_valid(forlorn_ritualant):
		return
	dialogue_presenter.start(node_id, _get_dialogue_actor())


func _on_request_item_grant(item_id: StringName) -> void:
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	if inventory_manager != null and inventory_manager.has_method("add_item"):
		inventory_manager.call("add_item", item_id, 1)
		print("[AshBell] item granted to inventory: ", item_id)
	else:
		print("[AshBell] InventoryManager not available, item grant skipped: ", item_id)


func _on_request_knowledge_unlock(knowledge_id: StringName) -> void:
	var memory := get_node_or_null("/root/WorldEventMemory")
	if memory != null:
		memory.call("mark_completed", StringName("knowledge_%s" % String(knowledge_id)), {
			"source": "forlorn_ritualant",
		})


func _set_dialogue_text(text: String) -> void:
	if dialogue_label != null:
		dialogue_label.text = text
	print("[AshBell] ", text)


func _update_debug() -> void:
	if debug_label == null:
		return

	debug_label.text = "ASH-BELL\npressure=%s\nthread=%s\nfountain=%s\nres=%s\nhostility=%s" % [
		event_state.silence_pressure,
		event_state.thread_tension,
		event_state.fountain_state,
		event_state.resolution,
		String(_debug_last_hostility_reason),
	]
