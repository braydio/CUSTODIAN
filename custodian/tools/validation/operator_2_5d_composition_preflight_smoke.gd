extends SceneTree

## Isolated fixtures prove the preflight contract without loading the Operator
## scene or activating any art. Every probe is read-only.
const PRESENTER_SCRIPT := preload("res://game/actors/operator/presentation/operator_body_presenter.gd")
const PLAYER_SCRIPT := preload("res://game/actors/operator/presentation/operator_animation_player.gd")
const SELECTOR_SCRIPT := preload("res://game/actors/operator/animations/operator_animation_selector.gd")
const PLAN_SCRIPT := preload("res://game/actors/operator/presentation/operator_body_presentation_plan.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	current_scene = root
	var frames := SpriteFrames.new()
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	for identity in [
		"unarmed/locomotion/idle_01/e/full_body",
		"unarmed/locomotion/idle_01/e/lower_body",
		"unarmed/locomotion/idle_01/e/upper_body",
		"unarmed/locomotion/idle_01/w/upper_body",
		"unarmed/locomotion/idle_01/ne/full_body",
		"unarmed/locomotion/walk_01/e/lower_body",
		"unarmed/defense/guard_01/w/upper_body",
	]:
		frames.add_animation(identity)
		frames.add_frame(identity, texture)
	var legacy := _sprite(root, "Legacy", frames)
	var lower := _sprite(root, "Lower", frames)
	var upper := _sprite(root, "Upper", frames)
	var exclusive := _sprite(root, "Exclusive", frames)
	var presenter = PRESENTER_SCRIPT.new()
	presenter.register_body_layers(1, [legacy])
	presenter.register_body_layers(2, [lower, upper])
	presenter.register_body_layers(5, [exclusive])
	var controller_script: GDScript = load("res://game/actors/operator/presentation/operator_presentation_controller.gd")
	var controller = controller_script.new(
		presenter, PLAYER_SCRIPT.new(), SELECTOR_SCRIPT.new(frames)
	)
	var legacy_plan = PLAN_SCRIPT.create(1, [legacy])
	var before := presenter.current_owner()
	var full_result: Dictionary = controller.call("preflight_composition_fixture_only",
		legacy_plan, &"full_body", [_clip(legacy, &"e", &"full_body")], legacy
	)
	_expect(full_result.status == "STRUCTURALLY_READY", "exact full-body fixture should pass")
	_expect(full_result.generation_status == "UNKNOWN/BLOCKED", "structural readiness must not claim generation approval")
	_expect(not full_result.movement_permission, "presentation preflight must not grant movement permission")
	_expect(presenter.current_owner() == before, "full-body preflight changed owner")

	var split_plan = PLAN_SCRIPT.create(2, [lower, upper])
	var split_clips: Array[Dictionary] = [
		_clip(lower, &"e", &"lower_body", &"locomotion", &"walk_01"),
		_clip(upper, &"w", &"upper_body", &"defense", &"guard_01"),
	]
	var split_result: Dictionary = controller.call("preflight_composition_fixture_only",
		split_plan,
		&"split_body",
		split_clips,
		lower
	)
	_expect(split_result.status == "STRUCTURALLY_READY", "split fixture with separate facings should pass")
	_expect(split_result.generation_status == "UNKNOWN/BLOCKED", "fixture structure must not claim generation consistency")
	_expect(not split_result.movement_permission, "split feasibility must not authorize gameplay movement")
	_expect(presenter.current_owner() == before, "split preflight changed owner")
	var missing_result: Dictionary = controller.call("preflight_composition_fixture_only",
		split_plan, &"split_body", [_clip(lower, &"e", &"lower_body")], lower
	)
	_expect(missing_result.status == "BLOCKED", "missing split layer must fail closed")
	_expect(presenter.current_owner() == before, "rejected split preflight changed owner")
	var duplicated_plan = PLAN_SCRIPT.create(2, [lower, lower])
	var duplicate_result: Dictionary = controller.call("preflight_composition_fixture_only",
		duplicated_plan,
		&"split_body",
		[_clip(lower, &"e", &"lower_body"), _clip(lower, &"w", &"upper_body")],
		lower
	)
	_expect(duplicate_result.status == "BLOCKED", "duplicate renderer cannot fake a complete split")
	_expect(presenter.current_owner() == before, "duplicate-layer rejection changed owner")
	var stale_profile := _clip(upper, &"n", &"upper_body")
	stale_profile.action = &"stale_untrusted_action"
	var stale_result: Dictionary = controller.call("preflight_composition_fixture_only",
		split_plan, &"split_body", [split_clips[0], stale_profile], lower
	)
	_expect(stale_result.status == "BLOCKED", "stale/untrusted exact selector identity must fail closed")
	_expect(presenter.current_owner() == before, "stale-profile rejection changed owner")

	var exclusive_plan = PLAN_SCRIPT.create(5, [exclusive])
	var exclusive_result: Dictionary = controller.call("preflight_composition_fixture_only",
		exclusive_plan, &"exclusive_rig", [_clip(exclusive, &"ne", &"full_body")], exclusive
	)
	_expect(exclusive_result.status == "STRUCTURALLY_READY", "registered exclusive rig fixture should pass")
	var wrong_owner_mode: Dictionary = controller.call("preflight_composition_fixture_only",
		exclusive_plan, &"full_body", [_clip(exclusive, &"ne", &"full_body")], exclusive
	)
	_expect(wrong_owner_mode.status == "BLOCKED", "exclusive owner cannot claim ordinary full-body mode")

	var hypothetical := _clip(legacy, &"ne", &"full_body")
	hypothetical.profile = &"operator_2_5d_128"
	hypothetical.generation = &"operator_2_5d_128" # Deliberately untrusted caller data.
	var unknown_result: Dictionary = controller.call("preflight_composition_fixture_only",
		legacy_plan, &"full_body", [hypothetical], legacy
	)
	_expect(unknown_result.status == "UNKNOWN/BLOCKED", "caller generation claim must not unlock 2.5D")
	_expect(presenter.current_owner() == before, "unknown-generation preflight changed owner")

	if _failures.is_empty():
		print("operator_2_5d_composition_preflight_smoke: PASS")
	else:
		for failure in _failures:
			push_error("operator_2_5d_composition_preflight_smoke: " + failure)
	quit(0 if _failures.is_empty() else 1)


func _sprite(parent: Node, sprite_name: String, frames: SpriteFrames) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = sprite_name
	sprite.sprite_frames = frames
	parent.add_child(sprite)
	return sprite


func _clip(
	sprite: AnimatedSprite2D,
	sector: StringName,
	layer: StringName,
	group: StringName = &"locomotion",
	action: StringName = &"idle_01",
	profile: StringName = &"unarmed"
) -> Dictionary:
	return {
		"sprite": sprite,
		"profile": profile,
		"group": group,
		"action": action,
		"sector": sector,
		"layer": layer,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
