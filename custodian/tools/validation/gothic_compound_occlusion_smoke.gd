extends SceneTree

const CONTEXT_SCRIPT := preload("res://game/world/procgen/gothic_compound/gothic_compound_sprite_context.gd")
const ASSET_DEFS_SCRIPT := preload("res://game/world/procgen/gothic_compound/gothic_compound_asset_defs.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var context := CONTEXT_SCRIPT.new()
	context.name = "OcclusionSmokeContext"
	root.add_child(context)
	await process_frame

	var tile := Vector2i(10, 10)
	var wall := context.spawn_asset(tile, ASSET_DEFS_SCRIPT.get_asset("wall_pillar"))
	assert(wall != null, "Expected wall pillar to spawn.")
	assert(wall.get_parent().name == "DepthSortLayer", "Wall pillar should use the dynamic depth-sort layer.")
	assert(wall.position == context.grid_to_world(tile) + Vector2(0.0, 32.0), "Wall pillar root should sit at its base/sort line.")
	assert((wall.get_node("Visual") as Sprite2D).position == Vector2(0.0, -32.0), "Wall visual should be offset above the base root.")
	assert(wall.get_node_or_null("Collision") != null, "Wall collision should remain on the root footprint.")

	var operator := Node2D.new()
	root.add_child(operator)

	operator.global_position = wall.global_position + Vector2(0.0, 8.0)
	context.update_depth_sort(operator)
	assert(wall.z_index == 1, "Wall should draw behind the operator when operator feet are below its base.")

	operator.global_position = wall.global_position + Vector2(0.0, -8.0)
	context.update_depth_sort(operator)
	assert(wall.z_index == 10, "Wall should draw in front of the operator when operator feet are above its base.")

	var gate_cell := Vector2i(20, 20)
	var gate := context.spawn_asset(gate_cell, ASSET_DEFS_SCRIPT.get_asset("gatehouse_open"))
	assert(gate != null, "Expected gatehouse to spawn.")
	assert(gate.get_parent().name == "DepthSortLayer", "Gatehouse should use the dynamic depth-sort layer.")
	assert(gate.position == context.grid_to_world(gate_cell) + Vector2(0.0, 160.0), "Gatehouse root should sit at its footprint base.")
	assert((gate.get_node("Visual") as Sprite2D).position == Vector2(0.0, -160.0), "Gatehouse visual should be offset from base root.")

	operator.global_position = gate.global_position + Vector2(0.0, 8.0)
	context.update_depth_sort(operator)
	assert(gate.z_index == 1, "Gatehouse should draw behind the operator when operator feet are below its base.")

	operator.global_position = gate.global_position + Vector2(0.0, -8.0)
	context.update_depth_sort(operator)
	assert(gate.z_index == 40, "Gatehouse should draw in front of the operator when operator feet are above its base.")

	var floor_node := context.spawn_asset(Vector2i(2, 2), ASSET_DEFS_SCRIPT.get_asset("terrain_stone_a"))
	var road_node := context.spawn_asset(Vector2i(3, 2), ASSET_DEFS_SCRIPT.get_asset("road_ns_a"))
	var road_stamp_node := context.spawn_asset(Vector2i(4, 2), ASSET_DEFS_SCRIPT.get_asset("road_ew_long"))
	var decal_node := context.spawn_asset(Vector2i(5, 2), ASSET_DEFS_SCRIPT.get_asset("grate_square"))
	assert(floor_node.get_parent().name == "TerrainLayer", "Floor tiles should stay out of the dynamic depth layer.")
	assert(road_node.get_parent().name == "RoadLayer", "Road tiles should stay out of the dynamic depth layer.")
	assert(road_stamp_node.get_parent().name == "PropLayer", "Long road stamp should stay out of the dynamic depth layer.")
	assert(decal_node.get_parent().name == "DecalLayer", "Decals should stay out of the dynamic depth layer.")

	print("[GothicCompoundOcclusionSmoke] ok")
	quit(0)
