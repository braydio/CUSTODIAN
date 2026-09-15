extends SceneTree

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const BASELINE := preload("res://content/lighting/profiles/awakening/awakening_baseline.tres")
const DUST := preload("res://content/lighting/profiles/awakening/awakening_dust_lung_failing_daylight.tres")
const THRESHOLD := preload("res://content/lighting/profiles/awakening/awakening_undergate_threshold.tres")
const CORE := preload("res://content/lighting/profiles/awakening/awakening_undergate_core.tres")
const NORTH := preload("res://content/lighting/profiles/awakening/awakening_undergate_north_threshold.tres")
const Layout := preload("res://game/world/awakening/awakening_layout.gd")

var failures: Array[String] = []


func _init() -> void:
	var scene := SCENE.instantiate()
	_check_world_stack(scene)
	_check_profiles()
	_check_authored_lighting(scene)
	_check_spatial_and_asset_contracts()
	_check_flashlight(scene)
	scene.free()
	_finish()


func _check_world_stack(scene: Node) -> void:
	var directors := scene.find_children("*", "WorldLightingDirector", true, false)
	_expect(directors.size() == 1, "Awakening must contain exactly one WorldLightingDirector")
	_expect(scene.get_node_or_null("World/Lighting/CanvasModulate") is CanvasModulate, "Awakening CanvasModulate missing")
	_expect(scene.get_node_or_null("World/Lighting/DirectionalLight2D") is DirectionalLight2D, "Awakening DirectionalLight2D missing")
	if directors.size() == 1:
		_expect(directors[0].default_profile == BASELINE, "Awakening default lighting profile must be awakening_baseline")


func _check_profiles() -> void:
	for profile in [BASELINE, DUST, THRESHOLD, CORE, NORTH]:
		_expect(profile != null, "an authored Awakening lighting profile failed to load")
	_expect(_luminance(DUST.ambient_color) > _luminance(THRESHOLD.ambient_color), "Dust Lung must be brighter than the Undergate threshold")
	_expect(_luminance(THRESHOLD.ambient_color) > _luminance(CORE.ambient_color), "Undergate threshold must be brighter than its core")
	_expect(_luminance(CORE.ambient_color) > 0.05, "Undergate core ambient must remain non-black")
	_expect(_luminance(NORTH.ambient_color) > _luminance(CORE.ambient_color), "north threshold must lift above the core")
	for profile in [BASELINE, DUST, THRESHOLD, CORE, NORTH]:
		_expect(is_zero_approx(profile.environment_influence), "Awakening profiles must resist environment influence")
		_expect(is_zero_approx(profile.weather_influence), "Awakening profiles must resist weather influence")


func _check_authored_lighting(scene: Node) -> void:
	var root := scene.get_node_or_null("World/AwakeningZones/Zone06_Undergate/Lighting")
	_expect(root != null, "Undergate authored lighting scene is not instanced")
	if root == null:
		return
	var expected_zones := {
		"DustLungFade": [Vector2(0, -3584), Vector2(896, 384), 10],
		"SouthThreshold": [Vector2(0, -3920), Vector2(768, 416), 20],
		"MechanismHallCore": [Vector2(0, -4384), Vector2(1344, 640), 30],
		"NorthThreshold": [Vector2(0, -4752), Vector2(768, 288), 40],
	}
	for zone_name in expected_zones:
		var zone := root.get_node_or_null("Zones/%s" % zone_name) as LightingZone2D
		var expected: Array = expected_zones[zone_name]
		_expect(zone != null, "missing lighting zone %s" % zone_name)
		if zone == null:
			continue
		_expect(zone.position == expected[0], "%s position drifted" % zone_name)
		_expect(zone.profile_priority == expected[2], "%s priority drifted" % zone_name)
		var shape := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
		_expect(shape != null and shape.shape is RectangleShape2D and shape.shape.size == expected[1], "%s bounds drifted" % zone_name)
	var lights := root.get_node("LocalLightPools").find_children("*", "PointLight2D", true, false)
	_expect(lights.size() == 4, "Undergate must keep a deliberate four-light local pool budget")
	for light in lights:
		_expect(light.texture != null, "%s must use an authored light cookie" % light.name)
	var occluders := root.get_node("MajorOccluders").find_children("*", "LightOccluder2D", true, false)
	_expect(occluders.size() == 6, "Undergate must contain six major-geometry occluders")
	for occluder in occluders:
		_expect(occluder.occluder != null, "%s has no occluder polygon" % occluder.name)


func _check_spatial_and_asset_contracts() -> void:
	var zone := Layout.zone_by_id(&"zone06_undergate")
	_expect(zone.get("envelope") == Rect2(-704, -4864, 1408, 1088), "Zone06 envelope was not widened")
	_expect(zone.get("entry") == Vector2(0, -3776) and zone.get("exit") == Vector2(0, -4864), "Zone06 route anchors changed")
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/metadata/assets/families/awakening_undergate_environment.asset.json"))
	_expect(json is Dictionary, "Undergate environment family JSON failed to parse")
	if json is Dictionary:
		_expect(json.canvas.width == 1536 and json.canvas.height == 1216, "Undergate environment canvas must be 1536x1216")
		_expect(json.states.underlay.frame_width == 1536 and json.states.foreground.frame_width == 1536, "Undergate state widths must match the canvas")


func _check_flashlight(scene: Node) -> void:
	var flashlights := scene.find_children("OperatorFlashlight", "Node2D", true, false)
	_expect(flashlights.size() == 1, "production Operator flashlight must remain present")
	var flashlight_source := FileAccess.get_file_as_string("res://game/actors/operator/components/operator_flashlight.gd").to_lower()
	for forbidden in ["battery", "charge_meter", "resource_consumption"]:
		_expect(not flashlight_source.contains(forbidden), "Undergate work introduced forbidden flashlight resource behavior: %s" % forbidden)


func _luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("awakening_undergate_lighting_smoke: " + message)


func _finish() -> void:
	if failures.is_empty():
		print("AWAKENING_UNDERGATE_LIGHTING_SMOKE: PASS")
		quit(0)
	else:
		print("AWAKENING_UNDERGATE_LIGHTING_SMOKE: FAIL (%d)" % failures.size())
		quit(1)
