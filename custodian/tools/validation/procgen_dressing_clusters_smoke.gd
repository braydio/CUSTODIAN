extends SceneTree

const PLANNER := preload("res://game/world/procgen/dressing/dressing_cluster_planner.gd")
const REALIZER := preload("res://game/world/procgen/dressing/dressing_cluster_realizer.gd")
const CATALOG := preload("res://content/procgen/dressing_clusters/dressing_cluster_catalog_v1.tres")
const CHILD := preload("res://game/world/procgen/dressing/dressing_cluster_child.gd")
const SPAWNER := preload("res://game/world/procgen/foliage/procgen_foliage_spawner.gd")
const MAP_SCRIPT := preload("res://game/world/procgen/proc_gen_tilemap.gd")

var _failed := false

func _init() -> void:
	var floors := {}
	var biomes := {}
	var materials := {}
	var deep := {}
	for y in range(64):
		for x in range(64):
			var cell := Vector2i(x, y)
			floors[cell] = true
			biomes[cell] = &"rocky_upland"
			materials[cell] = &"natural_rock"
			deep[cell] = true
	var route_hard := {}
	for y in range(64): route_hard[Vector2i(32, y)] = true
	var context := {"seed": 41372, "map_area": 4096, "floor_cells": floors, "wall_cells": {}, "chasm_cells": {}, "ocean_cells": {}, "biome_by_cell": biomes, "surface_material_by_cell": materials, "route_hard_clearance_cells": route_hard, "route_shoulder_cells": {}, "sparse_dressing_cells": {}, "deep_dressing_cells": deep, "road_cells": {}, "parking_cells": {}, "service_hardstand_cells": {}, "encounter_reserved_cells": {}, "authored_cells": {}, "reserved_cells": {}, "ingress_dressing_clearance_cells": {}, "macro_dressing_clearance_cells": {}, "indoor_cells": {}}
	context.wall_cells[Vector2i(0, 0)] = true
	context.chasm_cells[Vector2i(1, 0)] = true
	context.ocean_cells[Vector2i(2, 0)] = true
	context.route_shoulder_cells[Vector2i(3, 0)] = true
	context.road_cells[Vector2i(4, 0)] = true
	context.parking_cells[Vector2i(5, 0)] = true
	context.service_hardstand_cells[Vector2i(6, 0)] = true
	context.encounter_reserved_cells[Vector2i(7, 0)] = true
	context.authored_cells[Vector2i(8, 0)] = true
	context.reserved_cells[Vector2i(9, 0)] = true
	context.ingress_dressing_clearance_cells[Vector2i(10, 0)] = true
	context.macro_dressing_clearance_cells[Vector2i(11, 0)] = true
	context.indoor_cells[Vector2i(12, 0)] = true
	var before := context.duplicate(true)
	var planner := PLANNER.new() as DressingClusterPlanner
	var first: Dictionary = planner.build_plan(context, CATALOG)
	var again: Dictionary = planner.build_plan(context, CATALOG)
	_require(first.fingerprint == again.fingerprint, "same semantic input changed fingerprint")
	_require(context == before, "planner mutated semantic input")
	_require(first.target_cluster_count == 4, "target count formula changed")
	_require(first.placed_cluster_count > 0, "valid synthetic Rocky context placed no clusters")
	var tilemap_source := FileAccess.get_file_as_string("res://game/world/procgen/proc_gen_tilemap.gd")
	var cluster_build_start := tilemap_source.find("func _build_dressing_cluster_plan(")
	var cluster_build_end := tilemap_source.find("func is_inside_dressing_cluster_suppression(", cluster_build_start)
	_require(cluster_build_start >= 0 and not tilemap_source.substr(cluster_build_start, cluster_build_end - cluster_build_start).contains(".realize("), "candidate cluster planning realizes presentation nodes")
	_require(CATALOG.filter_profiles(&"woodland", &"natural_rock").is_empty(), "Rocky catalog leaked into another biome")
	_validate_production_profiles()
	var occupied := {}
	var anchors: Array[Vector2i] = []
	var profiles_by_id := {}
	for profile: DressingClusterProfile in CATALOG.filter_profiles(&"rocky_upland", &"natural_rock"):
		profiles_by_id[profile.cluster_id] = profile
	for placement: Dictionary in first.placements:
		var profile_id := String(placement.cluster_id)
		_require(["rocky_tree_scrub_small_01", "rocky_tree_scrub_large_01", "rocky_scrub_pocket_01"].has(profile_id), "unknown proof profile placed")
		for cell: Vector2i in placement.footprint_cells:
			_require(not occupied.has(cell), "cluster footprints overlap")
			occupied[cell] = true
		var anchor: Vector2i = placement.anchor
		var profile: DressingClusterProfile = profiles_by_id[placement.cluster_id]
		for prior: Vector2i in anchors:
			_require(anchor.distance_to(prior) >= profile.min_anchor_spacing_cells, "profile anchor spacing was violated")
		anchors.append(anchor)
		for child: Dictionary in placement.children:
			var cell: Vector2i = child.cell
			_require(floors.has(cell), "child escaped final floor")
			_require(not route_hard.has(cell), "child entered hard route clearance")
			for mask_name in ["wall_cells", "chasm_cells", "ocean_cells", "route_shoulder_cells", "road_cells", "parking_cells", "service_hardstand_cells", "encounter_reserved_cells", "authored_cells", "reserved_cells", "ingress_dressing_clearance_cells", "macro_dressing_clearance_cells", "indoor_cells"]:
				_require(not (context[mask_name] as Dictionary).has(cell), "child entered excluded %s" % mask_name)
	_require(context == before, "suppression planning changed semantic dictionaries")
	_require(first.child_by_cell.size() == first.placements.map(func(p: Dictionary) -> int: return (p.children as Array).size()).reduce(func(a: int, b: int) -> int: return a + b, 0), "child map count mismatch")
	var spawner := SPAWNER.new() as ProcgenFoliageSpawner
	var tree_image := Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
	var shrub_image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	var tree_texture := ImageTexture.create_from_image(tree_image)
	var shrub_texture := ImageTexture.create_from_image(shrub_image)
	var parent := Node2D.new()
	root.add_child(parent)
	var authored_context := {"foliage_parent": parent, "foliage_nodes": {}, "generated_floor_cells": {Vector2i(8, 8): true, Vector2i(20, 20): true}, "foliage_tree_textures": [tree_texture], "foliage_shrub_textures": [shrub_texture], "tile_noise_hash": Callable(self, "_noise"), "tile_to_world_position": Callable(self, "_world"), "enable_fruit_spawning": false, "foliage_wind_enabled": true, "foliage_density": 0.0}
	_require(spawner.place_at_kind(authored_context, Vector2i(8, 8), &"tree"), "authored tree incorrectly used random density roll")
	_require(spawner.place_at_kind(authored_context, Vector2i(20, 20), &"shrub"), "authored shrub placement failed")
	_require(authored_context.foliage_nodes[Vector2i(8, 8)].kind == "tree", "forced tree selected wrong texture class")
	_require(authored_context.foliage_nodes[Vector2i(20, 20)].kind == "shrub", "forced shrub selected wrong texture class")
	var authored_tree: Sprite2D = authored_context.foliage_nodes[Vector2i(8, 8)].node
	_require(authored_tree.material == spawner.get_shared_materials().tree, "authored foliage did not reuse the shared wind/occlusion material")
	_require(authored_tree.get_node_or_null("TrunkCollision") is StaticBody2D, "authored tree did not reuse tree trunk collision policy")
	_require(not spawner.place_at_kind(authored_context, Vector2i(9, 9), &"tree"), "authored placement bypassed floor clearance")
	var shrub_sprite: Sprite2D = authored_context.foliage_nodes[Vector2i(20, 20)].node
	var chosen_texture := shrub_sprite.texture
	var realizer := REALIZER.new() as DressingClusterRealizer
	spawner.clear(authored_context)
	var streaming_context := authored_context.duplicate()
	streaming_context["foliage_nodes"] = {}
	var stream_plan := {"child_by_cell": {Vector2i(20, 20): {"cluster_id": &"stream_fixture", "kind": &"shrub", "required": true}}}
	var revealed := realizer.realize(stream_plan, streaming_context, spawner)
	_require(revealed.placed_child_count == 1, "stream reveal did not realize the planned child")
	var first_texture: Texture2D = streaming_context.foliage_nodes[Vector2i(20, 20)].node.texture
	spawner.remove_at(streaming_context, Vector2i(20, 20))
	_require(not streaming_context.foliage_nodes.has(Vector2i(20, 20)), "stream unload retained cluster foliage ownership")
	realizer.realize(stream_plan, streaming_context, spawner)
	var second_texture: Texture2D = streaming_context.foliage_nodes[Vector2i(20, 20)].node.texture
	_require(first_texture == chosen_texture and second_texture == first_texture, "stream reveal changed deterministic child texture")
	var host := MAP_SCRIPT.new() as ProcGenTilemap
	host.dressing_clusters_enabled = true
	host._biome_id_by_cell[Vector2i.ZERO] = &"rocky_upland"
	host._surface_material_by_cell[Vector2i.ZERO] = &"natural_rock"
	_require(is_equal_approx(host.get_foliage_presentation_density_multiplier(Vector2i.ZERO), 0.62), "Rocky natural-rock residual multiplier mismatch")
	host._biome_id_by_cell[Vector2i.ZERO] = &"woodland"
	_require(is_equal_approx(host.get_foliage_presentation_density_multiplier(Vector2i.ZERO), 1.0), "other biome received Rocky residual multiplier")
	host.free()
	spawner.clear(authored_context)
	parent.free()
	if _failed:
		quit(1)
		return
	print("procgen_dressing_clusters_smoke: PASS placed=%d children=%d fingerprint=%s" % [first.placed_cluster_count, first.child_by_cell.size(), first.fingerprint])
	quit(0)

func _noise(cell: Vector2i) -> int:
	return abs(cell.x * 73856093 ^ cell.y * 19349663)

func _validate_production_profiles() -> void:
	var expected := {
		"rocky_tree_scrub_small_01": {"size": Vector2i(7, 7), "suppression": Vector2i(11, 11), "weight": 10, "limit": 4, "spacing": 9, "sparse": true, "deep": true, "children": ["tree@0,0", "shrub@-2,1", "shrub@2,1", "shrub@0,2"]},
		"rocky_tree_scrub_large_01": {"size": Vector2i(9, 7), "suppression": Vector2i(13, 11), "weight": 6, "limit": 3, "spacing": 11, "sparse": false, "deep": true, "children": ["tree@-2,0", "tree@2,1", "shrub@-1,2", "shrub@1,-2", "shrub@3,2"]},
		"rocky_scrub_pocket_01": {"size": Vector2i(7, 7), "suppression": Vector2i(11, 11), "weight": 12, "limit": 4, "spacing": 8, "sparse": true, "deep": true, "children": ["shrub@0,0", "shrub@-2,0", "shrub@2,0", "shrub@-1,2", "shrub@1,-2"]},
	}
	for profile: DressingClusterProfile in CATALOG.profiles:
		var id := String(profile.cluster_id)
		_require(expected.has(id), "unexpected profile in V1 catalog: %s" % id)
		var rule: Dictionary = expected.get(id, {})
		var footprint_bounds := _bounds(profile.footprint_cells)
		var suppression_bounds := _bounds(profile.suppression_cells)
		_require(footprint_bounds.size == rule.get("size", Vector2i.ZERO), "%s footprint envelope mismatch" % id)
		_require(suppression_bounds.size == rule.get("suppression", Vector2i.ZERO), "%s suppression envelope mismatch" % id)
		_require(profile.required_biome == &"rocky_upland" and profile.allowed_surface_materials == PackedStringArray(["natural_rock"]), "%s semantic eligibility mismatch" % id)
		_require(profile.weight == rule.get("weight") and profile.max_instances_per_map == rule.get("limit") and profile.min_anchor_spacing_cells == rule.get("spacing"), "%s placement budget mismatch" % id)
		_require(profile.allow_sparse_band == rule.get("sparse") and profile.allow_deep_band == rule.get("deep"), "%s band policy mismatch" % id)
		var child_signatures: Array[String] = []
		for child: DressingClusterChild in profile.children:
			child_signatures.append("%s@%d,%d" % [child.foliage_kind(), child.offset_cells.x, child.offset_cells.y])
		_require(child_signatures == rule.get("children", []), "%s child composition mismatch" % id)
	_require(CATALOG.profiles.size() == expected.size(), "catalog omitted one or added extra proof profiles")

func _bounds(cells: Array[Vector2i]) -> Rect2i:
	var result := Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		result = result.expand(cell)
	return Rect2i(result.position, result.size + Vector2i.ONE)

func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * 32.0

func _require(ok: bool, message: String) -> void:
	if not ok:
		_failed = true
		push_error("procgen_dressing_clusters_smoke: " + message)
