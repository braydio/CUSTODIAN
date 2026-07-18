extends SceneTree

const TurretPlacementScript := preload("res://game/systems/core/systems/turret_placement.gd")
const FabricationTerminalViewModelScript := preload("res://game/ui/terminal/fabrication_terminal_view_model.gd")
const UIScript := preload("res://game/ui/hud/ui.gd")

var _placement_failures: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ledger := root.get_node_or_null("/root/ResourceLedger")
	var build_inventory := root.get_node_or_null("/root/BuildInventory")
	var fab_pipeline := root.get_node_or_null("/root/FabPipeline")
	assert(ledger != null)
	assert(build_inventory != null)
	assert(fab_pipeline != null)

	ledger.call("clear")
	build_inventory.call("clear")
	fab_pipeline.call("clear_jobs")
	ledger.call("add", "blackwood", 10)
	ledger.call("add", "ruin_scrap", 4)
	assert(fab_pipeline.call("try_start_recipe", "barricade_light"))
	fab_pipeline.call("_tick_jobs", 4.1)
	assert(int(build_inventory.call("get_amount", "barricade_light")) == 1)

	var view_model := FabricationTerminalViewModelScript.new() as FabricationTerminalViewModel
	var view := view_model.build(root, "barricade_light")
	var ready_build := _find_ready_build(view.get("ready_builds", []), "barricade_light")
	assert(not ready_build.is_empty())
	assert(bool(ready_build.get("deployable", false)))
	assert(str(ready_build.get("action_text", "")) == "BUILD PLACE barricade_light")

	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.set_script(UIScript)
	game_root.add_child(ui)
	var placement := TurretPlacementScript.new() as TurretPlacement
	placement.name = "TurretPlacement"
	world.add_child(placement)
	await process_frame
	placement.build_placement_failed.connect(_on_build_placement_failed)
	assert(placement.get_placeable_type_for_build_token("barricade_light") == "light_barricade")
	assert(bool(ui.call("_start_ready_build_placement", "barricade_light")))
	assert(placement.is_placing())
	assert(placement.get_selected_type() == "light_barricade")
	assert(_terminal_contains(ui, "BUILD PLACEMENT ACTIVE // BARRICADE_LIGHT"))

	var blocker := Node2D.new()
	blocker.add_to_group("structure")
	world.add_child(blocker)
	blocker.global_position = Vector2.ZERO
	assert(not placement.attempt_place_build_at(Vector2.ZERO))
	assert(int(build_inventory.call("get_amount", "barricade_light")) == 1)
	assert(not _placement_failures.is_empty())
	assert(str(_placement_failures.back().get("reason", "")) == "invalid_site")
	assert(_terminal_contains(ui, "INVALID BUILD SITE"))

	blocker.queue_free()
	await process_frame
	assert(placement.attempt_place_build_at(Vector2(128.0, 0.0)))
	assert(int(build_inventory.call("get_amount", "barricade_light")) == 0)
	assert(not placement.is_placing())
	assert(_terminal_contains(ui, "BARRICADE PLACED"))
	var structures := placement.get_placed_structures()
	assert(structures.size() == 1)
	var barricade := structures[0]
	assert(barricade is LightBarricade)
	assert(barricade.is_in_group("structure"))
	assert(barricade.is_in_group("buildable_structure"))
	assert(barricade.is_in_group("enemy_obstacle"))
	assert(is_equal_approx(float(barricade.get("current_health")), 80.0))
	var collision_body := barricade.get_node_or_null("StaticBody2D")
	assert(collision_body != null)
	assert(collision_body.get_node_or_null("CollisionShape2D") != null)
	var projectile_result: Dictionary = collision_body.call("receive_projectile_hit", 12.0, "enemy")
	assert(is_equal_approx(float(projectile_result.get("applied_damage", 0.0)), 10.0))
	assert(is_equal_approx(float(barricade.get("current_health")), 70.0))

	build_inventory.call("add", "turret_basic", 1)
	assert(placement.get_placeable_type_for_build_token("turret_basic") == "gunner")
	assert(placement.enter_build_token_placement("turret_basic"))
	assert(placement.attempt_place_build_at(Vector2(256.0, 0.0)))
	assert(int(build_inventory.call("get_amount", "turret_basic")) == 0)
	assert(placement.get_placed_turrets().size() == 1)

	barricade.call("take_damage", 40.0)
	assert(str(barricade.get("state")) == "damaged")
	barricade.call("take_damage", 30.0)
	await process_frame
	assert(not is_instance_valid(barricade))

	ledger.call("clear")
	build_inventory.call("clear")
	fab_pipeline.call("clear_jobs")
	game_root.queue_free()
	await process_frame
	print("[BuildStructurePlacementSmoke] ok")
	quit(0)


func _find_ready_build(rows: Array, build_token_id: String) -> Dictionary:
	for row_variant in rows:
		if row_variant is Dictionary and str((row_variant as Dictionary).get("id", "")) == build_token_id:
			return row_variant as Dictionary
	return {}


func _terminal_contains(ui: Node, expected: String) -> bool:
	var lines: Array = ui.get("_terminal_lines")
	for line_variant in lines:
		if str(line_variant).contains(expected):
			return true
	return false


func _on_build_placement_failed(build_token_id: String, reason: String) -> void:
	_placement_failures.append({
		"build_token_id": build_token_id,
		"reason": reason,
	})
