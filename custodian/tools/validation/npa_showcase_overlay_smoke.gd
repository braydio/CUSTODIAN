extends SceneTree

const LEVEL_SCENE := preload("res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena.tscn")
const CONTROLLER_SCRIPT := preload("res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_scenario_controller.gd")
var _errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	var navigation := Node.new()
	navigation.name = "ValidationNavigation"
	navigation.add_to_group("navigation")
	root.add_child(navigation)
	root.add_child(level)
	await process_frame
	var controller := level.get_node_or_null("EventRuntime/ScenarioController")
	var overlay := level.get_node_or_null("EventRuntime/ShowcaseOverlay")
	_check(controller != null and bool(controller.call("is_enabled")), "registered arena controller should be enabled")
	_check(overlay != null and overlay is CanvasLayer, "registered arena should own its scene-local overlay")
	if overlay != null:
		var panel := overlay.find_child("NpaShowcasePanel", true, false) as Control
		_check(panel != null, "overlay should build its bounded status panel")
		if panel != null:
			var viewport_size := get_root().get_viewport().get_visible_rect().size
			_check(panel.position.x >= 0.0 and panel.position.y >= 0.0 and panel.position.x + panel.size.x <= viewport_size.x and panel.position.y + panel.size.y <= viewport_size.y, "overlay panel should fit the authored 1280x720 viewport")
	if controller != null:
		_check(controller.call("get_actor_state", &"broken_warrant").get("status") == "N/A (not landed)", "unlanded Warrant must remain explicit N/A state")
		_check(controller.call("get_actor_state", &"escort_frame_m7").get("status") == "N/A (not landed)", "unlanded M-7 must remain explicit N/A state")
		_check(bool(controller.call("spawn_actor", &"marine")), "dev controller should spawn Marine through its scene")
		await process_frame
		var state: Dictionary = controller.call("get_actor_state", &"marine")
		_check(state.get("status") == "LIVE", "spawned Marine should produce a live card")
		_check(state.get("class") == "CharacterBody2D", "Marine card should report runtime class")
		_check(state.get("allegiance") == "hostile", "Marine allegiance should come from relationship authority")
		_check(state.get("corpse") == "ALIVE", "Marine lifecycle should report live state")
		_check(controller.call("get_event_log").size() <= 24, "event log must remain bounded")
		controller.call("reset_scenario")
		await process_frame
		_check(controller.call("get_actor_state", &"marine").get("status") == "N/A", "reset should clear actor to N/A")
	var foreign_root := Node2D.new()
	var foreign_controller := CONTROLLER_SCRIPT.new()
	foreign_root.add_child(foreign_controller)
	root.add_child(foreign_root)
	await process_frame
	_check(not bool(foreign_controller.call("is_enabled")), "scenario writes must stay disabled outside the registered level")
	foreign_controller.queue_free()
	foreign_root.queue_free()
	level.queue_free()
	await process_frame
	if _errors.is_empty():
		print("npa_showcase_overlay_smoke passed")
		quit()
	else:
		for error in _errors:
			push_error(error)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
