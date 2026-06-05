extends Control

const PANEL_BG := Color("#070909ee")
const PANEL_EDGE := Color("#8a6f3d")
const PANEL_EDGE_DIM := Color("#4d412b")
const TEXT_GOLD := Color("#d4b56a")
const TEXT_BODY := Color("#d6d1bf")
const TEXT_MUTED := Color("#8f8a7d")
const TEXT_DANGER := Color("#c94d42")
const TEXT_SIGNAL := Color("#38d6e8")

var _tabs: TabContainer
var _summary_label: Label
var _runtime_label: Label
var _player_label: Label
var _combat_label: Label
var _world_label: Label
var _systems_label: Label
var _inventory_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_ensure_built()
	visible = false


func set_debug_visible(p_visible: bool) -> void:
	_ensure_built()
	visible = p_visible
	if visible and is_inside_tree():
		call_deferred("grab_focus")


func is_debug_visible() -> bool:
	return visible


func update_snapshot(snapshot: Dictionary) -> void:
	_ensure_built()
	if not visible:
		return
	_summary_label.text = str(snapshot.get("summary", "No snapshot."))
	_runtime_label.text = _format_section(snapshot.get("runtime", {}))
	_player_label.text = _format_section(snapshot.get("player", {}))
	_combat_label.text = _format_section(snapshot.get("combat", {}))
	_world_label.text = _format_section(snapshot.get("world", {}))
	_systems_label.text = _format_section(snapshot.get("systems", {}))
	_inventory_label.text = _format_section(snapshot.get("inventory", {}))


func _build() -> void:
	if _tabs != null:
		return
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.0, 0.0, 0.0, 0.46)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var root := MarginContainer.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	stack.add_child(header)

	var title := Label.new()
	title.name = "Title"
	title.text = "DEBUG SCREEN"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label(title, TEXT_GOLD, 18, true)
	header.add_child(title)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "F12 / debug_hud toggles"
	_apply_label(hint, TEXT_MUTED, 12, false)
	header.add_child(hint)

	_summary_label = Label.new()
	_summary_label.name = "Summary"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label(_summary_label, TEXT_SIGNAL, 12, false)
	stack.add_child(_summary_label)

	_tabs = TabContainer.new()
	_tabs.name = "Tabs"
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_color_override("font_selected_color", TEXT_GOLD)
	_tabs.add_theme_color_override("font_unselected_color", TEXT_MUTED)
	stack.add_child(_tabs)

	_runtime_label = _add_tab("Runtime")
	_player_label = _add_tab("Player")
	_combat_label = _add_tab("Combat")
	_world_label = _add_tab("World")
	_systems_label = _add_tab("Systems")
	_inventory_label = _add_tab("Inventory")


func _ensure_built() -> void:
	if _tabs == null:
		_build()


func _add_tab(tab_name: String) -> Label:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	var label := Label.new()
	label.name = "%sReadout" % tab_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label(label, TEXT_BODY, 12, false)
	scroll.add_child(label)
	return label


func _format_section(value: Variant) -> String:
	if value is Dictionary:
		var lines: Array[String] = []
		for key in (value as Dictionary).keys():
			lines.append("%s: %s" % [str(key).capitalize(), _format_value((value as Dictionary)[key])])
		return "\n".join(lines) if not lines.is_empty() else "No data."
	if value is Array:
		var array_lines: Array[String] = []
		for item in value:
			array_lines.append("- %s" % _format_value(item))
		return "\n".join(array_lines) if not array_lines.is_empty() else "No data."
	return _format_value(value)


func _format_value(value: Variant) -> String:
	if value is float:
		return "%.2f" % float(value)
	if value is Vector2:
		var vec := value as Vector2
		return "(%.1f, %.1f)" % [vec.x, vec.y]
	if value is Dictionary:
		return JSON.stringify(value)
	if value is Array:
		return JSON.stringify(value)
	return str(value)


func _apply_label(label: Label, color: Color, size: int, bold: bool) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	if bold:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color("#000000aa"))


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_EDGE
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color("#00000099")
	style.shadow_size = 10
	return style
