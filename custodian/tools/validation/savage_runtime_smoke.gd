extends SceneTree

const SAVAGE_SCENE := preload("res://game/actors/enemies/enemy_savage.tscn")
const SAVAGE_ANIMATION_LIBRARY := preload("res://game/enemies/procgen/savage_animation_library.gd")
const ENEMY_FACTORY_SCRIPT := preload("res://game/systems/core/systems/enemy_factory.gd")
const WAVE_MANAGER_SCRIPT := preload("res://game/systems/core/systems/wave_manager.gd")

const EXPECTED_FRAMES := {
	"idle_e": 9,
	"idle_n": 5,
	"idle_s": 9,
	"idle_se": 5,
	"idle_sw": 4,
	"idle_w": 9,
	"move_e": 8,
	"move_w": 8,
}

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_assert_true(
		not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://content/sprites/enemy_savage")),
		"savage assets should not exist in a loose content/sprites/enemy_savage tree"
	)
	var root := Node2D.new()
	root.name = "SavageRuntimeSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var frames := SAVAGE_ANIMATION_LIBRARY.get_savage_sprite_frames()
	for animation_name in EXPECTED_FRAMES:
		_assert_true(frames.has_animation(animation_name), "savage should include %s" % animation_name)
		_assert_true(frames.get_frame_count(animation_name) == int(EXPECTED_FRAMES[animation_name]), "%s should have %d frames" % [animation_name, EXPECTED_FRAMES[animation_name]])
	_assert_true(SAVAGE_ANIMATION_LIBRARY.get_idle_animation(Vector2(-1.0, 1.0)) == &"idle_sw", "southwest should select idle_sw")
	_assert_true(SAVAGE_ANIMATION_LIBRARY.get_idle_animation(Vector2(1.0, -1.0)) == &"idle_n", "missing northeast art should fall back to idle_n")
	_assert_true(SAVAGE_ANIMATION_LIBRARY.get_movement_animation(Vector2.RIGHT) == &"move_e", "east movement should select authored move_e")
	_assert_true(SAVAGE_ANIMATION_LIBRARY.get_movement_animation(Vector2.LEFT) == &"move_w", "west movement should select authored move_w")
	_assert_true(SAVAGE_ANIMATION_LIBRARY.get_movement_animation(Vector2.UP) == &"move_e", "missing north movement should use deterministic nearest art")
	var gameplay_direction := Vector2.UP
	SAVAGE_ANIMATION_LIBRARY.get_movement_animation(gameplay_direction)
	_assert_true(gameplay_direction == Vector2.UP, "presentation fallback must not alter gameplay direction")

	var savage := SAVAGE_SCENE.instantiate()
	root.add_child(savage)
	await process_frame
	var sprite := savage.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(savage.get("custom_enemy_animation_set") == "enemy_savage", "savage scene should select its animation set")
	_assert_true(savage.get("behavior_profile_id") == &"raider_savage", "savage runtime scene should select its distinct behavior profile")
	_assert_true(bool(savage.get("savage_chain_enabled")), "savage runtime scene should enable its two-hit chain")
	_assert_true(bool(savage.get("savage_pounce_enabled")), "savage runtime scene should enable its pounce")
	_assert_true(float(savage.get("health_bar_vertical_offset")) <= -80.0, "savage health bar should clear the tall mixed-canvas art")
	_assert_true(sprite != null and sprite.sprite_frames.has_animation("idle_e"), "savage scene should build runtime SpriteFrames")
	savage.call("_update_custom_enemy_animation", Vector2.LEFT, true, false)
	_assert_true(sprite != null and String(sprite.animation) == "move_w", "savage left movement should play authored move_w")
	savage.call("_update_custom_enemy_animation", Vector2.RIGHT, true, false)
	_assert_true(sprite != null and String(sprite.animation) == "move_e", "savage right movement should play authored move_e")
	var fallback_frames := sprite.sprite_frames.duplicate() as SpriteFrames
	fallback_frames.remove_animation(&"move_e")
	fallback_frames.remove_animation(&"move_w")
	sprite.sprite_frames = fallback_frames
	savage.call("_update_custom_enemy_animation", Vector2.RIGHT, true, false)
	_assert_true(String(sprite.animation) == "idle_e", "missing movement art should retain directional idle fallback")
	sprite.sprite_frames = frames
	for commitment in [&"windup", &"chain"]:
		sprite.play(&"idle_s")
		if commitment == &"windup":
			savage.set("_savage_pounce_phase", commitment)
		else:
			savage.set("_savage_chain_phase", commitment)
		savage.call("_update_custom_enemy_animation", Vector2.RIGHT, true, false)
		_assert_true(String(sprite.animation) == "idle_s", "movement must not overwrite active %s presentation" % commitment)
		savage.set("_savage_pounce_phase", &"")
		savage.set("_savage_chain_phase", &"")
	sprite.play(&"idle_n")
	savage.set("_recoil_timer", 0.1)
	savage.call("_update_custom_enemy_animation", Vector2.RIGHT, true, false)
	_assert_true(String(sprite.animation) == "idle_n", "movement must not overwrite active reaction presentation")
	savage.set("_recoil_timer", 0.0)
	sprite.play(&"idle_sw")
	savage.set("dead", true)
	savage.call("_update_custom_enemy_animation", Vector2.RIGHT, true, false)
	_assert_true(String(sprite.animation) == "idle_sw", "movement must not overwrite death presentation")
	savage.set("dead", false)

	var factory := ENEMY_FACTORY_SCRIPT.new()
	factory.set("savage_scene", SAVAGE_SCENE)
	_assert_true(factory.call("get_scene_for_type", "savage") == SAVAGE_SCENE, "EnemyFactory should resolve savage")
	var wave_manager := WAVE_MANAGER_SCRIPT.new()
	wave_manager.set("savage_scene", SAVAGE_SCENE)
	_assert_true(wave_manager.call("_scene_for_enemy_type", "savage") == SAVAGE_SCENE, "WaveManager should resolve savage")
	wave_manager.call("_apply_behavior_profile", savage, "savage")
	_assert_true(savage.get("behavior_profile_id") == &"raider_savage", "WaveManager should preserve the Savage-specific default profile")

	var game_scene_text := FileAccess.get_file_as_string("res://scenes/game.tscn")
	_assert_true(game_scene_text.contains("enemy_savage.tscn"), "game scene should preload enemy_savage.tscn")
	_assert_true(game_scene_text.contains("savage_scene = ExtResource"), "game WaveManager should receive savage_scene")
	root.queue_free()
	await process_frame

	if _failed:
		push_error("savage_runtime_smoke failed")
		quit(1)
		return
	print("[SavageRuntimeSmoke] directional idle/movement fallback, priority, actor, factory, and wave wiring resolved.")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
