extends SceneTree

const HUB_HOST_SCENE := preload("res://scenes/hub_runtime_host.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const HUB_STATE_SCRIPT := preload("res://game/state/persistent/hub_state.gd")
const PROCESSION_SCRIPT := preload(
	"res://game/world/hub/events/road_procession/road_procession_sequence.gd"
)
const LAYOUT := preload("res://game/world/hub/first_set/hub_first_set_layout.gd")
const EVENT_ID: StringName = &"hub_road_procession_v1"
const WALK_FRAME_LIMIT := 2400


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var legacy_snapshot := (HUB_STATE_SCRIPT.new(7) as HubState).snapshot()
	legacy_snapshot.erase("authored_event_records")
	var legacy_state := HUB_STATE_SCRIPT.restore(legacy_snapshot) as HubState
	_expect(
		legacy_state != null and legacy_state.authored_event_records.is_empty(),
		"legacy HubState snapshots did not restore with empty event records",
		failures
	)
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
	_expect(world != null and map != null, "production HubRuntimeHost did not load its H1 map", failures)
	_expect(hub_state != null, "production HubRuntimeHost did not own HubState", failures)
	if world == null or map == null or hub_state == null:
		_finish(failures)
		return

	var route_result := map.complete_route_activation({"major_context": &"hub"})
	_expect(route_result, "Hub first-set navigation did not activate", failures)
	var route := map.authored_navigation.compute_path(
		LAYOUT.MARKERS["Spawn_SouthReach"], LAYOUT.MARKERS["ForumSouth"]
	)
	_expect(not route.is_empty(), "production Hub navigation cannot route Spawn_SouthReach to ForumSouth", failures)
	var operator := OPERATOR_SCENE.instantiate() as CharacterBody2D
	operator.name = "Operator"
	world.add_child(operator)
	_expect(map.enter_from_main_at_spawn(operator, &"Spawn_SouthReach"), "real Operator could not enter the Hub at South Reach", failures)
	await process_frame
	var procession := map.get_node_or_null("RoadProcessionSequence") as RoadProcessionSequence
	_expect(procession != null, "production Hub map did not install its local procession controller", failures)
	_expect(operator.is_in_group("player"), "real Operator is not eligible for physical event triggers", failures)
	_expect(map.get_node_or_null("AdjudicationDaisInteraction") != null, "Forum Dais interaction was displaced", failures)
	_expect(world.get_node_or_null("CrownTransferIngress") != null, "Crown Transfer ingress was displaced", failures)
	if procession == null:
		_finish(failures)
		return
	_expect(operator.global_position == LAYOUT.MARKERS["Spawn_SouthReach"], "real Operator missed the Hub South Reach spawn", failures)
	var start_position := operator.global_position

	Input.action_press(&"move_up")
	var reached_first := await _walk_until(operator, hub_state, 1, Vector2(0.0, -1500.0))
	Input.action_release(&"move_up")
	_expect(reached_first, "real Operator did not reach the south procession beat by walking", failures)
	_expect(operator.global_position.distance_to(start_position) > 1000.0, "Operator was teleported instead of traversing the Hub route", failures)
	var partial_record := hub_state.get_authored_event_record(EVENT_ID)
	_expect(int(partial_record.get("completed_beats", 0)) == 1, "south beat was not recorded once", failures)
	_expect(str(partial_record.get("last_beat", "")) == "south", "first beat did not record south as its identity", failures)
	var first_beat_visuals: Dictionary = procession.get_sequence_snapshot()
	var lamp_energies: Array = first_beat_visuals.get("lamp_energies", [])
	_expect(
		lamp_energies.size() == 3 and float(lamp_energies[0]) > 0.0 \
		and is_zero_approx(float(lamp_energies[1])) and is_zero_approx(float(lamp_energies[2])),
		"south beat did not activate only its local light presentation",
		failures
	)
	var partial_snapshot := hub_state.snapshot()
	var mutated_read := hub_state.get_authored_event_record(EVENT_ID)
	mutated_read["completed_beats"] = 0
	_expect(int(hub_state.get_authored_event_record(EVENT_ID).get("completed_beats", 0)) == 1, "event-record reads are not defensive copies", failures)
	var mutated_snapshot := hub_state.snapshot()
	(mutated_snapshot["authored_event_records"] as Dictionary)[String(EVENT_ID)]["completed_beats"] = 0
	_expect(int(hub_state.get_authored_event_record(EVENT_ID).get("completed_beats", 0)) == 1, "HubState snapshot shares nested event-record data", failures)

	# Simulate returning to the Hub from a serialized mid-event state.
	procession.free()
	var resumed_state := HUB_STATE_SCRIPT.restore(partial_snapshot) as HubState
	authority.set("hub_state", resumed_state)
	var resumed_procession := _add_procession(map, resumed_state)
	Input.action_press(&"move_up")
	var reached_forum := await _walk_until(operator, resumed_state, 3, Vector2(0.0, -2500.0))
	Input.action_release(&"move_up")
	_expect(reached_forum, "real Operator could not finish the northbound procession route to ForumSouth", failures)
	_expect(operator.global_position.y <= LAYOUT.MARKERS["ForumSouth"].y, "real Operator did not enter ForumSouth after the sequence", failures)
	var completed_record := resumed_state.get_authored_event_record(EVENT_ID)
	_expect(bool(completed_record.get("sequence_complete", false)), "north beat did not complete the event", failures)
	_expect(str(completed_record.get("last_beat", "")) == "north", "final beat order was not north", failures)
	var resumed_snapshot := resumed_procession.get_sequence_snapshot()
	_expect(resumed_snapshot.get("activation_order", []) == [&"middle", &"north"], "restored event did not resume at the next ordered beats", failures)
	_expect(int(resumed_snapshot.get("bell_activation_count", 0)) == 2, "restored event replayed its completed south bell or missed later bells", failures)
	for frame_index in 90:
		await physics_frame
	_expect(_all_lamps_dark(resumed_procession), "procession lamps did not fade after the north beat", failures)
	_expect(not _any_bell_playing(resumed_procession), "bells did not return to silence after the north beat", failures)

	var completed_snapshot := resumed_state.snapshot()
	var loaded_state := HUB_STATE_SCRIPT.restore(completed_snapshot) as HubState
	authority.set("hub_state", loaded_state)
	resumed_procession.free()
	var loaded_procession := _add_procession(map, loaded_state)
	await process_frame
	for beat_index in 3:
		loaded_procession.call("_on_body_entered", operator, beat_index)
	var loaded_result: Dictionary = loaded_procession.get_sequence_snapshot()
	_expect(int(loaded_result.get("completed_beats", 0)) == 3, "completed HubState snapshot lost its event stage", failures)
	_expect(int(loaded_result.get("beat_activation_count", 0)) == 0, "completed procession replayed a bell/lamp on return", failures)
	_expect(int(loaded_result.get("bell_activation_count", 0)) == 0, "completed procession emitted a bell after snapshot restore", failures)
	_expect(_all_lamps_dark(loaded_procession), "temporary procession lamps did not return to silence", failures)
	_expect(not _any_bell_playing(loaded_procession), "procession bells did not decay to silence", failures)
	if bootstrap != null:
		_expect(int(bootstrap.get("generation_count")) == generation_count_before, "Hub procession touched Contract prewarm", failures)
	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "hub_road_empty_procession",
		"passed": failures.is_empty(),
		"failure_count": failures.size(),
		"failures": failures,
		"operator_start": start_position,
		"operator_end": operator.global_position,
		"partial_record": partial_record,
		"completed_record": completed_record,
		"restored_activation_order": resumed_snapshot.get("activation_order", []),
		"hub_generation_count": generation_count_before,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("hub_road_empty_procession_smoke: %s" % ("PASS" if failures.is_empty() else "FAIL"))
	_finish(failures)


func _add_procession(map: HubFirstSetMap, state: HubState) -> RoadProcessionSequence:
	var procession := PROCESSION_SCRIPT.new() as RoadProcessionSequence
	procession.name = "RoadProcessionSequence"
	procession.configure(state)
	map.add_child(procession)
	return procession


func _walk_until(
	operator: CharacterBody2D,
	state: HubState,
	expected_beats: int,
	target: Vector2
) -> bool:
	for _frame_index in WALK_FRAME_LIMIT:
		await physics_frame
		if int(state.get_authored_event_record(EVENT_ID).get("completed_beats", 0)) >= expected_beats \
		and operator.global_position.y <= target.y:
			return true
	return false


func _all_lamps_dark(procession: RoadProcessionSequence) -> bool:
	var values: Array = procession.get_sequence_snapshot().get("lamp_intensities", [])
	for value: Variant in values:
		if float(value) > 0.01:
			return false
	return values.size() == 3


func _any_bell_playing(procession: RoadProcessionSequence) -> bool:
	for child in procession.get_children():
		if child is AudioStreamPlayer2D and (child as AudioStreamPlayer2D).playing:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(failures: Array[String]) -> void:
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	quit(0 if failures.is_empty() else 1)
