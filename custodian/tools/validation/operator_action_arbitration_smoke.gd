extends SceneTree

const ACTION_CONTROLLER := preload("res://game/actors/operator/combat/operator_action_controller.gd")
const PRESENTATION_CONTROLLER := preload("res://game/actors/operator/presentation/operator_presentation_controller.gd")
const BODY_PRESENTER := preload("res://game/actors/operator/presentation/operator_body_presenter.gd")
const BODY_PLAN := preload("res://game/actors/operator/presentation/operator_body_presentation_plan.gd")
const ANIMATION_PLAYER := preload("res://game/actors/operator/presentation/operator_animation_player.gd")
const ANIMATION_SELECTOR := preload("res://game/actors/operator/animations/operator_animation_selector.gd")

var _failures: Array[String] = []
var _entered_actions: Array[StringName] = []
var _reentries: Array[StringName] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_action_arbitration()
	_test_presentation_translation()
	_test_controller_authority_boundaries()
	if _failures.is_empty():
		print("operator_action_arbitration_smoke: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_action_arbitration() -> void:
	var controller = ACTION_CONTROLLER.new()
	controller.action_entered.connect(_on_action_entered)
	_expect(controller.current_action.is_empty(), "action controller should start neutral")
	_expect(not controller.request(&"walk", 1), "locomotion must not be an action")
	_expect(controller.request(ACTION_CONTROLLER.FAST_ATTACK, 10), "fast attack should enter from neutral")
	_expect(controller.is_active(ACTION_CONTROLLER.FAST_ATTACK), "fast attack should own the action axis")
	controller.advance(0.125)
	_expect(is_equal_approx(controller.elapsed, 0.125), "action clock should advance explicitly")
	_expect(controller.request(ACTION_CONTROLLER.FAST_ATTACK, 10), "same-action request should be accepted")
	_expect(controller.elapsed == 0.0, "same-action re-entry should reset action elapsed")
	_expect(_reentries.has(ACTION_CONTROLLER.FAST_ATTACK), "same-action re-entry should be observable")
	_expect(not controller.request(ACTION_CONTROLLER.BLOCK, 7), "lower-priority action must not preempt attack")
	_expect(controller.request(ACTION_CONTROLLER.DAMAGE_REACTION, 20), "damage reaction should preempt attack")
	_expect(not controller.request(ACTION_CONTROLLER.FAST_ATTACK, 10), "attack must not preempt damage reaction")
	_expect(controller.request(ACTION_CONTROLLER.DAMAGE_REACTION, 24), "repeated reaction request should be accepted")
	_expect(_reentries.has(ACTION_CONTROLLER.DAMAGE_REACTION), "reaction should support same-action re-entry")
	_expect(controller.complete(ACTION_CONTROLLER.DAMAGE_REACTION), "current reaction should complete")
	_expect(controller.current_action.is_empty(), "completed action should return to neutral")
	_expect(controller.request(ACTION_CONTROLLER.BLOCK, 8), "block should enter from neutral")
	_expect(not controller.request(ACTION_CONTROLLER.EQUIP, 100), "held block remains non-interruptible")
	_expect(controller.request(ACTION_CONTROLLER.DEATH, 20), "terminal death must preempt any action")
	_expect(controller.terminal, "death should set terminal arbitration")
	_expect(not controller.request(ACTION_CONTROLLER.FAST_ATTACK, 1000), "death must reject later actions")
	controller.reset_for_respawn()
	_expect(not controller.terminal, "explicit respawn should release terminal arbitration")
	_expect(controller.current_action.is_empty(), "respawn should return to neutral without idle action")
	_expect(controller.request(ACTION_CONTROLLER.FAST_ATTACK, 10), "actions should be available after respawn")


func _test_presentation_translation() -> void:
	var frames := SpriteFrames.new()
	var death_identity := &"unarmed/reaction/death_01/omni/full_body"
	frames.add_animation(death_identity)
	frames.add_frame(death_identity, _texture())
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	root.add_child(sprite)
	var presenter = BODY_PRESENTER.new()
	_expect(
		presenter.register_body_layers(BODY_PRESENTER.Owner.LEGACY_FULL_BODY, [sprite]),
		"legacy body renderer should register"
	)
	var playback = ANIMATION_PLAYER.new()
	var selector = ANIMATION_SELECTOR.new(frames)
	var presentation = PRESENTATION_CONTROLLER.new(presenter, playback, selector)
	var plan = BODY_PLAN.create(BODY_PRESENTER.Owner.LEGACY_FULL_BODY, [sprite])
	var resolved: StringName = presentation.present_omni_animation(
		plan, sprite, &"unarmed", &"reaction", &"death_01", &"full_body", true
	)
	_expect(resolved == death_identity, "semantic omni identity should resolve through the selector")
	_expect(sprite.visible, "presentation controller should transfer body ownership")
	_expect(sprite.animation == death_identity, "presentation controller should play the resolved identity")
	var invalid_layer := AnimatedSprite2D.new()
	var invalid_plan = BODY_PLAN.create(BODY_PRESENTER.Owner.LEGACY_FULL_BODY, [invalid_layer])
	_expect(
		not presentation.present_animation(invalid_plan, invalid_layer, death_identity),
		"unregistered body layer should reject the presentation transaction"
	)
	_expect(presenter.current_owner() == BODY_PRESENTER.Owner.LEGACY_FULL_BODY, "rejected plan must preserve current owner")
	invalid_layer.free()
	sprite.free()


func _test_controller_authority_boundaries() -> void:
	var action_source := FileAccess.get_file_as_string("res://game/actors/operator/combat/operator_action_controller.gd")
	for forbidden in ["AnimatedSprite2D", "SpriteFrames", "OperatorAnimationPlayer", "OperatorAnimationSelector", "InputFrame"]:
		_expect(not action_source.contains(forbidden), "action controller must not reference %s" % forbidden)
	var state_dir := DirAccess.open("res://game/actors/operator/animations/states")
	_expect(state_dir == null, "legacy Operator action-state runtime directory should be removed")
	var plan_source := FileAccess.get_file_as_string("res://game/actors/operator/presentation/operator_body_presentation_plan.gd")
	for forbidden in ["var action", "var priority", "var animation", "var elapsed", "var input"]:
		_expect(not plan_source.contains(forbidden), "mechanical body plan must not expose %s" % forbidden)


func _texture() -> Texture2D:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


func _on_action_entered(action: StringName, _sequence: int, reentry: bool) -> void:
	_entered_actions.append(action)
	if reentry:
		_reentries.append(action)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
