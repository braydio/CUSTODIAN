extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CANONICAL_ANCHOR := Vector2(0.0, -18.0)
const ANCHOR_EPSILON_PX := 0.5
const VISUAL_NODE_NAMES := [
	"DodgeFXBackSprite",
	"AnimatedSprite2D",
	"ModularCapeSprite",
	"ModularLowerBodySprite",
	"ModularUpperBodySprite",
	"ModularHeadSprite",
	"ModularSidearmSprite",
	"ModularUpperFxSprite",
	"MeleeWeaponOverlaySprite",
	"MeleeFxOverlaySprite",
]

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorVisualAnchorSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	var operator := OPERATOR_SCENE.instantiate()
	operator.global_position = Vector2(320.0, 240.0)
	root.add_child(operator)
	await process_frame
	var gameplay_origin: Vector2 = operator.global_position

	_check_transition(operator, gameplay_origin, "idle", func() -> void:
		operator.set("velocity", Vector2.ZERO)
		operator.call("_update_animation")
	)
	_check_transition(operator, gameplay_origin, "walk", func() -> void:
		operator.set("movement_direction", Vector2.RIGHT)
		operator.set("velocity", Vector2.RIGHT * 40.0)
		operator.call("_update_animation")
	)
	_check_transition(operator, gameplay_origin, "unarmed_fast_attack", func() -> void:
		operator.set("using_unarmed", true)
		operator.set("combat_loadout_mode", "melee")
		operator.set("primary_weapon_equipped", false)
		operator.set("_melee_attack_key", "unarmed_fast_1")
		operator.set("_melee_forward", Vector2.RIGHT)
		operator.call("_sync_modular_fast_attack_phase", &"strike")
	)
	_check_transition(operator, gameplay_origin, "melee_fast_attack", func() -> void:
		operator.call("_play_named_melee_weapon_overlay", &"melee_2h_fast_weapon")
		operator.call("_play_named_melee_fx_overlay", &"melee_2h_fast_fx")
	)
	_check_transition(operator, gameplay_origin, "hit_recoil", func() -> void:
		operator.call("take_damage", 1.0, true, {"attack_id": "anchor_smoke"})
	)
	_check_transition(operator, gameplay_origin, "block", func() -> void:
		operator.set("using_unarmed", true)
		operator.set("combat_loadout_mode", "melee")
		operator.call("start_block")
	)
	_check_transition(operator, gameplay_origin, "parry", func() -> void:
		operator.call("_play_parry_animation", &"unarmed_parry")
	)
	_check_transition(operator, gameplay_origin, "dodge", func() -> void:
		operator.set("_dodge_cooldown_remaining", 0.0)
		operator.set("stamina", 100.0)
		operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"committed", 1.0)
	)
	_check_transition(operator, gameplay_origin, "field_patch", func() -> void:
		operator.set("aim_direction", Vector2.RIGHT)
		operator.call("_play_field_patch_use_presentation")
	)
	_check_transition(operator, gameplay_origin, "ranged_stance_fire", func() -> void:
		operator.set("using_unarmed", false)
		operator.set("combat_loadout_mode", "ranged")
		operator.set("primary_weapon_equipped", true)
		operator.set("aim_direction", Vector2.RIGHT)
		operator.call("_begin_modular_primary_ranged_aim_presentation")
		operator.call("_begin_modular_primary_ranged_fire_presentation")
	)

	root.queue_free()
	await process_frame
	if _failed:
		push_error("operator_visual_anchor_smoke failed")
		quit(1)
		return
	print("[OperatorVisualAnchorSmoke] canonical anchors survived all presentation transitions.")
	quit(0)


func _check_transition(
	operator: Node2D,
	gameplay_origin: Vector2,
	label: String,
	transition: Callable
) -> void:
	transition.call()
	_assert(
		operator.global_position.is_equal_approx(gameplay_origin),
		"%s changed the Operator gameplay root from %s to %s"
		% [label, gameplay_origin, operator.global_position]
	)
	var visible_count := 0
	for node_name: String in VISUAL_NODE_NAMES:
		var sprite := operator.get_node_or_null(node_name) as AnimatedSprite2D
		_assert(sprite != null, "%s is missing %s" % [label, node_name])
		if sprite == null:
			continue
		_assert(
			sprite.position.distance_to(CANONICAL_ANCHOR) <= ANCHOR_EPSILON_PX,
			"%s left %s at position %s instead of %s"
			% [label, node_name, sprite.position, CANONICAL_ANCHOR]
		)
		_assert(
			sprite.offset.length() <= ANCHOR_EPSILON_PX,
			"%s left %s with offset %s" % [label, node_name, sprite.offset]
		)
		if sprite.visible:
			visible_count += 1
	_assert(visible_count > 0, "%s left no Operator visual layer visible" % label)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
