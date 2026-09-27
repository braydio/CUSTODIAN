extends SceneTree

class FakePhysicalWaveManager:
	extends Node
	signal wave_completed(wave_number: int)
	var received_plan: Dictionary = {}
	func apply_external_wave_plan(plan: Dictionary) -> bool: received_plan = plan.duplicate(true); return true

class FakeSimulationRuntime:
	extends Node
	signal physical_assault_plan_ready(plan: AssaultSpawnPlan)
	var acknowledged: Array[String] = []
	var queued_kind: StringName = &""
	var queued_payload: Dictionary = {}
	func acknowledge_assault_handoff(plan_id: String) -> bool: acknowledged.append(plan_id); return true
	func queue_command(kind: StringName, payload: Dictionary) -> int: queued_kind = kind; queued_payload = payload.duplicate(true); return 1

var failures: Array[String] = []

func _init() -> void: call_deferred("_run")

func _run() -> void:
	_check_macro_order()
	_check_relay_determinism()
	_check_event_determinism()
	_check_assault_determinism_and_handoff()
	_check_snapshot_continuation()
	_check_legacy_snapshot_migration()
	_check_physical_authority_boundary()
	finish()

func _check_macro_order() -> void:
	var kernel := SimulationKernel.new(WorldSimulationState.new(11)); var order: Array[String] = []
	kernel.macro_stage_completed.connect(func(stage: StringName) -> void: order.append(String(stage)))
	for index in 60: kernel.step_once()
	_check(order == ["power", "logistics", "repairs", "fabrication", "relay", "systemic_events", "strategic_assault"], "macro order must remain explicit and stable")

func _check_relay_determinism() -> void:
	var first := SimulationKernel.new(WorldSimulationState.new(7101)); var second := SimulationKernel.new(WorldSimulationState.new(7101))
	for kernel in [first, second]:
		kernel.queue(SimulationCommand.STABILIZE_RELAY, {"relay_id": "R_ARCHIVE"})
		kernel.queue(SimulationCommand.SYNC_RELAYS)
	for index in 600: first.step_once(); second.step_once()
	_check(first.state.relays.R_ARCHIVE.status == "STABLE", "relay stabilization command was not retained")
	_check(first.state.relay_knowledge_level == 1 and int(first.state.relays.R_ARCHIVE.packets_pending) == 0, "relay packet sync did not progress the macro knowledge level")
	_check(first.state.canonical_fingerprint() == second.state.canonical_fingerprint(), "same relay seed and command trace diverged")

func _check_event_determinism() -> void:
	var first_state := WorldSimulationState.new(101); var second_state := WorldSimulationState.new(101)
	first_state.ambient_threat = 20.0; second_state.ambient_threat = 20.0
	var first := SimulationKernel.new(first_state); var second := SimulationKernel.new(second_state)
	for index in 1200: first.step_once(); second.step_once()
	_check(first.state.systemic_event_state.history.size() > 0, "systemic event selection did not record an event")
	_check(first.state.canonical_fingerprint() == second.state.canonical_fingerprint(), "same event seed diverged")

func _check_assault_determinism_and_handoff() -> void:
	var first_state := WorldSimulationState.new(202); var second_state := WorldSimulationState.new(202)
	first_state.ambient_threat = 20.0; second_state.ambient_threat = 20.0
	var first := SimulationKernel.new(first_state); var second := SimulationKernel.new(second_state)
	var plans: Array[AssaultSpawnPlan] = []; first.assault_handoff_ready.connect(func(plan: AssaultSpawnPlan) -> void: plans.append(plan))
	for index in 300: first.step_once(); second.step_once()
	_check(first.state.canonical_fingerprint() == second.state.canonical_fingerprint(), "same strategic assault seed diverged")
	_check(first.state.assault.phase == "HANDOFF_READY", "strategic approach did not become a handoff-ready plan")
	_check(not plans.is_empty() and not plans[0].waves.is_empty(), "typed physical assault plan was not emitted")
	if not plans.is_empty(): _check(plans[0].waves[0].has("composition") and plans[0].waves[0].has("objective"), "typed plan lacks physical composition/objective")

func _check_snapshot_continuation() -> void:
	var uninterrupted_state := WorldSimulationState.new(303); uninterrupted_state.ambient_threat = 18.0
	var uninterrupted := SimulationKernel.new(uninterrupted_state)
	for index in 600: uninterrupted.step_once()
	var snapshot := SimulationSnapshot.capture(uninterrupted.state)
	var restored := SimulationSnapshot.restore(JSON.parse_string(JSON.stringify(snapshot.to_dict())))
	_check(restored != null, "live macro snapshot failed restore")
	if restored == null: return
	_check(uninterrupted.state.canonical_fingerprint() == restored.canonical_fingerprint(), "snapshot restore changed the branch point fingerprint")
	var continued := SimulationKernel.new(restored)
	for index in 600: uninterrupted.step_once(); continued.step_once()
	_check(uninterrupted.state.canonical_fingerprint() == continued.state.canonical_fingerprint(), "snapshot branch fingerprint diverged from uninterrupted macro trajectory")
	_check(SimulationCanonicalJson.encode(uninterrupted.state.to_dict()) == SimulationCanonicalJson.encode(continued.state.to_dict()), "snapshot branch canonical state diverged")
	_check(SimulationCanonicalJson.encode(uninterrupted.state.events) == SimulationCanonicalJson.encode(continued.state.events), "snapshot branch event trace diverged")

func _check_legacy_snapshot_migration() -> void:
	var state := WorldSimulationState.new(404); var current := SimulationSnapshot.capture(state).to_dict()
	current.schema_version = 2; current.state.schema_version = 2; current.state.erase("rng_state"); current.state.erase("systemic_event_state"); current.state.erase("relay_knowledge_level"); current.state.erase("relay_dormancy_pressure"); current.state.erase("assaults_enabled"); current.state.relays = {}
	var migrated := SimulationSnapshot.restore(current)
	_check(migrated != null and migrated.relays.has("R_NORTH"), "version 2 snapshot did not migrate with relay defaults")
	_check(migrated != null and not migrated.assaults_enabled, "legacy snapshot migration enabled strategic assaults without saved configuration")
	_check(migrated != null and SimulationSnapshot.capture(migrated).to_dict().schema_version == 3, "snapshot migration did not advance schema")

func _check_physical_authority_boundary() -> void:
	var assault := AssaultSimulationState.new(); assault.phase = "HANDOFF_READY"; assault.assault_id = "assault_test"; assault.objective = "COMMAND"; assault.spawn_plan = [{"composition": ["grunt"], "lane": "north", "objective": "breach_command", "behavior_profile": ""}]
	var saved := assault.to_dict()
	for forbidden in ["hp", "damage", "kills", "ammo_spent", "combat_result", "salvage"]: _check(not saved.has(forbidden), "macro assault state contains physical result field %s" % forbidden)
	var plan := assault.to_spawn_plan().to_dict()
	_check(plan.has("plan_id") and plan.waves[0].has("composition"), "handoff plan is not data-only physical instructions")
	_check(not plan.waves[0].has("damage") and not plan.waves[0].has("enemy_results"), "handoff plan contains abstract encounter outcome")
	var runtime := FakeSimulationRuntime.new(); runtime.name = "FakeRuntime"; root.add_child(runtime)
	var manager := FakePhysicalWaveManager.new(); manager.name = "FakeWaveManager"; root.add_child(manager)
	var binding := WaveManagerSimulationBinding.new(); binding.name = "Binding"; binding.simulation_runtime_path = NodePath("../FakeRuntime"); binding.wave_manager_path = NodePath("../FakeWaveManager"); root.add_child(binding)
	runtime.physical_assault_plan_ready.emit(assault.to_spawn_plan()); manager.wave_completed.emit(1)
	_check(runtime.acknowledged == ["assault_test"] and manager.received_plan.plan_id == "assault_test", "typed plan did not cross the physical binding")
	_check(runtime.queued_kind == SimulationCommand.PHYSICAL_ASSAULT_COMPLETED and runtime.queued_payload.get("assault_id", "") == "assault_test", "physical completion was not returned as an observation")
	binding.queue_free(); manager.queue_free(); runtime.queue_free()

func _check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func finish() -> void:
	if failures.is_empty(): print("WORLD_SIMULATION_MACRO_STATE_SMOKE: PASS"); quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
