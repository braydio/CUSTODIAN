extends SceneTree
const SPAWNER := preload("res://game/systems/spawning/ambient_enemy_spawner.gd")
const CRITTERS := preload("res://game/systems/core/systems/ambient_critter_manager.gd")
class Provider extends Node:
	var safe := Vector2(128, 96)
	func _ready() -> void: add_to_group("procgen_walkability_provider")
	func find_safe_runtime_walkable_global(_position: Vector2, _radius: int) -> Vector2: return safe
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var host := Node.new(); root.add_child(host)
	var provider := Provider.new(); host.add_child(provider)
	var spawner := SPAWNER.new(); host.add_child(spawner)
	var critters := CRITTERS.new(); host.add_child(critters)
	assert(spawner.resolve_runtime_walkable_spawn(Vector2.ZERO, 6) == provider.safe)
	assert(critters.call("_resolve_runtime_walkable_spawn", Vector2.ZERO, 8) == provider.safe)
	provider.safe = Vector2.INF
	assert(spawner.resolve_runtime_walkable_spawn(Vector2.ZERO, 6) == Vector2.INF)
	assert(critters.call("_resolve_runtime_walkable_spawn", Vector2.ZERO, 8) == Vector2.INF)
	print("ambient_actor_spawn_walkability_smoke: PASS"); host.free(); quit(0)
