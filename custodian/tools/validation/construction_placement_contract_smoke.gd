extends SceneTree

const POWER_SCRIPT := preload("res://game/systems/core/systems/power.gd")
const PLACEMENT_SCRIPT := preload("res://game/systems/core/systems/turret_placement.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry := root.get_node("InfrastructureRegistry")
	registry.clear_runtime_state()
	var build_inventory := root.get_node("BuildInventory")
	build_inventory.clear()
	build_inventory.add("capacitor_bank_mk1", 1)
	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var power := POWER_SCRIPT.new()
	power.name = "Power"
	power.total_power = 100.0
	power.max_power = 500.0
	game_root.add_child(power)
	power.set_process(false)
	var placement := PLACEMENT_SCRIPT.new()
	placement.name = "TurretPlacement"
	world.add_child(placement)
	var blocker := Node2D.new()
	blocker.global_position = Vector2(200, 200)
	blocker.add_to_group("structure")
	world.add_child(blocker)
	_require(placement.enter_build_token_placement("capacitor_bank_mk1"), "Capacitor Ready Build did not enter placement mode.")
	_require(not placement.attempt_place_build_at(Vector2(200, 200)), "Occupied site should reject construction.")
	_require(build_inventory.get_amount("capacitor_bank_mk1") == 1, "Invalid placement consumed the Ready Build token.")
	_require(placement.attempt_place_build_at(Vector2(800, 800)), "Valid site did not commit the Capacitor foundation.")
	_require(build_inventory.get_amount("capacitor_bank_mk1") == 0, "Valid placement did not consume exactly one token.")
	var structures := placement.get_placed_structures()
	_require(structures.size() == 1, "Valid placement should create one structure instance.")
	var bank: Node = structures[0] if not structures.is_empty() else null
	_require(bank != null and str(bank.get("construction_state")) == "under_construction", "Placed Capacitor should begin as active construction, not an instant finished building.")
	power.call("request_grid_refresh")
	_require(is_equal_approx(power.max_power, 500.0), "Foundation contributed storage before commissioning.")
	if bank != null:
		bank.call("complete_construction")
	power.call("request_grid_refresh")
	_require(is_equal_approx(power.max_power, 750.0), "Commissioned Capacitor did not add 250 reserve capacity.")
	game_root.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[ConstructionPlacementContractSmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[ConstructionPlacementContractSmoke] PASS")
	quit(0)
