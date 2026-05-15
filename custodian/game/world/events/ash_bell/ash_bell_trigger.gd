class_name AshBellTrigger
extends Area2D

enum TriggerKind {
	INTRO,
	FOUNTAIN,
	EXIT,
	GHOST_PROCESSION,
}

@export var trigger_kind: int = TriggerKind.INTRO
@export var site_path: NodePath

@onready var site: BellKneelerSite = get_node_or_null(site_path)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if site == null or body == null or not body.is_in_group("player"):
		return

	match trigger_kind:
		TriggerKind.INTRO:
			site.trigger_intro()
		TriggerKind.FOUNTAIN:
			site.set_player_inside_fountain(true)
		TriggerKind.EXIT:
			site.exit_site()
		TriggerKind.GHOST_PROCESSION:
			site.event_state.add_silence_pressure(5, &"procession_lane_crossed")


func _on_body_exited(body: Node) -> void:
	if site == null or body == null or not body.is_in_group("player"):
		return
	if trigger_kind == TriggerKind.FOUNTAIN:
		site.set_player_inside_fountain(false)
