extends SceneTree
## C2b: the dodge FX renderer is canonical and builds nothing at runtime.
##
## `_ensure_dodge_fx_animation()` used to load two PNGs and construct a private
## `SpriteFrames` on the Operator at `_ready`. It loaded exactly the art behind
## the canonical identities `shared/transition/dodge_01/{n,s}/fx`, so C2b bound
## `DodgeFXBackSprite` to `operator_runtime_frames.tres` in the scene and deleted
## the builder.
##
## `_play_dodge_fx()` fails soft -- a missing animation makes it return without
## showing anything -- so the dodge flow test passes whether or not the FX
## actually resolves. This asserts the visible result rather than the absence of
## an error.

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const RUNTIME_FRAMES := preload("res://content/sprites/operator/runtime/operator_runtime_frames.tres")

var _failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("[OperatorDodgeFxCanonicalSmoke] %s" % message)


func _run() -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)

	var fx := operator.get("dodge_fx_back_sprite") as AnimatedSprite2D
	_check(fx != null, "the Operator scene must still have a DodgeFXBackSprite")
	if fx == null:
		return _finish(operator)

	# The renderer is the canonical database itself, not a copy of it. A
	# duplicate would satisfy has_animation() while quietly reintroducing the
	# actor-local database C2b removed.
	_check(
		fx.sprite_frames == RUNTIME_FRAMES,
		"DodgeFXBackSprite must bind the canonical runtime frames, got %s" % fx.sprite_frames
	)

	# Both authored facings resolve, with the timing the retired builder supplied.
	for sector: String in ["n", "s"]:
		var identity := StringName("shared/transition/dodge_01/%s/fx" % sector)
		_check(
			RUNTIME_FRAMES.has_animation(identity),
			"canonical dodge FX identity %s is missing" % identity
		)
		if not RUNTIME_FRAMES.has_animation(identity):
			continue
		_check(
			RUNTIME_FRAMES.get_frame_count(identity) == 9,
			"%s should keep its authored 9 frames, got %d"
				% [identity, RUNTIME_FRAMES.get_frame_count(identity)]
		)
		_check(
			is_equal_approx(RUNTIME_FRAMES.get_animation_speed(identity), 25.0),
			"%s should keep the authored 25 fps the runtime builder used, got %s"
				% [identity, RUNTIME_FRAMES.get_animation_speed(identity)]
		)
		_check(
			not RUNTIME_FRAMES.get_animation_loop(identity),
			"%s must not loop" % identity
		)

	# The live path: a northward dodge presents the north strip, a southward one
	# the south strip. Asserting the played identity is what makes this bite --
	# _play_dodge_fx() returns silently when nothing resolves.
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN]:
		operator.set("_dodge_direction", direction)
		operator.set("_dodge_active", true)
		operator.call("_play_dodge_fx", true, 0)
		var expected := StringName(
			"shared/transition/dodge_01/%s/fx" % ("n" if direction.y < -0.05 else "s")
		)
		_check(
			fx.animation == expected,
			"dodge %s should present %s, got %s" % [direction, expected, fx.animation]
		)
		_check(fx.visible, "dodge FX must be visible while dodging %s" % direction)

	_finish(operator)


func _finish(operator: Node) -> void:
	operator.queue_free()
	await process_frame
	if _failures > 0:
		push_error("operator_dodge_fx_canonical_smoke: FAIL (%d)" % _failures)
		quit(1)
		return
	print("operator_dodge_fx_canonical_smoke: PASS")
	quit(0)
