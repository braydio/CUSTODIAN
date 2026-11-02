extends SceneTree

const SITE := preload("res://game/world/events/abandoned_station/abandoned_station_site.gd")
const MEMORY := preload("res://game/systems/core/state/world_event_memory.gd")
const ENVIRONMENT := preload("res://game/world/environment/world_environment_director.gd")
const LIGHTING := preload("res://game/world/lighting/world_lighting_director.gd")
const SERVICE_POSITIONS := [Vector2.ZERO, Vector2(48.0, 0.0), Vector2(96.0, 0.0)]
const TICKS_PER_SECOND := 60
const WINDOW_TICKS := 90 * TICKS_PER_SECOND

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	_expect(game_state != null, "GameState autoload must provide the fixed simulation tick")
	if game_state == null:
		_finish()
		return
	var original_tick := int(game_state.get("tick"))

	_test_fixed_duration_and_restore(game_state)
	_test_service_orders_preserve_station_until_s3(game_state)
	_test_deadline_and_completion_are_disjoint(game_state)
	await _test_pause_and_reload_preserve_simulation_time(game_state)
	_test_legacy_completion_is_not_an_s3_decision()
	await _test_escalation_does_not_mutate_global_environment(game_state)

	game_state.set("tick", original_tick)
	_finish()


func _test_fixed_duration_and_restore(game_state: Node) -> void:
	var memory := MEMORY.new()
	var site := _make_site(&"stability_timer", memory)
	game_state.set("tick", 120)
	site.service_point(1)
	var payload: Dictionary = memory.get_payload(&"stability_timer")
	_expect(int(payload.get("stability_started_tick", -1)) == 120,
		"first service must persist the authoritative fixed tick without wall-clock time")
	_expect(String(payload.get("stability_phase", "")) == "active",
		"first service must enter the active stability phase")

	game_state.set("tick", 300)
	site.service_point(1)
	payload = memory.get_payload(&"stability_timer")
	_expect(int(payload.get("stability_started_tick", -1)) == 120,
		"duplicate service must not reset the 90-second deadline")
	_expect(site.has_method("advance_to_simulation_tick"),
		"site must expose deterministic fixed-tick advancement for runtime and validation")
	if site.has_method("advance_to_simulation_tick"):
		site.call("advance_to_simulation_tick", 120 + WINDOW_TICKS - 1)
		_expect(_phase(site) == "active",
			"timer must remain active one fixed tick before 90 simulation seconds")
		site.call("advance_to_simulation_tick", 120 + WINDOW_TICKS)
		_expect(_phase(site) == "expired",
			"timer must expire at exactly 90 simulation seconds")

	var restored := _make_site(&"stability_timer", memory)
	_expect(_phase(restored) == "expired",
		"expired phase must restore from the in-run event payload")
	_expect(not memory.is_completed(&"stability_timer"),
		"local stability expiry must not complete the campaign event")
	_expect(_has_site_local_cue(restored),
		"stability escalation must remain a local station presentation cue")

	_free_site(restored)
	_free_site(site)
	memory.free()


func _test_service_orders_preserve_station_until_s3(game_state: Node) -> void:
	var orders := [[0, 1, 2], [2, 0, 1], [1, 2, 0]]
	for order_index in range(orders.size()):
		var event_name := StringName("station_order_%d" % order_index)
		var memory := MEMORY.new()
		var site := _make_site(event_name, memory)
		game_state.set("tick", 900)
		for service_index in orders[order_index]:
			site.service_point(int(service_index))
		var payload: Dictionary = memory.get_payload(event_name)
		_expect(payload.get("services", []) == [true, true, true],
			"any service order must preserve the same completed subsystem set")
		_expect(String(payload.get("stability_phase", "")) == "hazard_revealed",
			"three services before expiry must reveal the unsafe outward link")
		_expect(not memory.is_completed(event_name),
			"S2 must leave final containment or shutdown resolution to S3")
		_expect(_phase(site) == "hazard_revealed",
			"runtime phase must distinguish service completion from event resolution")

		var restored := _make_site(event_name, memory)
		_expect(_phase(restored) == "hazard_revealed",
			"hazard reveal must restore without restarting the timer or resolving the event")
		_expect(not memory.is_completed(event_name),
			"restoring S2 success must not mark the S1 event complete")
		_free_site(restored)
		_free_site(site)
		memory.free()


func _test_deadline_and_completion_are_disjoint(game_state: Node) -> void:
	var memory := MEMORY.new()
	var site := _make_site(&"stability_deadline", memory)
	game_state.set("tick", 2400)
	site.service_point(0)
	site.service_point(1)
	if site.has_method("advance_to_simulation_tick"):
		site.call("advance_to_simulation_tick", 2400 + WINDOW_TICKS)
	game_state.set("tick", 2400 + WINDOW_TICKS)
	site.service_point(2)
	var payload: Dictionary = memory.get_payload(&"stability_deadline")
	_expect(String(payload.get("stability_phase", "")) == "expired",
		"a service at the deadline must lose to expiration deterministically")
	_expect(payload.get("services", []) == [true, true, false],
		"service input at the deadline must not complete a third subsystem")
	_expect(not memory.is_completed(&"stability_deadline"),
		"expired and successful event resolution must remain disjoint")
	_free_site(site)
	memory.free()


func _test_pause_and_reload_preserve_simulation_time(game_state: Node) -> void:
	var memory := MEMORY.new()
	var was_paused := bool(game_state.get("paused"))
	game_state.set("tick", 6000)
	game_state.set("paused", true)
	var site := _make_site(&"stability_pause", memory)
	site.service_point(0)
	await process_frame
	_expect(int(game_state.get("tick")) == 6000,
		"paused GameState must not advance the local stability clock")
	var restored := _make_site(&"stability_pause", memory)
	_expect(_phase(restored) == "active" and int(restored.get_stability_started_tick()) == 6000,
		"restoring a paused event must preserve its phase and original start tick")
	_expect(int(restored.get_remaining_stability_ticks()) == WINDOW_TICKS,
		"paused restore must not consume any stability time")
	game_state.set("tick", 6000 + 30 * TICKS_PER_SECOND)
	restored.advance_to_simulation_tick(int(game_state.get("tick")))
	_expect(int(restored.get_remaining_stability_ticks()) == 60 * TICKS_PER_SECOND,
		"resumed simulation must consume only elapsed fixed ticks")
	game_state.set("paused", was_paused)
	_free_site(restored)
	_free_site(site)
	memory.free()


func _test_legacy_completion_is_not_an_s3_decision() -> void:
	var memory := MEMORY.new()
	memory.mark_completed(&"station_legacy_complete", {"services": [true, true, true]})
	var site := _make_site(&"station_legacy_complete", memory)
	var payload: Dictionary = memory.get_payload(&"station_legacy_complete")
	_expect(_phase(site) != "hazard_revealed",
		"legacy S1 completion must not be reinterpreted as the S2 hazard or S3 outcome")
	_expect(not payload.has("containment_decision") and not payload.has("resolution"),
		"legacy completed payload must not fabricate a containment or shutdown decision")
	_expect(memory.is_completed(&"station_legacy_complete"),
		"S2 must not rewrite the legacy event completion record")
	_free_site(site)
	memory.free()


func _test_escalation_does_not_mutate_global_environment(game_state: Node) -> void:
	var lighting := LIGHTING.new()
	lighting.name = "WorldLightingDirector"
	root.add_child(lighting)
	var environment := ENVIRONMENT.new()
	environment.name = "WorldEnvironmentDirector"
	root.add_child(environment)
	await process_frame
	environment.set("clock_enabled", false)
	environment.call("debug_force_weather", "overcast")
	var environment_before: Dictionary = environment.call("debug_get_state")
	var ambient_before: Color = lighting.get("resolved_ambient_color")
	var directional_before: Color = lighting.get("resolved_directional_color")
	var energy_before: float = lighting.get("resolved_directional_energy")
	var memory := MEMORY.new()
	var site := _make_site(&"station_environment_invariance", memory)
	game_state.set("tick", 4800)
	site.service_point(0)
	site.service_point(1)
	site.service_point(2)
	_expect(_phase(site) == "hazard_revealed" and _has_site_local_cue(site),
		"hazard escalation must be visible through a station-local cue")
	_expect(environment.call("debug_get_state") == environment_before,
		"station escalation must not change global weather state")
	_expect(lighting.get("resolved_ambient_color") == ambient_before
		and lighting.get("resolved_directional_color") == directional_before
		and is_equal_approx(float(lighting.get("resolved_directional_energy")), energy_before),
		"station escalation must not change global lighting state")
	_free_site(site)
	memory.free()
	environment.free()
	lighting.free()


func _make_site(event_id: StringName, memory: Node) -> Node:
	var site := SITE.new()
	root.add_child(site)
	site.configure(event_id, SERVICE_POSITIONS, memory)
	return site


func _free_site(site: Node) -> void:
	if is_instance_valid(site):
		site.free()


func _has_site_local_cue(site: Node) -> bool:
	var cue := site.get_node_or_null("LocalStabilityCue") as Polygon2D
	return cue != null and cue.get_parent() == site and cue.color.a > 0.0


func _phase(site: Node) -> String:
	return String(site.call("get_stability_phase")) if site.has_method("get_stability_phase") else ""


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: abandoned station stability fixed-tick scenarios=6")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
