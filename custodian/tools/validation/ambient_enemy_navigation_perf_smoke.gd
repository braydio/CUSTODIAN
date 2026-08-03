extends SceneTree

const AMBIENT_SPAWNER_SCRIPT := preload(
	"res://game/systems/spawning/ambient_enemy_spawner.gd"
)
const NAVIGATION_SYSTEM_SCRIPT := preload(
	"res://game/systems/core/systems/navigation_system.gd"
)
const SPATIAL_INDEX_SCRIPT := preload(
	"res://game/systems/simulation/enemy_spatial_index.gd"
)

var _path_callback_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_root := Node2D.new()
	test_root.name = "AmbientEnemyNavigationPerfSmoke"
	root.add_child(test_root)

	var enemy_template := Node2D.new()
	var enemy_scene := PackedScene.new()
	assert(enemy_scene.pack(enemy_template) == OK)
	enemy_template.free()

	var spawner := AMBIENT_SPAWNER_SCRIPT.new() as AmbientEnemySpawner
	spawner.enemy_scene = enemy_scene
	test_root.add_child(spawner)
	spawner.set_physics_process(false)
	var spawn_positions := [
		Vector2(100.0, 200.0),
		Vector2(140.0, 200.0),
		Vector2(180.0, 200.0),
		Vector2(220.0, 200.0),
	]
	for index in spawn_positions.size():
		spawner.queue_enemy_spawn(
			enemy_scene,
			test_root,
			spawn_positions[index],
			Vector2.ZERO,
			&"perf_camp",
			700.0,
			&"raider_grunt",
			Callable()
		)
	assert(spawner.get_pending_spawn_count() == 4)

	var frame_durations_usec: Array[int] = []
	for expected_spawn_count in range(1, 5):
		var frame_started := Time.get_ticks_usec()
		spawner.call("_physics_process", 1.0 / 60.0)
		frame_durations_usec.append(Time.get_ticks_usec() - frame_started)
		var spawn_snapshot := spawner.get_performance_snapshot()
		assert(int(spawn_snapshot["spawn_count"]) == expected_spawn_count)
		assert(
			int(spawn_snapshot["queue_depth"])
			== 4 - expected_spawn_count
		)
	var spawned_nodes := test_root.get_children().filter(
		func(child: Node) -> bool:
			return child != spawner
	)
	assert(spawned_nodes.size() == 4)
	for index in spawned_nodes.size():
		assert(
			(spawned_nodes[index] as Node2D).global_position
			== spawn_positions[index]
		)

	var navigation := NAVIGATION_SYSTEM_SCRIPT.new() as NavigationSystem
	test_root.add_child(navigation)
	navigation.enemy_navigation_broker.set_physics_process(false)
	var requesters: Array[Node] = []
	for index in 4:
		var requester := Node.new()
		requester.name = "PathRequester_%d" % index
		test_root.add_child(requester)
		requesters.append(requester)
		assert(navigation.request_enemy_path(
			requester,
			Vector2.ZERO,
			Vector2(64.0, 64.0),
			Callable(self, "_on_path_ready")
		))
	navigation.enemy_navigation_broker.call("_physics_process", 1.0 / 60.0)
	assert(_path_callback_count == 2)
	navigation.enemy_navigation_broker.call("_physics_process", 1.0 / 60.0)
	assert(_path_callback_count == 4)
	var nav_snapshot := (
		navigation.enemy_navigation_broker.get_performance_snapshot()
	)
	assert(int(nav_snapshot["query_count"]) == 4)
	assert(int(nav_snapshot["queue_depth"]) == 0)

	var spatial_index := SPATIAL_INDEX_SCRIPT.new() as EnemySpatialIndex
	spatial_index.refresh_interval_sec = 0.05
	test_root.add_child(spatial_index)
	spatial_index.set_physics_process(false)
	for index in spawned_nodes.size():
		var actor := spawned_nodes[index] as Node2D
		actor.add_to_group("enemy")
		actor.set_meta("stable_spawn_ordinal", index + 1)
	spatial_index.call("_rebuild")
	var nearby := spatial_index.get_nearby_enemies(Vector2(100.0, 200.0))
	assert(not nearby.is_empty())
	assert(nearby.size() <= spawned_nodes.size())

	var spawn_snapshot := spawner.get_performance_snapshot()
	print(
		(
			"ambient_enemy_navigation_perf_smoke: PASS "
			+ "spawn_total=%d spawn_max_usec=%d prewarm_usec=%d "
			+ "astar_queries=%d astar_total_usec=%d "
			+ "astar_max_usec=%d max_test_frame_usec=%d"
		)
		% [
			int(spawn_snapshot["spawn_count"]),
			int(spawn_snapshot["spawn_max_usec"]),
			int(spawn_snapshot["prewarm_usec"]),
			int(nav_snapshot["query_count"]),
			int(nav_snapshot["query_total_usec"]),
			int(nav_snapshot["query_max_usec"]),
			frame_durations_usec.max(),
		]
	)
	test_root.queue_free()
	quit(0)


func _on_path_ready(
	_path: PackedVector2Array,
	_target: Vector2
) -> void:
	_path_callback_count += 1
