extends SceneTree

const RIG_SCENE := preload("res://game/actors/enemies/visuals/humanoid_cutout_rig_2d.tscn")
const TEST_ENEMY_SCENE := preload("res://game/actors/enemies/dev/enemy_humanoid_cutout_test.tscn")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const SKIN_PATH := "res://content/sprites/enemies/enemy_humanoid_cutout_test/runtime/body/rig/enemy_humanoid_cutout_test_humanoid_rig_skin.tres"

const REQUIRED_NODE_PATHS := [
	"MotionRoot/PelvisPivot/PelvisSprite",
	"MotionRoot/PelvisPivot/CapePivot/CapeSprite",
	"MotionRoot/PelvisPivot/BackAttachmentPivot/BackAttachmentSprite",
	"MotionRoot/PelvisPivot/TorsoPivot/TorsoSprite",
	"MotionRoot/PelvisPivot/TorsoPivot/HeadPivot/HeadSprite",
	"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackUpperArmSprite",
	"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackForearmPivot/BackForearmSprite",
	"MotionRoot/PelvisPivot/TorsoPivot/BackUpperArmPivot/BackForearmPivot/BackHandPivot/BackHandSprite",
	"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontUpperArmSprite",
	"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontForearmPivot/FrontForearmSprite",
	"MotionRoot/PelvisPivot/TorsoPivot/FrontUpperArmPivot/FrontForearmPivot/FrontHandPivot/FrontHandSprite",
	"MotionRoot/PelvisPivot/BackThighPivot/BackThighSprite",
	"MotionRoot/PelvisPivot/BackThighPivot/BackShinPivot/BackShinSprite",
	"MotionRoot/PelvisPivot/BackThighPivot/BackShinPivot/BackFootPivot/BackFootSprite",
	"MotionRoot/PelvisPivot/FrontThighPivot/FrontThighSprite",
	"MotionRoot/PelvisPivot/FrontThighPivot/FrontShinPivot/FrontShinSprite",
	"MotionRoot/PelvisPivot/FrontThighPivot/FrontShinPivot/FrontFootPivot/FrontFootSprite",
	"MotionRoot/PelvisPivot/FrontAttachmentPivot/FrontAttachmentSprite",
	"MotionRoot/PelvisPivot/WeaponPivot/WeaponSprite",
	"MotionRoot/PelvisPivot/WeaponPivot/WeaponGripAnchor",
	"MotionRoot/PelvisPivot/WeaponPivot/WeaponTipAnchor",
	"BodyCenterAnchor",
	"HeadAnchor",
	"HitAnchor",
	"GroundAnchor",
	"AnimationPlayer",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var skin := load(SKIN_PATH) as HumanoidCutoutRigSkin
	_expect(skin != null, "Skin resource did not load.", failures)
	_expect(skin != null and skin.profile != null, "Profile resource did not load.", failures)
	if skin == null:
		_finish(failures)
		return

	for atlas in [skin.south_atlas, skin.north_atlas, skin.east_atlas]:
		_expect(atlas != null, "Required atlas is missing.", failures)
		if atlas != null:
			_expect(Vector2i(atlas.get_width(), atlas.get_height()) == Vector2i(480, 384),
				"Required atlas dimensions are not 480x384.", failures)

	var rig := RIG_SCENE.instantiate() as HumanoidCutoutRig2D
	_expect(rig != null, "Rig scene did not instantiate.", failures)
	root.add_child(rig)
	rig.set_skin(skin)
	await process_frame

	for path in REQUIRED_NODE_PATHS:
		_expect(rig.has_node(path), "Missing required rig node: %s" % path, failures)
	_expect(rig.PART_CELLS.size() == 20, "Cell map does not contain exactly 20 entries.", failures)
	var unique_cells: Dictionary = {}
	for cell in rig.PART_CELLS.values():
		unique_cells[cell] = true
	_expect(unique_cells.size() == 20, "Cell map regions are not unique.", failures)
	for part in rig.REQUIRED_PARTS:
		_expect(rig.PART_CELLS.has(part), "Required part is absent from cell map: %s" % String(part), failures)

	for direction in [&"s", &"n", &"e"]:
		rig.set_direction_code(direction)
		var head := rig.get_node(rig.PART_NODE_PATHS[&"head"]) as Sprite2D
		_expect(head.texture is AtlasTexture, "Direction %s did not slice head." % String(direction), failures)
		if head.texture is AtlasTexture:
			var region := (head.texture as AtlasTexture).region
			_expect(Vector2i(region.size) == Vector2i(96, 96), "Extracted cell is not 96x96.", failures)

	rig.set_direction_code(&"w")
	_expect(rig.is_west_mirrored(), "Missing west atlas did not mirror east.", failures)
	var authored_west := _blank_atlas()
	var authored_skin := skin.duplicate(true) as HumanoidCutoutRigSkin
	authored_skin.west_atlas = authored_west
	rig.set_skin(authored_skin)
	rig.set_direction_code(&"w")
	_expect(not rig.is_west_mirrored(), "Authored west atlas was still mirrored.", failures)
	var west_head := rig.get_node(rig.PART_NODE_PATHS[&"head"]) as Sprite2D
	_expect(west_head.texture is AtlasTexture and (west_head.texture as AtlasTexture).atlas == authored_west,
		"Authored west atlas did not override east.", failures)

	var blank_skin := authored_skin.duplicate(true) as HumanoidCutoutRigSkin
	var blank := _blank_atlas()
	blank_skin.south_atlas = blank
	blank_skin.north_atlas = blank
	blank_skin.east_atlas = blank
	blank_skin.west_atlas = null
	rig.set_skin(blank_skin)
	rig.set_direction_code(&"s")
	_expect((rig.get_node(rig.PART_NODE_PATHS[&"cape"]) as Sprite2D).texture is AtlasTexture,
		"Optional blank part failed to resolve safely.", failures)

	rig.set_direction_code(&"e")
	rig.set_facing_vector(Vector2(1, 1))
	_expect(rig.get_direction_code() == &"e", "Diagonal tie did not preserve horizontal sector.", failures)
	rig.set_direction_code(&"s")
	rig.set_facing_vector(Vector2(1, 1))
	_expect(rig.get_direction_code() == &"s", "Diagonal tie did not preserve vertical sector.", failures)

	var player := rig.get_node("AnimationPlayer") as AnimationPlayer
	_check_animation(player, &"idle", true, failures)
	_check_animation(player, &"run", true, failures)
	_check_animation(player, &"attack_light", false, failures)
	_check_animation(player, &"hit_react", false, failures)
	_check_animation(player, &"death", false, failures)

	_expect(rig.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"Rig root filtering is not nearest.", failures)
	for sprite in rig.find_children("*", "Sprite2D", true, false):
		_expect((sprite as Sprite2D).texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			"Part filtering is not nearest: %s" % sprite.get_path(), failures)
	for forbidden_type in ["Skeleton2D", "Bone2D", "Polygon2D", "MeshInstance2D"]:
		_expect(rig.find_children("*", forbidden_type, true, false).is_empty(),
			"Forbidden deforming node exists: %s" % forbidden_type, failures)
	for collision in rig.find_children("*", "CollisionObject2D", true, false):
		failures.append("Collision node is under cutout rig: %s" % collision.get_path())

	var test_enemy := TEST_ENEMY_SCENE.instantiate() as CharacterBody2D
	root.add_child(test_enemy)
	test_enemy.set_physics_process(false)
	var original_position := test_enemy.global_position
	var enemy_rig := test_enemy.get_node("HumanoidCutoutRig2D") as HumanoidCutoutRig2D
	enemy_rig.play_state(&"run", true)
	await process_frame
	await process_frame
	_expect(test_enemy.global_position == original_position,
		"Visual animation moved the CharacterBody2D root.", failures)
	_expect(test_enemy.get_node("CollisionShape2D").get_parent() == test_enemy,
		"Gameplay collision moved under a visual pivot.", failures)

	var grunt := GRUNT_SCENE.instantiate()
	_expect(grunt != null, "Existing enemy_grunt.tscn did not instantiate.", failures)
	root.add_child(grunt)
	grunt.set_physics_process(false)
	await process_frame
	_expect(int(grunt.get("visual_backend")) == 0,
		"Authored-frame backend is no longer the default.", failures)
	var grunt_sprite := grunt.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_expect(grunt_sprite != null and grunt_sprite.sprite_frames != null,
		"Existing grunt SpriteFrames did not load.", failures)
	if grunt_sprite != null and grunt_sprite.sprite_frames != null:
		_expect(grunt_sprite.sprite_frames.has_animation("idle_s"),
			"Existing grunt authored animation library is missing idle_s.", failures)

	_finish(failures)


func _check_animation(
	player: AnimationPlayer,
	name: StringName,
	should_loop: bool,
	failures: Array[String]
) -> void:
	_expect(player.has_animation(String(name)), "Missing animation: %s" % String(name), failures)
	if not player.has_animation(String(name)):
		return
	var animation := player.get_animation(String(name))
	var loops := animation.loop_mode != Animation.LOOP_NONE
	_expect(loops == should_loop, "Animation loop contract drift: %s" % String(name), failures)


func _blank_atlas() -> ImageTexture:
	var image := Image.create(480, 384, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(image)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("HUMANOID_CUTOUT_RIG_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error("[HumanoidCutoutRigSmoke] %s" % failure)
	quit(1)
