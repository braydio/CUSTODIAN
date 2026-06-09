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

const PAGE_STATUS := "status"
const PAGE_HISTORY := "history"
const PAGE_LEDGER := "ledger"

const PAGE_ORDER := [PAGE_STATUS, PAGE_HISTORY, PAGE_LEDGER]
const PAGE_LABELS := {
	"status": "STATUS",
	"history": "HISTORY",
	"ledger": "LEDGER",
}

const CATEGORY_ORDER := ["all", "key", "relic", "cognitive", "carried", "resources"]
const CATEGORY_LABELS := {
	"all": "ALL CARRIED",
	"key": "KEY OBJECTS",
	"relic": "RELICS",
	"cognitive": "COGNITIVE",
	"carried": "MISCELLANY",
	"resources": "MATERIAL RESOURCES",
}

@export var inventory: Inventory

var _inventory_manager: Node = null
var _resource_ledger: Node = null
var _selected_category := "all"
var _selected_item_id := ""
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
var _page_hint: Label
var _pages_root: Control
var _status_page: Control
var _history_page: Control
var _ledger_page: Control

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
var _history_log: RichTextLabel
var _history_empty: Label

var _ledger_category_list: VBoxContainer
var _ledger_item_grid: GridContainer
var _ledger_count_label: Label
var _ledger_empty_label: Label
var _ledger_detail_icon: TextureRect
var _ledger_detail_name: Label
var _ledger_detail_class: Label
var _ledger_detail_count: Label
var _ledger_detail_description: Label
var _ledger_detail_provenance: Label


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
	visible = false


func open(inv: Inventory = null) -> void:
	if inv != null:
		inventory = inv
	_refresh_entries()
	_select_page(PAGE_STATUS, false)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_focus_current_page()


func close() -> void:
	if not visible:
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
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
	_update_status_row(_status_phase_row, Catalog.ICON_OBJECTIVE, "PHASE: %s" % text, Palette.BLUE_TECH)
	_append_history_entry("PHASE", text, Palette.BLUE_TECH)


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
	_update_status_row(_status_return_row, Catalog.ICON_RETURN_MOORING, text, Palette.BLUE_TECH if active else Palette.MUTED_TEXT)
	_append_history_entry("RETURN MOORING", text, Palette.BLUE_TECH if active else Palette.MUTED_TEXT)


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
	backdrop.color = Color(0.01, 0.015, 0.018, 0.92)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_frame = PanelContainer.new()
	_frame.name = "ReliquaryFrame"
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.offset_left = 18.0
	_frame.offset_top = 18.0
	_frame.offset_right = -18.0
	_frame.offset_bottom = -18.0
	_frame.add_theme_stylebox_override("panel", Styles.panel_style())
	add_child(_frame)
	_add_frame_texture(_frame)
	_add_corner_ornaments(_frame)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 28)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_right", 28)
	outer.add_theme_constant_override("margin_bottom", 24)
	_frame.add_child(outer)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 12)
	outer.add_child(stack)

	stack.add_child(_build_header())
	stack.add_child(_build_divider())
	stack.add_child(_build_page_rail())
	stack.add_child(_build_divider())

	_pages_root = Control.new()
	_pages_root.name = "PageRoot"
	_pages_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pages_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(_pages_root)

	_status_page = _build_status_page()
	_history_page = _build_history_page()
	_ledger_page = _build_ledger_page()
	_pages_root.add_child(_status_page)
	_pages_root.add_child(_history_page)
	_pages_root.add_child(_ledger_page)


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 64
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var eyebrow := _label("CUSTODIAN FIELD LEDGER / STATUS ACCESS", Palette.MUTED_TEXT, 12)
	var title := _label("RELIQUARY INVENTORY", Palette.GOLD_TEXT, 25)
	title_stack.add_child(eyebrow)
	title_stack.add_child(title)
	header.add_child(title_stack)
	_header_status = _label("PAGE: STATUS", Palette.BLUE_TECH, 13)
	_header_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_header_status)
	_count_label = _label("0 RECORDS", Palette.BLUE_TECH, 13)
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_count_label)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "CLOSE  [I / Y]"
	close_button.custom_minimum_size = Vector2(130, 38)
	_apply_button_style(close_button)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	return header


func _build_page_rail() -> Control:
	var rail := HBoxContainer.new()
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.add_theme_constant_override("separation", 8)
	var rail_label := _label("PAGES", Palette.MUTED_TEXT, 11)
	rail.add_child(rail_label)
	for page in PAGE_ORDER:
		var button := Button.new()
		button.name = "%sButton" % PAGE_LABELS[page].capitalize()
		button.text = PAGE_LABELS[page]
		button.custom_minimum_size = Vector2(116, 34)
		button.pressed.connect(_select_page.bind(page))
		_apply_button_style(button)
		_page_buttons[page] = button
		rail.add_child(button)
	_page_hint = _label("STATUS FIRST / HISTORY SECOND / LEDGER LAST", Palette.MUTED_TEXT, 11)
	_page_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rail.add_child(_page_hint)
	return rail


func _build_status_page() -> Control:
	var page := HBoxContainer.new()
	page.name = "StatusPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)

	var left_panel := _panel(true, Vector2(340, 0))
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 18)
	left_margin.add_theme_constant_override("margin_top", 18)
	left_margin.add_theme_constant_override("margin_right", 18)
	left_margin.add_theme_constant_override("margin_bottom", 18)
	left_panel.add_child(left_margin)
	var left_stack := VBoxContainer.new()
	left_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_stack.add_theme_constant_override("separation", 10)
	left_margin.add_child(left_stack)

	left_stack.add_child(_label("FIELD POSTURE", Palette.GOLD_TEXT, 12))
	_status_health_label = _label("HEALTH 100/100", Palette.BODY_TEXT, 18)
	left_stack.add_child(_status_health_label)
	_status_health_bar = _progress_bar(Palette.DANGER)
	left_stack.add_child(_status_health_bar)
	_status_stamina_label = _label("STAMINA READY", Palette.EVRFOREST_PALE_GREEN, 14)
	left_stack.add_child(_status_stamina_label)
	_status_stamina_bar = _progress_bar(Palette.EVRFOREST_PALE_GREEN)
	left_stack.add_child(_status_stamina_bar)

	left_stack.add_child(_build_divider())
	_status_summary = _label("BLACK RELIQUARY / FIELD STATUS", Palette.MUTED_TEXT, 11)
	_status_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_stack.add_child(_status_summary)

	left_stack.add_child(_build_divider())
	_status_location_row = _create_status_row(Catalog.COMPASS_ROSE_SMALL, "LOCATION: --")
	_status_phase_row = _create_status_row(Catalog.ICON_OBJECTIVE, "PHASE: --")
	_status_objective_row = _create_status_row(Catalog.ICON_OBJECTIVE, "OBJECTIVE: --")
	_status_key_row = _create_status_row(Catalog.ICON_KEY_ITEM, "Sundered Gate Key: MISSING")
	_status_gate_row = _create_status_row(Catalog.ICON_GATE_LOCKED, "MAIN GATE: LOCKED")
	_status_return_row = _create_status_row(Catalog.ICON_RETURN_MOORING, "RETURN MOORING: DORMANT")
	for row in [_status_location_row, _status_phase_row, _status_objective_row, _status_key_row, _status_gate_row, _status_return_row]:
		left_stack.add_child(row)

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
		_status_minimap_frame.custom_minimum_size = Vector2(720, 540)
		minimap_stack.add_child(_status_minimap_frame)

	page.add_child(left_panel)
	page.add_child(minimap_panel)
	return page


func _build_history_page() -> Control:
	var page := _panel(true, Vector2(0, 0))
	page.name = "HistoryPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
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
	stack.add_child(_label("Recent state changes are retained here as a readable field record.", Palette.MUTED_TEXT, 11))
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
	var page := _panel(true, Vector2(0, 0))
	page.name = "LedgerPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
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
	stack.add_child(_label("RECOVERED OBJECT REGISTER", Palette.GOLD_TEXT, 12))
	stack.add_child(_build_ledger_body())
	return page


func _build_ledger_body() -> Control:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)

	var categories := _panel(true, Vector2(180, 0))
	var category_margin := MarginContainer.new()
	category_margin.add_theme_constant_override("margin_left", 12)
	category_margin.add_theme_constant_override("margin_top", 14)
	category_margin.add_theme_constant_override("margin_right", 12)
	category_margin.add_theme_constant_override("margin_bottom", 14)
	categories.add_child(category_margin)
	_ledger_category_list = VBoxContainer.new()
	_ledger_category_list.add_theme_constant_override("separation", 8)
	category_margin.add_child(_ledger_category_list)
	_ledger_category_list.add_child(_label("CLASSIFICATION", Palette.GOLD_TEXT, 12))
	for category in CATEGORY_ORDER:
		var button := Button.new()
		button.text = CATEGORY_LABELS[category]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 42
		button.pressed.connect(_select_category.bind(category))
		_apply_button_style(button)
		_category_buttons[category] = button
		_ledger_category_list.add_child(button)
	body.add_child(categories)

	var records := _panel(true, Vector2(520, 0))
	records.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var record_margin := MarginContainer.new()
	record_margin.add_theme_constant_override("margin_left", 14)
	record_margin.add_theme_constant_override("margin_top", 14)
	record_margin.add_theme_constant_override("margin_right", 14)
	record_margin.add_theme_constant_override("margin_bottom", 14)
	records.add_child(record_margin)
	var record_stack := VBoxContainer.new()
	record_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	record_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	record_stack.add_theme_constant_override("separation", 10)
	record_margin.add_child(record_stack)
	record_stack.add_child(_label("FIELD REGISTER", Palette.GOLD_TEXT, 12))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	record_stack.add_child(scroll)
	_ledger_item_grid = GridContainer.new()
	_ledger_item_grid.columns = 4
	_ledger_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ledger_item_grid.add_theme_constant_override("h_separation", 8)
	_ledger_item_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_ledger_item_grid)
	_ledger_empty_label = _label("NO CARRIED OBJECTS RECORDED\n\nField ledger awaits recovered evidence.", Palette.MUTED_TEXT, 15)
	_ledger_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ledger_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ledger_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	record_stack.add_child(_ledger_empty_label)
	body.add_child(records)

	body.add_child(_build_ledger_detail_panel())
	return body


func _build_ledger_detail_panel() -> Control:
	var detail := _panel(true, Vector2(310, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	detail.add_child(margin)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	stack.add_child(_label("INSPECTED RECORD", Palette.GOLD_TEXT, 12))
	_ledger_detail_icon = TextureRect.new()
	_ledger_detail_icon.custom_minimum_size = Vector2(112, 112)
	_ledger_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ledger_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ledger_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stack.add_child(_ledger_detail_icon)
	_ledger_detail_name = _label("NO RECORD SELECTED", Palette.BODY_TEXT, 20)
	_ledger_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_ledger_detail_name)
	_ledger_detail_class = _label("CLASSIFICATION: --", Palette.BLUE_TECH, 12)
	stack.add_child(_ledger_detail_class)
	_ledger_detail_count = _label("QUANTITY: --", Palette.GOLD_TEXT, 13)
	stack.add_child(_ledger_detail_count)
	stack.add_child(_build_divider())
	_ledger_detail_description = _label("Select a recovered object to inspect its ledger record.", Palette.BODY_TEXT, 14)
	_ledger_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ledger_detail_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(_ledger_detail_description)
	_ledger_detail_provenance = _label("PROVENANCE: --", Palette.MUTED_TEXT, 11)
	_ledger_detail_provenance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_ledger_detail_provenance)
	return detail


func _connect_resource_ledger() -> void:
	_resource_ledger = get_node_or_null("/root/ResourceLedger")
	if _resource_ledger != null and _resource_ledger.has_signal("changed"):
		var callback := Callable(self, "_refresh_entries")
		if not _resource_ledger.is_connected("changed", callback):
			_resource_ledger.connect("changed", callback)


func _connect_live_inventory() -> void:
	_inventory_manager = get_node_or_null("/root/InventoryManager")
	if _inventory_manager != null and _inventory_manager.has_signal("inventory_changed"):
		var callback := Callable(self, "_refresh_entries")
		if not _inventory_manager.is_connected("inventory_changed", callback):
			_inventory_manager.connect("inventory_changed", callback)


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
	for child in _ledger_item_grid.get_children():
		child.queue_free()
	_item_buttons.clear()
	var filtered: Array[Dictionary] = []
	for entry in _entries:
		var definition: Dictionary = entry["definition"]
		if _selected_category == "all" or str(definition.get("category", "carried")) == _selected_category:
			filtered.append(entry)
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


func _create_item_button(entry: Dictionary) -> Button:
	var definition: Dictionary = entry["definition"]
	var button := Button.new()
	button.name = "Item_%s" % str(entry["item_id"])
	button.custom_minimum_size = Vector2(112, 128)
	button.tooltip_text = str(definition.get("description", ""))
	button.text = "%s\nx%d" % [str(definition.get("display_name", entry["item_id"])).to_upper(), int(entry["quantity"])]
	button.icon = Assets.item_icon(str(entry["item_id"]))
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(_select_entry.bind(entry))
	button.focus_entered.connect(_select_entry.bind(entry))
	_apply_button_style(button, str(entry["item_id"]) == _selected_item_id)
	return button


func _select_category(category: String) -> void:
	_selected_category = category
	_rebuild_item_grid()
	_focus_current_page()


func _select_entry(entry: Dictionary) -> void:
	_selected_item_id = str(entry.get("item_id", ""))
	_show_detail(entry)
	for button in _item_buttons:
		_apply_button_style(button, button.name == "Item_%s" % _selected_item_id)


func _show_detail(entry: Dictionary) -> void:
	if _ledger_detail_icon == null:
		return
	if entry.is_empty():
		_ledger_detail_icon.texture = Assets.texture("icon_unknown")
		_ledger_detail_name.text = "NO RECORD SELECTED"
		_ledger_detail_class.text = "CLASSIFICATION: --"
		_ledger_detail_count.text = "QUANTITY: --"
		_ledger_detail_description.text = "Select a recovered object to inspect its ledger record."
		_ledger_detail_provenance.text = "PROVENANCE: --"
		return
	var definition: Dictionary = entry["definition"]
	_ledger_detail_icon.texture = Assets.item_icon(str(entry["item_id"]))
	_ledger_detail_name.text = str(definition.get("display_name", entry["item_id"])).to_upper()
	_ledger_detail_class.text = "CLASSIFICATION: %s / %s" % [
		str(definition.get("category", "carried")).to_upper(),
		str(definition.get("rarity", "unclassified")).to_upper(),
	]
	_ledger_detail_count.text = "QUANTITY: %d" % int(entry.get("quantity", 0))
	_ledger_detail_description.text = str(definition.get("description", "No recovered archive description is available."))
	_ledger_detail_provenance.text = "PROVENANCE: %s" % str(definition.get("provenance", "LOCAL LEDGER / UNVERIFIED"))


func _update_category_button_states() -> void:
	for category in _category_buttons:
		_apply_button_style(_category_buttons[category] as Button, category == _selected_category)


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


func _select_page(page_name: String, focus := true) -> void:
	_current_page = page_name if PAGE_ORDER.has(page_name) else PAGE_STATUS
	if _header_status != null:
		_header_status.text = "PAGE: %s" % PAGE_LABELS.get(_current_page, _current_page.to_upper())
	for page in [_status_page, _history_page, _ledger_page]:
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
	if _page_hint != null:
		_page_hint.text = "STATUS FIRST / HISTORY SECOND / LEDGER LAST"
	for page in _page_buttons:
		_apply_button_style(_page_buttons[page] as Button, page == _current_page)
	if focus:
		_focus_current_page()


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
	_count_label.text = "%d RECORDS / %d UNITS" % [_entries.size(), _total_units(_entries)]


func _apply_button_style(button: Button, selected := false) -> void:
	var normal := Styles.panel_style(true)
	normal.border_color = Palette.GOLD_TEXT if selected else Palette.BORDER_DIM
	normal.bg_color = Color(0.08, 0.095, 0.09, 0.98) if selected else Palette.PANEL_DEEP
	var hover := normal.duplicate()
	hover.border_color = Palette.GOLD_TEXT
	hover.bg_color = Color(0.12, 0.13, 0.11, 0.98)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Palette.GOLD_TEXT if selected else Palette.BODY_TEXT)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_TEXT)
	button.add_theme_color_override("font_focus_color", Palette.GOLD_TEXT)
	button.add_theme_font_size_override("font_size", 11)


func _panel(deep: bool, minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", Styles.panel_style(deep))
	return panel


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
	Styles.configure_nine_patch(frame_texture, path)
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
