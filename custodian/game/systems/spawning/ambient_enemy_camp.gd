extends Node2D
class_name AmbientEnemyCamp

@export var camp_id: StringName = &"camp"
@export var enemy_scene: PackedScene
@export var enemy_count_min: int = 2
@export var enemy_count_max: int = 4
@export var spawn_radius_px: float = 96.0
@export var leash_radius_px: float = 700.0
@export var activation_range_px: float = 1200.0
@export var initially_active: bool = true
@export var respawn_enabled: bool = false
@export var faction_id: StringName = &"hostile"
@export var behavior_profile_id: StringName = &"raider_grunt"

var _spawned := false
var _spawned_enemies: Array[Node] = []


func _ready() -> void:
	add_to_group("ambient_enemy_camp")
	set_process(initially_active)


func _process(_delta: float) -> void:
	_prune_enemies()
	if _spawned and (not respawn_enabled or not _spawned_enemies.is_empty()):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_to(player.global_position) > activation_range_px:
		return
	spawn_camp()


func spawn_camp() -> void:
	if enemy_scene == null:
		return
	var count_range := maxi(0, enemy_count_max - enemy_count_min)
	var stable_offset := int((String(camp_id).hash() & 0x7fffffff) % (count_range + 1)) if count_range > 0 else 0
	var count := maxi(0, enemy_count_min + stable_offset)
	var parent := get_parent()
	for index in count:
		var enemy := enemy_scene.instantiate() as Node2D
		if enemy == null:
			continue
		parent.add_child(enemy)
		var angle := TAU * float(index) / float(maxi(1, count))
		var radius := spawn_radius_px * (0.55 + 0.45 * float((index % 3) + 1) / 3.0)
		enemy.global_position = global_position + Vector2.RIGHT.rotated(angle) * radius
		var behavior := enemy.get_node_or_null("EnemyBehaviorStateMachine")
		if behavior != null:
			if behavior.has_method("setup_profile"):
				behavior.call("setup_profile", behavior_profile_id)
			if behavior.has_method("setup_ambient_home"):
				behavior.call("setup_ambient_home", global_position, camp_id, leash_radius_px)
		_spawned_enemies.append(enemy)
	_spawned = true


func _prune_enemies() -> void:
	for index in range(_spawned_enemies.size() - 1, -1, -1):
		if not is_instance_valid(_spawned_enemies[index]):
			_spawned_enemies.remove_at(index)


func get_active_enemy_count() -> int:
	_prune_enemies()
	return _spawned_enemies.size()
