extends Node

var _completed_events: Dictionary = {}
var _spawned_events: Dictionary = {}
var _event_payloads: Dictionary = {}
var run_seed: int = 0


func reset_run_events(p_run_seed := 0) -> void:
	run_seed = int(p_run_seed)
	_completed_events.clear()
	_spawned_events.clear()
	_event_payloads.clear()


func has_spawned(event_id: StringName) -> bool:
	return bool(_spawned_events.get(String(event_id), false))


func mark_spawned(event_id: StringName, payload := {}) -> void:
	var key := String(event_id)
	_spawned_events[key] = true
	if payload is Dictionary:
		_event_payloads[key] = (payload as Dictionary).duplicate(true)


func is_completed(event_id: StringName) -> bool:
	return bool(_completed_events.get(String(event_id), false))


func mark_completed(event_id: StringName, payload := {}) -> void:
	var key := String(event_id)
	_completed_events[key] = true
	_spawned_events[key] = true
	if payload is Dictionary:
		_event_payloads[key] = (payload as Dictionary).duplicate(true)


func get_payload(event_id: StringName) -> Dictionary:
	return (_event_payloads.get(String(event_id), {}) as Dictionary).duplicate(true)


func get_event_seed(event_id: StringName, salt := "") -> int:
	var key := "%s:%s:%s" % [String(event_id), str(run_seed), salt]
	return abs(hash(key))
