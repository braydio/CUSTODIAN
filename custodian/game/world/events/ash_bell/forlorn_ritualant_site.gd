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

@onready var silence_veil: CanvasItem = get_node_or_null(silence_veil_path)
@onready var pressure_halo: CanvasItem = get_node_or_null(pressure_halo_path)
@onready var thread_visual: CanvasItem = get_node_or_null(thread_visual_path)
@onready var fountain_ring: CanvasItem = get_node_or_null(fountain_ring_path)
@onready var bell_shadow: CanvasItem = get_node_or_null(bell_shadow_path)

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
	&"inspect_fountain": [
		"The basin is dry.",
		"It still remembers what held it.",
	],
	&"set_stilling_pin": [
		"The pin finds the basin.",
		"Orra will know you passed this way.",
		"The dead are counted.",
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

var _fountain_stabilize_time: float = 0.0


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
	_update_event_atmosphere()
	_update_debug()


func _process(delta: float) -> void:
	if _player_inside_fountain:
		_fountain_stand_time += delta

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
	if event_state.ritualant_hostile:
		return

	event_state.set_thread_tension(100, &"thread_cut")
	event_state.set_resolution(AshBellEventState.Resolution.CUT_THREAD)
	event_state.add_silence_pressure(25, &"thread_cut")
	request_dialogue.emit(dialogue_id, &"cut_thread_response")
	_show_unarrived_apparition()
	_start_hostile_phase()


func take_stilling_pin() -> void:
	if event_state.has_stilling_pin:
		return

	event_state.has_stilling_pin = true
	event_state.set_resolution(AshBellEventState.Resolution.TOOK_STILLING_PIN)
	event_state.unlock_knowledge(&"ash_bell_ninth_bell")
	request_item_grant.emit(&"stilling_pin")

	if stilling_pin_pickup != null:
		stilling_pin_pickup.queue_free()


func inspect_dry_fountain() -> void:
	if event_state.fountain_state == AshBellEventState.FountainState.ABSENT:
		event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)

	event_state.add_silence_pressure(3, &"fountain_touched")
	event_state.unlock_knowledge(&"ash_bell_dry_fountain")
	request_dialogue.emit(dialogue_id, &"inspect_fountain")


func set_stilling_pin() -> void:
	if not event_state.has_stilling_pin:
		return

	event_state.set_resolution(AshBellEventState.Resolution.SET_STILLING_PIN)
	event_state.add_silence_pressure(35, &"stilling_pin_set")
	request_dialogue.emit(dialogue_id, &"set_stilling_pin")
	_show_unarrived_apparition()
	_trigger_ghost_procession()


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

	if event_state.ritualant_hostile:
		return

	if event_state.resolution == AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
			or event_state.resolution == AshBellEventState.Resolution.TOUCHED_THREAD \
			or event_state.resolution == AshBellEventState.Resolution.TOOK_STILLING_PIN:
		if peaceful_exit_requires_thread_touch and not event_state.has_thread_knot:
			return

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
		fountain_ring.visible = event_state.fountain_state != AshBellEventState.FountainState.ABSENT
		match event_state.fountain_state:
			AshBellEventState.FountainState.GHOST:
				fountain_ring.modulate = Color(0.55, 0.72, 1.0, lerpf(0.35, 0.75, pressure))
			AshBellEventState.FountainState.BLACK_WATER:
				fountain_ring.modulate = Color(0.05, 0.08, 0.12, lerpf(0.65, 1.0, pressure))
			AshBellEventState.FountainState.CRACKED_ANCHORED:
				fountain_ring.modulate = Color(0.95, 0.82, 0.42, 0.8)
			_:
				fountain_ring.modulate.a = 0.0

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
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	if inventory_manager != null and inventory_manager.has_method("add_item"):
		inventory_manager.call("add_item", item_id, 1)
		print("[AshBell] item granted to inventory: ", item_id)
	else:
		print("[AshBell] InventoryManager not available, item grant skipped: ", item_id)


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
