extends Node2D

signal contract_generated(contract: Dictionary)
signal contract_generation_failed(result: Dictionary)

@export var auto_generate_on_ready := false
@export var randomize_seed_on_ready := false


func generate_contract(_seed_value: int) -> void:
	# Keep the bootstrap in GENERATING while the test observes the scene boundary.
	pass
