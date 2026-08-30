extends SceneTree

const RESOURCE_SCENE := preload("res://game/resources/resource_node.tscn")
const POWER_NODE_SCRIPT := preload("res://game/actors/sector/power_node.gd")
const WAVE_SCRIPT := preload("res://game/systems/core/systems/wave_manager.gd")
const SPAWN_SCRIPT := preload("res://game/systems/core/systems/spawn_node.gd")
const POWER_SCRIPT := preload("res://game/systems/core/systems/power.gd")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const MARINE_SCENE := preload("res://game/actors/enemies/enemy_marine.tscn")
const REPAIR_SCRIPT := preload("res://game/infrastructure/repair/field_repair_interaction.gd")
const NAVIGATION_SCRIPT := preload("res://game/systems/core/systems/navigation_system.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ledger := root.get_node("ResourceLedger")
	ledger.clear()
	ledger.add("ruin_scrap", 5)
	var resource := RESOURCE_SCENE.instantiate()
	resource.resource_id = "ruin_scrap"
	resource.work_required = 2
	resource.yield_amount = 10
	resource.secondary_yields = {"power_components": 1}
	root.add_child(resource)
	resource.interact(null)
	resource.interact(null)
	_require(resource.is_depleted(), "actual ResourceNode did not physically deplete")
	_require(ledger.get_amount("ruin_scrap") == 15 and ledger.get_amount("power_components") == 1, "actual ResourceNode did not deposit exact yields")

	var game := Node.new()
	game.name = "GameRoot"
	root.add_child(game)
	var world := Node2D.new()
	world.name = "World"
	game.add_child(world)
	var navigation := NAVIGATION_SCRIPT.new()
	navigation.name = "NavigationSystem"
	game.add_child(navigation)
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	world.add_child(enemies)
	var spawns := Node2D.new()
	spawns.name = "SpawnNodes"
	world.add_child(spawns)
	var spawn := Node2D.new()
	spawn.name = "NorthSpawn"
	spawn.set_script(SPAWN_SCRIPT)
	spawn.set("lane", "north")
	spawn.position = Vector2(0, -420)
	spawns.add_child(spawn)
	var sectors := Node2D.new()
	sectors.name = "Sectors"
	world.add_child(sectors)
	var power_sector := POWER_NODE_SCRIPT.new()
	power_sector.name = "POWER"
	power_sector.set("sector_name", "POWER")
	power_sector.set("sector_type", "POWER")
	power_sector.position = Vector2.ZERO
	sectors.add_child(power_sector)
	var power := POWER_SCRIPT.new()
	power.name = "Power"
	game.add_child(power)
	power.set_process(false)
	await process_frame
	var output_before := power.get_total_power_output_rate()
	power_sector.take_damage(40.0)
	_require(power.get_total_power_output_rate() < output_before, "physical POWER damage did not reduce generation")

	ledger.add("ruin_scrap", 6)
	var actor := Node2D.new()
	actor.position = Vector2.ZERO
	world.add_child(actor)
	var repair := REPAIR_SCRIPT.new()
	repair.target_path = NodePath("/root/GameRoot/World/Sectors/POWER")
	repair.hold_duration = 0.01
	repair.resource_cost = {"ruin_scrap": 6, "power_components": 1}
	repair.repair_amount = 30.0
	world.add_child(repair)
	var damaged_hp := float(power_sector.get("current_health"))
	repair.interact(actor)
	repair.call("_physics_process", 0.02)
	_require(float(power_sector.get("current_health")) > damaged_hp, "field repair did not call actual Sector.repair")
	_require(ledger.get_amount("power_components") == 0, "field repair did not pay through ResourceLedger")

	var waves := WAVE_SCRIPT.new()
	waves.name = "WaveManager"
	waves.automatic_cadence_enabled = false
	waves.procedural_enemy_variants_enabled = false
	waves.grunt_scene = GRUNT_SCENE
	waves.marine_scene = MARINE_SCENE
	waves.intra_wave_spawn_interval = 0.01
	waves.spawn_burst_size = 6
	waves.spawn_burst_pause = 0.01
	game.add_child(waves)
	await process_frame
	var composition: Array[String] = ["grunt", "grunt", "grunt", "marine", "grunt", "grunt"]
	_require(waves.start_external_wave(composition, "north", "destroy_power"), "authored WaveManager ingress rejected exact plan")
	for _index in range(30):
		await create_timer(0.02).timeout
	_require(enemies.get_child_count() == 6, "authored wave did not instantiate exactly six physical enemies")
	var grunts := 0
	var marines := 0
	for enemy in enemies.get_children():
		_require(String(enemy.get("attack_objective")) == "destroy_power", "spawned enemy lost physical destroy_power objective")
		_require(bool(enemy.get_meta("authored_wave_enemy", false)), "spawned enemy lacks authored-wave observation tag")
		if String(enemy.get("enemy_name")).to_upper().contains("MARINE"):
			marines += 1
		else:
			grunts += 1
	_require(grunts == 5 and marines == 1, "authored wave type composition drifted")
	var first_enemy := enemies.get_child(0) as Node2D
	var spawn_position := first_enemy.global_position
	for _index in range(20):
		await physics_frame
	_require(first_enemy.global_position.distance_to(spawn_position) > 1.0, "physical hostile did not advance toward live POWER target")
	var status: Dictionary = waves.get_wave_status()
	_require(int(status.get("pending_spawns", -1)) == 0, "authored wave retained pending spawns")

	resource.queue_free()
	game.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("[CommandPressurePhysicalLoopSmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[CommandPressurePhysicalLoopSmoke] PASS")
	quit(0)
