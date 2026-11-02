extends Node
class_name CommandPressureScenarioDirector

signal phase_changed(phase: StringName)

const PREPARATION_SECONDS := 110.0
const ASSAULT_COMPOSITION: Array[String] = [
	"grunt", "grunt", "grunt", "marine", "grunt", "grunt",
]
const NODE_LAYOUT := {
	"World/Operator": Vector2(720, -420),
	"World/CommandTerminal": Vector2(804, -492),
	"World/FieldFabricatorMk1": Vector2(1120, -480),
	"World/FabricationConstructionZone": Vector2(1168, -480),
	"World/Sectors/POWER": Vector2(1500, -480),
	"World/Sectors/DEFENSE": Vector2(804, -860),
	"World/Sectors/NORTH_TRANSIT": Vector2(804, -1220),
	"World/Sectors/STORAGE": Vector2(390, -480),
	"World/Sectors/ARCHIVE": Vector2(390, -840),
	"World/Sectors/SOUTH_TRANSIT": Vector2(804, 0),
	"World/SpawnNodes/NorthSpawn": Vector2(804, -2200),
}

var phase: StringName = &"PREPARATION"
var elapsed := 0.0
var assault_started := false
var authored_spawned := 0
var lowest_power_reserve := INF
var start_resources: Dictionary = {}
var field_repairs_completed := 0
var remote_repairs_completed := 0
var completed_recipes: Array[String] = []
var placed_structures: Array[String] = []
var corpse_salvage: Dictionary = {}
var _terminal_was_open := false


func _ready() -> void:
	add_to_group("command_pressure_scenario")
	call_deferred("_initialize_scenario")


func _process(delta: float) -> void:
	if phase == &"PREPARATION":
		elapsed += delta
		if elapsed >= PREPARATION_SECONDS:
			start_assault()
	_observe_live_state()


func _initialize_scenario() -> void:
	var game_root := get_node_or_null("/root/GameRoot")
	if game_root == null:
		return
	for path_variant in NODE_LAYOUT.keys():
		var node := game_root.get_node_or_null(String(path_variant)) as Node2D
		if node != null:
			node.position = NODE_LAYOUT[path_variant]
	_configure_spawns(game_root)
	_configure_integrity(game_root)
	_configure_turrets(game_root)
	_configure_ledger()
	await get_tree().process_frame
	await get_tree().process_frame
	_tune_power_reserve(game_root)
	_connect_runtime_observation(game_root)
	_log_event(&"command_pressure_started", get_setup_snapshot())


func _configure_spawns(game_root: Node) -> void:
	for spawn_name in ["NorthSpawn", "EastSpawn", "SouthSpawn", "WestSpawn"]:
		var spawn := game_root.get_node_or_null("World/SpawnNodes/%s" % spawn_name)
		if spawn == null:
			continue
		spawn.set("active", spawn_name == "NorthSpawn")
		if spawn_name == "NorthSpawn":
			spawn.set("lane", "north")


func _configure_integrity(game_root: Node) -> void:
	for sector_name in ["POWER", "DEFENSE", "ARCHIVE", "STORAGE", "NORTH_TRANSIT", "SOUTH_TRANSIT"]:
		var sector := game_root.get_node_or_null("World/Sectors/%s" % sector_name)
		if sector == null:
			continue
		var target_ratio := 0.35 if sector_name == "POWER" else (0.55 if sector_name == "DEFENSE" else 1.0)
		var max_hp := float(sector.get("max_health"))
		var damage := maxf(0.0, float(sector.get("current_health")) - max_hp * target_ratio)
		if damage > 0.0:
			sector.call("take_damage", damage)


func _configure_turrets(game_root: Node) -> void:
	var defense := game_root.get_node_or_null("World/Sectors/DEFENSE")
	if defense == null:
		return
	for turret in defense.get_children():
		if "max_inaccuracy_degrees" in turret:
			turret.set("max_inaccuracy_degrees", 0.0)


func _configure_ledger() -> void:
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger == null:
		return
	ledger.call("clear")
	ledger.call("add", "ruin_scrap", 5)
	start_resources = ledger.call("get_snapshot")


func _tune_power_reserve(game_root: Node) -> void:
	var power := game_root.get_node_or_null("Power")
	if power == null or not power.has_method("get_power_status"):
		return
	var status: Dictionary = power.call("get_power_status")
	var deficit := maxf(0.1, -float(status.get("net_per_second", 0.0)))
	power.set("total_power", minf(float(power.get("max_power")), deficit * 75.0))
	lowest_power_reserve = float(power.get("total_power"))


func _connect_runtime_observation(game_root: Node) -> void:
	var waves := game_root.get_node_or_null("WaveManager")
	if waves != null and waves.has_signal("authored_enemy_spawned"):
		waves.connect("authored_enemy_spawned", Callable(self, "_on_authored_enemy_spawned"))
	for resource in get_parent().get_node("ResourceNodes").get_children():
		resource.connect("depleted", Callable(self, "_on_resource_depleted"))
	for port in get_parent().get_node("ServicePorts").get_children():
		port.connect("repair_completed", Callable(self, "_on_field_repair_completed"))
	var power_sector := game_root.get_node_or_null("World/Sectors/POWER")
	if power_sector != null:
		power_sector.connect("damaged", Callable(self, "_on_power_damaged"))
	var power_system := game_root.get_node_or_null("Power")
	if power_system != null and power_system.has_signal("emergency_repair_applied"):
		power_system.connect("emergency_repair_applied", Callable(self, "_on_remote_repair"))
	var fab := get_node_or_null("/root/FabPipeline")
	if fab != null:
		fab.connect("job_started", Callable(self, "_on_recipe_started"))
		fab.connect("job_completed", Callable(self, "_on_recipe_completed"))
	var construction := game_root.get_node_or_null("World/ConstructionPlacement")
	if construction != null:
		construction.connect("placement_committed", Callable(self, "_on_structure_placed"))


func start_assault() -> bool:
	if assault_started:
		return false
	var waves := get_node_or_null("/root/GameRoot/WaveManager")
	if waves == null or not waves.has_method("start_external_wave"):
		return false
	assault_started = bool(waves.call("start_external_wave", ASSAULT_COMPOSITION, "north", "destroy_power", &""))
	if assault_started:
		phase = &"ASSAULT"
		phase_changed.emit(phase)
		_log_event(&"command_pressure_assault_started", {"composition": ASSAULT_COMPOSITION})
	return assault_started


func _observe_live_state() -> void:
	var power := get_node_or_null("/root/GameRoot/Power")
	if power != null:
		lowest_power_reserve = minf(lowest_power_reserve, float(power.get("total_power")))
	if phase == &"ASSAULT" and assault_started:
		var waves := get_node_or_null("/root/GameRoot/WaveManager")
		if waves != null:
			var status: Dictionary = waves.call("get_wave_status")
			if not bool(status.get("in_progress", false)) and int(status.get("pending_spawns", 0)) == 0 and int(status.get("alive_enemies", 0)) == 0:
				phase = &"AFTERMATH"
				phase_changed.emit(phase)
				_log_event(&"command_pressure_assault_cleared")
	var ui := get_node_or_null("/root/GameRoot/UI")
	var terminal_open := ui != null and ui.has_method("is_terminal_open") and bool(ui.call("is_terminal_open"))
	if phase == &"AFTERMATH" and terminal_open and not _terminal_was_open:
		phase = &"COMPLETE"
		phase_changed.emit(phase)
		_log_event(&"command_pressure_aftermath_opened", get_after_action_snapshot())
		_log_event(&"command_pressure_completed", get_after_action_snapshot())
	_terminal_was_open = terminal_open


func get_setup_snapshot() -> Dictionary:
	return {
		"scenario_id": "command_pressure_v1",
		"phase": String(phase),
		"preparation_seconds": PREPARATION_SECONDS,
		"composition": ASSAULT_COMPOSITION.duplicate(),
		"node_layout": NODE_LAYOUT.duplicate(true),
		"resource_node_count": get_parent().get_node("ResourceNodes").get_child_count(),
	}


func get_after_action_snapshot() -> Dictionary:
	var power := get_node_or_null("/root/GameRoot/Power")
	var ledger := get_node_or_null("/root/ResourceLedger")
	var waves := get_node_or_null("/root/GameRoot/WaveManager")
	var registry := get_node_or_null("/root/InfrastructureRegistry")
	var fab := get_node_or_null("/root/FabPipeline")
	return {
		"phase": String(phase),
		"power": power.call("get_power_status") if power != null else {},
		"resources": ledger.call("get_snapshot") if ledger != null else {},
		"resource_delta": _dictionary_delta(start_resources, ledger.call("get_snapshot") if ledger != null else {}),
		"wave": waves.call("get_wave_status") if waves != null else {},
		"hostiles_spawned": authored_spawned,
		"field_repairs": field_repairs_completed,
		"remote_repairs": remote_repairs_completed,
		"power_low_water_mark": lowest_power_reserve,
		"sectors": _sector_integrity_snapshot(),
		"fabrication_jobs": fab.call("get_jobs_snapshot") if fab != null else [],
		"completed_recipes": completed_recipes.duplicate(),
		"placed_structures": placed_structures.duplicate(),
		"infrastructure": registry.call("get_structure_snapshot") if registry != null else [],
		"corpse_salvage": corpse_salvage.duplicate(true),
	}


func _sector_integrity_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for sector in get_tree().get_nodes_in_group("sector"):
		result.append({
			"name": String(sector.get("sector_name")),
			"current_hp": float(sector.get("current_health")),
			"max_hp": float(sector.get("max_health")),
			"powered": bool(sector.get("powered")),
			"power_tier": String(sector.get("power_tier")),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["name"]) < String(b["name"]))
	return result


func _dictionary_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var result := {}
	for key in after.keys():
		result[key] = int(after[key]) - int(before.get(key, 0))
	return result


func _on_authored_enemy_spawned(enemy: Node, enemy_type: String) -> void:
	authored_spawned += 1
	enemy.child_entered_tree.connect(func(child: Node) -> void:
		if child is EnemyCorpseLoot:
			child.loot_collected.connect(_on_corpse_loot_collected)
	)
	_log_event(&"command_pressure_enemy_spawned", {"enemy_type": enemy_type, "count": authored_spawned})


func _on_resource_depleted(_node: Node, resource_id: String, amount: int) -> void:
	_log_event(&"command_pressure_resource_node_depleted", {"resource_id": resource_id, "amount": amount})


func _on_field_repair_completed(_target: Node, amount: float) -> void:
	field_repairs_completed += 1
	_log_event(&"command_pressure_field_repair_completed", {"repair_amount": amount})


func _on_power_damaged(amount: float, new_hp: float) -> void:
	_log_event(&"command_pressure_power_damaged", {"amount": amount, "new_hp": new_hp})


func _on_remote_repair(sector_name: String, repair_amount: float, power_cost: float) -> void:
	remote_repairs_completed += 1
	_log_event(&"command_pressure_remote_repair_completed", {"sector": sector_name, "repair_amount": repair_amount, "power_cost": power_cost})


func _on_recipe_started(job_id: int, recipe_id: String) -> void:
	_log_event(&"command_pressure_recipe_started", {"job_id": job_id, "recipe_id": recipe_id})


func _on_recipe_completed(job_id: int, recipe_id: String, output_type: String, output_id: String, output_amount: int) -> void:
	completed_recipes.append(recipe_id)
	_log_event(&"command_pressure_recipe_completed", {"job_id": job_id, "recipe_id": recipe_id, "output_type": output_type, "output_id": output_id, "output_amount": output_amount})


func _on_structure_placed(_instance: Node2D, build_id: StringName) -> void:
	placed_structures.append(String(build_id))
	_log_event(&"command_pressure_structure_placed", {"build_id": String(build_id)})


func _on_corpse_loot_collected(payload: Dictionary) -> void:
	for key in payload.keys():
		corpse_salvage[key] = int(corpse_salvage.get(key, 0)) + int(payload[key])


func _log_event(kind: StringName, data: Dictionary = {}) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", kind, data)
