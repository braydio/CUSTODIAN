extends SceneTree

const POWER_SCRIPT := preload("res://game/systems/core/systems/power.gd")
const PLACEMENT_SCRIPT := preload("res://game/infrastructure/construction_placement_controller.gd")
const FIELD_FABRICATOR_SCENE := preload("res://game/infrastructure/structures/field_fabricator_mk1.tscn")
const SOURCE_SCRIPT := preload("res://tools/validation/fixtures/power_rate_test_source.gd")
const FAB_VIEW_MODEL := preload("res://game/ui/terminal/fabrication_terminal_view_model.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry := root.get_node("InfrastructureRegistry")
	registry.clear_runtime_state()
	var resource_ledger := root.get_node("ResourceLedger")
	var build_inventory := root.get_node("BuildInventory")
	var fab_pipeline := root.get_node("FabPipeline")
	fab_pipeline.set_process(false)
	fab_pipeline.allow_test_without_fabricator = false
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
	var consumer := fabricator.get_node("PowerConsumer") as PowerConsumerComponent
	var visual := fabricator.get_node("VisualController") as FieldFabricatorVisualController
	var placement := PLACEMENT_SCRIPT.new()
	placement.name = "ConstructionPlacement"
	world.add_child(placement)
	var zone := ConstructionZone2D.new()
	zone.size = Vector2(1800, 1800)
	zone.global_position = Vector2(900, 900)
	zone.allowed_categories = [&"power"]
	world.add_child(zone)
	power.call("_process", 1.0 / 60.0)
	_require(is_equal_approx(fab_pipeline.get_fabrication_rate_multiplier(), 1.0), "Standard-powered Fabricator should run at 1.0x.")
	consumer.apply_power_allocation(10.0)
	_require(is_equal_approx(fab_pipeline.get_fabrication_rate_multiplier(), 0.4), "Minimum allocation should degrade Fabricator throughput to 0.4x.")
	consumer.apply_power_allocation(25.0)
	_require(is_equal_approx(fab_pipeline.get_fabrication_rate_multiplier(), 1.0), "Standard allocation should restore 1.0x throughput.")
	var terminal_projection: Dictionary = FAB_VIEW_MODEL.new().build(game_root)
	var terminal_status: Dictionary = terminal_projection.get("status", {})
	_require(str(terminal_status.get("fabricator_state", "")) == "ONLINE", "Terminal should report the real standard-powered machine as ONLINE.")
	_require(is_equal_approx(float(terminal_status.get("power_allocated", 0.0)), 25.0), "Terminal should project actual allocated power.")
	_require(is_equal_approx(float(terminal_status.get("fabrication_multiplier", 0.0)), 1.0), "Terminal should project actual Fabrication multiplier.")
	consumer.overdrive_enabled = true
	consumer.apply_power_allocation(40.0)
	_require(is_equal_approx(fab_pipeline.get_fabrication_rate_multiplier(), 1.35), "Enabled overdrive should run at 1.35x.")
	consumer.overdrive_enabled = false
	consumer.apply_power_allocation(25.0)
	fabricator.call("take_damage", 160.0)
	_require(is_equal_approx(fab_pipeline.get_fabrication_rate_multiplier(), 0.25), "Half-integrity Fabricator should preserve the existing integrity-scaled power and service throughput contract.")
	terminal_projection = FAB_VIEW_MODEL.new().build(game_root)
	terminal_status = terminal_projection.get("status", {})
	_require(str(terminal_status.get("fabricator_state", "")) == "DEGRADED", "Terminal should report integrity-degraded machine truth.")
	fabricator.call("heal", 160.0)
	_require(is_equal_approx(fab_pipeline.get_fabrication_rate_multiplier(), 1.0), "Repair should restore standard throughput.")
	resource_ledger.add("structural_alloy", 8)
	resource_ledger.add("ruin_scrap", 14)
	resource_ledger.add("power_components", 2)
	resource_ledger.add("capacitor_dust", 8)
	resource_ledger.add("resin_clot", 1)
	resource_ledger.add("blackwood", 10)
	resource_ledger.add("ruin_scrap", 4)
	_require(fab_pipeline.try_start_recipe("capacitor_bank_mk1"), "Capacitor work order did not start with exact materials.")
	_require(fab_pipeline.try_start_recipe("barricade_light"), "Second FIFO work order did not queue.")
	fab_pipeline.call("_tick_jobs", 1.0)
	var queued: Array = fab_pipeline.get_jobs_snapshot()
	_require(float((queued[0] as Dictionary).get("elapsed", 0.0)) > 0.0, "First FIFO job did not progress.")
	_require(is_zero_approx(float((queued[1] as Dictionary).get("elapsed", 0.0))), "Second FIFO job progressed before the first completed.")
	terminal_projection = FAB_VIEW_MODEL.new().build(game_root)
	terminal_status = terminal_projection.get("status", {})
	_require(str(terminal_status.get("active_recipe_id", "")) == "capacitor_bank_mk1", "Terminal should project the active FIFO recipe.")
	_require(int(terminal_status.get("waiting_queue_count", -1)) == 1, "Terminal should project one waiting FIFO job.")
	consumer.apply_power_allocation(0.0)
	var paused_elapsed := float((fab_pipeline.get_jobs_snapshot()[0] as Dictionary).get("elapsed", 0.0))
	fab_pipeline.call("_tick_jobs", 2.0)
	_require(is_equal_approx(float((fab_pipeline.get_jobs_snapshot()[0] as Dictionary).get("elapsed", 0.0)), paused_elapsed), "Power loss should preserve active job progress.")
	_require(visual.get_active_state() == &"offline", "Power loss should select offline presentation.")
	consumer.apply_power_allocation(25.0)
	_require(visual.get_active_state() == &"startup", "Power restoration should play startup.")
	visual.call("_on_body_animation_finished")
	_require(visual.get_active_state() == &"fabricate", "Startup completion should resume fabrication presentation.")
	fab_pipeline.call("_tick_jobs", 5.0)
	_require(visual.get_active_state() == &"fabricate_complete", "Job completion should play fabricate_complete.")
	queued = fab_pipeline.get_jobs_snapshot()
	_require(queued.size() == 1 and str((queued[0] as Dictionary).get("recipe_id", "")) == "barricade_light", "Second FIFO job should become active only after first completion.")
	_require(is_zero_approx(float((queued[0] as Dictionary).get("elapsed", 0.0))), "Newly active second job should still be at zero progress after handoff.")
	visual.call("_on_body_animation_finished")
	_require(visual.get_active_state() == &"fabricate", "Completion one-shot should return to fabricate when another job waits.")
	_require(build_inventory.get_amount("capacitor_bank_mk1") == 1, "Completed work order did not create a Capacitor Ready Build.")
	_require(placement.enter_build_token_placement("capacitor_bank_mk1"), "Ready Build did not enter construction placement.")
	_require(placement.attempt_commit_at(Vector2(900, 900)), "Capacitor placement failed at a clear site.")
	var bank: Node = get_nodes_in_group("infrastructure_structure").filter(func(node): return node != fabricator)[0]
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
	fabricator.call("take_damage", 320.0)
	_require(is_zero_approx(fab_pipeline.get_fabrication_rate_multiplier()), "Destroyed Fabricator must not fabricate at legacy 1.0x.")
	_require(not fab_pipeline.try_start_recipe("barricade_light"), "Destroyed Fabricator must reject new work orders.")
	terminal_projection = FAB_VIEW_MODEL.new().build(game_root)
	terminal_status = terminal_projection.get("status", {})
	_require(str(terminal_status.get("fabricator_state", "")) == "DESTROYED", "Terminal should report destroyed machine truth.")
	registry.unregister_structure(fabricator)
	_require(is_zero_approx(fab_pipeline.get_fabrication_rate_multiplier()), "Absent Fabricator must not fabricate at legacy 1.0x.")
	terminal_projection = FAB_VIEW_MODEL.new().build(game_root)
	terminal_status = terminal_projection.get("status", {})
	_require(str(terminal_status.get("fabricator_state", "")) == "OFFLINE", "Terminal should report an absent Fabricator as OFFLINE without failing.")
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
