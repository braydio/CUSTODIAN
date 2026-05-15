class_name AshBellEventState
extends Resource

signal pressure_changed(silence_pressure: int, thread_tension: int)
signal fountain_state_changed(new_state: int)
signal resolution_changed(new_resolution: int)
signal knowledge_unlocked(knowledge_id: StringName)

enum FountainState {
	ABSENT,
	GHOST,
	BLACK_WATER,
	CRACKED_ANCHORED,
}

enum Resolution {
	UNSEEN,
	SEEN,
	SPOKE_TO_KNEELER,
	TOUCHED_THREAD,
	TOOK_CLAPPER,
	CUT_THREAD,
	RANG_SILENCE,
	PROVOKED_KNEELER,
	KNEELER_DISSOLVED,
	SITE_STABILIZED,
	SITE_DEFILED,
}

@export var silence_pressure: int = 0
@export var thread_tension: int = 0
@export var fountain_state: int = FountainState.ABSENT
@export var resolution: int = Resolution.UNSEEN

var seen_dialogue: Dictionary = {}
var unlocked_knowledge: Dictionary = {}
var has_clapper: bool = false
var has_thread_knot: bool = false
var apparition_seen: bool = false
var kneeler_hostile: bool = false


func add_silence_pressure(amount: int, reason: StringName = &"unknown") -> void:
	if amount == 0:
		return

	var previous := silence_pressure
	silence_pressure = clampi(silence_pressure + amount, 0, 100)
	if silence_pressure == previous:
		return

	pressure_changed.emit(silence_pressure, thread_tension)
	_apply_pressure_thresholds(reason)


func add_thread_tension(amount: int, reason: StringName = &"unknown") -> void:
	if amount == 0:
		return

	var previous := thread_tension
	thread_tension = clampi(thread_tension + amount, 0, 100)
	if thread_tension != previous:
		pressure_changed.emit(silence_pressure, thread_tension)

	if thread_tension >= 100:
		set_resolution(Resolution.CUT_THREAD)
		add_silence_pressure(25, &"thread_snap")


func calm_thread(amount: int) -> void:
	if amount <= 0:
		return

	var previous := thread_tension
	thread_tension = clampi(thread_tension - amount, 0, 100)
	if thread_tension != previous:
		pressure_changed.emit(silence_pressure, thread_tension)


func mark_dialogue_seen(node_id: StringName) -> void:
	seen_dialogue[node_id] = true


func has_seen_dialogue(node_id: StringName) -> bool:
	return bool(seen_dialogue.get(node_id, false))


func unlock_knowledge(knowledge_id: StringName) -> void:
	if bool(unlocked_knowledge.get(knowledge_id, false)):
		return

	unlocked_knowledge[knowledge_id] = true
	knowledge_unlocked.emit(knowledge_id)


func set_fountain_state(new_state: int) -> void:
	if fountain_state == new_state:
		return

	fountain_state = new_state
	fountain_state_changed.emit(fountain_state)


func set_resolution(new_resolution: int) -> void:
	if resolution == new_resolution:
		return

	resolution = new_resolution
	resolution_changed.emit(resolution)


func _apply_pressure_thresholds(_reason: StringName) -> void:
	if silence_pressure >= 60 and fountain_state < FountainState.BLACK_WATER:
		set_fountain_state(FountainState.BLACK_WATER)
	elif silence_pressure >= 45 and fountain_state < FountainState.GHOST:
		set_fountain_state(FountainState.GHOST)

	if silence_pressure >= 90 and not kneeler_hostile:
		kneeler_hostile = true
		set_resolution(Resolution.PROVOKED_KNEELER)
