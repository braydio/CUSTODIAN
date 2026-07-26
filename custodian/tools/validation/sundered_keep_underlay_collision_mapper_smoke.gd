extends SceneTree

const MAPPER_SCENE_PATH := "res://scenes/debug/sundered_keep_underlay_collision_mapper.tscn"
const UNDERLAY_DEBUG_SCENE_PATH := "res://scenes/debug/sundered_keep_production_underlay_debug.tscn"
const PRODUCTION_SCENE_PATH := "res://game/world/sundered_keep/sundered_keep_map.tscn"
const COLLISION_DATA_PATH := "res://content/levels/sundered_keep/sundered_keep_underlay_collision.json"
const ROUTE_DATA_PATH := "res://content/routes/sundered_keep/sundered_keep_route.json"
const EXPECTED_UNDERLAY_PATH := "res://content/masters/sundered_keep/sundered_keep_main_overlay.png"

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var collision_data := _read_json(COLLISION_DATA_PATH)
	_assert(
		str(collision_data.get("schema", ""))
		== "custodian.sundered_keep.underlay_collision.v1",
		"canonical underlay collision schema is invalid"
	)
	var map_size_pixels: Array = collision_data.get("map_size_pixels", [])
	_assert(
		map_size_pixels.size() >= 2
		and is_equal_approx(float(map_size_pixels[0]), 3584.0)
		and is_equal_approx(float(map_size_pixels[1]), 2560.0),
		"canonical underlay collision map dimensions are not 3584x2560"
	)
	var debug_scene := await _instantiate_scene(UNDERLAY_DEBUG_SCENE_PATH)
	var production_scene := await _instantiate_scene(PRODUCTION_SCENE_PATH)
	if debug_scene != null and production_scene != null:
		_validate_collision_consumer(debug_scene, true, collision_data)
		_validate_collision_consumer(production_scene, false, collision_data)
		_validate_collision_parity(debug_scene, production_scene)
		_validate_production_markers(production_scene, collision_data)
	_validate_route_quarantine()
	await _validate_mapper_scene()
	if debug_scene != null:
		debug_scene.queue_free()
	if production_scene != null:
		production_scene.queue_free()
	await process_frame
	_finish()


func _instantiate_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	_assert(packed != null, "%s did not load" % path)
	if packed == null:
		return null
	var scene := packed.instantiate()
	_assert(scene != null, "%s did not instantiate" % path)
	if scene == null:
		return null
	root.add_child(scene)
	await process_frame
	await process_frame
	return scene


func _validate_collision_consumer(
	scene: Node,
	is_debug: bool,
	data: Dictionary
) -> void:
	var prefix := "World/" if is_debug else ""
	var mapped_root := scene.get_node_or_null(prefix + "MappedUnderlayBounds")
	var mapped_body := scene.get_node_or_null(
		prefix + "MappedUnderlayBounds/UnderlayBoundaryCollision"
	) as StaticBody2D
	_assert(mapped_root != null, "collision consumer missing MappedUnderlayBounds")
	_assert(mapped_body != null, "collision consumer missing UnderlayBoundaryCollision")
	if mapped_body == null:
		return
	var segments: Array = data.get("segments", [])
	_assert(
		mapped_body.get_child_count() == segments.size(),
		"collision consumer segment count does not match canonical JSON"
	)
	for shape_variant: Node in mapped_body.get_children():
		var shape := shape_variant as CollisionShape2D
		_assert(shape != null, "mapped boundary child is not a CollisionShape2D")
		if shape == null:
			continue
		_assert(shape.shape is CapsuleShape2D, "mapped boundary is not a capsule")
		_assert(shape.has_meta("boundary_a"), "mapped boundary missing boundary_a metadata")
		_assert(shape.has_meta("boundary_b"), "mapped boundary missing boundary_b metadata")
		_assert(
			str(shape.get_meta("collision_authority", "")) == "underlay_mapper",
			"mapped boundary does not identify mapper authority"
		)
	if is_debug:
		_assert(
			scene.call("get_underlay_collision_data") == data,
			"debug scene did not load canonical collision JSON"
		)
	else:
		var state := scene.call("get_sundered_keep_debug_state") as Dictionary
		_assert(
			state.get("underlay_texture_path", "") == EXPECTED_UNDERLAY_PATH,
			"production map does not use the approved main underlay"
		)
		_assert(
			state.get("map_size_tiles", Vector2i.ZERO) == Vector2i(112, 80),
			"production map dimensions are not 112x80"
		)
		_assert(
			scene.call("get_underlay_collision_data") == data,
			"production map did not load canonical collision JSON"
		)


func _validate_collision_parity(debug_scene: Node, production_scene: Node) -> void:
	var debug_body := debug_scene.get_node(
		"World/MappedUnderlayBounds/UnderlayBoundaryCollision"
	) as StaticBody2D
	var production_body := production_scene.get_node(
		"MappedUnderlayBounds/UnderlayBoundaryCollision"
	) as StaticBody2D
	if debug_body == null or production_body == null:
		return
	_assert(
		debug_body.get_child_count() == production_body.get_child_count(),
		"debug and production collision counts differ"
	)
	for index in range(mini(
		debug_body.get_child_count(),
		production_body.get_child_count()
	)):
		var debug_shape := debug_body.get_child(index) as CollisionShape2D
		var production_shape := production_body.get_child(index) as CollisionShape2D
		if debug_shape == null or production_shape == null:
			continue
		var debug_capsule := debug_shape.shape as CapsuleShape2D
		var production_capsule := production_shape.shape as CapsuleShape2D
		_assert(debug_shape.position.is_equal_approx(production_shape.position), "collision parity position mismatch at %d" % index)
		_assert(is_equal_approx(debug_shape.rotation, production_shape.rotation), "collision parity rotation mismatch at %d" % index)
		_assert(is_equal_approx(debug_capsule.radius, production_capsule.radius), "collision parity radius mismatch at %d" % index)
		_assert(is_equal_approx(debug_capsule.height, production_capsule.height), "collision parity height mismatch at %d" % index)
		_assert(debug_shape.get_meta("boundary_a") == production_shape.get_meta("boundary_a"), "collision parity boundary_a mismatch at %d" % index)
		_assert(debug_shape.get_meta("boundary_b") == production_shape.get_meta("boundary_b"), "collision parity boundary_b mismatch at %d" % index)


func _validate_production_markers(scene: Node, data: Dictionary) -> void:
	var markers: Dictionary = data.get("markers", {})
	var entry_spawn := scene.find_child("EntrySpawn", true, false) as Node2D
	var main_gate := scene.find_child("MainGateInteraction", true, false) as Node2D
	_assert(
		entry_spawn != null
		and entry_spawn.position.is_equal_approx(_marker_position(markers, "spawn")),
		"EntrySpawn does not match canonical spawn marker"
	)
	_assert(
		main_gate != null
		and main_gate.position.is_equal_approx(_marker_position(markers, "main_gate")),
		"Main Gate does not match canonical main_gate marker"
	)


func _validate_route_quarantine() -> void:
	var route := _read_json(ROUTE_DATA_PATH)
	var profiles_by_id := {}
	for profile_variant: Variant in route.get("profiles", []):
		var profile := profile_variant as Dictionary
		profiles_by_id[str(profile.get("profile_id", ""))] = profile
	var production: Dictionary = profiles_by_id.get("production", {})
	var expected := [
		"enter_vista",
		"vista_to_keep_direct",
		"vista_exfil",
		"keep_to_vista_direct",
		"keep_exfil",
	]
	_assert(
		production.get("enabled_edge_ids", []) == expected,
		"production route does not use the approved direct Keep graph"
	)
	for forbidden in [
		"vista_to_causeway",
		"causeway_to_keep",
		"causeway_to_vista",
		"keep_to_causeway",
		"enter_causeway_debug",
		"causeway_exfil_debug",
	]:
		_assert(
			not (production.get("enabled_edge_ids", []) as Array).has(forbidden),
			"production route enables quarantined edge %s" % forbidden
		)
	var causeway_only: Dictionary = profiles_by_id.get("causeway_only", {})
	_assert(
		causeway_only.get("enabled_edge_ids", [])
		== ["enter_causeway_debug", "causeway_exfil_debug"],
		"Return Causeway is not isolated to causeway_only"
	)


func _validate_mapper_scene() -> void:
	var scene := await _instantiate_scene(MAPPER_SCENE_PATH)
	if scene == null:
		return
	var help := scene.get_node_or_null("CanvasLayer/Help") as Label
	_assert(help != null and help.text.contains("Mode: COLLISION"), "mapper help missing collision mode")
	_assert(scene.has_method("_load_collision_document"), "mapper cannot load canonical JSON")
	_assert(scene.has_method("_write_collision_document"), "mapper cannot serialize canonical JSON")
	var data := scene.call("_load_collision_document") as Dictionary
	_assert(
		str(data.get("schema", ""))
		== "custodian.sundered_keep.underlay_collision.v1",
		"mapper did not read canonical collision JSON"
	)
	scene.queue_free()
	await process_frame


func _marker_position(markers: Dictionary, marker_id: String) -> Vector2:
	var marker: Dictionary = markers.get(marker_id, {})
	var position: Array = marker.get("position", [])
	return Vector2(float(position[0]), float(position[1])) if position.size() >= 2 else Vector2.ZERO


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SunderedKeepUnderlayCollisionMapperSmoke] PASS")
		quit(0)
		return
	print("[SunderedKeepUnderlayCollisionMapperSmoke] FAIL failures=%d" % _failures.size())
	quit(1)
