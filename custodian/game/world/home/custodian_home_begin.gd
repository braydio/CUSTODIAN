extends Node2D
class_name CustodianHomeBegin

const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")

@onready var operator_ref: Node2D = get_node_or_null("World/Operator") as Node2D
@onready var terminal: Node2D = get_node_or_null("World/FieldTerminal") as Node2D
@onready var hud: Node = get_node_or_null("CustodianHUD")
@onready var signal_needle: Line2D = get_node_or_null("World/SignalNeedle") as Line2D

var _witness_established := false
var _last_signal_band := -1


func _ready() -> void:
	if terminal != null:
		if terminal.has_signal("witness_established"):
			terminal.connect("witness_established", _on_witness_established)
		if terminal.has_signal("terminal_access_requested"):
			terminal.connect("terminal_access_requested", _on_terminal_access_requested)
	_configure_hud()
	_update_signal_state(true)


func _process(_delta: float) -> void:
	_update_signal_state(false)
	_update_prompt()
	_update_signal_needle()


func _configure_hud() -> void:
	if hud == null:
		return
	hud.call("set_location", "ROAD OF WITNESSES")
	hud.set_phase("LOCAL WAKE")
	hud.set_objective("Trace the Custodian frequency")
	hud.set_minimap_visible(true)
	hud.set_debug_overlay_visible(false)
	hud.call("set_status_line", "key", Catalog.ICON_OBJECTIVE, "WITNESS: ABSENT", Palette.MUTED_TEXT)
	hud.call("set_status_line", "gate", Catalog.ICON_HAZARD, "PROVENANCE: DAMAGED", Palette.DANGER)
	hud.call("set_status_line", "return", Catalog.COMPASS_ROSE_SMALL, "SCAN: PASSIVE", Palette.BLUE_TECH)


func _update_signal_state(force: bool) -> void:
	if hud == null or operator_ref == null or terminal == null:
		return
	if _witness_established:
		if force or _last_signal_band != 4:
			_last_signal_band = 4
			hud.set_phase("WITNESS ESTABLISHED")
			hud.set_objective("Stabilize the terminal")
			hud.call("set_status_line", "key", Catalog.ICON_OBJECTIVE, "WITNESS: ESTABLISHED", Palette.GREEN_SIGNAL)
			hud.call("set_status_line", "gate", Catalog.ICON_KEY_ITEM, "ARCHIVE: PARTIAL", Palette.GOLD_TEXT)
			hud.call("set_status_line", "return", Catalog.COMPASS_ROSE_SMALL, "LOCAL SCAN: UNLOCKED", Palette.BLUE_TECH)
			hud.set_debug_text("CUSTODIAN FIELD TERMINAL LOCATED.\nARCHIVE LINK: PARTIAL\nLOCAL COMMAND: DEGRADED\nNEW DIRECTIVE: STABILIZE THE TERMINAL.")
		return

	var distance := operator_ref.global_position.distance_to(terminal.global_position)
	var band := _get_signal_band(distance)
	if not force and band == _last_signal_band:
		return
	_last_signal_band = band
	match band:
		0:
			hud.set_phase("LOCAL WAKE")
			hud.set_objective("Trace the Custodian frequency")
			hud.call("set_status_line", "key", Catalog.ICON_OBJECTIVE, "SIGNAL MATCH: 18%", Palette.MUTED_TEXT)
			hud.call("set_status_line", "gate", Catalog.ICON_HAZARD, "INTERFERENCE: HIGH", Palette.DANGER)
			hud.call("set_status_line", "return", Catalog.COMPASS_ROSE_SMALL, "SOURCE: NEAR", Palette.BLUE_TECH)
		1:
			hud.set_phase("SIGNAL TRACKING")
			hud.set_objective("Continue tracking the frequency")
			hud.call("set_status_line", "key", Catalog.ICON_OBJECTIVE, "SIGNAL MATCH: 43%", Palette.GOLD_TEXT)
			hud.call("set_status_line", "gate", Catalog.ICON_HAZARD, "SOURCE: STATIONARY", Palette.GOLD_TEXT)
			hud.call("set_status_line", "return", Catalog.COMPASS_ROSE_SMALL, "AUTH: REQUESTED", Palette.BLUE_TECH)
		2:
			hud.set_phase("PROVENANCE ECHO")
			hud.set_objective("Follow the damaged authority carrier")
			hud.call("set_status_line", "key", Catalog.ICON_OBJECTIVE, "SIGNAL MATCH: 71%", Palette.GOLD_TEXT)
			hud.call("set_status_line", "gate", Catalog.ICON_HAZARD, "LOCATION: AHEAD / BELOW / PRIOR", Palette.DANGER)
			hud.call("set_status_line", "return", Catalog.COMPASS_ROSE_SMALL, "SOURCE ID: PARTIAL", Palette.BLUE_TECH)
		_:
			hud.set_phase("TERMINAL CONTACT")
			hud.set_objective("Approach and establish witness contact")
			hud.call("set_status_line", "key", Catalog.ICON_OBJECTIVE, "SIGNAL MATCH: 94%", Palette.GREEN_SIGNAL)
			hud.call("set_status_line", "gate", Catalog.ICON_KEY_ITEM, "REQUEST: WITNESS", Palette.GOLD_TEXT)
			hud.call("set_status_line", "return", Catalog.COMPASS_ROSE_SMALL, "AUTHORITY: PARTIAL", Palette.BLUE_TECH)


func _get_signal_band(distance: float) -> int:
	if distance > 620.0:
		return 0
	if distance > 360.0:
		return 1
	if distance > 150.0:
		return 2
	return 3


func _update_prompt() -> void:
	if hud == null or terminal == null or operator_ref == null:
		return
	var target: Node = null
	if "interaction_target" in operator_ref:
		target = operator_ref.get("interaction_target")
	if target != terminal:
		return
	var input_hint := _get_interact_prompt_key()
	if _witness_established:
		hud.show_interaction(
			"CUSTODIAN TERMINAL",
			"Basic archive access is partial",
			input_hint,
			Catalog.ICON_OBJECTIVE
		)
	else:
		hud.show_interaction(
			"CUSTODIAN FIELD TERMINAL",
			"Establish witness contact",
			input_hint,
			Catalog.ICON_OBJECTIVE
		)


func _update_signal_needle() -> void:
	if signal_needle == null or operator_ref == null or terminal == null:
		return
	signal_needle.visible = not _witness_established
	if _witness_established:
		return
	var direction := operator_ref.global_position.direction_to(terminal.global_position)
	var origin := operator_ref.global_position + Vector2(0.0, -34.0)
	signal_needle.clear_points()
	signal_needle.add_point(origin)
	signal_needle.add_point(origin + direction * 42.0)
	signal_needle.modulate.a = 0.35 + 0.35 * absf(sin(float(Engine.get_process_frames()) * 0.08))


func _on_witness_established(_actor: Node) -> void:
	_witness_established = true
	_update_signal_state(true)
	if hud != null:
		hud.show_interaction(
			"WITNESS ACCEPTED",
			"Archive link partial. Restore local power.",
			_get_interact_prompt_key(),
			Catalog.ICON_OBJECTIVE
		)


func _on_terminal_access_requested(_actor: Node) -> void:
	if hud != null:
		hud.set_debug_overlay_visible(false)
		hud.show_interaction(
			"ARCHIVE PARTIAL",
			"Memory damaged. Restore terminal subsystems.",
			_get_interact_prompt_key(),
			Catalog.ICON_OBJECTIVE
		)
		hud.call("set_status_line", "gate", Catalog.ICON_KEY_ITEM, "ARCHIVE: DAMAGED", Palette.GOLD_TEXT)


func get_beginning_state() -> Dictionary:
	return {
		"witness_established": _witness_established,
		"signal_band": _last_signal_band,
		"objective": "Stabilize the terminal" if _witness_established else "Trace the Custodian frequency",
	}


func _get_interact_prompt_key() -> String:
	if not InputMap.has_action("interact"):
		return "G"
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			return OS.get_keycode_string(key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode)
	return "G"
