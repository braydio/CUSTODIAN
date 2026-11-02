extends Node

signal network_scanned(snapshot: Dictionary)
signal relay_registered(relay_id: StringName)
signal relay_state_changed(relay_id: StringName, snapshot: Dictionary)
signal stabilization_started(relay_id: StringName, ticks_required: int)
signal stabilization_progressed(relay_id: StringName, progress: float)
signal stabilization_completed(relay_id: StringName, packets_pending: int)
signal sync_completed(result: Dictionary)
signal knowledge_changed(knowledge_index: int, benefits: Dictionary)

const RelayDataScript := preload("res://game/systems/core/systems/arrn/relay_data.gd")
const StabilizationTaskScript := preload("res://game/systems/core/systems/arrn/stabilization_task.gd")
const KnowledgeSystemScript := preload("res://game/systems/core/systems/arrn/knowledge_system.gd")
const BenefitsManagerScript := preload("res://game/systems/core/systems/arrn/benefits_manager.gd")

const STATUS_UNKNOWN := 0
const STATUS_LOCATED := 1
const STATUS_UNSTABLE := 2
const STATUS_STABLE := 3
const STATUS_WEAK := 4
const STATUS_DORMANT := 5
const RISK_TRANSIT := 0
const RISK_FRINGE := 1
const RISK_CORE := 2
const KNOWLEDGE_MAX: int = 7
const RELAY_STABLE_MIN: float = 70.0
const RELAY_WEAK_MIN: float = 30.0
const RELAY_STABILITY_MAX: float = 100.0
const WEAK_SYNC_FAIL_CHANCE: float = 0.10
const RELAY_DECAY_BASE: float = 0.5
const RELAY_DECAY_PER_ASSAULT: float = 0.2
const KNOWLEDGE_DRIFT_PERIOD: int = 40

var relay_nodes: Dictionary = {}
var knowledge_index: int = 0
var knowledge_track: String = "RELAY_RECOVERY"
var relay_packets_pending: int = 0
var dormancy_pressure: int = 0
var benefits: Dictionary = {}

var _network_scanned: bool = false
var _last_game_tick: int = -1
var _active_tasks: Dictionary = {}
var _registered_entities: Dictionary = {}
var _knowledge_system = KnowledgeSystemScript.new()
var _benefits_manager = BenefitsManagerScript.new()


func _ready() -> void:
	add_to_group("arrn_manager")
	_initialize_default_relays()
	_update_benefits()
	set_process(true)


func _process(_delta: float) -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	var current_tick := int(game_state.get("tick"))
	if _last_game_tick < 0:
		_last_game_tick = current_tick
	while _last_game_tick < current_tick:
		_last_game_tick += 1
		tick_relays(_last_game_tick)


func _initialize_default_relays() -> void:
	relay_nodes.clear()
	_add_default_relay(&"R_NORTH", &"T_NORTH", STATUS_LOCATED, 80.0, RISK_TRANSIT, 3)
	_add_default_relay(&"R_SOUTH", &"T_SOUTH", STATUS_LOCATED, 80.0, RISK_TRANSIT, 3)
	_add_default_relay(&"R_ARCHIVE", &"ARCHIVE", STATUS_UNKNOWN, 40.0, RISK_FRINGE, 4)
	_add_default_relay(&"R_GATEWAY", &"GATEWAY", STATUS_UNKNOWN, 40.0, RISK_FRINGE, 4)
	_recalculate_dormancy_pressure()


func _add_default_relay(relay_id: StringName, sector_id: StringName, status: int, stability: float, risk_profile: int, ticks_required: int) -> void:
	var relay = RelayDataScript.new()
	relay.configure(relay_id, sector_id, status, stability, risk_profile, ticks_required)
	relay_nodes[String(relay_id)] = relay
	_update_status_from_stability(relay, false)


func scan_network(fidelity: String = "FULL") -> Dictionary:
	_network_scanned = true
	for relay in relay_nodes.values():
		if relay != null:
			relay.is_interactable = true
			_update_status_from_stability(relay, false)
	_update_registered_entities()
	var snapshot := get_snapshot(fidelity)
	network_scanned.emit(snapshot)
	return snapshot


func get_snapshot(fidelity: String = "FULL") -> Dictionary:
	var relay_list: Array[Dictionary] = []
	for relay_id in _sorted_relay_ids():
		var relay = relay_nodes[relay_id]
		relay_list.append(relay.to_snapshot(_network_scanned))
	return {
		"scanned": _network_scanned,
		"fidelity": _apply_fidelity_benefit(fidelity),
		"knowledge_track": knowledge_track,
		"knowledge_index": knowledge_index,
		"knowledge_max": KNOWLEDGE_MAX,
		"relay_packets_pending": relay_packets_pending,
		"dormancy_pressure": dormancy_pressure,
		"benefits": benefits.duplicate(true),
		"benefit_labels": _benefits_manager.unlocked_labels(knowledge_index),
		"relays": relay_list,
		"active_tasks": get_tasks_snapshot(),
	}


func get_scan_lines(fidelity: String = "FULL") -> Array[String]:
	var effective_fidelity := _apply_fidelity_benefit(fidelity)
	if effective_fidelity == "LOST":
		return ["RELAY SCAN: NO SIGNAL."]
	var lines: Array[String] = []
	if effective_fidelity == "FRAGMENTED":
		lines.append("SIGNAL IRREGULAR. CONTACT REQUIRES FIELD VERIFICATION.")
		for relay_id in _sorted_relay_ids():
			var relay = relay_nodes[relay_id]
			lines.append("- %s: CONTACT | SECTOR %s | CONFIDENCE LOW" % [String(relay.relay_id), String(relay.sector_id)])
		return lines
	lines.append("RELAY NETWORK:")
	for relay_id in _sorted_relay_ids():
		var relay = relay_nodes[relay_id]
		if effective_fidelity == "DEGRADED":
			lines.append("- %s: %s | SECTOR %s" % [
				String(relay.relay_id),
				RelayDataScript.status_to_string(relay.status),
				String(relay.sector_id),
			])
		else:
			lines.append("- %s: %s | SECTOR %s | STABILITY %d | STABILIZE %d TICKS" % [
				String(relay.relay_id),
				RelayDataScript.status_to_string(relay.status),
				String(relay.sector_id),
				int(round(relay.stability)),
				relay.stability_ticks_required,
			])
	lines.append("PENDING PACKETS: %d" % relay_packets_pending)
	lines.append("KNOWLEDGE INDEX: %d/%d" % [knowledge_index, KNOWLEDGE_MAX])
	lines.append("DORMANCY PRESSURE: %d" % dormancy_pressure)
	return lines


func register_relay_entity(relay_id: StringName, entity: Node) -> void:
	var key := String(relay_id)
	if not relay_nodes.has(key):
		return
	_registered_entities[key] = entity
	relay_registered.emit(relay_id)
	_update_entity(key)


func unregister_relay_entity(relay_id: StringName, entity: Node) -> void:
	var key := String(relay_id)
	if _registered_entities.get(key) == entity:
		_registered_entities.erase(key)


func set_relay_world_position(relay_id: StringName, world_position: Vector2) -> void:
	var relay: Variant = get_relay(relay_id)
	if relay == null:
		return
	relay.world_position = world_position
	_emit_relay_changed(relay)


func get_relay(relay_id: StringName):
	return relay_nodes.get(String(relay_id), null)


func is_network_scanned() -> bool:
	return _network_scanned


func can_stabilize(relay_id: StringName) -> Dictionary:
	var relay: Variant = get_relay(relay_id)
	if relay == null:
		return {"ok": false, "reason": "UNKNOWN_RELAY"}
	if _active_tasks.has(String(relay_id)):
		return {"ok": false, "reason": "TASK_ACTIVE"}
	if relay.status == STATUS_STABLE and relay.stability >= RELAY_STABILITY_MAX:
		return {"ok": false, "reason": "ALREADY_STABLE"}
	return {"ok": true, "reason": "OK"}


func start_stabilization(relay_id: StringName, actor: Node = null) -> Dictionary:
	var check := can_stabilize(relay_id)
	if not bool(check.get("ok", false)):
		return check
	var relay: Variant = get_relay(relay_id)
	var tick := _get_current_tick()
	var actor_id := actor.get_instance_id() if actor != null else 0
	var task = StabilizationTaskScript.new(relay_id, relay.stability_ticks_required, actor_id, tick)
	_active_tasks[String(relay_id)] = task
	if actor != null and actor.has_method("set_arrn_stabilization_locked"):
		actor.call("set_arrn_stabilization_locked", true)
	stabilization_started.emit(relay_id, relay.stability_ticks_required)
	return {"ok": true, "reason": "STARTED", "task": task.to_snapshot()}


func complete_stabilization_now(relay_id: StringName, actor: Node = null) -> Dictionary:
	var started := start_stabilization(relay_id, actor)
	if not bool(started.get("ok", false)) and str(started.get("reason", "")) != "TASK_ACTIVE":
		return started
	while _active_tasks.has(String(relay_id)):
		_advance_stabilization_task(String(relay_id), _get_current_tick())
	return {"ok": true, "reason": "COMPLETED"}


func get_tasks_snapshot() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for task in _active_tasks.values():
		if task != null:
			out.append(task.to_snapshot())
	return out


func sync_packets() -> Dictionary:
	if relay_packets_pending <= 0:
		return {"ok": false, "reason": "NO_PENDING_PACKETS", "knowledge_index": knowledge_index}
	var packets := relay_packets_pending
	var weak_count := _count_relays_with_status(STATUS_WEAK)
	var active_relays := _count_active_relays()
	var failed := _deterministic_weak_failures(packets, weak_count)
	var gain := _knowledge_system.compute_sync_gain(packets, weak_count, active_relays, failed)
	var old_index := knowledge_index
	knowledge_index = min(KNOWLEDGE_MAX, knowledge_index + gain)
	relay_packets_pending = 0
	_update_benefits()
	var result := {
		"ok": true,
		"packets": packets,
		"failed": failed,
		"successful": maxi(0, packets - failed),
		"effective_gain": gain,
		"old_knowledge_index": old_index,
		"knowledge_index": knowledge_index,
		"knowledge_max": KNOWLEDGE_MAX,
		"benefit": _benefits_manager.label_for_level(knowledge_index) if knowledge_index > old_index else "",
		"benefits": benefits.duplicate(true),
	}
	sync_completed.emit(result)
	knowledge_changed.emit(knowledge_index, benefits.duplicate(true))
	return result


func tick_relays(game_tick: int = -1) -> void:
	var tick := _get_current_tick() if game_tick < 0 else game_tick
	for relay_id in _active_tasks.keys().duplicate():
		_advance_stabilization_task(str(relay_id), tick)
	var active_assaults := _get_active_assault_count()
	var decay_rate := RELAY_DECAY_BASE + float(active_assaults) * RELAY_DECAY_PER_ASSAULT
	for relay in relay_nodes.values():
		if relay == null:
			continue
		var relay_data = relay
		if _active_tasks.has(String(relay_data.relay_id)):
			continue
		if relay_data.last_stabilized_time == tick:
			continue
		relay_data.stability = clampf(relay_data.stability - decay_rate, 0.0, RELAY_STABILITY_MAX)
		_update_status_from_stability(relay_data, true)
	_recalculate_dormancy_pressure()
	_apply_knowledge_drift(tick)


func has_benefit(benefit_id: String) -> bool:
	return bool(benefits.get(benefit_id.strip_edges().to_lower(), false))


func get_repair_power_cost(base_cost: float) -> float:
	if has_benefit("maintenance_archive_i"):
		return maxf(1.0, base_cost - 1.0)
	return base_cost


func get_threat_warning_tick_bonus() -> int:
	return 2 if has_benefit("threat_forecast_i") else 0


func get_logistics_penalty_multiplier() -> float:
	return 0.9 if has_benefit("logistics_optimization_i") else 1.0


func apply_fidelity_benefit(fidelity: String) -> String:
	return _apply_fidelity_benefit(fidelity)


func are_archive_blueprints_unlocked() -> bool:
	return has_benefit("fab_blueprints_i") or has_benefit("fab_blueprints_archive")


func _advance_stabilization_task(relay_key: String, tick: int) -> void:
	var task = _active_tasks.get(relay_key, null)
	if task == null:
		_active_tasks.erase(relay_key)
		return
	if not task.tick():
		stabilization_progressed.emit(task.relay_id, task.progress())
		return
	var relay: Variant = get_relay(task.relay_id)
	if relay != null:
		relay.status = STATUS_STABLE
		relay.stability = RELAY_STABILITY_MAX
		relay.current_signal_strength = 1.0
		relay.last_stabilized_time = tick
		relay.is_interactable = true
		relay_packets_pending += 1
		_emit_relay_changed(relay)
	_unlock_task_actor(task)
	_active_tasks.erase(relay_key)
	_recalculate_dormancy_pressure()
	stabilization_progressed.emit(task.relay_id, 1.0)
	stabilization_completed.emit(task.relay_id, relay_packets_pending)


func _unlock_task_actor(task) -> void:
	if task.actor_instance_id == 0:
		return
	for node in get_tree().get_nodes_in_group("player"):
		if node != null and node.get_instance_id() == task.actor_instance_id and node.has_method("set_arrn_stabilization_locked"):
			node.call("set_arrn_stabilization_locked", false)
			return
	for node in get_tree().get_nodes_in_group("operator"):
		if node != null and node.get_instance_id() == task.actor_instance_id and node.has_method("set_arrn_stabilization_locked"):
			node.call("set_arrn_stabilization_locked", false)
			return


func _update_status_from_stability(relay, emit_change: bool) -> void:
	if relay.status == STATUS_UNKNOWN and not _network_scanned:
		return
	var previous: int = int(relay.status)
	if relay.stability >= RELAY_STABLE_MIN:
		relay.status = STATUS_STABLE
	elif relay.stability >= RELAY_WEAK_MIN:
		relay.status = STATUS_WEAK if _network_scanned else relay.status
	else:
		relay.status = STATUS_DORMANT if _network_scanned else relay.status
	relay.current_signal_strength = clampf(relay.stability / RELAY_STABILITY_MAX, 0.0, 1.0)
	if emit_change and previous != relay.status:
		_emit_relay_changed(relay)


func _emit_relay_changed(relay) -> void:
	_update_entity(String(relay.relay_id))
	relay_state_changed.emit(relay.relay_id, relay.to_snapshot(_network_scanned))


func _update_registered_entities() -> void:
	for relay_id in _registered_entities.keys():
		_update_entity(str(relay_id))


func _update_entity(relay_key: String) -> void:
	var entity: Node = _registered_entities.get(relay_key, null)
	var relay = relay_nodes.get(relay_key, null)
	if entity == null or relay == null or not is_instance_valid(entity):
		return
	if entity.has_method("apply_arrn_state"):
		entity.call("apply_arrn_state", relay.to_snapshot(_network_scanned), _network_scanned)


func _recalculate_dormancy_pressure() -> void:
	var dormant := _count_relays_with_status(STATUS_DORMANT)
	if has_benefit("archival_synthesis"):
		dormant = int(floor(float(dormant) * 0.5))
	dormancy_pressure = dormant


func _apply_knowledge_drift(tick: int) -> void:
	if tick <= 0 or tick % KNOWLEDGE_DRIFT_PERIOD != 0:
		return
	if dormancy_pressure < 3 or knowledge_index <= 0:
		return
	knowledge_index -= 1
	_update_benefits()
	knowledge_changed.emit(knowledge_index, benefits.duplicate(true))


func _update_benefits() -> void:
	benefits = _benefits_manager.build_benefits(knowledge_index)


func _apply_fidelity_benefit(fidelity: String) -> String:
	var normalized := fidelity.strip_edges().to_upper()
	if normalized.is_empty():
		normalized = "FULL"
	if has_benefit("signal_reconstruction_ii") and normalized in ["LOST", "FRAGMENTED"]:
		return "DEGRADED"
	if has_benefit("signal_reconstruction_i") and normalized == "DEGRADED":
		return "FULL"
	return normalized


func _deterministic_weak_failures(packets: int, weak_count: int) -> int:
	var failed := 0
	var attempts := mini(maxi(0, weak_count), maxi(0, packets))
	for i in range(attempts):
		var roll := _stable_unit_roll("%d:%d:%d:%d" % [_get_current_tick(), knowledge_index, relay_packets_pending, i])
		if roll < WEAK_SYNC_FAIL_CHANCE:
			failed += 1
	return failed


func _stable_unit_roll(text: String) -> float:
	var value := 2166136261
	for index in range(text.length()):
		value = value ^ text.unicode_at(index)
		value = (value * 16777619) & 0x7fffffff
	return float(value % 10000) / 10000.0


func _count_relays_with_status(status: int) -> int:
	var count := 0
	for relay in relay_nodes.values():
		if relay != null and relay.status == status:
			count += 1
	return count


func _count_active_relays() -> int:
	var count := 0
	for relay in relay_nodes.values():
		if relay != null and relay.status in [STATUS_STABLE, STATUS_WEAK]:
			count += 1
	return count


func _sorted_relay_ids() -> Array[String]:
	var ids: Array[String] = []
	for relay_id in relay_nodes.keys():
		ids.append(str(relay_id))
	ids.sort()
	return ids


func _get_current_tick() -> int:
	var game_state := _get_game_state()
	if game_state == null:
		return Engine.get_physics_frames()
	return int(game_state.get("tick"))


func _get_active_assault_count() -> int:
	var game_state := _get_game_state()
	if game_state != null and "current_phase" in game_state and game_state.get("current_phase") == game_state.Phase.ASSAULT_ACTIVE:
		return 1
	var wave_manager := get_node_or_null("/root/GameRoot/WaveManager")
	if wave_manager != null and wave_manager.has_method("get_wave_status"):
		var status = wave_manager.call("get_wave_status")
		if status is Dictionary and bool((status as Dictionary).get("active", false)):
			return 1
	return 0


func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState")
