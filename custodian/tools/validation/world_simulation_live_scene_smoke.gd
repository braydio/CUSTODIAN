extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var packed := load("res://scenes/game.tscn") as PackedScene; var scene := packed.instantiate(); root.add_child(scene); current_scene=scene; await process_frame
	var runtimes := get_nodes_in_group("world_simulation_runtime"); check(runtimes.size()==1,"expected exactly one runtime")
	if runtimes.size()==1:
		var runtime := runtimes[0] as WorldSimulationRuntime; check(runtime.clock != null and runtime.kernel != null and runtime.session != null,"runtime ownership incomplete"); var start:=runtime.kernel.state.fixed_tick
		runtime._process(SimulationClock.FIXED_DT); check(runtime.kernel.state.fixed_tick==start+1,"fixed tick did not advance"); runtime.set_simulation_paused(true); var before:=runtime.kernel.state.canonical_fingerprint(); runtime.queue_command(SimulationCommand.ADD_MATERIALS,{"amount":2}); runtime._process(1.0); check(runtime.kernel.state.canonical_fingerprint()==before,"pause mutated state"); runtime.set_simulation_paused(false); runtime._process(SimulationClock.FIXED_DT); check(runtime.kernel.state.materials==5,"paused command did not survive"); check(runtime.latest_snapshot != null,"snapshot absent")
	for identity in WorldIdentityContract.SCENE_SECTOR_TO_MACRO: check(not WorldIdentityContract.map_scene_identity(identity).is_empty(),"unresolved identity %s" % identity)
	var game_state:=root.get_node_or_null("GameState"); check(game_state != null and game_state.has_method("advance"),"GameState compatibility unavailable"); finish()
func check(value: bool, message: String) -> void: if not value: failures.append(message)
func finish() -> void:
	if failures.is_empty(): print("WORLD_SIMULATION_LIVE_SCENE_SMOKE: PASS"); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)
