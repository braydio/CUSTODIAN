extends SceneTree

const AWAKENING_SCENE := preload("res://scenes/awakening_first_return.tscn")
const FAKE_CONTRACT_MAP_SCRIPT := preload(
	"res://tools/validation/fixtures/fake_world_contract_map.gd"
)
const CAMPAIGN_SCENARIO_SCRIPT := preload("res://game/state/run/campaign_scenario.gd")
const HUB_STATE_SCRIPT := preload("res://game/state/persistent/hub_state.gd")
const SELECTION_AUTHORITY_SCRIPT := preload(
	"res://game/world/hub/hub_campaign_selection_authority.gd"
)

var _route_failure_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var bootstrap := root.get_node_or_null("WorldContractBootstrap")
	var transition_manager := root.get_node_or_null("WorldTransitionManager")
	_expect(bootstrap != null, "WorldContractBootstrap autoload is missing", failures)
	_expect(transition_manager != null, "WorldTransitionManager autoload is missing", failures)
	if not failures.is_empty():
		_finish(failures)
		return

	bootstrap.call("reset")
	bootstrap.call("restore_generator_scene")
	transition_manager.call("arm_for_startup_awakening")
	var awakening := AWAKENING_SCENE.instantiate()
	root.add_child(awakening)
	current_scene = awakening
	await process_frame
	awakening.set("completed", true)
	awakening.set("opening_console_acknowledged", true)
	awakening.set("p9_recovered", true)
	var operator := awakening.get_node("World/Operator") as CharacterBody2D
	operator.global_position = Vector2(0.0, -6336.0)
	var completion_snapshot := {
		"completed": true,
		"opening_console_acknowledged": true,
		"p9_recovered": true,
		"final_zone_id": &"zone10_road_south_reach",
		"operator_global_position": operator.global_position,
	}
	_expect(
		bool(transition_manager.call("request_awakening_to_hub", completion_snapshot)),
		"qualified Awakening did not request the production Hub handoff",
		failures
	)
	await _wait_for_hub(transition_manager)
	var hub_root := current_scene
	var hub_world := hub_root.get_node_or_null("World") as Node2D
	var hub_map := hub_world.get_node_or_null("Level") if hub_world != null else null
	var authority := hub_root.get_node_or_null("HubCampaignAuthority") if hub_root != null else null
	var dais := hub_map.get_node_or_null("AdjudicationDaisInteraction") if hub_map != null else null
	var route_manager := hub_world.get_node_or_null("RouteTraversalManager") if hub_world != null else null
	var ingress := hub_world.get_node_or_null("CrownTransferIngress") if hub_world != null else null
	_expect(authority != null, "production Hub host omitted HubCampaignAuthority", failures)
	_expect(dais != null and dais.is_in_group("interactable"), "production H1 map omitted its Adjudication Dais interaction", failures)
	_expect(route_manager != null and ingress != null, "H4 route services are unavailable for the persistence check", failures)
	_expect(int(bootstrap.get("generation_count")) == 0, "Hub entry started Contract prewarm before Dais acceptance", failures)
	if not failures.is_empty():
		_finish(failures)
		return

	var fake_success := _build_fake_generator_scene(false)
	bootstrap.call("set_generator_scene_for_testing", fake_success)
	var authority_identity := authority.get_instance_id()
	var hub_state := authority.get("hub_state") as HubState
	var scene_before_acceptance := current_scene
	operator.global_position = dais.global_position
	var interaction_target := operator.call("_find_best_interactable", 88.0) as Node
	_expect(interaction_target == dais, "Operator proximity did not select the production Dais", failures)
	var accepted_result: Dictionary = dais.call("interact", operator)
	var accepted_scenario := authority.call("get_accepted_scenario") as CampaignScenario
	_expect(bool(accepted_result.get("ok", false)), "Dais acceptance did not succeed", failures)
	_expect(accepted_scenario != null, "HubState did not retain a typed CampaignScenario", failures)
	if accepted_scenario == null:
		_finish(failures)
		return
	var accepted_identity := accepted_scenario.get_instance_id()
	var accepted_seed := accepted_scenario.seed
	_expect(accepted_seed != 0, "accepted scenario seed is zero", failures)
	_expect(
		int(bootstrap.get("generation_count")) == 1,
		"Dais acceptance did not start exactly one prewarm generation",
		failures
	)
	_expect(int(bootstrap.get("run_seed")) == accepted_seed, "bootstrap seed differs from the accepted scenario", failures)
	_expect(
		bootstrap.call("get_state") == 1,
		"fake Contract generator did not enter GENERATING after acceptance",
		failures
	)
	var repeated_generating: Dictionary = dais.call("interact", operator)
	_expect(not bool(repeated_generating.get("ok", false)), "a repeated GENERATING interaction was accepted again", failures)
	_expect(int(bootstrap.get("generation_count")) == 1, "GENERATING interaction started a duplicate prewarm", failures)

	await _wait_for_bootstrap_state(bootstrap, 2)
	_expect(bootstrap.call("is_ready"), "fake Contract prewarm did not reach READY", failures)
	_expect(current_scene == scene_before_acceptance, "Dais acceptance changed the current scene", failures)
	_expect(current_scene != null and current_scene.scene_file_path != "res://scenes/game.tscn", "H3 loaded the operational Contract scene", failures)
	_expect(String(transition_manager.get("current_context")) == "hub", "Hub ceased to own the major context during prewarm", failures)
	_expect(
		int((authority.call("get_preparation_snapshot") as Dictionary).get("accepted_seed", 0)) == accepted_seed,
		"H5 preparation snapshot omitted the accepted seed",
		failures
	)
	_expect(
		String((authority.call("get_preparation_snapshot") as Dictionary).get("generation_state", "")) == "READY",
		"H5 preparation snapshot omitted READY state",
		failures
	)
	var repeated_ready: Dictionary = dais.call("interact", operator)
	_expect(not bool(repeated_ready.get("ok", false)), "a repeated READY interaction was accepted again", failures)
	_expect(int(bootstrap.get("generation_count")) == 1, "READY interaction rerolled the accepted scenario", failures)

	var state_snapshot := hub_state.call("snapshot") as Dictionary
	var restored_state := HUB_STATE_SCRIPT.restore(state_snapshot) as HubState
	var restored_scenario := restored_state.get_accepted_scenario() as CampaignScenario
	_expect(restored_scenario != null, "HubState snapshot omitted the accepted scenario", failures)
	if restored_scenario != null:
		_expect(restored_scenario.scenario_id == accepted_scenario.scenario_id, "HubState restore changed scenario identity", failures)
		_expect(restored_scenario.seed == accepted_seed, "HubState restore changed scenario seed", failures)

	var h1_identity := hub_map.get_instance_id()
	var session_identity := hub_state.get_instance_id()
	var ingress_position: Vector2 = hub_map.call("get_named_marker", &"CrownTransfer").global_position
	operator.global_position = ingress_position
	ingress.call("interact", operator)
	await _wait_for_twin(route_manager)
	var route_session: RefCounted = route_manager.call("get_active_session") as RefCounted
	var twin: Node = route_session.get("current_instance") if route_session != null else null
	_expect(twin != null, "accepted Hub scenario could not enter the Twin route", failures)
	_expect(not hub_map.visible, "H1 remained active while Twin owned route traversal", failures)
	_expect(not dais.call("can_interact", operator), "the deactivated H1 Dais remained interactable in Twin", failures)
	_expect(current_scene == hub_root, "Twin authored traversal changed the Hub host scene", failures)
	_expect(hub_map.get_instance_id() == h1_identity, "Twin traversal replaced the H1 map", failures)
	_expect(authority.get_instance_id() == authority_identity, "Twin traversal replaced the Hub campaign authority", failures)
	_expect((authority.get("hub_state") as HubState).get_instance_id() == session_identity, "Twin traversal replaced HubState", failures)
	_expect((authority.call("get_accepted_scenario") as CampaignScenario).get_instance_id() == accepted_identity, "Twin traversal replaced the accepted scenario", failures)
	_expect(int(bootstrap.get("generation_count")) == 1, "Twin traversal restarted Contract prewarm", failures)
	if twin != null:
		var return_exit := twin.get_node_or_null("Exits/Exit_ReturnHub") as Node2D
		_expect(return_exit != null, "Twin route omitted its return exit", failures)
		if return_exit != null:
			operator.global_position = return_exit.global_position
			return_exit.call("interact", operator)
			await _wait_for_route_end(route_manager)
	_expect(current_scene == hub_root, "Twin return left the player outside the Hub", failures)
	_expect(hub_map.visible, "Twin return did not reactivate H1", failures)
	_expect(dais.call("can_interact", operator), "H1 Dais did not reactivate after Twin return", failures)
	_expect((authority.call("get_accepted_scenario") as CampaignScenario).get_instance_id() == accepted_identity, "Twin return lost the accepted scenario", failures)
	_expect(int(bootstrap.get("generation_count")) == 1, "Twin return restarted Contract prewarm", failures)

	# Use a second fresh authority and a failing fake generator to prove the failure
	# remains visible while the accepted scenario stays latched against rerolls.
	bootstrap.call("reset")
	bootstrap.call("set_generator_scene_for_testing", _build_fake_generator_scene(true))
	var failure_authority := Node.new()
	failure_authority.name = "H3FailureAuthorityProbe"
	failure_authority.set_script(SELECTION_AUTHORITY_SCRIPT)
	root.add_child(failure_authority)
	await process_frame
	var failure_result: Dictionary = failure_authority.call("accept_first_contract")
	_expect(bool(failure_result.get("ok", false)), "failure probe could not accept its first scenario", failures)
	await _wait_for_bootstrap_state(bootstrap, 3)
	_expect(String(failure_authority.call("get_preparation_state")) == "FAILED", "failed prewarm state was not exposed", failures)
	_expect(
		String(failure_authority.call("get_dais_interaction_prompt")).contains("FAILED"),
		"the Dais did not surface FAILED prewarm status",
		failures
	)
	var failed_scenario := failure_authority.call("get_accepted_scenario") as CampaignScenario
	var failed_identity := failed_scenario.get_instance_id() if failed_scenario != null else 0
	var generation_count_after_failure := int(bootstrap.get("generation_count"))
	var repeated_failure: Dictionary = failure_authority.call("accept_first_contract")
	_expect(String(repeated_failure.get("code", "")) == "SCENARIO_ALREADY_ACCEPTED", "FAILED interaction did not remain latched", failures)
	_expect(int(bootstrap.get("generation_count")) == generation_count_after_failure, "FAILED interaction started a retry or reroll", failures)
	_expect(
		(failure_authority.call("get_accepted_scenario") as CampaignScenario).get_instance_id() == failed_identity,
		"FAILED interaction replaced the accepted scenario",
		failures
	)
	_expect(current_scene == hub_root, "failed prewarm changed the current Hub scene", failures)
	_expect(String(transition_manager.get("current_context")) == "hub", "failed prewarm displaced Hub context", failures)

	failure_authority.queue_free()
	bootstrap.call("reset")
	bootstrap.call("restore_generator_scene")
	await process_frame
	if failures.is_empty():
		print("hub_forum_adjudication_smoke: PASS accepted_once seed=%d TwinRoundTrip=true failureVisible=true" % accepted_seed)
		quit(0)
	else:
		_finish(failures)


func _build_fake_generator_scene(should_fail: bool) -> PackedScene:
	var generator := Node2D.new()
	generator.set_script(FAKE_CONTRACT_MAP_SCRIPT)
	generator.set("should_fail", should_fail)
	var packed := PackedScene.new()
	packed.pack(generator)
	generator.free()
	return packed


func _wait_for_hub(manager: Node) -> void:
	for _frame in range(300):
		if StringName(manager.get("current_context")) == &"hub" and not bool(manager.call("is_transitioning")):
			return
		await process_frame


func _wait_for_twin(manager: Node) -> void:
	for _frame in range(300):
		var session: RefCounted = manager.call("get_active_session") as RefCounted
		if session != null and session.get("current_level_id") == &"hub_twin_solaria":
			return
		await process_frame


func _wait_for_route_end(manager: Node) -> void:
	for _frame in range(300):
		if manager.call("get_active_session") == null:
			return
		await process_frame


func _wait_for_bootstrap_state(bootstrap: Node, expected_state: int) -> void:
	for _frame in range(120):
		if int(bootstrap.call("get_state")) == expected_state:
			return
		await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(failures: Array[String]) -> void:
	for failure: String in failures:
		push_error("hub_forum_adjudication_smoke: %s" % failure)
	print("hub_forum_adjudication_smoke: FAIL count=%d" % failures.size())
	quit(1)
