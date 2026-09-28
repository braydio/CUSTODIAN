class_name RepairSimulationSystem
extends RefCounted
func step_macro(state: WorldSimulationState) -> void:
	if state.repairs.is_empty(): return
	var job := RepairJobState.from_dict(state.repairs[0]) if state.repairs[0] is Dictionary else state.repairs[0] as RepairJobState
	var structure: StructureSimulationState = state.structures.get(job.structure_id)
	if structure == null: state.repairs.pop_front(); state.record_event(&"repair_rejected",{"job_id":job.job_id}); return
	var speed: float = float(SimulationPolicyTables.REPAIR_SPEED[clampi(state.policies.repair_intensity, 0, 4)]) * state.logistics_multiplier
	if state.relay_knowledge_level >= 2: speed *= 1.1
	if not structure.powered: speed = 0.0
	speed *= float({"FULL": 1.0, "DEGRADED": 0.9, "FRAGMENTED": 0.75, "LOST": 0.5}.get(state.macro_fidelity, 0.5))
	speed *= maxf(0.5, 1.0 - maxf(0.0, state.power_load - 4.0) * 0.05)
	var amount := minf(float(structure.max_hp - structure.hp), speed)
	var prior_whole := floori(job.progress); job.progress += amount
	structure.repair(floori(job.progress) - prior_whole); job.remaining -= 1.0
	if structure.hp >= structure.max_hp:
		state.repairs.pop_front(); state.record_event(&"repair_completed",{"job_id":job.job_id,"structure_id":job.structure_id})
	else:
		job.remaining = maxf(0.0, job.remaining)
		state.repairs[0]=job
