extends Node

signal toggled(enabled: bool)
signal event_logged(kind: StringName, data: Dictionary)
signal warning_logged(message: String, data: Dictionary)

const OVERLAY_SCENE_PATH := "res://scenes/debug/dev_observatory_overlay.tscn"
const INPUT_ACTION := "debug_observatory"
const EXPORT_INPUT_ACTION := "debug_observatory_export"
const DEFAULT_EXPORT_DIR := "user://dev_observatory"
const DEFAULT_EXPORT_PATH := "user://dev_observatory/latest_session.json"

@export var max_events := 300
@export var sample_interval := 0.25
@export var auto_create_overlay := true

var enabled := false
var events: Array[Dictionary] = []
var total_events_logged := 0
var dropped_event_count := 0
var counters: Dictionary = {}
var gauges: Dictionary = {}
var warnings: Array[Dictionary] = []
var last_export_path := ""
var last_export_absolute_path := ""
var last_export_time := ""
var last_export_error := ""

var _sample_accum := 0.0
var _overlay: CanvasLayer = null
var _boot_time_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_boot_time_msec = Time.get_ticks_msec()
	_ensure_input_actions()

	if auto_create_overlay:
		_create_overlay()

	log_event(&"observatory_ready", {
		"overlay_scene": OVERLAY_SCENE_PATH,
		"input_action": INPUT_ACTION
	})


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(INPUT_ACTION):
		toggle()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(EXPORT_INPUT_ACTION):
		export_timestamped_session_json()
		get_viewport().set_input_as_handled()
		return


func _process(delta: float) -> void:
	_sample_accum += delta
	if _sample_accum >= sample_interval:
		_sample_accum = 0.0
		_sample_runtime_gauges()


func toggle() -> void:
	set_enabled(!enabled)


func set_enabled(value: bool) -> void:
	if enabled == value:
		return

	enabled = value

	if _overlay != null:
		_overlay.visible = enabled

	toggled.emit(enabled)
	log_event(&"observatory_toggled", {"enabled": enabled})


func log_event(kind: StringName, data: Dictionary = {}) -> void:
	total_events_logged += 1
	var entry := {
		"time_msec": Time.get_ticks_msec(),
		"uptime_sec": get_uptime_sec(),
		"kind": kind,
		"data": data
	}

	events.append(entry)

	while events.size() > max_events:
		events.pop_front()
		dropped_event_count += 1

	event_logged.emit(kind, data)


func increment(name: StringName, amount: int = 1) -> void:
	counters[name] = int(counters.get(name, 0)) + amount


func accumulate(name: StringName, amount: float) -> void:
	counters[name] = float(counters.get(name, 0.0)) + amount


func set_counter(name: StringName, value: int) -> void:
	counters[name] = value


func set_gauge(name: StringName, value: Variant) -> void:
	gauges[name] = value


func mark_warning(message: String, data: Dictionary = {}) -> void:
	var entry := {
		"time_msec": Time.get_ticks_msec(),
		"uptime_sec": get_uptime_sec(),
		"message": message,
		"data": data
	}

	warnings.append(entry)

	while warnings.size() > 100:
		warnings.pop_front()

	increment(&"warnings")
	log_event(&"warning", {
		"message": message,
		"data": data
	})

	warning_logged.emit(message, data)


func clear() -> void:
	events.clear()
	total_events_logged = 0
	dropped_event_count = 0
	counters.clear()
	gauges.clear()
	warnings.clear()
	log_event(&"observatory_cleared")


func get_recent_events(limit: int = 20, kind_filter: StringName = &"") -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	for i in range(events.size() - 1, -1, -1):
		var event_entry: Dictionary = events[i]
		if kind_filter == &"" or event_entry.get("kind", &"") == kind_filter:
			out.append(event_entry)

		if out.size() >= limit:
			break

	return out


func get_recent_warnings(limit: int = 10) -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	for i in range(warnings.size() - 1, -1, -1):
		out.append(warnings[i])
		if out.size() >= limit:
			break

	return out


func get_uptime_sec() -> float:
	return float(Time.get_ticks_msec() - _boot_time_msec) / 1000.0


func get_summary() -> Dictionary:
	return {
		"enabled": enabled,
		"uptime_sec": get_uptime_sec(),
		"event_count": events.size(),
		"event_capacity": max_events,
		"total_events_logged": total_events_logged,
		"dropped_event_count": dropped_event_count,
		"event_buffer_saturated": dropped_event_count > 0,
		"counter_count": counters.size(),
		"gauge_count": gauges.size(),
		"warning_count": warnings.size(),
		"counters": counters,
		"gauges": gauges,
		"recent_events": get_recent_events(12),
		"recent_warnings": get_recent_warnings(5)
	}


func export_session_json(path: String = DEFAULT_EXPORT_PATH) -> String:
	var resolved_path := path.strip_edges()
	if resolved_path.is_empty():
		resolved_path = DEFAULT_EXPORT_PATH

	if not _ensure_parent_dir(resolved_path):
		last_export_error = "Could not create parent directory for %s" % resolved_path
		mark_warning("Developer Observatory export failed: could not create parent directory.", {
			"path": resolved_path,
		})
		return ""

	var payload := _build_export_payload(resolved_path)
	var file := FileAccess.open(resolved_path, FileAccess.WRITE)
	if file == null:
		var error_code := FileAccess.get_open_error()
		last_export_error = "Could not open %s (error %s)" % [resolved_path, error_code]
		mark_warning("Developer Observatory export failed: could not open file.", {
			"path": resolved_path,
			"error": error_code,
		})
		return ""

	file.store_string(JSON.stringify(payload, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_export_error = "Could not write %s (error %s)" % [resolved_path, write_error]
		mark_warning("Developer Observatory export failed: could not write file.", {
			"path": resolved_path,
			"error": write_error,
		})
		return ""

	last_export_path = resolved_path
	last_export_absolute_path = ProjectSettings.globalize_path(resolved_path)
	last_export_time = Time.get_datetime_string_from_system(false, true)
	last_export_error = ""
	log_event(&"observatory_session_exported", {
		"path": resolved_path,
		"absolute_path": last_export_absolute_path,
		"event_count": events.size(),
		"warning_count": warnings.size(),
		"counter_count": counters.size(),
		"gauge_count": gauges.size(),
	})
	print("[DevObservatory] Session exported: %s" % last_export_absolute_path)

	return resolved_path


func export_timestamped_session_json() -> String:
	var stamp := Time.get_datetime_string_from_system(false, true)
	stamp = stamp.replace("-", "")
	stamp = stamp.replace(":", "")
	stamp = stamp.replace("T", "_")
	stamp = stamp.replace(" ", "_")

	var timestamped_path := "%s/session_%s.json" % [DEFAULT_EXPORT_DIR, stamp]
	var exported_path := export_session_json(timestamped_path)

	if not exported_path.is_empty():
		# Keep one stable path available for tools without directory discovery.
		export_session_json(DEFAULT_EXPORT_PATH)
		last_export_path = exported_path
		last_export_absolute_path = ProjectSettings.globalize_path(exported_path)

	return exported_path


func _build_export_payload(path: String) -> Dictionary:
	var scene_name := ""
	var scene_path := ""

	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		scene_name = tree.current_scene.name
		scene_path = tree.current_scene.scene_file_path

	return {
		"schema": "custodian.dev_observatory.session.v1",
		"exported_at": Time.get_datetime_string_from_system(false, true),
		"export_path": path,
		"metadata": {
			"project_name": ProjectSettings.get_setting("application/config/name", "CUSTODIAN"),
			"project_version": ProjectSettings.get_setting("application/config/version", ""),
		},
		"engine": {
			"version": _json_safe(Engine.get_version_info()),
			"frames_per_second": Engine.get_frames_per_second(),
			"time_scale": Engine.time_scale,
		},
		"session": {
			"uptime_sec": get_uptime_sec(),
			"boot_time_msec": _boot_time_msec,
			"event_count": events.size(),
			"event_capacity": max_events,
			"total_events_logged": total_events_logged,
			"dropped_event_count": dropped_event_count,
			"event_buffer_saturated": dropped_event_count > 0,
			"counter_count": counters.size(),
			"gauge_count": gauges.size(),
			"warning_count": warnings.size(),
			"observatory_enabled": enabled,
		},
		"scene": {
			"name": scene_name,
			"path": scene_path,
		},
		"counters": _json_safe(counters),
		"gauges": _json_safe(gauges),
		"warnings": _json_safe(warnings),
		"events": _json_safe(events),
	}


func _json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL:
			return null
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_STRING_NAME, TYPE_NODE_PATH:
			return String(value)
		TYPE_VECTOR2:
			var v := value as Vector2
			return {"x": v.x, "y": v.y}
		TYPE_VECTOR2I:
			var v := value as Vector2i
			return {"x": v.x, "y": v.y}
		TYPE_VECTOR3:
			var v := value as Vector3
			return {"x": v.x, "y": v.y, "z": v.z}
		TYPE_VECTOR3I:
			var v := value as Vector3i
			return {"x": v.x, "y": v.y, "z": v.z}
		TYPE_RECT2:
			var r := value as Rect2
			return {
				"position": _json_safe(r.position),
				"size": _json_safe(r.size),
			}
		TYPE_RECT2I:
			var r := value as Rect2i
			return {
				"position": _json_safe(r.position),
				"size": _json_safe(r.size),
			}
		TYPE_COLOR:
			var c := value as Color
			return {
				"r": c.r,
				"g": c.g,
				"b": c.b,
				"a": c.a,
				"html": c.to_html(true),
			}
		TYPE_ARRAY:
			var out: Array = []
			for item in value:
				out.append(_json_safe(item))
			return out
		TYPE_DICTIONARY:
			var out := {}
			var dict := value as Dictionary
			for key in dict.keys():
				out[str(key)] = _json_safe(dict[key])
			return out
		TYPE_OBJECT:
			var object := value as Object
			if object == null:
				return null
			if object is Node:
				var node := object as Node
				return {
					"node_name": node.name,
					"node_path": str(node.get_path()) if node.is_inside_tree() else "",
					"class": node.get_class(),
				}
			return str(value)
		_:
			return str(value)


func _ensure_parent_dir(path: String) -> bool:
	var base_dir := path.get_base_dir()
	if base_dir.is_empty():
		return true

	var absolute_dir := ProjectSettings.globalize_path(base_dir)
	var result := DirAccess.make_dir_recursive_absolute(absolute_dir)
	return result == OK or DirAccess.dir_exists_absolute(absolute_dir)


func _sample_runtime_gauges() -> void:
	set_gauge(&"fps", Engine.get_frames_per_second())
	set_gauge(&"uptime_sec", snappedf(get_uptime_sec(), 0.01))

	var tree := get_tree()
	if tree == null:
		return

	var node_stats := _collect_node_stats(tree.root)
	for stat_name in node_stats.keys():
		set_gauge(StringName(str(stat_name)), node_stats[stat_name])

	var enemies := _get_unique_group_nodes(["enemy", "enemies"])
	set_gauge(&"active_enemies", enemies.size())
	var director_agents := tree.get_nodes_in_group("enemy_behavior_agent").size()
	set_gauge(&"director_behavior_agents", director_agents)
	set_gauge(&"legacy_combat_agents", maxi(0, enemies.size() - director_agents))
	set_gauge(&"ambient_critters", tree.get_nodes_in_group("ambient_critter").size())
	set_gauge(&"active_projectiles", _count_active_projectiles(tree))
	_sample_player_gauges(tree)
	_sample_enemy_gauges(enemies)


func _sample_player_gauges(tree: SceneTree) -> void:
	var player := tree.get_first_node_in_group("player")
	if player == null:
		return

	if player is Node2D:
		var p := player as Node2D
		set_gauge(&"player_position", Vector2i(roundi(p.global_position.x), roundi(p.global_position.y)))

	if player.has_method("get_health"):
		set_gauge(&"player_health", float(player.call("get_health")))
	elif "current_health" in player:
		set_gauge(&"player_health", float(player.get("current_health")))

	if player.has_method("get_max_health"):
		set_gauge(&"player_max_health", float(player.call("get_max_health")))
	elif "max_health" in player:
		set_gauge(&"player_max_health", float(player.get("max_health")))

	if player.has_method("get_sprint_status"):
		var sprint_status: Variant = player.call("get_sprint_status")
		if sprint_status is Dictionary:
			var status := sprint_status as Dictionary
			set_gauge(&"player_stamina", float(status.get("stamina", 0.0)))
			set_gauge(&"player_stamina_max", float(status.get("stamina_max", 0.0)))
			set_gauge(&"player_sprinting", bool(status.get("is_sprinting", false)))

	if player.has_method("get_field_patch_status"):
		var patch_status: Variant = player.call("get_field_patch_status")
		if patch_status is Dictionary:
			var status := patch_status as Dictionary
			set_gauge(&"field_patches_remaining", int(status.get("count", 0)))
			set_gauge(&"field_patches_max", int(status.get("max", 0)))
			set_gauge(&"field_patch_active", bool(status.get("active", false)))

	if player.has_method("get_weapon_status"):
		var weapon_status: Variant = player.call("get_weapon_status")
		if weapon_status is Dictionary:
			var status := weapon_status as Dictionary
			set_gauge(&"player_loaded_ammo", int(status.get("loaded_ammo", 0)))
			set_gauge(&"player_reserve_ammo", int(status.get("reserve_ammo", 0)))
			set_gauge(&"player_active_weapon_id", String(status.get("active_weapon_id", "")))
			set_gauge(&"player_active_weapon_state_key", String(status.get("active_weapon_state_key", "")))
			set_gauge(&"player_magazine_capacity", int(status.get("magazine_size", 0)))
			set_gauge(&"player_ammo_per_shot", int(status.get("ammo_per_shot", 0)))
			set_gauge(&"player_weapon_heat", float(status.get("heat", 0.0)))
			set_gauge(&"player_weapon_overheated", bool(status.get("overheated", false)))


func _sample_enemy_gauges(enemies: Array) -> void:
	var legacy_sample: Dictionary = {}
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.is_in_group("enemy_behavior_agent") and enemy.has_method("get_behavior_snapshot"):
			var snapshot: Variant = enemy.call("get_behavior_snapshot")
			if snapshot is Dictionary:
				set_gauge(&"enemy_behavior_sample", snapshot)
				return
		elif legacy_sample.is_empty() and enemy.has_method("get_behavior_snapshot"):
			var snapshot: Variant = enemy.call("get_behavior_snapshot")
			if snapshot is Dictionary:
				legacy_sample = snapshot
	if not legacy_sample.is_empty():
		set_gauge(&"legacy_enemy_sample", legacy_sample)


func _get_unique_group_nodes(group_names: Array) -> Array:
	var tree := get_tree()
	if tree == null:
		return []
	var seen := {}
	var out: Array = []
	for group_name in group_names:
		for node in tree.get_nodes_in_group(StringName(str(group_name))):
			if node == null or not is_instance_valid(node):
				continue
			var id := node.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			out.append(node)
	return out


func _count_active_projectiles(tree: SceneTree) -> int:
	var projectiles := tree.get_nodes_in_group("projectiles")
	if projectiles.size() > 0:
		return projectiles.size()
	var projectile_root := get_node_or_null("/root/GameRoot/World/Projectiles")
	if projectile_root == null:
		return 0
	return projectile_root.get_child_count()


func _count_nodes(root_node: Node) -> int:
	var count := 1
	for child in root_node.get_children():
		count += _count_nodes(child)
	return count


func _collect_node_stats(root_node: Node) -> Dictionary:
	var stats := {
		"node_count": 0,
		"node_count_world": 0,
		"node_count_procgen": 0,
		"node_count_props": 0,
		"node_count_collision": 0,
		"node_count_vfx": 0,
		"node_count_ui": 0,
		"physics_body_count": 0,
		"collision_shape_count": 0,
		"collision_shape_count_runtime_walls": 0,
		"collision_shape_count_foliage": 0,
		"collision_shape_count_ruin_props": 0,
		"collision_shape_count_enemies": 0,
		"collision_shape_count_projectiles": 0,
		"physics_body_count_runtime_walls": 0,
		"physics_body_count_foliage": 0,
		"physics_body_count_ruin_props": 0,
		"process_enabled_node_count": 0,
		"physics_process_enabled_node_count": 0,
	}
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stats["node_count"] += 1
		var path := str(node.get_path()).to_lower()
		if path.begins_with("/root/gameroot/world"):
			stats["node_count_world"] += 1
		if "procgen" in path or node.is_in_group("procgen_walkability_provider"):
			stats["node_count_procgen"] += 1
		if "prop" in path or node.is_in_group("runtime_prop"):
			stats["node_count_props"] += 1
		if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
			stats["node_count_collision"] += 1
		if node is CollisionShape2D or node is CollisionPolygon2D:
			stats["collision_shape_count"] += 1
			var shape_category := _get_collision_owner_category(node)
			if shape_category == &"runtime_walls":
				stats["collision_shape_count_runtime_walls"] += 1
			elif shape_category == &"foliage":
				stats["collision_shape_count_foliage"] += 1
			elif shape_category == &"ruin_props":
				stats["collision_shape_count_ruin_props"] += 1
			elif shape_category == &"enemies":
				stats["collision_shape_count_enemies"] += 1
			elif shape_category == &"projectiles":
				stats["collision_shape_count_projectiles"] += 1
		if node is PhysicsBody2D:
			stats["physics_body_count"] += 1
			var body_category := _get_collision_owner_category(node)
			if body_category == &"runtime_walls":
				stats["physics_body_count_runtime_walls"] += 1
			elif body_category == &"foliage":
				stats["physics_body_count_foliage"] += 1
			elif body_category == &"ruin_props":
				stats["physics_body_count_ruin_props"] += 1
		if node is Control or node is CanvasLayer:
			stats["node_count_ui"] += 1
		if "vfx" in path or "effect" in path or node.is_in_group("vfx"):
			stats["node_count_vfx"] += 1
		if node.is_processing():
			stats["process_enabled_node_count"] += 1
		if node.is_physics_processing():
			stats["physics_process_enabled_node_count"] += 1
		for child in node.get_children():
			if child is Node:
				stack.append(child)
	return stats


func _get_collision_owner_category(node: Node) -> StringName:
	var cursor := node
	while cursor != null:
		if cursor.is_in_group("enemies") or cursor.is_in_group("enemy"):
			return &"enemies"
		if cursor.is_in_group("projectiles"):
			return &"projectiles"
		if cursor.is_in_group("runtime_prop") or cursor is ProceduralProp:
			return &"ruin_props"
		var name_lower := String(cursor.name).to_lower()
		if "foliage" in name_lower or "tree" in name_lower or "shrub" in name_lower:
			return &"foliage"
		if name_lower == "walls" or "runtimewall" in name_lower or "runtime_wall" in name_lower:
			return &"runtime_walls"
		cursor = cursor.get_parent()
	return &""


func _ensure_input_actions() -> void:
	_ensure_action_key(INPUT_ACTION, KEY_F9)
	_ensure_action_key(EXPORT_INPUT_ACTION, KEY_F10)


func _ensure_action_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	if _action_has_key(action, keycode):
		return

	var key := InputEventKey.new()
	key.keycode = keycode
	key.key_label = keycode
	InputMap.action_add_event(action, key)


func _action_has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event == null:
			continue
		if key_event.keycode == keycode or key_event.physical_keycode == keycode or key_event.key_label == keycode:
			return true
	return false


func _create_overlay() -> void:
	if _overlay != null:
		return

	var existing := _find_existing_overlay()
	if existing != null:
		_overlay = existing
		_overlay.visible = enabled
		return

	if !ResourceLoader.exists(OVERLAY_SCENE_PATH):
		push_warning("Developer Observatory overlay scene missing: %s" % OVERLAY_SCENE_PATH)
		return

	var scene := load(OVERLAY_SCENE_PATH)
	if scene == null or not scene is PackedScene:
		push_warning("Developer Observatory failed to load overlay scene: %s" % OVERLAY_SCENE_PATH)
		return

	var packed := scene as PackedScene
	var instance := packed.instantiate()
	if !(instance is CanvasLayer):
		push_warning("Developer Observatory overlay scene root must be CanvasLayer.")
		instance.queue_free()
		return

	_overlay = instance
	get_tree().root.call_deferred("add_child", _overlay)
	_overlay.visible = enabled


func _find_existing_overlay() -> CanvasLayer:
	var tree := get_tree()
	if tree == null:
		return null
	var stack: Array[Node] = [tree.root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node != self and node.name == "DevObservatoryOverlay" and node is CanvasLayer:
			return node as CanvasLayer
		for child in node.get_children():
			stack.append(child)
	return null
