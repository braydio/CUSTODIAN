extends SceneTree

const FabricationTerminalViewModelScript := preload("res://game/ui/terminal/fabrication_terminal_view_model.gd")
const TerminalCommandRouterScript := preload("res://game/ui/terminal/terminal_command_router.gd")
const TurretPlacementScript := preload("res://game/systems/core/systems/turret_placement.gd")
func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var resource_ledger := root.get_node_or_null("/root/ResourceLedger")
	var build_inventory := root.get_node_or_null("/root/BuildInventory")
	var fab_pipeline := root.get_node_or_null("/root/FabPipeline")
	assert(resource_ledger != null)
	assert(build_inventory != null)
	assert(fab_pipeline != null)

	resource_ledger.call("clear")
	resource_ledger.call("add", "ruin_scrap", 30)
	resource_ledger.call("add", "structural_alloy", 12)
	resource_ledger.call("add", "power_components", 2)
	resource_ledger.call("add", "capacitor_dust", 6)
	resource_ledger.call("add", "signal_filament", 2)
	resource_ledger.call("add", "memory_glass_fragment", 2)
	resource_ledger.call("add", "resin_clot", 4)
	resource_ledger.call("add", "fiber_moss", 3)
	resource_ledger.call("add", "blackwood", 10)
	build_inventory.call("clear")
	build_inventory.call("add", "turret_basic", 1)
	build_inventory.call("add", "barricade_light", 1)
	build_inventory.call("add", "power_bank_patch", 1)
	fab_pipeline.call("clear_jobs")

	var view_model := FabricationTerminalViewModelScript.new() as FabricationTerminalViewModel
	assert(view_model != null)
	var view := view_model.build(root, "power_bank_patch")
	var status: Dictionary = view.get("status", {})
	assert(str(status.get("fabricator_state", "")) == "ONLINE")
	assert(str(status.get("ready_build_summary", "")) == "3 ready / 1 deployable")
	assert(str(status.get("next_action", "")).begins_with("Place completed Basic Turret"))
	var selected: Dictionary = view.get("selected_work_order", {})
	assert(str(selected.get("id", "")) == "power_bank_patch")
	assert(str(selected.get("action_text", "")) == "STORED READY BUILD")
	assert(str(selected.get("result_text", "")).begins_with("Ready Build: Power Bank Patch"))
	var ready_builds: Array = view.get("ready_builds", [])
	assert(not ready_builds.is_empty())
	assert(str((ready_builds[0] as Dictionary).get("action_text", "")) == "BUILD PLACE turret_basic")
	assert(str((ready_builds[1] as Dictionary).get("action_text", "")) == "STORED READY BUILD")
	assert(TerminalCommandRouterScript.VALID_VERBS.has("BUILD"))
	assert(TurretPlacementScript.new().get_turret_type_for_build_token("turret_basic") == "gunner")
	var work_orders: Array = view.get("work_orders", [])
	assert(not work_orders.is_empty())
	var barricade_row := _find_row(work_orders, "barricade_light")
	assert(not barricade_row.is_empty())
	assert(str(barricade_row.get("purpose", "")).contains("lane denial"))
	var archive_row := _find_row(work_orders, "archive_sensor_pylon")
	assert(not archive_row.is_empty())
	assert(str(archive_row.get("purpose", "")).contains("Archive-grade"))

	build_inventory.call("clear")
	fab_pipeline.call("clear_jobs")
	view = view_model.build(root)
	status = view.get("status", {})
	assert(str(status.get("first_fabrication_hint", "")).contains("First Fabrication"))
	print("[FabricationTerminalReadabilitySmoke] ok")
	quit(0)


func _find_row(rows: Array, row_id: String) -> Dictionary:
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row := row_variant as Dictionary
		if str(row.get("id", "")) == row_id:
			return row
	return {}
