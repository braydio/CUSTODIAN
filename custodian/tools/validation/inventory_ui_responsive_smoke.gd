extends SceneTree

const INVENTORY_SCENE := preload("res://game/ui/inventory/inventory_ui.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inventory_manager := root.get_node_or_null("InventoryManager")
	if inventory_manager != null:
		inventory_manager.call("clear")
		inventory_manager.call("add_item", &"faint_recollection", 2)
		inventory_manager.call("add_item", &"sundered_gate_key", 1)
		inventory_manager.call("add_item", &"p9_sidearm", 1)
		for index in range(5):
			inventory_manager.call(
				"add_item",
				StringName("ledger_layout_record_%02d" % index),
				1
			)
	await _assert_resolution(Vector2i(2048, 1152), 4)
	await _assert_resolution(Vector2i(1920, 1080), 4)
	await _assert_resolution(Vector2i(1600, 900), 4)
	await _assert_resolution(Vector2i(1500, 900), 4)
	await _assert_resolution(Vector2i(1499, 900), 3)
	await _assert_resolution(Vector2i(1280, 720), 3)
	await _assert_resolution(Vector2i(1152, 648), 3)
	await _assert_resolution(Vector2i(1151, 648), 2)
	await _assert_resolution(Vector2i(1024, 648), 2)

	var ui := INVENTORY_SCENE.instantiate()
	root.add_child(ui)
	await process_frame
	ui.call("open")
	ui.call("_select_page", "ledger", false)
	ui.set("_controller_prompts_active", false)
	ui.call("_update_input_prompts")
	var footer := _find_node_named(ui, "InputFooter")
	var footer_label := _find_first_label(footer)
	_assert(footer_label != null and footer_label.text.contains("Q  PREVIOUS PAGE"), "keyboard page prompt missing")
	_assert(footer_label != null and footer_label.text.contains("F  FILTER"), "keyboard ledger controls missing")
	ui.set("_controller_prompts_active", true)
	ui.call("_update_input_prompts")
	_assert(footer_label != null and footer_label.text.contains("LB  PREVIOUS PAGE"), "controller page prompt missing")
	_assert(footer_label != null and footer_label.text.contains("A  SELECT"), "controller selection prompt missing")
	var close_button := _find_node_named(ui, "CloseButton") as Button
	_assert(close_button != null and close_button.text == "B  CLOSE", "controller close prompt missing")
	var filter_event := InputEventJoypadButton.new()
	filter_event.button_index = JOY_BUTTON_X
	filter_event.pressed = true
	ui.call("_unhandled_input", filter_event)
	_assert(str(ui.get("_selected_category")) == "key", "controller filter input did not change category")
	var sort_event := InputEventJoypadButton.new()
	sort_event.button_index = JOY_BUTTON_RIGHT_STICK
	sort_event.pressed = true
	ui.call("_unhandled_input", sort_event)
	_assert(bool(ui.get("_sort_name_first")), "controller sort input did not toggle sort order")
	var previous_page_event := InputEventJoypadButton.new()
	previous_page_event.button_index = JOY_BUTTON_LEFT_SHOULDER
	previous_page_event.pressed = true
	ui.call("_unhandled_input", previous_page_event)
	_assert(str(ui.get("_current_page")) == "equipment", "controller previous-page input did not cycle pages")
	ui.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		for resolution in [
			Vector2i(1280, 720),
			Vector2i(1600, 900),
			Vector2i(1920, 1080),
		]:
			for page_name in ["status", "ledger", "equipment"]:
				await _capture_page_at_resolution(page_name, resolution)

	if _failed:
		push_error("inventory_ui_responsive_smoke failed")
		quit(1)
		return
	print("[InventoryUIResponsiveSmoke] desktop/medium/compact breakpoints and prompts passed.")
	quit(0)


func _assert_resolution(resolution: Vector2i, expected_columns: int) -> void:
	root.content_scale_size = resolution
	root.size = resolution
	var ui := INVENTORY_SCENE.instantiate()
	root.add_child(ui)
	await process_frame
	ui.call("open")
	ui.call("_select_page", "ledger", false)
	await process_frame
	await process_frame
	ui.call("_update_ledger_grid_columns")
	var item_grid := _find_node_named(ui, "ItemGrid") as GridContainer
	_assert(
		item_grid != null and item_grid.columns == expected_columns,
		"%s expected %d columns, got %s (viewport=%s, register=%s)" % [
			resolution,
			expected_columns,
			item_grid.columns if item_grid != null else "<missing>",
			ui.get_viewport_rect().size,
			item_grid.get_parent_control().size if item_grid != null else Vector2.ZERO,
		]
	)
	var expected_card_size := Vector2(148, 152)
	var expected_icon_size := Vector2(88, 88)
	if resolution.x < 1152:
		expected_card_size = Vector2(164, 164)
		expected_icon_size = Vector2(96, 96)
	elif resolution.x < 1500:
		expected_card_size = Vector2(156, 158)
		expected_icon_size = Vector2(92, 92)
	var detail_icon := _find_node_named(
		ui,
		"InspectionIcon"
	) as TextureRect
	_assert(
		detail_icon != null
		and detail_icon.custom_minimum_size == Vector2(112, 112),
		"%s inspection art should use its compact 112px viewport" % resolution
	)
	var category_panel := ui.get("_ledger_category_panel") as PanelContainer
	var detail_panel := ui.get("_ledger_detail_panel") as PanelContainer
	_assert(
		category_panel != null
		and category_panel.custom_minimum_size.x == 150.0,
		"%s Ledger category rail should be 150px" % resolution
	)
	_assert(
		detail_panel != null
		and detail_panel.custom_minimum_size.x == 340.0,
		"%s Inspection panel should be 340px" % resolution
	)
	var records_panel := _find_node_named(ui, "LedgerRecordsPanel") as PanelContainer
	var records_style := records_panel.get_theme_stylebox("panel") as StyleBoxFlat if records_panel != null else null
	_assert(
		records_style != null and records_style.bg_color.a >= 0.9,
		"%s center register lacks an opaque backing" % resolution
	)
	for child in item_grid.get_children():
		var card := child as Button
		var icon := _find_node_named(card, "ItemIcon") as TextureRect
		_assert(
			card != null
			and card.custom_minimum_size == expected_card_size,
			"%s card did not use responsive size %s" % [
				resolution,
				expected_card_size,
			]
		)
		_assert(
			icon != null
			and icon.custom_minimum_size == expected_icon_size,
			"%s icon did not use responsive size %s for %s" % [
				resolution,
				expected_icon_size,
				card.name,
			]
		)
		_assert(
			icon != null and _rect_contains(card.get_global_rect(), icon.get_global_rect()),
			"%s item icon intersects card boundaries for %s" % [resolution, card.name]
		)
	if resolution == Vector2i(1600, 900):
		var item_scroll := _find_node_named(ui, "ItemScroll") as ScrollContainer
		var vertical_scrollbar := (
			item_scroll.get_v_scroll_bar()
			if item_scroll != null
			else null
		)
		_assert(
			item_grid.get_child_count() == 8,
			"1600x900 Ledger fixture should contain eight records"
		)
		_assert(
			vertical_scrollbar != null
			and not vertical_scrollbar.visible,
			"1600x900 should show eight Ledger records without register scrolling"
		)

	ui.call("_select_page", "status", false)
	await process_frame
	await process_frame
	var page_root := _find_node_named(ui, "PageRoot") as Control
	var status_left := _find_node_named(ui, "StatusPage").get_child(0) as PanelContainer
	var minimap := _find_node_named(ui, "BlackReliquaryMinimapFrame") as Control
	if minimap == null:
		minimap = _find_largest_control_named_like(ui, "Minimap")
	var return_row := _find_label_with_text(ui, "RETURN MOORING")
	var footer_panel := _find_node_named(ui, "InputFooter") as Control
	if resolution.y >= 720:
		_assert(
			return_row != null and page_root != null
			and return_row.get_global_rect().end.y <= page_root.get_global_rect().end.y + 0.5,
			"%s lower status rows extend beneath the page/footer (row=%s page=%s)" % [
				resolution,
				return_row.get_global_rect() if return_row != null else Rect2(),
				page_root.get_global_rect() if page_root != null else Rect2(),
			]
		)
		_assert(
			minimap != null and page_root != null
			and minimap.get_global_rect().end.y <= page_root.get_global_rect().end.y + 0.5,
			"%s status minimap extends beneath the page/footer (map=%s page=%s)" % [
				resolution,
				minimap.get_global_rect() if minimap != null else Rect2(),
				page_root.get_global_rect() if page_root != null else Rect2(),
			]
		)
		_assert(
			footer_panel != null and page_root != null
			and page_root.get_global_rect().end.y <= footer_panel.get_global_rect().position.y + 0.5,
			"%s status content overlaps the footer" % resolution
		)
	if resolution.x <= 1280:
		_assert(
			status_left.custom_minimum_size.x <= 280.0
			and minimap.custom_minimum_size.y <= 250.0,
			"%s compact status sizing was not applied" % resolution
		)
	else:
		_assert(
			minimap.custom_minimum_size.y >= 300.0,
			"%s standard status map minimum height was not retained" % resolution
		)

	ui.call("_select_page", "ledger", false)
	await process_frame
	ui.queue_free()
	await process_frame


func _find_node_named(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_named(child, target_name)
		if found != null:
			return found
	return null


func _find_largest_texture_rect(node: Node) -> TextureRect:
	var best: TextureRect = node as TextureRect if node is TextureRect else null
	for child in node.get_children():
		var candidate := _find_largest_texture_rect(child)
		if candidate != null and (
			best == null
			or candidate.custom_minimum_size.x > best.custom_minimum_size.x
		):
			best = candidate
	return best


func _find_first_label(node: Node) -> Label:
	if node == null:
		return null
	if node is Label:
		return node as Label
	for child in node.get_children():
		var label := _find_first_label(child)
		if label != null:
			return label
	return null


func _find_label_with_text(node: Node, needle: String) -> Label:
	if node is Label and (node as Label).text.contains(needle):
		return node as Label
	for child in node.get_children():
		var label := _find_label_with_text(child, needle)
		if label != null:
			return label
	return null


func _find_largest_control_named_like(node: Node, needle: String) -> Control:
	var best: Control = null
	if node is Control and String(node.name).contains(needle):
		best = node as Control
	for child in node.get_children():
		var candidate := _find_largest_control_named_like(child, needle)
		if candidate != null and (
			best == null
			or candidate.size.x * candidate.size.y > best.size.x * best.size.y
		):
			best = candidate
	return best


func _rect_contains(outer: Rect2, inner: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x - 0.5
		and inner.position.y >= outer.position.y - 0.5
		and inner.end.x <= outer.end.x + 0.5
		and inner.end.y <= outer.end.y + 0.5
	)


func _capture_page_at_resolution(page_name: String, resolution: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = resolution
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world_preview := ColorRect.new()
	world_preview.name = "BrightWorldPreview"
	world_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_preview.color = Color(0.55, 0.32, 0.06, 1.0)
	viewport.add_child(world_preview)
	var bright_structure := ColorRect.new()
	bright_structure.position = Vector2(
		float(resolution.x) * 0.18,
		float(resolution.y) * 0.12
	)
	bright_structure.size = Vector2(
		float(resolution.x) * 0.64,
		float(resolution.y) * 0.72
	)
	bright_structure.color = Color(1.0, 0.78, 0.22, 1.0)
	world_preview.add_child(bright_structure)
	var ui := INVENTORY_SCENE.instantiate()
	viewport.add_child(ui)
	await process_frame
	ui.call("open")
	ui.call("_select_page", page_name, false)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		viewport.queue_free()
		return
	var capture_path := "user://inventory_ui_%s_%dx%d.png" % [
		page_name,
		resolution.x,
		resolution.y,
	]
	_assert(
		image.save_png(capture_path) == OK,
		"%s %s visual-check capture could not be written" % [resolution, page_name]
	)
	viewport.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[InventoryUIResponsiveSmoke] %s" % message)
