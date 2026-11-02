extends SceneTree

const PLANNER := preload("res://game/world/compound/rooms/persistent_compound_layout_planner.gd")
const SEEDS := [1, 2, 3, 10, 42, 99, 1337]
const REQUIRED := ["command_post", "power", "archive", "defense", "storage", "north_transit", "south_transit", "maintenance"]

var _failed := false


func _init() -> void:
	var signatures := {}
	for seed in SEEDS:
		var first := _generate(seed)
		var second := _generate(seed)
		_expect(first == second, "seed %d must be field-equivalent" % seed)
		_validate_layout(first, seed)
		signatures[_signature(first)] = true
	_expect(signatures.size() >= 3, "seven seeds must produce at least three topology signatures")

	var impossible := PLANNER.new().generate_layout(7, Rect2i(0, 0, 20, 16), [])
	_expect(not bool(impossible.get("valid", true)), "impossible required layout must return invalid")
	_finish()


func _generate(seed: int) -> Dictionary:
	var planner := PLANNER.new()
	_expect(planner.load_default_graph(), "persistent graph must load")
	return planner.generate_layout(seed, Rect2i(8, 8, 64, 52), [Vector2i(24, 8), Vector2i(56, 59)])


func _validate_layout(layout: Dictionary, seed: int) -> void:
	_expect(bool(layout.get("valid", false)), "seed %d must produce a valid layout: %s" % [seed, layout.get("diagnostics", {})])
	var rooms: Array = layout.get("rooms", [])
	_expect(rooms.size() >= 10 and rooms.size() <= 13, "seed %d room count must be 10-13" % seed)
	var types := {}
	var sizes := {}
	var zones := {}
	var xs := {}
	var ys := {}
	for room_variant in rooms:
		var room := room_variant as Dictionary
		var rect: Rect2i = room.get("rect", Rect2i())
		types[String(room.get("type", ""))] = true
		sizes[str(rect.size)] = true
		zones[String(room.get("zone", ""))] = true
		xs[int(room.get("center", Vector2i.ZERO).x)] = true
		ys[int(room.get("center", Vector2i.ZERO).y)] = true
		_expect((layout["rect"] as Rect2i).encloses(rect), "seed %d room inside compound" % seed)
	for required_type in REQUIRED:
		_expect(types.has(required_type), "seed %d missing %s" % [seed, required_type])
	_expect(sizes.size() >= 3, "seed %d must have three footprint sizes" % seed)
	_expect(zones.has("core") and zones.has("operational") and zones.has("perimeter"), "seed %d must use all zones" % seed)
	_expect(xs.size() >= 4 or ys.size() >= 4, "seed %d must not reproduce fixed two-column grid" % seed)
	for a in range(rooms.size()):
		for b in range(a + 1, rooms.size()):
			_expect(not (rooms[a]["rect"] as Rect2i).intersects(rooms[b]["rect"]), "seed %d rooms overlap" % seed)
	var diagnostics: Dictionary = layout.get("diagnostics", {})
	_expect(bool(diagnostics.get("connected", false)), "seed %d graph connected" % seed)
	var negative := float(diagnostics.get("negative_space_ratio", -1.0))
	_expect(negative >= 0.22 and negative <= 0.55, "seed %d negative space %.3f in range" % [seed, negative])
	_expect((layout.get("connections", []) as Array).size() >= rooms.size() - 1, "seed %d has connected edge count" % seed)


func _signature(layout: Dictionary) -> String:
	var pieces: Array[String] = []
	for room in layout.get("rooms", []):
		pieces.append("%s:%s" % [room.get("type", ""), room.get("center", Vector2i.ZERO)])
	for connection in layout.get("connections", []):
		pieces.append("%s>%s" % [connection.get("from_room_id", ""), connection.get("to_room_id", "")])
	return "|".join(pieces)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	if _failed:
		push_error("persistent_compound_layout_smoke failed")
		quit(1)
		return
	print("persistent_compound_layout_smoke passed")
	quit()
