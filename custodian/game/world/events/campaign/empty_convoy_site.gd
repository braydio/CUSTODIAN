class_name EmptyConvoySite
extends Node2D

const MANIFEST_TEXT := "IN TRANSIT / DISPATCH ABSENT / RECEIPT UNACKNOWLEDGED"
const EVENT_PREFIX := "campaign_empty_convoy_v1"
const SECURITY_LIMIT := 3
const SECURITY_OFFSETS := [Vector2(-104.0, -76.0), Vector2(104.0, -76.0), Vector2(0.0, 124.0)]
const SECURITY_FACING := [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(0.0, 1.0)]
const STATE_IDLE := &"idle"
const STATE_ACTIVE := &"active"
const STATE_CLEARED := &"cleared"
const STATE_EMPTY_DEFENSE := &"empty_defense"

var inspect_count := 0
var event_id: StringName
var security_state: StringName = STATE_IDLE
var expected_enemy_count := 0
var _world_seed := 0
var _memory: Node
var _spawner: Node
var _defeated_slots: Array[String] = []
var _active_enemies: Dictionary = {}


func _ready() -> void:
	add_to_group("interactable")
	queue_redraw()


func configure_runtime(world_seed: int, memory: Node = null, spawner: Node = null) -> void:
	_world_seed = world_seed
	_memory = memory if memory != null else get_node_or_null("/root/WorldEventMemory")
	_spawner = spawner if spawner != null else get_tree().get_first_node_in_group("ambient_enemy_spawn_scheduler")
	var run_seed := int(_memory.get("run_seed")) if _memory != null and "run_seed" in _memory else 0
	event_id = StringName("%s:%d:%d" % [EVENT_PREFIX, run_seed, _world_seed])
	_restore_event_state()
	queue_redraw()


func can_interact(_actor: Node = null) -> bool:
	return true


func get_interaction_prompt() -> String:
	match security_state:
		STATE_IDLE:
			return "SCAN CARGO CRADLE"
		STATE_ACTIVE:
			return "SECURITY ACTIVE — %d/%d NEUTRALIZED" % [_defeated_slots.size(), expected_enemy_count]
		STATE_CLEARED:
			return "CONVOY SECURITY CLEARED"
		STATE_EMPTY_DEFENSE:
			return "SECURITY UNAVAILABLE — EVIDENCE MODE"
	return "INSPECT CONVOY MANIFEST"


func get_interaction_prompt_body() -> String:
	match security_state:
		STATE_IDLE:
			return MANIFEST_TEXT
		STATE_ACTIVE:
			return "SECURITY RESPONSE ACTIVE / RETREAT REMAINS AVAILABLE"
		STATE_CLEARED:
			return "SECURITY CLEARED / SHIPMENT CUSTODY UNVERIFIED"
		STATE_EMPTY_DEFENSE:
			return "NO SAFE REGISTERED DEFENSE / EVIDENCE RETAINED"
	return MANIFEST_TEXT


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return 72.0


func interact(_actor: Node = null) -> void:
	inspect_count += 1
	if security_state == STATE_IDLE:
		_activate_security()
	queue_redraw()


func _activate_security() -> void:
	var scenes := _registered_enemy_scenes()
	if scenes.is_empty() or _spawner == null \
			or not _spawner.has_method("resolve_runtime_walkable_spawn"):
		_enter_empty_defense_mode("registered_enemy_or_walkability_service_unavailable")
		return
	var planned_count := SECURITY_LIMIT
	var positions: Array[Vector2] = []
	for index in range(planned_count):
		var desired: Vector2 = global_position + (SECURITY_OFFSETS[index] as Vector2)
		var resolved: Variant = _spawner.call("resolve_runtime_walkable_spawn", desired, 6)
		if not resolved is Vector2 or resolved == Vector2.INF:
			continue
		var spawn_position := resolved as Vector2
		var separated := true
		for prior in positions:
			if spawn_position.distance_squared_to(prior) < 44.0 * 44.0:
				separated = false
				break
		if separated:
			positions.append(spawn_position)
	if positions.is_empty():
		_enter_empty_defense_mode("no_safe_registered_spawn_position")
		return

	expected_enemy_count = positions.size()
	security_state = STATE_ACTIVE
	_persist_spawned_state()
	var parent: Node2D = self
	if _spawner.has_method("get_enemy_spawn_parent"):
		var spawn_parent := _spawner.call("get_enemy_spawn_parent") as Node2D
		if spawn_parent != null:
			parent = spawn_parent
	for index in range(positions.size()):
		var scene := scenes[index % scenes.size()]
		var enemy := scene.instantiate() as Node2D
		if enemy == null:
			continue
		enemy.set_meta("empty_convoy_event_id", String(event_id))
		enemy.set_meta("empty_convoy_slot", index)
		parent.add_child(enemy)
		enemy.global_position = positions[index]
		var facing: Vector2 = SECURITY_FACING[index] as Vector2
		if enemy.has_method("set_ability_facing"):
			enemy.call("set_ability_facing", facing)
		if enemy.has_method("refresh_enemy_directional_animation"):
			enemy.call("refresh_enemy_directional_animation")
		_configure_ambient_home(enemy)
		if enemy.has_signal("enemy_died"):
			enemy.connect("enemy_died", Callable(self, "_on_security_enemy_died"))
		_active_enemies[str(index)] = enemy
	if _active_enemies.is_empty():
		_enter_empty_defense_mode("registered_enemy_scenes_failed_to_instantiate")
	else:
		expected_enemy_count = _active_enemies.size()
		_persist_spawned_state()


func _registered_enemy_scenes() -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	if _spawner == null:
		return scenes
	var raw_scenes: Variant = _spawner.get("enemy_scenes")
	if raw_scenes is Array:
		for item in raw_scenes:
			if item is PackedScene:
				scenes.append(item as PackedScene)
	if scenes.is_empty():
		var fallback: Variant = _spawner.get("enemy_scene")
		if fallback is PackedScene:
			scenes.append(fallback as PackedScene)
	return scenes


func _configure_ambient_home(enemy: Node2D) -> void:
	var behavior := enemy.get_node_or_null("EnemyBehaviorStateMachine")
	if behavior == null:
		return
	var profile := StringName(str(enemy.get("behavior_profile_id")))
	if profile != &"":
		behavior.call("setup_profile", profile)
	if behavior.has_method("setup_ambient_home"):
		behavior.call("setup_ambient_home", global_position, event_id, 320.0)


func _on_security_enemy_died(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy) \
			or String(enemy.get_meta("empty_convoy_event_id", "")) != String(event_id):
		return
	var slot := str(enemy.get_meta("empty_convoy_slot", ""))
	if slot.is_empty() or _defeated_slots.has(slot):
		return
	_defeated_slots.append(slot)
	_active_enemies.erase(slot)
	if _defeated_slots.size() >= expected_enemy_count:
		security_state = STATE_CLEARED
		_persist_completed_state()
	else:
		_persist_spawned_state()
	queue_redraw()


func _restore_event_state() -> void:
	if event_id.is_empty() or _memory == null or not _memory.has_method("get_payload"):
		return
	if _memory.has_method("is_completed") and bool(_memory.call("is_completed", event_id)):
		security_state = STATE_CLEARED
		return
	var payload: Dictionary = _memory.call("get_payload", event_id)
	security_state = StringName(payload.get("security_state", String(STATE_IDLE)))
	expected_enemy_count = maxi(0, int(payload.get("expected_enemy_count", 0)))
	var raw_defeated: Variant = payload.get("defeated_slots", [])
	if raw_defeated is Array:
		for slot in raw_defeated:
			_defeated_slots.append(str(slot))
	if security_state == STATE_ACTIVE:
		var live_count := _reconnect_live_enemies()
		if live_count == 0:
			_enter_empty_defense_mode("active_wave_not_present_on_reentry")
	elif security_state not in [STATE_IDLE, STATE_CLEARED, STATE_EMPTY_DEFENSE]:
		_enter_empty_defense_mode("invalid_persisted_security_state")


func _reconnect_live_enemies() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy) \
				or String(enemy.get_meta("empty_convoy_event_id", "")) != String(event_id):
			continue
		var slot := str(enemy.get_meta("empty_convoy_slot", ""))
		if slot.is_empty():
			continue
		if bool(enemy.get("dead")):
			if not _defeated_slots.has(slot):
				_defeated_slots.append(slot)
			continue
		_active_enemies[slot] = enemy
		if enemy.has_signal("enemy_died"):
			var callback := Callable(self, "_on_security_enemy_died")
			if not enemy.is_connected("enemy_died", callback):
				enemy.connect("enemy_died", callback)
		count += 1
	return count


func _enter_empty_defense_mode(reason: String) -> void:
	security_state = STATE_EMPTY_DEFENSE
	_persist_spawned_state({"empty_defense_reason": reason})


func _persist_spawned_state(extra: Dictionary = {}) -> void:
	if _memory == null or not _memory.has_method("mark_spawned"):
		return
	_memory.call("mark_spawned", event_id, _state_payload(extra))


func _persist_completed_state() -> void:
	if _memory == null or not _memory.has_method("mark_completed"):
		return
	_memory.call("mark_completed", event_id, _state_payload())


func _state_payload(extra: Dictionary = {}) -> Dictionary:
	var payload := {
		"security_state": String(security_state),
		"world_seed": _world_seed,
		"expected_enemy_count": expected_enemy_count,
		"defeated_slots": _defeated_slots.duplicate(),
	}
	for key in extra:
		payload[key] = extra[key]
	return payload


func _draw() -> void:
	var metal := Color("53616a")
	var shadow := Color("202a31")
	var edge := Color("87949a")
	_draw_wreck(Vector2(-58.0, -42.0), -0.48, metal, shadow, edge)
	_draw_wreck(Vector2(58.0, -42.0), 0.48, metal, shadow, edge)
	_draw_wreck(Vector2(0.0, 62.0), PI, metal, shadow, edge)
	# Empty central cargo cradle with an open side facing the manifest.
	draw_rect(Rect2(Vector2(-25.0, -10.0), Vector2(50.0, 38.0)), shadow, false, 4.0)
	draw_line(Vector2(-20.0, 14.0), Vector2(20.0, 14.0), edge, 3.0)
	# A physical receipt plate; inspecting it has no campaign-state side effects.
	draw_rect(Rect2(Vector2(-39.0, 35.0), Vector2(78.0, 20.0)), Color("b9ae8e"), true)
	var ink := Color("30383a")
	draw_string(ThemeDB.fallback_font, Vector2(-36.0, 43.0), "IN TRANSIT / DISPATCH ABSENT", HORIZONTAL_ALIGNMENT_LEFT, 72.0, 4, ink)
	draw_string(ThemeDB.fallback_font, Vector2(-36.0, 51.0), "RECEIPT UNACKNOWLEDGED", HORIZONTAL_ALIGNMENT_LEFT, 72.0, 4, ink)
	var state_text := "SECURITY: %s" % String(security_state).to_upper().replace("_", " ")
	draw_string(ThemeDB.fallback_font, Vector2(-48.0, 73.0), state_text, HORIZONTAL_ALIGNMENT_LEFT, 96.0, 6, Color("f0c66e"))


func _draw_wreck(origin: Vector2, rotation: float, metal: Color, shadow: Color, edge: Color) -> void:
	var transform := Transform2D(rotation, origin)
	var hull := PackedVector2Array([
		transform * Vector2(-25.0, -10.0),
		transform * Vector2(12.0, -14.0),
		transform * Vector2(27.0, -3.0),
		transform * Vector2(8.0, 12.0),
		transform * Vector2(-21.0, 9.0),
	])
	draw_colored_polygon(hull, metal)
	draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[4], hull[0]]), edge, 2.0)
	draw_line(transform * Vector2(-9.0, -4.0), transform * Vector2(12.0, 5.0), shadow, 4.0)
