extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var state:=DefaultCampaignScenarioFactory.create_world(DefaultCampaignScenarioFactory.create_scenario()); state.structures.COMMAND_POST.apply_damage(20); state.inventory.COMPONENTS = 1; var kernel:=SimulationKernel.new(state); kernel.queue(SimulationCommand.QUEUE_REPAIR,{"structure_id":"COMMAND_POST","material_cost":0,"ticks":0.01}); kernel.queue(SimulationCommand.QUEUE_FABRICATION,{"recipe_id":"TURRET_AMMO","category":"DEFENSE","ticks":0.01,"outputs":{"turret_ammo":200}})
	kernel.apply_commands_at_current_boundary()
	if state.materials != 2: push_error("caller supplied repair cost was not ignored")
	for i in 1500: kernel.step_once()
	if state.structures.COMMAND_POST.hp==100 and state.stocks.turret_ammo==9 and state.repairs.is_empty() and state.fabrication_queue.is_empty(): print("REPAIR_FABRICATION_SIMULATION_SMOKE: PASS"); quit(0); return
	push_error("repair/fabrication deterministic completion failed hp=%s ammo=%s repairs=%s fab=%s" % [state.structures.COMMAND_POST.hp,state.stocks.turret_ammo,state.repairs,state.fabrication_queue]); quit(1)
