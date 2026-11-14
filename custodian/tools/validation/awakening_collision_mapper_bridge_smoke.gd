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
	var original_draft: Dictionary = {}
	var fixture_points: Array[Vector2] = []
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
		_check(mapper.has_method("save_collision_draft_to") and mapper.has_method("load_collision_draft_from"), "mapper exposes explicit-path draft save/reopen for isolated verification")
		_check(mapper.has_method("copy_exact_vertices") and mapper.has_method("capture_annotated_draft"), "mapper exposes exact-vertices clipboard and annotated capture actions")
		if mapper.has_method("save_collision_draft_to") and mapper.has_method("load_collision_draft_from"):
			var roundtrip_path := ProjectSettings.globalize_path("user://awakening_mapper_roundtrip.json")
			fixture_points = [Vector2(0, -3000), Vector2(4, -3000)]
			var registered_group: Node = mapper._target_level.find_child("RegisteredComposition04_05", true, false)
			var dust_lung_sprite := registered_group.get_node_or_null("DustLung") as Sprite2D if registered_group != null else null
			var source_art := Bridge.art_provenance_for_sprite(dust_lung_sprite, fixture_points)
			_check(not str(source_art.resource).is_empty() and source_art.source_pixel_points.size() == 2, "registered production-art resource supplies a stable source-pixel provenance fixture")
			mapper._draft_polylines = [fixture_points]
			mapper.proposal_metadata.clear()
			mapper.proposal_metadata.append({"id": "stable-fixture-001", "owner_id": "fixture_owner", "purpose": "roundtrip", "geometry_kind": "decoration", "proposal_mode": "replace_existing", "source_collision_id": "fixture-source", "source_art": source_art})
			mapper.proposal_kind = "decoration"
			mapper._owner_field.text = "fixture_owner"
			mapper._purpose_field.text = "roundtrip"
			for snap_fixture in [1.0, 4.0]:
				mapper.snap_step = snap_fixture
				_check(mapper.call("save_collision_draft_to", roundtrip_path), "real mapper saves explicit-path draft fixture at snap %s" % snap_fixture)
				mapper._draft_polylines.clear()
				mapper.proposal_metadata.clear()
				mapper.snap_step = 4.0 if snap_fixture == 1.0 else 1.0
				_check(mapper.call("load_collision_draft_from", roundtrip_path), "real mapper reopens saved draft fixture")
				_check(mapper.snap_step == snap_fixture, "reopened draft restores exact snap interval %s" % snap_fixture)
				_check(mapper._draft_polylines == [fixture_points], "reopened draft preserves ordered world vertices")
			var restored_metadata: Dictionary = mapper.proposal_metadata[0] if not mapper.proposal_metadata.is_empty() else {}
			_check(restored_metadata.get("id") == "stable-fixture-001" and restored_metadata.get("owner_id") == "fixture_owner" and restored_metadata.get("purpose") == "roundtrip" and restored_metadata.get("geometry_kind") == "decoration" and restored_metadata.get("proposal_mode") == "replace_existing" and restored_metadata.get("source_collision_id") == "fixture-source" and JSON.stringify(restored_metadata.get("source_art", {})) == JSON.stringify(source_art) and mapper._next_proposal_id == 2, "reopened draft preserves all proposal metadata, source-art provenance, and the next stable ID")
			DirAccess.remove_absolute(roundtrip_path)
			mapper._draft_polylines[0][1] = fixture_points[1] + Vector2(4, 0)
			_check(mapper.call("save_collision_draft_to", roundtrip_path), "edited draft saves without recalculating source-art provenance")
			mapper._draft_polylines.clear()
			mapper.proposal_metadata.clear()
			_check(mapper.call("load_collision_draft_from", roundtrip_path), "edited draft reopens")
			_check(mapper._draft_polylines[0][1] == fixture_points[1] + Vector2(4, 0) and JSON.stringify(mapper.proposal_metadata[0].source_art) == JSON.stringify(source_art), "edited reopen keeps changed vertices and original source-art coordinates")
			DirAccess.remove_absolute(roundtrip_path)
			original_draft = Bridge.make_draft(mapper._draft_polylines, "fixture_owner", "roundtrip", "decoration", "scene-sha", "layout-sha", mapper.snap_step, mapper.proposal_metadata)
			_check(Bridge.validate_draft(original_draft, "other-scene", "layout-sha").has("stale_scene_or_layout_sha"), "stale source hashes remain an explicit fail-closed finding")
			var missing_art := original_draft.duplicate(true)
			missing_art.proposals[0].erase("source_art")
			_check(Bridge.validate_draft(missing_art, "scene-sha", "layout-sha").has("source_art_provenance_missing"), "missing source-art provenance is rejected")
			var malformed_art := original_draft.duplicate(true)
			malformed_art.proposals[0].source_art.world_transform[0] = "not-a-number"
			_check(Bridge.validate_draft(malformed_art, "scene-sha", "layout-sha").has("source_art_provenance_malformed"), "malformed source-art transforms are rejected")
			var unsupported := original_draft.duplicate(true)
			unsupported.schema = "future.unsupported"
			_check(not Bridge.validate_draft(unsupported, "scene-sha", "layout-sha").is_empty(), "unsupported draft schema is rejected")
			var invalid_path := ProjectSettings.globalize_path("user://awakening_mapper_invalid.json")
			var invalid_file := FileAccess.open(invalid_path, FileAccess.WRITE)
			invalid_file.store_string(JSON.stringify(unsupported))
			invalid_file.close()
			var prior_vertices: Array = mapper._draft_polylines.duplicate(true)
			_check(not mapper.call("load_collision_draft_from", invalid_path) and mapper._draft_polylines == prior_vertices, "invalid draft reopen fails closed without changing current valid geometry")
			DirAccess.remove_absolute(invalid_path)
		if mapper.has_method("copy_exact_vertices"):
			mapper._selected_polyline_index = 0
			var copied: String = mapper.call("copy_exact_vertices")
			_check(copied.contains("stable-fixture-001") and copied.contains(str(fixture_points[0].x)) and copied.contains("source_pixel_points"), "exact-vertex clipboard includes stable identity, world pixels, and source pixels")
			_check(copied == str(mapper.call("copy_exact_vertices")), "exact-vertex clipboard serialization is deterministic")
			if not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
				_check(mapper._export_status.contains("Clipboard is unavailable"), "missing clipboard support produces an actionable error")
			mapper._selected_polyline_index = -1
			_check(str(mapper.call("copy_exact_vertices")).is_empty(), "empty selection refuses exact-vertex copy")
		if mapper.has_method("capture_annotated_draft"):
			if not fixture_points.is_empty(): mapper._camera.position = fixture_points[0]
			var capture_base := ProjectSettings.globalize_path("user://awakening_mapper_capture")
			var capture: Dictionary = await mapper.call("capture_annotated_draft", capture_base)
			if DisplayServer.get_name() == "headless":
				_check(not capture.get("ok", false) and capture.get("error") == "headless_capture_unavailable", "headless renderer reports capture unavailable without fabricating evidence")
			else:
				_check(capture.get("ok", false) and FileAccess.file_exists(capture_base + ".png") and FileAccess.file_exists(capture_base + ".json"), "interactive renderer captures the real mapper viewport and paired JSON")
				var capture_file := FileAccess.open(capture_base + ".json", FileAccess.READ)
				var capture_json: Variant = JSON.parse_string(capture_file.get_as_text()) if capture_file != null else null
				if capture_file != null: capture_file.close()
				_check(capture_json is Dictionary and capture_json.get("base", {}).get("scene_git_sha", "") != "" and capture_json.get("capture", {}).get("layers", []).has("registered_production_art"), "interactive capture records source hashes and production-art layer")
				var captured_image := Image.load_from_file(capture_base + ".png")
				_check(captured_image != null and not captured_image.is_empty(), "interactive capture PNG is decodable")
				DirAccess.remove_absolute(capture_base + ".png")
				DirAccess.remove_absolute(capture_base + ".json")
			var invalid_capture: Dictionary = Bridge.write_capture_bundle("", Image.create(2, 2, false, Image.FORMAT_RGBA8), {})
			_check(not invalid_capture.get("ok", false) and invalid_capture.get("error") == "output_path_empty", "capture rejects an empty output path")
			var relative_capture: Dictionary = Bridge.write_capture_bundle("relative/capture", Image.create(2, 2, false, Image.FORMAT_RGBA8), {})
			_check(not relative_capture.get("ok", false) and relative_capture.get("error") == "output_path_must_be_absolute", "capture rejects ambiguous relative output paths")
			var bundle_base := ProjectSettings.globalize_path("user://awakening_mapper_capture_bundle")
			var repeat_base := ProjectSettings.globalize_path("user://awakening_mapper_capture_repeat")
			var capture_image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
			capture_image.fill(Color(0.1, 0.3, 0.5, 1.0))
			var capture_payload := {"schema": Bridge.SCHEMA, "base": original_draft.base, "snap_px": mapper.snap_step, "proposals": original_draft.proposals, "capture": {"layers": ["registered_production_art", "source_collision_red_or_green", "draft_proposal_cyan"]}}
			var capture_result: Dictionary = Bridge.write_capture_bundle(bundle_base, capture_image, capture_payload)
			var repeat_result: Dictionary = Bridge.write_capture_bundle(repeat_base, capture_image, capture_payload)
			_check(capture_result.get("ok", false) and repeat_result.get("ok", false), "paired PNG and JSON bundle writes succeed")
			_check(FileAccess.get_sha256(bundle_base + ".json") == FileAccess.get_sha256(repeat_base + ".json") and FileAccess.get_sha256(bundle_base + ".png") == FileAccess.get_sha256(repeat_base + ".png"), "unchanged capture inputs produce byte-identical PNG and JSON")
			var occupied: Dictionary = Bridge.write_capture_bundle(bundle_base, capture_image, capture_payload)
			_check(not occupied.get("ok", false) and occupied.get("error") == "output_path_occupied", "capture refuses to overwrite existing evidence")
			DirAccess.remove_absolute(bundle_base + ".png")
			DirAccess.remove_absolute(bundle_base + ".json")
			DirAccess.remove_absolute(repeat_base + ".png")
			DirAccess.remove_absolute(repeat_base + ".json")
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
	var source_art := {"resource": "res://art/fixture.png", "world_transform": [1.0, 0.0, 0.0, 1.0, 4.0, 8.0], "source_pixel_points": [[2.0, 3.0], [4.0, 3.0]]}
	var valid := Bridge.make_draft([[Vector2(-100, 0), Vector2(-80, 0)]], "artist_wall_01", "west wall correction", "decoration", "scene-sha", "layout-sha", 4.0, [{"id": "stable-fixture-001", "source_art": source_art}])
	_check(valid.snap_px == 4.0 and valid.proposals[0].id == "stable-fixture-001" and valid.proposals[0].source_art == source_art, "draft serialization retains snap interval, stable ID, and source-art provenance")
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
