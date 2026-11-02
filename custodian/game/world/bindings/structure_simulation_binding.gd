class_name StructureSimulationBinding
extends Node
@export var structure_id := ""
var runtime: WorldSimulationRuntime
var _applying_snapshot := false
func _ready() -> void: runtime = get_tree().get_first_node_in_group("world_simulation_runtime") as WorldSimulationRuntime
func submit_damage(amount: int, source: String = "physical") -> int:
	if _applying_snapshot or runtime == null: return -1
	return runtime.queue_command(SimulationCommand.DAMAGE_STRUCTURE, {"structure_id": structure_id, "amount": amount, "source": source})
