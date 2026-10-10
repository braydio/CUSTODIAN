extends SceneTree

const AWAKENING_SCENE := preload("res://scenes/awakening_first_return.tscn")
const HUB_MAP_SCRIPT := preload("res://game/world/hub/first_set/hub_first_set_map.gd")
const FAKE_CONTRACT_MAP_SCRIPT := preload("res://tools/validation/fixtures/fake_world_contract_map.gd")

var _finished_results: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager := root.get_node_or_null("WorldTransitionManager")
	if manager == null:
		_fail("WorldTransitionManager autoload is missing")
		return
	manager.transition_finished.connect(_on_transition_finished)
	manager.call("arm_for_startup_awakening")
	var awakening := AWAKENING_SCENE.instantiate()
	root.add_child(awakening)
	current_scene = awakening
	await process_frame
	var operator := awakening.get_node("World/Operator") as CharacterBody2D
	if operator == null or manager.get("active_context_root") != awakening:
		_fail("Production Awakening was not registered with a real Operator")
		return

	var invalid_snapshot := {"completed": false}
	if bool(manager.call("request_awakening_to_hub", invalid_snapshot)):
		_fail("Incomplete completion snapshot was accepted")
		return
	if StringName(manager.get("last_rejection_code")) != &"COMPLETION_NOT_QUALIFIED":
		_fail("Incomplete qualification did not fail closed deterministically")
		return

	awakening.set("opening_console_acknowledged", true)
	awakening.set("p9_recovered", true)
	var completion_volume := awakening.get_node("World/AwakeningZones/Zone10_RoadSouthReach/Triggers/SouthReachCompletion") as Area2D
	operator.global_position = completion_volume.global_position + Vector2(0.0, 100.0)
	var qualified_snapshot := {
		"completed": true,
		"opening_console_acknowledged": true,
		"p9_recovered": true,
		"final_zone_id": &"zone10_road_south_reach",
		"operator_global_position": operator.global_position,
	}
	manager.set("hub_host_scene_path", "res://scenes/missing_hub_runtime_host.tscn")
	await physics_frame
	await physics_frame
	operator.global_position = completion_volume.global_position
	for _frame in range(10):
		await physics_frame
		if bool(manager.call("is_transitioning")):
			break
	if not bool(manager.call("is_transitioning")) or operator.is_physics_processing():
		_fail("Real Operator entering from south did not synchronously freeze outgoing movement")
		return
	manager.call("request_awakening_to_hub", qualified_snapshot)
	if StringName(manager.get("last_rejection_code")) != &"TRANSITION_IN_PROGRESS":
		_fail("Duplicate completion was not suppressed while staging")
		return
	await _wait_for_result_count(1)
	if _finished_results.size() != 1:
		_fail("Target-stage failure did not produce exactly one result")
		return
	var failure := _finished_results[0]
	if bool(failure.get("succeeded", true)) or StringName(failure.get("failure_code", &"")) != &"TARGET_SCENE_UNAVAILABLE":
		_fail("Missing Hub scene did not report TARGET_SCENE_UNAVAILABLE")
		return
	if operator.global_position != Vector2(0.0, -6336.0):
		_fail("Rollback did not return the Operator south of the completion volume")
		return
	if current_scene != awakening or bool(awakening.get("completed")):
		_fail("Rollback did not restore Awakening as the playable current scene")
		return
	if operator.get_parent() != awakening.get_node("World") or operator.collision_layer == 0 or operator.collision_mask == 0:
		_fail("Rollback did not restore Operator parent and collision")
		return
	if awakening.get_node_or_null("World/AwakeningZones/Zone10_RoadSouthReach/SetPieces/SouthReachCollapse") == null:
		_fail("Rollback removed the Awakening safety barrier")
		return
	if int(manager.call("count_authoritative_worlds")) != 1:
		_fail("Rollback did not restore exactly one authoritative world")
		return

	var collision_layer := operator.collision_layer
	var collision_mask := operator.collision_mask
	operator.collision_layer = 0
	operator.collision_mask = 0
	operator.global_position = completion_volume.global_position + Vector2(0.0, 300.0)
	await physics_frame
	await physics_frame
	manager.set("hub_host_scene_path", "res://scenes/hub_runtime_host.tscn")
	operator.collision_layer = collision_layer
	operator.collision_mask = collision_mask
	operator.global_position = completion_volume.global_position + Vector2(0.0, 100.0)
	await physics_frame
	await physics_frame
	operator.global_position = completion_volume.global_position
	for _frame in range(10):
		await physics_frame
		if bool(manager.call("is_transitioning")):
			break
	if not bool(manager.call("is_transitioning")) or operator.is_physics_processing():
		_fail("Second real Operator entry did not freeze movement immediately")
		return
	await _wait_for_result_count(2)
	if _finished_results.size() != 2:
		_fail("Successful Hub transition did not produce exactly one result")
		return
	var success := _finished_results[1]
	if not bool(success.get("succeeded", false)) or StringName(success.get("final_context", &"")) != &"hub":
		_fail("Qualified Awakening completion did not enter Hub")
		return
	var hub_root := current_scene
	var hub_world := hub_root.get_node_or_null("World")
	var map := hub_root.get_node_or_null("World/Level")
	var navigation := hub_root.get_node_or_null("NavigationSystem")
	var camera := hub_root.get_node_or_null("World/Camera2D") as Camera2D
	if hub_root.name != "GameRoot" or not (map is HUB_MAP_SCRIPT) or operator.get_parent() != hub_world:
		_fail("Hub host does not contain the reviewed map and transferred Operator")
		return
	if operator.global_position != map.call("get_spawn_position", &"Spawn_SouthReach"):
		_fail("Operator did not arrive exactly at Spawn_SouthReach")
		return
	if navigation.get("runtime_navigation_provider") != map.get("authored_navigation"):
		_fail("Hub authored navigation was not bound before input unlock")
		return
	if camera.call("get_runtime_map") != map:
		_fail("Hub runtime camera map was not bound")
		return
	var order: Array = success.get("binding_order", [])
	if order.find(&"navigation_bound") < 0 or order.find(&"camera_bound") <= order.find(&"navigation_bound") or order.find(&"authority_committed") <= order.find(&"camera_bound") or order.find(&"input_unlocked") <= order.find(&"authority_committed"):
		_fail("Hub bindings and input unlock did not occur in the required order")
		return
	if int(manager.call("count_authoritative_worlds")) != 1:
		_fail("Successful Hub commit did not leave exactly one authoritative world")
		return
	var completion_count := _finished_results.size()
	if bool(manager.call("request_awakening_to_hub", qualified_snapshot)):
		_fail("Stale Awakening completion created another Hub transition")
		return
	await process_frame
	if _finished_results.size() != completion_count:
		_fail("Stale Awakening completion created another Hub transition")
		return
	if root.get_node_or_null("WorldContractBootstrap") == null or int(root.get_node("WorldContractBootstrap").get("generation_count")) != 0:
		_fail("Awakening-to-Hub transition unexpectedly generated a Contract")
		return
	await _exercise_continuity_port_deployment(manager, hub_root, operator)

	print("PASS: H2 handoff plus H5 Continuity Port pending, rollback, exact scenario/map deployment, and authority exclusivity")
	quit(0)


func _wait_for_result_count(count: int) -> void:
	for _frame in range(240):
		if _finished_results.size() >= count:
			return
		await process_frame


func _exercise_continuity_port_deployment(manager: Node, hub_root: Node, operator: CharacterBody2D) -> void:
	var authority := hub_root.get_node_or_null("HubCampaignAuthority")
	var port := hub_root.get_node_or_null("World/Level/ContinuityPortInteraction")
	var bootstrap := root.get_node_or_null("WorldContractBootstrap")
	if authority == null or port == null or bootstrap == null:
		_fail("Production Hub did not expose its scenario authority and Continuity Port")
		return
	bootstrap.call("reset")
	await process_frame
	bootstrap.call("set_generator_scene_for_testing", _build_fake_generator_scene())
	var accepted: Dictionary = authority.call("accept_first_contract")
	if not bool(accepted.get("ok", false)):
		_fail("Forum did not accept the first scenario")
		return
	var scenario: CampaignScenario = accepted.get("scenario")
	var pending: Dictionary = port.call("interact", operator)
	if pending.get("code") != "PREPARATION_PENDING" or int(bootstrap.get("generation_count")) != 1:
		_fail("Port failed to hold Hub while the one accepted Contract generated")
		return
	for _frame in range(120):
		if int(bootstrap.call("get_state")) != 1:
			break
		await process_frame
	if int(bootstrap.call("get_state")) != 2:
		_fail("Fake accepted Contract did not reach READY")
		return
	var map_instance: Node = bootstrap.get_latest_contract().get("map", {}).get("instance")
	if map_instance == null:
		_fail("READY bootstrap did not retain its generated map")
		return
	var map_id := map_instance.get_instance_id()
	manager.set("campaign_scene_path", "res://tools/validation/fixtures/hub_campaign_deployment_failure.tscn")
	var rejected_activation: Dictionary = port.call("interact", operator)
	if not bool(rejected_activation.get("ok", false)):
		_fail("READY Port did not begin the first Campaign activation attempt")
		return
	await _wait_for_result_count(3)
	if _finished_results.size() != 3 or bool(_finished_results[2].get("succeeded", true)) \
			or get_current_scene() != hub_root or int(bootstrap.call("get_state")) != 2 \
			or bootstrap.get_latest_contract().get("map", {}).get("instance") != map_instance:
		_fail("Activation failure did not restore Hub and the same READY map")
		return
	var still_accepted: CampaignScenario = authority.call("get_accepted_scenario")
	if still_accepted == null or still_accepted.scenario_id != scenario.scenario_id:
		_fail("Deployment rollback changed accepted Hub scenario state")
		return
	manager.set("campaign_scene_path", "res://tools/validation/fixtures/hub_campaign_deployment_success.tscn")
	var deploy: Dictionary = port.call("interact", operator)
	if not bool(deploy.get("ok", false)):
		_fail("READY Port could not retry activation with the retained map")
		return
	await _wait_for_result_count(4)
	if _finished_results.size() != 4 or not bool(_finished_results[3].get("succeeded", false)):
		_fail("Same-map Hub→Campaign activation did not commit")
		return
	var campaign := get_current_scene()
	var simulation := campaign.get_node_or_null("Simulation")
	var loader := campaign.get_node_or_null("ContractWorldLoader")
	var session: CampaignSession = simulation.get("session") if simulation != null else null
	var active_map: Node = loader.call("get_active_map_instance") if loader != null else null
	if session == null or session.scenario.scenario_id != scenario.scenario_id \
			or session.scenario.seed != scenario.seed or active_map == null \
			or active_map.get_instance_id() != map_id \
			or campaign.get_node("World/Operator") != operator \
			or int(bootstrap.call("get_state")) != 4 \
			or int(manager.call("count_authoritative_worlds")) != 1:
		_fail("Campaign lost accepted identity, prewarmed map, Operator, or exclusive authority")
		return
	manager.set("campaign_scene_path", "res://scenes/game.tscn")


func _build_fake_generator_scene() -> PackedScene:
	var generator := Node2D.new()
	generator.set_script(FAKE_CONTRACT_MAP_SCRIPT)
	var packed := PackedScene.new()
	assert(packed.pack(generator) == OK)
	generator.free()
	return packed


func _on_transition_finished(result: Dictionary) -> void:
	_finished_results.append(result.duplicate(true))


func _fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)
