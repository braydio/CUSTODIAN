extends SceneTree

const SCENE_PATH := "res://game/world/levels/authored/dev/sepulcher_material_operator_v2/sepulcher_material_operator_v2.tscn"
const LEVEL_SCRIPT := preload("res://game/world/levels/authored/dev/sepulcher_material_operator_v2/sepulcher_material_operator_v2_level.gd")
const ROOT_TO_WORLD := Vector2(0.0, 18.0)
const BODY_PATHS := ["AnimatedSprite2D", "ModularLowerBodySprite", "ModularUpperBodySprite"]
const OVERLAY_PATHS := [
	"ModularSidearmSprite",
	"ModularUpperFxSprite",
	"DodgeFXBackSprite",
	"MeleeWeaponOverlaySprite",
	"MeleeFxOverlaySprite",
	"PrimaryWeaponSocket/PrimaryWeaponSprite",
	"PrimaryWeaponSocket/WeaponSprite",
	"PrimaryWeaponSocket/OffhandPropSprite",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		_fail("V2 standalone scene is missing")
		_report()
		return
	var packed := load(SCENE_PATH) as PackedScene
	var game_root := packed.instantiate() as Node2D if packed != null else null
	if game_root == null or game_root.name != "GameRoot":
		_fail("scene wrapper root must be GameRoot")
		_report()
		return
	root.add_child(game_root)
	var level := game_root.get_node("World/Level") as Node2D
	var operator := game_root.get_node("World/Operator") as CharacterBody2D
	var controller := game_root.get_node("World/PlayerController")
	var camera := game_root.get_node("World/Camera2D") as Camera2D
	var bootstrap := game_root.get_node("World/LevelPlaytestBootstrap")
	var preview := operator.get_node("CanonicalOperatorPresentation")
	var authored_spawn := Vector2(512, 520)
	var spawn_marker: Vector2 = level.call("get_spawn_position", &"Spawn_Main")
	if spawn_marker.distance_to(authored_spawn) > 0.01:
		_fail("authored Operator spawn marker moved from its declared coordinates")
	if bootstrap.get_meta("playtest_profile", "") != "full":
		_fail("normal full playtest bootstrap was not activated")
	if operator.global_position.distance_to(spawn_marker) > 0.01:
		_fail("bootstrap did not preserve authored Operator spawn at the ready boundary")
	for _frame in 6:
		await process_frame
	if operator.scene_file_path != "res://game/actors/operator/operator.tscn":
		_fail("preview must instance the real operator.tscn")
	if controller.get_node_or_null(controller.get("operator_path")) != operator:
		_fail("normal PlayerController must control the actual Operator")
	if level.get("camera_bounds") != Rect2(0, 0, 1024, 768):
		_fail("sandbox camera/gameplay bounds changed")
	if not camera.has_presentation_framing() or camera.get_presentation_bounds_override() != Rect2(0, 0, 1024, 768):
		_fail("dev-only camera framing/bounds were not scoped to this sandbox")
	if not is_equal_approx(camera.zoom.x, 1.25) or not is_equal_approx(camera.zoom.y, 1.25):
		_fail("camera effective zoom must be 1.25 in both axes")
	if operator.scale != Vector2.ONE:
		_fail("Operator world scale was changed to fit the preview")
	if game_root.get_node_or_null("World/DebugVaultStorage") != null:
		_fail("unrelated debug vault prop appeared in the scene")

	var blockout := level.get_node("NeutralBlockoutPresentation") as Node2D
	var courtyard := level.get_node("NativeCourtyardPresentation") as Node2D
	var repeat := level.get_node("RepeatDiagnosticPresentation") as Node2D
	var quiet := level.get_node("QuietModularPresentation") as Node2D
	var cells := quiet.get_node("MaterialCells") as Node2D
	var grout := quiet.get_node("CharcoalGrout") as Node2D
	var routes := quiet.get_node("BronzeInlayRoutes") as Node2D
	if courtyard.get_child_count() != 4 or repeat.get_child_count() != 4:
		_fail("modes 2 and 3 must retain exactly four original 512px pieces")
	_check_macro(courtyard, false)
	_check_macro(repeat, true)
	if cells.get_child_count() != 48:
		_fail("quiet material mode must contain exactly 48 cells")
	_check_material_cells(cells)
	if routes.get_child_count() != 4:
		_fail("quiet floor must contain exactly two dark/bronze route pairs")
	_check_bronze_routes(routes)
	if not level.call("are_inlays_enabled"):
		_fail("the two authored inlay routes should be visible by default")
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.QUIET_MODULAR:
		_fail("mode 4 quiet modular must be the default")
	if not preview.call("is_canonical_enabled"):
		_fail("approved 128px idle preview must be the default character art")
	if not String(level.get_node("PlaytestUI/AnimationCoverageLabel").text).contains("MOTION/COMBAT ART NOT AUTHORED"):
		_fail("unfinished 128px movement/combat art must be clearly labeled")
	_check_canonical_registration(operator, preview)
	_check_canonical_atlas(preview)
	_check_no_legacy_visible(operator)

	var navigation := level.get_node_or_null("NavigationRoot")
	if navigation == null or navigation.get_child_count() != 0:
		_fail("sandbox NavigationRoot must be present and empty")
	var boundary := level.get_node("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary.get_child_count() != 4:
		_fail("sandbox must retain its four fixed boundary rails")
	var collision_snapshot := _collision_snapshot(level)
	var start := operator.global_position
	Input.action_press("move_right")
	for _frame in 8:
		await physics_frame
	Input.action_release("move_right")
	if operator.global_position.distance_to(start) < 1.0:
		_fail("real Operator did not move with the normal gameplay controller")
	# Stop every source of actor motion before repositioning for presentation-only
	# assertions. Waiting with physics active made the old exact-position check
	# depend on the next controller/CharacterBody2D tick.
	Input.action_release("move_right")
	controller.set_process(false)
	controller.set_physics_process(false)
	operator.set_physics_process(false)
	operator.velocity = Vector2.ZERO
	operator.global_position = authored_spawn
	if operator.global_position.distance_to(authored_spawn) > 0.01:
		_fail("test could not restore the fixed preview player position")
	for _frame in 2:
		await physics_frame
	if operator.global_position.distance_to(authored_spawn) > 0.01:
		_fail("Operator moved after test physics and controller motion were disabled")

	# Presentation modes are floor-only and preserve the live actor/camera/collision/navigation.
	camera.set_process(false)
	camera.set_physics_process(false)
	var camera_transform := camera.global_transform
	var camera_zoom := camera.zoom
	var operator_transform := operator.global_transform
	for mode in [1, 2, 3, 4]:
		level.call("set_presentation_mode", mode)
		var roots := [blockout, courtyard, repeat, quiet]
		for index in roots.size():
			if roots[index].visible != (index + 1 == mode):
				_fail("floor mode %d selected unexpected presentation roots" % mode)
		if operator.global_transform != operator_transform:
			_fail("floor mode %d changed the real Operator transform" % mode)
		if camera.global_transform != camera_transform or camera.zoom != camera_zoom:
			_fail("floor mode %d changed camera framing" % mode)
		if _collision_snapshot(level) != collision_snapshot:
			_fail("floor mode %d changed collision geometry" % mode)
		if navigation.get_child_count() != 0:
			_fail("floor mode %d changed navigation ownership" % mode)

	level.call("_unhandled_input", _pressed_key(KEY_TAB))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.NATIVE_COURTYARD:
		_fail("Tab from mode 4 must select mode 2")
	level.call("_unhandled_input", _pressed_key(KEY_TAB))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.QUIET_MODULAR:
		_fail("Tab from mode 2 must select mode 4")
	level.call("_unhandled_input", _pressed_key(KEY_1))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.NEUTRAL_BLOCKOUT:
		_fail("1 must select neutral blockout")
	level.call("_unhandled_input", _pressed_key(KEY_3))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.REPEAT_NW_DIAGNOSTIC:
		_fail("3 must select NW repeat diagnostic")
	level.call("_unhandled_input", _pressed_key(KEY_4))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.QUIET_MODULAR:
		_fail("4 must select quiet modular floor")
	level.call("_unhandled_input", _pressed_key(KEY_B))
	if level.call("are_inlays_enabled"):
		_fail("B must toggle both quiet-floor bronze routes")
	level.call("_unhandled_input", _pressed_key(KEY_B))
	if not level.call("are_inlays_enabled"):
		_fail("B must restore both quiet-floor bronze routes")

	preview.call("set_canonical_enabled", false)
	await process_frame
	if preview.call("is_canonical_enabled") or not (operator.get_node("AnimatedSprite2D") as CanvasItem).visible:
		_fail("V legacy mode must show the live legacy Operator body")
	preview.call("set_canonical_enabled", true)
	for _frame in 3:
		await process_frame
	if not preview.call("is_canonical_enabled"):
		_fail("V canonical mode did not restore the approved idle preview")
	_check_no_legacy_visible(operator)
	if operator.global_transform != operator_transform or camera.global_transform != camera_transform or camera.zoom != camera_zoom:
		_fail("V character toggle changed gameplay coordinates or camera")
	if _collision_snapshot(level) != collision_snapshot:
		_fail("V character toggle changed collision")
	if str(ProjectSettings.get_setting("application/run/main_scene")) == SCENE_PATH:
		_fail("V2 preview must not replace the production main scene")

	game_root.free()
	_report()


func _check_macro(root_node: Node2D, repeated: bool) -> void:
	var centers := [Vector2(256, 256), Vector2(768, 256), Vector2(256, 768), Vector2(768, 768)]
	var names := ["native_paving_nw.png", "native_paving_ne.png", "native_paving_sw.png", "native_paving_se.png"]
	for index in root_node.get_child_count():
		var sprite := root_node.get_child(index) as Sprite2D
		if sprite == null or sprite.texture == null:
			_fail("macro floor child %d is not a textured Sprite2D" % index)
			continue
		if sprite.texture.get_size() != Vector2(512, 512) or sprite.position != centers[index] or sprite.scale != Vector2.ONE or not is_zero_approx(sprite.rotation):
			_fail("macro floor piece %s changed native size/registration" % sprite.name)
		if repeated:
			if sprite.texture.resource_path.get_file() != "native_paving_nw.png":
				_fail("repeat diagnostic must reuse only the original NW crop")
		elif sprite.texture.resource_path.get_file() != names[index]:
			_fail("native courtyard has unexpected source crop at index %d" % index)


func _check_material_cells(cells: Node2D) -> void:
	var basalt_count := 0
	for y in range(6):
		for x in range(8):
			var tile := cells.get_child(y * 8 + x) as Sprite2D
			var expect_basalt := (x * 7 + y * 11) % 11 < 2
			var expected_name := ("Basalt" if expect_basalt else "Limestone") + "_%d_%d" % [x, y]
			if expect_basalt:
				basalt_count += 1
			if tile == null or tile.name != expected_name:
				_fail("deterministic 8x6 material arrangement differs at %d,%d" % [x, y])
				continue
			var atlas := tile.texture as AtlasTexture
			var expected_region := Rect2(29, 332, 128, 128) if expect_basalt else Rect2(202, 227, 128, 128)
			if atlas == null or atlas.region != expected_region:
				_fail("tile %s does not use its exact source AtlasTexture region" % tile.name)
			if tile.position != Vector2(x * 128 + 64, y * 128 + 64) or tile.scale != Vector2.ONE:
				_fail("tile %s changed its native cell placement" % tile.name)
	if basalt_count == 0 or basalt_count >= 48:
		_fail("quiet floor must preserve both limestone and basalt material samples")


func _check_bronze_routes(routes: Node2D) -> void:
	var expected := [
		PackedVector2Array([Vector2(192, 192), Vector2(192, 320), Vector2(448, 320)]),
		PackedVector2Array([Vector2(704, 448), Vector2(832, 448), Vector2(832, 576)]),
	]
	for index in 2:
		var dark := routes.get_node("OxidizedGreenRoute_%d" % index) as Line2D
		var highlight := routes.get_node("BronzeHighlight_%d" % index) as Line2D
		if dark.points != expected[index] or dark.width != 4.0 or highlight.points != expected[index] or highlight.width != 1.0:
			_fail("bronze route %d differs from the two unique authored polylines" % index)


func _check_canonical_registration(operator: CharacterBody2D, preview: Node) -> void:
	var sprite := preview.call("get_canonical_sprite") as Sprite2D
	var legacy := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.scale != Vector2.ONE or sprite.rotation != 0.0:
		_fail("canonical body must stay 1px/world pixel, unrotated and unscaled")
	if sprite.position + Vector2(0, 106 - 64) != ROOT_TO_WORLD:
		_fail("canonical [64,106] root lost legacy-aligned world registration")
	var legacy_root := legacy.position + Vector2(0, 84 - 48)
	if legacy_root != ROOT_TO_WORLD:
		_fail("reference legacy body registration unexpectedly changed")


func _check_canonical_atlas(preview: Node) -> void:
	var sprite := preview.call("get_canonical_sprite") as Sprite2D
	var atlas := sprite.texture as AtlasTexture if sprite != null else null
	if atlas == null or atlas.region.size != Vector2(128, 128):
		_fail("canonical preview must display exact 128x128 atlas frames")
	var expected_row := int(preview.get("_direction_index"))
	if atlas != null and int(atlas.region.position.y) != expected_row * 128:
		_fail("canonical row must follow the actual eight-direction Operator state")


func _check_no_legacy_visible(operator: CharacterBody2D) -> void:
	for path in BODY_PATHS + OVERLAY_PATHS:
		var layer := operator.get_node_or_null(path) as CanvasItem
		if layer != null and layer.visible:
			_fail("canonical body mode leaves a legacy layer visible: %s" % path)


func _collision_snapshot(level: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var body := level.get_node("Collision/PathBoundaryCollision") as StaticBody2D
	for child in body.get_children():
		if child is CollisionShape2D:
			var shape := child as CollisionShape2D
			result.append({
				"name": str(shape.name),
				"position": shape.position,
				"rotation": shape.rotation,
				"shape": shape.shape.get_instance_id() if shape.shape != null else 0,
			})
	return result


func _pressed_key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "sepulcher_material_operator_v2",
		"passed": _failures.is_empty(),
		"failure_count": _failures.size(),
		"failures": _failures,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("sepulcher_material_operator_v2_smoke: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
