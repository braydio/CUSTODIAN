extends SceneTree

const GRUNT_ANIMATION_LIBRARY := preload("res://game/enemies/procgen/grunt_animation_library.gd")

const REQUIRED_BODY_ANIMATIONS := {
	"idle_s": 10,
	"run_e": 10,
	"run_w": 10,
	"melee_e": 10,
	"melee_se": 10,
	"melee_sw": 10,
	"melee_w": 11,
	"stagger_s": 8,
	"stagger_e": 8,
	"stagger_w": 8,
	"crit_s": 8,
	"crit_recovery_s": 5,
	"death_s": 12,
	"flinch_s": 6,
}

const REQUIRED_FX_ANIMATIONS := {
	"melee_fx_e": 10,
	"melee_fx_se": 10,
	"melee_fx_sw": 10,
	"melee_fx_w": 10,
	"crit_fx_s": 8,
	"flinch_fx_s": 5,
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var body_frames: SpriteFrames = GRUNT_ANIMATION_LIBRARY.get_grunt_sprite_frames()
	var fx_frames: SpriteFrames = GRUNT_ANIMATION_LIBRARY.get_grunt_fx_sprite_frames()

	if not _check_frames(body_frames, REQUIRED_BODY_ANIMATIONS, "body"):
		quit(1)
		return
	if not _check_frames(fx_frames, REQUIRED_FX_ANIMATIONS, "fx"):
		quit(1)
		return

	if GRUNT_ANIMATION_LIBRARY.get_move_animation(Vector2.RIGHT) != &"run_e":
		push_error("Grunt right movement did not resolve to run_e.")
		quit(1)
		return
	if GRUNT_ANIMATION_LIBRARY.get_move_animation(Vector2.LEFT) != &"run_w":
		push_error("Grunt left movement did not resolve to run_w.")
		quit(1)
		return
	if GRUNT_ANIMATION_LIBRARY.get_attack_animation(Vector2.LEFT) != &"melee_w":
		push_error("Grunt left attack did not resolve to melee_w.")
		quit(1)
		return
	if GRUNT_ANIMATION_LIBRARY.get_attack_animation(Vector2(1.0, 1.0)) != &"melee_se":
		push_error("Grunt southeast attack did not resolve to melee_se.")
		quit(1)
		return
	if GRUNT_ANIMATION_LIBRARY.get_stagger_animation(Vector2.RIGHT) != &"stagger_e":
		push_error("Grunt right stagger did not resolve to stagger_e.")
		quit(1)
		return
	if GRUNT_ANIMATION_LIBRARY.get_stagger_animation(Vector2.LEFT) != &"stagger_w":
		push_error("Grunt left stagger did not resolve to stagger_w.")
		quit(1)
		return
	if GRUNT_ANIMATION_LIBRARY.get_stagger_animation(Vector2.DOWN) != &"stagger_s":
		push_error("Grunt vertical stagger did not resolve to stagger_s.")
		quit(1)
		return
	if GRUNT_ANIMATION_LIBRARY.get_attack_fx_animation(Vector2.LEFT) != &"melee_fx_w":
		push_error("Grunt left attack FX did not resolve to melee_fx_w.")
		quit(1)
		return

	print("[GruntAnimationSmoke] body and FX animations loaded and directional selectors resolved.")
	quit(0)


func _check_frames(frames: SpriteFrames, expected: Dictionary, label: String) -> bool:
	for animation_name in expected.keys():
		var name := String(animation_name)
		if not frames.has_animation(name):
			push_error("Missing grunt %s animation: %s" % [label, name])
			return false
		var actual := frames.get_frame_count(name)
		var wanted := int(expected[animation_name])
		if actual != wanted:
			push_error("Unexpected grunt %s frame count for %s: got %d, wanted %d" % [label, name, actual, wanted])
			return false
	return true
