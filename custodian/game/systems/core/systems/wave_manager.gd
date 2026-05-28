extends Node
class_name WaveManager

const ENEMY_VARIANT_FACTORY_SCRIPT := preload("res://game/enemies/procgen/enemy_variant_factory.gd")

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()

@export var wave_interval: float = 45.0
@export var intra_wave_spawn_interval: float = 0.5
@export var spawn_burst_size: int = 3
@export var spawn_burst_pause: float = 6.0
@export var base_points: int = 7
@export var growth_per_wave: int = 4
@export var max_wave: int = 20
@export var initial_delay: float = 15.0
@export var max_alive_enemies: int = 80
@export var recovery_enemy_threshold: int = 0
@export var recovery_poll_interval: float = 2.0

@export var drone_scene: PackedScene
@export var fast_drone_scene: PackedScene
@export var heavy_drone_scene: PackedScene
@export var grunt_scene: PackedScene
@export var procedural_enemy_variants_enabled: bool = true
@export var debug_spawn_grunt_on_start: bool = false
@export var debug_start_grunt_offset: Vector2 = Vector2(96.0, 0.0)

@export var enemy_container_path: NodePath = NodePath("/root/GameRoot/World/Enemies")
@export var game_state_path: NodePath = NodePath("/root/GameState")
@export var operator_path: NodePath = NodePath("/root/GameRoot/World/Operator")

var wave_number: int = 0
var active: bool = false

var _timer: Timer
var _spawn_timer: Timer
var _spawn_nodes: Array[SpawnNode] = []
var _spawn_index: int = 0
var _composition_index: int = 0
var _wave_in_progress: bool = false
var _pending_spawns: Array[String] = []
var _external_wave_queue: Array[String] = []
var _forced_lane: String = ""
var _forced_objective: String = ""
var _forced_behavior_profile: StringName = &""
var _game_state: Node = null
var _burst_spawns_remaining: int = 0
var _waiting_for_recovery_clearance: bool = false

const ENEMY_COST := {
	"drone": 1,
	"grunt": 2,
	"fast": 2,
	"heavy": 4,
	"wolf": 2,
}

func _ready():
	_setup_timer()
	_refresh_spawn_nodes()
	_bind_game_state()
	_maybe_debug_spawn_grunt_on_start.call_deferred()
	print("[WaveManager] Initialized with %d spawn nodes" % _spawn_nodes.size())

func _bind_game_state() -> void:
	_game_state = get_node_or_null(game_state_path)
	if _game_state == null:
		return
	var callback := Callable(self, "_on_phase_changed")
	if not _game_state.is_connected("phase_changed", callback):
		_game_state.connect("phase_changed", callback)
	_sync_phase_state(_game_state.current_phase)

func _setup_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = max(0.1, wave_interval)
	_timer.autostart = false
	_timer.timeout.connect(_on_wave_timer_timeout)
	add_child(_timer)

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = max(0.05, intra_wave_spawn_interval)
	_spawn_timer.autostart = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

func _on_wave_timer_timeout() -> void:
	if _waiting_for_recovery_clearance:
		_arm_next_wave_timer()
		return
	start_next_wave()

func _on_phase_changed(_old_phase: int, new_phase: int) -> void:
	_sync_phase_state(new_phase)

func _sync_phase_state(phase: int) -> void:
	var assault_active := phase == GameState.Phase.ASSAULT_ACTIVE
	active = assault_active
	if assault_active:
		if _wave_in_progress:
			return
		if initial_delay > 0.0 and wave_number == 0:
			_timer.start(max(0.1, initial_delay))
		elif _timer.is_stopped():
			start_next_wave()
		return

	_timer.stop()
	_spawn_timer.stop()
	_pending_spawns.clear()
	_wave_in_progress = false
	_waiting_for_recovery_clearance = false
	_forced_lane = ""
	_forced_objective = ""
	_forced_behavior_profile = &""

func _refresh_spawn_nodes() -> void:
	_spawn_nodes.clear()
	for node in get_tree().get_nodes_in_group("enemy_spawn"):
		if node is SpawnNode and node.active:
			_spawn_nodes.append(node)
	_spawn_nodes.sort_custom(func(a: SpawnNode, b: SpawnNode) -> bool:
		return a.lane < b.lane
	)

func start_next_wave() -> void:
	if not active:
		return
	if _wave_in_progress:
		return
	if wave_number >= max_wave:
		print("[WaveManager] Max wave reached: %d" % max_wave)
		if _game_state != null:
			_game_state.complete_assault()
		all_waves_completed.emit()
		return

	_refresh_spawn_nodes()
	if _spawn_nodes.is_empty():
		push_warning("[WaveManager] No spawn nodes available")
		_timer.start()
		return

	wave_number += 1
	var points := _calculate_points()
	var difficulty := _calculate_difficulty()

	print("[WaveManager] Starting wave %d | points=%d difficulty=%.2f" % [wave_number, points, difficulty])
	wave_started.emit(wave_number)
	_wave_in_progress = true
	_prepare_wave_queue(points)
	_burst_spawns_remaining = min(spawn_burst_size, _pending_spawns.size())
	_waiting_for_recovery_clearance = false
	_spawn_next_from_queue(difficulty)
	if not _pending_spawns.is_empty():
		_schedule_next_spawn()
	else:
		_complete_wave()

func _calculate_points() -> int:
	return base_points + wave_number * growth_per_wave

func _calculate_difficulty() -> float:
	return 1.0 + wave_number * 0.20

func _prepare_wave_queue(points: int) -> void:
	_pending_spawns.clear()
	if not _external_wave_queue.is_empty():
		_pending_spawns.assign(_external_wave_queue)
		_external_wave_queue.clear()
		return

	var remaining_points := points
	while remaining_points > 0:
		var enemy_type := _choose_enemy_type(remaining_points)
		if enemy_type.is_empty():
			break
		_pending_spawns.append(enemy_type)
		remaining_points -= int(ENEMY_COST[enemy_type])

func _on_spawn_timer_timeout() -> void:
	var difficulty := _calculate_difficulty()
	_spawn_next_from_queue(difficulty)
	if _pending_spawns.is_empty():
		_spawn_timer.stop()
		_complete_wave()
	else:
		_schedule_next_spawn()

func _spawn_next_from_queue(difficulty: float) -> void:
	if _pending_spawns.is_empty():
		return
	if _is_at_alive_enemy_cap():
		return
	var enemy_type: String = str(_pending_spawns.pop_front())
	_spawn_enemy(enemy_type, difficulty)
	if _burst_spawns_remaining > 0:
		_burst_spawns_remaining -= 1

func _complete_wave() -> void:
	_wave_in_progress = false
	_forced_lane = ""
	_forced_objective = ""
	_forced_behavior_profile = &""
	wave_completed.emit(wave_number)
	if active:
		_waiting_for_recovery_clearance = true
		_arm_next_wave_timer()

func _choose_enemy_type(available_points: int) -> String:
	var options: Array[String] = []

	if available_points >= ENEMY_COST["drone"] and drone_scene != null:
		options.append("drone")
	if available_points >= ENEMY_COST["grunt"] and wave_number >= 2 and grunt_scene != null:
		options.append("grunt")
	if available_points >= ENEMY_COST["fast"] and wave_number >= 3 and fast_drone_scene != null:
		options.append("fast")
	if available_points >= ENEMY_COST["heavy"] and wave_number >= 6 and heavy_drone_scene != null:
		options.append("heavy")

	if options.is_empty():
		return ""

	var picked := options[_composition_index % options.size()]
	_composition_index += 1
	return picked

func _spawn_enemy(enemy_type: String, difficulty: float) -> bool:
	var parent = get_node_or_null(enemy_container_path)
	if parent == null:
		push_warning("[WaveManager] Enemy container missing at %s" % String(enemy_container_path))
		return false

	var packed_scene := _scene_for_enemy_type(enemy_type)
	if packed_scene == null:
		push_warning("[WaveManager] Enemy scene missing for type %s" % enemy_type)
		return false
	var is_fallback_variant := enemy_type != "drone" and packed_scene == drone_scene

	var lane_nodes := _spawn_nodes
	if not _forced_lane.is_empty():
		var filtered: Array[SpawnNode] = []
		for node in _spawn_nodes:
			if node.lane == _forced_lane:
				filtered.append(node)
		if not filtered.is_empty():
			lane_nodes = filtered

	var spawn_node := lane_nodes[_spawn_index % lane_nodes.size()]
	_spawn_index += 1

	var enemy := packed_scene.instantiate()
	if enemy == null:
		return false

	if enemy is Node2D:
		enemy.global_position = spawn_node.global_position

	var variant_profile: Resource = null
	if procedural_enemy_variants_enabled and enemy_type == "wolf":
		variant_profile = _build_enemy_variant_profile(enemy_type, spawn_node)

	if is_fallback_variant:
		_configure_enemy_variant(enemy, enemy_type)
	if not _forced_objective.is_empty() and "attack_objective" in enemy:
		enemy.set("attack_objective", _forced_objective)
	_apply_behavior_profile(enemy, enemy_type, _forced_behavior_profile)
	parent.add_child(enemy)
	if variant_profile != null and enemy.has_method("apply_variant"):
		enemy.call("apply_variant", variant_profile)
	elif enemy.has_method("apply_difficulty_modifiers"):
		enemy.apply_difficulty_modifiers(difficulty, difficulty)
	return true

func debug_spawn_enemy_type(enemy_type: String = "drone", spawn_position: Vector2 = Vector2.ZERO, difficulty: float = 1.0, behavior_profile: StringName = &"") -> bool:
	var parent = get_node_or_null(enemy_container_path)
	if parent == null:
		push_warning("[WaveManager] Enemy container missing at %s" % String(enemy_container_path))
		return false
	var normalized_type := enemy_type.strip_edges().to_lower()
	if normalized_type.is_empty():
		normalized_type = "drone"
	var packed_scene := _scene_for_enemy_type(normalized_type)
	if packed_scene == null:
		push_warning("[WaveManager] Enemy scene missing for debug type %s" % normalized_type)
		return false
	var enemy := packed_scene.instantiate()
	if enemy == null:
		return false
	if enemy is Node2D:
		(enemy as Node2D).global_position = spawn_position
	var is_fallback_variant := normalized_type != "drone" and packed_scene == drone_scene
	if is_fallback_variant:
		_configure_enemy_variant(enemy, normalized_type)
	_apply_behavior_profile(enemy, normalized_type, behavior_profile)
	parent.add_child(enemy)
	if normalized_type == "wolf" and procedural_enemy_variants_enabled and enemy.has_method("apply_variant"):
		var variant_profile := _build_debug_enemy_variant_profile(normalized_type)
		if variant_profile != null:
			enemy.call("apply_variant", variant_profile)
	elif enemy.has_method("apply_difficulty_modifiers"):
		enemy.apply_difficulty_modifiers(difficulty, difficulty)
	print("[WaveManager] Debug spawned %s at %s" % [normalized_type, spawn_position])
	return true

func set_external_wave_plan(composition: Array[String], lane: String = "", objective: String = "", behavior_profile: StringName = &"") -> void:
	_external_wave_queue.clear()
	for enemy_type in composition:
		_external_wave_queue.append(String(enemy_type))
	_forced_lane = lane.strip_edges().to_lower()
	_forced_objective = objective.strip_edges().to_lower()
	_forced_behavior_profile = behavior_profile

func get_wave_status() -> Dictionary:
	var next_wave_in := -1.0
	if _timer and not _timer.is_stopped():
		next_wave_in = _timer.time_left
	return {
		"wave_number": wave_number,
		"max_wave": max_wave,
		"active": active,
		"in_progress": _wave_in_progress,
		"alive_enemies": _count_alive_enemies(),
		"max_alive_enemies": max_alive_enemies,
		"pending_spawns": _pending_spawns.size(),
		"next_wave_in": next_wave_in,
		"forced_lane": _forced_lane,
		"forced_objective": _forced_objective,
		"forced_behavior_profile": String(_forced_behavior_profile),
		"contract_phase": _game_state.get_phase_name() if _game_state != null else "UNKNOWN",
	}


func _is_at_alive_enemy_cap() -> bool:
	if max_alive_enemies <= 0:
		return false
	return _count_alive_enemies() >= max_alive_enemies


func _count_alive_enemies() -> int:
	var alive := 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("counts_for_wave_cap") and not bool(enemy.call("counts_for_wave_cap")):
			continue
		if enemy.has_method("is_dead") and bool(enemy.call("is_dead")):
			continue
		if "dead" in enemy and bool(enemy.get("dead")):
			continue
		alive += 1
	return alive

func _scene_for_enemy_type(enemy_type: String) -> PackedScene:
	match enemy_type:
		"drone":
			return drone_scene
		"fast":
			return fast_drone_scene if fast_drone_scene != null else drone_scene
		"grunt":
			return grunt_scene if grunt_scene != null else drone_scene
		"heavy":
			return heavy_drone_scene if heavy_drone_scene != null else drone_scene
		"wolf":
			return drone_scene
		_:
			return null


func _apply_behavior_profile(enemy: Node, enemy_type: String, profile_id: StringName = &"") -> void:
	var chosen_profile := profile_id
	if chosen_profile == &"" and enemy_type == "grunt":
		chosen_profile = &"raider_grunt"
	if chosen_profile == &"":
		return
	if enemy.has_method("set_behavior_profile"):
		enemy.call("set_behavior_profile", chosen_profile)


func _maybe_debug_spawn_grunt_on_start() -> void:
	if not debug_spawn_grunt_on_start:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var operator := get_node_or_null(operator_path)
	if not (operator is Node2D):
		push_warning("[WaveManager] Debug grunt startup spawn skipped; operator missing at %s" % String(operator_path))
		return
	var spawn_position := (operator as Node2D).global_position + debug_start_grunt_offset
	debug_spawn_enemy_type("grunt", spawn_position, 1.0)


func _build_debug_enemy_variant_profile(enemy_type: String) -> Resource:
	var biome_id := _get_enemy_variant_biome_id()
	var context := {
		"wave_number": wave_number,
		"spawn_index": _spawn_index,
		"lane": "debug",
		"objective": "debug",
	}
	match enemy_type:
		"wolf":
			var factory = ENEMY_VARIANT_FACTORY_SCRIPT.new()
			return factory.call("build_wolf_variant", 9701, biome_id, 1, context)
		_:
			return null


func _build_enemy_variant_profile(enemy_type: String, spawn_node: SpawnNode) -> Resource:
	var seed := _stable_enemy_seed(enemy_type, spawn_node)
	var biome_id := _get_enemy_variant_biome_id()
	var threat_level := clampi(int(ceil(float(wave_number) / 4.0)), 1, 5)
	var context := {
		"wave_number": wave_number,
		"spawn_index": _spawn_index,
		"lane": spawn_node.lane,
		"objective": _forced_objective,
	}
	match enemy_type:
		"wolf":
			var factory = ENEMY_VARIANT_FACTORY_SCRIPT.new()
			return factory.call("build_wolf_variant", seed, biome_id, threat_level, context)
		_:
			return null


func _stable_enemy_seed(enemy_type: String, spawn_node: SpawnNode) -> int:
	var text := "%d:%d:%s:%s:%s" % [wave_number, _spawn_index, enemy_type, spawn_node.lane, _forced_objective]
	var value := 2166136261
	for index in range(text.length()):
		value = value ^ text.unicode_at(index)
		value = (value * 16777619) & 0x7fffffff
	return maxi(1, value)


func _get_enemy_variant_biome_id() -> String:
	var procgen := get_tree().get_first_node_in_group("procgen_tilemap")
	if procgen != null and procgen.has_method("get_planet_world_profile"):
		var profile_variant: Variant = procgen.call("get_planet_world_profile")
		if profile_variant is Dictionary:
			var profile := profile_variant as Dictionary
			var planet_key := String(profile.get("planet_key", ""))
			if planet_key.contains("forest") or float(profile.get("foliage_density", 0.0)) >= 0.16:
				return "forest_ruin"
			if planet_key.contains("void"):
				return "void_contaminated"
			return "industrial_ruin"
	return "default"

func _configure_enemy_variant(enemy: Node, enemy_type: String) -> void:
	match enemy_type:
		"fast":
			enemy.set("enemy_name", "FAST DRONE")
			enemy.set("speed", float(enemy.get("speed")) * 1.25)
			enemy.set("health", float(enemy.get("health")) * 0.80)
			enemy.set("max_health", float(enemy.get("max_health")) * 0.80)
			if enemy is Node2D:
				(enemy as Node2D).scale = Vector2(0.85, 0.85)
			if enemy.has_node("Visual"):
				enemy.get_node("Visual").modulate = Color(0.9, 0.9, 0.2, 1.0)
		"heavy":
			enemy.set("enemy_name", "HEAVY DRONE")
			enemy.set("speed", float(enemy.get("speed")) * 0.75)
			enemy.set("health", float(enemy.get("health")) * 1.80)
			enemy.set("max_health", float(enemy.get("max_health")) * 1.80)
			enemy.set("damage", float(enemy.get("damage")) * 1.35)
			if enemy is Node2D:
				(enemy as Node2D).scale = Vector2(1.25, 1.25)
			if enemy.has_node("Visual"):
				enemy.get_node("Visual").modulate = Color(0.3, 0.3, 0.9, 1.0)
		_:
			pass


func _schedule_next_spawn() -> void:
	if _pending_spawns.is_empty():
		return
	if _burst_spawns_remaining <= 0:
		_burst_spawns_remaining = min(spawn_burst_size, _pending_spawns.size())
		_spawn_timer.start(max(0.1, spawn_burst_pause))
		return
	_spawn_timer.start(max(0.05, intra_wave_spawn_interval))


func _arm_next_wave_timer() -> void:
	if not active:
		return
	if _count_alive_enemies() > recovery_enemy_threshold:
		_timer.start(max(0.1, recovery_poll_interval))
		return
	_waiting_for_recovery_clearance = false
	_timer.start(max(0.1, wave_interval))
