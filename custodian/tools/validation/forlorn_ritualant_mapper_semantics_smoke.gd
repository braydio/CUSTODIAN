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
	var thread_left := (by_id.get("encounter.thread_hazard_left", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var thread_right := (by_id.get("encounter.thread_hazard_right", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var ritualant_position := (by_id.get("encounter.ritualant", {}) as Dictionary).get("point", Vector2.ZERO) as Vector2
	_check(not thread_left.has_point(ritualant_position) and not thread_right.has_point(ritualant_position), "Ritualant point overlaps White Thread hazard")
	_check(thread_left == Rect2(-384.0, -1298.0, 288.0, 64.0), "left White Thread hazard drifted from visible segment")
	_check(thread_right == Rect2(96.0, -1298.0, 288.0, 64.0), "right White Thread hazard drifted from visible segment")
	var dialogue_gap := Rect2(-96.0, -1298.0, 192.0, 64.0)
	_check(not dialogue_gap.intersects(thread_left) and not dialogue_gap.intersects(thread_right), "central x=-96..96 dialogue approach gap is not hazard-free")
	var chamber := (by_id.get("encounter.ritualant_chamber", {}) as Dictionary).get("rect", Rect2()) as Rect2
	_check(chamber == Rect2(-640.0, -1600.0, 1280.0, 960.0), "chapel is not the mapper-backed 1280x960 authority")
	var combat := (by_id.get("encounter.combat_bounds", {}) as Dictionary).get("rect", Rect2()) as Rect2
	_check(combat == Rect2(-576.0, -1568.0, 1152.0, 800.0), "combat bounds are not the expanded authored arena")
	for anchor_id: String in ["interaction.anchor_west", "interaction.anchor_north", "interaction.anchor_east"]:
		var anchor_record := by_id.get(anchor_id, {}) as Dictionary
		var anchor_center := anchor_record.get("center", Vector2.ZERO) as Vector2
		_check(combat.has_point(anchor_center), "%s lies outside CombatBounds" % anchor_id)
	_validate_white_thread_art()
	var chapel_connector := level.CHAPEL_CONNECTOR as Rect2
	for probe: Vector2 in [chapel_connector.get_center(), Vector2(0.0, -704.0), Vector2(0.0, -768.0)]:
		_check(Geometry2D.is_point_in_polygon(probe, level.PLAYABLE_BOUNDARY_LOOP), "chapel playable polygon disconnected at %s" % probe)
	var landing_connector := (by_id.get("traversal.landing_connector", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var landing_bridge := (by_id.get("art.landing_connector_bridge", {}) as Dictionary).get("rect", Rect2()) as Rect2
	_check(landing_bridge.encloses(landing_connector), "LandingConnectorBridge art does not fully cover playable connector")
	var camera_count := 0
	for record: Dictionary in records:
		if str(record.get("group", "")) == "camera":
			camera_count += 1
	_check(camera_count == 5, "mapper did not expose all five runtime camera zones")
	var chapel_art := by_id.get("art.chapel_outer_blend", {}) as Dictionary
	_check(chapel_art.get("texture_size", Vector2.ZERO) == Vector2(1280.0, 1024.0), "chapel art bounds did not derive from texture size")
	var arena_art := by_id.get("art.ritualant_arena_expanded_base", {}) as Dictionary
	_check(arena_art.get("texture_size", Vector2.ZERO) == Vector2(2594.0, 1737.0), "expanded arena master is not mapper-visible at 2594x1737")
	var seal_art := by_id.get("art.lower_quarter_seal", {}) as Dictionary
	_check(seal_art.get("texture_size", Vector2.ZERO) == Vector2(1024.0, 512.0), "lower-quarter seal is not mapper-visible at native size")
	for side: String in ["left", "right"]:
		var warning := by_id.get("art.thread_warning_%s" % side, {}) as Dictionary
		var activation := by_id.get("art.thread_activation_%s" % side, {}) as Dictionary
		_check((warning.get("rect", Rect2()) as Rect2).size == Vector2(384.0, 96.0), "%s thread warning bounds drifted" % side)
		_check((activation.get("rect", Rect2()) as Rect2).size == Vector2(384.0, 128.0), "%s thread activation bounds drifted" % side)
	var parallax := by_id.get("art.parallax.far_void", {}) as Dictionary
	_check(bool(parallax.get("parallax", false)), "parallax art was not distinguished from gameplay-aligned art")

	var mapper := MAPPER_SCENE.instantiate()
	root.add_child(mapper)
	await process_frame
	var matches := mapper.call("get_debug_geometry_under_point", ritualant_position) as Array
	var match_ids: Array[String] = []
	for record: Dictionary in matches:
		match_ids.append(str(record.get("id", "")))
	_check(not match_ids.has("encounter.thread_hazard_left") and not match_ids.has("encounter.thread_hazard_right"), "mouse inspection reports a thread hazard at Ritualant")
	_check(match_ids.has("interaction.ritualant"), "mouse inspection missed Ritualant interaction")
	mapper.call("_apply_semantic_preset", ["boundary", "art", "traversal"])
	var preset_state := mapper.call("get_collision_mapper_state") as Dictionary
	var preset_groups := preset_state.get("semantic_groups", {}) as Dictionary
	_check(bool(preset_groups.get("boundary")) and bool(preset_groups.get("art")) and bool(preset_groups.get("traversal")), "F2 art-alignment preset omitted a required group")
	_check(not bool(preset_groups.get("hazard")) and not bool(preset_groups.get("camera")), "F2 art-alignment preset leaked unrelated groups")
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


func _validate_white_thread_art() -> void:
	var texture := load("res://content/tiles/encounters/ritualant_set/white_thread_hazard_runtime_02__768x64.png") as Texture2D
	var image := texture.get_image() if texture != null else null
	_check(image != null and image.get_size() == Vector2i(768, 64), "White Thread runtime art is not 768x64")
	if image == null:
		return
	_check(_opaque_bounds(image, 0, 288) == Rect2i(0, 0, 288, 64), "left visible White Thread bounds do not equal mechanical hazard bounds")
	_check(_opaque_bounds(image, 288, 480) == Rect2i(), "White Thread art crosses the central 192 px safe gap")
	_check(_opaque_bounds(image, 480, 768) == Rect2i(480, 0, 288, 64), "right visible White Thread bounds do not equal mechanical hazard bounds")


func _opaque_bounds(image: Image, start_x: int, end_x: int) -> Rect2i:
	var min_point := Vector2i(end_x, image.get_height())
	var max_point := Vector2i(-1, -1)
	for y in image.get_height():
		for x in range(start_x, end_x):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			min_point.x = mini(min_point.x, x)
			min_point.y = mini(min_point.y, y)
			max_point.x = maxi(max_point.x, x)
			max_point.y = maxi(max_point.y, y)
	if max_point.x < min_point.x:
		return Rect2i()
	return Rect2i(min_point, max_point - min_point + Vector2i.ONE)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
