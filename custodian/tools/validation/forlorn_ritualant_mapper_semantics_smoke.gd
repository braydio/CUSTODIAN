extends SceneTree

const LEVEL_SCENE := preload("res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn")
const SITE_SCENE := preload("res://game/world/events/ash_bell/forlorn_ritualant_site.tscn")
const MAPPER_SCENE := preload("res://scenes/debug/forlorn_ritualant_underground_mapper.tscn")

class FakeActor:
	extends CharacterBody2D

var _errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await _validate_runtime_geometry()
	await _validate_dialogue_hazard_suppression()
	await _validate_deferred_hostility()
	if _errors.is_empty():
		print("[ForlornRitualantMapperSemanticsSmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error("[ForlornRitualantMapperSemanticsSmoke] %s" % error)
	quit(1)


func _validate_runtime_geometry() -> void:
	var level := LEVEL_SCENE.instantiate() as ForlornRitualantUnderground
	root.add_child(level)
	await process_frame
	var records := level.get_authoring_debug_geometry()
	var by_id := {}
	var groups := {}
	for record: Dictionary in records:
		by_id[str(record.get("id", ""))] = record
		groups[str(record.get("group", ""))] = true
	for required_group in ["boundary", "encounter", "hazard", "interaction", "camera", "transition", "art", "traversal"]:
		_check(groups.has(required_group), "semantic mapper lacks %s group" % required_group)
	var thread_rect := (by_id.get("encounter.thread_hazard", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var ritualant_position := (by_id.get("encounter.ritualant", {}) as Dictionary).get("point", Vector2.ZERO) as Vector2
	_check(thread_rect.has_point(ritualant_position), "fixture changed: Ritualant no longer overlaps thread hazard")
	var chamber := (by_id.get("encounter.ritualant_chamber", {}) as Dictionary).get("rect", Rect2()) as Rect2
	_check(chamber.size == Vector2(1120.0, 864.0), "chapel dimensions changed before mapper-backed re-authoring")
	var combat := (by_id.get("encounter.combat_bounds", {}) as Dictionary).get("rect", Rect2()) as Rect2
	_check(combat.size == Vector2(1000.0, 700.0), "combat bounds changed during mapper-only pass")
	var camera_count := 0
	for record: Dictionary in records:
		if str(record.get("group", "")) == "camera":
			camera_count += 1
	_check(camera_count == 5, "mapper did not expose all five runtime camera zones")
	var chapel_art := by_id.get("art.chapel_outer_blend", {}) as Dictionary
	_check(chapel_art.get("texture_size", Vector2.ZERO) == Vector2(1280.0, 1024.0), "chapel art bounds did not derive from texture size")
	var parallax := by_id.get("art.parallax.far_void", {}) as Dictionary
	_check(bool(parallax.get("parallax", false)), "parallax art was not distinguished from gameplay-aligned art")

	var mapper := MAPPER_SCENE.instantiate()
	root.add_child(mapper)
	await process_frame
	var matches := mapper.call("get_debug_geometry_under_point", ritualant_position) as Array
	var match_ids: Array[String] = []
	for record: Dictionary in matches:
		match_ids.append(str(record.get("id", "")))
	_check(match_ids.has("encounter.thread_hazard"), "mouse inspection missed thread hazard at Ritualant")
	_check(match_ids.has("interaction.ritualant"), "mouse inspection missed Ritualant interaction")
	mapper.queue_free()
	level.queue_free()
	await process_frame


func _validate_dialogue_hazard_suppression() -> void:
	var site := SITE_SCENE.instantiate() as ForlornRitualantSite
	root.add_child(site)
	var actor := FakeActor.new()
	actor.add_to_group("player")
	root.add_child(actor)
	await process_frame
	var hazard := site.get_node("Props/WhiteThreadHazard") as WhiteThreadHazard
	actor.global_position = hazard.global_position
	_check(site.dialogue_presenter.start(&"first_interaction", actor), "dialogue fixture did not start")
	var tension_before := site.event_state.thread_tension
	hazard._on_body_entered(actor)
	hazard._physics_process(1.6)
	_check(site.event_state.thread_tension == tension_before, "white thread mutated while dialogue owned actor")
	_check(not site.event_state.ritualant_hostile, "Ritualant became hostile during locking dialogue")
	site.dialogue_presenter.force_close()
	hazard._physics_process(0.8)
	_check(site.event_state.thread_tension > tension_before, "white thread did not resume after dialogue")
	site.queue_free()
	actor.queue_free()
	await process_frame


func _validate_deferred_hostility() -> void:
	var site := SITE_SCENE.instantiate() as ForlornRitualantSite
	root.add_child(site)
	var actor := FakeActor.new()
	actor.add_to_group("player")
	root.add_child(actor)
	await process_frame
	_check(site.dialogue_presenter.start(&"first_interaction", actor), "deferred-hostility dialogue did not start")
	site.event_state.set_silence_pressure(90, &"silence_pressure_90")
	_check(not site.event_state.ritualant_hostile, "event resource mutated hostility during dialogue")
	_check(site.get("_deferred_hostility_reason") == &"silence_pressure_90", "site did not retain deferred hostility reason")
	site.dialogue_presenter.force_close()
	site._process(0.0)
	_check(site.event_state.ritualant_hostile, "deferred hostility did not resume after dialogue")
	_check(site.debug_get_last_hostility_reason() == &"silence_pressure_90", "hostility diagnostic lost exact cause")
	site.queue_free()
	actor.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
