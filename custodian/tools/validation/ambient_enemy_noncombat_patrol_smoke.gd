extends SceneTree

const SPAWNER := preload("res://game/systems/spawning/ambient_enemy_spawner.gd")
const GRUNT := preload("res://game/actors/enemies/enemy_grunt.tscn")

class Provider extends Node:
	func _ready() -> void: add_to_group("procgen_walkability_provider")
	func find_safe_runtime_walkable_global(position: Vector2, _radius: int) -> Vector2: return position

func _init() -> void: call_deferred("_run")
func _run() -> void:
	var host := Node2D.new(); root.add_child(host); host.add_child(Provider.new())
	var spawner := SPAWNER.new(); host.add_child(spawner); spawner.set_physics_process(false)
	var spawned: Array[Node2D] = []
	spawner.queue_enemy_spawn(GRUNT, host, Vector2(64, 64), Vector2(64, 64), &"patrol", 160.0, &"raider_grunt", func(enemy: Node2D): spawned.append(enemy))
	spawner.call("_physics_process", 0.016); await process_frame
	assert(spawned.size() == 1)
	var grunt := spawned[0]; assert(bool(grunt.get("behavior_state_machine_enabled")))
	var machine := grunt.get_node("EnemyBehaviorStateMachine") as EnemyBehaviorStateMachine
	machine.setup_ambient_home(grunt.global_position, &"patrol", 160.0)
	machine.call("_consider_objective_candidate", {})
	assert(machine.current_state in [EnemyBehaviorStateMachine.PATROL, EnemyBehaviorStateMachine.AMBIENT_ACTIVITY])
	grunt.set("use_pathfinding", false)
	var start := grunt.global_position; machine._patrol_target = start + Vector2(48, 0); machine.call("_update_patrol", grunt, 0.1)
	assert(grunt.global_position != start)
	assert(grunt.global_position.distance_to(start) <= 160.0)
	var source := FileAccess.get_file_as_string("res://game/actors/enemies/enemy.gd")
	assert(source.count("if current_path.is_empty():\n\t\treturn Vector2.ZERO") >= 2)
	print("ambient_enemy_noncombat_patrol_smoke: PASS"); quit(0)
