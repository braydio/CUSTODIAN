class_name FabricationSimulationSystem
extends RefCounted
func step_macro(state: WorldSimulationState) -> void:
	if state.fabrication_queue.is_empty(): return
	var job := FabricationJobState.from_dict(state.fabrication_queue[0]) if state.fabrication_queue[0] is Dictionary else state.fabrication_queue[0] as FabricationJobState
	var allocation := int(state.policies.fabrication_allocation.get(job.category,2)); job.remaining -= (0.5 + allocation*0.25) * state.logistics_multiplier
	if job.remaining <= 0.0:
		for key in job.outputs:
			if key == "repair_drones": state.stocks.repair_drones=int(state.stocks.get("repair_drones",0))+int(job.outputs[key])
			elif key == "turret_ammo": state.stocks.turret_ammo=int(state.stocks.get("turret_ammo",0))+int(job.outputs[key])
			else: state.inventory[key]=int(state.inventory.get(key,0))+int(job.outputs[key])
		state.fabrication_queue.pop_front(); state.record_event(&"fabrication_completed",{"job_id":job.job_id,"recipe_id":job.recipe_id})
	else: state.fabrication_queue[0]=job
