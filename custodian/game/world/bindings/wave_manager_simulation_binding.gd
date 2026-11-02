class_name WaveManagerSimulationBinding
extends Node
@export var wave_manager_path: NodePath
@export var simulation_runtime_path: NodePath
var _active_plan_id := ""

func _ready() -> void:
	var runtime := get_node_or_null(simulation_runtime_path)
	var manager := get_node_or_null(wave_manager_path)
	if runtime != null and runtime.has_signal("physical_assault_plan_ready"):
		runtime.physical_assault_plan_ready.connect(consume_plan)
	if manager != null and manager.has_signal("external_plan_physically_completed"):
		manager.external_plan_physically_completed.connect(_on_plan_completed)

func consume_plan(plan: AssaultSpawnPlan) -> bool:
	if _active_plan_id == plan.plan_id: return true
	var manager := get_node_or_null(wave_manager_path)
	if manager == null or not manager.has_method("apply_external_wave_plan"): return false
	if not bool(manager.call("apply_external_wave_plan", plan.to_dict())): return false
	_active_plan_id = plan.plan_id
	var runtime := get_node_or_null(simulation_runtime_path)
	if runtime != null and runtime.has_method("queue_command"):
		runtime.call("queue_command", SimulationCommand.ASSAULT_HANDOFF_ACCEPTED, {"plan_id": plan.plan_id})
	return true

func _on_plan_completed(plan_id: String) -> void:
	if _active_plan_id.is_empty() or _active_plan_id != plan_id: return
	var runtime := get_node_or_null(simulation_runtime_path)
	if runtime != null and runtime.has_method("queue_command"):
		runtime.call("queue_command", SimulationCommand.PHYSICAL_ASSAULT_COMPLETED, {"assault_id": plan_id})
	_active_plan_id = ""
