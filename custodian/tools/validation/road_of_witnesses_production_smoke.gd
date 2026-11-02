extends SceneTree

const SCENE := "res://scenes/hub_road_of_witnesses_prototype.tscn"
const SCRIPT := "res://game/world/hub/road_of_witnesses_prototype.gd"
const MODULES := [
	["south_reach_civic_axis", Vector2(768, 896)],
	["witness_plaza", Vector2(896, 896)],
	["collapsed_chapel_court", Vector2(768, 896)],
	["archive_ruin_west", Vector2(896, 896)],
	["overgrown_reliquary_east", Vector2(896, 896)],
]

var _failures: Array[String] = []

func _init() -> void:
	if not ResourceLoader.exists(SCENE):
		_fail("missing Road scene")
		_report()
		return
	var packed := load(SCENE) as PackedScene
	var road_scene := packed.instantiate()
	root.add_child(road_scene)
	await process_frame
	var road := road_scene.get_node_or_null("World/RoadOfWitnessesPrototype") as Node2D
	if road == null:
		_fail("standalone Road node missing")
	else:
		_check_road(road)
	road_scene.free()
	var source := FileAccess.get_file_as_string(SCRIPT)
	if source.contains("Road_of_Witnesses_Tilemap.png") or source.contains("MAP_TEXTURE_PATH") or source.contains("OCCLUSION_REGIONS"):
		_fail("production Road script still references monolithic presentation")
	_report()

func _check_road(road: Node2D) -> void:
	var modules := road.get_node_or_null("EnvironmentModules")
	if modules == null:
		_fail("EnvironmentModules missing")
		return
	if modules.get_child_count() != MODULES.size():
		_fail("expected %d modules, found %d" % [MODULES.size(), modules.get_child_count()])
	for entry in MODULES:
		var module_id: String = entry[0]
		var expected_size: Vector2 = entry[1]
		var module := modules.get_node_or_null(String(module_id).capitalize())
		if module == null:
			_fail("missing module: %s" % module_id)
			continue
		for layer_name in ["Underlay", "Foreground"]:
			var sprite := module.get_node_or_null(layer_name) as Sprite2D
			if sprite == null or sprite.texture == null:
				_fail("%s/%s missing texture" % [module_id, layer_name])
				continue
			if sprite.texture.get_size() != expected_size:
				_fail("%s/%s size %s != %s" % [module_id, layer_name, str(sprite.texture.get_size()), str(expected_size)])
			if not sprite.centered or sprite.scale != Vector2.ONE:
				_fail("%s/%s registration drift" % [module_id, layer_name])
			if layer_name == "Foreground" and sprite.z_index != 4:
				_fail("%s foreground z-index drift" % module_id)
	var bounds: Rect2 = road.get("_map_bounds")
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		_fail("aggregate Road bounds are empty")
	if road.get_node_or_null("CollisionRoot") == null:
		_fail("collision authority root missing")

func _fail(message: String) -> void:
	_failures.append(message)

func _report() -> void:
	var result := {"schema": "custodian.headless_test.result.v1", "test": "road_of_witnesses_production_smoke", "passed": _failures.is_empty(), "failure_count": _failures.size(), "failures": _failures}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("road_of_witnesses_production_smoke: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
