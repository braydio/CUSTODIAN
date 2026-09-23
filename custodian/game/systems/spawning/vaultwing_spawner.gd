extends Node
class_name VaultwingSpawner

## Focused deterministic population authority for wild Vaultwings. This keeps
## hostile aerial fauna out of the passive AmbientCritterManager and generic
## ambient enemy camp lifecycle.

const VAULTWING_SCENE := preload("res://game/actors/ambient/vaultwing/vaultwing.tscn")

@export var vaultwing_scene: PackedScene = VAULTWING_SCENE
@export var vaultwing_container_path := NodePath("/root/GameRoot/World/Ambient")
@export var max_active_vaultwings := 2
@export var min_distance_from_player_start_px := 520.0
@export var seed_value := 1
@export var perch_group: StringName = &"vaultwing_perch"

var _spawned: Array[Node] = []

func _ready() -> void:
	add_to_group("vaultwing_spawn_scheduler")
	call_deferred("spawn_from_markers")


func spawn_from_markers() -> int:
	if vaultwing_scene == null or max_active_vaultwings <= 0:
		return 0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var markers := get_tree().get_nodes_in_group("vaultwing_spawn_marker")
	markers.sort_custom(_sort_nodes_by_position)
	var created := 0
	for marker_variant in markers:
		if created >= max_active_vaultwings:
			break
		var marker := marker_variant as Node2D
		if marker == null or marker.is_queued_for_deletion():
			continue
		if bool(marker.get_meta("vaultwing_spawned", false)):
			continue
		if player != null and marker.global_position.distance_to(player.global_position) < min_distance_from_player_start_px:
			continue
		if spawn_at(marker.global_position, seed_value + created):
			marker.set_meta("vaultwing_spawned", true)
			created += 1
	_obs_set_gauge("active_vaultwings", _active_count())
	return created


func spawn_at(spawn_position: Vector2, creature_seed: int = seed_value) -> Vaultwing:
	if vaultwing_scene == null or _active_count() >= max_active_vaultwings:
		return null
	var parent := get_node_or_null(vaultwing_container_path)
	if parent == null:
		parent = get_parent()
	var creature := vaultwing_scene.instantiate() as Vaultwing
	if creature == null:
		return null
	parent.add_child(creature)
	creature.global_position = spawn_position
	creature.set_ambient_seed(creature_seed)
	creature.set_home_position(spawn_position)
	creature.set_perch_positions(_perch_positions())
	_spawned.append(creature)
	_log_event(&"vaultwing_spawned", {"seed": creature_seed, "position": spawn_position})
	_obs_set_gauge("active_vaultwings", _spawned.size())
	return creature


func get_active_count() -> int:
	_prune_spawned()
	return _spawned.size()


func reset_for_world() -> void:
	despawn_all("world_reset")
	for marker_variant in get_tree().get_nodes_in_group("vaultwing_spawn_marker"):
		var marker := marker_variant as Node
		if marker != null and marker.has_meta("vaultwing_spawned"):
			marker.set_meta("vaultwing_spawned", false)

func despawn_all(reason: String = "explicit_cleanup") -> void:
	for creature in _spawned:
		if is_instance_valid(creature):
			_log_event(&"vaultwing_despawned", {"reason": reason, "position": creature.global_position})
			creature.queue_free()
	_spawned.clear()
	_obs_set_gauge("active_vaultwings", 0)


func _active_count() -> int:
	_prune_spawned()
	return _spawned.size()


func _prune_spawned() -> void:
	_spawned = _spawned.filter(func(creature: Node) -> bool:
		if not is_instance_valid(creature) or creature.is_queued_for_deletion():
			_log_event(&"vaultwing_despawned", {"reason": "runtime_removal"})
			return false
		return true
	)
	_obs_set_gauge("active_vaultwings", _spawned.size())


func _perch_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var markers := get_tree().get_nodes_in_group(perch_group)
	markers.sort_custom(_sort_nodes_by_position)
	for marker_variant in markers:
		var marker := marker_variant as Node2D
		if marker != null and not marker.is_queued_for_deletion():
			positions.append(marker.global_position)
	return positions


func _sort_nodes_by_position(a: Node, b: Node) -> bool:
	var a_2d := a as Node2D
	var b_2d := b as Node2D
	if a_2d == null or b_2d == null:
		return str(a.get_path()) < str(b.get_path())
	if not is_equal_approx(a_2d.global_position.x, b_2d.global_position.x):
		return a_2d.global_position.x < b_2d.global_position.x
	return a_2d.global_position.y < b_2d.global_position.y


func _log_event(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)

func _obs_set_gauge(gauge_name: String, value: Variant) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("set_gauge"):
		observatory.call("set_gauge", gauge_name, value)
