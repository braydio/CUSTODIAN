extends RefCounted
class_name MomentActionDriver

const SAFE_PROPERTIES := {
	"position": true, "global_position": true, "visible": true,
	"health": true, "current_health": true, "max_health": true,
	"field_patch_count": true, "aim_direction": true, "facing": true,
	"operator_weapon_socket_debug_enabled": true,
}

var roles: Dictionary = {}
var fixture: Dictionary = {}
var scene_root: Node
var observatory: Node
var results: Array[Dictionary] = []
var markers: Array[Dictionary] = []
var _pressed: Dictionary = {}
var _scheduled_releases: Dictionary = {}


func configure(context: Dictionary) -> void:
	roles = context.get("roles", {})
	fixture = context.get("fixture", {})
	scene_root = context.get("scene_root")
	observatory = context.get("observatory")


func begin_tick(tick: int) -> void:
	for action_name: Variant in _scheduled_releases.get(tick, []):
		Input.action_release(StringName(action_name))
		_pressed.erase(StringName(action_name))
	_scheduled_releases.erase(tick)


func perform(action: Dictionary, tick: int) -> Dictionary:
	var kind := str(action.get("action", ""))
	var result := {"tick": tick, "action": kind, "ok": true}
	match kind:
		"input_press":
			_input_press(str(action.get("name", "")), result)
		"input_release":
			_input_release(str(action.get("name", "")), result)
		"input_tap":
			var name := str(action.get("name", ""))
			_input_press(name, result)
			if bool(result.ok):
				var release_tick := int(action.get(
					"release_tick",
					tick + max(1, int(action.get("hold_ticks", 1)))
				))
				if not _scheduled_releases.has(release_tick):
					_scheduled_releases[release_tick] = []
				_scheduled_releases[release_tick].append(name)
		"aim_at_role":
			var target := _role(str(action.get("target_role", "")), result)
			var actor := _role(str(action.get("role", "operator")), result)
			if target is Node2D and actor is Node2D:
				_set_aim(actor, target.global_position)
		"aim_at_world":
			var actor := _role(str(action.get("actor_role", "operator")), result)
			var point: Variant = _vector(action.get("position", []))
			if actor is Node2D and point != null:
				_set_aim(actor, point)
		"set_role_position":
			var node := _role(str(action.get("role", "")), result)
			var value: Variant = _vector(action.get("position", []))
			if node is Node2D and value != null:
				node.global_position = value
		"set_role_property":
			_set_role_property(action, result)
		"set_role_physics_enabled":
			var node := _role(str(action.get("role", "")), result)
			if node != null:
				node.set_physics_process(bool(action.get("enabled", true)))
		"set_role_process_enabled":
			var node := _role(str(action.get("role", "")), result)
			if node != null:
				node.set_process(bool(action.get("enabled", true)))
		"capture_marker":
			markers.append({
				"tick": tick,
				"name": str(action.get("name", "marker")),
				"data": action.get("data", {}),
			})
		"fixture_command":
			_fixture_command(action, result)
		"finish":
			result["finish"] = true
		_:
			result.ok = false
			result["error"] = "unsupported action: %s" % kind
	results.append(result)
	_log(action, result, tick)
	return result


func has_unreleased_inputs() -> bool:
	return not _pressed.is_empty() or not _scheduled_releases.is_empty()


func release_all() -> void:
	for action_name: Variant in _pressed:
		Input.action_release(StringName(action_name))
	_pressed.clear()
	_scheduled_releases.clear()


func _input_press(name: String, result: Dictionary) -> void:
	var action_name := StringName(name)
	if not InputMap.has_action(action_name):
		result.ok = false
		result["error"] = "unknown InputMap action: %s" % name
		return
	Input.action_press(action_name)
	_pressed[action_name] = true


func _input_release(name: String, result: Dictionary) -> void:
	var action_name := StringName(name)
	if not InputMap.has_action(action_name):
		result.ok = false
		result["error"] = "unknown InputMap action: %s" % name
		return
	Input.action_release(action_name)
	_pressed.erase(action_name)


func _role(name: String, result: Dictionary) -> Node:
	var node := roles.get(name) as Node
	if node == null or not is_instance_valid(node):
		result.ok = false
		result["error"] = "role is unavailable: %s" % name
		return null
	return node


func _set_role_property(action: Dictionary, result: Dictionary) -> void:
	var node := _role(str(action.get("role", "")), result)
	var property := str(action.get("property", ""))
	if node == null:
		return
	if not SAFE_PROPERTIES.has(property):
		result.ok = false
		result["error"] = "property is not allowlisted: %s" % property
		return
	var value: Variant = action.get("value")
	var converted: Variant = _vector(value)
	if converted != null:
		value = converted
	node.set(property, value)


func _set_aim(actor: Node2D, world_point: Vector2) -> void:
	var direction := actor.global_position.direction_to(world_point)
	if "aim_direction" in actor:
		actor.set("aim_direction", direction)
	if "last_move_direction" in actor:
		actor.set("last_move_direction", direction)


func _fixture_command(action: Dictionary, result: Dictionary) -> void:
	var fixture_id := str(fixture.get("id", ""))
	var command := str(action.get("name", ""))
	var allowed := {
		"combat_playground": [
			"begin_deterministic_enemy_attack",
			"set_target_guard_state",
		],
		"sundered_keep_world_vista": [
			"place_operator_at_reveal_progress",
			"begin_authored_walkthrough",
		],
		"ash_bell_lift": [
			"begin_lift_descent",
			"reset_lift_exterior",
		],
		"ash_bell_threadway": [
			"acquire_white_thread_knot",
			"walk_operator_across",
			"stand_at_lift_entrance",
		],
		"forlorn_ritualant_completion": [
			"approach_reveal",
			"first_dialogue",
			"touch_thread",
			"thread_pull",
			"ninth_answer",
			"orra_late",
			"return_lift",
			"begin_return",
		],
		"ritualant_underground_landing_visual": [
			"begin_landing_descent",
			"hold_apron_center",
			"begin_north_walk",
		],
		"field_fabricator": [
			"power_on",
			"begin_fabrication",
			"complete_fabrication",
		],
	}
	if command not in allowed.get(fixture_id, []):
		result.ok = false
		result["error"] = "fixture command is not registered: %s/%s" % [fixture_id, command]
		return
	if scene_root.has_method("moment_forge_fixture_command"):
		var response: Variant = scene_root.call(
			"moment_forge_fixture_command", command, action.get("args", {})
		)
		result["response"] = response
		return
	if command == "begin_deterministic_enemy_attack":
		var target := roles.get(str(action.get("role", "target"))) as Node
		if target != null and target.has_method("behavior_attack_target"):
			target.call("behavior_attack_target")
			return
	result.ok = false
	result["error"] = "fixture command has no live implementation: %s" % command


func _vector(value: Variant) -> Variant:
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return null


func _log(action: Dictionary, result: Dictionary, tick: int) -> void:
	if observatory == null or not observatory.has_method("log_event"):
		return
	observatory.call(&"log_event", &"moment_forge_action", {
		"moment_tick": tick,
		"authored_action": action,
		"result": result,
	})
