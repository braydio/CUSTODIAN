extends Node2D

signal contract_generated(contract: Dictionary)
signal contract_generation_failed(result: Dictionary)

@export var auto_generate_on_ready: bool = false
@export var randomize_seed_on_ready: bool = false
@export var should_fail: bool = false


func generate_contract(seed_value: int) -> void:
	call_deferred("_finish_generation", seed_value)


func _finish_generation(seed_value: int) -> void:
	if should_fail:
		contract_generation_failed.emit({
			"reason": "forced_failure",
			"contract_seed": seed_value,
		})
		return
	var map_instance := Node2D.new()
	map_instance.name = "FakePrewarmedMap"
	add_child(map_instance)
	contract_generated.emit({
		"contract_seed": seed_value,
		"world_profile": {},
		"map": {
			"instance": map_instance,
			"level_data": {},
		},
	})
