extends SceneTree

const SITE := preload("res://game/world/events/abandoned_station/abandoned_station_site.gd")
const MEMORY := preload("res://game/systems/core/state/world_event_memory.gd")
const SERVICE_POSITIONS := [Vector2.ZERO, Vector2(32.0, 0.0), Vector2(64.0, 0.0)]
const TICKS_PER_SECOND := 60
const WINDOW_TICKS := 90 * TICKS_PER_SECOND
const MAINTAIN := "maintain_containment"
const SHUT_DOWN := "shut_down_coupling"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	_expect(game_state != null, "GameState autoload must provide the station's simulation tick")
	if game_state == null:
		_finish()
		return
	var original_tick := int(game_state.get("tick"))

	_test_maintain_containment_completes_once(game_state)
	_test_shutdown_records_distinct_outcome(game_state)
	_test_expiry_never_offers_resolution(game_state)
	_test_legacy_completion_does_not_fabricate_resolution()
	_test_run_reset_clears_run_scoped_completion()

	game_state.set("tick", original_tick)
	_finish()


func _test_maintain_containment_completes_once(game_state: Node) -> void:
	var memory := MEMORY.new()
	var site := _make_site(&"station_maintain", memory, game_state, 120)
	_expect(not site.can_offer_resolution(), "resolution must remain unavailable before all services are restored")
	_expect(site.get_resolution_points().size() == 2,
		"station must author exactly two resolution points")
	_expect(not _point(site, MAINTAIN).can_interact(null)
		and not _point(site, SHUT_DOWN).can_interact(null),
		"both resolution points must be disabled before the hazard is revealed")

	site.service_point(0)
	site.service_point(1)
	_expect(not site.can_offer_resolution(), "two services must not unlock the containment choice")
	site.service_point(2)
	_expect(site.can_offer_resolution(), "three timely services must unlock the containment choice")
	var hazard_readout := String(site.get_node("EvacuationBroadcast").text)
	_expect(hazard_readout.contains("EVIDENCE OUTCOME PENDING")
		and not hazard_readout.contains("EVIDENCE PRESERVED"),
		"hazard reveal must not imply a containment outcome before the player chooses")
	_expect(_point(site, MAINTAIN).can_interact(null)
		and _point(site, SHUT_DOWN).can_interact(null),
		"both authored decisions must be interactable after the hazard reveal")

	_point(site, MAINTAIN).interact(null)
	var payload: Dictionary = memory.get_payload(&"station_maintain")
	_expect(memory.is_completed(&"station_maintain"), "choosing containment must complete the run-scoped event")
	_expect(String(payload.get("containment_decision", "")) == MAINTAIN,
		"containment decision must be stored exactly once under its stable decision ID")
	_expect(String(payload.get("containment_readback", "")) == "EVIDENCE PRESERVED",
		"maintain-containment must return the preserved-evidence readback")
	_expect(String(site.get_stability_phase()) == "resolved",
		"the station must enter its resolved state without creating a campaign-wide outcome")
	_expect(not site.can_offer_resolution(), "a resolved station must stop offering choices")
	var resolved_payload := payload.duplicate(true)
	_point(site, SHUT_DOWN).interact(null)
	_expect(memory.get_payload(&"station_maintain") == resolved_payload,
		"a repeated or alternate interaction must not change the completed decision")

	var restored := _make_site(&"station_maintain", memory, game_state, 5000)
	_expect(String(restored.get_stability_phase()) == "resolved",
		"same-run restore must preserve the selected resolution")
	_expect(String(restored.get_resolution_readback()) == "EVIDENCE PRESERVED",
		"same-run restore must preserve the matching readback")
	_expect(not restored.can_offer_resolution(), "same-run restore must not allow a second resolution")
	_free_site(restored)
	_free_site(site)
	memory.free()


func _test_shutdown_records_distinct_outcome(game_state: Node) -> void:
	var memory := MEMORY.new()
	var site := _make_site(&"station_shutdown", memory, game_state, 900)
	_complete_services(site)
	_point(site, SHUT_DOWN).interact(null)
	var payload: Dictionary = memory.get_payload(&"station_shutdown")
	_expect(memory.is_completed(&"station_shutdown"), "shutting down coupling must complete the event")
	_expect(String(payload.get("containment_decision", "")) == SHUT_DOWN,
		"shutdown must persist its distinct stable decision ID")
	_expect(String(payload.get("containment_readback", "")) == "EVIDENCE INCOMPLETE",
		"shutdown must return the incomplete-evidence readback")
	_expect(String(site.get_resolution_readback()) == "EVIDENCE INCOMPLETE",
		"shutdown readback must be presented by the station controller")
	_free_site(site)
	memory.free()


func _test_expiry_never_offers_resolution(game_state: Node) -> void:
	var memory := MEMORY.new()
	var site := _make_site(&"station_expired", memory, game_state, 1800)
	site.service_point(0)
	site.service_point(1)
	site.advance_to_simulation_tick(1800 + WINDOW_TICKS)
	site.service_point(2)
	_expect(String(site.get_stability_phase()) == "expired", "the exact 90-second deadline must expire S2")
	_expect(not site.can_offer_resolution(), "expired stability must not offer either S3 choice")
	_expect(not _point(site, MAINTAIN).can_interact(null)
		and not _point(site, SHUT_DOWN).can_interact(null),
		"expired station must keep both decisions unavailable")
	_expect(not memory.is_completed(&"station_expired"),
		"local expiry must leave the campaign event and extraction available")
	_expect(not memory.get_payload(&"station_expired").has("containment_decision"),
		"expiry must not fabricate a containment decision")
	_free_site(site)
	memory.free()


func _test_legacy_completion_does_not_fabricate_resolution() -> void:
	var memory := MEMORY.new()
	memory.mark_completed(&"station_legacy_complete", {"services": [true, true, true]})
	var site := _make_site(&"station_legacy_complete", memory, null, 0)
	_expect(String(site.get_stability_phase()) != "hazard_revealed",
		"legacy completion must not be reinterpreted as a revealed S3 hazard")
	_expect(not site.can_offer_resolution(), "legacy completion must not offer an unrecorded decision")
	_expect(String(site.get_resolution_readback()).is_empty(),
		"legacy completion must not fabricate a decision readback")
	_expect(not memory.get_payload(&"station_legacy_complete").has("containment_decision"),
		"legacy payload must remain free of synthetic S3 decision data")
	_free_site(site)
	memory.free()


func _test_run_reset_clears_run_scoped_completion() -> void:
	var memory := MEMORY.new()
	memory.mark_completed(&"campaign_abandoned_station_site_v1:41:7", {
		"services": [true, true, true],
		"containment_decision": MAINTAIN,
		"containment_readback": "EVIDENCE PRESERVED",
	})
	memory.reset_run_events(42)
	_expect(not memory.is_completed(&"campaign_abandoned_station_site_v1:41:7"),
		"new run must clear the prior run's completion instead of creating campaign-wide outcome state")
	_expect(memory.get_payload(&"campaign_abandoned_station_site_v1:41:7").is_empty(),
		"new run must not retain the prior run's station decision payload")
	memory.free()


func _make_site(event_id: StringName, memory: Node, game_state: Node, tick: int) -> Node:
	if game_state != null:
		game_state.set("tick", tick)
	var site := SITE.new()
	root.add_child(site)
	site.configure(event_id, SERVICE_POSITIONS, memory)
	return site


func _complete_services(site: Node) -> void:
	site.service_point(0)
	site.service_point(1)
	site.service_point(2)


func _point(site: Node, decision_id: String) -> Node:
	for point in site.get_resolution_points():
		if String(point.decision_id) == decision_id:
			return point
	return null


func _free_site(site: Node) -> void:
	if is_instance_valid(site):
		site.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: abandoned station containment scenarios=5")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
