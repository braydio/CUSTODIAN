extends SceneTree

const TRAVEL_FRAMES_PATH := "res://assets/resources/vfx/weapons/carbine_mk1/carbine_mk1_projectile_travel_loop_01_frames.tres"
const IMPACT_FRAMES_PATH := "res://assets/resources/vfx/weapons/carbine_mk1/carbine_mk1_impact_hard_01_frames.tres"
const TRAVEL_PNG_PATH := "res://content/sprites/effects/weapons/carbine_mk1/carbine_mk1_projectile_travel_loop_01.png"
const IMPACT_PNG_PATH := "res://content/sprites/effects/weapons/carbine_mk1/carbine_mk1_projectile_impact_hard_01.png"
const IMPACT_SCENE_PATH := "res://game/vfx/weapons/carbine_mk1/carbine_mk1_impact_hard_vfx.tscn"
const BULLET_SCENE_PATH := "res://game/actors/projectiles/bullet.tscn"
const CARBINE_DATA_PATH := "res://content/weapons/data/carbine_mk1.json"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_frames(TRAVEL_FRAMES_PATH, &"travel", true, 24.0, 3, [
		Rect2(0, 0, 48, 16),
		Rect2(48, 0, 48, 16),
		Rect2(96, 0, 48, 16),
	])
	_validate_frames(IMPACT_FRAMES_PATH, &"impact", false, 24.0, 6, [
		Rect2(0, 0, 64, 64),
		Rect2(64, 0, 64, 64),
		Rect2(128, 0, 64, 64),
		Rect2(192, 0, 64, 64),
		Rect2(256, 0, 64, 64),
		Rect2(320, 0, 64, 64),
	])
	_validate_png_dimensions(TRAVEL_PNG_PATH, Vector2i(144, 16))
	_validate_png_dimensions(IMPACT_PNG_PATH, Vector2i(384, 64))
	_validate_scene()
	_validate_carbine_data()
	_finish()


func _validate_frames(path: String, animation: StringName, loop: bool, speed: float, frame_count: int, regions: Array) -> void:
	_require(ResourceLoader.exists(path), "Missing SpriteFrames resource: %s" % path)
	var frames := load(path) as SpriteFrames
	_require(frames != null, "Resource is not SpriteFrames: %s" % path)
	if frames == null:
		return
	_require(frames.has_animation(animation), "%s missing animation %s" % [path, animation])
	_require(frames.get_animation_loop(animation) == loop, "%s loop mismatch" % path)
	_require(is_equal_approx(frames.get_animation_speed(animation), speed), "%s speed mismatch" % path)
	_require(frames.get_frame_count(animation) == frame_count, "%s frame count mismatch" % path)
	for index in range(min(frame_count, regions.size())):
		var texture := frames.get_frame_texture(animation, index) as AtlasTexture
		_require(texture != null, "%s frame %d is not AtlasTexture" % [path, index])
		if texture != null:
			_require(texture.region == regions[index], "%s frame %d region mismatch: %s" % [path, index, texture.region])


func _validate_png_dimensions(path: String, expected: Vector2i) -> void:
	if not FileAccess.file_exists(path):
		push_warning("[CarbineProjectileVFXSmoke] Missing production PNG: %s" % path)
		return
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(path))
	_require(err == OK, "Failed to load PNG: %s" % path)
	if err != OK:
		return
	var actual := image.get_size()
	if actual != expected:
		push_warning("[CarbineProjectileVFXSmoke] PNG dimension drift: %s expected=%s actual=%s" % [path, expected, actual])
	_require(image.detect_alpha() != Image.ALPHA_NONE, "PNG should contain alpha: %s" % path)


func _validate_scene() -> void:
	_require(ResourceLoader.exists(BULLET_SCENE_PATH), "Missing bullet scene.")
	var bullet_scene := load(BULLET_SCENE_PATH) as PackedScene
	_require(bullet_scene != null, "Bullet scene should load.")
	if bullet_scene != null:
		var bullet := bullet_scene.instantiate()
		root.add_child(bullet)
		var visual := bullet.get_node_or_null("Visual")
		_require(visual is AnimatedSprite2D, "Bullet Visual should be AnimatedSprite2D.")
		_require(bullet.get("impact_scene") is PackedScene, "Generic bullet should provide a non-blocking default impact scene for drone/turret callers.")
		if visual is AnimatedSprite2D:
			var sprite := visual as AnimatedSprite2D
			_require(sprite.sprite_frames != null, "Bullet Visual should have SpriteFrames.")
			_require(sprite.animation == &"travel", "Bullet Visual should default to travel animation.")
		bullet.queue_free()
	_require(ResourceLoader.exists(IMPACT_SCENE_PATH), "Missing Carbine impact scene.")
	var impact_scene := load(IMPACT_SCENE_PATH) as PackedScene
	_require(impact_scene != null, "Carbine impact scene should load.")
	if impact_scene != null:
		var impact := impact_scene.instantiate()
		root.add_child(impact)
		_require(impact.has_method("configure_impact"), "Impact VFX should support configure_impact.")
		impact.queue_free()


func _validate_carbine_data() -> void:
	var file := FileAccess.open(CARBINE_DATA_PATH, FileAccess.READ)
	_require(file != null, "Missing carbine weapon data.")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_require(parsed is Dictionary, "Carbine weapon data should parse.")
	if not (parsed is Dictionary):
		return
	var data := parsed as Dictionary
	var projectile: Dictionary = data.get("projectile", {})
	var visual_effects: Dictionary = data.get("visual_effects", {})
	_require(str(projectile.get("scene", "")) == BULLET_SCENE_PATH, "Carbine should use generic bullet scene.")
	_require(str(projectile.get("visual_sprite_frames", "")) == TRAVEL_FRAMES_PATH, "Carbine should assign travel SpriteFrames.")
	_require(str(projectile.get("impact_scene", "")) == IMPACT_SCENE_PATH, "Carbine should assign hard impact scene.")
	_require(bool(visual_effects.get("tracer", false)), "Carbine visual_effects.tracer should be true.")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[CarbineProjectileVFXSmoke] " + message)


func _finish() -> void:
	if _failed:
		print("[CarbineProjectileVFXSmoke] FAILED")
		quit(1)
		return
	print("[CarbineProjectileVFXSmoke] PASS")
	quit(0)
