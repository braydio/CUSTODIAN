class_name AshBellInteractable
extends Area2D

enum InteractionKind {
	RITUALANT,
	ASK_BELL,
	ASK_THREAD,
	ASK_ORRA,
	TOUCH_THREAD,
	CUT_THREAD,
	TAKE_STILLING_PIN,
	DRY_FOUNTAIN,
	SET_STILLING_PIN,
}

@export var interaction_kind: int = InteractionKind.RITUALANT
@export var site_path: NodePath
@export var interaction_distance: float = 84.0
@export var prompt_text: String = ""

## If true, child visuals under this Area2D are hidden while the interaction is locked.
@export var hide_when_locked: bool = true

## If true, the Area2D stops being detectable while locked.
@export var disable_monitorable_when_locked: bool = true

@onready var site: ForlornRitualantSite = get_node_or_null(site_path)

var _refresh_timer: float = 0.0
var _last_available: bool = true


func _ready() -> void:
	add_to_group("interactable")
	_refresh_availability(true)


func _process(delta: float) -> void:
	_refresh_timer = maxf(0.0, _refresh_timer - delta)
	if _refresh_timer > 0.0:
		return

	_refresh_timer = 0.12
	_refresh_availability(false)


func can_interact(_actor: Node = null) -> bool:
	if site == null or site.event_state == null:
		return false

	var state := site.event_state

	match interaction_kind:
		InteractionKind.RITUALANT:
			return not state.ritualant_hostile \
				and state.resolution < AshBellEventState.Resolution.PROVOKED_RITUALANT

		InteractionKind.ASK_BELL, InteractionKind.ASK_THREAD, InteractionKind.ASK_ORRA:
			return state.resolution >= AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
				and not state.ritualant_hostile

		InteractionKind.TOUCH_THREAD:
			return state.resolution >= AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
				and not state.has_thread_knot \
				and not state.ritualant_hostile

		InteractionKind.CUT_THREAD:
			return state.resolution >= AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
				and not state.ritualant_hostile \
				and state.resolution != AshBellEventState.Resolution.CUT_THREAD

		InteractionKind.TAKE_STILLING_PIN:
			return state.resolution >= AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
				and not state.has_stilling_pin

		InteractionKind.DRY_FOUNTAIN:
			return state.resolution >= AshBellEventState.Resolution.SEEN \
				and state.fountain_state != AshBellEventState.FountainState.BLACK_WATER

		InteractionKind.SET_STILLING_PIN:
			return state.has_stilling_pin \
				and state.resolution >= AshBellEventState.Resolution.TOOK_STILLING_PIN \
				and state.resolution != AshBellEventState.Resolution.SET_STILLING_PIN

		_:
			return true


func get_interaction_prompt() -> String:
	if not can_interact():
		return ""

	if not prompt_text.strip_edges().is_empty():
		return prompt_text

	match interaction_kind:
		InteractionKind.RITUALANT:
			return "LISTEN TO FORLORN-RITUALANT"
		InteractionKind.ASK_BELL:
			return "ASK: BELL?"
		InteractionKind.ASK_THREAD:
			return "ASK: THREAD?"
		InteractionKind.ASK_ORRA:
			return "ASK: ORRA?"
		InteractionKind.TOUCH_THREAD:
			return "TOUCH WHITE THREAD"
		InteractionKind.CUT_THREAD:
			return "CUT WHITE THREAD"
		InteractionKind.TAKE_STILLING_PIN:
			return "TAKE STILLING PIN"
		InteractionKind.DRY_FOUNTAIN:
			return "INSPECT DRY FOUNTAIN"
		InteractionKind.SET_STILLING_PIN:
			return "SET PIN IN BASIN"
		_:
			return "INTERACT"


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	if site == null:
		push_warning("AshBellInteractable has no site reference.")
		return

	if not can_interact(actor):
		return

	match interaction_kind:
		InteractionKind.RITUALANT:
			site.interact_with_ritualant()

		InteractionKind.ASK_BELL:
			site.ask_about_bell()

		InteractionKind.ASK_THREAD:
			site.ask_about_thread()

		InteractionKind.ASK_ORRA:
			site.ask_about_orra()

		InteractionKind.TOUCH_THREAD:
			site.touch_thread()

		InteractionKind.CUT_THREAD:
			site.cut_thread()

		InteractionKind.TAKE_STILLING_PIN:
			site.take_stilling_pin()

		InteractionKind.DRY_FOUNTAIN:
			site.inspect_dry_fountain()

		InteractionKind.SET_STILLING_PIN:
			site.set_stilling_pin()


func _refresh_availability(force: bool) -> void:
	var available := can_interact()
	if not force and available == _last_available:
		return

	_last_available = available

	if disable_monitorable_when_locked:
		monitorable = available
		monitoring = true

	if hide_when_locked:
		for child in get_children():
			if child is CanvasItem:
				(child as CanvasItem).visible = available
