extends SceneTree
const FIXTURE_DIR := "res://tools/validation/fixtures/world_simulation"
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var files := DirAccess.get_files_at(FIXTURE_DIR); files.sort()
	for file in files:
		if not file.ends_with(".json"): continue
		var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [FIXTURE_DIR,file])); if not SimulationParityContract.validate_fixture(fixture): failures.append("invalid fixture: %s" % file); continue
		var actual := replay(fixture); var expected: Dictionary = SimulationCanonicalJson.normalize(fixture.projection); var diffs := SimulationParityContract.differences(expected, actual)
		for diff in diffs: failures.append("PARITY_MISMATCH fixture: %s path: %s python: %s godot: %s" % [file,diff.path,diff.python,diff.godot])
		var actual_hash := SimulationCanonicalJson.sha256(actual); if actual_hash != fixture.projection_sha256: failures.append("PARITY_HASH_MISMATCH %s python=%s godot=%s" % [file,fixture.projection_sha256,actual_hash])
		if SimulationCanonicalJson.encode(actual) != SimulationCanonicalJson.encode(replay(fixture)): failures.append("repeat diverged: %s" % file)
	finish()
func replay(fixture: Dictionary) -> Dictionary:
	var state := WorldSimulationState.new(int(fixture.seed)); var kernel := SimulationKernel.new(state)
	for command: Dictionary in fixture.commands: kernel.queue(StringName(command.kind), command.payload, int(command.at_world_tick))
	kernel.apply_commands_at_current_boundary()
	while state.world_tick < int(fixture.checkpoint_world_tick): for index in 60: kernel.step_once()
	if state.fixed_tick != state.world_tick*60: failures.append("macro relation mismatch")
	return SimulationParityContract.projection(state)
func finish() -> void:
	if failures.is_empty(): print("WORLD_SIMULATION_PYTHON_PARITY_SMOKE: PASS"); quit(0)
	else: for failure in failures: push_error(failure); quit(1)
