extends SceneTree

const DOMAIN := "SYNTHETIC_DOMAIN"
const GROUP := "NAMED_PATROL_01"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_uninstantiated_group_progress()
	_check_deterministic_registration_order()
	_check_pause_and_invalid_operations()
	_check_snapshot_continuation_and_legacy_v4()
	finish()


func _check_uninstantiated_group_progress() -> void:
	var active_actor := Node2D.new()
	active_actor.name = "PhysicalActor_A"
	active_actor.add_to_group("f14_abstract_activity_physical_actor")
	active_actor.set_meta("location_id", "A")
	root.add_child(active_actor)
	var state := _new_single_group_state()
	var kernel := SimulationKernel.new(state)
	var before := state.abstract_activity.get_group(DOMAIN, GROUP)
	_check(state.abstract_activity.groups.size() == 1, "proof must begin with exactly one abstract group")
	_check(_physical_actor_count_at("B") == 0, "synthetic location B unexpectedly has a physical Node2D")
	for index in 59: kernel.step_once()
	_check(state.abstract_activity.get_group(DOMAIN, GROUP).route_progress_index == 0, "group advanced before the 60 fixed-tick threshold")
	kernel.step_once()
	var after := state.abstract_activity.get_group(DOMAIN, GROUP)
	_check(after.group_id == before.group_id and after.domain_id == before.domain_id, "abstract group identity changed during progression")
	_check(after.location_id == "A" and after.route_progress_index == 1, "uninstantiated B patrol did not advance its route state")
	_check(after.last_advanced_fixed_tick == 60, "abstract group did not record its authoritative fixed tick")
	_check(_physical_actor_count_at("B") == 0, "abstract progression instantiated a physical Node2D in B")
	_check(state.abstract_activity.causal_events.size() == 1, "patrol progression did not record one causal event")
	if not state.abstract_activity.causal_events.is_empty():
		var event: Dictionary = state.abstract_activity.causal_events[0]
		_check(event.cause == "bounded_offscreen_patrol_progression", "causal event lacks the approved reason")
		_check(event.fixed_tick == 60 and event.world_tick == 1, "causal event has the wrong authoritative tick")
	_check(state.abstract_activity.advance_to_fixed_tick(60, 1), "idempotent same-tick activity call was rejected")
	_check(state.abstract_activity.causal_events.size() == 1, "same-tick activity call duplicated a causal event")
	active_actor.queue_free()
	await process_frame


func _check_deterministic_registration_order() -> void:
	var first := _new_two_group_state(false)
	var second := _new_two_group_state(true)
	var first_kernel := SimulationKernel.new(first)
	var second_kernel := SimulationKernel.new(second)
	for index in 120:
		first_kernel.step_once()
		second_kernel.step_once()
	_check(first.canonical_fingerprint() == second.canonical_fingerprint(), "map insertion order changed canonical state")
	_check(SimulationCanonicalJson.encode(first.abstract_activity.causal_events) == SimulationCanonicalJson.encode(second.abstract_activity.causal_events), "map insertion order changed causal event order")
	_check(first.abstract_activity.causal_events.size() == 4, "two patrols did not produce bounded deterministic progress events")


func _check_pause_and_invalid_operations() -> void:
	var state := _new_single_group_state()
	var kernel := SimulationKernel.new(state)
	var clock := SimulationClock.new()
	clock.paused = true
	var fingerprint := state.canonical_fingerprint()
	for index in 60: clock.advance(SimulationClock.FIXED_DT, Callable(kernel, "step_once"))
	_check(clock.fixed_tick == 0 and state.fixed_tick == 0, "paused clock advanced authoritative time")
	_check(state.canonical_fingerprint() == fingerprint, "paused clock mutated abstract activity")
	_check(not state.abstract_activity.register_group(DOMAIN, GROUP, "B", "PATROL_ROUTE", ["B", "A"]), "duplicate group ID was accepted")
	_check(not state.abstract_activity.register_group(DOMAIN, "UNKNOWN_LOCATION_GROUP", "MISSING", "PATROL_ROUTE", ["MISSING", "A"]), "unknown location reference was accepted")
	var before := state.canonical_fingerprint()
	_check(not state.abstract_activity.advance_to_fixed_tick(-1, 0), "negative elapsed fixed tick was accepted")
	_check(state.canonical_fingerprint() == before, "invalid activity operation partially mutated state")
	_check(state.abstract_activity.advance_to_fixed_tick(60, 1), "valid fixed tick was rejected")
	before = state.canonical_fingerprint()
	_check(not state.abstract_activity.advance_to_fixed_tick(59, 1), "backwards fixed tick was accepted")
	_check(state.canonical_fingerprint() == before, "backwards tick partially mutated abstract state")


func _check_snapshot_continuation_and_legacy_v4() -> void:
	var uninterrupted := _new_single_group_state()
	var uninterrupted_kernel := SimulationKernel.new(uninterrupted)
	for index in 60: uninterrupted_kernel.step_once()
	var snapshot := SimulationSnapshot.capture(uninterrupted).to_dict()
	var restored := SimulationSnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
	_check(restored != null, "abstract activity snapshot failed to restore")
	if restored != null:
		_check(restored.abstract_activity.groups.size() == 1, "snapshot restore lost or duplicated the abstract group")
		var continued := SimulationKernel.new(restored)
		for index in 120:
			uninterrupted_kernel.step_once()
			continued.step_once()
		_check(uninterrupted.canonical_fingerprint() == restored.canonical_fingerprint(), "snapshot continuation diverged from uninterrupted state")
		_check(SimulationCanonicalJson.encode(uninterrupted.abstract_activity.causal_events) == SimulationCanonicalJson.encode(restored.abstract_activity.causal_events), "snapshot continuation diverged in causal events")
	var legacy := SimulationSnapshot.capture(WorldSimulationState.new(701)).to_dict()
	legacy.schema_version = 4
	legacy.state.schema_version = 4
	legacy.state.erase("abstract_activity")
	var migrated := SimulationSnapshot.restore(legacy)
	_check(migrated != null and migrated.abstract_activity.groups.is_empty(), "legacy v4 snapshot did not load with a safe empty activity state")
	_check(migrated != null and SimulationSnapshot.capture(migrated).to_dict().schema_version == 5, "legacy v4 snapshot did not migrate to schema v5")
	var invalid := snapshot.duplicate(true)
	var activity: Dictionary = invalid.state.abstract_activity
	var groups: Array = activity.groups
	groups.append(groups[0].duplicate(true))
	activity.groups = groups
	invalid.fingerprint = SimulationCanonicalJson.sha256(invalid.state)
	_check(SimulationSnapshot.restore(invalid) == null, "duplicate serialized group identity did not fail closed")
	invalid = snapshot.duplicate(true)
	activity = invalid.state.abstract_activity
	groups = activity.groups
	groups[0].location_id = "MISSING"
	activity.groups = groups
	invalid.fingerprint = SimulationCanonicalJson.sha256(invalid.state)
	_check(SimulationSnapshot.restore(invalid) == null, "invalid serialized location reference did not fail closed")


func _new_single_group_state() -> WorldSimulationState:
	var state := WorldSimulationState.new(700)
	_check(state.abstract_activity.register_location(DOMAIN, "B"), "could not register synthetic B location")
	_check(state.abstract_activity.register_location(DOMAIN, "A"), "could not register synthetic A location")
	_check(state.abstract_activity.register_group(DOMAIN, GROUP, "B", "PATROL_ROUTE", ["B", "A"]), "could not register named abstract patrol")
	return state


func _new_two_group_state(reverse_registration: bool) -> WorldSimulationState:
	var state := WorldSimulationState.new(710)
	var domains := ["DOMAIN_ALPHA", "DOMAIN_OMEGA"]
	var locations := ["B", "A"]
	if reverse_registration:
		domains.reverse()
		locations.reverse()
	for domain_id in domains:
		for location_id in locations:
			_check(state.abstract_activity.register_location(domain_id, location_id), "determinism fixture location registration failed")
	var group_records := [
		{"domain_id": "DOMAIN_ALPHA", "group_id": "PATROL_01"},
		{"domain_id": "DOMAIN_OMEGA", "group_id": "PATROL_02"},
	]
	if reverse_registration:
		group_records.reverse()
	for record in group_records:
		_check(state.abstract_activity.register_group(String(record.domain_id), String(record.group_id), "B", "PATROL_ROUTE", ["B", "A"]), "determinism fixture group registration failed")
	return state


func _physical_actor_count_at(location_id: String) -> int:
	var count := 0
	for actor in get_nodes_in_group("f14_abstract_activity_physical_actor"):
		if actor is Node2D and String(actor.get_meta("location_id", "")) == location_id:
			count += 1
	return count


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func finish() -> void:
	if failures.is_empty():
		print("WORLD_SIMULATION_ABSTRACT_ACTIVITY_SMOKE: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
