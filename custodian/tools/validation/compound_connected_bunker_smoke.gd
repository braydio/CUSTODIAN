extends SceneTree

## Type B (connected_bunker) blockout: planner contract plus the real ProcGenTilemap.
## Verifies physically separated surface/subsurface layers, one continuous
## underground network, paired vertical entries and sealed layer boundaries.

const PLANNER := preload("res://game/world/compound/rooms/persistent_compound_layout_planner.gd")
const VIEW_SCRIPT := preload("res://game/ui/minimap/minimap_view.gd")
const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEEDS := [1, 2, 3, 10, 42, 99, 1337]
const RECTS: Array[Rect2i] = [Rect2i(8, 8, 64, 52), Rect2i(8, 8, 70, 56), Rect2i(8, 8, 76, 60)]
const INGRESS: Array[Vector2i] = [Vector2i(24, 8), Vector2i(8, 40), Vector2i(40, 59), Vector2i(71, 30)]
const REQUIRED := ["command_post", "power", "archive", "defense", "storage", "north_transit", "south_transit", "maintenance"]
const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_planner()
	await _check_runtime()
	_finish()


# ---- planner contract -------------------------------------------------------

func _generate(seed: int, rect: Rect2i, profile_id: StringName = &"connected_bunker") -> Dictionary:
	var planner := PLANNER.new()
	_expect(planner.load_default_graph(), "graph and profile catalog must load")
	return planner.generate_layout(seed, rect, INGRESS, profile_id)


func _check_planner() -> void:
	for rect in RECTS:
		for seed in SEEDS:
			var first := _generate(seed, rect)
			var second := _generate(seed, rect)
			_expect(first == second, "seed %d %s must be repeatable" % [seed, rect])
			_expect(bool(first.get("valid", false)), "seed %d %s must be valid: %s" % [seed, rect, first.get("diagnostics", {})])
			if not bool(first.get("valid", false)):
				continue
			_validate_layout(first, seed)
	var legacy := _generate(42, RECTS[0], &"")
	var walled := _generate(42, RECTS[0], &"walled_yard")
	_expect(not legacy.has("layers") and not walled.has("layers"), "legacy and walled_yard must not gain a subsurface layer")
	_check_minimap_projection()
	var tiny := _generate(42, Rect2i(0, 0, 40, 30))
	_expect(not bool(tiny.get("valid", true)), "undersized bounds must fail closed")
	var reason := String((tiny.get("diagnostics", {}) as Dictionary).get("failure_reason", ""))
	_expect(reason == "connected_bunker_bounds_too_small", "undersized bounds report their reason, got %s" % reason)


func _check_minimap_projection() -> void:
	var layout := _generate(1337, RECTS[0])
	var view := VIEW_SCRIPT.new() as MinimapView
	view.size = Vector2(360, 260)
	root.add_child(view)
	view.set_level_data({
		"map_size": Vector2i(112, 96),
		"tile_size": Vector2(32, 32),
		"compound_rect": layout["rect"],
		"compound_ingress": layout["ingress"],
		"compound_rooms": layout["rooms"],
		"compound_connections": layout["connections"],
		"compound_buildings": layout["buildings"],
		"compound_surface_housings": layout["surface_housings"],
		"compound_vertical_entries": layout["vertical_entries"],
	})
	var summary := view.get_compound_layout_summary()
	var counts: Dictionary = summary.get("layer_room_counts", {})
	_expect(int(counts.get("subsurface", 0)) == (layout["rooms"] as Array).size(), "minimap projects every underground room by layer")
	_expect(int(summary.get("surface_housing_count", 0)) == (layout["surface_housings"] as Array).size(), "minimap projects the surface housings")
	_expect(int(summary.get("vertical_entry_count", 0)) == (layout["vertical_entries"] as Array).size(), "minimap projects the vertical entries")
	view.set_overview_mode(true)
	view.queue_redraw()
	view.queue_free()


func _validate_layout(layout: Dictionary, seed: int) -> void:
	var tag := "seed %d" % seed
	var layers: Dictionary = layout.get("layers", {})
	var surface: Rect2i = (layers.get("surface", {}) as Dictionary).get("rect", Rect2i())
	var subsurface: Rect2i = (layers.get("subsurface", {}) as Dictionary).get("rect", Rect2i())
	var separator: Rect2i = (layers.get("subsurface", {}) as Dictionary).get("separator_rect", Rect2i())
	var content: Rect2i = (layers.get("subsurface", {}) as Dictionary).get("content_rect", Rect2i())
	var compound: Rect2i = layout.get("rect", Rect2i())
	_expect(surface.size.x > 0 and subsurface.size.x > 0, "%s exports both layers" % tag)
	_expect(not surface.intersects(subsurface), "%s layer reservations never overlap" % tag)
	_expect(separator.position.y == surface.end.y and subsurface.position.y == separator.end.y, "%s separator is a solid band between the layers" % tag)
	_expect(separator.size.y >= 2, "%s separator is at least two tiles thick" % tag)
	_expect(compound.encloses(surface) and compound.encloses(subsurface), "%s layers stay inside the compound" % tag)
	_expect(String(layout.get("layer_id", "")) == "surface", "%s entry layer is the surface" % tag)

	var rooms: Array = layout.get("rooms", [])
	var types := {}
	var ids := {}
	for room_variant in rooms:
		var room := room_variant as Dictionary
		var rect: Rect2i = room.get("rect", Rect2i())
		types[String(room.get("type", ""))] = true
		_expect(not ids.has(String(room.get("id", ""))), "%s room IDs are unique" % tag)
		ids[String(room.get("id", ""))] = true
		_expect(String(room.get("layer_id", "")) == "subsurface", "%s functional rooms live underground" % tag)
		_expect(content.encloses(rect), "%s %s stays inside the subsurface content" % [tag, room.get("id", "room")])
		_expect(not surface.intersects(rect), "%s %s never touches surface space" % [tag, room.get("id", "room")])
	for required_type in REQUIRED:
		_expect(types.has(required_type), "%s underground network includes %s" % [tag, required_type])
	for a in range(rooms.size()):
		for b in range(a + 1, rooms.size()):
			_expect(not (rooms[a]["rect"] as Rect2i).intersects(rooms[b]["rect"]), "%s rooms never overlap" % tag)

	var spine: Array = layout.get("spine_cells", [])
	_expect(spine.size() >= 3, "%s has a corridor spine of three or more cells" % tag)
	_expect(int((layout.get("diagnostics", {}) as Dictionary).get("spine_length", 0)) >= 3, "%s reports a 3+ cell spine length" % tag)
	var thresholds: Array = layout.get("compartment_thresholds", [])
	_expect(thresholds.size() == rooms.size(), "%s has one compartment threshold per room" % tag)

	var housings: Array = layout.get("surface_housings", [])
	var entries: Array = layout.get("vertical_entries", [])
	_expect(housings.size() >= 2 and entries.size() >= 2, "%s has two or more housings with paired entries" % tag)
	var spine_set := {}
	for cell in spine:
		spine_set[cell] = true
	for entry_variant in entries:
		var entry := entry_variant as Dictionary
		var housing := _find(housings, String(entry.get("housing_id", "")))
		_expect(not housing.is_empty(), "%s entry %s references a housing" % [tag, entry.get("id", "")])
		if housing.is_empty():
			continue
		var surface_anchor: Vector2i = entry.get("surface_anchor", Vector2i.ZERO)
		var under_anchor: Vector2i = entry.get("subsurface_anchor", Vector2i.ZERO)
		_expect((housing["rect"] as Rect2i).has_point(surface_anchor), "%s surface anchor sits in its housing" % tag)
		_expect(spine_set.has(under_anchor), "%s subsurface anchor is a spine cell" % tag)
		_expect(bool(entry.get("reversible", false)) and String(entry.get("edge_type", "")) == "vertical_entry", "%s entry is a reversible vertical_entry edge" % tag)
		_expect((housing["rect"] as Rect2i).intersection(subsurface).size == Vector2i.ZERO, "%s housing is outside the subsurface region" % tag)

	var ingress: Array = layout.get("ingress", [])
	_expect(ingress.size() >= 2, "%s keeps two or more surface ingress cells" % tag)
	for cell in ingress:
		_expect(surface.has_point(cell) and not subsurface.has_point(cell), "%s ingress opens only into the surface band" % tag)

	var courtyard := {}
	for cell in layout.get("courtyard_cells", []):
		courtyard[cell] = true
		_expect(not subsurface.has_point(cell), "%s courtyard never enters the subsurface region" % tag)
	_expect(courtyard.size() > 0, "%s has a surface yard" % tag)


func _find(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if String((item as Dictionary).get("id", "")) == item_id:
			return item
	return {}


# ---- real runtime -----------------------------------------------------------

func _check_runtime() -> void:
	var first_signature := ""
	for seed in SEEDS:
		var map := await _generate_map(seed)
		var data := map.get_level_data()
		var signature := _validate_runtime(map, data, seed)
		if seed == SEEDS[0]:
			first_signature = signature
		map.queue_free()
		await process_frame
	var repeat := await _generate_map(SEEDS[0])
	var repeat_signature := _runtime_signature(repeat, repeat.get_level_data())
	_expect(repeat_signature == first_signature, "seed %d real runtime geometry must be repeatable" % SEEDS[0])
	repeat.queue_free()
	await process_frame


func _generate_map(seed: int) -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.compound_archetype_id = "connected_bunker"
	root.add_child(map)
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var generator := map.get_node("ProcGen2") as ProcGen
	generator.generate_seed = false
	generator.seed = seed
	generator.map_size = Vector2i(112, 96)
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.enable_final_foliage = false
	map.enable_ruin_prop_spawning = false
	map.interior_prop_spawning_enabled = false
	map.auto_bake_nav = false
	map.generate()
	await process_frame
	return map


func _walkable(map: ProcGenTilemap) -> Dictionary:
	var floors := map.debug_get_generated_floor_cells()
	var walls := map.debug_get_generated_wall_cells()
	var walkable := {}
	for cell in floors:
		if not walls.has(cell):
			walkable[cell] = true
	return walkable


func _flood(start: Vector2i, walkable: Dictionary) -> Dictionary:
	var seen := {}
	if not walkable.has(start):
		return seen
	var frontier: Array[Vector2i] = [start]
	seen[start] = true
	var head := 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		for direction in CARDINALS:
			var next_cell: Vector2i = current + direction
			if walkable.has(next_cell) and not seen.has(next_cell):
				seen[next_cell] = true
				frontier.append(next_cell)
	return seen


func _validate_runtime(map: ProcGenTilemap, data: Dictionary, seed: int) -> String:
	var tag := "runtime seed %d" % seed
	_expect(String(data.get("compound_archetype_id", "")) == "connected_bunker", "%s exports the selected archetype" % tag)
	var layers: Dictionary = data.get("compound_layers", {})
	_expect(layers.has("surface") and layers.has("subsurface"), "%s exports layer-aware metadata" % tag)
	var surface: Rect2i = (layers.get("surface", {}) as Dictionary).get("rect", Rect2i())
	var subsurface: Rect2i = (layers.get("subsurface", {}) as Dictionary).get("rect", Rect2i())
	var separator: Rect2i = (layers.get("subsurface", {}) as Dictionary).get("separator_rect", Rect2i())
	var content: Rect2i = (layers.get("subsurface", {}) as Dictionary).get("content_rect", Rect2i())
	var rooms: Array = data.get("compound_rooms", [])
	var housings: Array = data.get("compound_surface_housings", [])
	var entries: Array = data.get("compound_vertical_entries", [])
	var thresholds: Array = data.get("compound_compartment_thresholds", [])
	_expect(rooms.size() == REQUIRED.size(), "%s exports every mandatory room, got %d" % [tag, rooms.size()])
	_expect(housings.size() >= 2 and entries.size() >= 2, "%s exports two or more housings and entries" % tag)
	_expect(thresholds.size() == rooms.size(), "%s exports compartment thresholds" % tag)
	if rooms.is_empty() or entries.size() < 2:
		return ""

	var walkable := _walkable(map)
	var walls := map.debug_get_generated_wall_cells()
	for y in range(separator.position.y, separator.end.y):
		for x in range(separator.position.x, separator.end.x):
			_expect(walls.has(Vector2i(x, y)) and not walkable.has(Vector2i(x, y)), "%s separator cell (%d,%d) is solid" % [tag, x, y])

	# One continuous underground region, reached physically from the first entry.
	var first_anchor: Vector2i = entries[0].get("subsurface_anchor", Vector2i.ZERO)
	var underground := _flood(first_anchor, walkable)
	_expect(underground.size() > 0, "%s underground anchor is walkable" % tag)
	for cell in underground:
		_expect(content.has_point(cell), "%s underground walkable cell %s leaked outside the subsurface content" % [tag, cell])
		if not content.has_point(cell):
			break
	for entry in entries:
		_expect(underground.has(entry.get("subsurface_anchor", Vector2i.ZERO)), "%s every vertical entry lands in the one underground network" % tag)
	for room in rooms:
		var rect: Rect2i = room.get("rect", Rect2i())
		_expect(underground.has(Vector2i(rect.get_center())), "%s %s is reachable underground without a room transfer" % [tag, room.get("id", "room")])
		_expect(underground.has(room.get("threshold_cell", Vector2i.ZERO)), "%s %s compartment threshold is walkable and connected" % [tag, room.get("id", "room")])
		for door in room.get("door_cells", []):
			_expect(walkable.has(door), "%s %s door is physical floor" % [tag, room.get("id", "room")])
	for connection in data.get("compound_connections", []):
		for cell in connection.get("path_cells", []):
			_expect(underground.has(cell), "%s tunnel path cell %s is physically walkable" % [tag, cell])
			break

	# Every walkable cell inside the subsurface region belongs to that one network.
	for y in range(subsurface.position.y, subsurface.end.y):
		for x in range(subsurface.position.x, subsurface.end.x):
			var cell := Vector2i(x, y)
			if walkable.has(cell):
				_expect(underground.has(cell), "%s stray walkable cell %s inside the subsurface region" % [tag, cell])
				break

	# The surface layer is separate, reaches the outside, and holds both housings.
	var spawn: Vector2i = data.get("compound_primary_anchor", Vector2i.ZERO)
	var surface_cells := _flood(spawn, walkable)
	_expect(surface_cells.size() > 0, "%s surface spawn is walkable" % tag)
	for cell in surface_cells:
		_expect(not subsurface.has_point(cell), "%s surface network leaked into the subsurface region at %s" % [tag, cell])
		if subsurface.has_point(cell):
			break
	for cell in underground:
		_expect(not surface_cells.has(cell), "%s surface and underground networks must not share walkable cells" % tag)
		break
	for entry in entries:
		_expect(surface_cells.has(entry.get("surface_anchor", Vector2i.ZERO)), "%s each housing is reachable from the surface spawn" % tag)
	var reached_ingress := 0
	for cell in data.get("compound_ingress", []):
		if surface_cells.has(cell):
			reached_ingress += 1
	_expect(reached_ingress >= 2, "%s surface network reaches two or more ingress cells" % tag)
	_expect(surface.encloses(Rect2i(spawn, Vector2i.ONE)), "%s surface spawn is in the surface band" % tag)
	return _runtime_signature(map, data)


func _runtime_signature(map: ProcGenTilemap, data: Dictionary) -> String:
	var walkable := _walkable(map)
	var cells: Array[Vector2i] = []
	var layers: Dictionary = data.get("compound_layers", {})
	var subsurface: Rect2i = (layers.get("subsurface", {}) as Dictionary).get("rect", Rect2i())
	var surface: Rect2i = (layers.get("surface", {}) as Dictionary).get("rect", Rect2i())
	for cell in walkable:
		if subsurface.has_point(cell) or surface.has_point(cell):
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	return "%d:%s:%s" % [cells.size(), hash(str(cells)), hash(str(data.get("compound_rooms", [])))]


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	if _failed:
		push_error("compound_connected_bunker_smoke failed")
		quit(1)
		return
	print("compound_connected_bunker_smoke passed")
	quit()
