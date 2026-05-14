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

func set_seed(seed: int) -> void:
	_rng.seed = int(seed)

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
	
	if not (json.data is Dictionary):
		push_error("[RoomGraph] JSON root must be a dictionary: " + file_path)
		return false

	var data := json.data as Dictionary
	return load_from_dict(data)

func load_from_dict(data: Dictionary) -> bool:
	graph_name = String(data.get("graph_name", "unnamed"))

	var rooms_value: Variant = data.get("rooms", {})
	var connections_value: Variant = data.get("connections", [])
	var seed_overrides_value: Variant = data.get("seed_overrides", {})

	if not (rooms_value is Dictionary):
		push_error("[RoomGraph] 'rooms' must be a dictionary")
		return false

	if not (connections_value is Array):
		push_error("[RoomGraph] 'connections' must be an array")
		return false

	if not (seed_overrides_value is Dictionary):
		push_error("[RoomGraph] 'seed_overrides' must be a dictionary")
		return false

	rooms = (rooms_value as Dictionary).duplicate(true)
	connections = (connections_value as Array).duplicate(true)
	seed_overrides = (seed_overrides_value as Dictionary).duplicate(true)

	return validate()

func get_room_config(room_type: String) -> Dictionary:
	return rooms.get(room_type, {})

func get_available_types() -> Array:
	var keys := rooms.keys()
	keys.sort()
	return keys

func is_required(room_type: String) -> bool:
	var config := get_room_config(room_type)
	return config.get("required", false)

func get_min_count(room_type: String) -> int:
	var config := get_room_config(room_type)
	return maxi(0, int(config.get("min_count", 1)))

func get_max_count(room_type: String) -> int:
	var config := get_room_config(room_type)
	var min_c := get_min_count(room_type)
	return maxi(min_c, int(config.get("max_count", min_c)))

func get_template_names(room_type: String) -> Array:
	var config := get_room_config(room_type)
	return config.get("templates", [])

func get_random_count(room_type: String) -> int:
	var min_c := get_min_count(room_type)
	var max_c := get_max_count(room_type)
	if max_c <= min_c:
		return min_c
	return _rng.randi_range(min_c, max_c)

func get_random_template(room_type: String) -> String:
	var templates := get_template_names(room_type)
	if templates.is_empty():
		push_warning("[RoomGraph] Room type has no templates: " + room_type)
		return ""
	var index := _rng.randi_range(0, templates.size() - 1)
	return String(templates[index])

func get_allowed_connections(from_type: String) -> Array:
	var allowed := []
	for conn in connections:
		if not (conn is Dictionary):
			continue
		if conn.get("from") == from_type or conn.get("from") == "any":
			allowed.append(conn)
		elif conn.get("to") == from_type:
			allowed.append({"from": conn.get("to"), "to": conn.get("from"), "direction": _opposite_direction(conn.get("direction", "any"))})
	return allowed

func allows_connection(from_type: String, to_type: String, direction: String = "any") -> bool:
	if connections.is_empty():
		return true

	for conn_variant in connections:
		if not (conn_variant is Dictionary):
			continue

		var conn := conn_variant as Dictionary
		var conn_from := String(conn.get("from", "any"))
		var conn_to := String(conn.get("to", "any"))
		var conn_direction := String(conn.get("direction", "any"))

		var direct_match := (
			(conn_from == "any" or conn_from == from_type)
			and (conn_to == "any" or conn_to == to_type)
			and (conn_direction == "any" or conn_direction == direction)
		)

		if direct_match:
			return true

		var reverse_direction := _opposite_direction(direction)
		var reverse_match := (
			(conn_from == "any" or conn_from == to_type)
			and (conn_to == "any" or conn_to == from_type)
			and (conn_direction == "any" or conn_direction == reverse_direction)
		)

		if reverse_match:
			return true

	return false

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

		var min_c := int(config.get("min_count", 1))
		var max_c := int(config.get("max_count", min_c))

		if min_c < 0:
			errors.append("Room type '%s' has min_count < 0" % room_type)

		if max_c < min_c:
			errors.append("Room type '%s' has max_count < min_count" % room_type)

		if bool(config.get("required", false)) and min_c < 1:
			errors.append("Required room '%s' has min_count < 1" % room_type)

	for conn_variant in connections:
		if not (conn_variant is Dictionary):
			errors.append("Connection entry must be a dictionary")
			continue

		var conn := conn_variant as Dictionary
		var from_type := String(conn.get("from", ""))
		var to_type := String(conn.get("to", ""))
		var direction := String(conn.get("direction", "any"))
		var valid_directions := ["north", "south", "east", "west", "any"]

		if from_type != "any" and not rooms.has(from_type):
			errors.append("Connection references unknown room: " + from_type)

		if to_type != "any" and not rooms.has(to_type):
			errors.append("Connection references unknown room: " + to_type)

		if not valid_directions.has(direction):
			errors.append("Connection has invalid direction: " + direction)
	
	if not errors.is_empty():
		for err in errors:
			push_error("[RoomGraph] Validation error: " + err)
		return false
	
	return true
