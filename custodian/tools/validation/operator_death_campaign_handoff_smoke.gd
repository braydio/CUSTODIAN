extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

var failures: Array[String] = []
var handoffs := 0
var outcomes := 0
var received_context: Dictionary = {}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset_run_state()

	var runtime := WorldSimulationRuntime.new()
	root.add_child(runtime)
	runtime.set_process(false)

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	operator.set_physics_process(false)
	operator.set_process(false)
	operator.set("_last_incoming_attack_context", {"attack_id": "lethal-probe"})
	operator.operator_down.connect(func(context: Dictionary):
		handoffs += 1
		received_context = context.duplicate(true)
		operator.call("_handle_death")
	)
	runtime.campaign_resolved.connect(func(outcome: CampaignOutcome):
		outcomes += 1
		check(outcome.is_valid() and outcome.result == &"FAILURE", "invalid failure outcome")
		check(outcome.reason == OperatorDeathCampaignBinding.DEATH_REASON, "death reason lost")
		check(not game_state.game_over, "Game Over preceded campaign outcome")
		operator.call("_handle_death")
		operator.get_node("OperatorDeathCampaignBinding").consume_operator_down({})
	)
	operator.call("_handle_death")
	operator.call("_handle_death")
	check(handoffs == 1 and outcomes == 1, "duplicate macro handoff/outcome")
	check(
		received_context.get("lethal_attack_context", {}).get("attack_id") == "lethal-probe",
		"structured lethal context lost",
	)
	check(
		received_context.has("position") and received_context.has("field_patches_remaining"),
		"death snapshot incomplete",
	)
	check(runtime.session.is_resolved(), "campaign remained unresolved")
	check(game_state.game_over, "campaign fallback absent")
	check(game_state.lives_remaining == game_state.total_lives, "Operator decremented legacy lives")
	operator.call("_finish_death")
	check(operator.get("_is_dead") and operator.current_health == 0.0, "fallback revived Operator")
	operator.free()
	runtime.free()
	game_state.reset_run_state()

	# An authored world without a runtime must still reach the safe fallback.
	operator = OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	operator.set_physics_process(false)
	operator.call("_handle_death")
	check(game_state.game_over, "no-runtime fallback absent")
	check(get_nodes_in_group("world_simulation_runtime").is_empty(), "fallback fabricated a campaign")
	operator.free()
	game_state.reset_run_state()

	# Already-resolved and unstarted sessions must not produce another outcome.
	for started in [true, false]:
		runtime = WorldSimulationRuntime.new()
		runtime.auto_start_default = false
		root.add_child(runtime)
		runtime.session = CampaignSession.new()
		if started:
			runtime.session.start()
			runtime.resolve_campaign(&"SUCCESS", "prior resolution")
		runtime.campaign_resolved.connect(func(_outcome: CampaignOutcome): outcomes += 1)
		operator = OPERATOR_SCENE.instantiate()
		root.add_child(operator)
		operator.call("_handle_death")
		check(outcomes == 1 and game_state.game_over, "inactive/resolved session fallback failed")
		operator.free()
		runtime.free()
		game_state.reset_run_state()

	var source := FileAccess.get_file_as_string("res://game/actors/operator/operator.gd")
	check(not source.contains("lose_life("), "actor still owns legacy life decrement")
	if failures.is_empty():
		print("OPERATOR_DEATH_CAMPAIGN_HANDOFF_SMOKE: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
