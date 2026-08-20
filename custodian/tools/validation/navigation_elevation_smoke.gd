extends SceneTree

const NAV := preload("res://game/systems/core/systems/navigation_system.gd")

class TraversalProvider extends Node:
	var allowed: Dictionary = {}
	func can_actor_move_between_tiles(from_cell: Vector2i, to_cell: Vector2i) -> bool:
		return bool(allowed.get([from_cell, to_cell], false))

func _init() -> void:
	var nav := NAV.new()
	var provider := TraversalProvider.new()
	nav.runtime_blocker_provider = provider
	for cell in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]: nav._walkable_tiles[cell] = true
	provider.allowed[[Vector2i(0, 0), Vector2i(1, 0)]] = true
	provider.allowed[[Vector2i(1, 0), Vector2i(0, 0)]] = true
	provider.allowed[[Vector2i(1, 0), Vector2i(2, 0)]] = true
	assert(nav._can_traverse_edge(Vector2i(0, 0), Vector2i(1, 0)))
	assert(nav._can_traverse_edge(Vector2i(1, 0), Vector2i(2, 0)))
	assert(not nav._can_traverse_edge(Vector2i(2, 0), Vector2i(1, 0)))
	assert(not nav._can_traverse_raster_step(Vector2i(2, 0), Vector2i(1, 0), 0))
	nav._initialized = true; nav.astar = AStar2D.new(); nav.floor_tilemap = TileMapLayer.new(); nav.floor_tilemap.tile_set = TileSet.new()
	assert(nav.compute_path_immediate(Vector2.ZERO, Vector2(64, 0)).is_empty())
	var enemy_source := FileAccess.get_file_as_string("res://game/actors/enemies/enemy.gd")
	assert(enemy_source.count("if current_path.is_empty():\n\t\treturn Vector2.ZERO") >= 2)
	print("navigation_elevation_smoke: PASS")
	nav.floor_tilemap.free()
	nav.free()
	provider.free()
	quit(0)
