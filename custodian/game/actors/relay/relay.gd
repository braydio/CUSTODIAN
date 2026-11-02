extends Node2D
class_name RelayNode

enum Status { UNKNOWN, LOCATED, UNSTABLE, STABLE, WEAK, DORMANT }
enum RiskProfile { TRANSIT, FRINGE, CORE }

@export var relay_id: StringName = &"R_NORTH"
@export var sector_id: StringName = &"T_NORTH"
@export var status: Status = Status.UNKNOWN
@export var stability: float = 40.0
@export var stability_ticks_required: int = 3
@export var risk_profile: RiskProfile = RiskProfile.TRANSIT
@export var last_stabilized_time: int = -1
@export var is_interactable: bool = false
@export var current_signal_strength: float = 0.0
@export_range(24.0, 160.0, 1.0) var interaction_distance: float = 86.0

@onready var mast: Polygon2D = get_node_or_null("Mast") as Polygon2D
@onready var base: Polygon2D = get_node_or_null("Base") as Polygon2D
@onready var signal_indicator: Node = get_node_or_null("SignalIndicator")
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label

var _network_scanned: bool = false
var _last_prompt: String = ""


func _ready() -> void:
	add_to_group("arrn_relay")
	add_to_group("interactable")
	_register_with_manager()
	_apply_visual_state()


func _exit_tree() -> void:
	var manager := _get_arrn_manager()
	if manager != null and manager.has_method("unregister_relay_entity"):
		manager.call("unregister_relay_entity", relay_id, self)


func apply_arrn_state(snapshot: Dictionary, network_scanned: bool) -> void:
	_network_scanned = network_scanned
	sector_id = StringName(str(snapshot.get("sector_id", String(sector_id))))
	status = _status_from_string(str(snapshot.get("raw_status", snapshot.get("status", "UNKNOWN"))))
	stability = float(snapshot.get("stability", stability))
	stability_ticks_required = int(snapshot.get("stability_ticks_required", stability_ticks_required))
	last_stabilized_time = int(snapshot.get("last_stabilized_time", last_stabilized_time))
	is_interactable = bool(snapshot.get("is_interactable", is_interactable))
	current_signal_strength = float(snapshot.get("current_signal_strength", current_signal_strength))
	visible = bool(snapshot.get("visible", network_scanned))
	_apply_visual_state()


func get_interaction_prompt() -> String:
	var manager := _get_arrn_manager()
	if manager == null:
		return ""
	if not _network_scanned:
		return "SCAN RELAYS AT COMMAND"
	if manager.has_method("can_stabilize"):
		var check: Dictionary = manager.call("can_stabilize", relay_id)
		if not bool(check.get("ok", false)):
			var reason := str(check.get("reason", "UNAVAILABLE"))
			if reason == "ALREADY_STABLE":
				return "RELAY %s STABLE (%d%%)" % [String(relay_id), int(round(stability))]
			if reason == "TASK_ACTIVE":
				return "STABILIZING %s" % String(relay_id)
			return "RELAY %s %s" % [String(relay_id), reason]
	return "%s STABILIZE RELAY %s (%d/%d TICKS)" % [
		_get_interact_prompt_key(),
		String(relay_id),
		0,
		stability_ticks_required,
	]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	var manager := _get_arrn_manager()
	if manager == null or not manager.has_method("start_stabilization"):
		return
	var result: Dictionary = manager.call("start_stabilization", relay_id, actor)
	_last_prompt = str(result.get("reason", ""))
	_apply_visual_state()


func _register_with_manager() -> void:
	var manager := _get_arrn_manager()
	if manager == null:
		return
	if manager.has_method("register_relay_entity"):
		manager.call("register_relay_entity", relay_id, self)
	if manager.has_method("set_relay_world_position"):
		manager.call("set_relay_world_position", relay_id, global_position)


func _apply_visual_state() -> void:
	var color := _status_color()
	if mast != null:
		mast.color = color
	if base != null:
		base.color = color.darkened(0.25)
	if signal_indicator != null and signal_indicator.has_method("set_signal"):
		signal_indicator.call("set_signal", current_signal_strength, color)
	if prompt_label != null:
		prompt_label.text = String(relay_id)
		prompt_label.modulate = color


func _status_color() -> Color:
	match status:
		Status.UNKNOWN:
			return Color(0.4, 0.4, 0.4, 0.5)
		Status.LOCATED:
			return Color(1.0, 0.8, 0.0, 0.92)
		Status.UNSTABLE:
			return Color(1.0, 0.4, 0.0, 0.92)
		Status.STABLE:
			return Color(0.0, 1.0, 0.35, 0.94)
		Status.WEAK:
			return Color(1.0, 0.6, 0.0, 0.88)
		Status.DORMANT:
			return Color(1.0, 0.0, 0.0, 0.82)
		_:
			return Color(0.4, 0.4, 0.4, 0.5)


func _status_from_string(value: String) -> Status:
	match value.strip_edges().to_upper():
		"LOCATED":
			return Status.LOCATED
		"UNSTABLE":
			return Status.UNSTABLE
		"STABLE":
			return Status.STABLE
		"WEAK":
			return Status.WEAK
		"DORMANT":
			return Status.DORMANT
		_:
			return Status.UNKNOWN


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return "PRESS %s TO" % OS.get_keycode_string(keycode)
	return "INTERACT TO"


func _get_arrn_manager() -> Node:
	return get_node_or_null("/root/ARRNManager")
