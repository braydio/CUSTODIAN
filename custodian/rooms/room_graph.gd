class_name RoomGraph
extends RefCounted

## Defines room connectivity rules for procedural level assembly.

var graph_name: String = ""
var rooms: Dictionary = {}
var connections: Array = []
var seed_overrides: Dictionary = {}

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator = null) -> void:
	_rng = rng if rng else RandomNumberGenerator.new()

func load_from_json_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("[RoomGraph] File not found: " + file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[RoomGraph] Cannot read: " + file_path)
		return false
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_error("[RoomGraph] JSON parse failed: " + file_path)
		return false
	
	var data: Dictionary = json.data
	return load_from_dict(data)

func load_from_dict(data: Dictionary) -> bool:
	graph_name = data.get("graph_name", "unnamed")
	rooms = data.get("rooms", {}).duplicate(true)
	connections = data.get("connections", []).duplicate(true)
	seed_overrides = data.get("seed_overrides", {}).duplicate(true)
	return true

func get_room_config(room_type: String) -> Dictionary:
	return rooms.get(room_type, {})

func get_available_types() -> Array:
	return rooms.keys()

func is_required(room_type: String) -> bool:
	var config := get_room_config(room_type)
	return config.get("required", false)

func get_min_count(room_type: String) -> int:
	var config := get_room_config(room_type)
	return config.get("min_count", 1)

func get_max_count(room_type: String) -> int:
	var config := get_room_config(room_type)
	return config.get("max_count", 1)

func get_template_names(room_type: String) -> Array:
	var config := get_room_config(room_type)
	return config.get("templates", [])

func get_random_count(room_type: String) -> int:
	var min_c := get_min_count(room_type)
	var max_c := get_max_count(room_type)
	if min_c == max_c:
		return min_c
	return _rng.randi_range(min_c, max_c)

func get_random_template(room_type: String) -> String:
	var templates := get_template_names(room_type)
	if templates.is_empty():
		return ""
	return templates[_rng.randi() % templates.size()]

func get_allowed_connections(from_type: String) -> Array:
	var allowed := []
	for conn in connections:
		if conn.get("from") == from_type or conn.get("from") == "any":
			allowed.append(conn)
		elif conn.get("to") == from_type:
			allowed.append({"from": conn.get("to"), "to": conn.get("from"), "direction": _opposite_direction(conn.get("direction", "any"))})
	return allowed

func _opposite_direction(dir: String) -> String:
	match dir:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
		"any": return "any"
		_: return "any"

func validate() -> bool:
	var errors := []
	
	for room_type in rooms.keys():
		var config: Dictionary = rooms.get(room_type, {})
		if config.get("templates", []).is_empty():
			errors.append("Room type '%s' has no templates" % room_type)
	
	for conn in connections:
		var from_type = conn.get("from", "")
		var to_type = conn.get("to", "")
		if from_type != "any" and not rooms.has(from_type):
			errors.append("Connection references unknown room: " + from_type)
		if to_type != "any" and not rooms.has(to_type):
			errors.append("Connection references unknown room: " + to_type)
	
	for room_type in rooms.keys():
		var config: Dictionary = rooms.get(room_type, {})
		if config.get("required", false):
			var min_c: int = int(config.get("min_count", 0))
			if min_c < 1:
				errors.append("Required room '%s' has min_count < 1" % room_type)
	
	if not errors.is_empty():
		for err in errors:
			push_error("[RoomGraph] Validation error: " + err)
		return false
	
	return true
