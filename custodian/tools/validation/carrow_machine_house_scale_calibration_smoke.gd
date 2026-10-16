extends SceneTree

const FIXTURE := preload("res://tools/level_authoring/carrow_machine_house_scale_fixture.gd")
const VARIANTS := {
	"24x18": {"size": Vector2i(24, 18), "floors": 432, "perimeter": 76, "solids": 154},
	"30x22": {"size": Vector2i(30, 22), "floors": 660, "perimeter": 96, "solids": 174},
	"36x26": {"size": Vector2i(36, 26), "floors": 936, "perimeter": 116, "solids": 194},
}
const EXPECTED_ART := {
	"NorthWallPanelled": "walls/wall_carrow_wall_run_panelled_long_01.png",
	"NorthWallConduit": "walls/wall_carrow_wall_run_conduit_long_01.png",
	"WestWall": "walls/wall_carrow_pillar_lit_01.png",
	"EastWall": "walls/wall_carrow_pillar_plain_02.png",
	"SouthDoorway": "walls/wall_carrow_doorframe_recessed_01.png",
	"RelayBank": "props/carrow_machine_house_relay_bank.png",
	"Switchgear": "props/carrow_machine_house_switchgear.png",
	"PartsLocker": "props/carrow_machine_house_parts_locker.png",
	"Workbench": "props/carrow_machine_house_workbench.png",
	"ServiceCabinet": "props/carrow_machine_house_service_cabinet.png",
	"ReplacementModules": "props/carrow_machine_house_replacement_modules.png",
	"ConduitJunction": "props/carrow_machine_house_conduit_junction.png",
	"PowerCabinet": "props/carrow_machine_house_power_cabinet.png",
}
const EXPECTED_ART_Z := {
	"NorthWallPanelled": -18, "NorthWallConduit": -18,
	"WestWall": -17, "EastWall": -17, "SouthDoorway": -16,
	"RelayBank": -12, "Switchgear": -12,
	"PartsLocker": -10, "Workbench": -10, "ServiceCabinet": -10,
	"ReplacementModules": -10, "ConduitJunction": -10, "PowerCabinet": -10,
}
const EXPECTED_STORAGE := {
	"carrow_service_parts_locker": {&"ruin_scrap": 52, &"structural_alloy": 4},
	"carrow_structural_spares_rack": {&"structural_alloy": 14, &"ruin_scrap": 16},
	"carrow_power_components_cabinet": {&"power_components": 4, &"capacitor_dust": 3, &"ruin_scrap": 10},
}
const VIEWPORT_SIZE := Vector2i(768, 576)
const TILE_SIZE := 32

var _failed: Array[String] = []
var _evidence_root := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = VIEWPORT_SIZE
	_evidence_root = ProjectSettings.globalize_path("res://../reports/carrow_scale_calibration")
	var make_dir_error := DirAccess.make_dir_recursive_absolute(_evidence_root)
	_check(make_dir_error == OK, "unable to create ignored Carrow scale evidence directory")
	_negative_controls()
	var comparison := {
		"tile_size_px": TILE_SIZE,
		"viewport_px": VIEWPORT_SIZE,
		"operator_speed_px_per_sec": 150.0,
		"camera_base_zoom": [0.84, 0.84],
		"variants": [],
	}
	for variant_id in VARIANTS:
		var scene_path := "res://scenes/debug/carrow_machine_house_scale_%s.tscn" % variant_id
		var packed := load(scene_path) as PackedScene
		_check(packed != null, "%s does not resolve to a PackedScene" % scene_path)
		if packed == null:
			continue
		var fixture := packed.instantiate() as CarrowMachineHouseScaleFixture
		_check(fixture != null, "%s does not instantiate the shared fixture controller" % scene_path)
		if fixture == null:
			continue
		root.add_child(fixture)
		await process_frame
		await physics_frame
		await process_frame
		var fixture_snapshot := fixture.get_fixture_snapshot()
		var report := _validate_fixture(fixture, fixture_snapshot, variant_id)
		var captures: Array[Dictionary] = []
		if DisplayServer.get_name() != "headless":
			for waypoint in [&"ENTRY", &"CENTER", &"NORTH"]:
				fixture.debug_teleport_to_waypoint(waypoint)
				await physics_frame
				await process_frame
				await process_frame
				RenderingServer.force_draw(false)
				var capture_path := "%s/%s/%s.png" % [_evidence_root, variant_id, String(waypoint).to_lower()]
				var capture_dir := capture_path.get_base_dir()
				_check(DirAccess.make_dir_recursive_absolute(capture_dir) == OK, "%s evidence folder creation failed" % variant_id)
				var image := fixture.get_viewport().get_texture().get_image()
				_check(image.get_size() == VIEWPORT_SIZE, "%s %s capture viewport is %s, expected %s" % [variant_id, waypoint, image.get_size(), VIEWPORT_SIZE])
				var save_error := image.save_png(capture_path)
				_check(save_error == OK, "%s %s screenshot did not save: %s" % [variant_id, waypoint, save_error])
				captures.append({
					"waypoint": String(waypoint),
					"path": capture_path,
					"width_px": image.get_width(),
					"height_px": image.get_height(),
					"sha256": FileAccess.get_sha256(capture_path) if save_error == OK else "",
				})
		else:
			captures = [
				{"waypoint": "ENTRY", "viewport_px": [VIEWPORT_SIZE.x, VIEWPORT_SIZE.y], "render_capture": false},
				{"waypoint": "CENTER", "viewport_px": [VIEWPORT_SIZE.x, VIEWPORT_SIZE.y], "render_capture": false},
				{"waypoint": "NORTH", "viewport_px": [VIEWPORT_SIZE.x, VIEWPORT_SIZE.y], "render_capture": false},
			]
		report["captures"] = captures
		report["fixture"] = fixture_snapshot
		var variant_dir := "%s/%s" % [_evidence_root, variant_id]
		_check(DirAccess.make_dir_recursive_absolute(variant_dir) == OK, "%s JSON evidence folder creation failed" % variant_id)
		_write_json("%s/geometry.json" % variant_dir, report)
		comparison.variants.append({
			"variant_id": variant_id,
			"grid_cells": [fixture.room_size.x, fixture.room_size.y],
			"pixel_extent": [fixture.room_size.x * TILE_SIZE, fixture.room_size.y * TILE_SIZE],
			"floor_cell_count": fixture.room_size.x * fixture.room_size.y,
			"solid_collider_cell_count": fixture.collision_shapes.size(),
			"art_count": fixture.get_node("ProductionArt").get_child_count(),
			"storage_count": fixture.get_node("ArtBoundStorage").get_child_count(),
			"camera_zoom": [fixture.camera.zoom.x, fixture.camera.zoom.y],
			"operator_speed_px_per_sec": 150.0,
			"capture_count": captures.size(),
		})
		fixture.queue_free()
		await process_frame
	_write_json("%s/comparison.json" % _evidence_root, comparison)
	if _failed.is_empty():
		print("PASS carrow_machine_house_scale_calibration: 3 exact scenes, physical clearance, assets/storage, controls, geometry JSON; renderer=%s" % DisplayServer.get_name())
		quit(0)
	else:
		for message in _failed:
			push_error(message)
		quit(1)


func _validate_fixture(fixture: CarrowMachineHouseScaleFixture, data: Dictionary, variant_id: String) -> Dictionary:
	var failure_start := _failed.size()
	var assertions := {}
	var expected: Dictionary = VARIANTS[variant_id]
	var size: Vector2i = expected.size
	var group_start := _failed.size()
	_check(fixture.variant_id == variant_id, "%s scene carries a different variant identifier" % variant_id)
	_check(fixture.room_size == size, "%s room dimensions are not fixed to %s" % [variant_id, size])
	_check(data.floor_cell_count == expected.floors, "%s floor count mismatch" % variant_id)
	_check(data.pixel_extent == size * TILE_SIZE, "%s pixel extent mismatch" % variant_id)
	_check(data.collider_shape_count == expected.solids, "%s collider count mismatch" % variant_id)
	_check(data.perimeter_collision_cell_count == expected.perimeter, "%s perimeter collision count mismatch" % variant_id)
	_check(fixture.get_node("Native32pxFloor").get_child_count() == expected.floors, "%s does not render exactly one floor Sprite2D per tile" % variant_id)
	for floor_sprite in fixture.get_node("Native32pxFloor").get_children():
		_check(floor_sprite is Sprite2D and Vector2i((floor_sprite as Sprite2D).texture.get_size()) == Vector2i(TILE_SIZE, TILE_SIZE) and (floor_sprite as Sprite2D).scale == Vector2(1.0, 1.0), "%s floor art is not at native 32px scale" % variant_id)
	_check(fixture.get_node("ProductionArt").get_child_count() == 13, "%s does not have exactly 13 production art placements" % variant_id)
	_check(fixture.get_node("ArtBoundStorage").get_child_count() == 3, "%s does not have exactly three art-bound resource interactions" % variant_id)
	assertions["fixed_extent_and_object_counts"] = _failed.size() == group_start

	group_start = _failed.size()
	var solid_cells := {}
	for solid in data.solid_cells:
		var cell: Vector2i = solid.tile
		_check(not solid_cells.has(cell), "%s duplicates collider tile %s" % [variant_id, cell])
		solid_cells[cell] = String(solid.owner)
	_check(solid_cells.size() == expected.solids, "%s static-body cell set does not match shape count" % variant_id)
	for y in range(size.y):
		for x in range(size.x):
			var cell := Vector2i(x, y)
			var perimeter := x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1
			var door := y == size.y - 1 and x >= (size.x >> 1) - 2 and x < (size.x >> 1) + 2
			var equipment_owner := _equipment_owner(cell, size)
			var should_be_solid := (perimeter and not door) or not equipment_owner.is_empty()
			_check(solid_cells.has(cell) == should_be_solid, "%s collider ownership disagrees at tile %s" % [variant_id, cell])
			if not equipment_owner.is_empty():
				_check(solid_cells.get(cell, "") == equipment_owner, "%s equipment collider owner mismatch at %s" % [variant_id, cell])
	assertions["solid_cell_set_matches_exact_perimeter_and_equipment"] = _failed.size() == group_start

	group_start = _failed.size()
	var expected_door: Array[Vector2i] = []
	for x in range((size.x >> 1) - 2, (size.x >> 1) + 2):
		expected_door.append(Vector2i(x, size.y - 1))
	_check(data.door_cells == expected_door, "%s south exit is not exactly four centered cells" % variant_id)
	var aisle: Array = data.aisle_cells
	_check(aisle.size() == 4 * (size.y - 2), "%s center aisle dimensions are incorrect" % variant_id)
	for cell_variant in aisle:
		_check(not solid_cells.has(cell_variant), "%s aisle contains collider at %s" % [variant_id, cell_variant])
	assertions["four_cell_doorway_and_clear_aisle"] = _failed.size() == group_start

	group_start = _failed.size()
	var expected_art_names := EXPECTED_ART.keys()
	_check(data.art.size() == 13, "%s artifact geometry is missing art records" % variant_id)
	var art_by_name := {}
	for art in data.art:
		art_by_name[String(art.name)] = art
	for art_name in expected_art_names:
		_check(art_by_name.has(art_name), "%s missing art node %s" % [variant_id, art_name])
		if not art_by_name.has(art_name):
			continue
		var art: Dictionary = art_by_name[art_name]
		_check(art.source == EXPECTED_ART[art_name], "%s %s source path changed" % [variant_id, art_name])
		_check(art.z_index == EXPECTED_ART_Z[art_name], "%s %s production z index changed" % [variant_id, art_name])
		_check(art.scale == Vector2.ONE, "%s %s art is not at native scale" % [variant_id, art_name])
		var expected_anchor := _expected_art_anchor(art_name, size)
		_check(art.anchor_tile == expected_anchor, "%s %s art anchor is %s, expected %s" % [variant_id, art_name, art.anchor_tile, expected_anchor])
		_check(ResourceLoader.exists("res://content/sprites/environment/structure/carrow_machine_house/runtime/" + EXPECTED_ART[art_name], "Texture2D"), "%s source art unavailable for %s" % [variant_id, art_name])
	assertions["native_art_paths_and_variant_anchors"] = _failed.size() == group_start

	group_start = _failed.size()
	var storage_by_id := {}
	for storage in data.storage:
		storage_by_id[String(storage.storage_id)] = storage
	_check(storage_by_id.size() == EXPECTED_STORAGE.size(), "%s storage identities are not unique" % variant_id)
	for storage_id in EXPECTED_STORAGE:
		_check(storage_by_id.has(storage_id), "%s missing storage interaction %s" % [variant_id, storage_id])
		if storage_by_id.has(storage_id):
			var stored: Dictionary = storage_by_id[storage_id]
			_check(stored.contents == EXPECTED_STORAGE[storage_id], "%s %s starting resources differ from East production" % [variant_id, storage_id])
			var anchor_name := "PartsLocker" if storage_id == "carrow_service_parts_locker" else "ReplacementModules" if storage_id == "carrow_structural_spares_rack" else "PowerCabinet"
			var anchor: Vector2i = _expected_art_anchor(anchor_name, size)
			_check(stored.position_px == Vector2(anchor * TILE_SIZE), "%s %s is not anchored to its matching artwork" % [variant_id, storage_id])
	for storage_node in fixture.get_node("ArtBoundStorage").get_children():
		_check(not bool(storage_node.get("default_visual_enabled")), "%s storage shows a generic default chest visual" % variant_id)
	assertions["three_storage_ids_contents_and_art_anchors"] = _failed.size() == group_start

	group_start = _failed.size()
	var operator_node := fixture.operator
	var operator_shape := operator_node.get_node("CollisionShape2D") as CollisionShape2D
	_check(operator_node.get_script().resource_path == "res://game/actors/operator/operator.gd", "%s uses a proxy instead of the shipped Operator scene" % variant_id)
	_check(operator_shape != null and operator_shape.shape is CapsuleShape2D, "%s Operator collision shape differs from the shipped CapsuleShape2D" % variant_id)
	_check(fixture.camera is CameraController and fixture.camera.operator_ref == operator_node and fixture.camera.follow_target == operator_node, "%s does not use the real camera controller following the actual Operator" % variant_id)
	_check(fixture.camera.base_zoom == Vector2(0.84, 0.84), "%s camera base zoom differs from shipped defaults" % variant_id)
	_check(not fixture.camera.auto_zoom_enabled and fixture.camera.zoom == fixture.camera.base_zoom, "%s camera is not fixed to the common shipped base zoom" % variant_id)
	_check(fixture.camera.authored_map_bounds.size == Vector2(size * TILE_SIZE), "%s camera bounds do not match exact pixel extent" % variant_id)
	_check(fixture.get_viewport_rect().size == Vector2(VIEWPORT_SIZE), "%s evidence viewport is not 768x576" % variant_id)
	var operator_script := operator_node.get_script() as GDScript
	var operator_constants: Dictionary = operator_script.get_script_constant_map() if operator_script != null else {}
	_check(is_equal_approx(float(operator_constants.get("SPEED", -1.0)), 150.0), "%s Operator movement speed is not the shipped 150px/s default" % variant_id)
	for index in range(3):
		var cell := fixture.waypoint_cell(index)
		_check(_operator_shape_clear(fixture, cell), "%s actual Operator capsule overlaps collision at waypoint %s" % [variant_id, cell])
	for door_cell in expected_door:
		_check(_operator_shape_clear(fixture, door_cell), "%s four-cell south doorway is not traversable by the actual Operator at %s" % [variant_id, door_cell])
	for shape_node in fixture.collision_shapes:
		_check(shape_node.shape is RectangleShape2D and (shape_node.shape as RectangleShape2D).size == Vector2.ONE * TILE_SIZE, "%s has a collider that is not exactly one native tile" % variant_id)
	assertions["real_operator_camera_and_physical_clearance"] = _failed.size() == group_start

	group_start = _failed.size()
	var route_nodes := fixture.find_children("*", "GothicCompoundMap", true, false)
	_check(route_nodes.is_empty(), "%s debug variant instantiated a production room router" % variant_id)
	_check(fixture.find_children("*", "CharacterBody2D", true, false).size() == 1, "%s does not contain exactly one CharacterBody2D" % variant_id)
	_test_controls_and_reset(fixture, variant_id)
	assertions["controls_reset_and_no_production_router"] = _failed.size() == group_start
	return {
		"variant_id": variant_id,
		"passed": _failed.size() == failure_start,
		"scene_path": "res://scenes/debug/carrow_machine_house_scale_%s.tscn" % variant_id,
		"expectations": {"grid_cells": [size.x, size.y], "pixel_extent": [size.x * TILE_SIZE, size.y * TILE_SIZE], "floor_cells": expected.floors, "solid_collider_cells": expected.solids, "art_placements": 13, "storage_interactions": 3},
		"assertions": assertions,
		"failures": _failed.slice(failure_start),
		"presentation_vs_collision_evidence": {
			"art_sprite_bounds_overlapping_walkable_floor_cells": _json_safe(_art_overlap_summary(data.art)),
			"source": "native Sprite2D rectangles compared against 32px floor cells; collision remains explicit authored geometry",
		},
	}


func _negative_controls() -> void:
	for variant_id in VARIANTS:
		var size: Vector2i = VARIANTS[variant_id].size
		var valid_rects := _expected_rects(size)
		_check(FIXTURE.validate_geometry(size, valid_rects), "%s fixed configuration fails its own geometry validator" % variant_id)
		_check(not FIXTURE.validate_geometry(Vector2i(size.x - 1, size.y), valid_rects), "%s malformed dimensions were accepted" % variant_id)
		var overlap := valid_rects.duplicate(true)
		overlap.append(valid_rects[0].duplicate(true))
		_check(not FIXTURE.validate_geometry(size, overlap), "%s overlapping equipment was accepted" % variant_id)
		var door_cell := Vector2i(size.x >> 1, size.y - 1)
		_check(not FIXTURE.validate_geometry(size, valid_rects, [door_cell]), "%s doorway obstruction was accepted" % variant_id)
	var valid_paths: Array[String] = []
	for placement in FIXTURE.ART_PLACEMENTS:
		valid_paths.append(String(placement.path))
	_check(FIXTURE.validate_art_paths(valid_paths), "registered 13-art set does not pass asset preflight")
	var missing_art := valid_paths.duplicate()
	missing_art[0] = "walls/missing_carrow_scale_fixture.png"
	_check(not FIXTURE.validate_art_paths(missing_art), "missing art source was accepted")
	var malformed := _expected_rects(Vector2i(24, 18))
	malformed[0]["rect"] = "not a Rect2i"
	_check(not FIXTURE.validate_geometry(Vector2i(24, 18), malformed), "malformed equipment rectangle was accepted")


func _test_controls_and_reset(fixture: CarrowMachineHouseScaleFixture, variant_id: String) -> void:
	var entry := fixture.waypoint_cell(0)
	var center := fixture.waypoint_cell(1)
	var north := fixture.waypoint_cell(2)
	fixture.debug_teleport_to_waypoint(&"CENTER")
	fixture.operator.velocity = Vector2(80, -30)
	fixture.operator.position += Vector2(20, 10)
	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_R
	fixture._input(reset_key)
	_check((fixture.operator.global_position / TILE_SIZE).floor() == Vector2(entry), "%s R/reset did not restore the ENTRY waypoint" % variant_id)
	_check(fixture.operator.velocity == Vector2.ZERO, "%s reset retained Operator movement velocity" % variant_id)
	for waypoint_spec in [{"key": KEY_1, "cell": entry}, {"key": KEY_2, "cell": center}, {"key": KEY_3, "cell": north}]:
		var waypoint_key := InputEventKey.new()
		waypoint_key.pressed = true
		waypoint_key.keycode = waypoint_spec.key
		fixture._input(waypoint_key)
		_check((fixture.operator.global_position / TILE_SIZE).floor() == Vector2(waypoint_spec.cell), "%s waypoint key %s failed" % [variant_id, waypoint_spec.key])
	var f1 := InputEventKey.new()
	f1.pressed = true
	f1.keycode = KEY_F1
	fixture._input(f1)
	_check(fixture.collider_overlay.visible, "%s F1 did not toggle actual-shape collider overlay" % variant_id)
	fixture._input(f1)
	_check(not fixture.collider_overlay.visible, "%s F1 did not turn collider overlay off" % variant_id)
	var f2 := InputEventKey.new()
	f2.pressed = true
	f2.keycode = KEY_F2
	fixture._input(f2)
	_check(fixture.grid_overlay.visible, "%s F2 did not toggle 32px grid overlay" % variant_id)
	fixture._input(f2)
	_check(not fixture.grid_overlay.visible, "%s F2 did not turn grid overlay off" % variant_id)
	var f3 := InputEventKey.new()
	f3.pressed = true
	f3.keycode = KEY_F3
	fixture._input(f3)
	_check(not fixture.values_label.visible, "%s F3 did not hide read-only values" % variant_id)
	fixture._input(f3)
	_check(fixture.values_label.visible, "%s F3 did not show read-only values" % variant_id)


func _operator_shape_clear(fixture: CarrowMachineHouseScaleFixture, cell: Vector2i) -> bool:
	var shape_node := fixture.operator.get_node("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return false
	var center := Vector2(cell * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = Transform2D(fixture.operator.global_rotation, center + shape_node.position)
	query.collision_mask = 1
	query.margin = 0.0
	query.exclude = [fixture.operator.get_rid()]
	var state := fixture.get_world_2d().direct_space_state
	return state.intersect_shape(query, 16).is_empty()


func _equipment_owner(cell: Vector2i, size: Vector2i) -> String:
	var rects := _expected_rects(size)
	for item in rects:
		if (item.rect as Rect2i).has_point(cell):
			return String(item.owner)
	return ""


func _expected_rects(size: Vector2i) -> Array[Dictionary]:
	return [
		{"owner": "nw_relay", "rect": Rect2i(3, 3, 6, 4)},
		{"owner": "ne_switchgear", "rect": Rect2i(size.x - 9, 3, 6, 4)},
		{"owner": "sw_service", "rect": Rect2i(3, size.y - 8, 5, 3)},
		{"owner": "se_power", "rect": Rect2i(size.x - 8, size.y - 8, 5, 3)},
	]


func _expected_art_anchor(name: String, size: Vector2i) -> Vector2i:
	match name:
		"NorthWallPanelled": return Vector2i((size.x >> 1) - 5, 2)
		"NorthWallConduit": return Vector2i((size.x >> 1) + 3, 2)
		"WestWall": return Vector2i(1, size.y >> 1)
		"EastWall": return Vector2i(size.x - 1, size.y >> 1)
		"SouthDoorway": return Vector2i((size.x >> 1) - 1, size.y)
		"RelayBank": return Vector2i(4, 4)
		"Switchgear": return Vector2i(size.x - 7, 4)
		"PartsLocker": return Vector2i(3, size.y - 7)
		"Workbench": return Vector2i(6, size.y - 7)
		"ServiceCabinet": return Vector2i(4, size.y - 5)
		"ReplacementModules": return Vector2i(7, size.y - 6)
		"ConduitJunction": return Vector2i(size.x - 5, size.y >> 1)
		"PowerCabinet": return Vector2i(size.x - 5, size.y - 6)
	return Vector2i(-999, -999)


func _art_overlap_summary(art_records: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for art in art_records:
		if not art.walkable_cells_covered_by_art_rect.is_empty():
			result.append({"name": art.name, "anchor_tile": art.anchor_tile, "walkable_cells": art.walkable_cells_covered_by_art_rect})
	return result


func _write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "unable to open evidence file %s" % path)
	if file == null:
		return
	file.store_string(JSON.stringify(_json_safe(value), "\t") + "\n")
	file.close()


func _json_safe(value: Variant) -> Variant:
	if value is Vector2i:
		return [value.x, value.y]
	if value is Vector2:
		return [value.x, value.y]
	if value is Rect2i:
		return {"position": _json_safe(value.position), "size": _json_safe(value.size)}
	if value is Rect2:
		return {"position": _json_safe(value.position), "size": _json_safe(value.size)}
	if value is StringName:
		return String(value)
	if value is Dictionary:
		var converted := {}
		for key in value:
			converted[String(key) if key is StringName else key] = _json_safe(value[key])
		return converted
	if value is Array:
		var converted: Array = []
		for item in value:
			converted.append(_json_safe(item))
		return converted
	return value


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed.append(message)
