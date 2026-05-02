class_name CognitiveStateSystem
extends Node

signal cognitive_values_changed(recollection: float, instinct: float, bearing: float)
signal dominant_state_changed(old_state: StringName, new_state: StringName)
signal instinct_action_requested(action_id: StringName)
signal cognitive_item_collected(item_id: StringName, amount: int)

const STATE_DRIFT := &"DRIFT"
const STATE_FLOW := &"FLOW"
const STATE_ALIGNMENT := &"ALIGNMENT"
const STATE_MIXED := &"MIXED"

const ITEM_AXIS := {
	&"faint_recollection": &"recollection",
	&"residual_instinct": &"instinct",
	&"ancient_bearing": &"bearing",
}

@export var recollection: float = 0.0
@export var instinct: float = 0.0
@export var bearing: float = 0.0
@export var instinct_meter: float = 0.0
@export var decay_per_second: float = 0.02
@export var mixed_state_margin: float = 0.08

var _dominant_state: StringName = STATE_MIXED


func _ready() -> void:
	_dominant_state = _calculate_dominant_state()


func _process(delta: float) -> void:
	if decay_per_second <= 0.0:
		return
	var old_values := Vector3(recollection, instinct, bearing)
	recollection = max(0.0, recollection - decay_per_second * delta)
	instinct = max(0.0, instinct - decay_per_second * delta)
	bearing = max(0.0, bearing - decay_per_second * delta)
	if not old_values.is_equal_approx(Vector3(recollection, instinct, bearing)):
		_emit_values_changed()


func add_from_item(item_id: StringName, amount: int = 1) -> void:
	if item_id == &"" or amount <= 0:
		return
	var value := float(amount)
	match ITEM_AXIS.get(item_id, &""):
		&"recollection":
			add_recollection(value)
		&"instinct":
			add_instinct(value)
		&"bearing":
			add_bearing(value)
		_:
			return
	cognitive_item_collected.emit(item_id, amount)


func add_recollection(amount: float) -> void:
	if amount <= 0.0:
		return
	recollection += amount
	_emit_values_changed()


func add_instinct(amount: float) -> void:
	if amount <= 0.0:
		return
	instinct += amount
	instinct_meter += amount
	_emit_values_changed()


func add_bearing(amount: float) -> void:
	if amount <= 0.0:
		return
	bearing += amount
	_emit_values_changed()


func get_weights() -> Dictionary:
	var total := recollection + instinct + bearing
	if total <= 0.001:
		return {
			"recollection": 0.0,
			"instinct": 0.0,
			"bearing": 0.0,
		}
	return {
		"recollection": recollection / total,
		"instinct": instinct / total,
		"bearing": bearing / total,
	}


func get_dominant_state() -> StringName:
	return _dominant_state


func get_rare_drop_multiplier() -> float:
	var weights := get_weights()
	return 1.0 + float(weights.get("bearing", 0.0)) * 0.6


func get_drop_rate_multiplier() -> float:
	var weights := get_weights()
	return 1.0 + float(weights.get("recollection", 0.0)) * 0.25


func get_input_delay_variance() -> float:
	var weights := get_weights()
	return float(weights.get("instinct", 0.0)) * 0.035


func get_move_speed_multiplier() -> float:
	var weights := get_weights()
	return 1.0 + float(weights.get("instinct", 0.0)) * 0.08


func get_attack_recovery_multiplier() -> float:
	var weights := get_weights()
	return 1.0 - float(weights.get("instinct", 0.0)) * 0.06


func get_player_accuracy_bonus() -> float:
	var weights := get_weights()
	return float(weights.get("bearing", 0.0)) * 0.08


func get_player_crit_bonus() -> float:
	var weights := get_weights()
	return float(weights.get("bearing", 0.0)) * 0.04


func get_enemy_accuracy_bonus() -> float:
	var weights := get_weights()
	return float(weights.get("recollection", 0.0)) * 0.04


func get_enemy_tracking_bonus() -> float:
	var weights := get_weights()
	return float(weights.get("recollection", 0.0)) * 0.05


func request_instinct_action(action_id: StringName) -> void:
	if action_id == &"":
		return
	instinct_action_requested.emit(action_id)


func to_save_dict() -> Dictionary:
	return {
		"recollection": recollection,
		"instinct": instinct,
		"bearing": bearing,
		"instinct_meter": instinct_meter,
	}


func from_save_dict(data: Dictionary) -> void:
	recollection = max(0.0, float(data.get("recollection", 0.0)))
	instinct = max(0.0, float(data.get("instinct", 0.0)))
	bearing = max(0.0, float(data.get("bearing", 0.0)))
	instinct_meter = max(0.0, float(data.get("instinct_meter", 0.0)))
	_emit_values_changed()


func _emit_values_changed() -> void:
	cognitive_values_changed.emit(recollection, instinct, bearing)
	var old_state := _dominant_state
	_dominant_state = _calculate_dominant_state()
	if old_state != _dominant_state:
		dominant_state_changed.emit(old_state, _dominant_state)


func _calculate_dominant_state() -> StringName:
	var weights := get_weights()
	var recollection_weight := float(weights.get("recollection", 0.0))
	var instinct_weight := float(weights.get("instinct", 0.0))
	var bearing_weight := float(weights.get("bearing", 0.0))
	var top_weight: float = max(recollection_weight, max(instinct_weight, bearing_weight))
	if top_weight <= 0.001:
		return STATE_MIXED

	var close_count := 0
	for weight in [recollection_weight, instinct_weight, bearing_weight]:
		if top_weight - weight <= mixed_state_margin:
			close_count += 1
	if close_count > 1:
		return STATE_MIXED
	if is_equal_approx(top_weight, recollection_weight):
		return STATE_DRIFT
	if is_equal_approx(top_weight, instinct_weight):
		return STATE_FLOW
	return STATE_ALIGNMENT
