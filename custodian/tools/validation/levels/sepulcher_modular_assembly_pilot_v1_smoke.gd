extends SceneTree

const SCENE_PATH := "res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/sepulcher_modular_assembly_pilot_v1.tscn"
const LEVEL_SCRIPT := preload("res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/sepulcher_modular_assembly_pilot_v1_level.gd")
const CANONICAL_PATH := "res://game/world/levels/authored/dev/sepulcher_material_operator_v2/preview/operator_2_5d_idle_relaxed_8dir_15f_128.png"
const CANONICAL_SHA256 := "d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3"
const EXPECTED_CENTERS := [Vector2(256, 256), Vector2(768, 256), Vector2(256, 768), Vector2(768, 768)]
const EXPECTED_ROTATIONS := [0.0, 90.0, 180.0, 270.0]
const EXPECTED_TEXTURES := ["paving_base", "paving_base", "paving_base", "paving_base"]
const EXPECTED_DAMAGE_X := [256.0, 384.0, 512.0, 640.0, 768.0]
const EXPECTED_DAMAGE_Y := [320.0, 448.0, 576.0, 704.0]
const EXPECTED_DAMAGE_ROTATIONS := [0.0, 90.0, 180.0, 270.0]
const ROOT_TO_WORLD := Vector2(0.0, 18.0)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		_fail("four-asset pilot scene is missing")
		_report()
		return
	var packed := load(SCENE_PATH) as PackedScene
	var game_root := packed.instantiate() as Node2D if packed != null else null
	if game_root == null or game_root.name != "GameRoot":
		_fail("scene must reuse a standalone GameRoot wrapper")
		_report()
		return
	root.add_child(game_root)
	for _frame in 8:
		await process_frame

	var level := game_root.get_node("World/Level") as Node2D
	var operator := game_root.get_node("World/Operator") as CharacterBody2D
	var controller := game_root.get_node("World/PlayerController")
	var camera := game_root.get_node("World/Camera2D") as Camera2D
	var bootstrap := game_root.get_node("World/LevelPlaytestBootstrap")
	var preview := operator.get_node("CanonicalOperatorPresentation")
	var navigation := level.get_node_or_null("NavigationRoot")
	if operator.scene_file_path != "res://game/actors/operator/operator.tscn":
		_fail("pilot must instance the real operator.tscn")
	if controller.get_node_or_null(controller.get("operator_path")) != operator:
		_fail("normal PlayerController must own the real Operator")
	if bootstrap.get_meta("playtest_profile", "") != "full":
		_fail("full gameplay bootstrap is not active")
	if operator.global_position.distance_to(Vector2(512, 520)) > 0.01:
		_fail("Operator spawn differs from (512,520)")
	if operator.scale != Vector2.ONE:
		_fail("Operator world scale must remain one")
	if not camera.has_presentation_framing() or camera.get_presentation_bounds_override() != Rect2(0, 0, 1024, 768):
		_fail("V2 scoped gameplay camera bounds were not reused")
	if not is_equal_approx(camera.zoom.x, 1.25) or not is_equal_approx(camera.zoom.y, 1.25):
		_fail("camera comparison zoom must remain the V2 1.25 framing")
	if level.get("camera_bounds") != Rect2(0, 0, 1024, 768):
		_fail("pilot sandbox must remain 1024x768")
	if navigation == null or navigation.get_child_count() != 0:
		_fail("navigation must remain the unchanged empty V2 playtest provider")
	if game_root.get_node_or_null("World/DebugVaultStorage") != null:
		_fail("unrelated debug vault fallback appeared")
	if not preview.call("is_canonical_enabled"):
		_fail("canonical idle presentation must be visible by default")
	_check_operator_source(operator, preview)

	var assembly := level.get_node_or_null("FourAssetAssemblyPresentation") as Node2D
	if assembly == null:
		_fail("assembled presentation root is missing")
		_report()
		return
	var paving := assembly.get_node("PavingTiles") as Node2D
	var damage := assembly.get_node("DamageOverlays") as Node2D
	var ring := assembly.get_node("WitnessRing") as Sprite2D
	var wall := assembly.get_node("RetainingWallFullStrip") as Sprite2D
	var wall_diagnostic := assembly.get_node("WallModuleJoinDiagnostic") as Node2D
	if paving.get_child_count() != 4 or damage.get_child_count() != 3:
		_fail("assembly needs four base sprites and three deterministic damage instances")
	_check_paving(paving)
	_check_sprite_size(ring, Vector2(512, 512), "witness ring")
	if ring.position != Vector2(512, 384) or ring.scale != Vector2.ONE:
		_fail("one witness ring must anchor at (512,384) at native scale")
	_check_sprite_size(wall, Vector2(768, 239), "complete wall strip")
	if wall.position != Vector2(128, 1) or wall.centered or wall.scale != Vector2.ONE:
		_fail("full strip upper-left registration must remain (128,1), 1:1")
	if wall.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("wall strip must use nearest gameplay filtering")
	if wall_diagnostic.get_child_count() < 4:
		_fail("separate three-module wall join diagnostic is missing")
	for index in 3:
		var module := wall_diagnostic.get_child(index) as Sprite2D
		_check_sprite_size(module, Vector2(256, 128), "wall module join diagnostic %d" % index)
		if module.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or not is_zero_approx(module.rotation):
			_fail("wall module diagnostic %d changed its unrotated native source" % index)
	for index in damage.get_child_count():
		var sprite := damage.get_child(index) as Sprite2D
		_check_sprite_size(sprite, Vector2(512, 512), "damage overlay %d" % index)
		if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			_fail("damage overlay %d must use nearest filtering" % index)
	_check_damage_alpha()
	_check_deterministic_damage(level)
	_check_wall_alpha()

	var path_collision := level.get_node("Collision/PathBoundaryCollision") as StaticBody2D
	if path_collision == null or path_collision.get_child_count() != 5:
		_fail("outer sandbox boundary plus north wall must create five persistent collision rails")
	var north_wall_found := false
	for child in path_collision.get_children():
		if child is CollisionShape2D:
			var shape := child as CollisionShape2D
			if shape.get_meta("boundary_a", Vector2.INF) == Vector2(128, 240) and shape.get_meta("boundary_b", Vector2.INF) == Vector2(896, 240):
				north_wall_found = true
	if not north_wall_found:
		_fail("independent north wall collision is not registered from x=128..896 at y=240")
	var collision_snapshot := _collision_snapshot(level)
	var actor_id := operator.get_instance_id()
	var operator_position := operator.global_position
	var camera_transform := camera.global_transform
	var camera_zoom := camera.zoom
	var navigation_count := navigation.get_child_count()
	for mode in [1, 2, 3, 4, 5]:
		level.call("set_presentation_mode", mode)
		if int(level.call("get_presentation_mode")) != mode:
			_fail("mode %d was not retained" % mode)
		var expected_roots := {
			"NeutralBlockoutPresentation": mode == 1,
			"NativeCourtyardPresentation": mode == 2,
			"RepeatDiagnosticPresentation": mode == 3,
			"QuietModularPresentation": mode == 4,
			"FourAssetAssemblyPresentation": mode == 5,
		}
		for root_name in expected_roots:
			if bool(level.get_node(root_name).visible) != bool(expected_roots[root_name]):
				_fail("mode %d has incorrect visibility for %s" % [mode, root_name])
		if operator.get_instance_id() != actor_id or operator.global_position != operator_position:
			_fail("mode %d changed the same Operator instance or position" % mode)
		if camera.global_transform != camera_transform or camera.zoom != camera_zoom:
			_fail("mode %d changed Camera2D state" % mode)
		if _collision_snapshot(level) != collision_snapshot:
			_fail("mode %d changed collision authority" % mode)
		if navigation.get_child_count() != navigation_count:
			_fail("mode %d changed navigation state" % mode)
		if (path_collision.get_child(4) as CollisionShape2D).disabled:
			_fail("wall collision became disabled in mode %d" % mode)

	level.call("set_presentation_mode", 4)
	level.call("_unhandled_input", _pressed_key(KEY_TAB))
	if int(level.call("get_presentation_mode")) != 2:
		_fail("Tab from mode 4 must select native courtyard mode 2")
	level.call("_unhandled_input", _pressed_key(KEY_TAB))
	if int(level.call("get_presentation_mode")) != 4:
		_fail("Tab from mode 2 must select quiet modular mode 4")
	level.call("_unhandled_input", _pressed_key(KEY_M))
	if int(level.call("get_presentation_mode")) != 5:
		_fail("M from mode 4 must select four-asset mode 5")
	level.call("_unhandled_input", _pressed_key(KEY_M))
	if int(level.call("get_presentation_mode")) != 4:
		_fail("M from mode 5 must select quiet modular mode 4")
	level.call("_unhandled_input", _pressed_key(KEY_U))
	if level.call("is_rotated_paving_enabled") or _paving_has_rotation(paving):
		_fail("U must toggle the entire paving set to a zero-rotation seam comparison")
	level.call("_unhandled_input", _pressed_key(KEY_U))
	if not level.call("is_rotated_paving_enabled"):
		_fail("U must restore the deterministic orthogonal rotation cohort")
	level.call("_unhandled_input", _pressed_key(KEY_D))
	if level.call("is_damage_enabled") or damage.visible:
		_fail("D must hide damage without changing collision")
	level.call("_unhandled_input", _pressed_key(KEY_R))
	if level.call("is_ring_enabled") or ring.visible:
		_fail("R must hide the single witness ring")
	level.call("_unhandled_input", _pressed_key(KEY_V))
	if preview.call("is_canonical_enabled"):
		_fail("V must switch from canonical idle to the real legacy Operator presentation")
	level.call("_unhandled_input", _pressed_key(KEY_V))
	if not preview.call("is_canonical_enabled"):
		_fail("V must restore the canonical idle presenter")
	level.call("_unhandled_input", _pressed_key(KEY_W))
	if level.call("is_wall_art_enabled") or wall.visible or path_collision.get_child_count() != 5:
		_fail("W must hide only wall artwork while its collision remains active")
	level.call("_unhandled_input", _pressed_key(KEY_J))
	if not level.call("is_wall_join_diagnostic_enabled") or wall_diagnostic.visible:
		_fail("J diagnostic toggle must remain subordinate to hidden wall artwork")
	level.call("_unhandled_input", _pressed_key(KEY_W))
	level.call("_unhandled_input", _pressed_key(KEY_J))
	if not wall.visible or wall_diagnostic.visible:
		_fail("W/J must restore the full wall strip without replacing it by modules")
	level.call("_unhandled_input", _pressed_key(KEY_D))
	level.call("_unhandled_input", _pressed_key(KEY_R))
	if _collision_snapshot(level) != collision_snapshot:
		_fail("art overlay toggles changed collision geometry")

	# Exercise the actual Operator controller once in open space and once into the wall.
	var start_position := operator.global_position
	Input.action_press("move_right")
	for _frame in 18:
		await physics_frame
	Input.action_release("move_right")
	if operator.global_position.distance_to(start_position) < 1.0:
		_fail("real Operator did not move under ordinary native gameplay input")
	operator.velocity = Vector2.ZERO
	operator.global_position = Vector2(512, 330)
	for _frame in 2:
		await physics_frame
	Input.action_press("move_up")
	for _frame in 60:
		await physics_frame
	Input.action_release("move_up")
	if operator.global_position.y < 240.0 or operator.global_position.y > 275.0:
		_fail("Operator crossed the north wall or could not reach its contact boundary: y=%s" % operator.global_position.y)
	if absf(operator.global_position.x - 512.0) > 2.0:
		_fail("north wall approach drifted outside the clear central contact path")
	operator.velocity = Vector2.ZERO
	operator.global_position = Vector2(512, 520)
	for _frame in 2:
		await physics_frame
	if operator.global_position.distance_to(Vector2(512, 520)) > 0.01:
		_fail("Operator could not return to the clear authored spawn path")
	if str(ProjectSettings.get_setting("application/run/main_scene")) == SCENE_PATH:
		_fail("dev pilot must not replace the production main scene")

	game_root.queue_free()
	await process_frame
	_report()


func _check_operator_source(operator: CharacterBody2D, preview: Node) -> void:
	var image_bytes := FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(CANONICAL_PATH))
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(image_bytes)
	if hashing.finish().hex_encode() != CANONICAL_SHA256:
		_fail("canonical idle art SHA-256 differs from the approved 128px source")
	var canonical := preview.call("get_canonical_sprite") as Sprite2D
	var atlas := canonical.texture as AtlasTexture if canonical != null else null
	if atlas == null or atlas.region.size != Vector2(128, 128):
		_fail("canonical presenter must display native 128x128 atlas cells")
	if canonical != null and (canonical.scale != Vector2.ONE or canonical.position + Vector2(0, 42) != ROOT_TO_WORLD):
		_fail("canonical presentation lost its exact scale or [64,106] registration")
	if operator.scene_file_path != "res://game/actors/operator/operator.tscn":
		_fail("canonical preview must remain attached to the real Operator")
	if not String(preview.get("canonical_idle_sheet").resource_path).ends_with("operator_2_5d_idle_relaxed_8dir_15f_128.png"):
		_fail("canonical presenter is not bound to the V2 accepted idle-only resource")
	if String(preview.call("get_direction_name")) == "":
		_fail("canonical preview has no resolved directional idle row")


func _check_paving(paving: Node2D) -> void:
	for index in paving.get_child_count():
		var sprite := paving.get_child(index) as Sprite2D
		if sprite == null:
			_fail("assembly paving child %d is not a Sprite2D" % index)
			continue
		_check_sprite_size(sprite, Vector2(512, 512), "paving tile %d" % index)
		if sprite.position != EXPECTED_CENTERS[index] or sprite.scale != Vector2.ONE:
			_fail("paving tile %s changed native 1:1 placement" % sprite.name)
		if not is_equal_approx(sprite.rotation_degrees, EXPECTED_ROTATIONS[index]):
			_fail("paving tile %s lost its deterministic orthogonal rotation" % sprite.name)
		if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			_fail("paving tile %s is not nearest-filtered" % sprite.name)
		if sprite.texture.resource_path.get_file().get_basename() != EXPECTED_TEXTURES[index]:
			_fail("paving tile %s uses an unexpected normalized base resource" % sprite.name)


func _check_deterministic_damage(level: Node) -> void:
	var first: Array = level.call("get_damage_layout")
	var second: Array = level.call("get_damage_layout")
	if int(level.call("get_damage_seed")) != 11012026 or first.size() != 3 or first != second:
		_fail("damage seed/layout is absent or changes between reads")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11012026
	var expected: Array[Dictionary] = []
	for _index in 3:
		expected.append({
			"position": Vector2(
				EXPECTED_DAMAGE_X[rng.randi_range(0, EXPECTED_DAMAGE_X.size() - 1)],
				EXPECTED_DAMAGE_Y[rng.randi_range(0, EXPECTED_DAMAGE_Y.size() - 1)]
			),
			"rotation_degrees": EXPECTED_DAMAGE_ROTATIONS[rng.randi_range(0, EXPECTED_DAMAGE_ROTATIONS.size() - 1)],
			"flip_h": rng.randi_range(0, 1) == 1,
			"flip_v": rng.randi_range(0, 1) == 1,
		})
	if first != expected:
		_fail("damage placement/rotation cohort is not derived from the stable seed")
	for index in first.size():
		var sprite := (level.get_node("FourAssetAssemblyPresentation/DamageOverlays") as Node2D).get_child(index) as Sprite2D
		var placement: Dictionary = first[index]
		if sprite.position != placement.position or not is_equal_approx(sprite.rotation_degrees, float(placement.rotation_degrees)):
			_fail("damage sprite %d differs from its seeded placement" % index)


func _check_damage_alpha() -> void:
	var image := Image.new()
	var image_error := image.load(ProjectSettings.globalize_path("res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/preview/generated/paving_damage_overlay.png"))
	if image_error != OK or image.is_empty() or image.get_size() != Vector2i(512, 512):
		_fail("normalized damage source must load as a 512x512 RGBA image")
		return
	var transparent := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a == 0.0:
				transparent += 1
	if float(transparent) / float(image.get_width() * image.get_height()) < 0.7:
		_fail("damage source has less than 70 percent fully transparent pixels")


func _check_wall_alpha() -> void:
	var image := Image.new()
	var image_error := image.load(ProjectSettings.globalize_path("res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/preview/generated/retaining_wall_full_strip_768.png"))
	if image_error != OK or image.is_empty() or image.get_size() != Vector2i(768, 239):
		_fail("full wall strip must load as its native 768x239 RGBA composition")
		return
	if image.get_pixel(0, 0).a != 0.0 or image.get_pixel(767, 0).a != 0.0:
		_fail("wall strip transparent exterior corners indicate an opaque checkerboard or matte")
	if image.get_pixel(384, 238).a == 0.0:
		_fail("full wall strip lacks its visible lower contact baseline")


func _check_sprite_size(sprite: Sprite2D, expected: Vector2, label: String) -> void:
	if sprite == null or sprite.texture == null or sprite.texture.get_size() != expected:
		_fail("%s expected native texture size %s" % [label, expected])


func _paving_has_rotation(paving: Node2D) -> bool:
	for sprite in paving.get_children():
		if not is_zero_approx((sprite as Sprite2D).rotation):
			return true
	return false


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
				"shape_id": shape.shape.get_instance_id() if shape.shape != null else 0,
				"disabled": shape.disabled,
				"a": shape.get_meta("boundary_a", Vector2.INF),
				"b": shape.get_meta("boundary_b", Vector2.INF),
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
		"test": "sepulcher_modular_assembly_pilot_v1",
		"passed": _failures.is_empty(),
		"failure_count": _failures.size(),
		"failures": _failures,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("sepulcher_modular_assembly_pilot_v1_smoke: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
