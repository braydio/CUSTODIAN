extends SceneTree

var failures: Array[String] = []

class FakePlanActor:
	extends Node
	var dead := false
	func is_dead() -> bool: return dead

func _init() -> void: call_deferred("_run")

func _run() -> void:
	_test_wear_python_parity()
	_test_wear_and_fidelity()
	_test_repairs()
	_test_fabrication()
	_test_assault_recency_and_power_weight()
	_test_relay_tier_seven_pressure()
	_test_plan_owned_completion()
	_test_terminal_consumes_authoritative_fidelity()
	_test_deterministic_continuation()
	if failures.is_empty(): print("PYTHON_SIM_REMAP2_SMOKE: PASS"); quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _test_wear_python_parity() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/validation/fixtures/python_sim_remap2/wear_parity.json"))
	var wear := WearSimulationSystem.new()
	for readiness in range(5):
		for fortification in range(5):
			var state := WorldSimulationState.new(readiness * 10 + fortification)
			state.policies.defense_readiness = readiness; state.policies.sector_fortification.COMMAND = fortification
			wear.step_macro(state)
			var expected := float(fixture.cases[str(readiness)][str(fortification)])
			_check(is_equal_approx(state.sectors.COMMAND.damage, expected), "Godot wear diverged from retained Python formula at readiness=%d fortification=%d" % [readiness, fortification])

func _test_wear_and_fidelity() -> void:
	var exposed := WorldSimulationState.new(7); var sheltered := WorldSimulationState.new(7)
	exposed.policies.defense_readiness = 4; sheltered.policies.defense_readiness = 0
	sheltered.policies.sector_fortification.COMMAND = 4
	var actor_state := StructureSimulationState.new("physical_boundary", "test", "COMMAND", 100)
	exposed.structures.actor = actor_state
	var wear := WearSimulationSystem.new(); wear.step_macro(exposed); wear.step_macro(sheltered)
	_check(exposed.sectors.COMMAND.damage > sheltered.sectors.COMMAND.damage, "readiness/fortification did not mitigate deterministic wear")
	_check(actor_state.hp == 100, "macro wear directly damaged a structure/physical HP value")
	var fidelity := FidelitySimulationSystem.new(); var state := WorldSimulationState.new(8)
	state.power_load = 1.0; fidelity.step_macro(state); _check(state.macro_fidelity == "FULL", "healthy comms did not retain FULL fidelity")
	state.sectors.COMMS.damage = 1.0; fidelity.step_macro(state); _check(state.macro_fidelity == "FRAGMENTED", "comms damage did not transition to FRAGMENTED")
	state.relay_knowledge_level = 6; fidelity.step_macro(state); _check(state.macro_fidelity == "DEGRADED", "tier-six relay reconstruction floor was not applied")
	state.sectors.COMMS.damage = 0.0; state.relay_knowledge_level = 0; state.signal_interference_ticks = 1; fidelity.step_macro(state)
	_check(state.macro_fidelity == "DEGRADED" and state.signal_interference_ticks == 0, "signal interference did not apply and expire deterministically")
	_check(state.events.any(func(event: Dictionary) -> bool: return event.kind == "macro_fidelity_changed"), "fidelity transitions were not recorded as simulation events")

func _test_repairs() -> void:
	var state := DefaultCampaignScenarioFactory.create_world(DefaultCampaignScenarioFactory.create_scenario(17))
	state.structures.COMMAND_POST.apply_damage(20)
	var kernel := SimulationKernel.new(state)
	kernel.queue(SimulationCommand.QUEUE_REPAIR, {"structure_id":"COMMAND_POST", "material_cost":999, "ticks":0.001})
	kernel.apply_commands_at_current_boundary()
	_check(state.materials == 2 and state.repairs.size() == 1, "repair cost was not derived from the simulation contract")
	var job := RepairJobState.from_dict(state.repairs[0])
	_check(job.remaining > 1.0 and job.repair_amount == 20, "repair duration/healing amount accepted caller-authored values")
	var poor := DefaultCampaignScenarioFactory.create_world(DefaultCampaignScenarioFactory.create_scenario(18)); poor.materials = 0; poor.structures.COMMAND_POST.apply_damage(20)
	var poor_kernel := SimulationKernel.new(poor); poor_kernel.queue(SimulationCommand.QUEUE_REPAIR, {"structure_id":"COMMAND_POST"}); poor_kernel.apply_commands_at_current_boundary()
	_check(poor.repairs.is_empty() and poor.structures.COMMAND_POST.hp == 80, "repair started without sufficient resources")
	var destroyed := DefaultCampaignScenarioFactory.create_world(DefaultCampaignScenarioFactory.create_scenario(19)); destroyed.structures.COMMAND_POST.apply_damage(100)
	var destroyed_kernel := SimulationKernel.new(destroyed); destroyed_kernel.queue(SimulationCommand.QUEUE_REPAIR, {"structure_id":"COMMAND_POST"}); destroyed_kernel.apply_commands_at_current_boundary()
	_check(destroyed.repairs.is_empty(), "destroyed structure bypassed reconstruction restrictions")
	var unpowered := DefaultCampaignScenarioFactory.create_world(DefaultCampaignScenarioFactory.create_scenario(20)); unpowered.structures.COMMAND_POST.apply_damage(20); unpowered.structures.COMMAND_POST.powered = false
	var unpowered_kernel := SimulationKernel.new(unpowered); unpowered_kernel.queue(SimulationCommand.QUEUE_REPAIR, {"structure_id":"COMMAND_POST"}); unpowered_kernel.apply_commands_at_current_boundary()
	_check(unpowered.repairs.is_empty(), "repair bypassed power eligibility")
	var locked := DefaultCampaignScenarioFactory.create_world(DefaultCampaignScenarioFactory.create_scenario(25)); locked.structures.COMMAND_POST.apply_damage(20); locked.assault.phase = "APPROACHING"; locked.assault.objective = "COMMAND"
	var locked_kernel := SimulationKernel.new(locked); locked_kernel.queue(SimulationCommand.QUEUE_REPAIR, {"structure_id":"COMMAND_POST"}); locked_kernel.apply_commands_at_current_boundary()
	_check(locked.repairs.is_empty(), "repair bypassed assault target lockout")
	for index in 600: kernel.step_once()
	var branch := SimulationKernel.new(SimulationSnapshot.restore(SimulationSnapshot.capture(state).to_dict()))
	for index in 600: kernel.step_once(); branch.step_once()
	_check(kernel.state.canonical_fingerprint() == branch.state.canonical_fingerprint(), "repair snapshot continuation diverged")

func _test_fabrication() -> void:
	var state := WorldSimulationState.new(21); state.inventory.COMPONENTS = 1
	var kernel := SimulationKernel.new(state)
	kernel.queue(SimulationCommand.QUEUE_FABRICATION, {"recipe_id":"TURRET_AMMO", "outputs":{"turret_ammo":999}, "ticks":0.01})
	kernel.apply_commands_at_current_boundary()
	_check(state.inventory.COMPONENTS == 0 and state.fabrication_queue.size() == 1, "recipe inputs were not consumed at queue time")
	var job := FabricationJobState.from_dict(state.fabrication_queue[0])
	_check(job.outputs == {"turret_ammo":3} and is_equal_approx(job.remaining, 7.0), "fabrication accepted caller-authored output/duration")
	var unsupported := WorldSimulationState.new(22); var unsupported_kernel := SimulationKernel.new(unsupported)
	unsupported_kernel.queue(SimulationCommand.QUEUE_FABRICATION, {"recipe_id":"CUSTOM", "outputs":{"MODULES":100}}); unsupported_kernel.apply_commands_at_current_boundary()
	_check(unsupported.fabrication_queue.is_empty() and unsupported.inventory.MODULES == 0, "unknown recipe minted resources")
	var empty := WorldSimulationState.new(23); empty.inventory = {"SCRAP":0,"COMPONENTS":0,"ASSEMBLIES":0,"MODULES":0}
	var fab := FabricationSimulationSystem.new()
	for index in 200: fab.step_macro(empty)
	_check(empty.inventory == {"SCRAP":0,"COMPONENTS":0,"ASSEMBLIES":0,"MODULES":0} and empty.stocks.turret_ammo == 6 and empty.stocks.repair_drones == 0, "ambient fabrication produced output without inputs")
	var ambient := WorldSimulationState.new(24); ambient.inventory.SCRAP = 20
	for index in 600: fab.step_macro(ambient)
	_check(ambient.stocks.turret_ammo > 6 and ambient.inventory.SCRAP < 20, "ambient fabrication did not consume inputs and add recipe output: scrap=%s components=%s progress=%s" % [ambient.inventory.SCRAP, ambient.stocks.turret_ammo, ambient.ambient_fab_progress])
	var branch_state := SimulationSnapshot.restore(SimulationSnapshot.capture(ambient).to_dict()); var continued := WorldSimulationState.new()
	continued = branch_state
	var branch_kernel := SimulationKernel.new(continued); var left_kernel := SimulationKernel.new(ambient)
	for index in 600: branch_kernel.step_once(); left_kernel.step_once()
	_check(branch_kernel.state.canonical_fingerprint() == left_kernel.state.canonical_fingerprint(), "ambient fabrication snapshot continuation diverged")

func _test_assault_recency_and_power_weight() -> void:
	var events := SystemicEventSimulationSystem.new(); var state := WorldSimulationState.new(31)
	state.assault.phase = "HANDED_OFF"; state.assault.assault_id = "recency_test"; state.ambient_threat = 0.0; state.systemic_event_state.ticks_since_assault = 91
	events.step_macro(state); _check(int(state.systemic_event_state.ticks_since_assault) == 0, "active physical assault did not reset recency")
	var kernel := SimulationKernel.new(state); kernel.queue(SimulationCommand.PHYSICAL_ASSAULT_COMPLETED, {"assault_id":"recency_test"}); kernel.apply_commands_at_current_boundary()
	_check(state.assault.phase == "NONE", "physical completion observation did not close assault before recency advanced")
	events.step_macro(state); _check(int(state.systemic_event_state.ticks_since_assault) == 1, "assault recency did not advance after true completion")
	state.ambient_threat = 20.0; state.systemic_event_state.last_category = ""
	state.systemic_event_state.ticks_since_assault = 4; var recent := events.compute_category_weights(state)
	state.systemic_event_state.ticks_since_assault = 5; var expired := events.compute_category_weights(state)
	_check(is_equal_approx(float(recent.ENVIRONMENTAL), float(expired.ENVIRONMENTAL) * 1.4), "under-five-tick assault recency weighting was not restored")
	state.power_load = 3.5; var low := events.compute_category_weights(state)
	state.power_load = 5.0; var high := events.compute_category_weights(state)
	_check(float(high.INFRASTRUCTURE) > float(low.INFRASTRUCTURE), "infrastructure event weighting ignored authoritative macro power load")

func _test_relay_tier_seven_pressure() -> void:
	for count in range(1, 5):
		var state := WorldSimulationState.new(count); state.relay_knowledge_level = 7
		for id in state.relays: state.relays[id].status = "UNKNOWN"
		for index in count: state.relays["R_%d" % index] = {"id":"R_%d" % index,"sector_id":"COMMAND","status":"DORMANT","stability":0.0,"packets_pending":0}
		state.relays.R_NORTH.packets_pending = 1
		RelaySimulationSystem.new().sync_packets(state)
		_check(state.relay_dormancy_pressure == ceili(float(count) / 2.0), "tier-seven dormancy pressure formula failed count %d" % count)

func _test_plan_owned_completion() -> void:
	var manager := WaveManager.new(); root.add_child(manager)
	var owned := Node.new(); var unrelated := Node.new(); root.add_child(owned); root.add_child(unrelated)
	manager._active_external_plan_id = "plan_a"; manager._external_plan_actors.plan_a = [owned.get_instance_id()]
	var completions: Array[String] = []; manager.external_plan_physically_completed.connect(func(id: String) -> void: completions.append(id))
	manager._pending_spawns = ["grunt"]; manager._check_external_plan_completion()
	_check(completions.is_empty(), "plan completed while it still had pending spawns")
	manager._pending_spawns.clear(); manager._check_external_plan_completion()
	_check(completions.is_empty(), "plan completed while a plan-owned actor remained alive")
	owned.free(); manager._check_external_plan_completion()
	_check(completions == ["plan_a"], "ambient/unrelated actors blocked or falsely satisfied plan completion")
	manager._check_external_plan_completion(); _check(completions.size() == 1, "plan completion observation emitted more than once")
	var dead_body := FakePlanActor.new(); dead_body.dead = true; root.add_child(dead_body)
	manager._active_external_plan_id = "plan_b"; manager._external_plan_actors.plan_b = [dead_body.get_instance_id()]
	manager._check_external_plan_completion()
	_check(completions == ["plan_a", "plan_b"], "resolved dead actor continued to block its plan")
	manager.free(); unrelated.free()
	dead_body.free()

func _test_deterministic_continuation() -> void:
	var left := WorldSimulationState.new(41); var right := WorldSimulationState.new(41)
	left.inventory.SCRAP = 20; right.inventory.SCRAP = 20
	left.policies.defense_readiness = 3; right.policies.defense_readiness = 3
	left.sectors.COMMS.damage = 0.8; right.sectors.COMMS.damage = 0.8
	var a := SimulationKernel.new(left); var b := SimulationKernel.new(right)
	for index in 1800: a.step_once(); b.step_once()
	var restored := SimulationSnapshot.restore(SimulationSnapshot.capture(a.state).to_dict()); var c := SimulationKernel.new(restored)
	for index in 1800: a.step_once(); c.step_once(); b.step_once()
	_check(a.state.canonical_fingerprint() == b.state.canonical_fingerprint(), "same-seed infrastructure trace diverged")
	_check(a.state.canonical_fingerprint() == c.state.canonical_fingerprint(), "wear/fidelity/ambient state snapshot continuation diverged")

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _test_terminal_consumes_authoritative_fidelity() -> void:
	var policy := TerminalFidelityPolicy.new()
	var result := policy.resolve(&"command", [], {"fidelity":"FULL"}, &"FRAGMENTED")
	_check(result == TerminalFidelityPolicy.FRAGMENTED, "terminal presentation overrode authoritative macro fidelity")
