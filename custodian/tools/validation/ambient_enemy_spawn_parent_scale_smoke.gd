extends SceneTree
const SPAWNER := preload("res://game/systems/spawning/ambient_enemy_spawner.gd")
const GRUNT := preload("res://game/actors/enemies/enemy_grunt.tscn")
class Provider extends Node:
	func _ready() -> void: add_to_group("procgen_walkability_provider")
	func find_safe_runtime_walkable_global(position: Vector2, _radius: int) -> Vector2: return position
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var game_root := Node.new(); game_root.name = "GameRoot"; root.add_child(game_root)
	var world := Node2D.new(); world.name = "World"; game_root.add_child(world)
	var enemies := Node2D.new(); enemies.name = "Enemies"; world.add_child(enemies)
	var procgen := Node2D.new(); procgen.scale = Vector2(2, 2); world.add_child(procgen); world.add_child(Provider.new())
	var spawner := SPAWNER.new(); world.add_child(spawner); spawner.set_physics_process(false)
	assert(spawner.get_enemy_spawn_parent() == enemies)
	spawner.queue_enemy_spawn(GRUNT, enemies, Vector2(80, 64), Vector2.ZERO, &"test", 100.0, &"raider_grunt", Callable())
	spawner.call("_physics_process", 0.016)
	var spawned := enemies.get_child(0) as Node2D
	assert(spawned.global_scale.is_equal_approx(Vector2.ONE)); assert(spawned.global_position.is_equal_approx(Vector2(80, 64)))
	var direct := GRUNT.instantiate() as Node2D; enemies.add_child(direct)
	assert(spawned.get_node("CollisionShape2D").shape.get_rect().size == direct.get_node("CollisionShape2D").shape.get_rect().size)
	assert((spawned.get_node("AnimatedSprite2D") as AnimatedSprite2D).scale == (direct.get_node("AnimatedSprite2D") as AnimatedSprite2D).scale)
	print("ambient_enemy_spawn_parent_scale_smoke: PASS"); game_root.free(); quit(0)
