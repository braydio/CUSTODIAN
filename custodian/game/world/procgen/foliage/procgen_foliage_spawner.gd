extends RefCounted
class_name ProcgenFoliageSpawner

const FOLIAGE_OCCLUSION_SHADER := preload("res://game/world/procgen/foliage_occlusion_bubble.gdshader")
const FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES := 8


func generate(context: Dictionary) -> Dictionary:
	var started := Time.get_ticks_msec()
	var foliage_parent := context.get("foliage_parent", null) as Node2D
	if foliage_parent == null:
		push_warning("[Foliage] Missing FoliageLayer, skipping foliage spawn")
		return _result(0, true, "missing_parent", started)

	clear(context)

	var foliage_textures: Array = context.get("foliage_textures", [])
	if foliage_textures.is_empty():
		push_warning("[Foliage] No foliage textures loaded, skipping foliage spawn")
		return _result(0, true, "missing_textures", started)

	if bool(context.get("enable_streaming_reveal", false)):
		if bool(context.get("foliage_debug_logging", false)):
			print("[Foliage] Streaming reveal active; foliage will spawn during tile reveal")
		return _result(0, true, "streaming_reveal", started, true)

	var generated_floor_cells: Dictionary = context.get("generated_floor_cells", {})
	var pending_foliage_tiles: Array = context.get("pending_foliage_tiles", [])
	pending_foliage_tiles.clear()
	var candidates := _collect_candidate_tiles(context, generated_floor_cells)

	if bool(context.get("foliage_deferred_spawn_enabled", false)):
		pending_foliage_tiles.append_array(candidates)
		if bool(context.get("foliage_debug_logging", false)):
			print("[Foliage] Queued %d foliage candidates for deferred spawn" % pending_foliage_tiles.size())
		return _result(0, false, "deferred_spawn_queued", started, true)

	var placed := 0
	for pos in candidates:
		if place_at(context, pos):
			placed += 1

	if bool(context.get("foliage_debug_logging", false)):
		print("[Foliage] Placed %d sprites under %s" % [placed, foliage_parent.get_path()])
	return _result(placed, false, "", started)


func clear(context: Dictionary) -> void:
	var foliage_nodes: Dictionary = context.get("foliage_nodes", {})
	for entry in foliage_nodes.values():
		var node: Node = null
		if entry is Dictionary:
			node = entry.get("node", null) as Node
		elif entry is Node:
			node = entry as Node
		if is_instance_valid(node):
			node.queue_free()
	foliage_nodes.clear()

	var fruit_sprites: Array = context.get("fruit_sprites", [])
	for sprite in fruit_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	fruit_sprites.clear()

	var pending_foliage_tiles: Array = context.get("pending_foliage_tiles", [])
	pending_foliage_tiles.clear()


func remove_at(context: Dictionary, pos: Vector2i) -> void:
	var foliage_nodes: Dictionary = context.get("foliage_nodes", {})
	var entry = foliage_nodes.get(pos, null)
	var node: Node2D = null
	if entry is Dictionary:
		node = entry.get("node", null) as Node2D
	elif entry is Node2D:
		node = entry as Node2D
	if node != null and is_instance_valid(node):
		node.queue_free()
	foliage_nodes.erase(pos)
	var get_region_type: Callable = context.get("get_region_type_at_tile", Callable())
	var region_tiles: Dictionary = context.get("region_tiles", {})
	if get_region_type.is_valid() and str(get_region_type.call(pos)) == "foliage_cover":
		region_tiles.erase(pos)


func process_pending(context: Dictionary) -> Dictionary:
	var started := Time.get_ticks_msec()
	var pending_foliage_tiles: Array = context.get("pending_foliage_tiles", [])
	if pending_foliage_tiles.is_empty():
		return _result(0, true, "no_pending_tiles", started, true)
	var batch_size := maxi(1, int(context.get("foliage_spawn_batch_size", 512)))
	var placed := 0
	while placed < batch_size and not pending_foliage_tiles.is_empty():
		var pos_variant = pending_foliage_tiles.pop_front()
		if not pos_variant is Vector2i:
			continue
		if place_at(context, pos_variant as Vector2i):
			placed += 1
	if bool(context.get("foliage_debug_logging", false)):
		print("[Foliage] Spawned batch placed=%d remaining=%d batch_size=%d" % [placed, pending_foliage_tiles.size(), batch_size])
	return _result(placed, pending_foliage_tiles.is_empty(), "deferred_spawn_batch", started, true)


func can_place_at(context: Dictionary, pos: Vector2i) -> bool:
	return _should_place_foliage(context, pos)


func place_at(context: Dictionary, pos: Vector2i) -> bool:
	return _place_foliage(context, pos)


func _should_place_foliage(context: Dictionary, pos: Vector2i) -> bool:
	if float(context.get("foliage_density", 0.0)) <= 0.0:
		return false
	if _call_bool(context, "is_road_surface_tile", pos) or _call_bool(context, "is_parking_zone_tile", pos):
		return false
	if _call_bool(context, "is_indoor_tile", pos):
		return false
	if _is_near_indoor_tile(context, pos, int(context.get("foliage_indoor_clearance_tiles", 0))):
		return false
	if _is_no_random_foliage_region_tile(context, pos):
		return false
	if _is_near_wall(context, pos):
		return false
	if _is_inside_foliage_clearance(context, pos):
		return false
	if _call_bool(context, "is_inside_combat_readability_clearance", pos):
		return false
	return _would_place_foliage_at(context, pos)


func _collect_candidate_tiles(context: Dictionary, generated_floor_cells: Dictionary) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for key in generated_floor_cells.keys():
		if not key is Vector2i:
			continue
		var pos := key as Vector2i
		if _should_place_foliage(context, pos):
			candidates.append(pos)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return candidates


func _is_near_wall(context: Dictionary, pos: Vector2i) -> bool:
	var generated_wall_cells: Dictionary = context.get("generated_wall_cells", {})
	if generated_wall_cells.is_empty():
		return false
	var distance := int(context.get("foliage_min_wall_distance", 1))
	for x in range(-distance, distance + 1):
		for y in range(-distance, distance + 1):
			if generated_wall_cells.has(pos + Vector2i(x, y)):
				return true
	return false


func _is_inside_foliage_clearance(context: Dictionary, pos: Vector2i) -> bool:
	var clearance_radius := int(context.get("foliage_spawn_clearance_radius", 0))
	if clearance_radius > 0:
		var get_player_spawn: Callable = context.get("get_player_spawn", Callable())
		var spawn_tile := Vector2i.ZERO
		if get_player_spawn.is_valid():
			spawn_tile = get_player_spawn.call() as Vector2i
		if abs(pos.x - spawn_tile.x) <= clearance_radius and abs(pos.y - spawn_tile.y) <= clearance_radius:
			return true
	var building_clearance := int(context.get("foliage_compound_building_clearance", 0))
	var buildings: Array = context.get("last_compound_buildings", [])
	for building in buildings:
		if not building is Rect2i:
			continue
		var expanded := (building as Rect2i).grow(building_clearance)
		if expanded.has_point(pos):
			return true
	return false


func _is_near_indoor_tile(context: Dictionary, pos: Vector2i, clearance_tiles: int) -> bool:
	if clearance_tiles <= 0:
		return false
	var region_tiles: Dictionary = context.get("region_tiles", {})
	if region_tiles.is_empty():
		return false
	for x in range(-clearance_tiles, clearance_tiles + 1):
		for y in range(-clearance_tiles, clearance_tiles + 1):
			if _call_bool(context, "is_indoor_tile", pos + Vector2i(x, y)):
				return true
	return false


func _is_inside_compound_zone(context: Dictionary, pos: Vector2i) -> bool:
	var rect: Rect2i = context.get("last_compound_rect", Rect2i())
	return rect.size.x > 0 and rect.size.y > 0 and rect.has_point(pos)


func _place_foliage(context: Dictionary, pos: Vector2i) -> bool:
	var foliage_parent := context.get("foliage_parent", null) as Node2D
	var foliage_nodes: Dictionary = context.get("foliage_nodes", {})
	if foliage_parent == null or foliage_nodes.has(pos):
		return false
	var texture := _pick_foliage_texture(context, pos)
	if texture == null:
		return false

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = _call_color(context, "get_planet_profile_color", "foliage_tint", Color.WHITE)
	var world_pos := _call_vector2(context, "tile_to_world_position", pos) + _foliage_jitter(context, pos)
	sprite.position = foliage_parent.to_local(world_pos)
	sprite.z_index = int(context.get("foliage_behind_z_index", 1))
	sprite.z_as_relative = false
	var material := ShaderMaterial.new()
	material.shader = FOLIAGE_OCCLUSION_SHADER
	material.set_shader_parameter("bubble_radius", float(context.get("foliage_player_occlusion_radius", 80.0)))
	material.set_shader_parameter("bubble_softness", float(context.get("foliage_player_occlusion_softness", 12.0)))
	material.set_shader_parameter("bubble_alpha", float(context.get("foliage_player_occlusion_alpha", 0.55)))
	material.set_shader_parameter("bubble_enabled", false)
	material.set_shader_parameter("bubble_count", 0)
	for bubble_index in range(FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES):
		material.set_shader_parameter("bubble_center_%d" % bubble_index, Vector2.ZERO)
	sprite.material = material
	foliage_parent.add_child(sprite)

	var texture_size := texture.get_size()
	var foliage_kind := _classify_foliage(texture_size)
	var has_trunk_collision := foliage_kind == "tree" and _should_add_tree_trunk_collision(context, pos)
	if has_trunk_collision:
		_add_tree_trunk_collision(context, sprite, texture_size)
	foliage_nodes[pos] = {
		"node": sprite,
		"world_pos": world_pos,
		"base_y": world_pos.y + texture_size.y * 0.5,
		"size": texture_size,
		"kind": foliage_kind,
		"has_collision": has_trunk_collision,
	}

	var get_region_type: Callable = context.get("get_region_type_at_tile", Callable())
	var set_region_tile: Callable = context.get("set_region_tile", Callable())
	if bool(context.get("intent_mark_foliage_cover", true)) \
			and get_region_type.is_valid() \
			and set_region_tile.is_valid() \
			and str(get_region_type.call(pos)) == "exterior":
		set_region_tile.call(pos, "foliage_cover", foliage_kind)

	if bool(context.get("enable_fruit_spawning", true)) \
			and context.get("fruit_texture", null) != null \
			and _should_place_fruit(context, pos, foliage_kind):
		_place_fruit(context, sprite, pos, texture_size, foliage_kind)
	return true


func _pick_foliage_texture(context: Dictionary, pos: Vector2i) -> Texture2D:
	var foliage_textures: Array = context.get("foliage_textures", [])
	if foliage_textures.is_empty():
		return null
	var idx := _tile_noise_hash(context, pos + Vector2i(19, 73)) % foliage_textures.size()
	return foliage_textures[idx] as Texture2D


func _classify_foliage(foliage_size: Vector2) -> String:
	if foliage_size.y >= 96.0:
		return "tree"
	return "shrub"


func _should_add_tree_trunk_collision(context: Dictionary, pos: Vector2i) -> bool:
	if not bool(context.get("foliage_probabilistic_tree_collision", true)):
		return true
	var local_tree_density := _estimate_local_tree_density(context, pos)
	if local_tree_density <= float(context.get("foliage_sparse_tree_collision_threshold", 0.08)):
		return true
	var sparse := float(context.get("foliage_sparse_tree_collision_threshold", 0.08))
	var dense_threshold := maxf(sparse + 0.01, float(context.get("foliage_dense_tree_collision_threshold", 0.22)))
	var density_t := clampf((local_tree_density - sparse) / (dense_threshold - sparse), 0.0, 1.0)
	var collision_chance := lerpf(1.0, float(context.get("foliage_dense_tree_collision_chance", 0.28)), density_t)
	var roll := float(_tile_noise_hash(context, pos + Vector2i(1459, 811)) % 1000) / 1000.0
	return roll < collision_chance


func _estimate_local_tree_density(context: Dictionary, center: Vector2i) -> float:
	var radius: int = maxi(1, int(context.get("foliage_tree_collision_density_radius", 4)))
	var possible := 0
	var tree_count := 0
	var generated_floor_cells: Dictionary = context.get("generated_floor_cells", {})
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos := center + Vector2i(x, y)
			if not generated_floor_cells.has(pos):
				continue
			if _call_bool(context, "is_road_surface_tile", pos) or _call_bool(context, "is_parking_zone_tile", pos):
				continue
			if _call_bool(context, "is_indoor_tile", pos) or _is_near_indoor_tile(context, pos, int(context.get("foliage_indoor_clearance_tiles", 0))):
				continue
			if _is_no_random_foliage_region_tile(context, pos):
				continue
			if _is_near_wall(context, pos) \
					or _is_inside_foliage_clearance(context, pos) \
					or _call_bool(context, "is_inside_combat_readability_clearance", pos):
				continue
			possible += 1
			if not _would_place_foliage_at(context, pos):
				continue
			var texture := _pick_foliage_texture(context, pos)
			if texture != null and _classify_foliage(texture.get_size()) == "tree":
				tree_count += 1
	if possible <= 0:
		return 0.0
	return float(tree_count) / float(possible)


func _would_place_foliage_at(context: Dictionary, pos: Vector2i) -> bool:
	if _call_bool(context, "is_road_surface_tile", pos) or _call_bool(context, "is_parking_zone_tile", pos):
		return false
	if _is_no_random_foliage_region_tile(context, pos):
		return false
	var density := float(context.get("foliage_density", 0.0))
	if _is_inside_compound_zone(context, pos):
		density *= float(context.get("foliage_compound_density_multiplier", 0.28))
	if density <= 0.0:
		return false
	var prob := float(_tile_noise_hash(context, pos + Vector2i(13, 41)) % 1000) / 1000.0
	return prob < density


func _is_no_random_foliage_region_tile(context: Dictionary, pos: Vector2i) -> bool:
	var get_region_data: Callable = context.get("get_region_data_at_tile", Callable())
	var data := {}
	if get_region_data.is_valid():
		data = get_region_data.call(pos)
	var region_type := String(data.get("region_type", "exterior"))
	var zone := String(data.get("zone", "natural"))
	if zone == "authored_scene" \
			or zone == "story_room" \
			or zone == "faction_activity" \
			or zone == "interior":
		return true
	if region_type.contains("authored") \
			or region_type.contains("story_room") \
			or region_type.contains("faction_site") \
			or region_type.contains("ash_bell") \
			or region_type.contains("forlorn_ritualant"):
		return true
	return false


func _add_tree_trunk_collision(context: Dictionary, foliage_sprite: Sprite2D, foliage_size: Vector2) -> void:
	if foliage_sprite == null:
		return
	var body := StaticBody2D.new()
	body.name = "TrunkCollision"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = context.get("foliage_tree_trunk_collision_size", Vector2(18, 12))
	shape.shape = rectangle
	body.position = Vector2(0, foliage_size.y * 0.5) + Vector2(context.get("foliage_tree_trunk_collision_offset", Vector2(0, -6)))
	body.add_child(shape)
	foliage_sprite.add_child(body)


func _should_place_fruit(context: Dictionary, pos: Vector2i, foliage_kind: String) -> bool:
	var fruit_prob := float(_tile_noise_hash(context, pos + Vector2i(17, 89)) % 1000) / 1000.0
	var chance := float(context.get("fruit_spawn_chance_tree", 0.14)) if foliage_kind == "tree" else float(context.get("fruit_spawn_chance_shrub", 0.10))
	return fruit_prob < chance


func _place_fruit(context: Dictionary, foliage_sprite: Sprite2D, foliage_tile: Vector2i, foliage_size: Vector2, foliage_kind: String) -> void:
	var fruit_texture := context.get("fruit_texture", null) as Texture2D
	if fruit_texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = fruit_texture
	sprite.modulate = _call_color(context, "get_planet_profile_color", "foliage_tint", Color.WHITE)

	var tiles_wide := maxi(1, int(context.get("fruit_tiles_wide", 3)))
	var tiles_high := maxi(1, int(context.get("fruit_tiles_high", 3)))
	var frame_x := _tile_noise_hash(context, foliage_tile + Vector2i(23, 47)) % tiles_wide
	var frame_y := _tile_noise_hash(context, foliage_tile + Vector2i(61, 11)) % tiles_high
	var frame_size := Vector2(
		float(fruit_texture.get_size().x) / float(tiles_wide),
		float(fruit_texture.get_size().y) / float(tiles_high)
	)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(frame_x * frame_size.x, frame_y * frame_size.y, frame_size.x, frame_size.y)
	sprite.centered = true

	var x_jitter := (float(_tile_noise_hash(context, foliage_tile + Vector2i(31, 59)) % 100) / 100.0 - 0.5)
	var y_jitter := (float(_tile_noise_hash(context, foliage_tile + Vector2i(71, 29)) % 100) / 100.0 - 0.5)
	var fruit_offset := Vector2.ZERO
	if foliage_kind == "tree":
		fruit_offset = Vector2(
			x_jitter * foliage_size.x * 0.18,
			-foliage_size.y * 0.18 + y_jitter * foliage_size.y * 0.04
		)
	else:
		fruit_offset = Vector2(
			x_jitter * foliage_size.x * 0.16,
			-foliage_size.y * 0.12 + y_jitter * foliage_size.y * 0.03
		)
	sprite.position = fruit_offset
	sprite.z_index = 1
	sprite.z_as_relative = true

	foliage_sprite.add_child(sprite)
	var fruit_sprites: Array = context.get("fruit_sprites", [])
	fruit_sprites.append(sprite)


func _foliage_jitter(context: Dictionary, pos: Vector2i) -> Vector2:
	var seed := _tile_noise_hash(context, pos + Vector2i(7, 13))
	var x_unit := float(seed % 21) - 10.0
	var y_unit := float((seed / 21) % 11) - 5.0
	var amplitude: Vector2 = context.get("foliage_jitter_amplitude", Vector2(4, 2))
	return Vector2(
		x_unit * (amplitude.x / 10.0),
		y_unit * (amplitude.y / 5.0)
	)


func _tile_noise_hash(context: Dictionary, pos: Vector2i) -> int:
	var callable: Callable = context.get("tile_noise_hash", Callable())
	if callable.is_valid():
		return int(callable.call(pos))
	return int(abs(pos.x * 73856093 ^ pos.y * 19349663))


func _call_bool(context: Dictionary, key: String, pos: Vector2i) -> bool:
	var callable: Callable = context.get(key, Callable())
	return bool(callable.call(pos)) if callable.is_valid() else false


func _call_vector2(context: Dictionary, key: String, pos: Vector2i) -> Vector2:
	var callable: Callable = context.get(key, Callable())
	if callable.is_valid():
		return callable.call(pos) as Vector2
	return Vector2.ZERO


func _call_color(context: Dictionary, key: String, color_id: String, fallback: Color) -> Color:
	var callable: Callable = context.get(key, Callable())
	if callable.is_valid():
		return callable.call(color_id, fallback) as Color
	return fallback


func _result(placed: int, skipped: bool, reason: String, started: int, deferred: bool = false) -> Dictionary:
	return {
		"placed": placed,
		"skipped": skipped,
		"reason": reason,
		"elapsed_ms": Time.get_ticks_msec() - started,
		"deferred": deferred,
	}
