extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	for ticks in [0,60,6000]:
		var state := DefaultCampaignScenarioFactory.create_world(DefaultCampaignScenarioFactory.create_scenario(9)); var kernel := SimulationKernel.new(state); kernel.queue(SimulationCommand.ADD_MATERIALS,{"amount":4}); state.repairs=[{"job_id":"R1","remaining":2.0}]; state.fabrication_queue=[{"job_id":"F1","remaining":3.0}]
		for index in ticks: kernel.step_once()
		var before := SimulationSnapshot.capture(state); var parsed: Dictionary = JSON.parse_string(JSON.stringify(before.to_dict())); var restored := SimulationSnapshot.restore(parsed); check(restored != null, "restore rejected valid snapshot"); if restored != null: check(state.canonical_fingerprint()==restored.canonical_fingerprint(), "round trip fingerprint mismatch")
	var failed := DefaultCampaignScenarioFactory.create_world(DefaultCampaignScenarioFactory.create_scenario()); failed.structures.COMMAND_POST.apply_damage(100); var fk:=SimulationKernel.new(failed)
	for i in 60: fk.step_once()
	check(failed.failed,"command post failure missing")
	check(SimulationSnapshot.restore({"schema":"bad","schema_version":99}) == null,"invalid schema accepted"); finish()
func check(value: bool, message: String) -> void: if not value: failures.append(message)
func finish() -> void:
	if failures.is_empty():
		print("WORLD_SIMULATION_SNAPSHOT_ROUNDTRIP_SMOKE: PASS")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)
