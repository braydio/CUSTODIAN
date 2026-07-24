extends SceneTree

const INVENTORY_SCENE := "res://game/ui/inventory/inventory_ui.tscn"
const ASSET_MANIFEST := "res://content/ui/inventory/runtime/inventory_ui_asset_manifest.json"
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")

class MockOperator:
	extends Node
	var sidearm_equipped := false

	func grant_sidearm(_definition: Resource = null) -> Dictionary:
		sidearm_equipped = true
		return {"granted": true}

	func remove_sidearm() -> Dictionary:
		sidearm_equipped = false
		return {"released": true}


func _initialize() -> void:
	var inventory_manager := root.get_node_or_null("InventoryManager")
	_assert(inventory_manager != null, "InventoryManager autoload missing")
	if inventory_manager != null:
		inventory_manager.call("clear")
		inventory_manager.call("add_item", &"faint_recollection", 2)
		inventory_manager.call("add_item", &"sundered_gate_key", 1)
		inventory_manager.call("add_item", &"p9_sidearm", 1)
	var mock_operator := MockOperator.new()
	mock_operator.add_to_group("player")
	root.add_child(mock_operator)
	var resource_ledger := root.get_node_or_null("ResourceLedger")
	_assert(resource_ledger != null, "ResourceLedger autoload missing")

	_validate_asset_manifest()

	var packed := load(INVENTORY_SCENE)
	_assert(packed is PackedScene, "inventory scene did not load")
	var inventory_ui := (packed as PackedScene).instantiate()
	root.add_child(inventory_ui)
	await process_frame
	_assert(inventory_ui.has_method("open"), "inventory UI missing open method")
	inventory_ui.call("open")
	await process_frame
	_assert(inventory_ui.visible, "inventory UI did not become visible")
	var status_page := _find_node_named(inventory_ui, "StatusPage") as Control
	var history_page := _find_node_named(inventory_ui, "HistoryPage") as Control
	var ledger_page := _find_node_named(inventory_ui, "LedgerPage") as Control
	var equipment_page := _find_node_named(inventory_ui, "EquipmentPage") as Control
	var page_root := _find_node_named(inventory_ui, "PageRoot") as Control
	var production_frame := _find_node_named(inventory_ui, "ProductionFrame") as NinePatchRect
	_assert(page_root != null and page_root.clip_contents, "PageRoot should clip overflowing page content")
	_assert(
		production_frame != null
		and not production_frame.draw_center
		and not production_frame.visible,
		"overscaled production frame should not compete with Ledger content"
	)
	var backdrop := _find_node_named(inventory_ui, "Backdrop") as ColorRect
	var backdrop_material := backdrop.material as ShaderMaterial if backdrop != null else null
	_assert(
		backdrop_material != null
		and backdrop_material.shader != null
		and backdrop_material.shader.resource_path.ends_with("reliquary_inventory_backdrop.gdshader"),
		"inventory backdrop should use Black Reliquary Archive Glass"
	)
	_assert(
		backdrop_material != null
		and backdrop_material.get_shader_parameter("exposure") <= 0.5
		and backdrop_material.get_shader_parameter("highlight_compression") >= 0.9,
		"archive glass should suppress and compress world highlights"
	)
	_assert_archive_glass_highlight_contract(backdrop_material)
	var footer := _find_node_named(inventory_ui, "InputFooter") as PanelContainer
	var footer_style := footer.get_theme_stylebox("panel") as StyleBoxFlat if footer != null else null
	_assert(
		footer != null and footer.custom_minimum_size.y >= 36.0
		and footer_style != null and footer_style.bg_color.a >= 0.95,
		"input prompts should sit on a dedicated near-opaque footer strip"
	)
	_assert(_find_node_named(inventory_ui, "PageHint") == null, "detached page hint should not remain")
	_assert(status_page != null, "status page root missing")
	_assert(_find_node_named(inventory_ui, "StatusButton") != null, "status tab button missing")
	_assert(_find_node_named(inventory_ui, "HistoryButton") != null, "history tab button missing")
	_assert(_find_node_named(inventory_ui, "LedgerButton") != null, "ledger tab button missing")
	_assert(_find_node_named(inventory_ui, "EquipmentButton") != null, "equipment tab button missing")
	_assert(status_page.visible, "inventory did not open to the status page")
	_assert(_find_label_with_text(inventory_ui, "FIELD LEDGER") != null, "simplified Field Ledger title missing")
	_assert(_find_label_with_text(inventory_ui, "CUSTODIAN FIELD LEDGER / RELIQUARY INVENTORY") == null, "redundant legacy inventory title remains")
	_assert(_find_node_named(inventory_ui, "HistoryLog") != null, "history log control missing")
	inventory_ui.call("set_location", "SUNDERED KEEP FRONT GATE")
	inventory_ui.call("set_phase", "APPROACH")
	inventory_ui.call("set_objective", "REACH THE MAIN GATE")
	inventory_ui.call("set_key_item_status", true, "Sundered Gate Key")
	inventory_ui.call("set_main_gate_status", false, true)
	inventory_ui.call("set_return_mooring_status", true, true)
	inventory_ui.call("set_health", 72, 100)
	inventory_ui.call("set_stamina_status", "READY", 64.0)
	inventory_ui.call("record_history_entry", "QUEST UPDATE", "Entered the front gate approach and confirmed the field ledger.", Color(0.82, 0.76, 0.62))
	await process_frame
	_assert(_find_label_with_text(inventory_ui, "SUNDERED KEEP FRONT GATE") != null, "status page did not render location text")
	_assert(_find_label_with_text(inventory_ui, "STAMINA READY 64%") != null, "status page did not render stamina text")
	var history_log := _find_node_named(inventory_ui, "HistoryLog") as RichTextLabel
	_assert(history_log != null and history_log.text.contains("QUEST UPDATE"), "history log did not record the quest update")
	inventory_ui.call("_select_page", "ledger")
	await process_frame
	_assert(ledger_page != null and ledger_page.visible, "ledger page did not become visible")
	var records_panel := _find_node_named(inventory_ui, "LedgerRecordsPanel") as PanelContainer
	var records_style := records_panel.get_theme_stylebox("panel") as StyleBoxFlat if records_panel != null else null
	_assert(
		records_panel != null and records_style != null
		and records_style.bg_color.a >= 0.9
		and records_style.border_color.a >= 0.37,
		"center Ledger register should have its own opaque bordered backing"
	)
	_assert(_find_node_named(inventory_ui, "Item_faint_recollection") != null, "live inventory item was not rendered")
	_assert(_find_node_named(inventory_ui, "Item_sundered_gate_key") != null, "Sundered Gate Key was not rendered")
	_assert(_find_node_named(inventory_ui, "Item_p9_sidearm") != null, "P-9 equipment item was not rendered")
	var item_grid := _find_node_named(inventory_ui, "ItemGrid")
	_assert(item_grid != null and not item_grid.get_children().is_empty(), "ledger item grid missing")
	_assert(item_grid is GridContainer and (item_grid as GridContainer).columns >= 1 and (item_grid as GridContainer).columns <= 4, "ledger item grid columns should be responsive and clamped")
	_assert(item_grid != null and item_grid.get_child(0).name == "Item_sundered_gate_key", "ledger should sort by class and display name")
	var selected_mark := (item_grid.get_child(0) as Button).get_node_or_null("SelectionMark") as ColorRect
	_assert(selected_mark != null and selected_mark.visible, "selected card should expose its persistent gold registration mark")
	var filter_button := _find_node_named(inventory_ui, "FilterButton") as Button
	var sort_button := _find_node_named(inventory_ui, "SortButton") as Button
	_assert(filter_button != null and filter_button.text.contains("FILTER · ALL"), "filter should be a truthful focusable control")
	_assert(sort_button != null and sort_button.text.contains("CLASS / NAME"), "sort should be a truthful focusable control")
	var all_category := _find_node_named(inventory_ui, "CategoryAllButton") as Button
	var cognitive_category := _find_node_named(inventory_ui, "CategoryCognitiveButton") as Button
	_assert(all_category != null and all_category.text.contains("4"), "All category should expose its current unit count")
	_assert(cognitive_category != null and cognitive_category.text.contains("2"), "Cognitive category should expose its current unit count")
	sort_button.emit_signal("pressed")
	await process_frame
	_assert(item_grid.get_child(0).name == "Item_faint_recollection", "name-first sort control did not reorder the register")
	sort_button.emit_signal("pressed")
	await process_frame
	_assert(item_grid.get_child(0).name == "Item_sundered_gate_key", "class-first sort control did not restore deterministic order")
	filter_button.emit_signal("pressed")
	await process_frame
	_assert(filter_button.text.contains("FILTER · KEY OBJECTS"), "filter control did not advance to Key Objects")
	_assert(item_grid.get_child_count() == 1 and item_grid.get_child(0).name == "Item_sundered_gate_key", "filter control did not constrain the register")
	inventory_ui.call("_select_category", "all")
	await process_frame
	var detail_equip_button := _find_node_named(inventory_ui, "EquipButton")
	var description_scroll := _find_node_named(inventory_ui, "DescriptionScroll") as ScrollContainer
	_assert(detail_equip_button != null and not _has_scroll_ancestor(detail_equip_button), "inspection action should be pinned outside scrolling content")
	_assert(description_scroll != null, "inspection description should own the only detail scrollbar")
	var key_quantity := (_find_node_named(inventory_ui, "Item_sundered_gate_key") as Button).get_node_or_null("ItemQuantity") as Label
	_assert(key_quantity != null and not key_quantity.visible, "key-object cards should not display stack quantity")
	var p9_card := _find_node_named(inventory_ui, "Item_p9_sidearm") as Button
	var p9_name := _find_node_named(p9_card, "ItemName") as Label
	_assert(p9_name != null and p9_name.text == "P-9 FIELD SIDEARM", "item card should keep its name in a dedicated text region")
	var expected_card_size := inventory_ui.call(
		"_ledger_card_size"
	) as Vector2
	var expected_icon_size := inventory_ui.call(
		"_ledger_icon_size"
	) as Vector2
	_assert(
		p9_card.custom_minimum_size == expected_card_size,
		"item card should use the active compact responsive footprint"
	)
	var p9_icon := _find_node_named(p9_card, "ItemIcon") as TextureRect
	var p9_icon_viewport := _find_node_named(p9_card, "IconViewport") as CenterContainer
	_assert(
		p9_icon != null
		and p9_icon.custom_minimum_size == expected_icon_size
		and p9_icon_viewport != null
		and p9_icon_viewport.custom_minimum_size == expected_icon_size,
		"item cards should use the active compact responsive icon viewport"
	)
	_assert(
		p9_icon != null and _rect_contains(p9_card.get_global_rect(), p9_icon.get_global_rect()),
		"item icon intersects its card boundary"
	)
	_assert(
		p9_icon != null and p9_icon.texture != null and p9_icon.texture.resource_path.ends_with("p9_custodian_sidearm__portrait__inventory__default__omni__1f__512.png"),
		"P-9 should resolve its production inventory portrait"
	)
	var first_card := item_grid.get_child(0) as Button
	var second_card := item_grid.get_child(1) as Button
	var first_mark := first_card.get_node_or_null("SelectionMark") as ColorRect
	second_card.grab_focus()
	await process_frame
	var second_focus_corners := second_card.get_node_or_null("FocusCorners") as Control
	var first_style := first_card.get_theme_stylebox("normal") as StyleBoxFlat
	_assert(
		first_mark != null and first_mark.visible and first_style != null
		and first_style.border_color.is_equal_approx(first_mark.color),
		"moving focus should not erase the persistent selected-item state"
	)
	_assert(
		second_focus_corners != null and second_focus_corners.visible,
		"focused item should use cyan corner marks"
	)
	inventory_ui.call("_select_category", "relic")
	await process_frame
	_assert(_find_label_with_text(inventory_ui, "NO RECOVERED RELICS REGISTERED") != null, "empty relic category should use field-ledger empty-state language")
	inventory_ui.call("_select_category", "all")
	await process_frame
	inventory_ui.call("_select_page", "equipment")
	await process_frame
	_assert(equipment_page != null and equipment_page.visible, "equipment page did not become visible")
	var equipment_action := _find_node_named(inventory_ui, "EquipmentActionButton") as Button
	var available_p9 := _find_node_named(inventory_ui, "AvailableEquipment_p9_sidearm") as Button
	_assert(available_p9 != null, "available Equipment column should list the carried P-9")
	_assert(equipment_action != null and equipment_action.text == "EQUIP SIDEARM" and not equipment_action.disabled, "equipment page should offer the carried P-9")
	equipment_action.emit_signal("pressed")
	await process_frame
	_assert(str(inventory_manager.call("get_equipped", &"sidearm")) == "p9_sidearm", "equipment page should fill the sidearm slot")
	_assert(mock_operator.sidearm_equipped, "equipment page should activate the Operator sidearm gate")
	_assert(equipment_action.text == "UNEQUIP", "filled equipment slot should offer unequip")
	_assert(
		_find_node_named(inventory_ui, "AvailableEquipment_p9_sidearm") == null
		and (_find_node_named(inventory_ui, "AvailableEquipmentEmpty") as Label).visible,
		"equipped gear should leave the Available Equipment column"
	)
	equipment_action.emit_signal("pressed")
	await process_frame
	_assert(str(inventory_manager.call("get_equipped", &"sidearm")).is_empty(), "equipment page should clear the sidearm slot")
	_assert(not mock_operator.sidearm_equipped, "unequip should disable the Operator sidearm gate")
	inventory_ui.call("_select_page", "ledger")
	await process_frame
	if resource_ledger != null:
		resource_ledger.call("add", &"blackwood", 1)
		await process_frame
	var blackwood_button := _find_node_named(inventory_ui, "Item_blackwood")
	_assert(blackwood_button != null, "blackwood resource item was not rendered")
	var blackwood_icon := _find_node_named(blackwood_button, "ItemIcon") as TextureRect if blackwood_button != null else null
	_assert(blackwood_icon != null, "blackwood item icon control missing")
	_assert(blackwood_icon != null and blackwood_icon.material is ShaderMaterial, "blackwood item icon ember material missing")
	var blackwood_material := blackwood_icon.material as ShaderMaterial if blackwood_icon != null else null
	_assert(blackwood_material != null and bool(blackwood_material.get_shader_parameter("use_auto_mask")), "blackwood ember material auto mask is not enabled")
	_assert(blackwood_material != null and is_equal_approx(float(blackwood_material.get_shader_parameter("ember_intensity")), 0.25), "blackwood ember material intensity changed unexpectedly")
	_assert(
		blackwood_icon != null and blackwood_icon.texture != null
		and blackwood_icon.texture.resource_path == "res://content/ui/inventory/runtime/icons/icon_blackwood.png",
		"blackwood item did not resolve its normalized canonical runtime icon"
	)
	var recollection_button := _find_node_named(inventory_ui, "Item_faint_recollection")
	var recollection_icon := _find_node_named(recollection_button, "ItemIcon") as TextureRect if recollection_button != null else null
	var recollection_material := recollection_icon.material as ShaderMaterial if recollection_icon != null else null
	_assert(
		recollection_icon != null
		and (recollection_material == null or recollection_material.shader.resource_path != "res://game/ui/inventory/shaders/inventory_ember_spark.gdshader"),
		"ember material leaked onto another inventory item: %s" % (
			recollection_material.shader.resource_path if recollection_material != null else "<none>"
		)
	)
	var detail_name := _find_label_with_text(inventory_ui, "FAINT RECOLLECTION")
	_assert(detail_name != null, "ledger default selection did not render a known item")
	inventory_ui.call("_select_page", "history")
	await process_frame
	_assert(history_page != null and history_page.visible, "history page did not become visible")
	_assert(history_log != null and history_log.visible, "history log did not become visible")
	inventory_manager.call("add_item", &"ancient_bearing", 3)
	await process_frame
	_assert(_find_node_named(inventory_ui, "Item_ancient_bearing") != null, "inventory did not update after live ledger change")
	inventory_ui.call("close")
	await process_frame
	_assert(not inventory_ui.visible, "inventory UI did not close")
	inventory_ui.call("open")
	await process_frame
	_assert(history_page.visible, "inventory should preserve the last-open page during the play session")
	inventory_ui.call("close")
	print("[InventoryUISmoke] PASS")
	quit(0)


func _validate_asset_manifest() -> void:
	var file := FileAccess.open(ASSET_MANIFEST, FileAccess.READ)
	_assert(file != null, "inventory asset manifest missing")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(parsed is Dictionary, "inventory asset manifest is not JSON")
	var assets: Dictionary = (parsed as Dictionary).get("assets", {})
	for asset_id in ["frame", "panel_deep", "slot_empty", "slot_hover", "slot_selected", "icon_unknown"]:
		_assert(assets.has(asset_id), "inventory manifest missing asset contract: %s" % asset_id)
		var entry: Dictionary = assets[asset_id]
		var fallback_path := str(entry.get("fallback_path", ""))
		_assert(ResourceLoader.exists(fallback_path), "inventory fallback asset does not resolve: %s" % fallback_path)


func _assert_archive_glass_highlight_contract(material: ShaderMaterial) -> void:
	if material == null:
		return
	var source := Vector3.ONE
	var luminance := _luminance(source)
	var saturation: float = material.get_shader_parameter("saturation")
	var compression: float = material.get_shader_parameter("highlight_compression")
	var exposure: float = material.get_shader_parameter("exposure")
	var tint_strength: float = material.get_shader_parameter("tint_strength")
	var tint: Color = material.get_shader_parameter("reliquary_tint")
	var graded := Vector3(luminance, luminance, luminance).lerp(
		source,
		saturation
	)
	graded /= Vector3.ONE + graded * compression
	graded *= exposure
	graded = graded.lerp(Vector3(tint.r, tint.g, tint.b), tint_strength)
	var active_text := Vector3(
		Palette.GOLD_TEXT.r,
		Palette.GOLD_TEXT.g,
		Palette.GOLD_TEXT.b
	)
	_assert(
		_luminance(graded) < _luminance(active_text),
		"archive-glass white highlight would render brighter than active UI text"
	)


func _luminance(value: Vector3) -> float:
	return value.dot(Vector3(0.2126, 0.7152, 0.0722))


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[InventoryUISmoke] %s" % message)
	quit(1)


func _find_node_named(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_named(child, target_name)
		if found != null:
			return found
	return null


func _find_label_with_text(node: Node, needle: String) -> Label:
	if node is Label and (node as Label).text.contains(needle):
		return node as Label
	for child in node.get_children():
		var found := _find_label_with_text(child, needle)
		if found != null:
			return found
	return null


func _has_scroll_ancestor(node: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current is ScrollContainer:
			return true
		current = current.get_parent()
	return false


func _rect_contains(outer: Rect2, inner: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x - 0.5
		and inner.position.y >= outer.position.y - 0.5
		and inner.end.x <= outer.end.x + 0.5
		and inner.end.y <= outer.end.y + 0.5
	)
