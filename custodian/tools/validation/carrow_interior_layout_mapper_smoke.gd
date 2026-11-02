extends SceneTree

const Draft := preload("res://tools/level_authoring/mapper/carrow_interior_layout_draft.gd")
const ROOMS := ["west_draft_house", "east_machine_house", "operations_house"]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture_scene := load("res://scenes/debug/carrow_machine_house_scale_24x18.tscn") as PackedScene
	var fixture := fixture_scene.instantiate() as Node2D
	root.add_child(fixture)
	await process_frame
	var operator := fixture.get_node_or_null("Operator") as CharacterBody2D
	var camera := fixture.get_node_or_null("Camera2D") as CameraController
	var shape_node := operator.get_node_or_null("CollisionShape2D") as CollisionShape2D if operator != null else null
	_check(operator != null and operator.scene_file_path.ends_with("operator.tscn"), "fixture has the real Operator scene")
	_check(camera is CameraController and camera.base_zoom == Vector2(0.84, 0.84), "fixture has the real fixed-base CameraController")
	_check(shape_node != null and shape_node.shape is CapsuleShape2D, "clearance validator uses the actual Operator capsule")
	var capsule := shape_node.shape as CapsuleShape2D if shape_node != null else null
	for room_id in ROOMS:
		_test_room(room_id, capsule, shape_node.position if shape_node != null else Vector2.ZERO, shape_node.scale if shape_node != null else Vector2.ONE)
	_test_draft_mutations(capsule, shape_node.position if shape_node != null else Vector2.ZERO, shape_node.scale if shape_node != null else Vector2.ONE)
	await _test_mapper_scene()
	if _failures.is_empty():
		print("carrow_interior_layout_mapper_smoke: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_room(room_id: String, capsule: CapsuleShape2D, shape_offset: Vector2, operator_scale: Vector2) -> void:
	var config := Draft.room_config(room_id)
	var grid: Vector2i = config.get("grid_wh", Vector2i.ZERO)
	var draft := Draft.create_draft(room_id)
	_check(not draft.is_empty(), "%s draft initializes" % room_id)
	_check(draft.get("grid_wh") == [grid.x, grid.y], "%s uses its exact approved grid" % room_id)
	_check(int(draft.get("tile_size", 0)) == 32, "%s uses a true 32px grid" % room_id)
	_check(String(draft.get("base_floor_state", "")) == "slab_plain_01", "%s uses the registered neutral base floor" % room_id)
	_check((draft.get("art_placements", []) as Array).is_empty(), "%s starts without invented prop placements" % room_id)
	_check((draft.get("floor_regions", []) as Array).is_empty(), "%s starts without repeated floor pattern overrides" % room_id)
	_check((draft.get("collision_shapes", []) as Array).size() == 5, "%s starts with only the room shell and split 3-cell doorway" % room_id)
	_check((draft.get("portal_cells", []) as Array).size() == 3, "%s has the current 3-cell portal" % room_id)
	var expected_storage := int(config.get("storage", []).size())
	_check((draft.get("storage_anchors", []) as Array).size() == expected_storage, "%s preserves each existing storage resource identity" % room_id)
	var report := Draft.validate(draft, capsule, shape_offset, operator_scale)
	_check(bool(report.get("passed", false)), "%s default shell and portal validate against actual capsule: %s" % [room_id, str(report.get("errors", []))])
	_check((report.get("checks", []) as Array).any(func(value: Dictionary) -> bool: return value.get("check") == "camera_regions_disjoint" and value.get("clear") == true), "%s reports disjoint off-map camera allocation" % room_id)
	var encoded_a := Draft.serialize(draft)
	var parsed: Variant = JSON.parse_string(encoded_a)
	_check(parsed is Dictionary and Draft.has_valid_digest(parsed as Dictionary), "%s draft JSON has a canonical content digest" % room_id)
	_check(Draft.serialize(parsed as Dictionary) == encoded_a, "%s JSON round-trip is byte-stable" % room_id)
	_check(Draft.is_safe_output_path(Draft.draft_path(room_id)), "%s output is confined to the ignored draft directory" % room_id)
	_check(not Draft.is_safe_output_path("/tmp/%s.draft.json" % room_id), "%s refuses output outside the confined reports tree" % room_id)


func _test_draft_mutations(capsule: CapsuleShape2D, shape_offset: Vector2, operator_scale: Vector2) -> void:
	var draft := Draft.create_draft("east_machine_house")
	_check(Draft.paint_floor_cell(draft, Vector2i(5, 5), "slab_worn_01"), "floor paint records one explicit cell")
	_check(Draft.paint_floor_cell(draft, Vector2i(6, 5), "slab_cracked_01"), "floor regions accept a second registered state")
	_check(Draft.erase_floor_cell(draft, Vector2i(5, 5)), "floor erase removes only its explicit cell")
	var asset_id := "carrow_machine_house_props/relay_bank::omni"
	_check(Draft.place_art(draft, "relay_anchor", asset_id, Vector2i(15, 7)), "registered prop anchor can be placed")
	_check(not Draft.place_art(draft, "relay_anchor", asset_id, Vector2i(16, 7)), "duplicate prop anchor names are rejected")
	_check(Draft.bind_storage(draft, "carrow_service_parts_locker", "relay_anchor"), "existing storage can bind to one named prop")
	_check(Draft.move_art(draft, "relay_anchor", Vector2i(14, 7)), "named prop anchor can be moved")
	var storage: Dictionary = {}
	for storage_variant in draft.storage_anchors:
		if String((storage_variant as Dictionary).get("storage_id", "")) == "carrow_service_parts_locker":
			storage = storage_variant
	_check(storage.get("anchor_cell") == [14, 7], "bound storage follows the exact named art anchor")
	_check(Draft.add_collision_rect(draft, "user_solid", Rect2i(8, 8, 2, 2)), "independent collision rectangle can be created")
	_check(Draft.move_collision_rect(draft, "user_solid", Vector2i(9, 8)), "collision rectangle can be edited")
	_check(Draft.delete_collision_shape(draft, "user_solid"), "collision rectangle can be erased")
	_check(Draft.set_portal_center(draft, 16), "3-cell portal can be moved along its south wall")
	_check(Draft.set_waypoint(draft, "maintenance_clearance", Vector2i(14, 12)), "named user clearance waypoint can be authored")
	draft = Draft.with_digest(draft)
	var report := Draft.validate(draft, capsule, shape_offset, operator_scale)
	_check(bool(report.get("passed", false)), "edited plan validates: %s" % str(report.get("errors", [])))
	_check((report.get("checks", []) as Array).any(func(value: Dictionary) -> bool: return value.get("check") == "operator_waypoint_clearance" and value.get("id") == "maintenance_clearance"), "report gives exact actual-capsule waypoint clearance")
	_check((report.get("checks", []) as Array).any(func(value: Dictionary) -> bool: return value.get("check") == "art_alpha_cell_coverage" and value.get("placement_id") == "relay_anchor"), "report exposes authored image alpha coverage as geometry facts")
	_check(Draft.delete_art(draft, "relay_anchor"), "named prop placement can be deleted")
	var unbound := false
	for storage_variant in draft.storage_anchors:
		var record := storage_variant as Dictionary
		if String(record.get("storage_id", "")) == "carrow_service_parts_locker":
			unbound = String(record.get("art_placement_id", "")) == ""
	_check(unbound, "deleting art unbinds but does not delete the resource record")
	var stale := draft.duplicate(true)
	stale["grid_wh"] = [28, 22]
	_check(not bool(Draft.validate(stale, capsule, shape_offset, operator_scale).get("passed", false)), "wrong room size fails closed")
	var stale_source := draft.duplicate(true)
	(stale_source.source_refs as Array)[0]["sha256"] = "0".repeat(64)
	stale_source = Draft.with_digest(stale_source)
	_check(not bool(Draft.validate(stale_source, capsule, shape_offset, operator_scale).get("passed", false)), "stale source pin fails without mutating the source")
	var overlap := Draft.create_draft("east_machine_house")
	Draft.add_collision_rect(overlap, "overlap_north", Rect2i(0, 0, 1, 1))
	overlap = Draft.with_digest(overlap)
	_check(not bool(Draft.validate(overlap, capsule, shape_offset, operator_scale).get("passed", false)), "overlapping collision rectangles block validation")
	var blocked := Draft.create_draft("east_machine_house")
	Draft.add_collision_rect(blocked, "portal_block", Rect2i(14, 21, 1, 1))
	blocked = Draft.with_digest(blocked)
	_check(not bool(Draft.validate(blocked, capsule, shape_offset, operator_scale).get("passed", false)), "collision in a portal cell blocks validation")
	var clipped := Draft.create_draft("east_machine_house")
	Draft.place_art(clipped, "clipped", asset_id, Vector2i(0, 0))
	clipped = Draft.with_digest(clipped)
	_check(not bool(Draft.validate(clipped, capsule, shape_offset, operator_scale).get("passed", false)), "art bounds that clip the room fail clearly")
	var storage_tamper := Draft.create_draft("east_machine_house")
	(storage_tamper.storage_anchors as Array)[0]["resources"]["ruin_scrap"] = 1
	storage_tamper = Draft.with_digest(storage_tamper)
	_check(not bool(Draft.validate(storage_tamper, capsule, shape_offset, operator_scale).get("passed", false)), "resource IDs and starting contents are immutable in drafts")


func _test_mapper_scene() -> void:
	var packed := load("res://scenes/debug/carrow_interior_layout_mapper.tscn") as PackedScene
	_check(packed != null, "debug authoring scene exists")
	if packed == null:
		return
	var mapper := packed.instantiate() as CarrowInteriorLayoutMapper
	root.add_child(mapper)
	await process_frame
	_check(mapper.room_id == "west_draft_house", "mapper opens on a declared room")
	_check(mapper.draft.get("art_placements", []).is_empty(), "mapper preview removes fixture's synthetic props")
	_check(mapper.draft.get("floor_regions", []).is_empty(), "mapper preview starts without patterned floor overrides")
	_check(mapper._operator != null and mapper._operator.get_script().resource_path == "res://game/actors/operator/operator.gd", "mapper retains the actual Operator")
	_check(mapper._game_camera is CameraController and mapper._game_camera.zoom == Vector2(0.84, 0.84), "mapper retains the actual CameraController at base zoom")
	_check(mapper._fixture.get_children().size() == 5, "preview contains only Operator, camera, neutral floor, draft art and draft collision")
	var smoke_path := Draft.draft_path(mapper.room_id).get_base_dir().path_join(".mapper-smoke-%d-%d.draft.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	_check(not FileAccess.file_exists(smoke_path), "round-trip smoke uses an isolated temporary draft path")
	Draft.paint_floor_cell(mapper.draft, Vector2i(2, 2), "slab_worn_01")
	Draft.place_art(mapper.draft, "smoke_prop", "carrow_machine_house_props/relay_bank::omni", Vector2i(12, 9))
	mapper._commit_mutation()
	var expected_layout := Draft.serialize(mapper.draft)
	var expected_art_count := mapper._art_root.get_child_count()
	var expected_floor_count := mapper._floor_root.get_child_count()
	var expected_collision_count := mapper._collision_root.get_child_count()
	var expected_operator_position := mapper._operator.global_position
	_check(mapper._save_draft_at(smoke_path), "mapper saves a validated draft to a confined ignored path")
	var saved_text := FileAccess.get_file_as_string(smoke_path)
	mapper.draft["grid_wh"] = [28, 22]
	_check(not mapper._save_draft_at(smoke_path) and FileAccess.get_file_as_string(smoke_path) == saved_text, "invalid replacement is rejected without overwriting a valid saved draft")
	mapper.draft = Draft.create_draft(mapper.room_id)
	mapper._build_preview()
	_check(mapper._load_draft_at(smoke_path), "mapper reloads a validated saved draft")
	_check(Draft.serialize(mapper.draft) == expected_layout, "saved and reopened draft retains identical canonical layout")
	_check(mapper._art_root.get_child_count() == expected_art_count and mapper._floor_root.get_child_count() == expected_floor_count and mapper._collision_root.get_child_count() == expected_collision_count, "saved and reopened draft rebuilds identical floor, art and collision presentation")
	_check(mapper._operator.global_position == expected_operator_position and mapper._game_camera.zoom == Vector2(0.84, 0.84), "draft reload preserves the actual Operator position and game camera projection")
	DirAccess.remove_absolute(smoke_path)
	mapper._room_select.select(1)
	mapper._on_room_selected(1)
	await process_frame
	_check(mapper.room_id == "east_machine_house" and mapper.draft.get("grid_wh") == [30, 22], "room selector switches to exact East dimensions")
	_check(mapper._game_camera.base_zoom == Vector2(0.84, 0.84), "room switch preserves actual camera base profile")
	mapper._room_select.select(2)
	mapper._on_room_selected(2)
	await process_frame
	_check(mapper.room_id == "operations_house" and mapper.draft.get("grid_wh") == [36, 26], "room selector switches to exact Operations dimensions")
	mapper.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
