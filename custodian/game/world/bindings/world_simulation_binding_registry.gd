class_name WorldSimulationBindingRegistry
extends Node
var runtime: WorldSimulationRuntime
var diagnostics: Dictionary = {}
func _ready() -> void: runtime = get_tree().get_first_node_in_group("world_simulation_runtime") as WorldSimulationRuntime
func report_unknown(identity: String) -> void:
	if diagnostics.has(identity): return
	diagnostics[identity] = true; push_warning("Unknown simulation scene binding: %s" % identity)
