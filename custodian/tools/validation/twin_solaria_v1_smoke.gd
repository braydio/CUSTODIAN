extends SceneTree

const V1_SCENE := preload("res://scenes/twin_solaria_v1.tscn")
const LEGACY_SCENE := preload("res://scenes/twin_solaria_backdrop_test.tscn")
const MASTER_SIZE := Vector2(2048.0, 1536.0)
const PLATES := {
	"SolariumIAcquisitionCourt": {"size": Vector2(617, 695), "position": Vector2(-687.5, -335.5)},
	"UpperCrownCourt": {"size": Vector2(697, 520), "position": Vector2(-90.5, -328.0)},
	"AuthorityThresholdPlate": {"size": Vector2(375, 355), "position": Vector2(-101.5, -35.5)},
	"ReciprocityMidcourt": {"size": Vector2(1190, 525), "position": Vector2(-19.0, 144.5)},
	"HomeIndexLowercourt": {"size": Vector2(825, 385), "position": Vector2(-71.5, 489.5)},
	"WestServiceTerrace": {"size": Vector2(275, 340), "position": Vector2(-536.5, 412.0)},
	"EastServiceTerrace": {"size": Vector2(275, 340), "position": Vector2(473.5, 412.0)},
	"CrownCauseway": {"size": Vector2(245, 216), "position": Vector2(-91.5, 660.0)},
}


func _initialize() -> void:
	var failures: Array[String] = []
	var scene := V1_SCENE.instantiate()
	root.add_child(scene)
	await process_frame

	var underlay := scene.get_node_or_null("FidelityUnderlay") as Sprite2D
	if underlay == null or underlay.texture == null:
		failures.append("fidelity underlay is missing")
	elif Vector2(underlay.texture.get_size()) != MASTER_SIZE:
		failures.append("fidelity underlay is not the native 2048x1536 master")
	if scene.scale != Vector2.ONE:
		failures.append("production scene root is scaled")
	if not scene.has_method("get_camera_bounds"):
		failures.append("production map bounds API is missing")
	elif scene.call("get_camera_bounds") != Rect2(-MASTER_SIZE * 0.5, MASTER_SIZE):
		failures.append("production map bounds do not match the master envelope")

	for plate_name in PLATES:
		var plate := scene.get_node_or_null("EnvironmentPlates/%s" % plate_name) as Sprite2D
		if plate == null or plate.texture == null:
			failures.append("plate is missing: %s" % plate_name)
			continue
		var expected: Dictionary = PLATES[plate_name]
		if Vector2(plate.texture.get_size()) != expected["size"]:
			failures.append("plate dimensions differ from tracker: %s" % plate_name)
		if plate.position != expected["position"] or plate.scale != Vector2.ONE:
			failures.append("plate registration or scale differs from manifest: %s" % plate_name)
		if plate.texture.resource_path.contains("asset_drop/"):
			failures.append("plate references asset_drop: %s" % plate_name)

	var legacy := LEGACY_SCENE.instantiate()
	root.add_child(legacy)
	await process_frame
	var legacy_background := legacy.get_node_or_null("World/TwinSolariaBackdrop/Background") as Sprite2D
	if legacy_background == null or legacy_background.texture == null:
		failures.append("legacy development preview backdrop is missing")
	elif Vector2(legacy_background.texture.get_size()) != legacy.get_camera_bounds().size:
		failures.append("legacy development preview bounds no longer follow its backdrop")
	if legacy.get_node_or_null("World/TwinSolariaBackdrop/PerimeterCollision") == null:
		failures.append("legacy development preview perimeter collision is missing")
	if not legacy.has_method("get_test_snapshot"):
		failures.append("legacy development preview marker is missing")
	else:
		var snapshot: Dictionary = legacy.call("get_test_snapshot")
		if not bool(snapshot.get("development_backdrop", false)):
			failures.append("legacy preview is not marked development-only")

	if failures.is_empty():
		print("Twin Solaria V1 smoke: PASS")
	else:
		for failure in failures:
			push_error("Twin Solaria V1 smoke: %s" % failure)
	legacy.queue_free()
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
