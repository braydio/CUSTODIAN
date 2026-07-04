extends SceneTree

const FOLIAGE_SPAWNER_SCRIPT := preload("res://game/world/procgen/foliage/procgen_foliage_spawner.gd")

class TestHost:
	extends Node

	var region_tiles := {}

	func _tile_noise_hash(pos: Vector2i) -> int:
		var value := int(pos.x * 73856093) ^ int(pos.y * 19349663)
		return abs(value)

	func _tile_to_world_position(pos: Vector2i) -> Vector2:
		return Vector2(pos.x * 16 + 8, pos.y * 16 + 8)

	func _get_planet_profile_color(_key: String, fallback: Color) -> Color:
		return fallback

	func get_player_spawn() -> Vector2i:
		return Vector2i(-100, -100)

	func is_road_surface_tile(_tile: Vector2i) -> bool:
		return false

	func is_parking_zone_tile(_tile: Vector2i) -> bool:
		return false

	func is_indoor_tile(_tile: Vector2i) -> bool:
		return false

	func get_region_type_at_tile(tile: Vector2i) -> String:
		return String(get_region_data_at_tile(tile).get("region_type", "exterior"))

	func get_region_data_at_tile(tile: Vector2i) -> Dictionary:
		return region_tiles.get(tile, {"region_type": "exterior", "zone": "natural"})

	func _set_region_tile(tile: Vector2i, region_type: String, zone: String) -> void:
		region_tiles[tile] = {
			"region_type": region_type,
			"zone": zone,
		}


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "ProcgenFoliageSpawnerSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var host := TestHost.new()
	root.add_child(host)
	var foliage_parent := Node2D.new()
	foliage_parent.name = "FoliageLayer"
	root.add_child(foliage_parent)

	var foliage_nodes := {}
	var fruit_sprites: Array[Node2D] = []
	var generated_floor_cells := {
		Vector2i(10, 10): {},
		Vector2i(11, 10): {},
		Vector2i(12, 10): {},
	}
	var generated_wall_cells := {}
	var texture := _make_texture(Color(0.2, 0.8, 0.3, 1.0), Vector2i(32, 32))
	var fruit_texture := _make_texture(Color(0.9, 0.1, 0.1, 1.0), Vector2i(24, 24))

	var context := {
		"host": host,
		"map_size": Vector2i(32, 32),
		"foliage_parent": foliage_parent,
		"foliage_nodes": foliage_nodes,
		"fruit_sprites": fruit_sprites,
		"foliage_textures": [texture],
		"fruit_texture": fruit_texture,
		"generated_floor_cells": generated_floor_cells,
		"generated_wall_cells": generated_wall_cells,
		"region_tiles": host.region_tiles,
		"last_compound_buildings": [],
		"last_compound_rect": Rect2i(),
		"enable_streaming_reveal": false,
		"foliage_debug_logging": false,
		"foliage_density": 1.0,
		"foliage_compound_density_multiplier": 0.28,
		"foliage_indoor_clearance_tiles": 0,
		"foliage_min_wall_distance": 1,
		"foliage_spawn_clearance_radius": 0,
		"foliage_compound_building_clearance": 0,
		"foliage_jitter_amplitude": Vector2.ZERO,
		"foliage_behind_z_index": 1,
		"foliage_front_z_index": 3,
		"foliage_player_occlusion_radius": 80.0,
		"foliage_player_occlusion_softness": 12.0,
		"foliage_player_occlusion_alpha": 0.55,
		"foliage_tree_trunk_collision_size": Vector2(18, 12),
		"foliage_tree_trunk_collision_offset": Vector2(0, -6),
		"foliage_probabilistic_tree_collision": true,
		"foliage_tree_collision_density_radius": 1,
		"foliage_sparse_tree_collision_threshold": 0.08,
		"foliage_dense_tree_collision_threshold": 0.22,
		"foliage_dense_tree_collision_chance": 0.28,
		"intent_mark_foliage_cover": true,
		"enable_fruit_spawning": true,
		"fruit_spawn_chance_tree": 1.0,
		"fruit_spawn_chance_shrub": 1.0,
		"fruit_tiles_wide": 3,
		"fruit_tiles_high": 3,
		"tile_noise_hash": Callable(host, "_tile_noise_hash"),
		"tile_to_world_position": Callable(host, "_tile_to_world_position"),
		"get_planet_profile_color": Callable(host, "_get_planet_profile_color"),
		"get_player_spawn": Callable(host, "get_player_spawn"),
		"is_road_surface_tile": Callable(host, "is_road_surface_tile"),
		"is_parking_zone_tile": Callable(host, "is_parking_zone_tile"),
		"is_indoor_tile": Callable(host, "is_indoor_tile"),
		"get_region_type_at_tile": Callable(host, "get_region_type_at_tile"),
		"get_region_data_at_tile": Callable(host, "get_region_data_at_tile"),
		"set_region_tile": Callable(host, "_set_region_tile"),
	}

	var spawner = FOLIAGE_SPAWNER_SCRIPT.new()
	var result: Dictionary = spawner.generate(context)
	_assert_true(int(result.get("placed", 0)) == generated_floor_cells.size(), "generate should place one foliage sprite per valid floor tile")
	_assert_true(foliage_nodes.size() == generated_floor_cells.size(), "foliage_nodes should track placed sprites")
	_assert_true(fruit_sprites.size() == generated_floor_cells.size(), "fruit_sprites should track placed fruit")

	spawner.remove_at(context, Vector2i(10, 10))
	_assert_true(not foliage_nodes.has(Vector2i(10, 10)), "remove_at should erase the tile")

	spawner.clear(context)
	_assert_true(foliage_nodes.is_empty(), "clear should empty foliage_nodes")
	_assert_true(fruit_sprites.is_empty(), "clear should empty fruit_sprites")

	if _failed:
		push_error("procgen_foliage_spawner_smoke failed")
		quit(1)
		return
	print("procgen_foliage_spawner_smoke passed")
	quit()


func _make_texture(color: Color, size: Vector2i) -> Texture2D:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
