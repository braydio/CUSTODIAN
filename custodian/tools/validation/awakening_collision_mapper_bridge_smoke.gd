extends SceneTree

const Bridge := preload("res://tools/level_authoring/mapper/awakening_collision_mapper_bridge.gd")
const Layout := preload("res://game/world/awakening/awakening_layout.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_draft_contracts()
	var packed := load("res://scenes/awakening_first_return.tscn") as PackedScene
	_check(packed != null, "production Awakening scene loads")
	if packed != null:
		var scene := packed.instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		var colliders := Bridge.collect_colliders(scene)
		_check(not colliders.is_empty(), "instantiated collision contributors discovered")
		_check(not _has_world_bounds_rail(colliders), "WORLD_BOUNDS rails are not misreported as colliders")
		_check(_has_record_fragment(colliders, "Wall_"), "generated 32px occupancy wall colliders are enumerated")
		_check(_has_record_kind(colliders, "CollisionPolygon2D"), "instantiated void polygons are enumerated")
		_check(_has_record_fragment(colliders, "SouthReachCollapseBody"), "temporary South Reach blocker is enumerated")
		_check(_has_zone_record(colliders, "zone10_road_south_reach"), "Road/South Reach blockers carry their true zone identity")
		_check(_has_gate_pylon(colliders, "gate_pylon_west_body", Vector2(-256, -4768)), "west gate pylon collider center and footprint")
		_check(_has_gate_pylon(colliders, "gate_pylon_east_body", Vector2(256, -4768)), "east gate pylon collider center and footprint")
		_check(absf((256.0 - 120.0) - (-256.0 + 120.0) - 272.0) < 0.01, "gate pylons preserve 272px central gap")
		scene.queue_free()
	await process_frame
	var mapper_scene := load("res://scenes/debug/awakening_first_return_mapper.tscn") as PackedScene
	_check(mapper_scene != null, "Awakening mapper scene loads")
	if mapper_scene != null:
		var mapper := mapper_scene.instantiate()
		root.add_child(mapper)
		await process_frame
		await process_frame
		var target := mapper.get("_target_level") as Node
		_check(target != null and target.process_mode == Node.PROCESS_MODE_DISABLED and target.visible, "real preview art remains visible while gameplay processing is disabled")
		_check(mapper.mapper_mode == "COLLISION" and mapper.adapter.authoring_modes() == ["COLLISION"], "unsupported marker and region modes are not advertised")
		_check(mapper.registration_bounds.size() >= 3, "registered 04-05 composite exposes actual sprite registration bounds")
		var gate_index := -1
		for index in mapper.actual_colliders.size():
			if str(mapper.actual_colliders[index].id).contains("gate_pylon_west_body"):
				gate_index = index
				break
		if gate_index >= 0:
			mapper._selected_collision_index = gate_index
			mapper.call("_import_selected_collider_for_adjustment")
			var imported: Dictionary = mapper.proposal_metadata[-1]
			_check(imported.proposal_mode == "replace_existing" and imported.source_collision_id == mapper.selected_collision_id and imported.owner_id == mapper.actual_colliders[gate_index].owner_id, "existing collider adjustment preserves owner identity without additive duplication")
			_check(mapper.mapper_undo() and mapper.mapper_redo() and mapper.proposal_metadata[-1].source_collision_id == mapper.selected_collision_id, "source identity survives proposal undo/redo")
		else:
			_check(false, "actual gate collider can be selected for an adjustment proposal")
		var scene_path := ProjectSettings.globalize_path("res://scenes/awakening_first_return.tscn")
		var script_path := ProjectSettings.globalize_path("res://game/world/awakening/awakening_first_return.gd")
		var scene_hash_before := FileAccess.get_sha256(scene_path)
		var script_hash_before := FileAccess.get_sha256(script_path)
		var enter := InputEventKey.new()
		enter.keycode = KEY_ENTER
		mapper.call("_handle_key", enter)
		var apply := InputEventKey.new()
		apply.keycode = KEY_U
		mapper.call("_handle_key", apply)
		_check(scene_hash_before == FileAccess.get_sha256(scene_path) and script_hash_before == FileAccess.get_sha256(script_path), "Enter/U do not write runtime scene or script")
		mapper.queue_free()
	await process_frame
	if _failures.is_empty():
		print("awakening_collision_mapper_bridge_smoke: PASS")
		quit(0)
	else:
		for failure in _failures: push_error(failure)
		quit(1)


func _check_draft_contracts() -> void:
	var valid := Bridge.make_draft([[Vector2(-100, 0), Vector2(-80, 0)]], "artist_wall_01", "west wall correction", "decoration", "scene-sha", "layout-sha", 4.0)
	_check(Bridge.validate_draft(valid, "scene-sha", "layout-sha").is_empty(), "valid draft passes provenance and shape validation")
	var roundtrip_path := ProjectSettings.globalize_path("user://awakening_collision_mapper_bridge_smoke.json")
	_check(Bridge.atomic_write_readback(roundtrip_path, valid), "draft saves atomically and parses back identically")
	DirAccess.remove_absolute(roundtrip_path)
	var missing_owner := valid.duplicate(true)
	missing_owner.proposals[0].owner_id = ""
	_check(Bridge.validate_draft(missing_owner, "scene-sha", "layout-sha").has("missing_owner"), "missing owner rejected")
	_check(Bridge.validate_draft(valid, "other-scene", "layout-sha").has("stale_scene_or_layout_sha"), "stale scene SHA rejected")
	var malformed := {"schema": Bridge.SCHEMA, "base": {}, "proposals": "bad"}
	_check(not Bridge.validate_draft(malformed, "", "").is_empty(), "malformed draft rejected")
	var connector: Rect2 = Layout.CONNECTORS.values()[0]
	var blocked := Bridge.make_draft([[connector.position, connector.end]], "artist_wall_02", "test connector", "blocker", "scene-sha", "layout-sha", 1.0)
	_check(Bridge.validate_draft(blocked, "scene-sha", "layout-sha").has("protected_route_intersection"), "connector-spanning blocker rejected")
	var passage: Rect2 = Layout.PASSAGES["lower_upper_spine_05_06"]
	var passage_blocked := Bridge.make_draft([[passage.position, passage.end]], "artist_wall_04", "close 05 to 06", "void", "scene-sha", "layout-sha", 1.0)
	_check(Bridge.validate_draft(passage_blocked, "scene-sha", "layout-sha").has("protected_route_width_violation"), "05 to 06 closure and 128px route narrowing rejected")
	var near_route := Bridge.make_draft([[connector.position + Vector2(-10, 0), connector.position + Vector2(-10, 16)]], "artist_wall_05", "near route", "blocker", "scene-sha", "layout-sha", 1.0)
	_check(Bridge.validate_draft(near_route, "scene-sha", "layout-sha").has("operator_11px_clearance_violation"), "Operator 11px clearance violation rejected")
	var sealed_room := Bridge.make_draft([[Vector2(-400, -8), Vector2(400, -8), Vector2(400, 8), Vector2(-400, 8)]], "artist_wall_06", "seal the Creche", "blocker", "scene-sha", "layout-sha", 1.0)
	_check(Bridge.validate_draft(sealed_room, "scene-sha", "layout-sha").has("candidate_route_or_operator_radius_failure"), "candidate occupancy search rejects a disconnected spawn-to-exit route")
	var marker := _protected_marker()
	if not marker.is_empty():
		var overlap := Bridge.make_draft([[marker.position - Vector2(2, 2), marker.position + Vector2(2, 2)]], "artist_wall_03", "marker test", "blocker", "scene-sha", "layout-sha", 1.0)
		_check(Bridge.validate_draft(overlap, "scene-sha", "layout-sha").has("protected_spawn_locker_lift_overlap"), "spawn/locker/lift overlap rejected")
	else:
		_check(false, "protected spawn/locker/lift fixture exists")


func _protected_marker() -> Dictionary:
	for zone in Layout.ZONES:
		for marker in Layout.markers_for(StringName(zone.id)):
			if str(marker.get("kind", "")) in ["spawn", "locker", "lift"]: return marker
	return {}


func _has_world_bounds_rail(records: Array[Dictionary]) -> bool:
	for record in records:
		if str(record.id).contains("WorldBounds") or str(record.id).contains("PathBoundaryCollision"): return true
	return false


func _has_record_fragment(records: Array[Dictionary], fragment: String) -> bool:
	for record in records:
		if str(record.id).contains(fragment): return true
	return false


func _has_record_kind(records: Array[Dictionary], kind: String) -> bool:
	for record in records:
		if str(record.kind) == kind: return true
	return false


func _has_zone_record(records: Array[Dictionary], zone_id: String) -> bool:
	for record in records:
		if str(record.zone_id) == zone_id: return true
	return false


func _has_gate_pylon(records: Array[Dictionary], name_part: String, center: Vector2) -> bool:
	for record in records:
		if not str(record.id).contains(name_part) or str(record.shape) != "rectangle": continue
		var points := record.world_points as PackedVector2Array
		var bounds := _bounds(points)
		if bounds.get_center().distance_to(center) <= 1.0 and bounds.size.distance_to(Vector2(240, 496)) <= 1.0:
			return true
	return false


func _bounds(points: PackedVector2Array) -> Rect2:
	var result := Rect2(points[0], Vector2.ZERO)
	for point in points: result = result.expand(point)
	return result


func _check(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
