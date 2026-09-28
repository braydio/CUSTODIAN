class_name FabricationSimulationSystem
extends RefCounted

const AMBIENT_RULES := {
	"REPAIRS":{"cycle":3.0,"inputs":{"SCRAP":2},"outputs":{"COMPONENTS":1}},
	"DEFENSE":{"cycle":5.0,"inputs":{"COMPONENTS":1},"outputs":{"turret_ammo":1}},
	"DRONES":{"cycle":8.0,"inputs":{"COMPONENTS":2,"ASSEMBLIES":1,"MODULES":1},"outputs":{"repair_drones":1}},
	"ARCHIVE":{"cycle":4.5,"inputs":{"COMPONENTS":2,"ASSEMBLIES":1},"outputs":{"MODULES":1}},
}

func step_macro(state: WorldSimulationState) -> void:
	if not state.fabrication_queue.is_empty():
		var job := FabricationJobState.from_dict(state.fabrication_queue[0]) if state.fabrication_queue[0] is Dictionary else state.fabrication_queue[0] as FabricationJobState
		var allocation := int(state.policies.fabrication_allocation.get(job.category,2)); job.remaining -= (0.5 + allocation*0.25) * state.logistics_multiplier * (0.9 if state.relay_knowledge_level >= 5 else 1.0)
		if job.remaining <= 0.0:
			FabricationRecipeContract.apply_outputs(state, job.outputs); state.fabrication_queue.pop_front(); state.record_event(&"fabrication_completed",{"job_id":job.job_id,"recipe_id":job.recipe_id})
		else: state.fabrication_queue[0]=job
	_step_ambient(state)

func _step_ambient(state: WorldSimulationState) -> void:
	var load_penalty := maxf(0.25, 1.0 - maxf(0.0, state.power_load - 3.0) * 0.08)
	var supply_factor := maxf(0.2, 1.0 - state.logistics_pressure * 0.12)
	var rate := 0.6 * load_penalty * supply_factor * state.logistics_multiplier
	var allocation_total := 0
	for category in PolicySimulationState.FABRICATION_CATEGORIES: allocation_total += maxi(0, int(state.policies.fabrication_allocation.get(category, 0)))
	if allocation_total <= 0: return
	for category in PolicySimulationState.FABRICATION_CATEGORIES:
		var progress := float(state.ambient_fab_progress.get(category, 0.0)) + rate * float(maxi(0, int(state.policies.fabrication_allocation.get(category, 0)))) / allocation_total
		state.ambient_fab_progress[category] = minf(progress, float(AMBIENT_RULES[category].cycle) * 1.5)
	var crafted := 0
	while crafted < 3:
		var order := PolicySimulationState.FABRICATION_CATEGORIES.duplicate()
		order.sort_custom(func(a: String, b: String) -> bool: return float(state.ambient_fab_progress[a]) > float(state.ambient_fab_progress[b]) if not is_equal_approx(float(state.ambient_fab_progress[a]), float(state.ambient_fab_progress[b])) else a < b)
		var did_craft := false
		for category in order:
			var rule: Dictionary = AMBIENT_RULES[category]
			if float(state.ambient_fab_progress[category]) < float(rule.cycle) or not FabricationRecipeContract.has_inputs(state, rule.inputs): continue
			FabricationRecipeContract.consume_inputs(state, rule.inputs); FabricationRecipeContract.apply_outputs(state, rule.outputs); state.ambient_fab_progress[category] = float(state.ambient_fab_progress[category]) - float(rule.cycle)
			state.record_event(&"ambient_fabrication_completed", {"category": category, "outputs": rule.outputs}); crafted += 1; did_craft = true
			if crafted >= 3: break
		if not did_craft: break
