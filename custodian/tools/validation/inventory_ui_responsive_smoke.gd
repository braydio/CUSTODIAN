extends SceneTree

const INVENTORY_SCENE := preload("res://game/ui/inventory/inventory_ui.tscn")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_resolution(Vector2i(2048, 1152), 4)
	await _assert_resolution(Vector2i(1920, 1080), 4)
	await _assert_resolution(Vector2i(1280, 720), 3)

	var ui := INVENTORY_SCENE.instantiate()
	root.add_child(ui)
	await process_frame
	ui.call("open")
	ui.call("_select_page", "ledger", false)
	ui.set("_controller_prompts_active", false)
	ui.call("_update_input_prompts")
	var footer := _find_node_named(ui, "InputFooter")
	var footer_label := footer.get_child(0) as Label if footer != null and footer.get_child_count() > 0 else null
	_assert(footer_label != null and footer_label.text.contains("Q  PREVIOUS PAGE"), "keyboard page prompt missing")
	_assert(footer_label != null and footer_label.text.contains("F  FILTER"), "keyboard ledger controls missing")
	ui.set("_controller_prompts_active", true)
	ui.call("_update_input_prompts")
	_assert(footer_label != null and footer_label.text.contains("LB  PREVIOUS PAGE"), "controller page prompt missing")
	_assert(footer_label != null and footer_label.text.contains("A  SELECT"), "controller selection prompt missing")
	var close_button := _find_node_named(ui, "CloseButton") as Button
	_assert(close_button != null and close_button.text == "B  CLOSE", "controller close prompt missing")
	ui.queue_free()
	await process_frame

	if _failed:
		push_error("inventory_ui_responsive_smoke failed")
		quit(1)
		return
	print("[InventoryUIResponsiveSmoke] 2048/1920/1280 columns and keyboard/controller prompts passed.")
	quit(0)


func _assert_resolution(resolution: Vector2i, expected_columns: int) -> void:
	root.size = resolution
	var ui := INVENTORY_SCENE.instantiate()
	root.add_child(ui)
	await process_frame
	ui.call("open")
	ui.call("_select_page", "ledger", false)
	await process_frame
	await process_frame
	var item_grid := _find_node_named(ui, "ItemGrid") as GridContainer
	_assert(
		item_grid != null and item_grid.columns == expected_columns,
		"%s expected %d columns, got %s" % [
			resolution,
			expected_columns,
			item_grid.columns if item_grid != null else "<missing>",
		]
	)
	var detail_icon := _find_largest_texture_rect(ui)
	_assert(
		detail_icon != null and detail_icon.custom_minimum_size.x >= 144.0,
		"%s inspection art should retain its 144px viewport" % resolution
	)
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


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[InventoryUIResponsiveSmoke] %s" % message)
