extends Control

const IntelDemoStateScript := preload("res://game/systems/intel/intel_demo_state.gd")

var demo_state: IntelDemoState

var _header_label: Label
var _truth_box: VBoxContainer
var _projection_box: VBoxContainer
var _transcript: RichTextLabel


func _ready() -> void:
	demo_state = IntelDemoStateScript.new()
	_build_ui()
	_refresh()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16.0
	root.offset_top = 16.0
	root.offset_right = -16.0
	root.offset_bottom = -16.0
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	_header_label = Label.new()
	_header_label.text = "CUSTODIAN // INTEL DEMO"
	_header_label.add_theme_font_size_override("font_size", 18)
	root.add_child(_header_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	root.add_child(button_row)

	_add_button(button_row, "STEP INCIDENT", _on_step_pressed)
	_add_button(button_row, "CYCLE FIDELITY", _on_cycle_fidelity_pressed)
	_add_button(button_row, "DAMAGE COMMS", _on_damage_comms_pressed)
	_add_button(button_row, "REPAIR COMMS", _on_repair_comms_pressed)
	_add_button(button_row, "RESET", _on_reset_pressed)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 12)
	root.add_child(split)

	_truth_box = VBoxContainer.new()
	_truth_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_truth_box)

	_projection_box = VBoxContainer.new()
	_projection_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_projection_box)

	_transcript = RichTextLabel.new()
	_transcript.custom_minimum_size = Vector2(0, 150)
	_transcript.fit_content = false
	_transcript.scroll_following = true
	root.add_child(_transcript)


func _add_button(parent: Control, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(callback)
	parent.add_child(button)


func _refresh() -> void:
	_header_label.text = demo_state.get_header_text()
	_render_sector_table(
		_truth_box,
		"DEV TRUTH — ACTUAL SIMULATION STATE",
		demo_state.get_truth_sectors(),
		true
	)
	_render_sector_table(
		_projection_box,
		"PLAYER PROJECTION — WHAT COMMAND CAN KNOW",
		demo_state.get_projected_sectors(),
		false
	)


func _render_sector_table(parent: VBoxContainer, title: String, sectors: Array, is_truth: bool) -> void:
	for child in parent.get_children():
		child.queue_free()

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(title_label)

	var header := Label.new()
	header.text = _format_header(is_truth)
	header.add_theme_font_size_override("font_size", 12)
	parent.add_child(header)

	for sector in sectors:
		if not (sector is Dictionary):
			continue
		var row := RichTextLabel.new()
		row.bbcode_enabled = false
		row.fit_content = true
		row.custom_minimum_size = Vector2(0, 42)
		row.text = _format_sector_row(sector, is_truth)
		parent.add_child(row)


func _format_header(is_truth: bool) -> String:
	if is_truth:
		return "SECTOR | INTEGRITY | POWER | HOSTILES | ACTIVITY | OBJECTIVE | ETA"
	return "SECTOR | INTEGRITY | POWER | HOSTILES | ACTIVITY | OBJECTIVE | ETA | CONF"


func _format_sector_row(sector: Dictionary, is_truth: bool) -> String:
	if is_truth:
		return "%s | %s%% | %s | %s | %s | %s | %s" % [
			sector.get("name", ""),
			str(sector.get("integrity", "")),
			sector.get("power", ""),
			str(sector.get("hostiles", "")),
			sector.get("activity", ""),
			sector.get("objective", ""),
			_format_truth_eta(int(sector.get("eta", -1))),
		]

	return "%s | %s | %s | %s | %s | %s | %s | %s" % [
		sector.get("name", ""),
		sector.get("integrity", ""),
		sector.get("power", ""),
		sector.get("hostiles", ""),
		sector.get("activity", ""),
		sector.get("objective", ""),
		sector.get("eta", ""),
		sector.get("confidence", ""),
	]


func _format_truth_eta(seconds: int) -> String:
	if seconds < 0:
		return "NONE"
	return "%ds" % seconds


func _write_log(message: String) -> void:
	_transcript.append_text("[%03d] %s\n" % [demo_state.tick, message])


func _on_step_pressed() -> void:
	demo_state.advance_step()
	_write_log("INCIDENT STEP ADVANCED. PROJECTION UPDATED FROM SAME TRUTH.")
	_refresh()


func _on_cycle_fidelity_pressed() -> void:
	demo_state.cycle_fidelity()
	_write_log("FIDELITY SET TO %s." % IntelProjector.fidelity_label(demo_state.fidelity))
	_refresh()


func _on_damage_comms_pressed() -> void:
	demo_state.damage_comms()
	_write_log("COMMS DEGRADED. TRUTH UNCHANGED. PROJECTION REDUCED.")
	_refresh()


func _on_repair_comms_pressed() -> void:
	demo_state.repair_comms()
	_write_log("COMMS PARTIALLY RESTORED. PROJECTION CLARITY IMPROVED.")
	_refresh()


func _on_reset_pressed() -> void:
	demo_state.reset()
	_transcript.clear()
	_write_log("DEMO RESET.")
	_refresh()
