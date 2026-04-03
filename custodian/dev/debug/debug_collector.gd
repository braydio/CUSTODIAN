extends Node

const EnemyScript = preload("res://game/actors/enemies/enemy.gd")

@export var enemy_container_path: NodePath = NodePath("/root/GameRoot/World/Enemies")
@export var projectile_container_path: NodePath = NodePath("/root/GameRoot/World/Projectiles")
@export var wave_manager_path: NodePath = NodePath("/root/GameRoot/WaveManager")


func _get_debug_bus() -> Node:
	return get_node_or_null("/root/DebugBus")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -10
	set_process(true)

func _process(_delta: float) -> void:
	var debug_bus := _get_debug_bus()
	if debug_bus == null or not debug_bus.enabled:
		return
	_update_stats(debug_bus)
	_update_overlays(debug_bus)
	_update_inspector(debug_bus)

func _update_stats(debug_bus: Node) -> void:
	debug_bus.set_stat("SIM", "FPS", int(Engine.get_frames_per_second()))
	debug_bus.set_stat("SIM", "Tick Time (ms)", "%.2f" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0))

	var enemies := get_tree().get_nodes_in_group("enemies")
	var turrets := get_tree().get_nodes_in_group("turret")
	var projectiles := _get_node_child_count(projectile_container_path)
	var entity_count := enemies.size() + turrets.size() + projectiles
	debug_bus.set_stat("SIM", "Entities Active", entity_count)

	debug_bus.set_stat("COMBAT", "Enemies Alive", enemies.size())
	debug_bus.set_stat("COMBAT", "Projectiles Active", projectiles)
	_update_player_stats(debug_bus)
	_update_power_stats(debug_bus)
	_update_mission_stats(debug_bus)
	_update_camera_stats(debug_bus)
	_update_director_stats(debug_bus)
	_update_supply_stats(debug_bus)

	var wave_manager = get_node_or_null(wave_manager_path)
	if wave_manager != null:
		debug_bus.set_stat("WAVE", "Wave #", wave_manager.wave_number)
		var queue = wave_manager.get("_pending_spawns")
		if queue is Array:
			debug_bus.set_stat("WAVE", "Spawn Queue", queue.size())
		var wave_timer = wave_manager.get("_timer")
		if wave_timer is Timer:
			debug_bus.set_stat("WAVE", "Time To Next", "%.1fs" % wave_timer.time_left)


func _update_player_stats(debug_bus: Node) -> void:
	var operator = get_node_or_null("/root/GameRoot/World/Operator")
	if operator == null:
		return
	if operator.has_method("get_weapon_status"):
		var ws: Dictionary = operator.call("get_weapon_status")
		var loadout := str(ws.get("loadout_mode", "holstered")).to_upper()
		var profile := str(ws.get("profile", "STANDARD")).to_upper()
		debug_bus.set_stat("PLAYER", "Loadout", loadout)
		debug_bus.set_stat("PLAYER", "Profile", profile)
		debug_bus.set_stat("PLAYER", "Ammo STD/HVY", "%d / %d" % [int(ws.get("ammo_standard", 0)), int(ws.get("ammo_heavy", 0))])
		debug_bus.set_stat("PLAYER", "Cooldown", "%.2fs" % float(ws.get("cooldown_remaining", 0.0)))
		debug_bus.set_stat("PLAYER", "Blocking", "YES" if bool(ws.get("blocking", false)) else "NO")
	if operator.has_method("get_sprint_status"):
		var ss: Dictionary = operator.call("get_sprint_status")
		var stamina := float(ss.get("stamina", 0.0))
		var stamina_max: float = max(1.0, float(ss.get("stamina_max", 1.0)))
		debug_bus.set_stat("PLAYER", "Stamina", "%d%%" % int(round((stamina / stamina_max) * 100.0)))
		debug_bus.set_stat("PLAYER", "Sprint", "YES" if bool(ss.get("is_sprinting", false)) else "NO")


func _update_power_stats(debug_bus: Node) -> void:
	var power = get_node_or_null("/root/GameRoot/Power")
	if power == null or not power.has_method("get_power_status"):
		return
	var status: Dictionary = power.call("get_power_status")
	debug_bus.set_stat("POWER", "Stored", "%d / %d" % [int(status.get("total", 0)), int(status.get("max", 0))])
	debug_bus.set_stat("POWER", "Drain", "%.1f/s" % (float(status.get("consumed", 0.0)) * 60.0))


func _update_mission_stats(debug_bus: Node) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if game_state.has_method("get_phase_name"):
		debug_bus.set_stat("MISSION", "Phase", String(game_state.call("get_phase_name")).replace("_", " "))
	debug_bus.set_stat("MISSION", "Contract Ready", "YES" if bool(game_state.get("contract_ready")) else "NO")
	debug_bus.set_stat("MISSION", "Materials", int(game_state.get("materials")))
	debug_bus.set_stat("MISSION", "Defense Rating", "%.1f" % float(game_state.get("defense_rating")))
	if bool(game_state.get("game_over")):
		var reason := "YES"
		if "game_over_reason" in game_state:
			reason = str(game_state.get("game_over_reason"))
		debug_bus.set_stat("MISSION", "Game Over", reason)
	else:
		debug_bus.set_stat("MISSION", "Game Over", "NO")


func _update_camera_stats(debug_bus: Node) -> void:
	var camera = get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera == null:
		return
	debug_bus.set_stat("CAMERA", "Follow", "ON" if bool(camera.get("follow_enabled")) else "OFF")


func _update_director_stats(debug_bus: Node) -> void:
	var director = get_node_or_null("/root/GameRoot/EnemyDirector")
	if director == null or not director.has_method("get_director_status"):
		return
	var status: Dictionary = director.call("get_director_status")
	debug_bus.set_stat("DIRECTOR", "Threat", "%.1f" % float(status.get("threat", 0.0)))
	debug_bus.set_stat("DIRECTOR", "Lane", str(status.get("lane", "none")).to_upper())
	debug_bus.set_stat("DIRECTOR", "Objective", str(status.get("objective", "none")).to_upper())
	debug_bus.set_stat("DIRECTOR", "Budget", int(status.get("budget", 0)))


func _update_supply_stats(debug_bus: Node) -> void:
	var supply_manager = get_node_or_null("/root/GameRoot/SupplyDropManager")
	if supply_manager == null or not supply_manager.has_method("get_status"):
		return
	var status: Dictionary = supply_manager.call("get_status")
	debug_bus.set_stat("SUPPLY", "Active", "YES" if bool(status.get("active", false)) else "NO")
	debug_bus.set_stat("SUPPLY", "Queued", int(status.get("drops_queued", 0)))
	var next_drop: float = float(status.get("next_drop_in", -1.0))
	debug_bus.set_stat("SUPPLY", "Next Drop", "--" if next_drop < 0.0 else "%.1fs" % next_drop)

func _update_overlays(debug_bus: Node) -> void:
	var ranges: Array = []
	var targeting: Array = []
	var ai_states: Array = []

	for turret in get_tree().get_nodes_in_group("turret"):
		if not (turret is Node2D):
			continue
		ranges.append({
			"pos": turret.global_position,
			"radius": turret.range,
			"color": Color(1, 0.2, 0.2, 0.5),
		})
		if turret.target != null and is_instance_valid(turret.target):
			targeting.append({
				"from": turret.global_position,
				"to": turret.target.global_position,
				"color": Color(1.0, 0.85, 0.2, 0.7),
				"width": 2.0,
			})

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var color: Color = enemy.get("base_tint") if enemy.has_method("get") else Color(0.8, 0.2, 0.2, 1.0)
		if enemy.has_method("is_dead") and enemy.is_dead():
			color = Color(0.35, 0.35, 0.35, 0.7)
		ai_states.append({
			"pos": enemy.global_position,
			"radius": 6.0,
			"color": color,
		})

	debug_bus.set_overlay("ranges", ranges)
	debug_bus.set_overlay("targeting", targeting)
	debug_bus.set_overlay("ai_states", ai_states)

func _update_inspector(debug_bus: Node) -> void:
	var targets: Array = []
	if debug_bus.selected_entity != null:
		targets.append(debug_bus.selected_entity)
	if debug_bus.hovered_entity != null and debug_bus.hovered_entity != debug_bus.selected_entity:
		targets.append(debug_bus.hovered_entity)

	for target in targets:
		var data := _build_inspector_data(target)
		if not data.is_empty():
			debug_bus.set_inspector_data(target, data)

func _build_inspector_data(target: Object) -> Dictionary:
	if target is Turret:
		var turret := target as Turret
		var efficiency := turret.get_efficiency()
		var effective_fire_rate := turret.fire_rate * efficiency
		var cooldown := 0.0
		if effective_fire_rate > 0.01:
			cooldown = max(0.0, (1.0 / effective_fire_rate) - turret.fire_timer)
		return {
			"State": str(turret.turret_state),
			"Target": _entity_name(turret.target),
			"Range": "%.0f" % turret.range,
			"Cooldown": "%.2fs" % cooldown,
			"DPS": "%.1f" % (turret.damage * effective_fire_rate),
		}
	if target is EnemyScript:
		var enemy := target as EnemyScript
		var hp_text := "%.0f / %.0f" % [enemy.health, enemy.max_health]
		return {
			"HP": hp_text,
			"State": "Dead" if enemy.dead else "Active",
			"Target": _entity_name(enemy.target),
			"Speed": "%.1f" % enemy.speed,
		}
	return {}

func _entity_name(entity: Object) -> String:
	if entity == null:
		return "None"
	if entity is Node:
		return (entity as Node).name
	return str(entity)

func _get_node_child_count(path: NodePath) -> int:
	var node = get_node_or_null(path)
	if node == null:
		return 0
	return node.get_child_count()
