class_name RepairSimulationSystem
extends RefCounted
func step_macro(state: WorldSimulationState) -> void:
	if state.repairs.is_empty(): return
	var job := RepairJobState.from_dict(state.repairs[0]) if state.repairs[0] is Dictionary else state.repairs[0] as RepairJobState
	var structure: StructureSimulationState = state.structures.get(job.structure_id)
	if structure == null: state.repairs.pop_front(); state.record_event(&"repair_rejected",{"job_id":job.job_id}); return
	job.remaining -= SimulationPolicyTables.REPAIR_SPEED[state.policies.repair_intensity] * state.logistics_multiplier
	if job.remaining <= 0.0: structure.repair(structure.max_hp); state.repairs.pop_front(); state.record_event(&"repair_completed",{"job_id":job.job_id,"structure_id":job.structure_id})
	else: state.repairs[0]=job
