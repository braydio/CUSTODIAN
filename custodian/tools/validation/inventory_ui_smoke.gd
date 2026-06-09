extends SceneTree

const INVENTORY_SCENE := "res://game/ui/inventory/inventory_ui.tscn"
const ASSET_MANIFEST := "res://content/ui/inventory/runtime/inventory_ui_asset_manifest.json"


func _initialize() -> void:
	var inventory_manager := root.get_node_or_null("InventoryManager")
	_assert(inventory_manager != null, "InventoryManager autoload missing")
	if inventory_manager != null:
		inventory_manager.call("clear")
		inventory_manager.call("add_item", &"faint_recollection", 2)
		inventory_manager.call("add_item", &"sundered_gate_key", 1)

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
	_assert(status_page != null, "status page root missing")
	_assert(_find_node_named(inventory_ui, "StatusButton") != null, "status tab button missing")
	_assert(_find_node_named(inventory_ui, "HistoryButton") != null, "history tab button missing")
	_assert(_find_node_named(inventory_ui, "LedgerButton") != null, "ledger tab button missing")
	_assert(status_page.visible, "inventory did not open to the status page")
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
	_assert(_find_node_named(inventory_ui, "Item_faint_recollection") != null, "live inventory item was not rendered")
	_assert(_find_node_named(inventory_ui, "Item_sundered_gate_key") != null, "Sundered Gate Key was not rendered")
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
