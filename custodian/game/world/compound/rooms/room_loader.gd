class_name RoomLoader
extends RefCounted

## Loads Tiled room templates and parses door metadata for Edgar-style generation.

const TILE_SIZE := 32
const SUPPORTED_TEMPLATE_EXTENSION := ".tmj"
const MARKER_LAYER_NAME := "Markers"
const DOOR_DIRECTIONS := ["north", "south", "east", "west"]

var _templates: Dictionary = {}
var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator = null) -> void:
	_rng = rng if rng else RandomNumberGenerator.new()

func set_seed(seed: int) -> void:
	_rng.seed = int(seed)

func load_templates_from_directory(directory_path: String) -> int:
	var dir := DirAccess.open(directory_path)
	if dir == null:
		push_error("[RoomLoader] Cannot open directory: " + directory_path)
		return 0
	
	var file_names: Array[String] = []

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			file_names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	file_names.sort()

	var loaded_count := 0
	for sorted_file_name in file_names:
		if sorted_file_name.ends_with(".tmj"):
			var full_path := directory_path.path_join(sorted_file_name)
			if _load_single_template(full_path):
				loaded_count += 1
		elif sorted_file_name.ends_with(".tmx"):
			push_warning("[RoomLoader] Skipping XML Tiled map; export as .tmj instead: " + directory_path.path_join(sorted_file_name))
	
	return loaded_count

func _load_single_template(file_path: String) -> bool:
	if not file_path.ends_with(SUPPORTED_TEMPLATE_EXTENSION):
		push_warning("[RoomLoader] Unsupported Tiled format; export as .tmj instead: " + file_path)
		return false
	if not FileAccess.file_exists(file_path):
		push_warning("[RoomLoader] Template not found: " + file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_warning("[RoomLoader] Cannot read file: " + file_path)
		return false
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_warning("[RoomLoader] JSON parse failed: " + file_path)
		return false
	
	if not (json.data is Dictionary):
		push_warning("[RoomLoader] JSON root must be a dictionary: " + file_path)
		return false

	var data := json.data as Dictionary
	if not data.has("width") or not data.has("height"):
		push_warning("[RoomLoader] Invalid Tiled map (missing dimensions): " + file_path)
		return false
	
	var template_name := file_path.get_file().get_basename()
	var properties := _parse_property_list(data.get("properties", []))
	var doors := _parse_doors_from_properties(properties)
	var object_layers := _parse_object_layers(data)
	var markers := _collect_markers(object_layers)
	var stairs := _collect_stairs(markers)
	
	var template := {
		"name": template_name,
		"path": file_path,
		"width": int(data["width"]),
		"height": int(data["height"]),
		"tile_width": int(data.get("tilewidth", TILE_SIZE)),
		"tile_height": int(data.get("tileheight", TILE_SIZE)),
		"doors_north": doors.get("doors_north", []),
		"doors_south": doors.get("doors_south", []),
		"doors_east": doors.get("doors_east", []),
		"doors_west": doors.get("doors_west", []),
		"room_type": doors.get("room_type", "generic"),
		"min_players": doors.get("min_players", 1),
		"max_players": doors.get("max_players", 4),
		"floor_index": int(properties.get("floor_index", 0)),
		"template_family": str(properties.get("template_family", "")),
		"properties": properties,
		"tiles": _parse_tiles(data),
		"layers": _parse_layers(data),
		"object_layers": object_layers,
		"markers": markers,
		"stairs": stairs,
		"player_spawn": _first_marker_tile(markers, "player_spawn"),
		"terminal_marker": _first_marker_tile(markers, "terminal"),
		"enemy_spawns": _collect_marker_tiles(markers, "enemy_spawn"),
		"turret_mounts": _collect_marker_tiles(markers, "turret_mount"),
	}
	
	_templates[template_name] = template
	return true

func _parse_property_list(properties: Array) -> Dictionary:
	var result := {}
	for prop in properties:
		if prop is Dictionary:
			var prop_name: String = prop.get("name", "")
			if prop_name.is_empty():
				continue
			result[prop_name] = prop.get("value")
	return result

func _parse_doors_from_properties(properties: Dictionary) -> Dictionary:
	var result := {}
	for direction in DOOR_DIRECTIONS:
		var door_key: String = "doors_" + str(direction)
		result[door_key] = _parse_door_value(properties.get(door_key, []))
	for key in ["room_type", "min_players", "max_players"]:
		if properties.has(key):
			result[key] = properties[key]
	return result

func _parse_door_value(raw_value: Variant) -> Array:
	if raw_value is Array:
		return _normalize_doors(raw_value as Array)
	if raw_value is String:
		return _parse_door_string(raw_value as String)
	return []

func _parse_door_string(door_str: String) -> Array:
	var doors: Array = []
	var trimmed := door_str.strip_edges()
	if trimmed.is_empty():
		return doors

	if trimmed.begins_with("["):
		var json := JSON.new()
		if json.parse(trimmed) == OK and json.data is Array:
			return _normalize_doors(json.data as Array)

	var door_chunks := trimmed.split(";")
	for chunk in door_chunks:
		var door := {}
		var parts := chunk.split(",")

		for part in parts:
			var kv := part.split(":")
			if kv.size() >= 2:
				var key := kv[0].strip_edges().to_lower()
				var value := kv[1].strip_edges()

				if key == "x" or key == "y" or key == "width" or key == "height" or key == "elevation":
					if value.is_valid_int():
						door[key] = int(value)
				elif key == "kind" or key == "type" or key == "lock" or key == "required_key":
					door[key] = value
			elif kv.size() == 1:
				var single := kv[0].strip_edges()
				if single.is_valid_int():
					door["x"] = int(single)

		if not door.is_empty():
			if not door.has("width"):
				door["width"] = 1
			if not door.has("height"):
				door["height"] = 1
			doors.append(door)

	return _normalize_doors(doors)

func _normalize_doors(raw_doors: Array) -> Array:
	var normalized: Array = []
	for raw_door in raw_doors:
		if not (raw_door is Dictionary):
			continue

		var source := raw_door as Dictionary
		var normalized_door := {}
		var x := int(source.get("x", 0))
		var y := int(source.get("y", 0))
		var width := maxi(1, int(source.get("width", 1)))
		var height := maxi(1, int(source.get("height", 1)))

		normalized_door["x"] = x
		normalized_door["y"] = y
		normalized_door["width"] = width
		normalized_door["height"] = height
		normalized_door["tile_position"] = Vector2i(x, y)

		for key in ["kind", "type", "lock", "required_key"]:
			if source.has(key):
				normalized_door[key] = String(source.get(key, ""))

		if source.has("elevation"):
			normalized_door["elevation"] = int(source.get("elevation", 0))

		normalized.append(normalized_door)
	return normalized

func _parse_tiles(data: Dictionary) -> Dictionary:
	var tiles := {}
	for layer in data.get("layers", []):
		if layer.get("type") == "tilelayer":
			var layer_name: String = layer.get("name", "unknown")
			tiles[layer_name] = layer.get("data", [])
	return tiles

func _parse_layers(data: Dictionary) -> Array:
	var layers_info := []
	for layer in data.get("layers", []):
		layers_info.append({
			"name": layer.get("name", ""),
			"type": layer.get("type", ""),
			"visible": layer.get("visible", true),
			"opacity": float(layer.get("opacity", 1.0)),
		})
	return layers_info

func _parse_object_layers(data: Dictionary) -> Array:
	var tile_width := int(data.get("tilewidth", TILE_SIZE))
	var tile_height := int(data.get("tileheight", TILE_SIZE))
	var object_layers: Array = []
	for layer in data.get("layers", []):
		if layer.get("type") != "objectgroup":
			continue
		var objects: Array = []
		for raw_object in layer.get("objects", []):
			if raw_object is Dictionary:
				objects.append(_parse_object_entry(raw_object, tile_width, tile_height))
		object_layers.append({
			"name": str(layer.get("name", "")),
			"visible": bool(layer.get("visible", true)),
			"opacity": float(layer.get("opacity", 1.0)),
			"properties": _parse_property_list(layer.get("properties", [])),
			"objects": objects,
		})
	return object_layers

func _parse_object_entry(raw_object: Dictionary, map_tile_width: int, map_tile_height: int) -> Dictionary:
	var object_width := float(raw_object.get("width", map_tile_width))
	var object_height := float(raw_object.get("height", map_tile_height))
	var pixel_x := float(raw_object.get("x", 0.0))
	var pixel_y := float(raw_object.get("y", 0.0))
	var tile_x := int(floor(pixel_x / max(1, map_tile_width)))
	var tile_y := int(floor(pixel_y / max(1, map_tile_height)))
	return {
		"id": int(raw_object.get("id", -1)),
		"name": str(raw_object.get("name", "")).strip_edges(),
		"type": str(raw_object.get("type", "")).strip_edges(),
		"pixel_position": Vector2(pixel_x, pixel_y),
		"tile_position": Vector2i(tile_x, tile_y),
		"size_pixels": Vector2(object_width, object_height),
		"size_tiles": Vector2i(
			max(1, int(ceil(object_width / max(1.0, float(map_tile_width))))),
			max(1, int(ceil(object_height / max(1.0, float(map_tile_height)))))
		),
		"point": bool(raw_object.get("point", false)),
		"rotation": float(raw_object.get("rotation", 0.0)),
		"properties": _parse_property_list(raw_object.get("properties", [])),
	}

func _collect_markers(object_layers: Array) -> Array:
	var markers: Array = []
	for object_layer in object_layers:
		var layer_name := str(object_layer.get("name", ""))
		for object_entry in object_layer.get("objects", []):
			var marker: Dictionary = (object_entry as Dictionary).duplicate(true)
			var marker_type := str(marker.get("type", "")).strip_edges().to_lower()
			if marker_type.is_empty():
				marker_type = str(marker.get("name", "")).strip_edges().to_lower()
			marker["marker_type"] = marker_type
			marker["layer"] = layer_name
			markers.append(marker)
	return markers

func _collect_stairs(markers: Array) -> Array:
	var stairs: Array = []
	for marker in markers:
		var marker_type := str(marker.get("marker_type", ""))
		if marker_type != "stairs_up" and marker_type != "stairs_down":
			continue
		var stair: Dictionary = (marker as Dictionary).duplicate(true)
		var stair_properties: Dictionary = stair.get("properties", {})
		stair["direction"] = "up" if marker_type == "stairs_up" else "down"
		stair["stair_id"] = str(stair_properties.get("stair_id", stair.get("name", "")))
		stair["target_template"] = str(stair_properties.get("target_template", ""))
		stair["target_stair_id"] = str(stair_properties.get("target_stair_id", ""))
		stair["target_floor"] = int(stair_properties.get("target_floor", 0))
		stairs.append(stair)
	return stairs

func _first_marker_tile(markers: Array, marker_type: String) -> Variant:
	for marker in markers:
		if str(marker.get("marker_type", "")) == marker_type:
			return marker.get("tile_position", Vector2i.ZERO)
	return null

func _collect_marker_tiles(markers: Array, marker_type: String) -> Array:
	var tiles: Array = []
	for marker in markers:
		if str(marker.get("marker_type", "")) == marker_type:
			tiles.append(marker.get("tile_position", Vector2i.ZERO))
	return tiles

func get_template(template_name: String) -> Dictionary:
	var template: Variant = _templates.get(template_name, {})
	if template is Dictionary:
		return (template as Dictionary).duplicate(true)
	return {}

func get_all_templates() -> Dictionary:
	return _templates.duplicate(true)

func get_templates_by_type(room_type: String) -> Array:
	var result := []
	for template in _templates.values():
		if template.get("room_type") == room_type:
			result.append(template)
	return result

func get_random_template_by_type(room_type: String) -> Dictionary:
	var candidates := get_templates_by_type(room_type)
	if candidates.is_empty():
		return {}
	return candidates[_rng.randi() % candidates.size()]

func get_template_dimensions(template_name: String) -> Vector2i:
	var template := get_template(template_name)
	if template.is_empty():
		return Vector2i.ZERO
	return Vector2i(template.get("width", 0), template.get("height", 0))

func has_doors(template_name: String, direction: String) -> bool:
	var template := get_template(template_name)
	if template.is_empty():
		return false
	var door_key := "doors_" + direction.to_lower()
	return not template.get(door_key, []).is_empty()

func get_doors(template_name: String, direction: String) -> Array:
	var template := get_template(template_name)
	if template.is_empty():
		return []
	var door_key := "doors_" + direction.to_lower()
	return template.get(door_key, [])

func can_connect(door_a: Dictionary, door_b: Dictionary) -> bool:
	if door_a.is_empty() or door_b.is_empty():
		return false

	var width_a := int(door_a.get("width", 1))
	var width_b := int(door_b.get("width", 1))
	var height_a := int(door_a.get("height", 1))
	var height_b := int(door_b.get("height", 1))

	if abs(width_a - width_b) > 1:
		return false

	if abs(height_a - height_b) > 1:
		return false

	var kind_a := String(door_a.get("kind", door_a.get("type", "standard")))
	var kind_b := String(door_b.get("kind", door_b.get("type", "standard")))

	if kind_a != "any" and kind_b != "any" and kind_a != kind_b:
		return false

	var elevation_a := int(door_a.get("elevation", 0))
	var elevation_b := int(door_b.get("elevation", 0))

	if abs(elevation_a - elevation_b) > 1:
		return false

	var required_key_a := String(door_a.get("required_key", ""))
	var required_key_b := String(door_b.get("required_key", ""))

	if not required_key_a.is_empty() and not required_key_b.is_empty() and required_key_a != required_key_b:
		return false

	return true
