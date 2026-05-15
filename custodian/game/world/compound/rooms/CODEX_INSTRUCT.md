
Yes — now that I can see the actual three files, here is the focused review with concrete updates. The three files are:

```txt
room_graph.gd
room_loader.gd
layout_assembler.gd
```

The core problem is that they are close to a usable room-assembly stack, but right now the contract between them is weak: `RoomGraph` defines rules but `LayoutAssembler` barely uses them, `RoomLoader` parses doors too loosely, and `LayoutAssembler` can produce ambiguous room IDs, bad bounds, non-deterministic graph choices, and failed connections even when valid doors exist. 

---

# 1. `room_graph.gd` changes

## 1.1 Add deterministic seed control

Add this after `_init()`:

```gdscript
func set_seed(seed: int) -> void:
	_rng.seed = int(seed)
```

This lets `LayoutAssembler.generate_layout(seed)` seed the graph’s RNG too.

---

## 1.2 Harden JSON root loading

Find this in `load_from_json_file()`:

```gdscript
var data: Dictionary = json.data
return load_from_dict(data)
```

Replace with:

```gdscript
if not (json.data is Dictionary):
	push_error("[RoomGraph] JSON root must be a dictionary: " + file_path)
	return falddsdaawadgs

---

## 1.3 Replace `load_from_dict()`

Replace the whole function:

```gdscript
func load_from_dict(data: Dictionary) -> boolb:
	graph_name = data.get("graph_name", "unnamed")
	rooms = data.get("rooms", {}).duplicate(true)
	connections = data.get("connections", []).duplicate(true)
	seed_overrides = data.get("seed_overrides", {}).duplicate(true)
	return true
```

with:

```gdscript
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
```

---

## 1.4 Make available room types deterministic

Find:

```gdscript
func get_available_types() -> Array:
	return rooms.keys()
```

Replace with:

```gdscript
func get_available_types() -> Array:
	var keys := rooms.keys()
	keys.sort()
	return keys
```

This prevents JSON/dictionary order from subtly changing room assignment order.

---

## 1.5 Replace count getters

Find:

```gdscript
func get_min_count(room_type: String) -> int:
	var config := get_room_config(room_type)
	return config.get("min_count", 1)

func get_max_count(room_type: String) -> int:
	var config := get_room_config(room_type)
	return config.get("max_count", 1)

func get_random_count(room_type: String) -> int:
	var min_c := get_min_count(room_type)
	var max_c := get_max_count(room_type)
	if min_c == max_c:
		return min_c
	return _rng.randi_range(min_c, max_c)
```

Replace with:

```gdscript
func get_min_count(room_type: String) -> int:
	var config := get_room_config(room_type)
	return maxi(0, int(config.get("min_count", 1)))


func get_max_count(room_type: String) -> int:
	var config := get_room_config(room_type)
	var min_c := get_min_count(room_type)
	return maxi(min_c, int(config.get("max_count", min_c)))


func get_random_count(room_type: String) -> int:
	var min_c := get_min_count(room_type)
	var max_c := get_max_count(room_type)

	if max_c <= min_c:
		return min_c

	return _rng.randi_range(min_c, max_c)
```

---

## 1.6 Replace template getter

Find:

```gdscript
func get_random_template(room_type: String) -> String:
	var templates := get_template_names(room_type)
	if templates.is_empty():
		return ""
	return templates[_rng.randi() % templates.size()]
```

Replace with:

```gdscript
func get_random_template(room_type: String) -> String:
	var templates := get_template_names(room_type)
	if templates.is_empty():
		push_warning("[RoomGraph] Room type has no templates: " + room_type)
		return ""

	var index := _rng.randi_range(0, templates.size() - 1)
	return String(templates[index])
```

---

## 1.7 Add graph-rule check API

Add this after `get_allowed_connections()`:

```gdscript
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
```

---

## 1.8 Strengthen `validate()`

Inside `validate()`, find:

```gdscript
for room_type in rooms.keys():
	var config: Dictionary = rooms.get(room_type, {})
	if config.get("templates", []).is_empty():
		errors.append("Room type '%s' has no templates" % room_type)
```

Replace with:

```gdscript
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
```

Then find the connection validation loop:

```gdscript
for conn in connections:
	var from_type = conn.get("from", "")
	var to_type = conn.get("to", "")
```

Replace the whole loop with:

```gdscript
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
```

---

# 2. `room_loader.gd` changes

## 2.1 Add deterministic seed control

Add after `_init()`:

```gdscript
func set_seed(seed: int) -> void:
	_rng.seed = int(seed)
```

---

## 2.2 Make directory loading deterministic

Find:

```gdscript
var loaded_count := 0
dir.list_dir_begin()
var file_name := dir.get_next()
while file_name != "":
	if file_name.ends_with(".tmj"):
		var full_path := directory_path + "/" + file_name
		if _load_single_template(full_path):
			loaded_count += 1
	elif file_name.ends_with(".tmx"):
		push_warning("[RoomLoader] Skipping XML Tiled map; export as .tmj instead: " + directory_path + "/" + file_name)
	file_name = dir.get_next()
dir.list_dir_end()

return loaded_count
```

Replace with:

```gdscript
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
```

---

## 2.3 Harden TMJ JSON root parsing

Find in `_load_single_template()`:

```gdscript
var data: Dictionary = json.data
if not data.has("width") or not data.has("height"):
```

Replace with:

```gdscript
if not (json.data is Dictionary):
	push_warning("[RoomLoader] JSON root must be a dictionary: " + file_path)
	return false

var data := json.data as Dictionary
if not data.has("width") or not data.has("height"):
```

---

## 2.4 Fix `_parse_door_string()` bug

Current `_parse_door_string()` creates `door := {}` inside each comma part and never appends key/value parsed doors. So a string like:

```txt
x:5,y:0,width:2,height:1
```

can return nothing useful.

Replace the whole function:

```gdscript
func _parse_door_string(door_str: String) -> Array:
	var doors := []
	if door_str.is_empty():
		return doors
	
	var trimmed := door_str.strip_edges()
	if trimmed.is_empty():
		return doors

	if trimmed.begins_with("["):
		var json := JSON.new()
		if json.parse(trimmed) == OK and json.data is Array:
			return _normalize_doors(json.data as Array)
	
	var parts := trimmed.split(",")
	for part in parts:
		var kv := part.split(":")
		if kv.size() >= 2:
			var door := {}
			var key := kv[0].strip_edges().to_lower()
			var value := kv[1].strip_edges()
			if key == "x" or key == "y":
				door[key] = int(value)
			elif key == "width" or key == "height":
				door[key] = int(value)
		elif kv.size() == 1:
			var single := kv[0].strip_edges()
			if single.is_valid_int():
				doors.append({"x": int(single), "width": 1})
	
	return doors
```

with:

```gdscript
func _parse_door_string(door_str: String) -> Array:
	var doors: Array = []

	var trimmed := door_str.strip_edges()
	if trimmed.is_empty():
		return doors

	if trimmed.begins_with("["):
		var json := JSON.new()
		if json.parse(trimmed) == OK and json.data is Array:
			return _normalize_doors(json.data as Array)

	# Supports semicolon-separated doors:
	# "x:5,y:0,width:2;height:1,x:10,y:0,width:1"
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
```

---

## 2.5 Replace `_normalize_doors()`

Find:

```gdscript
func _normalize_doors(raw_doors: Array) -> Array:
	var normalized: Array = []
	for raw_door in raw_doors:
		if raw_door is Dictionary:
			var normalized_door := {}
			for key in ["x", "y", "width", "height"]:
				if raw_door.has(key):
					normalized_door[key] = int(raw_door.get(key, 0))
			if not normalized_door.is_empty():
				normalized.append(normalized_door)
	return normalized
```

Replace with:

```gdscript
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
```

---

## 2.6 Return duplicates from template getters

Find:

```gdscript
func get_template(template_name: String) -> Dictionary:
	return _templates.get(template_name, {})

func get_all_templates() -> Dictionary:
	return _templates
```

Replace with:

```gdscript
func get_template(template_name: String) -> Dictionary:
	var template: Variant = _templates.get(template_name, {})
	if template is Dictionary:
		return (template as Dictionary).duplicate(true)
	return {}


func get_all_templates() -> Dictionary:
	return _templates.duplicate(true)
```

This prevents callers from accidentally mutating the loader’s source templates.

---

## 2.7 Improve `can_connect()`

Find:

```gdscript
func can_connect(door_a: Dictionary, door_b: Dictionary) -> bool:
	var width_a = door_a.get("width", 1)
	var width_b = door_b.get("width", 1)
	return abs(width_a - width_b) <= 1
```

Replace with:

```gdscript
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
```

---

# 3. `layout_assembler.gd` changes

## 3.1 Seed all three cooperating systems

Find:

```gdscript
func generate_layout(seed: int) -> Dictionary:
	_rng.seed = int(seed)
	_placed_rooms.clear()
```

Replace with:

```gdscript
func generate_layout(seed: int) -> Dictionary:
	_rng.seed = int(seed)

	if _room_graph != null:
		_room_graph.set_seed(seed)

	if _room_loader != null:
		_room_loader.set_seed(seed)

	_placed_rooms.clear()
```

---

## 3.2 Add null guard at layout start

After `_placed_rooms.clear()`, add:

```gdscript
if _room_loader == null:
	push_error("[LayoutAssembler] Missing RoomLoader")
	return {
		"rooms": [],
		"connections": [],
		"bounds": {"min": Vector2i.ZERO, "max": Vector2i.ZERO},
		"room_count": 0,
		"errors": ["missing_room_loader"],
	}

if _room_graph == null:
	push_error("[LayoutAssembler] Missing RoomGraph")
	return {
		"rooms": [],
		"connections": [],
		"bounds": {"min": Vector2i.ZERO, "max": Vector2i.ZERO},
		"room_count": 0,
		"errors": ["missing_room_graph"],
	}
```

---

## 3.3 Use fixed cell step instead of per-template spacing

Find:

```gdscript
var current_grid_pos := Vector2i.ZERO
var room_instances := []
```

Replace with:

```gdscript
var current_grid_pos := Vector2i.ZERO
var room_instances := []
var layout_cell_step := _calculate_layout_cell_step(room_assignments)
```

Find:

```gdscript
var room_world_position := _grid_to_world(current_grid_pos, template)
```

Replace with:

```gdscript
var room_world_position := _grid_to_world(current_grid_pos, layout_cell_step)
```

Replace `_grid_to_world()`:

```gdscript
func _grid_to_world(grid_pos: Vector2i, template: Dictionary) -> Vector2:
	var room_width: int = int(template.get("width", 10)) * TILE_SIZE
	var room_height: int = int(template.get("height", 10)) * TILE_SIZE
	var spacing := ROOM_SPACING * TILE_SIZE
	
	return Vector2(
		grid_pos.x * (room_width + spacing),
		grid_pos.y * (room_height + spacing)
	)
```

with:

```gdscript
func _grid_to_world(grid_pos: Vector2i, layout_cell_step: Vector2i) -> Vector2:
	return Vector2(
		float(grid_pos.x * layout_cell_step.x),
		float(grid_pos.y * layout_cell_step.y)
	)


func _calculate_layout_cell_step(room_assignments: Array) -> Vector2i:
	var max_width_tiles := 1
	var max_height_tiles := 1

	for assignment_variant in room_assignments:
		if not (assignment_variant is Dictionary):
			continue

		var assignment := assignment_variant as Dictionary
		var template_name := String(assignment.get("template", ""))
		if template_name.is_empty():
			continue

		var template := _room_loader.get_template(template_name)
		if template.is_empty():
			continue

		max_width_tiles = maxi(max_width_tiles, int(template.get("width", 1)))
		max_height_tiles = maxi(max_height_tiles, int(template.get("height", 1)))

	return Vector2i(
		(max_width_tiles + ROOM_SPACING) * TILE_SIZE,
		(max_height_tiles + ROOM_SPACING) * TILE_SIZE
	)
```

---

## 3.4 Add stable room IDs and intensity

Find:

```gdscript
var room_instance: Dictionary = {
	"type": assignment["type"],
	"template": template_name,
```

Replace with:

```gdscript
var room_type := String(assignment["type"])
var room_id := "%s_%02d" % [room_type, room_instances.size()]

var room_instance: Dictionary = {
	"id": room_id,
	"type": room_type,
	"template": template_name,
```

Then inside that same dictionary, after:

```gdscript
"template_family": str(template.get("template_family", "")),
```

add:

```gdscript
"intensity": _estimate_room_intensity(room_type, current_grid_pos),
```

Add this helper near `_generate_room_assignments()`:

```gdscript
func _estimate_room_intensity(room_type: String, grid_pos: Vector2i) -> float:
	var distance_score := clampf(Vector2(grid_pos).length() / 4.0, 0.0, 1.0)
	var type_bonus := 0.0

	var lowered := room_type.to_lower()

	if lowered.contains("combat") or lowered.contains("encounter"):
		type_bonus += 0.20

	if lowered.contains("objective") or lowered.contains("boss") or lowered.contains("exit"):
		type_bonus += 0.35

	if lowered.contains("start") or lowered.contains("spawn") or lowered.contains("entry"):
		type_bonus -= 0.30

	return clampf(distance_score + type_bonus, 0.0, 1.0)
```

---

## 3.5 Keep start/entry rooms early

At the end of `_generate_room_assignments()`, before:

```gdscript
return assignments
```

add:

```gdscript
assignments.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
	return _room_assignment_priority(a) < _room_assignment_priority(b)
)
```

Then add helper:

```gdscript
func _room_assignment_priority(assignment: Dictionary) -> int:
	var room_type := String(assignment.get("type", "")).to_lower()

	if room_type.contains("start") or room_type.contains("spawn") or room_type.contains("entry"):
		return 0

	if room_type.contains("hub") or room_type.contains("safe"):
		return 1

	if room_type.contains("combat") or room_type.contains("encounter"):
		return 5

	if room_type.contains("objective") or room_type.contains("boss") or room_type.contains("exit"):
		return 9

	return 4
```

This preserves some progression after the shuffle.

---

## 3.6 Populate `_placed_rooms`

Find near the end of `generate_layout()`:

```gdscript
layout["rooms"] = room_instances
layout["connections"] = _generate_connections(room_instances)
layout["bounds"] = _calculate_bounds(room_instances)
layout["room_count"] = room_instances.size()

return layout
```

Replace with:

```gdscript
layout["rooms"] = room_instances
layout["connections"] = _generate_connections(room_instances)
layout["bounds"] = _calculate_bounds(room_instances)
layout["room_count"] = room_instances.size()

if layout["connections"].is_empty() and room_instances.size() > 1:
	push_warning("[LayoutAssembler] Generated layout has multiple rooms but no valid connections")

_placed_rooms = room_instances.duplicate(true)

return layout
```

---

## 3.7 Enforce graph connection rules

Find `_make_connection()`:

```gdscript
func _make_connection(room_a: Dictionary, room_b: Dictionary, dir_a: String, dir_b: String) -> Dictionary:
	var doors_a: Array = room_a["doors"].get(dir_a, [])
	var doors_b: Array = room_b["doors"].get(dir_b, [])
```

Replace the top with:

```gdscript
func _make_connection(room_a: Dictionary, room_b: Dictionary, dir_a: String, dir_b: String) -> Dictionary:
	if _room_graph != null:
		if not _room_graph.allows_connection(String(room_a.get("type", "")), String(room_b.get("type", "")), dir_a):
			return {}

	var doors_a: Array = room_a["doors"].get(dir_a, [])
	var doors_b: Array = room_b["doors"].get(dir_b, [])
```

---

## 3.8 Pick any compatible door pair

Find:

```gdscript
var door_a = doors_a[0] if doors_a.size() > 0 else {}
var door_b = doors_b[0] if doors_b.size() > 0 else {}

if not _room_loader.can_connect(door_a, door_b):
	return {}
```

Replace with:

```gdscript
var door_pair := _find_compatible_door_pair(doors_a, doors_b)
if door_pair.is_empty():
	return {}

var door_a: Dictionary = door_pair["from_door"]
var door_b: Dictionary = door_pair["to_door"]
```

Add helper near `_make_connection()`:

```gdscript
func _find_compatible_door_pair(doors_a: Array, doors_b: Array) -> Dictionary:
	var compatible_pairs: Array[Dictionary] = []

	for door_a_variant in doors_a:
		if not (door_a_variant is Dictionary):
			continue

		var door_a := door_a_variant as Dictionary

		for door_b_variant in doors_b:
			if not (door_b_variant is Dictionary):
				continue

			var door_b := door_b_variant as Dictionary

			if _room_loader.can_connect(door_a, door_b):
				compatible_pairs.append({
					"from_door": door_a,
					"to_door": door_b,
				})

	if compatible_pairs.is_empty():
		return {}

	var index := _rng.randi_range(0, compatible_pairs.size() - 1)
	return compatible_pairs[index]
```

---

## 3.9 Return resolved connection endpoint tiles

Replace the return block in `_make_connection()`:

```gdscript
return {
	"from_room": room_a["template"],
	"to_room": room_b["template"],
	"from_direction": dir_a,
	"to_direction": dir_b,
	"from_door": door_a,
	"to_door": door_b,
}
```

with:

```gdscript
var from_tile := _resolve_connection_door_tile(room_a, door_a)
var to_tile := _resolve_connection_door_tile(room_b, door_b)

return {
	"from_room": room_a.get("id", room_a["template"]),
	"to_room": room_b.get("id", room_b["template"]),
	"from_template": room_a["template"],
	"to_template": room_b["template"],
	"from_direction": dir_a,
	"to_direction": dir_b,
	"from_door": door_a,
	"to_door": door_b,
	"from_tile": from_tile,
	"to_tile": to_tile,
}
```

Add helper:

```gdscript
func _resolve_connection_door_tile(room: Dictionary, door: Dictionary) -> Vector2i:
	var room_origin := _world_to_tile_origin(room.get("world_position", Vector2.ZERO))
	var tile_value: Variant = door.get("tile_position", null)

	if tile_value is Vector2i:
		return room_origin + (tile_value as Vector2i)

	var x := int(door.get("x", 0))
	var y := int(door.get("y", 0))
	return room_origin + Vector2i(x, y)
```

---

## 3.10 Replace bounds calculation

Current bounds are grid-cell bounds, not actual assembled tile bounds.

Replace `_calculate_bounds()` entirely:

```gdscript
func _calculate_bounds(room_instances: Array) -> Dictionary:
	if room_instances.is_empty():
		return {"min": Vector2i.ZERO, "max": Vector2i.ZERO, "size": Vector2i.ZERO}

	var min_pos := Vector2i(999999, 999999)
	var max_pos := Vector2i(-999999, -999999)

	for room_variant in room_instances:
		if not (room_variant is Dictionary):
			continue

		var room := room_variant as Dictionary
		var world: Vector2 = room.get("world_position", Vector2.ZERO)
		var origin := _world_to_tile_origin(world)
		var size := Vector2i(
			int(room.get("width", 0)),
			int(room.get("height", 0))
		)

		min_pos.x = mini(min_pos.x, origin.x)
		min_pos.y = mini(min_pos.y, origin.y)
		max_pos.x = maxi(max_pos.x, origin.x + size.x)
		max_pos.y = maxi(max_pos.y, origin.y + size.y)

	return {
		"min": min_pos,
		"max": max_pos,
		"size": max_pos - min_pos,
	}
```

---

# 4. Bigger design issue: layout is still “grid adjacency,” not real graph assembly

Even after these fixes, `LayoutAssembler` still places rooms in a 3-column grid and only connects grid-adjacent rooms. That is acceptable as a first pass, but not a strong EDGAR-style assembler yet.

The next upgrade would be:

```txt
required rooms first
place start/entry at origin
walk graph connections outward
choose compatible templates per required direction
place rooms based on door alignment, not fixed grid cells
only use fallback grid if graph placement fails
```

I would not do that until the above contract fixes are in, because door parsing and connection validation need to be reliable first.

---

# 5. Priority order

Do these in this order:

1. `RoomLoader._parse_door_string()` fix.
2. `RoomLoader._normalize_doors()` upgrade.
3. `RoomLoader.can_connect()` upgrade.
4. `RoomGraph.set_seed()` and validation hardening.
5. `RoomGraph.allows_connection()`.
6. `LayoutAssembler.generate_layout()` seeds all systems.
7. `LayoutAssembler` fixed layout cell spacing.
8. Stable room IDs.
9. Compatible door pair selection.
10. Resolved connection endpoint tiles.
11. Bounds calculation.
12. `_placed_rooms` population.

Documentation drift note: after applying these, update the procgen/AI context docs to say room assembly now uses deterministic room graph seeding, normalized door metadata, graph-rule-enforced connections, compatible door-pair selection, stable room IDs, resolved connection endpoint tiles, and actual assembled tile bounds.
