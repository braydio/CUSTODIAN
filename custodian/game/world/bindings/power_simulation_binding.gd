class_name PowerSimulationBinding
extends Node
var strategic_power_load := 0.0
func _ready() -> void:
	var runtime := get_tree().get_first_node_in_group("world_simulation_runtime") as WorldSimulationRuntime
	if runtime != null: runtime.snapshot_updated.connect(func(snapshot: SimulationSnapshot) -> void: strategic_power_load = float(snapshot.payload.get("power_load", 0.0)))
