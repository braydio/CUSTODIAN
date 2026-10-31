extends SceneTree

const HUB_HOST_SCENE := preload("res://scenes/hub_runtime_host.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const HUB_STATE_SCRIPT := preload("res://game/state/persistent/hub_state.gd")
const LAYOUT := preload("res://game/world/hub/first_set/hub_first_set_layout.gd")
const EVENT_ID: StringName = &"hub_sepulcher_grave_v1"
const RECORD_SCHEMA := "custodian.hub_authored_event.sepulcher_grave.v1"
const ATTEST := "attest_provenance_conflict"
const LEAVE := "leave_unresolved"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
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
	var state := authority.get("hub_state") as HubState if authority != null else null
	_expect(world != null and map != null and state != null, "production Hub host did not bind its world, map, and HubState", failures)
	if world == null or map == null or authority == null or state == null:
		_finish(failures)
		return
	_expect(map.complete_route_activation({"major_context": &"hub"}), "Hub navigation did not activate", failures)

	var operator := OPERATOR_SCENE.instantiate() as CharacterBody2D
	operator.name = "Operator"
	world.add_child(operator)
	_expect(map.enter_from_main_at_spawn(operator, &"Spawn_SouthReach"), "real Operator could not enter the Hub", failures)
	var event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
	_expect(event != null, "production map did not bind the grave controller", failures)
	if event == null:
		_finish(failures)
		return

	var readings := event.get_inspection_positions()
	for index in readings.size():
		operator.global_position = readings[index]
		var reading_point := event.get_inspection_point(index)
		_expect(reading_point != null and reading_point.call("can_interact", operator), "ordered grave reading %d was unavailable" % (index + 1), failures)
		if reading_point != null:
			reading_point.call("interact", operator)
	_expect(event.get_completed_readings() == 3, "three distinct readings did not enable the resolution", failures)
	_expect(event.can_offer_resolution(), "the unresolved grave did not offer its decision", failures)

	var choices := event.get_resolution_points()
	_expect(choices.size() == 2, "grave did not expose exactly two physical resolution points", failures)
	var labels: Array[String] = []
	for choice in choices:
		labels.append(str(choice.get_interaction_prompt()))
		_expect(
			not map.authored_navigation.compute_path(LAYOUT.MARKERS["Spawn_SouthReach"], choice.global_position).is_empty(),
			"a resolution interaction point was outside production Hub navigation",
			failures
		)
	_expect(labels.has("ATTEST: PROVENANCE CONFLICT"), "attestation choice label changed", failures)
	_expect(labels.has("LEAVE UNRESOLVED"), "leave-unresolved choice label changed", failures)
	var unresolved_snapshot := state.snapshot()

	var attest_point: Node2D = null
	for choice in choices:
		if str(choice.get("resolution_id")) == ATTEST:
			attest_point = choice
	_expect(attest_point != null, "attestation interaction point was missing", failures)
	if attest_point != null:
		operator.global_position = attest_point.global_position
		_expect(bool(attest_point.call("can_interact", operator)), "attestation was not physically actionable", failures)
		attest_point.call("interact", operator)
	var attested := state.get_authored_event_record(EVENT_ID)
	_expect(str(attested.get("resolution", "")) == ATTEST, "attestation was not persisted", failures)
	if attest_point != null:
		attest_point.call("interact", operator)
	_expect(state.get_authored_event_record(EVENT_ID) == attested, "repeated choice input changed the resolution record", failures)
	_expect(not event.can_offer_resolution(), "resolved grave still offered another choice", failures)
	for choice in choices:
		_expect(not bool(choice.call("can_interact", operator)), "a resolution choice remained actionable after commitment", failures)

	var resolved_snapshot := state.snapshot()
	event.queue_free()
	await process_frame
	var restored_state := HUB_STATE_SCRIPT.restore(resolved_snapshot) as HubState
	authority.set("hub_state", restored_state)
	map.call("_build_sepulcher_grave_evidence")
	await process_frame
	var returning_event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
	_expect(returning_event != null and returning_event.get_growth_visible(), "resolved grave did not show its pale growth on return", failures)
	_expect(returning_event != null and str(returning_event.get_event_snapshot().get("resolution")) == ATTEST, "snapshot restore changed the attestation", failures)
	var attested_growth_visible_on_return := returning_event != null and returning_event.get_growth_visible()
	if returning_event != null:
		for index in readings.size():
			operator.global_position = readings[index]
			var reading_point := returning_event.get_inspection_point(index)
			_expect(reading_point != null and bool(reading_point.call("can_interact", operator)), "resolved grave reading %d could not be reread" % (index + 1), failures)
			if reading_point != null:
				reading_point.call("interact", operator)
		_expect(restored_state.get_authored_event_record(EVENT_ID) == attested, "rereading evidence altered the recorded resolution", failures)
		_expect(not _contains_collision_owner(returning_event), "grave choice or growth presentation introduced collision ownership", failures)

	# Restore the exact unresolved three-reading pre-choice state and exercise the
	# independent LEAVE UNRESOLVED path against a fresh controller.
	var leave_state := HUB_STATE_SCRIPT.restore(unresolved_snapshot) as HubState
	authority.set("hub_state", leave_state)
	if returning_event != null:
		returning_event.queue_free()
	await process_frame
	map.call("_build_sepulcher_grave_evidence")
	await process_frame
	var leave_event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
	var leave_point: Node2D = null
	if leave_event != null:
		for choice in leave_event.get_resolution_points():
			if str(choice.get("resolution_id")) == LEAVE:
				leave_point = choice
	_expect(leave_point != null, "leave-unresolved interaction point was missing", failures)
	if leave_point != null:
		operator.global_position = leave_point.global_position
		_expect(bool(leave_point.call("can_interact", operator)), "leave-unresolved was not physically actionable", failures)
		leave_point.call("interact", operator)
	var left_unresolved_record := leave_state.get_authored_event_record(EVENT_ID)
	_expect(str(left_unresolved_record.get("resolution", "")) == LEAVE, "leave-unresolved choice was not persisted", failures)
	if leave_point != null:
		leave_point.call("interact", operator)
	_expect(leave_state.get_authored_event_record(EVENT_ID) == left_unresolved_record, "repeated leave-unresolved input changed its committed record", failures)
	_expect(leave_event != null and not leave_event.get_growth_visible(), "pale growth appeared before a later visit after resolution", failures)
	var leave_snapshot := leave_state.snapshot()
	if leave_event != null:
		leave_event.queue_free()
	await process_frame
	var restored_leave_state := HUB_STATE_SCRIPT.restore(leave_snapshot) as HubState
	authority.set("hub_state", restored_leave_state)
	map.call("_build_sepulcher_grave_evidence")
	await process_frame
	var returning_leave_event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
	_expect(returning_leave_event != null and str(returning_leave_event.get_resolution()) == LEAVE, "leave-unresolved snapshot did not restore its finding", failures)
	_expect(returning_leave_event != null and returning_leave_event.get_growth_visible(), "leave-unresolved finding did not show pale growth on a later visit", failures)
	if returning_leave_event != null:
		_expect(not returning_leave_event.can_offer_resolution(), "restored leave-unresolved finding offered a second resolution", failures)
		for choice in returning_leave_event.get_resolution_points():
			_expect(not bool(choice.call("can_interact", operator)), "restored leave-unresolved choice remained actionable", failures)
	if bootstrap != null:
		_expect(int(bootstrap.get("generation_count")) == generation_count_before, "grave resolution touched Contract prewarm", failures)
	_expect(restored_state.snapshot().get("accepted_scenario", {}) == state.snapshot().get("accepted_scenario", {}), "grave resolution changed accepted Contract state", failures)

	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "hub_sepulcher_grave_resolution",
		"passed": failures.is_empty(),
		"failure_count": failures.size(),
		"failures": failures,
		"attested_record": attested,
		"leave_unresolved_record": left_unresolved_record,
		"attestation_growth_visible_on_return": attested_growth_visible_on_return,
		"leave_unresolved_growth_visible_on_return": returning_leave_event != null and returning_leave_event.get_growth_visible(),
		"hub_generation_count": generation_count_before,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("hub_sepulcher_grave_resolution_smoke: %s" % ("PASS" if failures.is_empty() else "FAIL"))
	_finish(failures)


func _contains_collision_owner(node: Node) -> bool:
	if node is CollisionObject2D:
		return true
	for child in node.get_children():
		if _contains_collision_owner(child):
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(failures: Array[String]) -> void:
	quit(0 if failures.is_empty() else 1)
