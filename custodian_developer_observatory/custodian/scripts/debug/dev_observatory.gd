extends Node
class_name DevObservatoryService

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

	var enemies := tree.get_nodes_in_group("enemies")
	if enemies.size() > 0:
		set_gauge(&"active_enemies", enemies.size())

	var projectiles := tree.get_nodes_in_group("projectiles")
	if projectiles.size() > 0:
		set_gauge(&"active_projectiles", projectiles.size())

	var player := tree.get_first_node_in_group("player")
	if player != null and player is Node2D:
		var p := player as Node2D
		set_gauge(&"player_position", Vector2i(roundi(p.global_position.x), roundi(p.global_position.y)))


func _count_nodes(root_node: Node) -> int:
	var count := 1
	for child in root_node.get_children():
		count += _count_nodes(child)
	return count


func _ensure_input_action() -> void:
	if InputMap.has_action(INPUT_ACTION):
		return

	InputMap.add_action(INPUT_ACTION)

	var key := InputEventKey.new()
	key.keycode = KEY_F9
	InputMap.action_add_event(INPUT_ACTION, key)


func _create_overlay() -> void:
	if _overlay != null:
		return

	if !ResourceLoader.exists(OVERLAY_SCENE_PATH):
		push_warning("Developer Observatory overlay scene missing: %s" % OVERLAY_SCENE_PATH)
		return

	var scene := load(OVERLAY_SCENE_PATH)
	if scene == null:
		push_warning("Developer Observatory failed to load overlay scene: %s" % OVERLAY_SCENE_PATH)
		return

	var instance := scene.instantiate()
	if !(instance is CanvasLayer):
		push_warning("Developer Observatory overlay scene root must be CanvasLayer.")
		instance.queue_free()
		return

	_overlay = instance
	get_tree().root.call_deferred("add_child", _overlay)
	_overlay.visible = enabled
