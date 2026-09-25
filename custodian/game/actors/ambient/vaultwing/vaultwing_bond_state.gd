extends Node
class_name VaultwingBondState

## Owns persistent bond progress and the transient, interruptible interaction.
## Movement and physical state remain owned by VaultwingBehaviorController.

signal stage_changed(previous: StringName, current: StringName)
signal feed_accepted(bait_id: StringName, feed_count: int)
signal feed_rejected(bait_id: StringName, reason: StringName)
signal bond_completed

const WILD: StringName = &"wild"
const OBSERVING: StringName = &"observing"
const TOLERANT: StringName = &"tolerant"
const ACCEPTING: StringName = &"accepting"
const BONDED: StringName = &"bonded"
const VALID_STAGES := [WILD, OBSERVING, TOLERANT, ACCEPTING, BONDED]
const SAVE_SCHEMA := "custodian.vaultwing_bond.v1"
const SPECIES_ID := "vaultwing_common"

@export var feeds_to_tolerant := 2
@export var feeds_to_accepting := 4
@export var feed_observation_seconds := 0.8
@export var encounter_cooldown_seconds := 2.5
@export var encounter_separation_px := 260.0
@export var trial_guarded_seconds := 1.1
@export var trial_landing_radius := 164.0
@export var trial_final_radius := 76.0
@export var trial_rushed_radius := 58.0
@export var accepted_bait_ids: Array[StringName] = [&"vaultwing_bait", &"carrion"]

var actor: Node2D
var stage: StringName = WILD
var bond_value := 0
var peaceful_feed_count := 0
var stable_creature_id: StringName = &""
var feed_attempt_active := false
var bond_trial_active := false
var trial_phase: StringName = &""
var _feeder: Node2D
var _attempt_bait: StringName = &""
var _attempt_elapsed := 0.0
var _trial_elapsed := 0.0
var _encounter_cooldown := 0.0
var _must_separate := false
var _last_encounter_feeder: Node2D
var _last_encounter_position := Vector2.ZERO
var _trial_initial_distance := INF
var last_rejection_reason: StringName = &""

func _process(delta: float) -> void:
	_encounter_cooldown = maxf(0.0, _encounter_cooldown - delta)
	if _must_separate and (
		_last_encounter_feeder == null
		or not is_instance_valid(_last_encounter_feeder)
		or _last_encounter_feeder.global_position.distance_to(_last_encounter_position) >= encounter_separation_px
	):
		_must_separate = false
		_last_encounter_feeder = null
	if feed_attempt_active:
		if not _attempt_is_safe():
			_interrupt_feed(&"unsafe_interruption")
		elif actor.has_method("is_bait_approach_complete") and not bool(actor.call("is_bait_approach_complete")):
			pass
		else:
			_attempt_elapsed += delta
			if _attempt_elapsed >= feed_observation_seconds:
				_complete_feed_attempt()
	if bond_trial_active:
		_update_trial(delta)

func configure(owner: Node2D, stable_id: StringName = &"") -> void:
	actor = owner
	if stable_id != &"": stable_creature_id = stable_id
	if stable_creature_id == &"": stable_creature_id = &"vaultwing_unassigned"

func get_stage() -> StringName: return stage
func get_stable_creature_id() -> StringName: return stable_creature_id
func is_bonded() -> bool: return stage == BONDED
func is_feed_attempt_active() -> bool: return feed_attempt_active
func is_bond_trial_active() -> bool: return bond_trial_active

func get_operator_tolerance_radius() -> float:
	match stage:
		WILD: return 72.0
		OBSERVING: return 104.0
		TOLERANT: return 148.0
		ACCEPTING: return 192.0
		BONDED: return 0.0
	return 72.0

func get_bait_offer_radius() -> float:
	match stage:
		WILD: return 240.0
		OBSERVING: return 210.0
		TOLERANT: return 180.0
		ACCEPTING: return 160.0
		BONDED: return 0.0
	return 0.0

func get_min_safe_approach_distance() -> float:
	match stage:
		WILD: return 92.0
		OBSERVING: return 72.0
		TOLERANT: return 48.0
		ACCEPTING: return 28.0
		BONDED: return 0.0
	return 92.0

func get_escalation_delay() -> float:
	match stage:
		WILD: return 0.0
		OBSERVING: return 0.55
		TOLERANT: return 1.15
		ACCEPTING: return 1.8
		BONDED: return INF
	return 0.0

func should_hold_safe_near_operator(feeder: Node2D) -> bool:
	return stage in [TOLERANT, ACCEPTING] and feeder != null and is_instance_valid(feeder) and not feed_attempt_active and actor != null and actor.global_position.distance_to(feeder.global_position) <= get_operator_tolerance_radius()

func can_accept_bait(bait_id: StringName, feeder: Node2D = null) -> bool:
	return _rejection_reason(bait_id, feeder) == &""

## Starts one observation attempt. Progress changes only after its safe dwell.
func offer_bait(bait_id: StringName, feeder: Node2D = null) -> bool:
	var reason := _rejection_reason(bait_id, feeder)
	if reason != &"":
		if feed_attempt_active:
			_interrupt_feed(reason)
		else:
			_reject(bait_id, reason)
		return false
	if feed_attempt_active:
		_reject(bait_id, &"attempt_in_progress")
		return false
	if _must_separate or _encounter_cooldown > 0.0:
		_reject(bait_id, &"same_encounter_cooldown")
		return false
	_feeder = feeder
	_attempt_bait = bait_id
	_attempt_elapsed = 0.0
	feed_attempt_active = true
	if actor.has_method("play_action"): actor.call("play_action", &"notice_bait")
	if actor.has_method("request_bait_observation"): actor.call("request_bait_observation", feeder)
	return true

func begin_bond_trial(feeder: Node2D = null) -> bool:
	if stage != ACCEPTING or bond_trial_active or feed_attempt_active:
		last_rejection_reason = &"trial_unavailable"
		_log(&"vaultwing_bond_trial_interrupted", _event_payload({"reason":"trial_unavailable"}))
		return false
	var reason := _trial_feeder_reason(feeder)
	if reason != &"":
		last_rejection_reason = reason
		_reject(&"vaultwing_bait", reason)
		return false
	var distance := actor.global_position.distance_to(feeder.global_position)
	if distance < trial_landing_radius or distance > 420.0:
		last_rejection_reason = &"premature_or_distant_approach"
		_reject(&"vaultwing_bait", &"premature_or_distant_approach")
		return false
	_feeder = feeder
	_trial_initial_distance = distance
	_trial_elapsed = 0.0
	trial_phase = &"voluntary_approach"
	bond_trial_active = true
	if actor.has_method("begin_voluntary_bond_approach"): actor.call("begin_voluntary_bond_approach", feeder)
	_log(&"vaultwing_bond_trial_started", _event_payload({"feeder": feeder.name}))
	return true

func complete_bond_trial(final_bait_id: StringName = &"vaultwing_bait", feeder: Node2D = null) -> bool:
	var reason := _rejection_reason(final_bait_id, feeder)
	if not bond_trial_active or stage != ACCEPTING or trial_phase != &"final_feed_ready": reason = &"trial_not_ready"
	elif feeder != _feeder: reason = &"feeder_changed"
	elif actor.global_position.distance_to(feeder.global_position) > trial_final_radius: reason = &"out_of_range"
	if reason != &"":
		_reject(final_bait_id, reason)
		if bond_trial_active: interrupt_bond_trial(reason)
		return false
	bond_trial_active = false
	trial_phase = &"recognition"
	peaceful_feed_count += 1
	bond_value += 1
	_set_stage(BONDED)
	if actor.has_method("set_allegiance"): actor.call("set_allegiance", ActorAllegianceComponent.OPERATOR_ALLIED)
	if actor.has_method("on_bond_completed"): actor.call("on_bond_completed", feeder)
	if actor.has_method("play_action"): actor.call("play_action", &"bond_greet")
	_log(&"vaultwing_feed_accepted", _event_payload({"bait_id":String(final_bait_id),"feed_count":peaceful_feed_count,"trial":true}))
	_log(&"vaultwing_bond_completed", _event_payload({"species":SPECIES_ID}))
	bond_completed.emit()
	trial_phase = &""
	_feeder = null
	_set_bonded_gauge()
	return true

func notify_actor_landed() -> void:
	if bond_trial_active and trial_phase == &"voluntary_approach":
		trial_phase = &"guarded_observation"
		_trial_elapsed = 0.0

func interrupt_bond_trial(reason: StringName = &"interrupted") -> void:
	if not bond_trial_active: return
	bond_trial_active = false
	var payload := _event_payload({"reason":String(reason),"phase":String(trial_phase)})
	_log(&"vaultwing_bond_trial_interrupted", payload)
	trial_phase = &""
	_feeder = null
	if actor.has_method("cancel_voluntary_bond_approach"): actor.call("cancel_voluntary_bond_approach")

func interrupt_interaction(reason: StringName = &"interrupted") -> void:
	if feed_attempt_active: _interrupt_feed(reason)
	if bond_trial_active: interrupt_bond_trial(reason)

func to_save_dict() -> Dictionary:
	return {
		"schema":SAVE_SCHEMA,
		"species_id":SPECIES_ID,
		"runtime_identity":SPECIES_ID,
		"stable_creature_id":String(stable_creature_id),
		"stage":String(stage),
		"bond_value":bond_value,
		"peaceful_feed_count":peaceful_feed_count,
		"bonded":stage == BONDED,
		"health":float(actor.get("health")) if actor != null else 0.0,
		"max_health":float(actor.get("max_health")) if actor != null else 0.0,
	}

func from_save_dict(data: Dictionary) -> bool:
	if str(data.get("schema", "")) != SAVE_SCHEMA or str(data.get("species_id", "")) != SPECIES_ID or str(data.get("runtime_identity", "")) != SPECIES_ID:
		return false
	for required_key in ["stable_creature_id", "stage", "bond_value", "peaceful_feed_count", "bonded", "health", "max_health"]:
		if not data.has(required_key): return false
	if typeof(data.bond_value) != TYPE_INT or typeof(data.peaceful_feed_count) != TYPE_INT:
		return false
	if typeof(data.bonded) != TYPE_BOOL or typeof(data.stable_creature_id) != TYPE_STRING or typeof(data.stage) != TYPE_STRING:
		return false
	if typeof(data.health) not in [TYPE_INT, TYPE_FLOAT] or typeof(data.max_health) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var loaded_stage := StringName(str(data.get("stage", String(WILD))))
	var loaded_id := StringName(str(data.get("stable_creature_id", "")))
	var loaded_health := float(data.get("health", -1.0))
	var loaded_max_health := float(data.get("max_health", -1.0))
	if loaded_stage not in VALID_STAGES or loaded_id == &"" or not is_finite(loaded_health) or not is_finite(loaded_max_health) or loaded_health < 0.0 or loaded_max_health <= 0.0 or loaded_health > loaded_max_health:
		return false
	if int(data.bond_value) < 0 or int(data.peaceful_feed_count) < 0:
		return false
	if bool(data.get("bonded", loaded_stage == BONDED)) != (loaded_stage == BONDED): return false
	if actor != null and actor.has_method("reset_bond_transient_state"):
		actor.call("reset_bond_transient_state")
	stable_creature_id = loaded_id
	stage = loaded_stage
	bond_value = maxi(0, int(data.get("bond_value", 0)))
	peaceful_feed_count = maxi(0, int(data.get("peaceful_feed_count", 0)))
	feed_attempt_active = false
	bond_trial_active = false
	trial_phase = &""
	_feeder = null
	_encounter_cooldown = 0.0
	_must_separate = false
	_last_encounter_feeder = null
	if actor != null:
		actor.set("max_health", loaded_max_health)
		actor.set("health", loaded_health)
		if actor.has_method("set_allegiance"):
			actor.call("set_allegiance", ActorAllegianceComponent.OPERATOR_ALLIED if stage == BONDED else ActorAllegianceComponent.HOSTILE)
		if stage == BONDED and actor.has_method("on_bond_completed"):
			actor.call("on_bond_completed", get_tree().get_first_node_in_group("player"))
	_set_bonded_gauge()
	return true

func _update_trial(delta: float) -> void:
	if not _feeder_is_valid():
		interrupt_bond_trial(&"feeder_invalid")
		return
	if not _actor_in_safe_interaction_state():
		# Flight is valid only during the voluntary approach.
		if trial_phase != &"voluntary_approach": interrupt_bond_trial(&"unsafe_combat")
		return
	var distance := actor.global_position.distance_to(_feeder.global_position)
	if trial_phase == &"voluntary_approach":
		if distance <= trial_landing_radius and actor.has_method("get_altitude_band_name") and actor.call("get_altitude_band_name") in [&"ground",&"perched"]:
			notify_actor_landed()
	elif trial_phase == &"guarded_observation":
		if distance < trial_rushed_radius:
			interrupt_bond_trial(&"rushed_approach")
			return
		_trial_elapsed += delta
		if _trial_elapsed >= trial_guarded_seconds:
			trial_phase = &"final_feed_ready"
			if actor.has_method("play_action"): actor.call("play_action", &"watch_player")

func _rejection_reason(bait_id: StringName, feeder: Node2D) -> StringName:
	if actor == null or not is_instance_valid(actor): return &"actor_invalid"
	if stage == BONDED: return &"already_bonded"
	if bait_id not in accepted_bait_ids: return &"invalid_bait"
	if feeder == null or not is_instance_valid(feeder) or not feeder.is_in_group("player"): return &"invalid_feeder"
	if feeder.has_method("is_dead") and bool(feeder.call("is_dead")): return &"feeder_invalid"
	if actor.has_method("is_dead") and bool(actor.call("is_dead")): return &"dead"
	if not _actor_in_safe_interaction_state(): return &"unsafe_state"
	var distance := actor.global_position.distance_to(feeder.global_position)
	if distance > get_bait_offer_radius(): return &"out_of_range"
	if distance < get_min_safe_approach_distance(): return &"too_close"
	return &""

func _trial_feeder_reason(feeder: Node2D) -> StringName:
	if actor == null or not is_instance_valid(actor) or (actor.has_method("is_dead") and bool(actor.call("is_dead"))): return &"actor_invalid"
	if feeder == null or not is_instance_valid(feeder) or not feeder.is_in_group("player"): return &"invalid_feeder"
	if stage != ACCEPTING: return &"trial_unavailable"
	if not _actor_in_safe_interaction_state() and actor.call("get_altitude_band_name") not in [&"high", &"attack"]:
		return &"unsafe_combat"
	var state := StringName(str(actor.call("get_state_name"))) if actor.has_method("get_state_name") else &""
	if state in [&"dive_windup",&"dive_strike",&"climb_out",&"air_stagger",&"ground_stagger",&"ground_attack",&"ground_stalk",&"land",&"takeoff",&"retreat",&"dead"]: return &"unsafe_combat"
	return &""

func _actor_in_safe_interaction_state() -> bool:
	if actor == null or not is_instance_valid(actor): return false
	if actor.has_method("is_dead") and bool(actor.call("is_dead")): return false
	var state := StringName(str(actor.call("get_state_name"))) if actor.has_method("get_state_name") else &""
	return state in [&"ground_idle", &"perch_idle"]

func _attempt_is_safe() -> bool:
	if not feed_attempt_active or not _feeder_is_valid() or not _actor_in_safe_interaction_state(): return false
	var distance := actor.global_position.distance_to(_feeder.global_position)
	return distance <= get_bait_offer_radius() and distance >= get_min_safe_approach_distance()

func _complete_feed_attempt() -> void:
	feed_attempt_active = false
	if actor.has_method("finish_bait_observation"): actor.call("finish_bait_observation")
	peaceful_feed_count += 1
	bond_value += 1
	var bait := _attempt_bait
	_log(&"vaultwing_feed_accepted", _event_payload({"bait_id":String(bait),"feed_count":peaceful_feed_count}))
	feed_accepted.emit(bait, peaceful_feed_count)
	var next := stage
	if stage == WILD: next = OBSERVING
	elif stage == OBSERVING and peaceful_feed_count >= feeds_to_tolerant: next = TOLERANT
	elif stage == TOLERANT and peaceful_feed_count >= feeds_to_accepting: next = ACCEPTING
	if next != stage: _set_stage(next)
	if actor.has_method("play_action"): actor.call("play_action", &"feed_accept")
	_encounter_cooldown = encounter_cooldown_seconds
	_must_separate = true
	_last_encounter_feeder = _feeder
	_last_encounter_position = _feeder.global_position
	_feeder = null
	_attempt_bait = &""

func _interrupt_feed(reason: StringName) -> void:
	last_rejection_reason = reason
	var bait := _attempt_bait
	feed_attempt_active = false
	if actor != null and actor.has_method("finish_bait_observation"): actor.call("finish_bait_observation")
	_feeder = null
	_attempt_bait = &""
	_log(&"vaultwing_feed_rejected", _event_payload({"bait_id":String(bait),"reason":String(reason)}))
	feed_rejected.emit(bait, reason)

func _reject(bait_id: StringName, reason: StringName) -> void:
	last_rejection_reason = reason
	feed_rejected.emit(bait_id, reason)
	_log(&"vaultwing_feed_rejected", _event_payload({"bait_id":String(bait_id),"reason":String(reason)}))

func _feeder_is_valid() -> bool:
	return _feeder != null and is_instance_valid(_feeder) and _feeder.is_in_group("player") and not (_feeder.has_method("is_dead") and bool(_feeder.call("is_dead")))

func _set_stage(next: StringName) -> void:
	if next == stage: return
	var previous := stage
	stage = next
	stage_changed.emit(previous, stage)
	_log(&"vaultwing_bond_stage_changed", _event_payload({"previous":String(previous),"current":String(stage)}))
	_set_bonded_gauge()

func _event_payload(extra: Dictionary = {}) -> Dictionary:
	var payload := {"stable_creature_id":String(stable_creature_id),"stage":String(stage)}
	payload.merge(extra, true)
	return payload

func _set_bonded_gauge() -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null or not observatory.has_method("set_gauge"): return
	var count := 0
	for candidate in get_tree().get_nodes_in_group("vaultwing"):
		if is_instance_valid(candidate) and candidate.has_method("is_bonded") and bool(candidate.call("is_bonded")): count += 1
	observatory.call("set_gauge", "bonded_vaultwings", count)

func _log(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"): observatory.call("log_event", event_name, payload)
