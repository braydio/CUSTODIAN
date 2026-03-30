extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()

@export var wave_interval: float = 45.0
@export var intra_wave_spawn_interval: float = 0.5
@export var spawn_burst_size: int = 2
@export var spawn_burst_pause: float = 6.0
@export var base_points: int = 5
@export var growth_per_wave: int = 3
@export var max_wave: int = 20
@export var initial_delay: float = 15.0
@export var max_alive_enemies: int = 60
@export var recovery_enemy_threshold: int = 0
@export var recovery_poll_interval: float = 2.0

@export var drone_scene: PackedScene
@export var fast_drone_scene: PackedScene
@export var heavy_drone_scene: PackedScene

@export var enemy_container_path: NodePath = NodePath("/root/GameRoot/World/Enemies")
@export var game_state_path: NodePath = NodePath("/root/GameState")

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
var _game_state: Node = null
var _burst_spawns_remaining: int = 0
var _waiting_for_recovery_clearance: bool = false

const ENEMY_COST := {
	"drone": 1,
	"fast": 2,
	"heavy": 4,
}

func _ready():
	_setup_timer()
	_refresh_spawn_nodes()
	_bind_game_state()
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
	wave_completed.emit(wave_number)
	if active:
		_waiting_for_recovery_clearance = true
		_arm_next_wave_timer()

func _choose_enemy_type(available_points: int) -> String:
	var options: Array[String] = []

	if available_points >= ENEMY_COST["drone"] and drone_scene != null:
		options.append("drone")
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

	if is_fallback_variant:
		_configure_enemy_variant(enemy, enemy_type)
	if not _forced_objective.is_empty() and "attack_objective" in enemy:
		enemy.set("attack_objective", _forced_objective)
	if enemy.has_method("apply_difficulty_modifiers"):
		enemy.apply_difficulty_modifiers(difficulty, difficulty)

	parent.add_child(enemy)
	return true

func set_external_wave_plan(composition: Array[String], lane: String = "", objective: String = "") -> void:
	_external_wave_queue.clear()
	for enemy_type in composition:
		_external_wave_queue.append(String(enemy_type))
	_forced_lane = lane.strip_edges().to_lower()
	_forced_objective = objective.strip_edges().to_lower()

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
		"heavy":
			return heavy_drone_scene if heavy_drone_scene != null else drone_scene
		_:
			return null

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
