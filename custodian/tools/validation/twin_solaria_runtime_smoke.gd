extends SceneTree

const LEVEL_SCENE := preload("res://game/world/levels/authored/hub/twin_solaria/twin_solaria.tscn")
const EXPECTED_CANVAS := Vector2(2048, 1536)
const PLATE_POSITIONS := {
	"solarium_i_acquisition_court": Vector2(-687.5, -335.5),
	"upper_crown_court": Vector2(-90.5, -328),
	"authority_threshold_plate": Vector2(-101.5, -35.5),
	"reciprocity_midcourt": Vector2(-19, 144.5),
	"home_index_lowercourt": Vector2(-71.5, 489.5),
	"west_service_terrace": Vector2(-536.5, 412),
	"east_service_terrace": Vector2(473.5, 412),
	"crown_causeway": Vector2(-91.5, 660),
}
const PLATE_SIZES := {
	"solarium_i_acquisition_court": Vector2(617, 695),
	"upper_crown_court": Vector2(697, 520),
	"authority_threshold_plate": Vector2(375, 355),
	"reciprocity_midcourt": Vector2(1190, 525),
	"home_index_lowercourt": Vector2(825, 385),
	"west_service_terrace": Vector2(275, 340),
	"east_service_terrace": Vector2(275, 340),
	"crown_causeway": Vector2(245, 216),
}

func _initialize() -> void:
	var failures: Array[String] = []
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	if not (level is AuthoredLevel2D):
		_fail(failures, "production root does not extend AuthoredLevel2D")
	if level.camera_bounds.size != EXPECTED_CANVAS:
		_fail(failures, "runtime camera bounds differ from 2048x1536 source authority")
	var underlay := level.get_node_or_null("UnderlayRoot/FidelityUnderlay") as Sprite2D
	if underlay == null or underlay.texture == null or Vector2(underlay.texture.get_size()) != EXPECTED_CANVAS:
		_fail(failures, "fidelity underlay is missing or not native 2048x1536")
	for state: String in PLATE_SIZES:
		var node_name := String(state).to_pascal_case()
		var plate := level.get_node_or_null("BackgroundRoot/%s" % node_name) as Sprite2D
		if plate == null or plate.texture == null:
			_fail(failures, "required registered plate is missing: %s" % state)
			continue
		var size := Vector2(plate.texture.get_size())
		if size != PLATE_SIZES[state]:
			_fail(failures, "%s runtime texture dimensions differ from its crop" % state)
		if plate.scale != Vector2.ONE:
			_fail(failures, "%s is not rendered at native scale" % state)
		if plate.position != PLATE_POSITIONS[state]:
			_fail(failures, "%s registration differs from the placement manifest" % state)
	if not level.has_spawn(&"Spawn_CrownCauseway"):
		_fail(failures, "Crown Causeway spawn is not registered on the production level")
	if level.get_node_or_null("Collision/PathBoundaryCollision") == null:
		_fail(failures, "authored boundary collision body missing")
	else:
		var boundaries := level.get_node("Collision/PathBoundaryCollision").get_child_count()
		if boundaries < 30:
			_fail(failures, "authored boundary rail segments were not generated (%d)" % boundaries)
	if level.get_node_or_null("POIRoot/HomeIndexReadout") == null:
		_fail(failures, "Home Index dormant readout missing")
	if level.get_node_or_null("POIRoot/ReciprocityDialReadout") == null:
		_fail(failures, "Reciprocity Dial dormant readout missing")
	var registry_script := load("res://game/world/levels/level_registry.gd")
	var registry: RefCounted = registry_script.new()
	if not bool(registry.call("load_index")):
		_fail(failures, "level registry failed: %s" % str(registry.call("get_errors")))
	elif not bool(registry.call("has_level", &"hub_twin_solaria")):
		_fail(failures, "hub_twin_solaria is absent from the current level registry")
	elif not bool(registry.call("level_has_spawn", &"hub_twin_solaria", &"Spawn_CrownCauseway")):
		_fail(failures, "registry does not declare the Crown Causeway spawn")
	level.queue_free()
	await process_frame
	var playtest_scene := load("res://scenes/twin_solaria_playtest.tscn") as PackedScene
	var playtest := playtest_scene.instantiate()
	root.add_child(playtest)
	await process_frame
	await process_frame
	if playtest.get_node_or_null("World/Level") == null:
		_fail(failures, "standalone playtest wrapper does not instance the production level")
	var playtest_operator := playtest.get_node_or_null("World/Operator") as Node2D
	if playtest_operator == null:
		_fail(failures, "standalone playtest wrapper is missing its temporary Operator")
	elif playtest_operator.position != Vector2(-91.5, 660):
		_fail(failures, "playtest bootstrap did not place the Operator at Crown Causeway")
	if playtest.get_node_or_null("World/Camera2D") == null:
		_fail(failures, "standalone playtest wrapper is missing its shared camera")
	playtest.queue_free()
	await process_frame
	if failures.is_empty():
		print("Twin Solaria production runtime smoke: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("Twin Solaria production runtime smoke: %s" % failure)
	quit(1)

func _fail(failures: Array[String], message: String) -> void:
	failures.append(message)
