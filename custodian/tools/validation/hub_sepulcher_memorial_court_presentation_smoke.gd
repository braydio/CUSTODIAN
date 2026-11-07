extends SceneTree

const HUB_HOST_SCENE := preload("res://scenes/hub_runtime_host.tscn")
const MAP_SCRIPT := preload("res://game/world/hub/first_set/hub_first_set_map.gd")
const PRESENTATION_SCRIPT := preload("res://game/world/hub/first_set/sepulcher_memorial_court_presentation.gd")
const EVENT_SCRIPT := preload("res://game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd")
const EXPECTED_FLOOR := "res://content/tiles/hub/sepulcher_gardens/hub_first_set_sepulcher_floor_materials_v2_memorial_court_worn_512.png"
const EXPECTED_RING := "res://content/sprites/environment/props/hub/sepulcher_gardens/hub_first_set_sepulcher_landmark_architecture_v2/runtime/overlay/hub_first_set_sepulcher_landmark_architecture_v2__overlay__landmark__memorial_court_index_ring__omni__1f__512.png"
const EXPECTED_WALL := "res://content/sprites/environment/props/hub/sepulcher_gardens/hub_first_set_sepulcher_landmark_architecture_v2/runtime/structure/hub_first_set_sepulcher_landmark_architecture_v2__structure__landmark__memorial_court_low_side_wall_module_preview__omni__1f__256x128.png"
const GRAVE_POSITION := Vector2(-1984.0, -3200.0)
const EXPECTED_INSPECTIONS: Array[Vector2] = [
	Vector2(-2304.0, -3200.0), Vector2(-1536.0, -3200.0), Vector2(-1536.0, -2688.0),
]
const EXPECTED_RESOLUTIONS: Array[Vector2] = [Vector2(-2076.0, -3088.0), Vector2(-1892.0, -3088.0)]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var host := HUB_HOST_SCENE.instantiate() as Node2D
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	await process_frame
	await process_frame
	var map := host.get_node_or_null("World/Level") as HubFirstSetMap
	if map == null:
		_fail("production Hub host did not load HubFirstSetMap", failures)
		_finish(failures)
		return
	var presentations := map.find_children("SepulcherMemorialCourtPresentation", "Node", true, false)
	_expect(presentations.size() == 1, "production Hub must contain exactly one court presentation", failures)
	var presentation := map.get_node_or_null("SepulcherMemorialCourtPresentation") as SepulcherMemorialCourtPresentation
	if presentation == null:
		_finish(failures)
		return
	_expect(presentation.get_script() == PRESENTATION_SCRIPT, "court node is not the visual-only presentation helper", failures)
	var sprites := presentation.get_presentation_sprites()
	_expect(sprites.size() == 3, "court must expose floor, ring and one native wall preview", failures)
	if sprites.size() == 3:
		_expect(sprites[0].texture.resource_path == EXPECTED_FLOOR, "floor is not bound to the verified Asset V2 texture", failures)
		_expect(sprites[1].texture.resource_path == EXPECTED_RING, "ring is not bound to the verified Asset V2 texture", failures)
		_expect(sprites[2].texture.resource_path == EXPECTED_WALL, "wall preview is not bound to the native-size module", failures)
		_expect(sprites[0].texture.get_size() == Vector2(512.0, 512.0), "floor target dimensions changed", failures)
		_expect(sprites[1].texture.get_size() == Vector2(512.0, 512.0), "ring target dimensions changed", failures)
		_expect(sprites[2].texture.get_size() == Vector2(256.0, 128.0), "wall module preview was resized", failures)
		_expect(sprites[1].position == GRAVE_POSITION, "ring moved away from the existing grave anchor", failures)
		_expect(sprites[2].position.y + sprites[2].texture.get_height() * 0.5 == -3456.0, "wall module no longer contacts the floor edge", failures)
	var ring := sprites[1].texture.get_image()
	_expect(ring != null and ring.detect_alpha(), "ring must retain true transparency", failures)
	if ring != null and ring.detect_alpha():
		_expect(ring.get_used_rect().size.x > 0, "ring alpha channel is empty", failures)

	var event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
	_expect(event != null, "production Hub grave event did not load", failures)
	if event != null:
		_expect(event.get("GRAVE_POSITION") == GRAVE_POSITION, "grave anchor changed", failures)
		_expect(event.get_inspection_positions() == EXPECTED_INSPECTIONS, "the three inspection positions changed", failures)
		var resolution_positions: Array[Vector2] = []
		for point in event.get_resolution_points():
			resolution_positions.append(point.global_position)
		_expect(resolution_positions == EXPECTED_RESOLUTIONS, "the two resolution positions changed", failures)
		var slab: Texture2D = event.get("MEMORIAL_SLAB_TEXTURE")
		_expect(slab != null and slab.resource_path.ends_with("memorial_slab__omni__1f__160x96.png"), "existing Memorial Slab texture changed", failures)
		_expect(event.z_index == 0, "grave/event presentation layering owner changed", failures)

	var walkable_before: Dictionary = map.blockout_grid.get_walkable_cells()
	var boundaries_before: Array = map.get_boundary_segments()
	var path_before: PackedVector2Array = map.authored_navigation.compute_path(Vector2(-1280.0, -3200.0), GRAVE_POSITION)
	presentation.visible = false
	await process_frame
	_expect(map.blockout_grid.get_walkable_cells() == walkable_before, "hiding the court changed navigation cells", failures)
	_expect(map.get_boundary_segments() == boundaries_before, "hiding the court changed collision boundaries", failures)
	_expect(map.authored_navigation.compute_path(Vector2(-1280.0, -3200.0), GRAVE_POSITION) == path_before, "hiding the court changed the P1 navigation path", failures)
	presentation.visible = true

	# Restore the event from a distinct persisted state and assert that its visual
	# sibling is not re-created by event transitions or reloads.
	var authority := host.get_node_or_null("HubCampaignAuthority")
	var hub_state := authority.get("hub_state") as HubState if authority != null else null
	if event != null and hub_state != null:
		var event_snapshot := hub_state.snapshot()
		var changed := hub_state.set_authored_event_record(EVENT_SCRIPT.EVENT_ID, {
			"schema": EVENT_SCRIPT.RECORD_SCHEMA,
			"completed_readings": 1,
			"last_reading_id": "record_a",
			"resolution": "",
		})
		_expect(changed, "could not stage a real grave event transition for duplicate guard", failures)
		event.queue_free()
		await process_frame
		map.call("_build_sepulcher_grave_evidence")
		await process_frame
		var reloaded_event := map.get_node_or_null("SepulcherGraveEvidence") as SepulcherGraveEvidence
		_expect(reloaded_event != null and reloaded_event.get_completed_readings() == 1, "grave event reload did not restore its state", failures)
		_expect(map.find_children("SepulcherMemorialCourtPresentation", "Node", true, false).size() == 1, "event reload duplicated the court presentation", failures)
		authority.set("hub_state", HubState.restore(event_snapshot))
	else:
		_fail("HubState or grave event was unavailable for reload check", failures)

	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "hub_sepulcher_memorial_court_presentation",
		"passed": failures.is_empty(),
		"failure_count": failures.size(),
		"failures": failures,
		"presentation_count": map.find_children("SepulcherMemorialCourtPresentation", "Node", true, false).size(),
		"inspection_positions": EXPECTED_INSPECTIONS,
		"resolution_positions": EXPECTED_RESOLUTIONS,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("hub_sepulcher_memorial_court_presentation_smoke: %s" % ("PASS" if failures.is_empty() else "FAIL"))
	_finish(failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		_fail(message, failures)


func _fail(message: String, failures: Array[String]) -> void:
	failures.append(message)
	push_error(message)


func _finish(failures: Array[String]) -> void:
	quit(0 if failures.is_empty() else 1)
