class_name CustodianHUD
extends CanvasLayer

const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")
const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")

@onready var location_title: Label = get_node_or_null("Root/TopLeftPanel/Margin/Content/LocationTitle")
@onready var phase_label: Label = get_node_or_null("Root/TopLeftPanel/Margin/Content/PhaseLabel")
@onready var objective_summary: Label = get_node_or_null("Root/TopLeftPanel/Margin/Content/ObjectiveSummary")
@onready var vitals_header: PanelContainer = get_node_or_null("Root/TopCenterVitals")
@onready var health_label: Label = get_node_or_null("Root/TopCenterVitals/Margin/Content/HealthLabel")
@onready var health_bar: ProgressBar = get_node_or_null("Root/TopCenterVitals/Margin/Content/HealthBar")
@onready var stamina_label: Label = get_node_or_null("Root/TopCenterVitals/Margin/Content/StaminaLabel")
@onready var minimap_frame: Node = get_node_or_null("Root/TopRightPanel/Margin/BlackReliquaryMinimapFrame")
@onready var prompt: Node = get_node_or_null("Root/BottomLeftPrompt/BlackReliquaryPrompt")
@onready var key_item_status: Node = get_node_or_null("Root/BottomRightStatus/Margin/Content/KeyItemStatus")
@onready var gate_status: Node = get_node_or_null("Root/BottomRightStatus/Margin/Content/GateStatus")
@onready var return_mooring_status: Node = get_node_or_null("Root/BottomRightStatus/Margin/Content/ReturnMooringStatus")
@onready var debug_overlay: Panel = get_node_or_null("Root/DebugOverlay")
@onready var debug_label: Label = get_node_or_null("Root/DebugOverlay/Margin/DebugLabel")

var _health_current := 100
var _health_max := 100
var _last_prompt_frame := -1
var _context_active := true
var _externally_suppressed := false


func _ready() -> void:
	add_to_group("custodian_hud")
	add_to_group("gameplay_overlay")
	_apply_theme()
	set_health(100, 100)
	set_stamina_label("STA READY")
	set_phase("FREE ROAM PREP")
	set_objective("Open the main gate")
	set_key_item_status(false)
	set_main_gate_status(false, true)
	set_return_mooring_status(true, true)
	set_debug_overlay_visible(false)
	hide_interaction()


func _process(_delta: float) -> void:
	_refresh_operator_status()
	if prompt != null and visible and _last_prompt_frame >= 0 and Engine.get_process_frames() - _last_prompt_frame > 2:
		hide_interaction()


func set_health(current: int, max_value: int) -> void:
	_health_current = max(0, current)
	_health_max = max(1, max_value)
	if health_label != null:
		health_label.text = "%d/%d" % [_health_current, _health_max]
		var ratio := float(_health_current) / float(_health_max)
		if ratio <= 0.3:
			health_label.add_theme_color_override("font_color", Palette.DANGER)
		elif ratio <= 0.6:
			health_label.add_theme_color_override("font_color", Palette.GOLD_TEXT)
		else:
			health_label.add_theme_color_override("font_color", Palette.BODY_TEXT)
	if health_bar != null:
		health_bar.max_value = 100.0
		health_bar.value = clampf((float(_health_current) / float(_health_max)) * 100.0, 0.0, 100.0)


func set_stamina_label(text: String) -> void:
	if stamina_label != null:
		stamina_label.text = text


func set_location(text: String) -> void:
	if location_title != null:
		location_title.text = "Location: %s" % text


func set_phase(text: String) -> void:
	if phase_label != null:
		phase_label.text = "Phase: %s" % text


func set_objective(text: String) -> void:
	if objective_summary != null:
		objective_summary.text = "Objective: %s" % text


func show_interaction(title: String, body: String, input_hint: String = "G", icon_path: String = "") -> void:
	_last_prompt_frame = Engine.get_process_frames()
	if prompt != null:
		prompt.call("show_prompt", title, body, input_hint, icon_path)


func hide_interaction() -> void:
	_last_prompt_frame = -1
	if prompt != null:
		prompt.call("hide_prompt")


func set_key_item_status(has_key: bool, item_name: String = "Sundered Gate Key") -> void:
	if key_item_status != null:
		var text := "%s: %s" % [item_name, "HELD" if has_key else "MISSING"]
		key_item_status.call("configure", Catalog.ICON_KEY_ITEM, text, Vector2(24, 24), Palette.GREEN_SIGNAL if has_key else Palette.MUTED_TEXT)


func set_main_gate_status(open: bool, locked: bool) -> void:
	if gate_status != null:
		var text := "MAIN GATE: OPEN" if open else ("MAIN GATE: LOCKED" if locked else "MAIN GATE: READY")
		var icon: String = Catalog.ICON_GATE_OPEN if open else Catalog.ICON_GATE_LOCKED
		var color: Color = Palette.GREEN_SIGNAL if open else (Palette.DANGER if locked else Palette.GOLD_TEXT)
		gate_status.call("configure", icon, text, Vector2(24, 24), color)


func set_return_mooring_status(active: bool, attuned: bool) -> void:
	if return_mooring_status != null:
		var text := "RETURN MOORING: %s" % ("ATTUNED" if attuned else ("ACTIVE" if active else "DORMANT"))
		return_mooring_status.call("configure", Catalog.ICON_RETURN_MOORING, text, Vector2(24, 24), Palette.BLUE_TECH if active else Palette.MUTED_TEXT)


func set_status_line(slot: String, icon_path: String, text: String, color: Color = Palette.BODY_TEXT) -> void:
	var target: Node = null
	match slot:
		"key", "top", "primary":
			target = key_item_status
		"gate", "middle", "secondary":
			target = gate_status
		"return", "bottom", "tertiary":
			target = return_mooring_status
		_:
			push_warning("[CustodianHUD] Unknown status slot: %s" % slot)
			return
	if target != null:
		target.call("configure", icon_path, text, Vector2(24, 24), color)


func set_minimap_visible(p_visible: bool) -> void:
	if minimap_frame != null:
		(minimap_frame as CanvasItem).visible = p_visible


func set_context_active(active: bool) -> void:
	_context_active = active
	if not active:
		hide_interaction()
	_apply_effective_visibility()


func set_external_overlay_hidden(hidden: bool) -> void:
	_externally_suppressed = hidden
	_apply_effective_visibility()


func is_context_active() -> bool:
	return _context_active


func set_debug_overlay_visible(p_visible: bool) -> void:
	if debug_overlay != null:
		debug_overlay.visible = p_visible


func set_debug_text(text: String) -> void:
	if debug_label != null:
		debug_label.text = text


func _apply_theme() -> void:
	for label in [location_title, phase_label, objective_summary, health_label, stamina_label, debug_label]:
		Styles.apply_label(label, Palette.BODY_TEXT, 14)
	Styles.apply_label(location_title, Palette.GOLD_TEXT, 18, true)
	Styles.apply_label(phase_label, Palette.GOLD_TEXT, 13)
	Styles.apply_label(objective_summary, Palette.BODY_TEXT, 14)
	Styles.apply_label(health_label, Palette.BODY_TEXT, 12, true)
	Styles.apply_label(stamina_label, Palette.MUTED_TEXT, 11)
	if vitals_header != null:
		var header_style := StyleBoxFlat.new()
		header_style.bg_color = Palette.PANEL_DEEP
		header_style.border_color = Palette.BORDER_DIM
		header_style.border_width_bottom = 1
		header_style.corner_radius_bottom_left = 2
		header_style.corner_radius_bottom_right = 2
		header_style.corner_radius_top_left = 2
		header_style.corner_radius_top_right = 2
		vitals_header.add_theme_stylebox_override("panel", header_style)
	if health_bar != null:
		health_bar.show_percentage = false
		health_bar.add_theme_stylebox_override("background", Styles.bar_background_style())
		health_bar.add_theme_stylebox_override("fill", Styles.bar_fill_style(Palette.DANGER))
	if debug_overlay != null:
		debug_overlay.add_theme_stylebox_override("panel", Styles.panel_style(true))


func _refresh_operator_status() -> void:
	var operator_ref := get_node_or_null("/root/GameRoot/World/Operator")
	if operator_ref == null:
		return
	var current := _health_current
	var max_value := _health_max
	if operator_ref.has_method("get_health"):
		current = int(round(float(operator_ref.call("get_health"))))
	elif "health" in operator_ref:
		current = int(round(float(operator_ref.get("health"))))
	if operator_ref.has_method("get_max_health"):
		max_value = int(round(float(operator_ref.call("get_max_health"))))
	elif "max_health" in operator_ref:
		max_value = int(round(float(operator_ref.get("max_health"))))
	if current != _health_current or max_value != _health_max:
		set_health(current, max_value)
	if operator_ref.has_method("get_sprint_status"):
		var sprint_status: Dictionary = operator_ref.call("get_sprint_status")
		var stamina_max: float = max(1.0, float(sprint_status.get("stamina_max", 1.0)))
		var stamina_pct: float = clampf(float(sprint_status.get("stamina", 0.0)) / stamina_max * 100.0, 0.0, 100.0)
		var mode: String = "SPRINT" if bool(sprint_status.get("is_sprinting", false)) else "READY"
		if bool(sprint_status.get("sprint_exhausted", false)):
			mode = "RECOVER"
		set_stamina_label("STA %d%% %s" % [int(round(stamina_pct)), mode])


func _apply_effective_visibility() -> void:
	visible = _context_active and not _externally_suppressed
