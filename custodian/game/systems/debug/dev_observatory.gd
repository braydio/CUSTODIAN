extends Node

signal toggled(enabled: bool)
signal event_logged(kind: StringName, data: Dictionary)
signal warning_logged(message: String, data: Dictionary)

const OVERLAY_SCENE_PATH := "res://scenes/debug/dev_observatory_overlay.tscn"
const INPUT_ACTION := "debug_observatory"

@export var max_events := 300
@export var sample_interval := 0.25
@export var auto_create_overlay := true

var enabled := false
var events: Array[Dictionary] = []
var counters: Dictionary = {}
var gauges: Dictionary = {}
var warnings: Array[Dictionary] = []

var _sample_accum := 0.0
var _overlay: CanvasLayer = null
var _boot_time_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_boot_time_msec = Time.get_ticks_msec()
	_ensure_input_action()

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
	var entry := {
		"time_msec": Time.get_ticks_msec(),
		"uptime_sec": get_uptime_sec(),
		"kind": kind,
		"data": data
	}

	events.append(entry)

	while events.size() > max_events:
		events.pop_front()

	event_logged.emit(kind, data)


func increment(name: StringName, amount: int = 1) -> void:
	counters[name] = int(counters.get(name, 0)) + amount


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
		"counter_count": counters.size(),
		"gauge_count": gauges.size(),
		"warning_count": warnings.size(),
		"counters": counters,
		"gauges": gauges,
		"recent_events": get_recent_events(12),
		"recent_warnings": get_recent_warnings(5)
	}


func _sample_runtime_gauges() -> void:
	set_gauge(&"fps", Engine.get_frames_per_second())
	set_gauge(&"uptime_sec", snappedf(get_uptime_sec(), 0.01))

	var tree := get_tree()
	if tree == null:
		return

	set_gauge(&"node_count", _count_nodes(tree.root))

	var enemies := _get_unique_group_nodes(["enemy", "enemies"])
	set_gauge(&"active_enemies", enemies.size())
	set_gauge(&"behavior_agents", tree.get_nodes_in_group("enemy_behavior_agent").size())
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
			set_gauge(&"player_weapon_heat", float(status.get("heat", 0.0)))
			set_gauge(&"player_weapon_overheated", bool(status.get("overheated", false)))


func _sample_enemy_gauges(enemies: Array) -> void:
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("get_behavior_snapshot"):
			var snapshot: Variant = enemy.call("get_behavior_snapshot")
			if snapshot is Dictionary:
				set_gauge(&"enemy_behavior_sample", snapshot)
				return


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


func _ensure_input_action() -> void:
	if not InputMap.has_action(INPUT_ACTION):
		InputMap.add_action(INPUT_ACTION)
	if _action_has_key(INPUT_ACTION, KEY_F9):
		return

	var key := InputEventKey.new()
	key.keycode = KEY_F9
	key.key_label = KEY_F9
	InputMap.action_add_event(INPUT_ACTION, key)


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
