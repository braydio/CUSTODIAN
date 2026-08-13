extends SceneTree

const CONTROLLER := preload("res://game/infrastructure/construction_placement_controller.gd")
const TURRET_PLACEMENT := preload("res://game/systems/core/systems/turret_placement.gd")
const POWER := preload("res://game/systems/core/systems/power.gd")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var inventory := root.get_node("BuildInventory")
	inventory.clear()
	var registry := root.get_node("InfrastructureRegistry")
	registry.clear_runtime_state()
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var power := POWER.new()
	power.name = "Power"
	power.total_power = 100.0
	power.max_power = 500.0
	game_root.add_child(power)
	power.set_process(false)
	var zone := ConstructionZone2D.new()
	zone.size = Vector2(512, 512)
	zone.global_position = Vector2(256, 256)
	zone.allowed_categories = [&"power"]
	zone.site_tags = [&"compound", &"fabrication"]
	world.add_child(zone)
	var controller := CONTROLLER.new() as ConstructionPlacementController
	controller.name = "ConstructionPlacement"
	world.add_child(controller)
	var tactical := TURRET_PLACEMENT.new() as TurretPlacement
	tactical.name = "TurretPlacement"
	world.add_child(tactical)
	await process_frame
	_require(controller.can_handle_build_token(&"capacitor_bank_mk1"), "controller does not own capacitor token")
	_require(tactical.get_placeable_type_for_build_token("capacitor_bank_mk1").is_empty(), "TurretPlacement still owns capacitor")
	_require(not controller.enter_build_token_placement(&"capacitor_bank_mk1"), "placement entered without token")
	inventory.add("capacitor_bank_mk1", 1)
	_require(controller.enter_build_token_placement(&"capacitor_bank_mk1"), "placement did not enter with token")
	_require(inventory.get_amount("capacitor_bank_mk1") == 1, "enter consumed token")
	controller.cancel_placement()
	_require(inventory.get_amount("capacitor_bank_mk1") == 1, "cancel consumed token")
	_require(controller.enter_build_token_placement(&"capacitor_bank_mk1"), "placement did not reenter")
	_require(not controller.attempt_commit_at(Vector2(480, 480)), "invalid partial-zone placement committed")
	_require(inventory.get_amount("capacitor_bank_mk1") == 1, "invalid placement consumed token")
	_require(controller.attempt_commit_at(Vector2(64, 64)), "valid placement failed")
	_require(inventory.get_amount("capacitor_bank_mk1") == 0, "commit did not consume exactly one token")
	var structures := get_nodes_in_group("infrastructure_structure")
	_require(structures.size() == 1, "commit did not create exactly one infrastructure structure")
	var bank := structures[0] if not structures.is_empty() else null
	_require(bank != null and str(bank.get("construction_state")) == "under_construction", "bank did not begin under construction")
	_require(not controller.attempt_commit_at(Vector2(192, 64)), "one token double-placed")
	power.call("request_grid_refresh")
	_require(is_equal_approx(power.max_power, 500.0), "foundation contributed storage")
	if bank != null:
		bank.call("complete_construction")
	power.call("request_grid_refresh")
	_require(is_equal_approx(power.max_power, 750.0), "commissioned bank did not add 250 storage")
	game_root.queue_free()
	await process_frame
	inventory.clear()
	registry.clear_runtime_state()
	_finish()


func _require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("[ConstructionPlacementControllerSmoke] %s" % message)


func _finish() -> void:
	if failed:
		quit(1)
		return
	print("[ConstructionPlacementControllerSmoke] PASS")
	quit(0)
