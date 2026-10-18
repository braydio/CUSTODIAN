extends SceneTree

## Type A (walled_yard) blockout: planner contract plus the real ProcGenTilemap.
## Verifies a close-packed building cluster, a closed perimeter with exactly two
## enumerated gates, yard-facing building doorways and a reachable service yard.

const PLANNER := preload("res://game/world/compound/rooms/persistent_compound_layout_planner.gd")
const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEEDS := [1, 2, 3, 10, 42, 99, 1337]
const RECTS: Array[Rect2i] = [Rect2i(8, 8, 64, 52), Rect2i(8, 8, 70, 56), Rect2i(8, 8, 76, 60)]
const INGRESS: Array[Vector2i] = [Vector2i(24, 8), Vector2i(56, 59), Vector2i(8, 30)]
const REQUIRED := ["command_post", "power", "archive", "defense", "storage", "north_transit", "south_transit", "maintenance"]
const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const WALL_THICKNESS := 2

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_planner()
	await _check_runtime()
	_finish()


# ---- planner contract -------------------------------------------------------

func _generate(seed: int, rect: Rect2i, profile_id: StringName = &"walled_yard") -> Dictionary:
	var planner := PLANNER.new()
	_expect(planner.load_default_graph(), "graph and profile catalog must load")
	return planner.generate_layout(seed, rect, INGRESS, profile_id)


func _bounding_area(layout: Dictionary) -> int:
	var bounds := Rect2i()
	var first := true
	for room in layout.get("rooms", []):
		var rect: Rect2i = room["rect"]
		bounds = rect if first else bounds.merge(rect)
		first = false
	return bounds.get_area()


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
			var legacy := _generate(seed, rect, &"")
			_expect(_bounding_area(first) <= _bounding_area(legacy), "seed %d buildings are no more spread out than the legacy campus" % seed)
	var legacy_layout := _generate(42, RECTS[0], &"")
	var bunker := _generate(42, RECTS[0], &"connected_bunker")
	_expect(not legacy_layout.has("gates") and not legacy_layout.has("perimeter"), "legacy must not gain Type A metadata")
	_expect(not bunker.has("gates") and bunker.has("layers"), "connected_bunker keeps its own geometry")
	var tiny := _generate(42, Rect2i(0, 0, 40, 30))
	_expect(not bool(tiny.get("valid", true)), "undersized bounds must fail closed")


func _validate_layout(layout: Dictionary, seed: int) -> void:
	var tag := "seed %d" % seed
	var compound: Rect2i = layout.get("rect", Rect2i())
	var gates: Array = layout.get("gates", [])
	var doorways: Array = layout.get("building_doorways", [])
	var rooms: Array = layout.get("rooms", [])
	var perimeter: Dictionary = layout.get("perimeter", {})
	_expect(String(layout.get("layer_id", "")) == "surface", "%s is a surface compound" % tag)
	_expect(not layout.has("layers"), "%s has no subsurface layer" % tag)
	_expect(gates.size() == 2, "%s has exactly two gates" % tag)
	_expect((layout.get("ingress", []) as Array).size() == 2, "%s ingress is exactly the two gates" % tag)
	if gates.size() == 2:
		_expect(String(gates[0]["role"]) == "primary" and String(gates[1]["role"]) == "secondary", "%s gates are primary then secondary" % tag)
		_expect(gates[0]["id"] != gates[1]["id"] and gates[0]["edge"] != gates[1]["edge"], "%s gates are distinct and on different edges" % tag)
		for gate in gates:
			_expect(compound.has_point(gate["cell"]), "%s gate sits on the compound" % tag)
			_expect((gate["cells"] as Array).size() == WALL_THICKNESS + 1, "%s gate corridor crosses the perimeter" % tag)
	_expect(String(perimeter.get("id", "")) == "perimeter_main" and int(perimeter.get("thickness", 0)) == WALL_THICKNESS, "%s exports the perimeter" % tag)
	_expect((perimeter.get("gate_ids", []) as Array).size() == 2, "%s perimeter enumerates its gates" % tag)

	var types := {}
	var ids := {}
	for room in rooms:
		types[String(room.get("type", ""))] = true
		ids[String(room.get("id", ""))] = true
	for required_type in REQUIRED:
		_expect(types.has(required_type), "%s includes %s" % [tag, required_type])
	_expect(doorways.size() == rooms.size(), "%s has one exterior doorway per building" % tag)
	var door_ids := {}
	for doorway in doorways:
		_expect(not door_ids.has(doorway["id"]) and ids.has(doorway["room_id"]), "%s doorway IDs are distinct and reference a building" % tag)
		door_ids[doorway["id"]] = true
		_expect(not _in_rooms(doorway["outside_cell"], rooms), "%s doorway opens onto the yard" % tag)
	var diagnostics: Dictionary = layout.get("diagnostics", {})
	_expect(float(diagnostics.get("yard_ratio", 0.0)) >= 0.22, "%s keeps at least 22 percent open yard" % tag)
	_expect(int(diagnostics.get("gate_count", 0)) == 2, "%s reports its gates" % tag)
	for anchor in ["fabricator_anchor", "construction_zone_anchor", "terminal_anchor"]:
		_expect(layout.get(anchor, Vector2i.ZERO) != Vector2i.ZERO, "%s keeps a valid %s" % [tag, anchor])
	for room in rooms:
		_expect(String(room.get("layer_id", "")) == "surface" and String(room.get("archetype_id", "")) == "walled_yard", "%s room carries Type A identity" % tag)


func _in_rooms(cell: Vector2i, rooms: Array) -> bool:
	for room in rooms:
		if (room["rect"] as Rect2i).has_point(cell):
			return true
	return false


# ---- real runtime -----------------------------------------------------------

func _check_runtime() -> void:
	var first_signature := ""
	for seed in SEEDS:
		var map := await _generate_map(seed)
		var signature := _validate_runtime(map, map.get_level_data(), seed)
		if seed == SEEDS[0]:
			first_signature = signature
		map.queue_free()
		await process_frame
	var repeat := await _generate_map(SEEDS[0])
	_expect(_signature(repeat, repeat.get_level_data()) == first_signature, "seed %d real runtime geometry must be repeatable" % SEEDS[0])
	repeat.queue_free()
	await process_frame


func _generate_map(seed: int) -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.compound_archetype_id = "walled_yard"
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


func _flood(start: Vector2i, walkable: Dictionary, blocked: Dictionary = {}) -> Dictionary:
	var seen := {}
	if not walkable.has(start) or blocked.has(start):
		return seen
	var frontier: Array[Vector2i] = [start]
	seen[start] = true
	var head := 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		for direction in CARDINALS:
			var next_cell: Vector2i = current + direction
			if walkable.has(next_cell) and not seen.has(next_cell) and not blocked.has(next_cell):
				seen[next_cell] = true
				frontier.append(next_cell)
	return seen


func _validate_runtime(map: ProcGenTilemap, data: Dictionary, seed: int) -> String:
	var tag := "runtime seed %d" % seed
	_expect(String(data.get("compound_archetype_id", "")) == "walled_yard", "%s exports the selected archetype" % tag)
	var compound: Rect2i = data.get("compound_rect", Rect2i())
	var perimeter: Dictionary = data.get("compound_perimeter", {})
	var gates: Array = data.get("compound_gates", [])
	var doorways: Array = data.get("compound_building_doorways", [])
	var rooms: Array = data.get("compound_rooms", [])
	_expect(gates.size() == 2 and doorways.size() == rooms.size() and not perimeter.is_empty(), "%s exports perimeter, gates and doorways" % tag)
	_expect((data.get("compound_ingress", []) as Array).size() == 2, "%s ingress is exactly the two gates" % tag)
	_expect(rooms.size() >= 8, "%s keeps every mandatory building" % tag)
	if gates.size() != 2 or rooms.is_empty():
		return ""

	var walkable := _walkable(map)
	var thickness := int(perimeter.get("thickness", WALL_THICKNESS))
	var gate_cells := {}
	for gate in gates:
		for cell in gate["cells"]:
			gate_cells[cell] = true

	# The boundary closes except at the two enumerated gates.
	var open_ring := 0
	for x in range(compound.position.x, compound.end.x):
		for y in range(compound.position.y, compound.end.y):
			var cell := Vector2i(x, y)
			var in_ring := x < compound.position.x + thickness or x >= compound.end.x - thickness \
				or y < compound.position.y + thickness or y >= compound.end.y - thickness
			if in_ring and walkable.has(cell):
				open_ring += 1
				_expect(gate_cells.has(cell), "%s perimeter breached at %s outside the gates" % [tag, cell])
	_expect(open_ring == 2 * thickness, "%s ring opening is exactly two gate corridors, got %d" % [tag, open_ring])

	# Physical crossing: each gate alone admits the outside, and with both shut nothing crosses.
	var outside_starts: Array[Vector2i] = []
	for gate in gates:
		outside_starts.append(gate["cell"] - (gate["inward"] as Vector2i))
	var inside_probe: Vector2i = data.get("compound_terminal_anchor", Vector2i.ZERO)
	var gate_a_cells := {}
	var gate_b_cells := {}
	for cell in gates[0]["cells"]:
		gate_a_cells[cell] = true
	for cell in gates[1]["cells"]:
		gate_b_cells[cell] = true
	for start in outside_starts:
		_expect(walkable.has(start), "%s approach outside a gate is walkable" % tag)
	var via_a := _flood(outside_starts[0], walkable, gate_b_cells)
	var via_b := _flood(outside_starts[1], walkable, gate_a_cells)
	var shut := _flood(outside_starts[0], walkable, _merge(gate_a_cells, gate_b_cells))
	_expect(via_a.has(inside_probe), "%s primary gate alone reaches the compound interior" % tag)
	_expect(via_b.has(inside_probe), "%s secondary gate alone reaches the compound interior" % tag)
	_expect(not shut.has(inside_probe), "%s with both gates shut the interior is unreachable" % tag)

	# Everything inside is reachable from the gates over physical floor.
	var reached := _flood(gates[0]["cells"][0], walkable)
	for gate in gates:
		_expect(reached.has(gate["cells"][0]), "%s both gates join one network" % tag)
	for room in rooms:
		_expect(reached.has(Vector2i((room["rect"] as Rect2i).get_center())), "%s %s is reachable from the gates" % [tag, room.get("id", "room")])
	for doorway in doorways:
		_expect(walkable.has(doorway["cell"]) and reached.has(doorway["outside_cell"]), "%s doorway %s opens onto a reachable yard" % [tag, doorway.get("id", "")])
	for key in ["compound_terminal_anchor", "compound_fabricator_anchor", "compound_construction_zone_anchor"]:
		var anchor: Vector2i = data.get(key, Vector2i.ZERO)
		_expect(walkable.has(anchor) and reached.has(anchor), "%s %s is valid walkable floor" % [tag, key])
	var yard := 0
	for cell in data.get("compound_courtyard_cells", []):
		if walkable.has(cell):
			yard += 1
	var base_inner := compound.grow(-4)
	_expect(float(yard) / float(maxi(1, base_inner.get_area())) >= 0.22, "%s keeps 22 percent walkable open yard" % tag)
	return _signature(map, data)


func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var merged := a.duplicate()
	merged.merge(b)
	return merged


func _signature(map: ProcGenTilemap, data: Dictionary) -> String:
	var walkable := _walkable(map)
	var compound: Rect2i = data.get("compound_rect", Rect2i())
	var cells: Array[Vector2i] = []
	for cell in walkable:
		if compound.has_point(cell):
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
		push_error("compound_walled_yard_smoke failed")
		quit(1)
		return
	print("compound_walled_yard_smoke passed")
	quit()
