extends Control
class_name InventoryUI

signal closed()

const Assets := preload("res://game/ui/inventory/inventory_asset_catalog.gd")
const ItemCatalog := preload("res://game/ui/inventory/inventory_item_catalog.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")
const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")

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

var _frame: PanelContainer
var _category_list: VBoxContainer
var _item_grid: GridContainer
var _count_label: Label
var _empty_label: Label
var _detail_icon: TextureRect
var _detail_name: Label
var _detail_class: Label
var _detail_count: Label
var _detail_description: Label
var _detail_provenance: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("gameplay_overlay")
	_build_interface()
	_connect_live_inventory()
	_connect_resource_ledger()
	_load_resource_defs()
	visible = false


func open(inv: Inventory = null) -> void:
	if inv != null:
		inventory = inv
	_refresh_entries()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_focus_first_available()


func close() -> void:
	if not visible:
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func _connect_resource_ledger() -> void:
	_resource_ledger = get_node_or_null("/root/ResourceLedger")
	if _resource_ledger != null and _resource_ledger.has_signal("changed"):
		var callback := Callable(self, "_refresh_entries")
		if not _resource_ledger.is_connected("changed", callback):
			_resource_ledger.connect("changed", callback)


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


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.015, 0.018, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_frame = PanelContainer.new()
	_frame.name = "ReliquaryFrame"
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.position = Vector2(-540, -340)
	_frame.size = Vector2(1080, 680)
	_frame.add_theme_stylebox_override("panel", Styles.panel_style())
	add_child(_frame)
	_add_frame_texture(_frame)
	_add_corner_ornaments(_frame)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 28)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_right", 28)
	outer.add_theme_constant_override("margin_bottom", 22)
	_frame.add_child(outer)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	outer.add_child(stack)
	stack.add_child(_build_header())
	stack.add_child(_build_divider())
	stack.add_child(_build_body())
	stack.add_child(_build_footer())


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 64
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var eyebrow := _label("CUSTODIAN FIELD LEDGER / CARRIED OBJECTS", Palette.MUTED_TEXT, 12)
	var title := _label("RELIQUARY INVENTORY", Palette.GOLD_TEXT, 25)
	title_stack.add_child(eyebrow)
	title_stack.add_child(title)
	header.add_child(title_stack)
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


func _build_body() -> Control:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)

	var categories := _panel(true, Vector2(180, 0))
	var category_margin := MarginContainer.new()
	category_margin.add_theme_constant_override("margin_left", 12)
	category_margin.add_theme_constant_override("margin_top", 14)
	category_margin.add_theme_constant_override("margin_right", 12)
	category_margin.add_theme_constant_override("margin_bottom", 14)
	categories.add_child(category_margin)
	_category_list = VBoxContainer.new()
	_category_list.add_theme_constant_override("separation", 8)
	category_margin.add_child(_category_list)
	_category_list.add_child(_label("CLASSIFICATION", Palette.GOLD_TEXT, 12))
	for category in CATEGORY_ORDER:
		var button := Button.new()
		button.text = CATEGORY_LABELS[category]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 42
		button.pressed.connect(_select_category.bind(category))
		_apply_button_style(button)
		_category_buttons[category] = button
		_category_list.add_child(button)
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
	record_stack.add_theme_constant_override("separation", 10)
	record_margin.add_child(record_stack)
	record_stack.add_child(_label("RECOVERED OBJECT REGISTER", Palette.GOLD_TEXT, 12))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	record_stack.add_child(scroll)
	_item_grid = GridContainer.new()
	_item_grid.columns = 4
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_grid.add_theme_constant_override("h_separation", 8)
	_item_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_item_grid)
	_empty_label = _label("NO CARRIED OBJECTS RECORDED\n\nField ledger awaits recovered evidence.", Palette.MUTED_TEXT, 15)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	record_stack.add_child(_empty_label)
	body.add_child(records)

	body.add_child(_build_detail_panel())
	return body


func _build_detail_panel() -> Control:
	var detail := _panel(true, Vector2(310, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	detail.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	stack.add_child(_label("INSPECTED RECORD", Palette.GOLD_TEXT, 12))
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(112, 112)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stack.add_child(_detail_icon)
	_detail_name = _label("NO RECORD SELECTED", Palette.BODY_TEXT, 20)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_detail_name)
	_detail_class = _label("CLASSIFICATION: --", Palette.BLUE_TECH, 12)
	stack.add_child(_detail_class)
	_detail_count = _label("QUANTITY: --", Palette.GOLD_TEXT, 13)
	stack.add_child(_detail_count)
	stack.add_child(_build_divider())
	_detail_description = _label("Select a recovered object to inspect its ledger record.", Palette.BODY_TEXT, 14)
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(_detail_description)
	_detail_provenance = _label("PROVENANCE: --", Palette.MUTED_TEXT, 11)
	_detail_provenance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_detail_provenance)
	return detail


func _build_footer() -> Control:
	var footer := HBoxContainer.new()
	var hint := _label("SELECT RECORD  [MOUSE / D-PAD]     CLOSE  [I / TAB / Y / ESC]", Palette.MUTED_TEXT, 11)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(hint)
	footer.add_child(_label("AUTHORITY: LOCAL CUSTODIAN", Palette.BORDER, 11))
	return footer


func _connect_live_inventory() -> void:
	_inventory_manager = get_node_or_null("/root/InventoryManager")
	if _inventory_manager != null and _inventory_manager.has_signal("inventory_changed"):
		var callback := Callable(self, "_refresh_entries")
		if not _inventory_manager.is_connected("inventory_changed", callback):
			_inventory_manager.connect("inventory_changed", callback)


func _refresh_entries() -> void:
	_entries.clear()
	_load_carried_items()
	_load_resources()
	_rebuild_item_grid()


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
	for child in _item_grid.get_children():
		child.queue_free()
	_item_buttons.clear()
	var filtered: Array[Dictionary] = []
	for entry in _entries:
		var definition: Dictionary = entry["definition"]
		if _selected_category == "all" or str(definition.get("category", "carried")) == _selected_category:
			filtered.append(entry)
	_count_label.text = "%d RECORDS / %d UNITS" % [filtered.size(), _total_units(filtered)]
	_empty_label.visible = filtered.is_empty()
	_item_grid.visible = not filtered.is_empty()
	for entry in filtered:
		var button := _create_item_button(entry)
		_item_grid.add_child(button)
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
	_focus_first_available()


func _select_entry(entry: Dictionary) -> void:
	_selected_item_id = str(entry.get("item_id", ""))
	_show_detail(entry)
	for button in _item_buttons:
		_apply_button_style(button, button.name == "Item_%s" % _selected_item_id)


func _show_detail(entry: Dictionary) -> void:
	if entry.is_empty():
		_detail_icon.texture = Assets.texture("icon_unknown")
		_detail_name.text = "NO RECORD SELECTED"
		_detail_class.text = "CLASSIFICATION: --"
		_detail_count.text = "QUANTITY: --"
		_detail_description.text = "Select a recovered object to inspect its ledger record."
		_detail_provenance.text = "PROVENANCE: --"
		return
	var definition: Dictionary = entry["definition"]
	_detail_icon.texture = Assets.item_icon(str(entry["item_id"]))
	_detail_name.text = str(definition.get("display_name", entry["item_id"])).to_upper()
	_detail_class.text = "CLASSIFICATION: %s / %s" % [
		str(definition.get("category", "carried")).to_upper(),
		str(definition.get("rarity", "unclassified")).to_upper(),
	]
	_detail_count.text = "QUANTITY: %d" % int(entry.get("quantity", 0))
	_detail_description.text = str(definition.get("description", "No recovered archive description is available."))
	_detail_provenance.text = "PROVENANCE: %s" % str(definition.get("provenance", "LOCAL LEDGER / UNVERIFIED"))


func _update_category_button_states() -> void:
	for category in _category_buttons:
		_apply_button_style(_category_buttons[category] as Button, category == _selected_category)


func _focus_first_available() -> void:
	if not _item_buttons.is_empty():
		_item_buttons[0].grab_focus()
	elif _category_buttons.has(_selected_category):
		(_category_buttons[_selected_category] as Button).grab_focus()


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
