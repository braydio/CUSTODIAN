extends Node
class_name NpaShowcaseScenarioController

const ACTORS := {
	&"marine": {"scene": "res://game/actors/enemies/enemy_marine.tscn", "socket": "MarineSocket", "host": "Enemies", "state": "available"},
	&"savage": {"scene": "res://game/actors/enemies/enemy_savage.tscn", "socket": "SavageSocket", "host": "Enemies", "state": "available"},
	&"vaultwing": {"scene": "res://game/actors/ambient/vaultwing/vaultwing.tscn", "socket": "VaultwingSocket", "host": "Enemies", "state": "available"},
	&"broken_warrant": {"scene": "", "socket": "BrokenWarrantSocket", "host": "Enemies", "state": "not_landed"},
	&"escort_frame_m7": {"scene": "", "socket": "EscortFrameM7Socket", "host": "Allies", "state": "not_landed"},
}
const RELATIONSHIP_RESOLVER := preload("res://game/systems/combat/actor_relationship_resolver.gd")

var _level: Node2D
var _actors: Dictionary = {}
var _selected_id: StringName = &"marine"
var _event_log: Array[String] = []


func _ready() -> void:
	_level = get_parent().get_parent() as Node2D
	if not _is_registered_arena():
		set_process(false)
		return
	for actor_id in ACTORS:
		_actors[actor_id] = null


func is_enabled() -> bool:
	return _is_registered_arena()


func get_actor_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for actor_id in ACTORS:
		result.append(actor_id)
	return result


func get_actor_state(actor_id: StringName) -> Dictionary:
	var spec: Dictionary = ACTORS.get(actor_id, {})
	if spec.is_empty():
		return {"id": actor_id, "status": "N/A", "enabled": false}
	var actor: Node = _live_actor(actor_id)
	if actor == null:
		return {"id": actor_id, "status": "N/A" if spec["state"] == "available" else "N/A (not landed)", "enabled": spec["state"] == "available"}
	var allegiance := str(RELATIONSHIP_RESOLVER.resolve_allegiance(actor))
	var operator := _level.get_tree().get_first_node_in_group("player")
	var target_eligible := "N/A" if operator == null else str(RELATIONSHIP_RESOLVER.can_target(operator, actor))
	var health_text := "N/A"
	if actor.has_method("get_lifecycle_debug_state"):
		var health_state: Dictionary = actor.call("get_lifecycle_debug_state")
		health_text = "%d / %d" % [roundi(float(health_state.get("health", 0.0))), roundi(float(health_state.get("max_health", 0.0)))]
	elif "health" in actor and "max_health" in actor:
		health_text = "%d / %d" % [roundi(float(actor.get("health"))), roundi(float(actor.get("max_health")))]
	var target := _read_target(actor)
	var corpse := "N/A"
	if actor.has_method("is_dead"):
		corpse = "dead" if bool(actor.call("is_dead")) else "alive"
	if actor.has_method("get_lifecycle_debug_state"):
		var lifecycle_state: Dictionary = actor.call("get_lifecycle_debug_state")
		var life_state: int = int(lifecycle_state.get("life_state", 0))
		var lifecycle_names := ["ALIVE", "DYING", "LOOTABLE_CORPSE", "EMPTY_CORPSE"]
		if life_state >= 0 and life_state < lifecycle_names.size():
			corpse = lifecycle_names[life_state]
	return {
		"id": actor_id, "status": "LIVE", "class": actor.get_class(), "role": str(actor.get("enemy_name")) if "enemy_name" in actor else actor.name,
		"allegiance": allegiance, "target_eligible": target_eligible, "target": target,
		"health": health_text, "corpse": corpse, "ability": _read_ability_phase(actor),
		"squad": _read_drone_state(actor), "target_control": "available" if "target" in actor else "N/A",
		"allegiance_control": actor.has_method("set_allegiance"), "enabled": true,
	}


func get_event_log() -> PackedStringArray:
	return PackedStringArray(_event_log)


func select_actor(actor_id: StringName) -> void:
	if ACTORS.has(actor_id):
		_selected_id = actor_id


func spawn_actor(actor_id: StringName) -> bool:
	if not _is_registered_arena() or not ACTORS.has(actor_id):
		return false
	var spec: Dictionary = ACTORS[actor_id]
	if str(spec["scene"]).is_empty():
		_record("%s is not landed; controls remain disabled" % actor_id)
		return false
	var old_actor := _live_actor(actor_id)
	if old_actor != null:
		old_actor.queue_free()
	var packed := load(str(spec["scene"])) as PackedScene
	if packed == null:
		_record("Unable to load %s" % actor_id)
		return false
	var actor := packed.instantiate() as Node2D
	if actor == null:
		return false
	var socket := _level.get_node_or_null("EventMarkers/ActorSockets/%s" % spec["socket"]) as Marker2D
	var host := _level.get_node_or_null("ScenarioActors/%s" % spec["host"]) as Node2D
	if socket == null or host == null:
		actor.free()
		_record("Missing authored socket or actor host for %s" % actor_id)
		return false
	host.add_child(actor)
	actor.global_position = socket.global_position
	actor.set_meta("npa_showcase_actor_id", actor_id)
	_actors[actor_id] = actor
	_selected_id = actor_id
	_record("Spawned %s through its registered dev scene" % actor_id)
	return true


func reset_scenario() -> void:
	if not _is_registered_arena():
		return
	for actor_id in get_actor_ids():
		var actor := _live_actor(actor_id)
		if actor != null:
			actor.queue_free()
		_actors[actor_id] = null
	_event_log.clear()
	_record("Scenario reset; actors return to N/A until spawned")


func request_actor_action(actor_id: StringName) -> bool:
	var actor := _live_actor(actor_id)
	if actor == null:
		return false
	if actor.has_method("behavior_attack_target"):
		var current_target: Node = actor.get("target") as Node if "target" in actor else null
		if current_target == null or not is_instance_valid(current_target):
			var operator := _level.get_tree().get_first_node_in_group("player") as Node2D
			if operator != null:
				actor.set("target", operator)
		actor.call("behavior_attack_target")
		_record("Requested actor-owned combat action for %s" % actor_id)
		return true
	if actor.has_method("request_marine_dash"):
		var operator := _level.get_tree().get_first_node_in_group("player") as Node2D
		if operator != null:
			actor.call("request_marine_dash", (operator.global_position - actor.global_position).normalized())
			_record("Requested Marine dash through its ability owner")
			return true
	return false


func damage_actor(actor_id: StringName) -> bool:
	var actor := _live_actor(actor_id)
	if actor == null or not actor.has_method("take_damage"):
		return false
	actor.call("take_damage", 100000.0)
	_record("Applied lethal debug damage through %s.take_damage" % actor.name)
	return true


func toggle_allegiance(actor_id: StringName) -> bool:
	var actor := _live_actor(actor_id)
	if actor == null or not actor.has_method("set_allegiance") or not actor.has_method("get_allegiance"):
		return false
	var next := &"operator_allied" if StringName(actor.call("get_allegiance")) == &"hostile" else &"hostile"
	var changed: bool = actor.call("set_allegiance", next)
	if changed:
		_record("Changed %s allegiance through its relationship owner" % actor_id)
	return changed


func cycle_target(actor_id: StringName) -> bool:
	var actor := _live_actor(actor_id)
	if actor == null or not "target" in actor:
		return false
	var candidates: Array[Node] = []
	var operator := _level.get_tree().get_first_node_in_group("player")
	if operator != null:
		candidates.append(operator)
	for other_id in get_actor_ids():
		var other := _live_actor(other_id)
		if other != null and other != actor and RELATIONSHIP_RESOLVER.can_target(actor, other):
			candidates.append(other)
	if candidates.is_empty():
		return false
	var current: Node = actor.get("target")
	var next_index := (candidates.find(current) + 1) % candidates.size()
	actor.set("target", candidates[next_index])
	_record("Selected target %s through %s target owner" % [candidates[next_index].name, actor_id])
	return true


func can_cycle_target(actor_id: StringName) -> bool:
	var actor := _live_actor(actor_id)
	return actor != null and "target" in actor


func set_drone_order(mode: StringName) -> bool:
	if not _is_registered_arena():
		return false
	var manager := _level.get_tree().root.get_node_or_null("GameRoot/DroneManager")
	if manager == null or not manager.has_method("set_squad_mode_name"):
		return false
	match mode:
		&"follow":
			manager.call("set_squad_mode_name", "follow")
		&"hold":
			manager.call("set_squad_mode_name", "hold")
		&"guard":
			var m7 := _live_actor(&"escort_frame_m7") as Node2D
			if m7 == null or not manager.has_method("issue_guard_order") or not bool(manager.call("issue_guard_order", m7.global_position)):
				return false
		&"recall":
			if not manager.has_method("return_to_operator_follow"):
				return false
			manager.call("return_to_operator_follow")
		_:
			return false
	_record("Requested DroneManager %s order" % mode)
	return true


func _is_registered_arena() -> bool:
	return _level != null and is_instance_valid(_level) and _level.is_inside_tree() and _level.scene_file_path == "res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena.tscn"


func _live_actor(actor_id: StringName) -> Node:
	var actor: Node = _actors.get(actor_id)
	if actor == null or not is_instance_valid(actor) or actor.is_queued_for_deletion():
		actor = null
		if _actors.has(actor_id):
			_actors[actor_id] = null
	return actor


func _read_target(actor: Node) -> String:
	for property_name in [&"current_target", &"target", &"command_target"]:
		if property_name in actor:
			var target: Variant = actor.get(property_name)
			if target is Node and is_instance_valid(target):
				return "%s (%s)" % [target.name, target.get_class()]
	return "N/A"


func _read_ability_phase(actor: Node) -> String:
	var phases: Array[String] = []
	for method_name in [&"get_standard_enemy_melee_debug_state", &"get_marine_dash_debug_state", &"get_savage_pounce_debug_state", &"get_savage_chain_debug_state", &"get_reaction_debug_state", &"get_parry_critical_debug_state"]:
		if not actor.has_method(method_name):
			continue
		var state: Dictionary = actor.call(method_name)
		var phase: Variant = state.get("phase", state.get("state", "N/A"))
		phases.append("%s=%s" % [String(method_name).trim_prefix("get_").trim_suffix("_debug_state"), phase])
	return "; ".join(phases) if not phases.is_empty() else "N/A"


func _read_drone_state(actor: Node) -> String:
	if actor.has_method("get_fire_mode_name"):
		var manager: Node = actor.get("manager") as Node if "manager" in actor else null
		var squad_state: Object = manager.get("squad_state") as Object if manager != null and "squad_state" in manager else null
		var squad_ids: Variant = squad_state.get("active_drone_ids") if squad_state != null and "active_drone_ids" in squad_state else "N/A"
		var anchor_mode: String = actor.call("get_anchor_mode_name") if actor.has_method("get_anchor_mode_name") else "N/A"
		var anchor := "operator"
		if "order_anchor_active" in actor and bool(actor.get("order_anchor_active")):
			var point: Vector2 = actor.get("order_anchor_position")
			anchor = "%.0f,%.0f" % [point.x, point.y]
		return "squad=%s drone=%s anchor=%s/%s fire=%s" % [squad_ids, actor.get("drone_id") if "drone_id" in actor else "N/A", anchor_mode, anchor, actor.call("get_fire_mode_name")]
	return "N/A"


func _record(message: String) -> void:
	_event_log.append(message)
	while _event_log.size() > 24:
		_event_log.pop_front()
