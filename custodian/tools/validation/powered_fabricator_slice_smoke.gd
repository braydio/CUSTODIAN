extends SceneTree

const POWER_SCRIPT := preload("res://game/systems/core/systems/power.gd")
const PLACEMENT_SCRIPT := preload("res://game/systems/core/systems/turret_placement.gd")
const FIELD_FABRICATOR_SCENE := preload("res://game/infrastructure/structures/field_fabricator_mk1.tscn")
const SOURCE_SCRIPT := preload("res://tools/validation/fixtures/power_rate_test_source.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry := root.get_node("InfrastructureRegistry")
	registry.clear_runtime_state()
	var resource_ledger := root.get_node("ResourceLedger")
	var build_inventory := root.get_node("BuildInventory")
	var fab_pipeline := root.get_node("FabPipeline")
	resource_ledger.clear()
	build_inventory.clear()
	fab_pipeline.clear_jobs()
	fab_pipeline.load_recipes()
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
	var source := SOURCE_SCRIPT.new()
	source.output_rate = 120.0
	source.add_to_group("power_node")
	world.add_child(source)
	var fabricator := FIELD_FABRICATOR_SCENE.instantiate()
	world.add_child(fabricator)
	var placement := PLACEMENT_SCRIPT.new()
	placement.name = "TurretPlacement"
	world.add_child(placement)
	power.call("_process", 1.0 / 60.0)
	_require(is_equal_approx(fab_pipeline.get_fabrication_rate_multiplier(), 1.0), "Standard-powered Fabricator should run at 1.0x.")
	resource_ledger.add("structural_alloy", 8)
	resource_ledger.add("ruin_scrap", 14)
	resource_ledger.add("power_components", 2)
	resource_ledger.add("capacitor_dust", 8)
	resource_ledger.add("resin_clot", 1)
	_require(fab_pipeline.try_start_recipe("capacitor_bank_mk1"), "Capacitor work order did not start with exact materials.")
	fab_pipeline.call("_tick_jobs", 6.0)
	_require(build_inventory.get_amount("capacitor_bank_mk1") == 1, "Completed work order did not create a Capacitor Ready Build.")
	_require(placement.enter_build_token_placement("capacitor_bank_mk1"), "Ready Build did not enter construction placement.")
	_require(placement.attempt_place_build_at(Vector2(900, 900)), "Capacitor placement failed at a clear site.")
	var bank: Node = placement.get_placed_structures()[0]
	bank.call("complete_construction")
	power.call("request_grid_refresh")
	_require(is_equal_approx(power.max_power, 750.0), "Commissioned bank did not increase grid capacity.")
	bank.call("take_damage", 120.0)
	power.call("request_grid_refresh")
	_require(is_equal_approx(power.max_power, 625.0), "Half-integrity bank should contribute half storage capacity.")
	bank.call("take_damage", 120.0)
	power.call("request_grid_refresh")
	_require(is_equal_approx(power.max_power, 500.0), "Destroyed bank did not unregister storage capacity.")
	var status := power.get_power_status()
	_require(status.has("stored_energy") and status.has("storage_capacity"), "Terminal-facing power snapshot lacks explicit reserve fields.")
	_require(registry.get_structure_snapshot().size() == 2, "Registry should retain Fabricator and destroyed bank state.")
	game_root.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[PoweredFabricatorSliceSmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[PoweredFabricatorSliceSmoke] PASS")
	quit(0)
