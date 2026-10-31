extends SceneTree

const HUB_HOST_SCENE := preload("res://scenes/hub_runtime_host.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const HUB_STATE_SCRIPT := preload("res://game/state/persistent/hub_state.gd")
const EVENT_SCRIPT := preload("res://game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd")
const LAYOUT := preload("res://game/world/hub/first_set/hub_first_set_layout.gd")
const EVENT_ID: StringName = &"hub_sepulcher_grave_v1"
const WALK_FRAME_LIMIT := 900


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var legacy_snapshot: Dictionary = (HUB_STATE_SCRIPT.new(7) as HubState).snapshot()
	legacy_snapshot.erase("authored_event_records")
	var legacy_state := HUB_STATE_SCRIPT.restore(legacy_snapshot) as HubState
	_expect(legacy_state != null and legacy_state.authored_event_records.is_empty(), "legacy HubState snapshot did not restore with an empty authored-event namespace", failures)

	var bootstrap := root.get_node_or_null("WorldContractBootstrap")
	var generation_count_before := int(bootstrap.get("generation_count")) if bootstrap != null else -1
	var host := HUB_HOST_SCENE.instantiate() as Node2D
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	await process_frame
	await process_frame

	var world := host.get_node_or_null("World") as Node2D
	var map := host.get_node_or_null("World/Level") as HubFirstSetMap
	var authority := host.get_node_or_null("HubCampaignAuthority")
	var hub_state := authority.get("hub_state") as HubState if authority != null else null
	_expect(world != null and map != null, "production HubRuntimeHost did not load its first-set map", failures)
	_expect(hub_state != null, "production HubRuntimeHost did not own HubState", failures)
	if world == null or map == null or hub_state == null:
		_finish(failures)
		return

	_expect(map.complete_route_activation({"major_context": &"hub"}), "Hub first-set navigation did not activate", failures)
	var event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
	_expect(event != null, "production Hub map did not bind the Grave evidence controller", failures)
	if event == null:
		_finish(failures)
		return

	var positions := event.get_inspection_positions()
	_expect(positions.size() == 3, "grave controller did not define three inspection points", failures)
	for position in positions:
		_expect(
			not map.authored_navigation.compute_path(LAYOUT.MARKERS["Spawn_SouthReach"], position).is_empty(),
			"a grave reading is not on the production Hub navigation network",
			failures
		)
	_expect(event.get_inspection_readout(0).contains("CYCLE 184 · NINTH WATCH"), "reading A changed the invariant date", failures)
	_expect(event.get_inspection_readout(0).contains("RECORD A: ELIAN VALE / WITNESS"), "reading A identity mismatch", failures)
	_expect(event.get_inspection_readout(1).contains("CYCLE 184 · NINTH WATCH"), "reading B changed the invariant date", failures)
	_expect(event.get_inspection_readout(1).contains("RECORD B: MARROW SEN / RELAY KEEPER"), "reading B identity mismatch", failures)
	_expect(event.get_inspection_readout(2).contains("CYCLE 184 · NINTH WATCH"), "reading C changed the invariant date", failures)
	_expect(event.get_inspection_readout(2).contains("RECORD C: IDENTITY HELD / NO VERIFIED CLAIMANT"), "reading C identity mismatch", failures)

	var operator := OPERATOR_SCENE.instantiate() as CharacterBody2D
	operator.name = "Operator"
	world.add_child(operator)
	_expect(map.enter_from_main_at_spawn(operator, &"Spawn_SouthReach"), "real Operator could not enter the Hub", failures)
	_expect(operator.is_in_group("player"), "real Operator is not eligible for physical grave interactions", failures)
	operator.global_position = positions[0]
	await process_frame

	var original_snapshot := hub_state.snapshot()
	var original_without_event_records := original_snapshot.duplicate(true)
	original_without_event_records.erase("authored_event_records")
	var point_a := event.get_inspection_point(0)
	_expect(_operator_targets(operator, point_a), "real Operator could not target the west grave inspection", failures)
	if point_a != null:
		point_a.call("interact", operator)
	var partial_record := hub_state.get_authored_event_record(EVENT_ID)
	_expect(int(partial_record.get("completed_readings", 0)) == 1, "first grave inspection was not persisted exactly once", failures)
	_expect(str(partial_record.get("last_reading_id", "")) == "record_a", "first grave reading identity was not persisted", failures)
	_expect(not bool(point_a.call("can_interact", operator)), "the completed physical inspection remained actionable", failures)

	if point_a != null:
		point_a.call("interact", operator)
		point_a.call("interact", operator)
	_expect(int(hub_state.get_authored_event_record(EVENT_ID).get("completed_readings", 0)) == 1, "repeated presses at one inspection point advanced multiple readings", failures)
	_expect(operator.call("_find_best_interactable", 88.0) == null, "another reading could be advanced from the first inspection position", failures)

	var partial_snapshot := hub_state.snapshot()
	var mutated_read := hub_state.get_authored_event_record(EVENT_ID)
	mutated_read["completed_readings"] = 3
	_expect(int(hub_state.get_authored_event_record(EVENT_ID).get("completed_readings", 0)) == 1, "authored-event record getter did not return a deep copy", failures)
	var mutated_snapshot := hub_state.snapshot()
	var snapshot_records: Dictionary = mutated_snapshot.get("authored_event_records", {})
	var nested_record: Dictionary = snapshot_records.get(String(EVENT_ID), {})
	nested_record["completed_readings"] = 0
	_expect(int(hub_state.get_authored_event_record(EVENT_ID).get("completed_readings", 0)) == 1, "HubState snapshot shared nested event-record data", failures)

	event.queue_free()
	await process_frame
	var resumed_state := HUB_STATE_SCRIPT.restore(partial_snapshot) as HubState
	authority.set("hub_state", resumed_state)
	map.call("_build_sepulcher_grave_evidence")
	await process_frame
	var resumed_event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
	_expect(resumed_event != null and resumed_event.get_completed_readings() == 1, "HubState restore did not resume at reading B", failures)
	var restored_without_event_records := resumed_state.snapshot()
	restored_without_event_records.erase("authored_event_records")
	_expect(restored_without_event_records == original_without_event_records, "grave persistence changed unrelated HubState fields", failures)
	if resumed_event == null:
		_finish(failures)
		return

	var point_b := resumed_event.get_inspection_point(1)
	var walked_to_b := await _walk_operator_to(operator, positions[1], &"move_right")
	_expect(walked_to_b, "real Operator could not walk from reading A to the north connector inspection", failures)
	_expect(_operator_targets(operator, point_b), "real Operator could not select reading B at its physical position", failures)
	if point_b != null and _operator_targets(operator, point_b):
		point_b.call("interact", operator)
	_expect(int(resumed_state.get_authored_event_record(EVENT_ID).get("completed_readings", 0)) == 2, "reading B did not advance the persisted sequence", failures)

	var point_c := resumed_event.get_inspection_point(2)
	var walked_to_c := await _walk_operator_to(operator, positions[2], &"move_down")
	_expect(walked_to_c, "real Operator could not walk from the north approach to the south connector inspection", failures)
	_expect(_operator_targets(operator, point_c), "real Operator could not select reading C at its physical position", failures)
	if point_c != null and _operator_targets(operator, point_c):
		point_c.call("interact", operator)
	var completed_record := resumed_state.get_authored_event_record(EVENT_ID)
	_expect(int(completed_record.get("completed_readings", 0)) == 3, "third inspection did not complete the sequence", failures)
	_expect(str(completed_record.get("last_reading_id", "")) == "record_c", "third reading identity was not persisted", failures)
	_expect(resumed_event.get_completed_readings() == 3, "grave controller snapshot disagrees with HubState", failures)

	var completed_snapshot := resumed_state.snapshot()
	resumed_event.queue_free()
	await process_frame
	var loaded_state := HUB_STATE_SCRIPT.restore(completed_snapshot) as HubState
	authority.set("hub_state", loaded_state)
	map.call("_build_sepulcher_grave_evidence")
	await process_frame
	var loaded_event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
	_expect(loaded_event != null and loaded_event.get_completed_readings() == 3, "completed HubState snapshot lost the grave evidence", failures)
	if loaded_event != null:
		for reading_index in positions.size():
			operator.global_position = positions[reading_index]
			var reread_point := loaded_event.get_inspection_point(reading_index)
			_expect(_operator_targets(operator, reread_point), "completed grave reading %d was not available for rereading" % (reading_index + 1), failures)
			if reread_point != null:
				reread_point.call("interact", operator)
		_expect(loaded_state.get_authored_event_record(EVENT_ID) == completed_record, "rereading a completed grave event changed its evidence record", failures)
	if bootstrap != null:
		_expect(int(bootstrap.get("generation_count")) == generation_count_before, "grave event touched Contract prewarm", failures)

	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "hub_sepulcher_grave_evidence",
		"passed": failures.is_empty(),
		"failure_count": failures.size(),
		"failures": failures,
		"positions": positions,
		"partial_record": partial_record,
		"completed_record": completed_record,
		"hub_generation_count": generation_count_before,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("hub_sepulcher_grave_evidence_smoke: %s" % ("PASS" if failures.is_empty() else "FAIL"))
	_finish(failures)


func _operator_targets(operator: CharacterBody2D, target: Node) -> bool:
	if operator == null or target == null:
		return false
	operator.call("_update_interaction_target")
	return operator.get("interaction_target") == target


func _walk_operator_to(operator: CharacterBody2D, target: Vector2, action: StringName) -> bool:
	Input.action_press(action)
	var reached := false
	for _frame_index in WALK_FRAME_LIMIT:
		await physics_frame
		if operator.global_position.distance_to(target) <= 48.0:
			reached = true
			break
	Input.action_release(action)
	return reached


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(failures: Array[String]) -> void:
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	quit(0 if failures.is_empty() else 1)
