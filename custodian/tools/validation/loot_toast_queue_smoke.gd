extends SceneTree

const QUEUE_SCENE := preload("res://game/ui/loot/loot_toast_queue.tscn")
const GAME_SCENE := preload("res://scenes/game.tscn")
const HUD_SCRIPT := preload("res://game/ui/hud/ui.gd")
const RESOURCE_NODE_SCRIPT := preload("res://game/resources/resource_node.gd")

class TestHudProvider:
	extends Node
	signal loot_toast_hud_clearance_changed
	var clearance_rect := Rect2()

	func get_loot_toast_hud_clearance_rect() -> Rect2:
		return clearance_rect

	func set_clearance(rect: Rect2) -> void:
		clearance_rect = rect
		loot_toast_hud_clearance_changed.emit()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var provider := TestHudProvider.new()
	root.add_child(provider)
	var essential := Control.new()
	essential.position = Vector2(20.0, 20.0)
	essential.size = Vector2(280.0, 48.0)
	root.add_child(essential)
	var health := Control.new()
	health.position = Vector2(20.0, 44.0)
	health.size = Vector2(240.0, 24.0)
	root.add_child(health)
	var optional_row := Control.new()
	optional_row.position = Vector2(20.0, 300.0)
	optional_row.size = Vector2(320.0, 40.0)
	optional_row.visible = false
	root.add_child(optional_row)
	await process_frame

	var hud_rect: Rect2 = HUD_SCRIPT.calculate_loot_toast_hud_clearance_rect([essential, health, optional_row])
	_assert(is_equal_approx(hud_rect.end.y, 68.0), "essentials-only HUD clearance did not use visible control rectangles")
	provider.set_clearance(hud_rect)
	var queue := QUEUE_SCENE.instantiate()
	provider.add_child(queue)
	await process_frame
	_assert(queue.is_in_group("loot_toast_queue"), "loot queue group registration missing")
	var essentials_top := float(queue.position.y)
	_assert(essentials_top >= hud_rect.end.y + 11.0, "first toast begins inside the essentials-only HUD clearance")
	_assert(is_equal_approx(essentials_top, 126.0), "fallback top changed when the visible HUD ended above it")

	optional_row.visible = true
	hud_rect = HUD_SCRIPT.calculate_loot_toast_hud_clearance_rect([essential, health, optional_row])
	provider.set_clearance(hud_rect)
	await process_frame
	var optional_top := float(queue.position.y)
	_assert(optional_top > essentials_top, "visible lower optional HUD row did not push the toast stack down")
	_assert(optional_top >= hud_rect.end.y + 11.0, "toast stack overlaps the visible optional HUD row")
	optional_row.visible = false
	hud_rect = HUD_SCRIPT.calculate_loot_toast_hud_clearance_rect([essential, health, optional_row])
	provider.set_clearance(hud_rect)
	await process_frame
	_assert(is_equal_approx(float(queue.position.y), essentials_top), "hidden optional row left stale toast clearance")

	queue.call("push_pickup", &"parts", "Recovered Parts", 3, Color.GOLD)
	queue.call("push_pickup", &"parts", "Recovered Parts", 7, Color.GOLD)
	_assert((queue.get("_entries") as Array).size() == 1, "same-item pickup did not merge")
	_assert(int((queue.get("_entries") as Array)[0].get("quantity", 0)) == 10, "merged pickup quantity drifted")
	queue.call("push_pickup", &"ammo", "Ammo Recovered", 4, Color.GREEN)
	_assert((queue.get("_entries") as Array).size() == 2, "different pickup categories merged")
	var resource_node := RESOURCE_NODE_SCRIPT.new()
	resource_node.resource_id = "blackwood"
	resource_node.work_required = 1
	resource_node.yield_amount = 6
	root.add_child(resource_node)
	resource_node.apply_harvest()
	var harvest_entry: Dictionary = (queue.get("_entries") as Array)[-1]
	_assert(harvest_entry.get("item_id", &"") == &"blackwood", "harvest resource id was not retained")
	_assert(int(harvest_entry.get("quantity", 0)) == 6, "harvest yield quantity was not retained")
	_assert(harvest_entry.get("detail", "") == "Resource harvested", "harvest detail was not retained")
	_assert(harvest_entry.get("icon") is Texture2D, "harvest resource icon was not loaded")
	queue.call("push_pickup", &"field_patch", "Field Patch", 1, Color.GREEN)
	await process_frame
	_assert((queue.get("_entries") as Array).size() == 4, "four-entry presentation fixture was not built")
	_assert_screen_geometry(queue, hud_rect, Vector2i(1280, 720))
	root.size = Vector2i(1600, 900)
	await process_frame
	queue.call("_on_viewport_size_changed")
	await process_frame
	_assert_screen_geometry(queue, hud_rect, Vector2i(1600, 900))
	root.size = Vector2i(1280, 720)
	await process_frame
	queue.call("_on_viewport_size_changed")
	await process_frame
	_assert_screen_geometry(queue, hud_rect, Vector2i(1280, 720))

	var production_game := GAME_SCENE.instantiate()
	var production_ui := production_game.get_node_or_null("UI")
	var production_queue := production_game.get_node_or_null("UI/LootToastQueue")
	_assert(production_ui != null and production_ui.has_method("get_loot_toast_hud_clearance_rect"), "production UI lacks the HUD-clearance provider")
	_assert(production_ui.has_signal("loot_toast_hud_clearance_changed"), "production UI lacks the clearance-change signal")
	_assert(production_queue != null and production_queue.get_parent() == production_ui, "production LootToastQueue is not bound to its live UI provider")
	production_game.free()
	resource_node.queue_free()
	provider.queue_free()
	await process_frame
	print("[LootToastQueueSmoke] PASS")
	quit(0)


func _assert_screen_geometry(queue: Control, hud_rect: Rect2, expected_viewport: Vector2i) -> void:
	var viewport_size := get_root().size
	_assert(viewport_size == expected_viewport, "headless viewport resize did not reach expected size %s (got %s)" % [str(expected_viewport), str(viewport_size)])
	_assert(is_equal_approx(queue.position.x, 18.0), "toast horizontal inset drifted")
	_assert(queue.position.x >= 0.0 and queue.position.x + queue.size.x <= viewport_size.x, "toast queue bounds exceed viewport horizontally")
	_assert(queue.position.y >= 0.0 and queue.position.y + queue.size.y <= viewport_size.y, "toast queue bounds exceed viewport vertically")
	var visible_entries := []
	for child in (queue.get_node("Entries") as VBoxContainer).get_children():
		if not child.is_queued_for_deletion():
			visible_entries.append(child as Control)
	_assert(visible_entries.size() >= 4, "four visible toast entries were not preserved")
	for index in 4:
		var rect: Rect2 = visible_entries[index].get_global_rect()
		_assert(rect.position.x >= 0.0 and rect.end.x <= viewport_size.x, "toast entry %d exceeds viewport horizontally" % index)
		_assert(rect.position.y >= 0.0 and rect.end.y <= viewport_size.y, "toast entry %d exceeds viewport vertically" % index)
		_assert(rect.position.y >= hud_rect.end.y + 11.0, "toast entry %d overlaps visible HUD controls" % index)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[LootToastQueueSmoke] %s" % message)
	quit(1)
