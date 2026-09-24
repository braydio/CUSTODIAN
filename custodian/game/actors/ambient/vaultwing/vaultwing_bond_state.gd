extends Node
class_name VaultwingBondState

## Slice B relationship/progression authority. This node owns bond semantics;
## Vaultwing remains the physical actor and behavior authority.

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

@export var feeds_to_tolerant := 2
@export var feeds_to_accepting := 4
@export var accepted_bait_ids: Array[StringName] = [&"vaultwing_bait", &"carrion"]

var actor: Node2D
var stage: StringName = WILD
var bond_value := 0
var peaceful_feed_count := 0
var stable_creature_id: StringName = &""
var bond_trial_active := false

func configure(owner: Node2D, stable_id: StringName = &"") -> void:
	actor = owner
	if stable_id != &"": stable_creature_id = stable_id
	if stable_creature_id == &"": stable_creature_id = &"vaultwing_unassigned"

func get_stage() -> StringName:
	return stage

func get_stable_creature_id() -> StringName:
	return stable_creature_id

func is_bonded() -> bool:
	return stage == BONDED

func can_accept_bait(bait_id: StringName, feeder: Node2D = null) -> bool:
	if actor == null or not is_instance_valid(actor): return false
	if stage == BONDED or bait_id not in accepted_bait_ids: return false
	if feeder != null:
		if not is_instance_valid(feeder) or not feeder.is_in_group("player"): return false
		var allowed := 112.0 if stage == WILD else 144.0
		if actor.global_position.distance_to(feeder.global_position) > allowed: return false
	if actor.has_method("is_dead") and bool(actor.call("is_dead")): return false
	if actor.has_method("get_altitude_band_name") and actor.call("get_altitude_band_name") not in [&"ground", &"perched"]: return false
	return true

func offer_bait(bait_id: StringName, feeder: Node2D = null) -> bool:
	if not can_accept_bait(bait_id, feeder):
		feed_rejected.emit(bait_id, _rejection_reason(bait_id, feeder))
		_log(&"vaultwing_feed_rejected", {"bait_id": String(bait_id), "stage": String(stage)})
		return false
	peaceful_feed_count += 1
	bond_value += 1
	feed_accepted.emit(bait_id, peaceful_feed_count)
	_log(&"vaultwing_feed_accepted", {"bait_id": String(bait_id), "feed_count": peaceful_feed_count})
	var next := stage
	if stage == WILD: next = OBSERVING
	elif stage == OBSERVING and peaceful_feed_count >= feeds_to_tolerant: next = TOLERANT
	elif stage == TOLERANT and peaceful_feed_count >= feeds_to_accepting: next = ACCEPTING
	if next != stage: _set_stage(next)
	return true

func begin_bond_trial() -> bool:
	if stage != ACCEPTING or bond_trial_active: return false
	bond_trial_active = true
	return true

func complete_bond_trial(final_bait_id: StringName = &"vaultwing_bait", feeder: Node2D = null) -> bool:
	if not bond_trial_active or stage != ACCEPTING: return false
	if not can_accept_bait(final_bait_id, feeder):
		feed_rejected.emit(final_bait_id, &"trial_invalid")
		return false
	bond_trial_active = false
	_set_stage(BONDED)
	if actor != null and actor.has_method("set_allegiance"):
		actor.call("set_allegiance", ActorAllegianceComponent.OPERATOR_ALLIED)
	_log(&"vaultwing_bond_completed", {"stable_creature_id": String(stable_creature_id)})
	bond_completed.emit()
	return true

func to_save_dict() -> Dictionary:
	return {
		"stable_creature_id": String(stable_creature_id),
		"stage": String(stage),
		"bond_value": bond_value,
		"peaceful_feed_count": peaceful_feed_count,
		"bond_trial_active": bond_trial_active,
	}

func from_save_dict(data: Dictionary) -> bool:
	var loaded_stage := StringName(str(data.get("stage", String(WILD))))
	if loaded_stage not in VALID_STAGES: return false
	var loaded_id := StringName(str(data.get("stable_creature_id", "")))
	if loaded_id == &"": return false
	stable_creature_id = loaded_id
	stage = loaded_stage
	bond_value = maxi(0, int(data.get("bond_value", 0)))
	peaceful_feed_count = maxi(0, int(data.get("peaceful_feed_count", 0)))
	bond_trial_active = bool(data.get("bond_trial_active", false)) and stage == ACCEPTING
	if actor != null and actor.has_method("set_allegiance"):
		actor.call("set_allegiance", ActorAllegianceComponent.OPERATOR_ALLIED if stage == BONDED else ActorAllegianceComponent.HOSTILE)
	return true

func _set_stage(next: StringName) -> void:
	if next == stage: return
	var previous := stage
	stage = next
	stage_changed.emit(previous, stage)
	_log(&"vaultwing_bond_stage_changed", {"previous": String(previous), "current": String(stage)})

func _rejection_reason(bait_id: StringName, feeder: Node2D) -> StringName:
	if stage == BONDED: return &"already_bonded"
	if bait_id not in accepted_bait_ids: return &"invalid_bait"
	if feeder == null or not is_instance_valid(feeder) or not feeder.is_in_group("player"): return &"invalid_feeder"
	if actor != null and actor.has_method("get_altitude_band_name") and actor.call("get_altitude_band_name") not in [&"ground", &"perched"]: return &"not_grounded"
	return &"out_of_range"

func _log(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)
