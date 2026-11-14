class_name EmptyConvoySite
extends Node2D

const MANIFEST_TEXT := "IN TRANSIT / DISPATCH ABSENT / RECEIPT UNACKNOWLEDGED"
const EVENT_PREFIX := "campaign_empty_convoy_v1"
const SECURITY_LIMIT := 3
const MAX_SECURITY_RETRIES := 3
const MAX_SECURITY_DIAGNOSTICS := 16
const SECURITY_OFFSETS := [Vector2(-104.0, -76.0), Vector2(104.0, -76.0), Vector2(0.0, 124.0)]
const SECURITY_FACING := [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(0.0, 1.0)]
const CUSTODY_TRACE_TEXT := "CONVOY CUSTODY TRACE: SHIPMENT UNVERIFIED"
const SALVAGE_RESOURCE_ID := "ruin_scrap"
const SALVAGE_AMOUNT := 1
const STATE_IDLE := &"idle"
const STATE_ACTIVE := &"active"
const STATE_DEFERRED := &"security_deferred"
const STATE_UNRESOLVED := &"security_unresolved"
const STATE_CLEARED := &"cleared"
const STATE_EMPTY_DEFENSE := &"empty_defense"
const STATE_TRACE_RECORDED := &"trace_recorded"
const STATE_EVIDENCE_ONLY := &"evidence_only"
const SLOT_UNATTEMPTED := "unattempted"
const SLOT_PENDING := "pending"
const SLOT_ACTIVE := "active"
const SLOT_DEFEATED := "defeated"
const SLOT_RETRYABLE := "retryable"
const SLOT_UNKNOWN := "unknown"

var inspect_count := 0
var event_id: StringName
var security_state: StringName = STATE_IDLE
var expected_enemy_count := SECURITY_LIMIT
var _world_seed := 0
var _memory: Node
var _spawner: Node
var _ledger: Node
var _defeated_slots: Array[String] = []
var _active_enemies: Dictionary = {}
var _spawn_positions: Array[Vector2] = []
var _assigned_slots: Dictionary = {}
var _slot_states: Array[String] = []
var _pending_spawn_count := 0
var _retry_attempt_count := 0
var _custody_trace_recorded := false
var _salvage_granted := false
var _empty_defense_authoritative := false
var _security_reason := ""
var _unverified_reentry_slots: Array[int] = []
var _batch_queued_count := 0
var _batch_accepted_count := 0
var _batch_rejected_count := 0
var _batch_candidate_positions: Array[Vector2] = []
var _diagnostic_event_count := 0
var _last_diagnostic_signature := ""
var _last_diagnostic_state := STATE_IDLE


func _ready() -> void:
	add_to_group("interactable")
	queue_redraw()


func configure_runtime(
	world_seed: int,
	memory: Node = null,
	spawner: Node = null,
	ledger: Node = null
) -> void:
	_world_seed = world_seed
	_memory = memory if memory != null else get_node_or_null("/root/WorldEventMemory")
	_spawner = spawner if spawner != null else get_tree().get_first_node_in_group("ambient_enemy_spawn_scheduler")
	_ledger = ledger if ledger != null else get_node_or_null("/root/ResourceLedger")
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
		STATE_DEFERRED:
			return "SECURITY DEFERRED — RETRY AFTER CONDITIONS CHANGE"
		STATE_UNRESOLVED:
			return "SECURITY UNRESOLVED — CUSTODY TRACE LOCKED"
		STATE_CLEARED:
			return "RECORD CUSTODY TRACE"
		STATE_EMPTY_DEFENSE:
			return "RECORD CUSTODY TRACE"
		STATE_TRACE_RECORDED:
			return "CUSTODY TRACE RECORDED"
		STATE_EVIDENCE_ONLY:
			return "CUSTODY TRACE — EVIDENCE ONLY"
	return "INSPECT CONVOY MANIFEST"


func get_interaction_prompt_body() -> String:
	match security_state:
		STATE_IDLE:
			return MANIFEST_TEXT
		STATE_ACTIVE:
			return "SECURITY RESPONSE ACTIVE / RETREAT REMAINS AVAILABLE"
		STATE_DEFERRED:
			return "SECURITY RESPONSE DEFERRED / NO CUSTODY TRACE OR SALVAGE UNTIL RESOLVED"
		STATE_UNRESOLVED:
			return "SECURITY STATUS UNVERIFIED / CUSTODY TRACE AND SALVAGE LOCKED"
		STATE_CLEARED:
			return "SECURITY CLEARED / SHIPMENT CUSTODY UNVERIFIED"
		STATE_EMPTY_DEFENSE:
			return "NO REGISTERED DEFENSE / EVIDENCE RETAINED"
		STATE_TRACE_RECORDED:
			return "%s / SALVAGE: +%d RUIN SCRAP" % [CUSTODY_TRACE_TEXT, SALVAGE_AMOUNT]
		STATE_EVIDENCE_ONLY:
			return "%s / LEDGER UNAVAILABLE; NO SALVAGE GRANTED" % CUSTODY_TRACE_TEXT
	return MANIFEST_TEXT


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return 72.0


func interact(_actor: Node = null) -> void:
	inspect_count += 1
	match security_state:
		STATE_IDLE:
			_attempt_security_activation()
		STATE_DEFERRED:
			_attempt_security_activation()
		STATE_CLEARED:
			_record_custody_trace()
		STATE_EMPTY_DEFENSE:
			if _empty_defense_authoritative:
				_record_custody_trace()
	queue_redraw()


func _record_custody_trace() -> void:
	if _custody_trace_recorded or not _trace_is_authorized():
		return
	var resource_defs: Variant = _ledger.call("get_resource_defs") \
		if _ledger != null and _ledger.has_method("get_resource_defs") else {}
	var ledger_ready := _ledger != null \
		and _ledger.has_method("add") \
		and resource_defs is Dictionary \
		and (resource_defs as Dictionary).has(SALVAGE_RESOURCE_ID)
	var completion_ready := _memory != null and _memory.has_method("mark_completed")
	_custody_trace_recorded = true
	_salvage_granted = ledger_ready and completion_ready
	security_state = STATE_TRACE_RECORDED if _salvage_granted else STATE_EVIDENCE_ONLY
	var payload := _state_payload({
		"custody_trace_recorded": true,
		"salvage_granted": _salvage_granted,
		"salvage_resource_id": SALVAGE_RESOURCE_ID if _salvage_granted else "",
		"salvage_amount": SALVAGE_AMOUNT if _salvage_granted else 0,
	})
	if completion_ready:
		_memory.call("mark_completed", event_id, payload)
	elif _memory != null and _memory.has_method("mark_spawned"):
		_memory.call("mark_spawned", event_id, payload)
	if _salvage_granted:
		_ledger.call("add", SALVAGE_RESOURCE_ID, SALVAGE_AMOUNT)
	_log_security_diagnostic(&"empty_convoy_security_trace_recorded", "authorized_clearance", [], 0, 0, 0)
	queue_redraw()


func _trace_is_authorized() -> bool:
	return security_state == STATE_CLEARED \
		or (security_state == STATE_EMPTY_DEFENSE and _empty_defense_authoritative)


func _attempt_security_activation() -> void:
	if _slot_states.is_empty():
		_slot_states.resize(SECURITY_LIMIT)
		for index in range(SECURITY_LIMIT):
			_slot_states[index] = SLOT_UNATTEMPTED
		_spawn_positions.resize(SECURITY_LIMIT)
		expected_enemy_count = SECURITY_LIMIT
	var scenes := _registered_enemy_scenes()
	if not _spawner_service_ready():
		_defer_security("spawn_service_unavailable", [], 0, 0, 0, false)
		return
	if scenes.is_empty():
		if _registered_defenders_absent_authoritatively():
			_enter_empty_defense_mode("registered_defender_registry_empty")
		else:
			_defer_security("registered_defender_registry_unavailable", [], 0, 0, 0, false)
		return
	var missing_slots: Array[int] = []
	for index in range(_slot_states.size()):
		if _slot_states[index] in [SLOT_UNATTEMPTED, SLOT_RETRYABLE]:
			missing_slots.append(index)
	if missing_slots.is_empty():
		return
	if _retry_attempt_count >= MAX_SECURITY_RETRIES and security_state != STATE_IDLE:
		_mark_security_unresolved("bounded_spawn_retry_limit_reached", [], 0, 0, 0)
		return
	var active_count := int(_spawner.call("get_active_enemy_count"))
	var pending_count := int(_spawner.call("get_pending_spawn_count"))
	var active_limit := int(_spawner.get("max_active_ambient_enemies"))
	var available_capacity := maxi(0, active_limit - active_count - pending_count)
	if available_capacity < missing_slots.size():
		_defer_security("registered_spawn_capacity_unavailable", [], 0, 0, 0, false)
		return
	var positions_by_slot: Dictionary = {}
	var candidates: Array[Vector2] = []
	for slot in missing_slots:
		var desired: Vector2 = global_position + (SECURITY_OFFSETS[slot] as Vector2)
		var resolved: Variant = _spawner.call("resolve_runtime_walkable_spawn", desired, 6)
		if not resolved is Vector2 or resolved == Vector2.INF:
			_defer_security("no_safe_registered_spawn_position", candidates, 0, 0, missing_slots.size(), true)
			return
		var spawn_position := resolved as Vector2
		var separated := true
		for prior in candidates:
			if spawn_position.distance_squared_to(prior) < 44.0 * 44.0:
				separated = false
				break
		if not separated:
			_defer_security("spawn_positions_not_separated", candidates, 0, 0, missing_slots.size(), true)
			return
		positions_by_slot[slot] = spawn_position
		candidates.append(spawn_position)
		_spawn_positions[slot] = spawn_position
	_batch_candidate_positions = candidates.duplicate()
	_batch_queued_count = missing_slots.size()
	_batch_accepted_count = 0
	_batch_rejected_count = 0
	_pending_spawn_count = missing_slots.size()
	security_state = STATE_ACTIVE
	_security_reason = "bounded_security_wave_queued"
	for slot in missing_slots:
		_slot_states[slot] = SLOT_PENDING
	_persist_spawned_state()
	_log_security_diagnostic(&"empty_convoy_security_transition", _security_reason, candidates, _batch_queued_count, 0, 0)
	for slot in missing_slots:
		var scene := scenes[slot % scenes.size()]
		_spawner.call(
			"queue_enemy_spawn",
			scene,
			self,
			positions_by_slot[slot],
			global_position,
			event_id,
			320.0,
			&"raider_grunt",
			Callable(self, "_on_security_enemy_spawned").bind(slot)
		)


func _spawner_service_ready() -> bool:
	if _spawner == null:
		return false
	for method in ["resolve_runtime_walkable_spawn", "get_active_enemy_count", "get_pending_spawn_count", "queue_enemy_spawn"]:
		if not _spawner.has_method(method):
			return false
	return _has_property(_spawner, "max_active_ambient_enemies")


func _registered_defenders_absent_authoritatively() -> bool:
	return _spawner is AmbientEnemySpawner \
		and _has_property(_spawner, "enemy_scenes") \
		and _has_property(_spawner, "enemy_scene")


func _has_property(target: Object, property_name: String) -> bool:
	for property in target.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _registered_enemy_scenes() -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	if _spawner == null:
		return scenes
	var raw_scenes: Variant = _spawner.get("enemy_scenes") if _has_property(_spawner, "enemy_scenes") else []
	if raw_scenes is Array:
		for item in raw_scenes:
			if item is PackedScene:
				scenes.append(item as PackedScene)
	if scenes.is_empty() and _has_property(_spawner, "enemy_scene"):
		var fallback: Variant = _spawner.get("enemy_scene")
		if fallback is PackedScene:
			scenes.append(fallback as PackedScene)
	return scenes


func _on_security_enemy_spawned(enemy: Node2D, slot_index: int) -> void:
	_pending_spawn_count = maxi(0, _pending_spawn_count - 1)
	if slot_index < 0 or slot_index >= _slot_states.size() or _slot_states[slot_index] != SLOT_PENDING:
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
		_batch_rejected_count += 1
		if _pending_spawn_count == 0:
			_finish_spawn_batch()
		return
	if enemy == null or not is_instance_valid(enemy):
		_slot_states[slot_index] = SLOT_RETRYABLE
		_security_reason = "queue_time_spawn_rejected"
		_batch_rejected_count += 1
	else:
		_slot_states[slot_index] = SLOT_ACTIVE
		_assigned_slots[str(slot_index)] = true
		enemy.set_meta("empty_convoy_event_id", String(event_id))
		enemy.set_meta("empty_convoy_slot", str(slot_index))
		var facing: Vector2 = SECURITY_FACING[slot_index] as Vector2
		if enemy.has_method("set_ability_facing"):
			enemy.call("set_ability_facing", facing)
		if enemy.has_method("refresh_enemy_directional_animation"):
			enemy.call("refresh_enemy_directional_animation")
		_configure_ambient_home(enemy)
		_active_enemies[slot_index] = enemy
		if enemy.has_signal("enemy_died"):
			enemy.connect("enemy_died", Callable(self, "_on_security_enemy_died"))
		_batch_accepted_count += 1
	if _pending_spawn_count == 0:
		_finish_spawn_batch()
	queue_redraw()


func _configure_ambient_home(enemy: Node2D) -> void:
	var behavior := enemy.get_node_or_null("EnemyBehaviorStateMachine")
	if behavior == null:
		return
	var profile := StringName(str(enemy.get("behavior_profile_id")))
	if profile != &"":
		behavior.call("setup_profile", profile)
	if behavior.has_method("setup_ambient_home"):
		behavior.call("setup_ambient_home", global_position, event_id, 320.0)


func _finish_spawn_batch() -> void:
	var failed_slots := 0
	for slot_state in _slot_states:
		if slot_state in [SLOT_UNATTEMPTED, SLOT_RETRYABLE]:
			failed_slots += 1
	if failed_slots > 0:
		_retry_attempt_count += 1
		security_state = STATE_DEFERRED if _retry_attempt_count < MAX_SECURITY_RETRIES else STATE_UNRESOLVED
		_security_reason = "queue_time_spawn_rejected"
	elif _all_security_slots_defeated():
		security_state = STATE_CLEARED
		_security_reason = "all_registered_defenders_verified_defeated"
	else:
		security_state = STATE_ACTIVE
		_security_reason = "registered_defenders_active"
	_persist_spawned_state()
	_log_security_diagnostic(&"empty_convoy_security_spawn_batch", _security_reason, _batch_candidate_positions, _batch_queued_count, _batch_accepted_count, _batch_rejected_count)
	queue_redraw()


func _all_security_slots_defeated() -> bool:
	if _slot_states.size() != SECURITY_LIMIT:
		return false
	for slot_state in _slot_states:
		if slot_state != SLOT_DEFEATED:
			return false
	return true


func _on_security_enemy_died(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy) \
			or String(enemy.get_meta("empty_convoy_event_id", "")) != String(event_id):
		return
	var slot := str(enemy.get_meta("empty_convoy_slot", ""))
	if slot.is_empty() or _defeated_slots.has(slot):
		return
	var slot_index := int(slot)
	if slot_index < 0 or slot_index >= _slot_states.size() or _slot_states[slot_index] != SLOT_ACTIVE:
		return
	_defeated_slots.append(slot)
	_slot_states[slot_index] = SLOT_DEFEATED
	_active_enemies.erase(slot_index)
	if _all_security_slots_defeated():
		security_state = STATE_CLEARED
		_security_reason = "all_registered_defenders_verified_defeated"
	elif not _unverified_reentry_slots.is_empty():
		security_state = STATE_UNRESOLVED
		_security_reason = "active_wave_missing_unverified"
	elif _slot_states.has(SLOT_RETRYABLE) or _slot_states.has(SLOT_UNATTEMPTED):
		security_state = STATE_DEFERRED
		_security_reason = "queue_time_spawn_rejected"
	else:
		security_state = STATE_ACTIVE
		_security_reason = "registered_defender_defeated"
	_persist_spawned_state()
	_log_security_diagnostic(&"empty_convoy_security_transition", _security_reason, [], 0, 0, 0)
	queue_redraw()


func _restore_event_state() -> void:
	if event_id.is_empty() or _memory == null or not _memory.has_method("get_payload"):
		return
	var payload: Dictionary = _memory.call("get_payload", event_id)
	if payload.is_empty():
		return
	_custody_trace_recorded = bool(payload.get("custody_trace_recorded", false))
	_salvage_granted = bool(payload.get("salvage_granted", false))
	_empty_defense_authoritative = bool(payload.get("empty_defense_authoritative", false))
	_retry_attempt_count = maxi(0, int(payload.get("security_retry_count", 0)))
	_security_reason = str(payload.get("security_reason", ""))
	expected_enemy_count = maxi(0, int(payload.get("expected_enemy_count", SECURITY_LIMIT)))
	var raw_defeated: Variant = payload.get("defeated_slots", [])
	if raw_defeated is Array:
		for slot in raw_defeated:
			if not _defeated_slots.has(str(slot)):
				_defeated_slots.append(str(slot))
	var raw_slots: Variant = payload.get("slot_states", [])
	if raw_slots is Array and raw_slots.size() == SECURITY_LIMIT:
		for slot_state in raw_slots:
			_slot_states.append(str(slot_state))
	else:
		_slot_states.resize(SECURITY_LIMIT)
		for index in range(SECURITY_LIMIT):
			_slot_states[index] = SLOT_UNATTEMPTED
	for defeated_slot in _defeated_slots:
		var defeated_index := int(defeated_slot)
		if defeated_index >= 0 and defeated_index < _slot_states.size():
			_slot_states[defeated_index] = SLOT_DEFEATED
	security_state = StringName(payload.get("security_state", String(STATE_IDLE)))
	if _custody_trace_recorded:
		security_state = STATE_TRACE_RECORDED if _salvage_granted else STATE_EVIDENCE_ONLY
		return
	if security_state == STATE_EMPTY_DEFENSE and not _empty_defense_authoritative:
		security_state = STATE_UNRESOLVED
		_security_reason = "legacy_empty_defense_not_authoritative"
	if security_state in [STATE_ACTIVE, STATE_DEFERRED, STATE_UNRESOLVED]:
		_reconnect_live_enemies()
	elif security_state == STATE_CLEARED:
		if not _all_security_slots_defeated():
			security_state = STATE_UNRESOLVED
			_security_reason = "clearance_receipt_missing_verified_slot_defeats"
	elif security_state == STATE_EMPTY_DEFENSE:
		_empty_defense_authoritative = true
	elif security_state != STATE_IDLE:
		security_state = STATE_UNRESOLVED
		_security_reason = "invalid_persisted_security_state"
	_persist_spawned_state()


func _reconnect_live_enemies() -> void:
	var observed_slots: Dictionary = {}
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy) \
				or String(enemy.get_meta("empty_convoy_event_id", "")) != String(event_id):
			continue
		var slot := str(enemy.get_meta("empty_convoy_slot", ""))
		if slot.is_empty():
			continue
		var slot_index := int(slot)
		if slot_index < 0 or slot_index >= _slot_states.size():
			continue
		if bool(enemy.get("dead")):
			if not _defeated_slots.has(slot):
				_defeated_slots.append(slot)
			_slot_states[slot_index] = SLOT_DEFEATED
			continue
		_active_enemies[slot_index] = enemy
		observed_slots[slot_index] = true
		_slot_states[slot_index] = SLOT_ACTIVE
		if enemy.has_signal("enemy_died"):
			var callback := Callable(self, "_on_security_enemy_died")
			if not enemy.is_connected("enemy_died", callback):
				enemy.connect("enemy_died", callback)
	_unverified_reentry_slots.clear()
	for index in range(_slot_states.size()):
		if _slot_states[index] == SLOT_UNKNOWN:
			_unverified_reentry_slots.append(index)
		elif _slot_states[index] in [SLOT_ACTIVE, SLOT_PENDING] and not observed_slots.has(index):
			_slot_states[index] = SLOT_UNKNOWN
			_unverified_reentry_slots.append(index)
	if not _unverified_reentry_slots.is_empty():
		security_state = STATE_UNRESOLVED
		_security_reason = "active_wave_missing_unverified"
	elif _all_security_slots_defeated():
		security_state = STATE_CLEARED
		_security_reason = "all_registered_defenders_verified_defeated"
	elif _slot_states.has(SLOT_RETRYABLE) or _slot_states.has(SLOT_UNATTEMPTED):
		security_state = STATE_DEFERRED
	else:
		security_state = STATE_ACTIVE


func _defer_security(reason: String, candidates: Array[Vector2], queued: int, accepted: int, rejected: int, count_retry: bool) -> void:
	if count_retry and _retry_attempt_count >= MAX_SECURITY_RETRIES:
		_mark_security_unresolved("bounded_spawn_retry_limit_reached:%s" % reason, candidates, queued, accepted, rejected)
		return
	if count_retry:
		_retry_attempt_count += 1
	security_state = STATE_DEFERRED
	_security_reason = reason
	for index in range(_slot_states.size()):
		if _slot_states[index] == SLOT_UNATTEMPTED:
			_slot_states[index] = SLOT_RETRYABLE
	_persist_spawned_state()
	_log_security_diagnostic(&"empty_convoy_security_transition", reason, candidates, queued, accepted, rejected)
	queue_redraw()


func _mark_security_unresolved(reason: String, candidates: Array[Vector2], queued: int, accepted: int, rejected: int) -> void:
	security_state = STATE_UNRESOLVED
	_security_reason = reason
	_persist_spawned_state()
	_log_security_diagnostic(&"empty_convoy_security_transition", reason, candidates, queued, accepted, rejected)
	queue_redraw()


func _enter_empty_defense_mode(reason: String) -> void:
	_empty_defense_authoritative = true
	security_state = STATE_EMPTY_DEFENSE
	_security_reason = reason
	_persist_spawned_state({"empty_defense_authoritative": true})
	_log_security_diagnostic(&"empty_convoy_security_transition", reason, [], 0, 0, 0)
	queue_redraw()


func _persist_spawned_state(extra: Dictionary = {}) -> void:
	if _memory == null or not _memory.has_method("mark_spawned"):
		return
	_memory.call("mark_spawned", event_id, _state_payload(extra))


func _state_payload(extra: Dictionary = {}) -> Dictionary:
	var payload := {
		"security_state": String(security_state),
		"security_reason": _security_reason,
		"security_retry_count": _retry_attempt_count,
		"world_seed": _world_seed,
		"expected_enemy_count": expected_enemy_count,
		"slot_states": _slot_states.duplicate(),
		"defeated_slots": _defeated_slots.duplicate(),
		"custody_trace_recorded": _custody_trace_recorded,
		"salvage_granted": _salvage_granted,
		"empty_defense_authoritative": _empty_defense_authoritative,
	}
	for key in extra:
		payload[key] = extra[key]
	return payload


func _log_security_diagnostic(kind: StringName, reason: String, candidates: Array[Vector2], queued: int, accepted: int, rejected: int) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null or not observatory.has_method("log_event") or _diagnostic_event_count >= MAX_SECURITY_DIAGNOSTICS:
		return
	var candidate_text: Array[String] = []
	for position in candidates:
		candidate_text.append("%d,%d" % [roundi(position.x), roundi(position.y)])
	var active_count := int(_spawner.call("get_active_enemy_count")) if _spawner != null and _spawner.has_method("get_active_enemy_count") else -1
	var pending_count := int(_spawner.call("get_pending_spawn_count")) if _spawner != null and _spawner.has_method("get_pending_spawn_count") else -1
	var capacity := -1
	if _spawner != null and _has_property(_spawner, "max_active_ambient_enemies") and active_count >= 0 and pending_count >= 0:
		capacity = maxi(0, int(_spawner.get("max_active_ambient_enemies")) - active_count - pending_count)
	var signature := "%s|%s|%s|%d|%d|%d" % [String(kind), String(security_state), reason, queued, accepted, rejected]
	if signature == _last_diagnostic_signature:
		return
	_last_diagnostic_signature = signature
	_diagnostic_event_count += 1
	var previous_state := _last_diagnostic_state
	_last_diagnostic_state = security_state
	observatory.call("log_event", kind, {
		"event_id": String(event_id),
		"generated_world_seed": _world_seed,
		"previous_state": String(previous_state),
		"state": String(security_state),
		"reason": reason,
		"active_count": active_count,
		"pending_count": pending_count,
		"capacity_available": capacity,
		"candidate_positions": candidate_text,
		"queue_success_count": accepted,
		"queue_failure_count": rejected,
		"queued_count": queued,
		"retry_count": _retry_attempt_count,
	})


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
