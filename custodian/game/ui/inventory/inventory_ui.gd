extends Control
class_name InventoryUI

signal closed()

const Assets := preload("res://game/ui/inventory/inventory_asset_catalog.gd")
const ItemCatalog := preload("res://game/ui/inventory/inventory_item_catalog.gd")
const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")
const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")
const MinimapFrameScene := preload("res://game/ui/components/black_reliquary_minimap_frame.tscn")
const IconLabelScene := preload("res://game/ui/components/black_reliquary_icon_label.tscn")
const RELIQUARY_BACKDROP_SHADER := preload(
	"res://game/ui/inventory/shaders/reliquary_inventory_backdrop.gdshader"
)
const RELIQUARY_BACKDROP_MATERIAL := preload(
	"res://game/ui/inventory/materials/reliquary_inventory_backdrop_material.tres"
)
const SYSTEM_TECH := Color("#5a9ea0")

const PAGE_STATUS := "status"
const PAGE_HISTORY := "history"
const PAGE_LEDGER := "ledger"
const PAGE_EQUIPMENT := "equipment"

const PAGE_ORDER := [PAGE_STATUS, PAGE_EQUIPMENT, PAGE_LEDGER, PAGE_HISTORY]
const PAGE_LABELS := {
	"status": "STATUS",
	"history": "HISTORY",
	"ledger": "LEDGER",
	"equipment": "EQUIPMENT",
}

const CATEGORY_ORDER := ["all", "key", "relic", "cognitive", "equipment", "carried", "resources"]
const CATEGORY_LABELS := {
	"all": "ALL",
	"key": "KEY OBJECTS",
	"relic": "RELICS",
	"cognitive": "COGNITIVE",
	"equipment": "EQUIPMENT",
	"carried": "MISCELLANEOUS",
	"resources": "MATERIALS",
}
const CATEGORY_EMPTY_COPY := {
	"all": "NO CARRIED OBJECTS RECORDED.\n\nFIELD LEDGER AWAITS RECOVERED EVIDENCE.",
	"key": "NO KEY OBJECTS REGISTERED.\n\nACCESS RECORDS REMAIN UNRESOLVED.",
	"relic": "NO RECOVERED RELICS REGISTERED.\n\nPROVENANCE CHANNEL REMAINS SILENT.",
	"cognitive": "NO COGNITIVE RESIDUE REGISTERED.\n\nCONTEXT RECOVERY HAS NOT STABILIZED.",
	"equipment": "NO UNEQUIPPED FIELD GEAR REGISTERED.\n\nRECOVERED EQUIPMENT WILL APPEAR HERE.",
	"carried": "NO MISCELLANEOUS OBJECTS REGISTERED.",
	"resources": "NO MATERIAL RESOURCES REGISTERED.\n\nFIELD RECOVERY BINS ARE EMPTY.",
}
const CATEGORY_SORT_ORDER := {
	"key": 0,
	"relic": 1,
	"cognitive": 2,
	"equipment": 3,
	"carried": 4,
	"resources": 5,
}

const LEDGER_CARD_DESKTOP := Vector2(148, 152)
const LEDGER_CARD_MEDIUM := Vector2(156, 158)
const LEDGER_CARD_COMPACT := Vector2(164, 164)

const LEDGER_ICON_DESKTOP := Vector2(88, 88)
const LEDGER_ICON_MEDIUM := Vector2(92, 92)
const LEDGER_ICON_COMPACT := Vector2(96, 96)

const LEDGER_GAP := 8

## Maps equipment item_ids to their weapon definition resource paths.
## Add new entries here when adding new equippable weapons.
const EQUIPMENT_WEAPON_DEFINITIONS := {
	"p9_sidearm": "res://game/actors/operator/sidearm_pistol_definition.tres",
}

@export var inventory: Inventory

var _inventory_manager: Node = null
var _resource_ledger: Node = null
var _selected_category := "all"
var _selected_item_id := ""
var _sort_name_first := false
var _controller_prompts_active := false
var _entries: Array[Dictionary] = []
var _category_buttons: Dictionary = {}
var _item_buttons: Array[Button] = []
var _resource_defs: Dictionary = {}

var _history_entries: Array[Dictionary] = []
var _history_counter := 0
var _status_cache := {
	"location": "",
	"phase": "",
	"objective": "",
	"health": "",
	"stamina": "",
	"key": "",
	"gate": "",
	"return": "",
}

var _current_page := PAGE_STATUS
var _page_buttons: Dictionary = {}

var _frame: PanelContainer
var _header_status: Label
var _count_label: Label
var _footer_hint: Label
var _close_button: Button
var _pages_root: Control
var _status_page: Control
var _history_page: Control
var _ledger_page: Control
var _equipment_page: Control

var _status_health_label: Label
var _status_health_bar: ProgressBar
var _status_stamina_label: Label
var _status_stamina_bar: ProgressBar
var _status_location_row: HBoxContainer
var _status_phase_row: HBoxContainer
var _status_objective_row: HBoxContainer
var _status_key_row: HBoxContainer
var _status_gate_row: HBoxContainer
var _status_return_row: HBoxContainer
var _status_summary: Label
var _status_minimap_frame: Control
var _status_left_panel: PanelContainer
var _status_left_stack: VBoxContainer
var _history_log: RichTextLabel
var _history_empty: Label

var _ledger_category_list: VBoxContainer
var _ledger_item_grid: GridContainer
var _ledger_count_label: Label
var _ledger_empty_label: Label
var _ledger_filter_label: Label
var _ledger_filter_button: Button
var _ledger_sort_button: Button
var _ledger_detail_icon: TextureRect
var _ledger_detail_name: Label
var _ledger_detail_class: Label
var _ledger_detail_count: Label
var _ledger_detail_description: Label
var _ledger_detail_use: Label
var _ledger_detail_provenance: Label
var _ledger_detail_equip_button: Button
var _ledger_category_panel: PanelContainer
var _ledger_records_panel: PanelContainer
var _ledger_detail_panel: PanelContainer

var _equipment_slot_container: VBoxContainer
var _equipment_slot_icon: TextureRect
var _equipment_slot_name: Label
var _equipment_slot_status: Label
var _equipment_action_button: Button
var _equipment_available_list: VBoxContainer
var _equipment_available_empty: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("gameplay_overlay")
	add_to_group("inventory_ui")
	_build_interface()
	_connect_live_inventory()
	_connect_resource_ledger()
	_load_resource_defs()
	_refresh_entries()
	_select_page(PAGE_STATUS, false)
	_update_input_prompts()
	call_deferred("_update_ledger_grid_columns")
	call_deferred("_update_responsive_layout")
	visible = false


func open(inv: Inventory = null) -> void:
	if inv != null:
		inventory = inv
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_entries()
	_select_page(_current_page, false)
	call_deferred("_update_ledger_grid_columns")
	call_deferred("_update_responsive_layout")
	_focus_current_page()


func close() -> void:
	if not visible:
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not _controller_prompts_active:
			_controller_prompts_active = true
			_update_input_prompts()
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		if _controller_prompts_active:
			_controller_prompts_active = false
			_update_input_prompts()
	if event.is_action_pressed("toggle_inventory"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if not visible or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.physical_keycode == KEY_Q:
			_cycle_page(-1)
			get_viewport().set_input_as_handled()
		elif key_event.physical_keycode == KEY_E:
			_cycle_page(1)
			get_viewport().set_input_as_handled()
		elif _current_page == PAGE_LEDGER and key_event.physical_keycode == KEY_F:
			_cycle_ledger_filter()
			get_viewport().set_input_as_handled()
		elif _current_page == PAGE_LEDGER and key_event.physical_keycode == KEY_R:
			_toggle_ledger_sort()
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton:
		var joy_event := event as InputEventJoypadButton
		if joy_event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_cycle_page(-1)
			get_viewport().set_input_as_handled()
		elif joy_event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_cycle_page(1)
			get_viewport().set_input_as_handled()
		elif _current_page == PAGE_LEDGER and joy_event.button_index == JOY_BUTTON_X:
			_cycle_ledger_filter()
			get_viewport().set_input_as_handled()
		elif _current_page == PAGE_LEDGER and joy_event.button_index == JOY_BUTTON_RIGHT_STICK:
			_toggle_ledger_sort()
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_update_ledger_grid_columns")
		call_deferred("_update_responsive_layout")


func set_location(text: String) -> void:
	if _status_cache["location"] == text:
		return
	_status_cache["location"] = text
	_update_status_row(_status_location_row, Catalog.COMPASS_ROSE_SMALL, "LOCATION: %s" % text, Palette.GOLD_TEXT)
	_append_history_entry("LOCATION", text, Palette.GOLD_TEXT)


func set_phase(text: String) -> void:
	if _status_cache["phase"] == text:
		return
	_status_cache["phase"] = text
	_update_status_row(_status_phase_row, Catalog.ICON_OBJECTIVE, "PHASE: %s" % text, SYSTEM_TECH)
	_append_history_entry("PHASE", text, SYSTEM_TECH)


func set_objective(text: String) -> void:
	if _status_cache["objective"] == text:
		return
	_status_cache["objective"] = text
	_update_status_row(_status_objective_row, Catalog.ICON_OBJECTIVE, "OBJECTIVE: %s" % text, Palette.BODY_TEXT)
	_append_history_entry("OBJECTIVE", text, Palette.BODY_TEXT)


func set_health(current: int, max_value: int) -> void:
	var current_text := "%d/%d" % [max(0, current), max(1, max_value)]
	if _status_cache["health"] == current_text:
		return
	_status_cache["health"] = current_text
	if _status_health_label != null:
		_status_health_label.text = "HEALTH %s" % current_text
		var ratio := float(max(0, current)) / float(max(1, max_value))
		if ratio <= 0.3:
			_status_health_label.add_theme_color_override("font_color", Palette.DANGER)
		elif ratio <= 0.6:
			_status_health_label.add_theme_color_override("font_color", Palette.GOLD_TEXT)
		else:
			_status_health_label.add_theme_color_override("font_color", Palette.BODY_TEXT)
	if _status_health_bar != null:
		_status_health_bar.max_value = 100.0
		_status_health_bar.value = clampf((float(max(0, current)) / float(max(1, max_value))) * 100.0, 0.0, 100.0)


func set_stamina_status(text: String, percent: float) -> void:
	var safe_percent := clampf(percent, 0.0, 100.0)
	var status_text := "%s %d%%" % [text, int(round(safe_percent))]
	if _status_cache["stamina"] == status_text:
		return
	_status_cache["stamina"] = status_text
	if _status_stamina_label != null:
		_status_stamina_label.text = "STAMINA %s" % status_text
	if _status_stamina_bar != null:
		_status_stamina_bar.max_value = 100.0
		_status_stamina_bar.value = safe_percent
		_status_stamina_bar.show_percentage = false


func set_key_item_status(has_key: bool, item_name: String = "Sundered Gate Key") -> void:
	var text := "%s: %s" % [item_name, "HELD" if has_key else "MISSING"]
	if _status_cache["key"] == text:
		return
	_status_cache["key"] = text
	_update_status_row(_status_key_row, Catalog.ICON_KEY_ITEM, text, Palette.GREEN_SIGNAL if has_key else Palette.MUTED_TEXT)
	_append_history_entry("KEY STATUS", text, Palette.GREEN_SIGNAL if has_key else Palette.MUTED_TEXT)


func set_main_gate_status(open: bool, locked: bool) -> void:
	var text := "MAIN GATE: OPEN" if open else ("MAIN GATE: LOCKED" if locked else "MAIN GATE: READY")
	if _status_cache["gate"] == text:
		return
	_status_cache["gate"] = text
	var icon: String = Catalog.ICON_GATE_OPEN if open else Catalog.ICON_GATE_LOCKED
	var color: Color = Palette.GREEN_SIGNAL if open else (Palette.DANGER if locked else Palette.GOLD_TEXT)
	_update_status_row(_status_gate_row, icon, text, color)
	_append_history_entry("GATE STATUS", text, color)


func set_return_mooring_status(active: bool, attuned: bool) -> void:
	var text := "RETURN MOORING: %s" % ("ATTUNED" if attuned else ("ACTIVE" if active else "DORMANT"))
	if _status_cache["return"] == text:
		return
	_status_cache["return"] = text
	_update_status_row(_status_return_row, Catalog.ICON_RETURN_MOORING, text, SYSTEM_TECH if active else Palette.MUTED_TEXT)
	_append_history_entry("RETURN MOORING", text, SYSTEM_TECH if active else Palette.MUTED_TEXT)


func set_status_line(slot: String, icon_path: String, text: String, color: Color = Palette.BODY_TEXT) -> void:
	match slot:
		"key", "top", "primary":
			_update_status_row(_status_key_row, icon_path, text, color)
		"gate", "middle", "secondary":
			_update_status_row(_status_gate_row, icon_path, text, color)
		"return", "bottom", "tertiary":
			_update_status_row(_status_return_row, icon_path, text, color)
		_:
			push_warning("[InventoryUI] Unknown status slot: %s" % slot)


func record_history_entry(title: String, body: String, color: Color = Palette.BODY_TEXT) -> void:
	_append_history_entry(title, body, color)


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color.WHITE
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop_material := RELIQUARY_BACKDROP_MATERIAL.duplicate() as ShaderMaterial
	backdrop_material.shader = RELIQUARY_BACKDROP_SHADER
	backdrop.material = backdrop_material
	add_child(backdrop)

	_frame = PanelContainer.new()
	_frame.name = "ReliquaryFrame"
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.offset_left = 18.0
	_frame.offset_top = 18.0
	_frame.offset_right = -18.0
	_frame.offset_bottom = -18.0
	_frame.add_theme_stylebox_override("panel", _inventory_panel_style(false))
	add_child(_frame)
	_add_frame_texture(_frame)
	_add_corner_ornaments(_frame)

	var outer := MarginContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_left", 32)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_right", 32)
	outer.add_theme_constant_override("margin_bottom", 18)
	_frame.add_child(outer)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10)
	outer.add_child(stack)

	stack.add_child(_build_header())
	stack.add_child(_build_divider())
	stack.add_child(_build_page_rail())
	stack.add_child(_build_divider())

	_pages_root = Control.new()
	_pages_root.name = "PageRoot"
	_pages_root.clip_contents = true
	_pages_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pages_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(_pages_root)

	_status_page = _build_status_page()
	_history_page = _build_history_page()
	_ledger_page = _build_ledger_page()
	_equipment_page = _build_equipment_page()
	_mount_page(_status_page)
	_mount_page(_history_page)
	_mount_page(_ledger_page)
	_mount_page(_equipment_page)
	stack.add_child(_build_footer())


func _mount_page(page: Control) -> void:
	if page == null:
		return
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pages_root.add_child(page)


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 52
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := _label("FIELD LEDGER", Palette.GOLD_TEXT, 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	_count_label = _label("0 RECORDS · 0 UNITS", SYSTEM_TECH, 13)
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_count_label)
	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.custom_minimum_size = Vector2(128, 40)
	_apply_button_style(_close_button)
	_close_button.pressed.connect(close)
	header.add_child(_close_button)
	return header


func _build_page_rail() -> Control:
	var rail := HBoxContainer.new()
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.add_theme_constant_override("separation", 10)
	for page in PAGE_ORDER:
		var button := Button.new()
		button.name = "%sButton" % PAGE_LABELS[page].capitalize()
		button.text = PAGE_LABELS[page]
		button.custom_minimum_size = Vector2(132, 38)
		button.pressed.connect(_select_page.bind(page))
		_apply_button_style(button)
		_page_buttons[page] = button
		rail.add_child(button)
	return rail


func _build_footer() -> Control:
	var footer := PanelContainer.new()
	footer.name = "InputFooter"
	footer.custom_minimum_size.y = 38
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_theme_stylebox_override("panel", Styles.inventory_footer_style())
	_footer_hint = _label("", Palette.MUTED_TEXT, 12)
	_footer_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_footer_hint)
	return footer


func _build_status_page() -> Control:
	var page := HBoxContainer.new()
	page.name = "StatusPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)

	_status_left_panel = _panel(true, Vector2(340, 0))
	_status_left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_status_left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 18)
	left_margin.add_theme_constant_override("margin_top", 18)
	left_margin.add_theme_constant_override("margin_right", 18)
	left_margin.add_theme_constant_override("margin_bottom", 18)
	_status_left_panel.add_child(left_margin)
	_status_left_stack = VBoxContainer.new()
	_status_left_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_left_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_status_left_stack.add_theme_constant_override("separation", 10)
	left_margin.add_child(_status_left_stack)

	_status_left_stack.add_child(_label("FIELD POSTURE", Palette.GOLD_TEXT, 12))
	_status_health_label = _label("HEALTH 100/100", Palette.BODY_TEXT, 18)
	_status_left_stack.add_child(_status_health_label)
	_status_health_bar = _progress_bar(Palette.DANGER)
	_status_left_stack.add_child(_status_health_bar)
	_status_stamina_label = _label("STAMINA READY", Palette.EVRFOREST_PALE_GREEN, 14)
	_status_left_stack.add_child(_status_stamina_label)
	_status_stamina_bar = _progress_bar(Palette.EVRFOREST_PALE_GREEN)
	_status_left_stack.add_child(_status_stamina_bar)

	_status_left_stack.add_child(_build_divider())
	_status_summary = _label("BLACK RELIQUARY / FIELD STATUS", Palette.MUTED_TEXT, 12)
	_status_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_left_stack.add_child(_status_summary)

	_status_left_stack.add_child(_build_divider())
	_status_location_row = _create_status_row(Catalog.COMPASS_ROSE_SMALL, "LOCATION: --")
	_status_phase_row = _create_status_row(Catalog.ICON_OBJECTIVE, "PHASE: --")
	_status_objective_row = _create_status_row(Catalog.ICON_OBJECTIVE, "OBJECTIVE: --")
	_status_key_row = _create_status_row(Catalog.ICON_KEY_ITEM, "Sundered Gate Key: MISSING")
	_status_gate_row = _create_status_row(Catalog.ICON_GATE_LOCKED, "MAIN GATE: LOCKED")
	_status_return_row = _create_status_row(Catalog.ICON_RETURN_MOORING, "RETURN MOORING: DORMANT")
	for row in [_status_location_row, _status_phase_row, _status_objective_row, _status_key_row, _status_gate_row, _status_return_row]:
		_status_left_stack.add_child(row)

	var minimap_panel := _panel(true, Vector2(0, 0))
	minimap_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minimap_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var minimap_margin := MarginContainer.new()
	minimap_margin.add_theme_constant_override("margin_left", 18)
	minimap_margin.add_theme_constant_override("margin_top", 18)
	minimap_margin.add_theme_constant_override("margin_right", 18)
	minimap_margin.add_theme_constant_override("margin_bottom", 18)
	minimap_panel.add_child(minimap_margin)
	var minimap_stack := VBoxContainer.new()
	minimap_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minimap_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	minimap_stack.add_theme_constant_override("separation", 10)
	minimap_margin.add_child(minimap_stack)
	minimap_stack.add_child(_label("TACTICAL STATUS MAP", Palette.GOLD_TEXT, 12))
	_status_minimap_frame = MinimapFrameScene.instantiate() as Control
	if _status_minimap_frame != null:
		if _status_minimap_frame.has_method("set_title"):
			_status_minimap_frame.call("set_title", "TACTICAL STATUS MAP")
		_status_minimap_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_status_minimap_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_status_minimap_frame.custom_minimum_size = Vector2(480, 300)
		minimap_stack.add_child(_status_minimap_frame)

	page.add_child(_status_left_panel)
	page.add_child(minimap_panel)
	return page


func _build_history_page() -> Control:
	var page := _panel(true, Vector2(0, 0))
	page.name = "HistoryPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	page.add_child(margin)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	stack.add_child(_label("QUEST HISTORY / LOG", Palette.GOLD_TEXT, 12))
	stack.add_child(_label("Recent state changes are retained here as a readable field record.", Palette.MUTED_TEXT, 12))
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var scroll_margin := MarginContainer.new()
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_left", 4)
	scroll_margin.add_theme_constant_override("margin_top", 4)
	scroll_margin.add_theme_constant_override("margin_right", 4)
	scroll_margin.add_theme_constant_override("margin_bottom", 4)
	scroll.add_child(scroll_margin)
	_history_log = RichTextLabel.new()
	_history_log.name = "HistoryLog"
	_history_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_history_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_history_log.fit_content = false
	_history_log.scroll_active = true
	_history_log.bbcode_enabled = true
	_history_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_history_log.selection_enabled = true
	scroll_margin.add_child(_history_log)
	_history_empty = _label("No log entries recorded yet.\nStatus changes will appear here as the field updates.", Palette.MUTED_TEXT, 14)
	_history_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_history_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_history_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_history_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_history_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_history_empty)
	return page


func _build_ledger_page() -> Control:
	var page := Control.new()
	page.name = "LedgerPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_bottom", 4)
	page.add_child(margin)
	margin.add_child(_build_ledger_body())
	return page


func _build_ledger_body() -> Control:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)

	_ledger_category_panel = _section_panel(Vector2(150, 0))
	_ledger_category_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_ledger_category_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var category_margin := MarginContainer.new()
	category_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	category_margin.add_theme_constant_override("margin_left", 12)
	category_margin.add_theme_constant_override("margin_top", 12)
	category_margin.add_theme_constant_override("margin_right", 12)
	category_margin.add_theme_constant_override("margin_bottom", 12)
	_ledger_category_panel.add_child(category_margin)
	_ledger_category_list = VBoxContainer.new()
	_ledger_category_list.add_theme_constant_override("separation", 7)
	category_margin.add_child(_ledger_category_list)
	_ledger_category_list.add_child(_label("CLASS", Palette.GOLD_TEXT, 12))
	for category in CATEGORY_ORDER:
		var button := Button.new()
		button.name = "Category%sButton" % category.capitalize()
		button.text = CATEGORY_LABELS[category]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 38
		button.pressed.connect(_select_category.bind(category))
		_apply_button_style(button)
		_category_buttons[category] = button
		_ledger_category_list.add_child(button)
	body.add_child(_ledger_category_panel)

	var records := VBoxContainer.new()
	records.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	records.size_flags_vertical = Control.SIZE_EXPAND_FILL
	records.add_theme_constant_override("separation", 10)
	records.add_child(_label("RECOVERED OBJECTS", Palette.GOLD_TEXT, 15))
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	_ledger_filter_button = Button.new()
	_ledger_filter_button.name = "FilterButton"
	_ledger_filter_button.custom_minimum_size = Vector2(178, 34)
	_ledger_filter_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ledger_filter_button.pressed.connect(_cycle_ledger_filter)
	_apply_button_style(_ledger_filter_button)
	controls.add_child(_ledger_filter_button)
	_ledger_sort_button = Button.new()
	_ledger_sort_button.name = "SortButton"
	_ledger_sort_button.custom_minimum_size = Vector2(174, 34)
	_ledger_sort_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ledger_sort_button.pressed.connect(_toggle_ledger_sort)
	_apply_button_style(_ledger_sort_button)
	controls.add_child(_ledger_sort_button)
	_ledger_filter_label = _label("", Palette.MUTED_TEXT, 12)
	_ledger_filter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ledger_filter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_child(_ledger_filter_label)
	records.add_child(controls)
	var scroll := ScrollContainer.new()
	scroll.name = "ItemScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	records.add_child(scroll)
	_ledger_item_grid = GridContainer.new()
	_ledger_item_grid.name = "ItemGrid"
	_ledger_item_grid.columns = 3
	_ledger_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ledger_item_grid.add_theme_constant_override("h_separation", LEDGER_GAP)
	_ledger_item_grid.add_theme_constant_override("v_separation", LEDGER_GAP)
	scroll.add_child(_ledger_item_grid)
	_ledger_empty_label = _label("NO CARRIED OBJECTS RECORDED\n\nField ledger awaits recovered evidence.", Palette.MUTED_TEXT, 15)
	_ledger_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ledger_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ledger_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	records.add_child(_ledger_empty_label)
	_ledger_records_panel = PanelContainer.new()
	_ledger_records_panel.name = "LedgerRecordsPanel"
	_ledger_records_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ledger_records_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ledger_records_panel.add_theme_stylebox_override(
		"panel",
		Styles.inventory_register_style()
	)
	var records_margin := MarginContainer.new()
	records_margin.add_theme_constant_override("margin_left", 14)
	records_margin.add_theme_constant_override("margin_top", 12)
	records_margin.add_theme_constant_override("margin_right", 14)
	records_margin.add_theme_constant_override("margin_bottom", 12)
	_ledger_records_panel.add_child(records_margin)
	records_margin.add_child(records)
	body.add_child(_ledger_records_panel)

	body.add_child(_build_ledger_detail_panel())
	return body


func _build_ledger_detail_panel() -> Control:
	_ledger_detail_panel = _section_panel(Vector2(340, 0))
	_ledger_detail_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	_ledger_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	_ledger_detail_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 9)
	margin.add_child(stack)

	stack.add_child(_label("INSPECTION", Palette.GOLD_TEXT, 15))

	var identity_header := HBoxContainer.new()
	identity_header.name = "InspectionIdentityHeader"
	identity_header.add_theme_constant_override("separation", 12)
	identity_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(identity_header)

	_ledger_detail_icon = TextureRect.new()
	_ledger_detail_icon.name = "InspectionIcon"
	_ledger_detail_icon.custom_minimum_size = Vector2(112, 112)
	_ledger_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ledger_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ledger_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	identity_header.add_child(_ledger_detail_icon)

	var identity_text := VBoxContainer.new()
	identity_text.name = "InspectionIdentityText"
	identity_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_text.add_theme_constant_override("separation", 5)
	identity_header.add_child(identity_text)

	_ledger_detail_name = _label("NO RECORD SELECTED", Palette.BODY_TEXT, 18)
	_ledger_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ledger_detail_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_text.add_child(_ledger_detail_name)

	var metadata := HBoxContainer.new()
	metadata.add_theme_constant_override("separation", 8)
	_ledger_detail_class = _label("CLASS: --", SYSTEM_TECH, 12)
	_ledger_detail_class.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ledger_detail_class.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metadata.add_child(_ledger_detail_class)
	_ledger_detail_count = _label("×--", Palette.GOLD_TEXT, 12)
	metadata.add_child(_ledger_detail_count)
	identity_text.add_child(metadata)

	_ledger_detail_use = _label("PRIMARY USE: UNKNOWN", Palette.MUTED_TEXT, 12)
	_ledger_detail_use.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity_text.add_child(_ledger_detail_use)

	stack.add_child(_build_divider())
	var description_scroll := ScrollContainer.new()
	description_scroll.name = "DescriptionScroll"
	description_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(description_scroll)
	var description_stack := VBoxContainer.new()
	description_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_stack.add_theme_constant_override("separation", 10)
	description_scroll.add_child(description_stack)
	description_stack.add_child(_label("DESCRIPTION", Palette.MUTED_TEXT, 12))
	_ledger_detail_description = _label("Select a recovered object to inspect its ledger record.", Palette.BODY_TEXT, 15)
	_ledger_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ledger_detail_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	description_stack.add_child(_ledger_detail_description)

	_ledger_detail_provenance = _label("PROVENANCE: --", Palette.MUTED_TEXT, 13)
	_ledger_detail_provenance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_stack.add_child(_ledger_detail_provenance)

	_ledger_detail_equip_button = Button.new()
	_ledger_detail_equip_button.name = "EquipButton"
	_ledger_detail_equip_button.text = ""
	_ledger_detail_equip_button.custom_minimum_size = Vector2(0, 42)
	_ledger_detail_equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ledger_detail_equip_button.disabled = true
	_ledger_detail_equip_button.visible = false
	_apply_button_style(_ledger_detail_equip_button)
	_ledger_detail_equip_button.pressed.connect(_on_equip_button_pressed)
	stack.add_child(_ledger_detail_equip_button)
	return _ledger_detail_panel


func _build_equipment_page() -> Control:
	var page := _panel(true, Vector2(0, 0))
	page.name = "EquipmentPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	page.add_child(margin)
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	margin.add_child(body)

	var active_panel := _section_panel(Vector2(520, 0))
	active_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var active_margin := MarginContainer.new()
	active_margin.add_theme_constant_override("margin_left", 16)
	active_margin.add_theme_constant_override("margin_top", 16)
	active_margin.add_theme_constant_override("margin_right", 16)
	active_margin.add_theme_constant_override("margin_bottom", 16)
	active_panel.add_child(active_margin)
	var active_stack := VBoxContainer.new()
	active_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_stack.add_theme_constant_override("separation", 14)
	active_margin.add_child(active_stack)
	active_stack.add_child(_label("ACTIVE SLOTS", Palette.GOLD_TEXT, 14))
	active_stack.add_child(_label(
		"Equipped records claim their field action. Empty slots retain the Operator's default behavior.",
		Palette.MUTED_TEXT,
		12
	))
	
	# Sidearm slot card
	var slot_card := _panel(true, Vector2(0, 0))
	slot_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 16)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_right", 16)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	slot_card.add_child(card_margin)
	
	var card_hbox := HBoxContainer.new()
	card_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_hbox.add_theme_constant_override("separation", 16)
	card_margin.add_child(card_hbox)
	
	# Slot icon
	var icon_container := MarginContainer.new()
	icon_container.custom_minimum_size = Vector2(96, 96)
	card_hbox.add_child(icon_container)
	_equipment_slot_icon = TextureRect.new()
	_equipment_slot_icon.custom_minimum_size = Vector2(80, 80)
	_equipment_slot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_equipment_slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_equipment_slot_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_container.add_child(_equipment_slot_icon)
	
	# Slot info
	var info_stack := VBoxContainer.new()
	info_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_stack.add_theme_constant_override("separation", 6)
	card_hbox.add_child(info_stack)
	
	info_stack.add_child(_label("SIDEARM SLOT", SYSTEM_TECH, 12))
	_equipment_slot_name = _label("EMPTY", Palette.MUTED_TEXT, 18)
	info_stack.add_child(_equipment_slot_name)
	_equipment_slot_status = _label("No sidearm equipped. Find one in the field and equip it from this terminal.", Palette.MUTED_TEXT, 12)
	_equipment_slot_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_stack.add_child(_equipment_slot_status)
	
	# Action button
	_equipment_action_button = Button.new()
	_equipment_action_button.name = "EquipmentActionButton"
	_equipment_action_button.text = ""
	_equipment_action_button.custom_minimum_size = Vector2(180, 38)
	_equipment_action_button.disabled = true
	_apply_button_style(_equipment_action_button)
	_equipment_action_button.pressed.connect(_on_equipment_action_pressed)
	var button_container := HBoxContainer.new()
	button_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	button_container.add_child(_equipment_action_button)
	info_stack.add_child(button_container)
	
	active_stack.add_child(slot_card)
	body.add_child(active_panel)

	var available_panel := _section_panel(Vector2(420, 0))
	available_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	available_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var available_margin := MarginContainer.new()
	available_margin.add_theme_constant_override("margin_left", 16)
	available_margin.add_theme_constant_override("margin_top", 16)
	available_margin.add_theme_constant_override("margin_right", 16)
	available_margin.add_theme_constant_override("margin_bottom", 16)
	available_panel.add_child(available_margin)
	_equipment_available_list = VBoxContainer.new()
	_equipment_available_list.name = "AvailableEquipmentList"
	_equipment_available_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equipment_available_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_equipment_available_list.add_theme_constant_override("separation", 10)
	available_margin.add_child(_equipment_available_list)
	_equipment_available_list.add_child(_label("AVAILABLE EQUIPMENT", Palette.GOLD_TEXT, 14))
	_equipment_available_empty = _label(
		"NO UNEQUIPPED EQUIPMENT",
		Palette.MUTED_TEXT,
		14
	)
	_equipment_available_empty.name = "AvailableEquipmentEmpty"
	_equipment_available_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equipment_available_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_equipment_available_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equipment_available_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_equipment_available_list.add_child(_equipment_available_empty)
	body.add_child(available_panel)
	return page


func _connect_resource_ledger() -> void:
	_resource_ledger = get_node_or_null("/root/ResourceLedger")
	if _resource_ledger != null and _resource_ledger.has_signal("changed"):
		var callback := Callable(self, "_on_resource_ledger_changed")
		if not _resource_ledger.is_connected("changed", callback):
			_resource_ledger.connect("changed", callback)


func _on_resource_ledger_changed(_snapshot: Dictionary) -> void:
	_refresh_entries()


func _connect_live_inventory() -> void:
	_inventory_manager = get_node_or_null("/root/InventoryManager")
	if _inventory_manager != null and _inventory_manager.has_signal("inventory_changed"):
		var callback := Callable(self, "_refresh_entries")
		if not _inventory_manager.is_connected("inventory_changed", callback):
			_inventory_manager.connect("inventory_changed", callback)
	if _inventory_manager != null and _inventory_manager.has_signal("equipment_changed"):
		var equip_callback := Callable(self, "_on_equipment_changed")
		if not _inventory_manager.is_connected("equipment_changed", equip_callback):
			_inventory_manager.connect("equipment_changed", equip_callback)


func _on_equipment_changed(_slot_name: StringName, _item_id: StringName) -> void:
	_refresh_equipment_page()
	_refresh_entries()  # Also refresh the ledger in case items were added/removed


func _refresh_equipment_page() -> void:
	if _equipment_slot_name == null or _equipment_slot_status == null or _equipment_slot_icon == null or _equipment_action_button == null:
		return

	_rebuild_available_equipment()
	
	if _inventory_manager == null or not _inventory_manager.has_method("get_equipped"):
		_equipment_slot_name.text = "OFFLINE"
		_equipment_slot_status.text = "Inventory manager unavailable."
		_equipment_action_button.disabled = true
		_equipment_action_button.visible = false
		return
	
	var equipped_id := str(_inventory_manager.call("get_equipped", &"sidearm"))
	if equipped_id == "" or equipped_id.is_empty():
		var sidearm_available := bool(_inventory_manager.call("has_item", &"p9_sidearm", 1))
		_equipment_slot_icon.texture = Assets.item_portrait(&"p9_sidearm") if sidearm_available else Assets.texture("icon_unknown")
		_equipment_slot_name.text = "P-9 FIELD SIDEARM / AVAILABLE" if sidearm_available else "EMPTY"
		_equipment_slot_name.modulate = Palette.BODY_TEXT if sidearm_available else Palette.MUTED_TEXT
		_equipment_slot_status.text = (
			"Recovered and carried. Equip the P-9 to claim the offhand action; while empty, offhand remains guard/parry."
			if sidearm_available else
			"No sidearm recovered. The offhand action remains guard/parry."
		)
		_equipment_action_button.text = "EQUIP SIDEARM" if sidearm_available else "NO SIDEARM AVAILABLE"
		_equipment_action_button.disabled = not sidearm_available
		_equipment_action_button.visible = true
	else:
		# Equipped
		var definition := ItemCatalog.get_definition(StringName(equipped_id))
		var display_name := str(definition.get("display_name", equipped_id))
		_equipment_slot_icon.texture = Assets.item_portrait(StringName(equipped_id))
		_equipment_slot_name.text = display_name.to_upper()
		_equipment_slot_name.modulate = Palette.GOLD_TEXT
		_equipment_slot_status.text = str(definition.get("description", "No description available."))
		_equipment_action_button.text = "UNEQUIP"
		_equipment_action_button.disabled = false
		_equipment_action_button.visible = true


func _rebuild_available_equipment() -> void:
	if _equipment_available_list == null or _equipment_available_empty == null:
		return
	for child in _equipment_available_list.get_children():
		if child == _equipment_available_empty or child is Label:
			continue
		_equipment_available_list.remove_child(child)
		child.queue_free()

	var equipped_id := ""
	if _inventory_manager != null and _inventory_manager.has_method("get_equipped"):
		equipped_id = str(_inventory_manager.call("get_equipped", &"sidearm"))

	var available: Array[Dictionary] = []
	for entry in _entries:
		var definition: Dictionary = entry.get("definition", {})
		if str(definition.get("category", "carried")) != "equipment":
			continue
		if str(entry.get("item_id", "")) == equipped_id:
			continue
		available.append(entry)

	_equipment_available_empty.visible = available.is_empty()
	for entry in available:
		_equipment_available_list.add_child(_create_available_equipment_card(entry))


func _create_available_equipment_card(entry: Dictionary) -> Button:
	var definition: Dictionary = entry.get("definition", {})
	var item_id := str(entry.get("item_id", ""))
	var card := Button.new()
	card.name = "AvailableEquipment_%s" % item_id
	card.custom_minimum_size = Vector2(0, 104)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.text = ""
	card.set_meta("item_id", item_id)
	_apply_button_style(card)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = Assets.item_portrait(item_id)
	icon.material = _item_icon_material(item_id)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.size_flags_vertical = Control.SIZE_EXPAND_FILL
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_theme_constant_override("separation", 4)
	row.add_child(labels)
	labels.add_child(_label(
		str(definition.get("display_name", item_id)).to_upper(),
		Palette.BODY_TEXT,
		16
	))
	labels.add_child(_label(
		"AVAILABLE · ×%d" % int(entry.get("quantity", 0)),
		SYSTEM_TECH,
		12
	))
	var description := _label(
		str(definition.get("description", "Recovered field equipment.")),
		Palette.MUTED_TEXT,
		12
	)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	labels.add_child(description)
	card.pressed.connect(_on_available_equipment_pressed.bind(entry))
	return card


func _on_available_equipment_pressed(entry: Dictionary) -> void:
	var item_id := StringName(str(entry.get("item_id", "")))
	var slot_name := _get_equipment_slot_for_item(item_id)
	if slot_name == &"":
		return
	_equip_item_to_slot(item_id, slot_name)


func _on_equipment_action_pressed() -> void:
	if _inventory_manager == null or not _inventory_manager.has_method("get_equipped"):
		return
	
	var equipped_id := str(_inventory_manager.call("get_equipped", &"sidearm"))
	if equipped_id == "" or equipped_id.is_empty():
		_equip_item_to_slot(&"p9_sidearm", &"sidearm")
		return
	
	# Find the player operator to call remove_sidearm()
	var operator := get_tree().get_first_node_in_group("player")
	if operator == null or not operator.has_method("remove_sidearm"):
		push_warning("[InventoryUI] Cannot unequip sidearm: operator not found or no remove_sidearm method")
		return
	
	# First unequip in InventoryManager (returns item to inventory)
	var released := bool(_inventory_manager.call("unequip_slot", &"sidearm"))
	if not released:
		return
	
	# Then remove sidearm from operator
	operator.call("remove_sidearm")
	
	record_history_entry("EQUIPMENT", "Sidearm unequipped and returned to inventory.", SYSTEM_TECH)
	_refresh_equipment_page()


func _on_equip_button_pressed() -> void:
	if _inventory_manager == null or not _inventory_manager.has_method("equip_item"):
		return
	if _selected_item_id.is_empty():
		return
	
	var item_id := StringName(_selected_item_id)
	var slot_name := _get_equipment_slot_for_item(item_id)
	if slot_name == &"":
		return
	_equip_item_to_slot(item_id, slot_name)


func _equip_item_to_slot(item_id: StringName, slot_name: StringName) -> void:
	if _inventory_manager == null or not _inventory_manager.has_method("equip_item"):
		return
	
	if bool(_inventory_manager.call("is_slot_filled", slot_name)):
		push_warning("[InventoryUI] Slot %s already filled" % slot_name)
		return
	
	# Find the mapping to weapon definition
	var def_path := str(EQUIPMENT_WEAPON_DEFINITIONS.get(item_id, ""))
	if def_path.is_empty():
		push_warning("[InventoryUI] No weapon definition mapping for item: %s" % item_id)
		return
	
	# Find operator to grant sidearm
	var operator := get_tree().get_first_node_in_group("player")
	if operator == null or not operator.has_method("grant_sidearm"):
		push_warning("[InventoryUI] Cannot equip sidearm: operator not found or no grant_sidearm method")
		return
	
	# Load the weapon definition
	var weapon_def := load(def_path)
	if weapon_def == null:
		push_warning("[InventoryUI] Failed to load weapon definition: %s" % def_path)
		return
	
	# Equip in InventoryManager (removes from inventory)
	var equipped := bool(_inventory_manager.call("equip_item", item_id, slot_name))
	if not equipped:
		return
	
	# Grant to operator
	var result: Dictionary = operator.call("grant_sidearm", weapon_def)
	if not result.get("granted", false):
		# unequip_slot already returns the item to carried inventory.
		_inventory_manager.call("unequip_slot", slot_name)
		push_warning("[InventoryUI] Failed to grant sidearm to operator")
		return
	
	record_history_entry("EQUIPMENT", "%s equipped to %s slot." % [str(item_id), str(slot_name)], Palette.GREEN_SIGNAL)
	_refresh_equipment_page()
	_refresh_entries()


## Given an equipment item_id, return which equipment slot it belongs in.
## Override this to add new slot mappings.
func _get_equipment_slot_for_item(item_id: StringName) -> StringName:
	if EQUIPMENT_WEAPON_DEFINITIONS.has(item_id):
		return &"sidearm"
	return &""


func _load_resource_defs() -> void:
	var path := "res://content/resources/resource_defs.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_resource_defs = parsed as Dictionary


func _refresh_entries() -> void:
	_entries.clear()
	_load_carried_items()
	_load_resources()
	_rebuild_item_grid()
	_update_count_label()
	_update_input_prompts()
	_rebuild_history_log()


func _load_carried_items() -> void:
	if inventory != null:
		for index in range(inventory.max_slots):
			var slot: Dictionary = inventory.get_item_at(index)
			var item: ItemResource = slot.get("item")
			if item == null:
				continue
			var definition := ItemCatalog.get_definition(StringName(item.item_id))
			definition["display_name"] = item.display_name
			definition["description"] = item.description
			_entries.append({"item_id": item.item_id, "quantity": int(slot.get("quantity", 0)), "category": "carried", "definition": definition})
		return
	if _inventory_manager != null and _inventory_manager.has_method("get_all_items"):
		var items: Dictionary = _inventory_manager.call("get_all_items")
		var ids: Array = items.keys()
		ids.sort_custom(func(a, b): return String(a) < String(b))
		for item_id_value in ids:
			var item_id := String(item_id_value)
			var definition := ItemCatalog.get_definition(StringName(item_id))
			var category := str(definition.get("category", "carried"))
			_entries.append({"item_id": item_id, "quantity": int(items[item_id_value]), "category": category, "definition": definition})


func _load_resources() -> void:
	if _resource_ledger == null or not _resource_ledger.has_method("get_snapshot"):
		return
	var snapshot: Dictionary = _resource_ledger.call("get_snapshot")
	var resource_ids: Array = snapshot.keys()
	resource_ids.sort()
	for resource_id in resource_ids:
		var quantity := int(snapshot[resource_id])
		if quantity <= 0:
			continue
		var def: Dictionary = _resource_defs.get(resource_id, {})
		var definition := {
			"item_id": resource_id,
			"display_name": str(def.get("label", resource_id.replace("_", " ").capitalize())),
			"description": str(def.get("description", "A recovered material resource.")),
			"category": "resources",
			"rarity": "material",
			"provenance": "FIELD RECOVERY / REFINED MATERIAL",
		}
		_entries.append({"item_id": resource_id, "quantity": quantity, "category": "resources", "definition": definition})


func _rebuild_item_grid() -> void:
	if _ledger_item_grid == null:
		return
	_update_ledger_grid_columns()
	for child in _ledger_item_grid.get_children():
		_ledger_item_grid.remove_child(child)
		child.queue_free()
	_item_buttons.clear()
	var filtered: Array[Dictionary] = []
	for entry in _entries:
		var definition: Dictionary = entry["definition"]
		if _selected_category == "all" or str(definition.get("category", "carried")) == _selected_category:
			filtered.append(entry)
	filtered.sort_custom(_sort_ledger_entries)
	_ledger_empty_label.text = str(CATEGORY_EMPTY_COPY.get(_selected_category, CATEGORY_EMPTY_COPY["all"]))
	_ledger_empty_label.visible = filtered.is_empty()
	_ledger_item_grid.visible = not filtered.is_empty()
	for entry in filtered:
		var button := _create_item_button(entry)
		_ledger_item_grid.add_child(button)
		_item_buttons.append(button)
	if filtered.is_empty():
		_selected_item_id = ""
		_show_detail({})
	elif _selected_item_id.is_empty() or not _contains_item(filtered, _selected_item_id):
		_select_entry(filtered[0])
	else:
		for entry in filtered:
			if str(entry["item_id"]) == _selected_item_id:
				_show_detail(entry)
				break
	_update_category_button_states()


func _update_ledger_grid_columns() -> void:
	if _ledger_item_grid == null:
		return

	var parent_control := _ledger_item_grid.get_parent_control()
	if parent_control == null or parent_control.size.x <= 0.0:
		return

	var viewport_width := get_viewport_rect().size.x
	var column_cap := 4
	if viewport_width < 1152.0:
		column_cap = 2
	elif viewport_width < 1500.0:
		column_cap = 3

	var card_width := _ledger_card_size().x
	var stride := card_width + LEDGER_GAP
	var columns := int(floor(
		(parent_control.size.x + LEDGER_GAP) / stride
	))
	_ledger_item_grid.columns = clampi(columns, 1, column_cap)


func _ledger_card_size() -> Vector2:
	var viewport_width := get_viewport_rect().size.x
	if viewport_width >= 1500.0:
		return LEDGER_CARD_DESKTOP
	if viewport_width >= 1152.0:
		return LEDGER_CARD_MEDIUM
	return LEDGER_CARD_COMPACT


func _ledger_icon_size() -> Vector2:
	var viewport_width := get_viewport_rect().size.x
	if viewport_width >= 1500.0:
		return LEDGER_ICON_DESKTOP
	if viewport_width >= 1152.0:
		return LEDGER_ICON_MEDIUM
	return LEDGER_ICON_COMPACT


func _apply_ledger_card_dimensions(button: Button) -> void:
	if button == null:
		return

	var card_size := _ledger_card_size()
	var icon_size := _ledger_icon_size()
	button.custom_minimum_size = card_size

	var icon_center := button.get_node_or_null(
		"ContentMargin/Content/IconViewport"
	) as CenterContainer
	if icon_center != null:
		icon_center.custom_minimum_size = icon_size

	var icon := button.find_child(
		"ItemIcon",
		true,
		false
	) as TextureRect
	if icon != null:
		icon.custom_minimum_size = icon_size


func _update_responsive_layout() -> void:
	var viewport_width := get_viewport_rect().size.x
	if _status_left_panel != null:
		_status_left_panel.custom_minimum_size.x = 280.0 if viewport_width <= 1280.0 else 340.0
	if _status_left_stack != null:
		_status_left_stack.add_theme_constant_override(
			"separation",
			7 if viewport_width <= 1280.0 else 10
		)
	if _status_minimap_frame != null:
		_status_minimap_frame.custom_minimum_size = (
			Vector2(400, 250)
			if viewport_width <= 1280.0
			else Vector2(480, 300)
		)
	if _ledger_category_panel != null:
		_ledger_category_panel.custom_minimum_size.x = 150.0
	if _ledger_detail_panel != null:
		_ledger_detail_panel.custom_minimum_size.x = 340.0
	for button in _item_buttons:
		_apply_ledger_card_dimensions(button)
	call_deferred("_update_ledger_grid_columns")


func _create_item_button(entry: Dictionary) -> Button:
	var definition: Dictionary = entry["definition"]
	var item_id := str(entry["item_id"])
	var button := Button.new()
	button.name = "Item_%s" % item_id
	button.custom_minimum_size = _ledger_card_size()
	button.tooltip_text = str(definition.get("description", ""))
	button.text = ""
	button.set_meta("inventory_category", str(definition.get("category", "carried")))
	button.set_meta("inventory_item_id", item_id)

	var content_margin := MarginContainer.new()
	content_margin.name = "ContentMargin"
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", 8)
	content_margin.add_theme_constant_override("margin_top", 16)
	content_margin.add_theme_constant_override("margin_right", 8)
	content_margin.add_theme_constant_override("margin_bottom", 6)
	button.add_child(content_margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	content_margin.add_child(content)
	var icon_center := CenterContainer.new()
	icon_center.name = "IconViewport"
	icon_center.custom_minimum_size = _ledger_icon_size()
	icon_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_center)
	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.custom_minimum_size = _ledger_icon_size()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = Assets.item_portrait(item_id)
	icon.material = _item_icon_material(item_id)
	icon.resized.connect(_update_item_icon_pivot.bind(icon))
	icon_center.add_child(icon)
	var category := str(definition.get("category", "carried"))
	var stamp := _label(_category_stamp(category), Palette.MUTED_TEXT, 10)
	stamp.name = "ItemStamp"
	stamp.position = Vector2(8, 6)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.visible = category in ["key", "relic", "cognitive", "equipment"]
	button.add_child(stamp)
	var name_label := _label(str(definition.get("display_name", entry["item_id"])).to_upper(), Palette.BODY_TEXT, 13)
	name_label.name = "ItemName"
	name_label.custom_minimum_size = Vector2(0, 36)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)
	var quantity := _label("×%d" % int(entry["quantity"]), Palette.GOLD_TEXT, 12)
	quantity.name = "ItemQuantity"
	quantity.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	quantity.offset_left = -48
	quantity.offset_top = 6
	quantity.offset_right = -8
	quantity.offset_bottom = 26
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quantity.visible = str(definition.get("category", "carried")) != "key"
	button.add_child(quantity)
	var selection_mark := ColorRect.new()
	selection_mark.name = "SelectionMark"
	selection_mark.position = Vector2(2, 52)
	selection_mark.size = Vector2(4, 84)
	selection_mark.color = Palette.GOLD_TEXT
	selection_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_mark.visible = item_id == _selected_item_id
	button.add_child(selection_mark)
	button.add_child(_create_focus_corner_marks())
	button.pressed.connect(_select_entry.bind(entry))
	button.focus_entered.connect(_refresh_item_focus.bind(button))
	button.focus_exited.connect(_refresh_item_focus.bind(button))
	_apply_item_button_style(button, category, item_id == _selected_item_id)
	return button


func _update_item_icon_pivot(icon: TextureRect) -> void:
	if icon == null:
		return
	icon.pivot_offset = icon.size * 0.5


func _create_focus_corner_marks() -> Control:
	var marks := Control.new()
	marks.name = "FocusCorners"
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marks.visible = false
	var corners := [
		[Vector2(0.0, 0.0), Vector4(5, 5, 15, 8)],
		[Vector2(1.0, 0.0), Vector4(-15, 5, -5, 8)],
		[Vector2(0.0, 1.0), Vector4(5, -8, 15, -5)],
		[Vector2(1.0, 1.0), Vector4(-15, -8, -5, -5)],
	]
	for index in corners.size():
		var mark := ColorRect.new()
		mark.name = "FocusCorner%d" % index
		mark.color = SYSTEM_TECH
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var corner: Array = corners[index]
		mark.anchor_left = (corner[0] as Vector2).x
		mark.anchor_top = (corner[0] as Vector2).y
		mark.anchor_right = (corner[0] as Vector2).x
		mark.anchor_bottom = (corner[0] as Vector2).y
		mark.offset_left = (corner[1] as Vector4).x
		mark.offset_top = (corner[1] as Vector4).y
		mark.offset_right = (corner[1] as Vector4).z
		mark.offset_bottom = (corner[1] as Vector4).w
		marks.add_child(mark)
	return marks


func _refresh_item_focus(button: Button) -> void:
	if button == null:
		return
	var selected := str(button.get_meta("inventory_item_id", "")) == _selected_item_id
	_apply_item_button_style(
		button,
		str(button.get_meta("inventory_category", "carried")),
		selected
	)


func _select_category(category: String) -> void:
	_selected_category = category
	if _ledger_filter_label != null:
		_ledger_filter_label.text = "%d SHOWN" % _filtered_entry_count(category)
	if _ledger_filter_button != null:
		_ledger_filter_button.text = "F  FILTER · %s" % str(CATEGORY_LABELS.get(category, category.to_upper()))
	_rebuild_item_grid()
	_focus_current_page()


func _cycle_ledger_filter() -> void:
	var current_index := CATEGORY_ORDER.find(_selected_category)
	var next_index := wrapi(current_index + 1, 0, CATEGORY_ORDER.size())
	_select_category(CATEGORY_ORDER[next_index])


func _toggle_ledger_sort() -> void:
	_sort_name_first = not _sort_name_first
	if _ledger_sort_button != null:
		_ledger_sort_button.text = "R  SORT · %s" % (
			"NAME / CLASS" if _sort_name_first else "CLASS / NAME"
		)
	_rebuild_item_grid()


func _select_entry(entry: Dictionary) -> void:
	_selected_item_id = str(entry.get("item_id", ""))
	_show_detail(entry)
	for button in _item_buttons:
		_apply_item_button_style(
			button,
			str(button.get_meta("inventory_category", "carried")),
			str(button.get_meta("inventory_item_id", "")) == _selected_item_id
		)


func _show_detail(entry: Dictionary) -> void:
	if _ledger_detail_icon == null:
		return
	if _ledger_detail_equip_button != null:
		_ledger_detail_equip_button.visible = false
		_ledger_detail_equip_button.disabled = true
	if entry.is_empty():
		_ledger_detail_icon.texture = Assets.texture("icon_unknown")
		_ledger_detail_icon.material = CanvasItemMaterial.new()
		_ledger_detail_name.text = "NO RECORD SELECTED"
		_ledger_detail_class.text = "CLASS · --"
		_ledger_detail_count.text = "×--"
		_ledger_detail_description.text = "Select a recovered object to inspect its ledger record."
		_ledger_detail_use.text = "PRIMARY USE: UNKNOWN"
		_ledger_detail_provenance.text = "PROVENANCE: --"
		return
	var definition: Dictionary = entry["definition"]
	var item_id := str(entry["item_id"])
	_ledger_detail_icon.texture = Assets.item_portrait(item_id)
	_ledger_detail_icon.material = _item_icon_material(item_id)
	_ledger_detail_name.text = str(definition.get("display_name", entry["item_id"])).to_upper()
	_ledger_detail_class.text = "%s · %s" % [
		str(definition.get("category", "carried")).to_upper(),
		str(definition.get("rarity", "unclassified")).to_upper(),
	]
	_ledger_detail_count.text = "×%d" % int(entry.get("quantity", 0))
	_ledger_detail_use.text = "PRIMARY USE: %s" % _usage_label(definition)
	_ledger_detail_description.text = str(definition.get("description", "No recovered archive description is available."))
	_ledger_detail_provenance.text = "PROVENANCE: %s" % str(definition.get("provenance", "LOCAL LEDGER / UNVERIFIED"))
	
	# Show equip button for equipment items if the slot is empty
	_show_equip_button_if_applicable(entry)


func _item_icon_material(item_id: String) -> Material:
	var effect_material := Assets.item_material(item_id)
	return effect_material if effect_material != null else CanvasItemMaterial.new()


## Show or hide the equip button for the given entry.
func _show_equip_button_if_applicable(entry: Dictionary) -> void:
	if _ledger_detail_equip_button == null or _inventory_manager == null:
		return
	var category := str(entry.get("definition", {}).get("category", "carried"))
	if category != "equipment":
		_ledger_detail_equip_button.visible = false
		_ledger_detail_equip_button.disabled = true
		return
	
	var item_id := StringName(str(entry["item_id"]))
	var slot_name := _get_equipment_slot_for_item(item_id)
	if slot_name == &"":
		_ledger_detail_equip_button.visible = false
		_ledger_detail_equip_button.disabled = true
		return
	
	if _inventory_manager.call("is_slot_filled", slot_name):
		_ledger_detail_equip_button.text = "SLOT IN USE"
		_ledger_detail_equip_button.disabled = true
		_ledger_detail_equip_button.visible = true
	else:
		var slot_label := String(slot_name).to_upper()
		_ledger_detail_equip_button.text = "EQUIP TO %s SLOT" % slot_label
		_ledger_detail_equip_button.disabled = false
		_ledger_detail_equip_button.visible = true


func _update_category_button_states() -> void:
	for category in _category_buttons:
		var button := _category_buttons[category] as Button
		button.text = "%-14s %3d" % [
			str(CATEGORY_LABELS.get(category, category.to_upper())),
			_category_unit_count(category),
		]
		_apply_button_style(button, category == _selected_category)


func _focus_current_page() -> void:
	match _current_page:
		PAGE_STATUS:
			if _page_buttons.has(PAGE_STATUS):
				(_page_buttons[PAGE_STATUS] as Button).grab_focus()
		PAGE_HISTORY:
			if _history_log != null:
				_history_log.grab_focus()
		PAGE_LEDGER:
			if not _item_buttons.is_empty():
				_item_buttons[0].grab_focus()
			elif _category_buttons.has(_selected_category):
				(_category_buttons[_selected_category] as Button).grab_focus()
		PAGE_EQUIPMENT:
			if _equipment_action_button != null and _equipment_action_button.visible:
				_equipment_action_button.grab_focus()
			elif _page_buttons.has(PAGE_EQUIPMENT):
				(_page_buttons[PAGE_EQUIPMENT] as Button).grab_focus()


func _select_page(page_name: String, focus := true) -> void:
	_current_page = page_name if PAGE_ORDER.has(page_name) else PAGE_STATUS
	for page in [_status_page, _history_page, _ledger_page, _equipment_page]:
		if page != null:
			page.visible = false
	match _current_page:
		PAGE_STATUS:
			if _status_page != null:
				_status_page.visible = true
		PAGE_HISTORY:
			if _history_page != null:
				_history_page.visible = true
			_rebuild_history_log()
		PAGE_LEDGER:
			if _ledger_page != null:
				_ledger_page.visible = true
			_rebuild_item_grid()
		PAGE_EQUIPMENT:
			if _equipment_page != null:
				_equipment_page.visible = true
			_refresh_equipment_page()
	for page in _page_buttons:
		_apply_button_style(_page_buttons[page] as Button, page == _current_page)
	_update_input_prompts()
	if focus:
		_focus_current_page()


func _cycle_page(offset: int) -> void:
	var current_index := PAGE_ORDER.find(_current_page)
	_select_page(PAGE_ORDER[wrapi(current_index + offset, 0, PAGE_ORDER.size())])


func _append_history_entry(title: String, body: String, color: Color = Palette.BODY_TEXT) -> void:
	var title_text := title.strip_edges()
	var body_text := body.strip_edges()
	if title_text.is_empty() and body_text.is_empty():
		return
	_history_counter += 1
	_history_entries.append({
		"index": _history_counter,
		"title": title_text,
		"body": body_text,
		"color": color,
	})
	if _history_entries.size() > 64:
		_history_entries = _history_entries.slice(_history_entries.size() - 64, _history_entries.size())
	_rebuild_history_log()


func _rebuild_history_log() -> void:
	if _history_log == null or _history_empty == null:
		return
	_history_empty.visible = _history_entries.is_empty()
	_history_log.visible = not _history_entries.is_empty()
	if _history_entries.is_empty():
		_history_log.text = ""
		return
	var lines: Array[String] = []
	for entry in _history_entries:
		var color: Color = entry.get("color", Palette.BODY_TEXT)
		var title := str(entry.get("title", "ENTRY")).to_upper()
		var body := str(entry.get("body", ""))
		lines.append("[color=#%s][b]%03d %s[/b][/color]" % [color.to_html(false), int(entry.get("index", 0)), title])
		if not body.strip_edges().is_empty():
			lines.append(body)
		lines.append("")
	_history_log.text = "\n".join(lines)
	_history_log.scroll_to_line(max(0, _history_log.get_line_count() - 1))


func _update_status_row(row: HBoxContainer, icon_path: String, text: String, color: Color) -> void:
	if row == null:
		return
	if row.has_method("configure"):
		row.call("configure", icon_path, text, Vector2(32, 32), color)
		return
	var icon_rect := row.get_node_or_null("Icon") as TextureRect
	var label := row.get_node_or_null("Label") as Label
	if icon_rect != null:
		icon_rect.texture = Styles.load_texture(icon_path)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if label != null:
		label.text = text
		Styles.apply_label(label, color, 14)


func _create_status_row(icon_path: String, text: String, color: Color = Palette.BODY_TEXT) -> HBoxContainer:
	var row := IconLabelScene.instantiate() as HBoxContainer
	if row == null:
		row = HBoxContainer.new()
	row.custom_minimum_size.y = maxf(row.custom_minimum_size.y, 32.0)
	row.visible = true
	_update_status_row(row, icon_path, text, color)
	return row


func _progress_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", Styles.bar_background_style())
	bar.add_theme_stylebox_override("fill", Styles.bar_fill_style(color))
	return bar


func _update_count_label() -> void:
	if _count_label == null:
		return
	_count_label.text = "%d RECORDS · %d UNITS" % [_entries.size(), _total_units(_entries)]


func _update_input_prompts() -> void:
	if _close_button != null:
		_close_button.text = "B  CLOSE" if _controller_prompts_active else "ESC  CLOSE"
	if _footer_hint != null:
		if _controller_prompts_active:
			_footer_hint.text = "LB  PREVIOUS PAGE     RB  NEXT PAGE%s     B  CLOSE" % (
				"     X  FILTER     R3  SORT     A  SELECT" if _current_page == PAGE_LEDGER else ""
			)
		else:
			_footer_hint.text = "Q  PREVIOUS PAGE     E  NEXT PAGE%s     ESC  CLOSE" % (
				"     F  FILTER     R  SORT" if _current_page == PAGE_LEDGER else ""
			)
	if _ledger_filter_button != null:
		_ledger_filter_button.text = "%s  FILTER · %s" % [
			"X" if _controller_prompts_active else "F",
			str(CATEGORY_LABELS.get(_selected_category, _selected_category.to_upper())),
		]
	if _ledger_sort_button != null:
		_ledger_sort_button.text = "%s  SORT · %s" % [
			"R3" if _controller_prompts_active else "R",
			"NAME / CLASS" if _sort_name_first else "CLASS / NAME",
		]
	if _ledger_filter_label != null:
		_ledger_filter_label.text = "%d SHOWN" % _filtered_entry_count(_selected_category)


func _filtered_entry_count(category: String) -> int:
	if category == "all":
		return _entries.size()
	var count := 0
	for entry in _entries:
		var definition: Dictionary = entry.get("definition", {})
		if str(definition.get("category", "carried")) == category:
			count += 1
	return count


func _category_unit_count(category: String) -> int:
	if category == "all":
		return _total_units(_entries)
	var count := 0
	for entry in _entries:
		var definition: Dictionary = entry.get("definition", {})
		if str(definition.get("category", "carried")) == category:
			count += int(entry.get("quantity", 0))
	return count


func _apply_button_style(button: Button, selected := false) -> void:
	var normal := Styles.panel_style(true)
	normal.border_color = Palette.GOLD_TEXT if selected else Palette.BORDER_DIM
	normal.bg_color = Color(0.08, 0.095, 0.09, 0.98) if selected else Palette.PANEL_DEEP
	normal.border_width_left = 2 if selected else 1
	normal.border_width_top = 2 if selected else 1
	normal.border_width_right = 2 if selected else 1
	normal.border_width_bottom = 2 if selected else 1
	var hover := normal.duplicate()
	hover.border_color = Palette.GOLD_TEXT
	hover.bg_color = Color(0.12, 0.13, 0.11, 0.98)
	var disabled := normal.duplicate()
	disabled.border_color = Color(Palette.BORDER_DIM, 0.45)
	disabled.bg_color = Color(0.025, 0.03, 0.03, 0.88)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Palette.GOLD_TEXT if selected else Palette.BODY_TEXT)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_TEXT)
	button.add_theme_color_override("font_focus_color", Palette.GOLD_TEXT)
	button.add_theme_color_override("font_disabled_color", Palette.MUTED_TEXT)
	button.add_theme_font_size_override("font_size", 11)


func _apply_item_button_style(button: Button, category: String, selected := false) -> void:
	var normal := Styles.panel_style(true)
	var category_color := _category_accent(category)
	normal.border_color = Palette.GOLD_TEXT if selected else category_color
	normal.bg_color = Color(0.08, 0.095, 0.09, 0.98) if selected else Palette.PANEL_DEEP
	var base_width := 2 if category in ["key", "equipment"] else 1
	var border_width := 2 if selected else base_width
	normal.border_width_left = border_width
	normal.border_width_top = border_width
	normal.border_width_right = border_width
	normal.border_width_bottom = border_width
	var hover := normal.duplicate()
	hover.border_color = Palette.GOLD_TEXT if selected else Palette.GOLD_TEXT.lightened(0.12)
	hover.bg_color = Color(0.12, 0.13, 0.11, 0.98)
	var focus := StyleBoxEmpty.new()
	var disabled := normal.duplicate()
	disabled.border_color = Color(category_color, 0.3)
	disabled.bg_color = Color(0.025, 0.03, 0.03, 0.88)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Palette.GOLD_TEXT if selected else Palette.BODY_TEXT)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_TEXT)
	button.add_theme_color_override("font_focus_color", Palette.GOLD_TEXT)
	button.add_theme_color_override("font_disabled_color", Palette.MUTED_TEXT)
	button.add_theme_font_size_override("font_size", 11)
	var name_label := button.find_child("ItemName", true, false) as Label
	if name_label != null:
		name_label.add_theme_color_override(
			"font_color",
			Palette.GOLD_TEXT if selected else Color(Palette.BODY_TEXT, 0.76)
		)
	var selection_mark := button.get_node_or_null("SelectionMark") as ColorRect
	if selection_mark != null:
		selection_mark.visible = selected
	var focus_corners := button.get_node_or_null("FocusCorners") as Control
	if focus_corners != null:
		focus_corners.visible = button.has_focus()
	var icon := button.find_child("ItemIcon", true, false) as TextureRect
	if icon != null:
		icon.pivot_offset = icon.size * 0.5
		icon.scale = Vector2.ONE * (1.03 if selected else 1.0)


func _panel(deep: bool, minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _inventory_panel_style(deep))
	return panel


func _section_panel(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	var style := _inventory_panel_style(true)
	style.bg_color = Color(0.025, 0.032, 0.032, 0.94)
	style.border_color = Color(Palette.BORDER_DIM, 0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _inventory_panel_style(deep := false) -> StyleBoxFlat:
	var style := Styles.panel_style(deep)
	style.bg_color.a = 0.96 if deep else 0.98
	return style


func _label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	Styles.apply_label(label, color, size)
	return label


func _build_divider() -> HSeparator:
	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Palette.BORDER_DIM)
	return divider


func _add_frame_texture(parent: Control) -> void:
	var path := Assets.asset_path("frame")
	if path.is_empty():
		return
	var frame_texture := NinePatchRect.new()
	frame_texture.name = "ProductionFrame"
	frame_texture.show_behind_parent = true
	frame_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Styles.configure_nine_patch(frame_texture, path):
		frame_texture.draw_center = false
		# The production frame source is a compact HUD ornament. Stretching its
		# border across the full Ledger creates a second, overbright arch behind
		# the page hierarchy; the styled ReliquaryFrame owns this outline.
		frame_texture.visible = false
	parent.add_child(frame_texture)
	parent.move_child(frame_texture, 0)


func _add_corner_ornaments(parent: Control) -> void:
	for asset_id in ["ornament_nw", "ornament_ne", "ornament_sw", "ornament_se"]:
		var ornament := TextureRect.new()
		ornament.name = asset_id.capitalize()
		ornament.texture = Assets.texture(asset_id)
		ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ornament.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ornament.custom_minimum_size = Vector2(48, 48)
		parent.add_child(ornament)
		match asset_id:
			"ornament_nw":
				ornament.position = Vector2(4, 4)
			"ornament_ne":
				ornament.set_anchors_preset(Control.PRESET_TOP_RIGHT)
				ornament.position = Vector2(-52, 4)
			"ornament_sw":
				ornament.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
				ornament.position = Vector2(4, -52)
			"ornament_se":
				ornament.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
				ornament.position = Vector2(-52, -52)


func _total_units(entries: Array[Dictionary]) -> int:
	var total := 0
	for entry in entries:
		total += int(entry.get("quantity", 0))
	return total


func _contains_item(entries: Array[Dictionary], item_id: String) -> bool:
	for entry in entries:
		if str(entry.get("item_id", "")) == item_id:
			return true
	return false


func _sort_ledger_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_definition: Dictionary = a.get("definition", {})
	var b_definition: Dictionary = b.get("definition", {})
	var a_category := str(a_definition.get("category", "carried"))
	var b_category := str(b_definition.get("category", "carried"))
	var a_order := int(CATEGORY_SORT_ORDER.get(a_category, 99))
	var b_order := int(CATEGORY_SORT_ORDER.get(b_category, 99))
	var a_name := str(a_definition.get("display_name", a.get("item_id", ""))).to_lower()
	var b_name := str(b_definition.get("display_name", b.get("item_id", ""))).to_lower()
	if not _sort_name_first and a_order != b_order:
		return a_order < b_order
	if a_name != b_name:
		return a_name < b_name
	if _sort_name_first and a_order != b_order:
		return a_order < b_order
	return str(a.get("item_id", "")) < str(b.get("item_id", ""))


func _category_accent(category: String) -> Color:
	match category:
		"key":
			return Color("#8f7744")
		"relic":
			return Color("#aaa17f")
		"cognitive":
			return Color(SYSTEM_TECH, 0.78)
		"equipment":
			return Color("#9b824c")
		"resources":
			return Color(Palette.BORDER_DIM, 0.68)
	return Palette.BORDER_DIM


func _category_stamp(category: String) -> String:
	return {
		"resources": "MAT",
		"relic": "REL",
		"key": "KEY",
		"cognitive": "COG",
		"equipment": "EQP",
	}.get(category, "MISC")


func _usage_label(definition: Dictionary) -> String:
	if definition.has("used_for"):
		return str(definition["used_for"]).to_upper()
	match str(definition.get("category", "carried")):
		"resources":
			return "REPAIRS / FABRICATION / FIELD COMPONENTS"
		"equipment":
			return "ACTIVE LOADOUT SLOT"
		"key":
			return "FIELD ACCESS"
		"cognitive":
			return "COGNITIVE STATE"
		"relic":
			return "CONTEXT / RITUAL EVIDENCE"
	return "UNKNOWN"
