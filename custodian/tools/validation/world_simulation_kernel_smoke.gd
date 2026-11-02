extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var scenario := DefaultCampaignScenarioFactory.create_scenario(1337); var first := SimulationKernel.new(DefaultCampaignScenarioFactory.create_world(scenario)); var second := SimulationKernel.new(DefaultCampaignScenarioFactory.create_world(scenario))
	for kernel in [first, second]: kernel.queue(SimulationCommand.SET_POLICY, {"repair_intensity": 3, "defense_readiness": 2, "surveillance_coverage": 2}); kernel.queue(SimulationCommand.DAMAGE_STRUCTURE, {"structure_id": "COMMAND_POST", "amount": 7})
	for index in 120: first.step_once(); second.step_once()
	check(first.state.canonical_fingerprint() == second.state.canonical_fingerprint(), "same seed/commands diverged"); check(first.state.fixed_tick == 120 and first.state.world_tick == 2, "fixed/world tick relationship incorrect"); check(first.state.structures.COMMAND_POST.hp == 93, "typed damage failed")
	var paused := SimulationClock.new(); paused.paused=true; check(paused.advance(1.0, func(): pass) == 0 and paused.accumulator == 0.0, "pause mutated clock"); paused.paused=false; check(paused.advance(SimulationClock.FIXED_DT*2.0, func(): pass) == 2, "clock resume failed"); var bounded := SimulationClock.new(); check(bounded.advance(1.0, func(): pass) == 8 and bounded.dropped_steps > 0, "catch-up guard failed")
	finish("WORLD_SIMULATION_KERNEL_SMOKE")
func check(value: bool, message: String) -> void: if not value: failures.append(message)
func finish(label: String) -> void:
	if failures.is_empty(): print("%s: PASS" % label); quit(0)
	else: for failure in failures: push_error(failure); quit(1)
