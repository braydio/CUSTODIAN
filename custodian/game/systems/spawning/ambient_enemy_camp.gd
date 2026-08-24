extends Node2D
class_name AmbientEnemyCamp

@export var camp_id: StringName = &"camp"
@export var enemy_scene: PackedScene
@export var enemy_count_min: int = 2
@export var enemy_count_max: int = 4
@export var spawn_radius_px: float = 96.0
@export var leash_radius_px: float = 700.0
@export var activation_range_px: float = 650.0
@export var initially_active: bool = true
@export var respawn_enabled: bool = false
@export var faction_id: StringName = &"hostile"
@export var behavior_profile_id: StringName = &"raider_grunt"
var home_position_px: Vector2 = Vector2.INF

var _spawned := false
var _spawned_enemies: Array[Node] = []
var _planned_count := -1
var _queued_or_spawned_count := 0


func _ready() -> void:
	add_to_group("ambient_enemy_camp")
	set_process(initially_active)


func _process(_delta: float) -> void:
	_prune_enemies()
	if _spawned and (not respawn_enabled or not _spawned_enemies.is_empty()):
		return
	if _spawned and respawn_enabled and _spawned_enemies.is_empty():
		_spawned = false
		_queued_or_spawned_count = 0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_to(player.global_position) > activation_range_px:
		return
	spawn_camp()


func spawn_camp() -> void:
	if enemy_scene == null:
		return
	if _planned_count < 0:
		var count_range := maxi(0, enemy_count_max - enemy_count_min)
		var stable_offset := int((String(camp_id).hash() & 0x7fffffff) % (count_range + 1)) if count_range > 0 else 0
		_planned_count = maxi(0, enemy_count_min + stable_offset)
	var count := maxi(0, _planned_count - _queued_or_spawned_count)
	var spawner := get_tree().get_first_node_in_group(
		"ambient_enemy_spawn_scheduler"
	)
	var parent: Node2D = null
	if spawner != null and spawner.has_method("get_enemy_spawn_parent"):
		parent = spawner.call("get_enemy_spawn_parent") as Node2D
	if parent == null:
		parent = get_node_or_null("/root/GameRoot/World/Enemies") as Node2D
	if parent == null:
		parent = get_node_or_null("/root/GameRoot/World") as Node2D
	if parent == null:
		push_warning("AmbientEnemyCamp: no neutral world actor parent; camp spawn aborted")
		return
	if spawner != null:
		var cap := int(spawner.get("max_active_ambient_enemies"))
		var active := int(spawner.call("get_active_enemy_count")) \
			if spawner.has_method("get_active_enemy_count") else 0
		var pending := int(spawner.call("get_pending_spawn_count")) \
			if spawner.has_method("get_pending_spawn_count") else 0
		count = mini(count, maxi(0, cap - active - pending))
	if count <= 0:
		return
	var resolved_positions: Array[Vector2] = []
	for local_index in count:
		var index := _queued_or_spawned_count + local_index
		var angle := TAU * float(index) / float(maxi(1, _planned_count))
		var radius := spawn_radius_px * (0.55 + 0.45 * float((index % 3) + 1) / 3.0)
		var desired_spawn_position := (
			global_position
			+ Vector2.RIGHT.rotated(angle) * radius
		)
		var spawn_position := Vector2.INF
		if spawner != null and spawner.has_method("resolve_runtime_walkable_spawn"):
			spawn_position = spawner.call(
				"resolve_runtime_walkable_spawn", desired_spawn_position, 6
			)
		if spawn_position == Vector2.INF:
			if spawner != null and spawner.has_method("record_spawn_rejection"):
				spawner.call("record_spawn_rejection")
			continue
		if (
			spawn_position.distance_squared_to(desired_spawn_position) > 1.0
			and spawner != null
			and spawner.has_method("record_spawn_projection")
		):
			spawner.call("record_spawn_projection")
		var separated := spawn_position != Vector2.INF
		for existing_position in resolved_positions:
			if spawn_position.distance_squared_to(existing_position) < 28.0 * 28.0:
				separated = false
				break
		if not separated:
			if spawner != null and spawner.has_method("record_spawn_rejection"):
				spawner.call("record_spawn_rejection")
			continue
		resolved_positions.append(spawn_position)
		if spawner != null and spawner.has_method("queue_enemy_spawn"):
			spawner.call(
				"queue_enemy_spawn",
				enemy_scene,
				parent,
				spawn_position,
				global_position,
				camp_id,
				leash_radius_px,
				behavior_profile_id,
				Callable(self, "_on_enemy_spawned")
			)
		else:
			push_warning("AmbientEnemyCamp: spawn scheduler unavailable; camp slot rejected")
	_queued_or_spawned_count += count
	_spawned = _queued_or_spawned_count >= _planned_count
	if _spawned:
		set_process(false)


func _spawn_enemy_immediately(parent: Node, spawn_position: Vector2) -> void:
	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null or not parent is Node2D:
		return
	# Set the transform before add_child() so _ready() captures the real home.
	enemy.position = (parent as Node2D).to_local(spawn_position)
	parent.add_child(enemy)
	_configure_spawned_enemy(enemy)


func _on_enemy_spawned(enemy: Node2D) -> void:
	_configure_spawned_enemy(enemy)


func _configure_spawned_enemy(enemy: Node2D) -> void:
	if enemy == null:
		return
	var behavior := enemy.get_node_or_null("EnemyBehaviorStateMachine")
	if behavior != null:
		if behavior.has_method("setup_profile"):
			behavior.call("setup_profile", behavior_profile_id)
		if behavior.has_method("setup_ambient_home"):
			behavior.call(
				"setup_ambient_home",
				global_position if home_position_px == Vector2.INF else home_position_px,
				camp_id,
				leash_radius_px
			)
	_spawned_enemies.append(enemy)


func _prune_enemies() -> void:
	for index in range(_spawned_enemies.size() - 1, -1, -1):
		if not is_instance_valid(_spawned_enemies[index]):
			_spawned_enemies.remove_at(index)


func get_active_enemy_count() -> int:
	_prune_enemies()
	return _spawned_enemies.size()
