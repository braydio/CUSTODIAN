extends SceneTree
const INVENTORY := preload("res://game/ui/inventory/inventory_ui.tscn")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var manager := root.get_node("InventoryManager"); manager.call("clear"); manager.call("add_item", &"faint_recollection", 3)
	var cognitive := root.get_node("CognitiveState"); cognitive.set("decay_per_second", 0.0); cognitive.call("from_save_dict", {"recollection": 3.0})
	var ui := INVENTORY.instantiate(); root.add_child(ui); await process_frame; ui.call("open"); ui.call("_select_page", "ledger"); await process_frame
	var entry: Dictionary = ui.get("_entries")[0]; var glance := str(ui.call("_build_glance_summary", entry)); var detail := str(ui.call("_build_detail_summary", entry))
	assert(glance.contains("RAW VALUE") and glance.contains("DOMINANT") and not glance.contains(str(entry.definition.description)))
	assert(detail.contains(str(entry.definition.description))); assert(ui.get("_inspection_mode") == InventoryUI.InspectionMode.GLANCE)
	ui.call("_toggle_inspection_mode"); assert(ui.get("_inspection_mode") == InventoryUI.InspectionMode.DETAIL)
	print("inventory_inspection_mode_smoke: PASS"); quit(0)
