extends Node
class_name AmbientEnemySpawner

const CAMP_SCRIPT := preload("res://game/systems/spawning/ambient_enemy_camp.gd")
const GRUNT_ANIMATION_LIBRARY := preload(
	"res://game/enemies/procgen/grunt_animation_library.gd"
)
const GENERATED_CAMP_GROUP := &"generated_procgen_ambient_camp"
const CAMP_CREATED_META := &"ambient_enemy_camp_created"

@export var enemy_scene: PackedScene
@export var enemy_scenes: Array[PackedScene] = []
@export var enemy_container_path: NodePath = NodePath("/root/GameRoot/World/Enemies")
@export var marker_group: StringName = &"ambient_enemy_camp_marker"
@export var min_distance_from_player_start_px: float = 420.0
@export var min_camp_spacing_px: float = 700.0
@export var max_generated_camps: int = 3
@export var max_active_ambient_enemies: int = 12
@export_range(1, 8, 1) var enemies_per_camp_min: int = 2
@export_range(1, 8, 1) var enemies_per_camp_max: int = 2

var _spawn_queue: Array[Dictionary] = []
var _next_spawn_ordinal := 1
var _max_spawn_usec := 0
var _last_spawn_usec := 0
var _spawned_count := 0
var _prewarm_usec := 0


func _ready() -> void:
	add_to_group("ambient_enemy_spawn_scheduler")
	set_physics_process(true)
	_prewarm_grunt_animation_library()
	call_deferred("spawn_from_markers")


func _physics_process(_delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	var request := _spawn_queue.pop_front() as Dictionary
	_spawn_queued_enemy(request)


func queue_enemy_spawn(
	scene: PackedScene,
	parent: Node,
	spawn_position: Vector2,
	home_position: Vector2,
	camp_id: StringName,
	leash_radius_px: float,
	behavior_profile_id: StringName,
	completion: Callable
) -> void:
	_spawn_queue.append({
		"scene": scene,
		"parent": parent,
		"spawn_position": spawn_position,
		"home_position": home_position,
		"camp_id": camp_id,
		"leash_radius_px": leash_radius_px,
		"behavior_profile_id": behavior_profile_id,
		"completion": completion,
		"spawn_ordinal": _next_spawn_ordinal,
	})
	_next_spawn_ordinal += 1
	_obs_set_gauge("ambient_enemy_spawn_queue_depth", _spawn_queue.size())


func _spawn_queued_enemy(request: Dictionary) -> void:
	var started := Time.get_ticks_usec()
	var scene := request.get("scene") as PackedScene
	var parent := request.get("parent") as Node
	if scene == null or parent == null or not is_instance_valid(parent):
		return
	var requested_position := request.get("spawn_position", Vector2.ZERO) as Vector2
	var spawn_position := resolve_runtime_walkable_spawn(requested_position, 4)
	if spawn_position == Vector2.INF:
		_obs_increment("ambient_enemy_spawn_rejected_unwalkable")
		return
	if spawn_position.distance_squared_to(requested_position) > 1.0:
		_obs_increment("ambient_enemy_spawn_projected")
	var enemy := scene.instantiate() as Node2D
	if enemy == null or not parent is Node2D:
		return
	enemy.position = (parent as Node2D).to_local(spawn_position)
	enemy.set_meta("stable_spawn_ordinal", int(request.get("spawn_ordinal", 0)))
	parent.add_child(enemy)
	var completion := request.get("completion") as Callable
	if completion.is_valid():
		completion.call(enemy)
	var elapsed := Time.get_ticks_usec() - started
	_last_spawn_usec = elapsed
	_spawned_count += 1
	_max_spawn_usec = maxi(_max_spawn_usec, elapsed)
	_obs_increment("ambient_enemy_spawn_count")
	_obs_set_gauge("ambient_enemy_spawn_last_usec", elapsed)
	_obs_set_gauge(
		"ambient_enemy_spawn_max_usec",
		_max_spawn_usec
	)
	_obs_set_gauge("ambient_enemy_spawn_queue_depth", _spawn_queue.size())


func get_enemy_spawn_parent() -> Node2D:
	var container := get_node_or_null(enemy_container_path) as Node2D
	if container != null:
		return container
	return get_node_or_null("/root/GameRoot/World") as Node2D


func record_spawn_projection() -> void:
	_obs_increment("ambient_enemy_spawn_projected")


func record_spawn_rejection() -> void:
	_obs_increment("ambient_enemy_spawn_rejected_unwalkable")


func resolve_runtime_walkable_spawn(
	desired_position: Vector2,
	radius_tiles: int = 6
) -> Vector2:
	var best := Vector2.INF
	var best_distance_sq := INF
	var providers := get_tree().get_nodes_in_group("procgen_walkability_provider")
	for provider in providers:
		if provider == null or not provider.has_method("find_safe_runtime_walkable_global"):
			continue
		var candidate: Variant = provider.call(
			"find_safe_runtime_walkable_global", desired_position, radius_tiles
		)
		if not candidate is Vector2:
			continue
		var position := candidate as Vector2
		if position == Vector2.INF:
			continue
		var distance_sq := desired_position.distance_squared_to(position)
		if distance_sq < best_distance_sq:
			best = position
			best_distance_sq = distance_sq
	if best != Vector2.INF:
		return best
	if not providers.is_empty():
		return Vector2.INF
	var navigation := get_node_or_null("/root/GameRoot/NavigationSystem")
	if (
		navigation != null
		and navigation.has_method("is_in_walkable_area")
		and bool(navigation.call("is_in_walkable_area", desired_position))
	):
		return desired_position
	return Vector2.INF


func _prewarm_grunt_animation_library() -> void:
	var started := Time.get_ticks_usec()
	GRUNT_ANIMATION_LIBRARY.get_grunt_sprite_frames()
	GRUNT_ANIMATION_LIBRARY.get_grunt_fx_sprite_frames()
	var elapsed := Time.get_ticks_usec() - started
	_prewarm_usec = elapsed
	_obs_set_gauge("ambient_enemy_animation_prewarm_usec", elapsed)


func get_pending_spawn_count() -> int:
	return _spawn_queue.size()


func get_performance_snapshot() -> Dictionary:
	return {
		"spawn_count": _spawned_count,
		"spawn_last_usec": _last_spawn_usec,
		"spawn_max_usec": _max_spawn_usec,
		"prewarm_usec": _prewarm_usec,
		"queue_depth": _spawn_queue.size(),
	}


func _observatory() -> Node:
	return get_node_or_null("/root/DevObservatory")


func _obs_increment(counter_name: String) -> void:
	var observatory := _observatory()
	if observatory != null and observatory.has_method("increment"):
		observatory.call("increment", counter_name, 1)


func _obs_set_gauge(gauge_name: String, value: Variant) -> void:
	var observatory := _observatory()
	if observatory != null and observatory.has_method("set_gauge"):
		observatory.call("set_gauge", gauge_name, value)




func spawn_from_markers() -> int:
	if enemy_scene == null and enemy_scenes.is_empty():
		return 0

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var accepted: Array[Vector2] = []
	var created := 0

	for marker_variant in get_tree().get_nodes_in_group(marker_group):
		var marker := marker_variant as Node2D
		if marker == null or marker.is_queued_for_deletion():
			continue
		var is_planned := marker.has_meta("encounter_id")
		if not is_planned and created >= max_generated_camps:
			break

		# ContractWorldLoader and the deferred startup call may both request
		# marker processing. A marker may create exactly one generated camp.
		if bool(marker.get_meta(CAMP_CREATED_META, false)):
			_obs_increment("ambient_enemy_duplicate_marker_suppressed")
			continue
		if _marker_has_generated_camp(marker):
			marker.set_meta(CAMP_CREATED_META, true)
			_obs_increment("ambient_enemy_duplicate_marker_suppressed")
			continue

		var marker_position := marker.global_position
		if not is_planned and (
			player != null
			and marker_position.distance_to(player.global_position)
			< min_distance_from_player_start_px
		):
			continue

		var too_close := false
		for existing_position in accepted:
			if (
				marker_position.distance_to(existing_position)
				< min_camp_spacing_px
			):
				too_close = true
				break
		if too_close and not is_planned:
			continue

		var camp := CAMP_SCRIPT.new() as AmbientEnemyCamp
		camp.camp_id = StringName(marker.get_meta("camp_id", "generated_camp_%d" % created))
		camp.enemy_scene = enemy_scene
		camp.enemy_scenes = _available_enemy_scenes()
		camp.enemy_count_min = int(marker.get_meta("enemy_count_min", enemies_per_camp_min))
		camp.enemy_count_max = maxi(camp.enemy_count_min, int(marker.get_meta("enemy_count_max", enemies_per_camp_max)))
		camp.behavior_profile_id = StringName(marker.get_meta("behavior_profile_id", &"raider_grunt"))
		var tile_size := _resolve_runtime_tile_size(marker)
		camp.leash_radius_px = float(marker.get_meta("leash_radius_tiles", camp.leash_radius_px / tile_size.x)) * tile_size.x
		camp.spawn_radius_px = float(marker.get_meta("spawn_radius_tiles", camp.spawn_radius_px / tile_size.x)) * tile_size.x
		camp.activation_range_px = float(marker.get_meta("activation_range_tiles", camp.activation_range_px / tile_size.x)) * tile_size.x
		var home_tile_variant: Variant = marker.get_meta("home_tile") if marker.has_meta("home_tile") else null
		var anchor_tile_variant: Variant = marker.get_meta("camp_tile") if marker.has_meta("camp_tile") else null
		if home_tile_variant is Vector2i and anchor_tile_variant is Vector2i:
			camp.home_position_px = marker_position + Vector2((home_tile_variant as Vector2i) - (anchor_tile_variant as Vector2i)) * tile_size
		camp.position = Vector2.ZERO
		camp.add_to_group(GENERATED_CAMP_GROUP)

		marker.set_meta(CAMP_CREATED_META, true)
		marker.add_child(camp)

		accepted.append(marker_position)
		created += 1
	return created


func _available_enemy_scenes() -> Array[PackedScene]:
	var available: Array[PackedScene] = []
	for scene in enemy_scenes:
		if scene != null:
			available.append(scene)
	return available


func _resolve_runtime_tile_size(marker: Node) -> Vector2:
	var current := marker
	while current != null:
		if current.has_method("get_runtime_tile_size"):
			var size := current.call("get_runtime_tile_size") as Vector2
			if size.x > 0.0 and size.y > 0.0:
				return size
		current = current.get_parent()
	return Vector2(32.0, 32.0)


func _marker_has_generated_camp(marker: Node) -> bool:
	for child in marker.get_children():
		if child is Node and child.is_in_group(GENERATED_CAMP_GROUP):
			return true
	return false


func get_active_enemy_count() -> int:
	var total := 0
	for camp in get_tree().get_nodes_in_group("ambient_enemy_camp"):
		if camp.has_method("get_active_enemy_count"):
			total += int(camp.call("get_active_enemy_count"))
	return total
