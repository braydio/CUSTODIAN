extends Node

signal state_changed(key: String, value: Variant)

var state: Dictionary = {}
var dependencies: Dictionary = {}
var _is_evaluating_dependencies: bool = false


func set_state(key: String, value: Variant) -> void:
	if state.get(key) == value:
		return

	var previous_value: Variant = state.get(key, null)
	state[key] = value
	state_changed.emit(key, value)

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		observatory.call("log_event", "world_state_changed", {
			"key": key,
			"value": value,
			"previous_value": previous_value,
			"derived": false,
			"persistence": "persistent",
			"source": "world_state_graph",
		})

	_evaluate_dependencies()


func get_state(key: String, default_value: Variant = false) -> Variant:
	return state.get(key, default_value)


func add_dependency(output_key: String, required_states: Dictionary, output_value: Variant = true) -> void:
	dependencies[output_key] = {
		"required": required_states.duplicate(true),
		"value": output_value,
	}
	_evaluate_dependencies()


func _evaluate_dependencies() -> void:
	if _is_evaluating_dependencies:
		return

	_is_evaluating_dependencies = true
	var changed := true
	while changed:
		changed = false
		for output_key in dependencies.keys():
			var dependency: Dictionary = dependencies[output_key]
			var required: Dictionary = dependency.get("required", {})
			var valid := true
			for required_key in required.keys():
				if state.get(required_key) != required[required_key]:
					valid = false
					break
			if not valid:
				continue
			var output_value: Variant = dependency.get("value", true)
			if state.get(output_key) == output_value:
				continue
			var previous_value: Variant = state.get(output_key, null)
			state[output_key] = output_value
			state_changed.emit(output_key, output_value)
			var observatory := get_node_or_null("/root/DevObservatory")
			if observatory != null:
				observatory.call("log_event", "world_state_changed", {
					"key": output_key,
					"value": output_value,
					"previous_value": previous_value,
					"derived": true,
					"persistence": "persistent",
					"source": "world_state_dependency",
				})
			changed = true
	_is_evaluating_dependencies = false
