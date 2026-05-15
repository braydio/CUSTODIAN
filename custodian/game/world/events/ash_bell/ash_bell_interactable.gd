class_name AshBellInteractable
extends Area2D

enum InteractionKind {
	KNEELER,
	ASK_BELL,
	ASK_THREAD,
	ASK_ORRA,
	TOUCH_THREAD,
	CUT_THREAD,
	TAKE_CLAPPER,
	DRY_FOUNTAIN,
	RING_CLAPPER,
}

@export var interaction_kind: int = InteractionKind.KNEELER
@export var site_path: NodePath
@export var interaction_distance: float = 84.0
@export var prompt_text: String = ""

@onready var site: BellKneelerSite = get_node_or_null(site_path)


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_prompt() -> String:
	if not prompt_text.strip_edges().is_empty():
		return prompt_text
	match interaction_kind:
		InteractionKind.KNEELER:
			return "LISTEN TO BELL-KNEELER"
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
		InteractionKind.TAKE_CLAPPER:
			return "TAKE BELL-CLAPPER"
		InteractionKind.DRY_FOUNTAIN:
			return "INSPECT DRY FOUNTAIN"
		InteractionKind.RING_CLAPPER:
			return "RING SILENCE"
		_:
			return "INTERACT"


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(_actor: Node) -> void:
	if site == null:
		push_warning("AshBellInteractable has no site reference.")
		return

	match interaction_kind:
		InteractionKind.KNEELER:
			site.interact_with_kneeler()
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
		InteractionKind.TAKE_CLAPPER:
			site.take_clapper()
		InteractionKind.DRY_FOUNTAIN:
			site.event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)
			site.event_state.add_silence_pressure(3, &"fountain_touched")
		InteractionKind.RING_CLAPPER:
			site.event_state.set_resolution(AshBellEventState.Resolution.RANG_SILENCE)
			site.event_state.add_silence_pressure(35, &"rang_silence")
			site.call("_show_unarrived_apparition")
