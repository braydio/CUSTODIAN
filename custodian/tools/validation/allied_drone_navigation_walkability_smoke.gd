extends SceneTree

const PROCGEN := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const DRONE := preload("res://game/actors/allies/combat_drone.gd")

class NoPathNavigation extends Node:
	func get_path_to_target(_start: Vector2, _target: Vector2) -> PackedVector2Array:
		return PackedVector2Array()

func _init() -> void:
	var map := PROCGEN.new()
	map._generated_floor_cells = {Vector2i(2, 0): true, Vector2i(0, 2): true}
	assert(map.find_nearest_runtime_walkable_cell(Vector2i.ZERO, 2) == Vector2i(2, 0))
	assert(map.find_nearest_runtime_walkable_cell(Vector2i(20, 20), 2) == null)
	var drone := DRONE.new()
	drone._navigation_system = NoPathNavigation.new()
	drone._walkability_provider = map
	assert(drone._navigation_direction(Vector2(64, 0)) == Vector2.ZERO)
	var manager_source := FileAccess.get_file_as_string("res://game/systems/drone/drone_manager.gd")
	assert(manager_source.find("var spawn_position := _project_drone_position") >= 0)
	assert(manager_source.find("squad_state.register_drone") > manager_source.find("var spawn_position :="))
	print("allied_drone_navigation_walkability_smoke: PASS")
	drone._navigation_system.free()
	drone.free()
	map.free()
	quit(0)
