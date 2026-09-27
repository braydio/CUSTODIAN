extends SceneTree

const SCENE := preload("res://game/world/levels/authored/hub/twin_solaria/twin_solaria.tscn")
const PLAYTEST_SCENE := preload("res://game/world/levels/authored/hub/twin_solaria/twin_solaria_playtest.tscn")
const LAYOUT := preload("res://game/world/levels/authored/hub/twin_solaria/twin_solaria_layout.gd")
const LEVEL_BASE := preload("res://game/world/levels/authored_level_2d.gd")
const REGISTRY := preload("res://game/world/levels/level_registry.gd")
const EXPECTED_PLATES := {
	"solarium_i_acquisition_court": {"size": Vector2i(617, 695), "position": Vector2(-687.5, -335.5)},
	"upper_crown_court": {"size": Vector2i(697, 520), "position": Vector2(-90.5, -328.0)},
	"authority_threshold_plate": {"size": Vector2i(375, 355), "position": Vector2(-101.5, -35.5)},
	"reciprocity_midcourt": {"size": Vector2i(1190, 525), "position": Vector2(-19.0, 144.5)},
	"home_index_lowercourt": {"size": Vector2i(825, 385), "position": Vector2(-71.5, 489.5)},
	"west_service_terrace": {"size": Vector2i(275, 340), "position": Vector2(-536.5, 412.0)},
	"east_service_terrace": {"size": Vector2i(275, 340), "position": Vector2(473.5, 412.0)},
	"crown_causeway": {"size": Vector2i(245, 216), "position": Vector2(-91.5, 660.0)},
}

var _failures: Array[String] = []


func _initialize() -> void:
	var level := SCENE.instantiate()
	root.add_child(level)
	await process_frame
	await physics_frame
	_check_level_contract(level)
	_check_visual_registration(level)
	_check_readouts(level)
	_check_authored_walkability(level)
	_check_production_source_paths()
	await _check_playtest_ownership()
	_report()
	level.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _check_level_contract(level: Node) -> void:
	if not level is LEVEL_BASE:
		_fail("production scene does not instantiate as AuthoredLevel2D")
	for forbidden in ["Operator", "Camera2D", "PlayerController"]:
		if level.find_child(forbidden, true, false) != null:
			_fail("production scene owns forbidden runtime node %s" % forbidden)
	if level.call("get_camera_bounds") != LAYOUT.WORLD_BOUNDS:
		_fail("camera bounds differ from TwinSolariaLayout")
	if not level.call("has_spawn", &"Spawn_CrownCauseway"):
		_fail("Spawn_CrownCauseway does not resolve")
	if not (level.call("get_spawn_position", &"Spawn_CrownCauseway") as Vector2).is_equal_approx(LAYOUT.SPAWN_CROWN_CAUSEWAY):
		_fail("Spawn_CrownCauseway position differs from layout authority")
	var registry = REGISTRY.new()
	if not bool(registry.call("load_index")):
		_fail("level registry failed: %s" % str(registry.call("get_errors")))
		return
	var definition = registry.call("get_level", &"hub_twin_solaria")
	if definition == null:
		_fail("hub_twin_solaria is not registered")
		return
	if not definition.call("validate").is_empty():
		_fail("registered Twin Solaria definition fails validation")
	if not definition.call("has_declared_spawn", &"Spawn_CrownCauseway"):
		_fail("registered definition omits Spawn_CrownCauseway")
	if definition.call("has_tag", &"world_ingress") or definition.get("ingress") != null:
		_fail("Twin Solaria is incorrectly registered for procgen world ingress")


func _check_visual_registration(level: Node) -> void:
	var underlay := level.get_node_or_null("UnderlayRoot/FidelityUnderlay") as Sprite2D
	if underlay == null or underlay.texture == null:
		_fail("exact fidelity underlay is missing")
	else:
		if Vector2i(underlay.texture.get_size()) != LAYOUT.MASTER_SIZE:
			_fail("fidelity underlay is not exactly 2048x1536")
		if not underlay.centered or underlay.position != Vector2.ZERO or underlay.scale != Vector2.ONE:
			_fail("fidelity underlay is not centered at origin at scale one")
	if level.scale != Vector2.ONE:
		_fail("production root is scaled")

	var sprite_count := 1
	for registration in LAYOUT.PLATES:
		var plate_id := String(registration["id"])
		var expected: Dictionary = EXPECTED_PLATES[plate_id]
		var layout_position: Vector2 = registration["position"]
		if registration["size"] != expected["size"] or layout_position != expected["position"]:
			_fail("TwinSolariaLayout locked source registration drifted: %s" % plate_id)
		var plate := level.get_node_or_null("PlayableRoot/PlateRoot/%s" % String(registration["node"])) as Sprite2D
		if plate == null or plate.texture == null:
			_fail("required gameplay plate is missing: %s" % plate_id)
			continue
		sprite_count += 1
		if Vector2i(plate.texture.get_size()) != expected["size"]:
			_fail("native gameplay plate dimensions differ: %s" % plate_id)
		if plate.position != layout_position or plate.scale != Vector2.ONE or not plate.centered:
			_fail("plate registration or scale differs from layout: %s" % plate_id)
		if plate.texture.resource_path != String(registration["path"]):
			_fail("plate is not bound to its canonical Asset V2 output: %s" % plate_id)
		if plate.texture.resource_path.contains("asset_drop/"):
			_fail("production plate references asset_drop: %s" % plate_id)
	var sprites := level.find_children("*", "Sprite2D", true, false)
	if sprites.size() != sprite_count:
		_fail("landmark/reference crops appear to be rendered over baked environment plates")


func _check_readouts(level: Node) -> void:
	for poi in LAYOUT.POIS:
		var name := "POI_" + String(poi["id"]).to_pascal_case()
		var interactable := level.get_node_or_null("POIRoot/%s" % name)
		if interactable == null:
			_fail("required dormant POI is missing: %s" % name)
			continue
		if interactable.global_position != LAYOUT.poi_position(poi):
			_fail("POI position differs from TwinSolariaLayout: %s" % name)
		if interactable.get_script() == null or interactable.get_script().resource_path != "res://game/world/interactions/world_readout_interactable.gd":
			_fail("POI does not use the shared read-only interaction contract: %s" % name)
	if bool(level.call("has_passage_activation")):
		_fail("V1 exposes strategic Passage activation")
	for retired in ["RouteSelection", "PassageActivation", "StrategicTravel"]:
		if level.find_child(retired, true, false) != null:
			_fail("V1 exposes retired route control %s" % retired)


func _check_authored_walkability(level: Node) -> void:
	var boundary := level.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null or boundary.get_child_count() < 12:
		_fail("authored Crown Verge boundary rails are missing")
		return
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState2D = level.get_world_2d().direct_space_state
	var spawn: Vector2 = LAYOUT.SPAWN_CROWN_CAUSEWAY + Vector2(0.0, 3.0)
	query.transform = Transform2D(0.0, spawn)
	if not space.intersect_shape(query, 8).is_empty():
		_fail("Operator-sized spawn probe overlaps authored collision")
	for y in range(650, -570, -32):
		query.transform = Transform2D(0.0, Vector2(-94.0, float(y) + 3.0))
		if not space.intersect_shape(query, 8).is_empty():
			_fail("authored boundary blocks the central walk spine at y=%d" % y)
			break


func _check_production_source_paths() -> void:
	for path in [
		"res://game/world/levels/authored/hub/twin_solaria/twin_solaria.gd",
		"res://game/world/levels/authored/hub/twin_solaria/twin_solaria_layout.gd",
		"res://game/world/levels/authored/hub/twin_solaria/twin_solaria_presentation.gd",
		"res://game/world/levels/authored/hub/twin_solaria/twin_solaria.tscn",
	]:
		if FileAccess.get_file_as_string(path).contains("asset_drop/"):
			_fail("production runtime source contains an asset_drop path: %s" % path)


func _check_playtest_ownership() -> void:
	var wrapper := PLAYTEST_SCENE.instantiate()
	root.add_child(wrapper)
	await process_frame
	for expected in ["Operator", "Camera2D", "PlayerController"]:
		if wrapper.get_node_or_null(expected) == null:
			_fail("standalone playtest wrapper does not own %s" % expected)
	if wrapper.get_node_or_null("Level/Operator") != null or wrapper.get_node_or_null("Level/Camera2D") != null:
		_fail("playtest actors were accidentally added to the production level")
	wrapper.queue_free()
	await process_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("Twin Solaria authored V1 smoke: PASS")
	else:
		for failure in _failures:
			push_error("Twin Solaria authored V1 smoke: %s" % failure)
