extends SceneTree

const CARROW_MAP := preload("res://game/world/gothic_compound/gothic_compound_map.gd")
const BACKDROP := preload("res://game/world/procgen/presentation/procgen_depth_backdrop.gd")
const PROFILE := preload("res://game/world/procgen/presentation/underlays/endless_forest_underlay.tres")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_map := Node2D.new()
	main_map.name = "ProcGenMap"
	root.add_child(main_map)
	var backdrop := BACKDROP.new() as ProcgenDepthBackdrop
	backdrop.name = "DepthBackdrop"
	main_map.add_child(backdrop)
	backdrop.set_underlay_profile(PROFILE, 29)
	backdrop.configure_from_cells([Vector2i(0, 0), Vector2i(12, 8)])
	await process_frame
	_require(backdrop.visible, "procgen backdrop did not configure visible")

	var map := CARROW_MAP.new() as GothicCompoundMap
	root.add_child(map)
	await process_frame
	map.configure_connection(main_map, Vector2(96, 128))
	var actor := Node2D.new()
	root.add_child(actor)
	map.enter_from_main(actor)
	_require(not backdrop.visible and backdrop.is_connected_map_isolated(), "Carrow entry did not isolate procgen backdrop")
	map.enter_machine_house(actor)
	_require(not backdrop.visible and backdrop.is_connected_map_isolated(), "Machine House entry re-exposed procgen backdrop")
	map.leave_machine_house(actor)
	_require(not backdrop.visible and backdrop.is_connected_map_isolated(), "Machine House exit re-exposed procgen backdrop while in Carrow")
	map.return_to_main(actor)
	_require(backdrop.visible and not backdrop.is_connected_map_isolated(), "Carrow return did not restore procgen backdrop")

	if _failed:
		quit(1)
		return
	print("carrow_backdrop_isolation_smoke: PASS transitions=4")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("carrow_backdrop_isolation_smoke: " + message)
