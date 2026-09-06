extends SceneTree

const BASE_SET := preload("res://game/actors/enemies/presentation/enemy_animation_set.gd")
const CONTROLLER := preload("res://game/actors/enemies/presentation/enemy_presentation_controller.gd")
const PURSUIT_SET: EnemyAnimationSet = preload("res://game/actors/enemies/presentation/sets/pursuit_frame_animation_set.tres")
const GRUNT_SET: EnemyAnimationSet = preload("res://game/actors/enemies/presentation/sets/enemy_grunt_animation_set.tres")


func _init() -> void:
	PURSUIT_SET.invalidate_sprite_frames_cache()
	var pursuit_frames := PURSUIT_SET.build_sprite_frames(&"body")
	assert(pursuit_frames.has_animation(&"melee_e"))
	assert(pursuit_frames.has_animation(&"melee_w"))
	assert(not pursuit_frames.has_animation(&"default"))
	assert(PURSUIT_SET.get_animation_name(PURSUIT_SET.resolve_clip(&"combat.fast_01", &"e"), &"body") == &"melee_e")
	assert(PURSUIT_SET.get_animation_name(PURSUIT_SET.resolve_clip(&"combat.fast_02", &"e"), &"body") == &"melee_e")
	assert(PURSUIT_SET.get_animation_name(PURSUIT_SET.resolve_clip(&"combat.fast_01", &"w"), &"body") == &"melee_w")
	assert(PURSUIT_SET.get_animation_name(PURSUIT_SET.resolve_clip(&"combat.fast_02", &"w"), &"body") == &"melee_w")
	assert(pursuit_frames.get_frame_count(&"melee_e") == 6)
	assert(PURSUIT_SET.build_sprite_frames(&"body") == pursuit_frames)
	assert(PURSUIT_SET.get_build_collisions(&"body").is_empty())

	GRUNT_SET.invalidate_sprite_frames_cache()
	var grunt_frames := GRUNT_SET.build_sprite_frames(&"body")
	var expected_names := {
		&"combat.fast_01": "melee_%s",
		&"combat.fast_02": "combat_fast_02_%s",
		&"combat.fast_03": "combat_fast_03_%s",
	}
	for action in expected_names:
		for direction in [&"e", &"w"]:
			var expected := StringName(String(expected_names[action]) % String(direction))
			var resolved := GRUNT_SET.get_animation_name(GRUNT_SET.resolve_clip(action, direction), &"body")
			assert(resolved == expected, "%s != %s" % [resolved, expected])
			assert(grunt_frames.has_animation(resolved))
	assert(GRUNT_SET.build_sprite_frames(&"body") == grunt_frames)

	var conflict: EnemyAnimationSet = BASE_SET.new()
	conflict.set_id = &"collision_fixture"
	conflict.collision_errors_enabled = false
	var source_a := "res://content/sprites/enemies/pursuit_frame/runtime/body/combat/pursuit_frame__body__combat__melee_brace_01__e__6f__96.png"
	var source_b := "res://content/sprites/enemies/pursuit_frame/runtime/body/combat/pursuit_frame__body__combat__melee_brace_01__w__6f__96.png"
	conflict.clips = [
		{"action": &"fixture.a", "direction": &"e", "body_name": &"collision", "body_path": source_a, "frame_size": Vector2i(96, 96), "fps": 12.0, "loop": false},
		{"action": &"fixture.b", "direction": &"w", "body_name": &"collision", "body_path": source_b, "frame_size": Vector2i(96, 96), "fps": 12.0, "loop": false},
	]
	var conflict_frames := conflict.build_sprite_frames(&"body")
	assert(conflict_frames.get_animation_names().count(&"collision") == 1)
	var collisions := conflict.get_build_collisions(&"body")
	assert(collisions.size() == 1)
	assert(collisions[0].get("set_id") == &"collision_fixture")
	assert(collisions[0].get("animation_name") == &"collision")

	var uncached_usec := _benchmark_setup(true)
	var cached_usec := _benchmark_setup(false)
	PURSUIT_SET.invalidate_sprite_frames_cache()
	GRUNT_SET.invalidate_sprite_frames_cache()
	conflict.invalidate_sprite_frames_cache()

	print("pursuit_frame_animation_set_smoke: PASS setup_before_uncached=%dus setup_after_cached=%dus" % [uncached_usec, cached_usec])
	quit(0)


func _benchmark_setup(invalidate_each: bool, iterations := 20) -> int:
	PURSUIT_SET.invalidate_sprite_frames_cache()
	if not invalidate_each:
		var warm: EnemyPresentationController = CONTROLLER.new()
		var warm_body := AnimatedSprite2D.new()
		var warm_fx := AnimatedSprite2D.new()
		warm.setup(PURSUIT_SET, warm_body, warm_fx)
		warm.body_sprite = null
		warm.fx_sprite = null
		warm_body.free()
		warm_fx.free()
	var started := Time.get_ticks_usec()
	for index in range(iterations):
		if invalidate_each:
			PURSUIT_SET.invalidate_sprite_frames_cache()
		var controller: EnemyPresentationController = CONTROLLER.new()
		var body := AnimatedSprite2D.new()
		var fx := AnimatedSprite2D.new()
		controller.setup(PURSUIT_SET, body, fx, index)
		controller.body_sprite = null
		controller.fx_sprite = null
		body.free()
		fx.free()
	return int((Time.get_ticks_usec() - started) / iterations)
