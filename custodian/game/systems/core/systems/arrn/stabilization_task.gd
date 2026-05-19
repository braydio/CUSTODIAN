extends RefCounted
class_name ARRNStabilizationTask

var relay_id: StringName = &""
var ticks_required: int = 1
var ticks_completed: int = 0
var actor_instance_id: int = 0
var started_tick: int = 0


func _init(relay_id_value: StringName = &"", ticks_required_value: int = 1, actor_id_value: int = 0, started_tick_value: int = 0) -> void:
	relay_id = relay_id_value
	ticks_required = maxi(1, ticks_required_value)
	actor_instance_id = actor_id_value
	started_tick = started_tick_value


func tick() -> bool:
	ticks_completed = mini(ticks_required, ticks_completed + 1)
	return is_complete()


func progress() -> float:
	return clampf(float(ticks_completed) / float(maxi(1, ticks_required)), 0.0, 1.0)


func is_complete() -> bool:
	return ticks_completed >= ticks_required


func to_snapshot() -> Dictionary:
	return {
		"relay_id": String(relay_id),
		"ticks_required": ticks_required,
		"ticks_completed": ticks_completed,
		"progress": progress(),
		"actor_instance_id": actor_instance_id,
		"started_tick": started_tick,
	}
