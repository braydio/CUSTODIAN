class_name WaveManagerSimulationBinding
extends Node
@export var wave_manager_path: NodePath
func consume_plan(plan: AssaultSpawnPlan) -> bool:
	var manager := get_node_or_null(wave_manager_path)
	if manager == null or not manager.has_method("apply_external_wave_plan"): return false
	manager.call("apply_external_wave_plan", plan.to_dict()); return true
