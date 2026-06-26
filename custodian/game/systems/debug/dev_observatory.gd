extends Node

@export var max_events: int = 2000

var enabled: bool = false
var events: Array[Dictionary] = []
var counters: Dictionary = {}
var gauges: Dictionary = {}


func _ready() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_observatory"):
		enabled = not enabled
		get_viewport().set_input_as_handled()


func log_event(kind: String, data := {}) -> void:
	var entry := {
		"time": Time.get_ticks_msec(),
		"kind": kind,
		"data": data if data is Dictionary else {},
	}
	events.append(entry)
	if events.size() > max_events:
		events.pop_front()


func increment(name: String, amount := 1) -> void:
	counters[name] = int(counters.get(name, 0)) + int(amount)


func set_counter(name: String, value: int) -> void:
	counters[name] = int(value)


func set_gauge(name: String, value: Variant) -> void:
	gauges[name] = value


func get_recent_events(kind := "", limit := 50) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for i in range(events.size() - 1, -1, -1):
		var entry: Dictionary = events[i]
		if kind == "" or String(entry.get("kind", "")) == kind:
			output.append(entry)
		if output.size() >= limit:
			break
	return output
