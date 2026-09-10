extends SceneTree

## Body-presentation ownership invariant for the Operator.
##
## At any instant exactly ONE body presentation system may own the Operator
## body. Weapon and FX overlays are allowed alongside it; a second body is not.
## This smoke asserts visible BODY OWNERS, not merely visible nodes, and probes
## the frame before and the frame after every handoff, because that boundary is
## where duplicate bodies appeared:
##
##   - a posture transition playing with the legacy full body behind it
##   - fast_01 parked on frame 0/1 behind the ready_to_fast_1 startup
##
## Owner ids mirror Operator.BodyOwner.
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CATALOG_FRAMES := preload("res://game/actors/operator/operator_animation_catalog_frames.tres")

const OWNER_NONE := 0
const OWNER_LEGACY_FULL_BODY := 1
const OWNER_MODULAR_BODY := 2
const OWNER_VIGIL_POSTURE_TRANSITION := 3
const OWNER_VIGIL_FAST_STARTUP := 4

const OWNER_NAMES := {
	OWNER_NONE: "NONE",
	OWNER_LEGACY_FULL_BODY: "LEGACY_FULL_BODY",
	OWNER_MODULAR_BODY: "MODULAR_BODY",
	OWNER_VIGIL_POSTURE_TRANSITION: "VIGIL_POSTURE_TRANSITION",
	OWNER_VIGIL_FAST_STARTUP: "VIGIL_FAST_STARTUP",
}

## Overlays that may legitimately be visible alongside any body owner.
const OVERLAY_NODE_NAMES := [
	"ModularCapeSprite",
	"ModularSidearmSprite",
	"ModularUpperFxSprite",
	"MeleeWeaponOverlaySprite",
	"MeleeFxOverlaySprite",
	"DodgeFXBackSprite",
]

var _failures: Array[String] = []
var _operator: Node = null


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorVisualOwnershipSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	_operator = OPERATOR_SCENE.instantiate()
	_operator.global_position = Vector2(320.0, 240.0)
	root.add_child(_operator)
	await process_frame

	_check_owner_api()
	await _check_vigil_posture_and_fast_chain()
	await _check_modular_locomotion()
	await _check_legacy_fallback_presentations()
	_check_overlays_do_not_count_as_bodies()
	_report()


# --- helpers -----------------------------------------------------------------

## The invariant: at most one owner has any visible body layer.
func _assert_single_owner(label: String, expected_owner: int = -1) -> void:
	var visible_owners: Array = _operator.call("get_visible_body_owners")
	if visible_owners.size() > 1:
		var names: Array = []
		for owner in visible_owners:
			names.append(OWNER_NAMES.get(owner, str(owner)))
		_fail("%s: %d body owners visible at once (%s)" % [
			label, visible_owners.size(), ", ".join(names),
		])
		return
	if visible_owners.is_empty():
		_fail("%s: no body owner is visible" % label)
		return
	if expected_owner >= 0 and visible_owners[0] != expected_owner:
		_fail("%s: body owned by %s, expected %s" % [
			label,
			OWNER_NAMES.get(visible_owners[0], str(visible_owners[0])),
			OWNER_NAMES.get(expected_owner, str(expected_owner)),
		])


func _legacy_body() -> AnimatedSprite2D:
	return _operator.get_node("AnimatedSprite2D") as AnimatedSprite2D


func _assert_legacy_hidden(label: String) -> void:
	var legacy := _legacy_body()
	if legacy != null and legacy.visible:
		_fail("%s: legacy full body is visible behind modular presentation" % label)


func _install_vigil_posture_art() -> void:
	var lower := _operator.get_node("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := _operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	_operator.call("_install_melee_posture_catalog_frames")
	for action in ["idle_ready_01", "idle_relaxed_01", "draw_01"]:
		for suffix in ["e", "w"]:
			_operator.call("_copy_catalog_animation", CATALOG_FRAMES, lower.sprite_frames,
				StringName("melee_1h/posture/%s/%s/lower_body" % [action, suffix]))
			_operator.call("_copy_catalog_animation", CATALOG_FRAMES, upper.sprite_frames,
				StringName("melee_1h/posture/%s/%s/upper_body" % [action, suffix]))
	var vigil_definition = _operator.get("melee_weapon_definition")
	if vigil_definition == null:
		_fail("Vigil dagger definition is unavailable")
		return
	_operator.call("_apply_melee_weapon_animation_resources", vigil_definition)
	var armed_weapons: Array = _operator.get("armed_weapons")
	var vigil_index := armed_weapons.find(vigil_definition)
	if vigil_index < 0:
		_fail("Vigil dagger is not in the armed weapon list")
		return
	_operator.call("_apply_armed_selection", vigil_index)


# --- relaxed -> ready -> fast_01 ---------------------------------------------

func _check_vigil_posture_and_fast_chain() -> void:
	_install_vigil_posture_art()
	if not _failures.is_empty():
		return

	# idle_relaxed: modular/authored body owns, legacy is retired.
	_operator.set("velocity", Vector2.ZERO)
	_operator.set("_melee_forward", Vector2.RIGHT)
	_operator.call("_update_animation")
	await process_frame
	_assert_single_owner("idle_relaxed")
	_assert_legacy_hidden("idle_relaxed")

	# relaxed_to_ready owns the body exclusively for its whole duration.
	if not bool(_operator.call("_start_vigil_posture_bridge", &"relaxed_to_ready_01")):
		_fail("relaxed_to_ready_01 bridge did not start")
		return
	_assert_single_owner("relaxed_to_ready frame 0", OWNER_VIGIL_POSTURE_TRANSITION)
	_assert_legacy_hidden("relaxed_to_ready frame 0")

	# One frame after the handoff, and again after a per-frame animation update:
	# _update_animation must not compose a second body behind the transition.
	await process_frame
	_operator.call("_update_animation")
	_assert_single_owner("relaxed_to_ready mid-transition", OWNER_VIGIL_POSTURE_TRANSITION)
	_assert_legacy_hidden("relaxed_to_ready mid-transition")
	await process_frame
	_operator.call("_update_animation")
	_assert_single_owner("relaxed_to_ready mid-transition +1 frame", OWNER_VIGIL_POSTURE_TRANSITION)

	# The legacy fallback must not steal the body from a transition that owns
	# it. Invoking it directly mid-transition is the shape of the original bug:
	# it used to re-show the legacy sprite behind the authored strip.
	_operator.call("_hide_modular_locomotion_layers")
	_assert_single_owner(
		"legacy fallback invoked mid-transition", OWNER_VIGIL_POSTURE_TRANSITION
	)
	_assert_legacy_hidden("legacy fallback invoked mid-transition")

	# ready_to_relaxed is the same contract in the other direction.
	_operator.set("_vigil_posture_bridge_token",
		int(_operator.get("_vigil_posture_bridge_token")) + 1)
	if bool(_operator.call("_start_vigil_posture_bridge", &"ready_to_relaxed_01")):
		_assert_single_owner("ready_to_relaxed frame 0", OWNER_VIGIL_POSTURE_TRANSITION)
		await process_frame
		_operator.call("_update_animation")
		_assert_single_owner("ready_to_relaxed mid-transition", OWNER_VIGIL_POSTURE_TRANSITION)
		_assert_legacy_hidden("ready_to_relaxed mid-transition")
	else:
		_fail("ready_to_relaxed_01 bridge did not start")

	# Release the bridge, then drive ready -> fast_01 startup.
	_operator.set("_vigil_posture_bridge_token",
		int(_operator.get("_vigil_posture_bridge_token")) + 1)
	_operator.call("_release_vigil_rig", [
		_operator.get("_vigil_posture_bridge_lower"),
		_operator.get("_vigil_posture_bridge_upper"),
		_operator.get("_vigil_posture_bridge_weapon"),
	], OWNER_VIGIL_POSTURE_TRANSITION)
	_operator.set("_vigil_posture_bridge_action", &"")
	_operator.set("_vigil_posture_bridge_attack_queued", false)

	var posture_state = _operator.get("_melee_posture_state")
	if posture_state == null:
		_fail("melee posture state is unavailable")
		return
	posture_state.begin_draw_grace(3.0)
	posture_state.resolve(0.0, true, true, false)
	_operator.set("_melee_fast_combo_step", 0)
	_operator.set("_skip_next_fast_attack_windup", false)
	# The startup resolves its strip from the attack aim direction, and only
	# east/west transition art is authored, so commit an explicit facing.
	_operator.set("aim_direction", Vector2.RIGHT)
	_operator.set("movement_direction", Vector2.RIGHT)
	_operator.set("visual_idle_direction", Vector2.RIGHT)
	_operator.set("_melee_forward", Vector2.RIGHT)

	if not bool(_operator.call("_try_start_vigil_ready_fast_startup")):
		_fail("ready_to_fast_1 startup did not start from idle_ready")
		return

	# The startup transition owns the body outright. fast_01 must not be visible
	# or parked on frame 0/1 behind it at any point.
	_assert_single_owner("ready_to_fast_1 frame 0", OWNER_VIGIL_FAST_STARTUP)
	_assert_legacy_hidden("ready_to_fast_1 frame 0")
	await process_frame
	_operator.call("_update_animation")
	_assert_single_owner("ready_to_fast_1 mid", OWNER_VIGIL_FAST_STARTUP)
	_assert_legacy_hidden("ready_to_fast_1 mid")
	await process_frame
	_operator.call("_update_animation")
	_assert_single_owner("ready_to_fast_1 mid +1 frame", OWNER_VIGIL_FAST_STARTUP)
	if not bool(_operator.get("_melee_fast_windup")):
		_fail("startup should still be in the fast windup window")

	# Final startup frame, then the release: the startup rig surrenders the body
	# before the attack claims it, so the boundary never shows both.
	_operator.call("_release_vigil_rig", [
		_operator.get("_vigil_startup_lower"),
		_operator.get("_vigil_startup_upper"),
		_operator.get("_vigil_startup_weapon"),
	], OWNER_VIGIL_FAST_STARTUP)
	if int(_operator.call("get_body_presentation_owner")) != OWNER_NONE:
		_fail("startup rig did not surrender the body on release")
	if not (_operator.call("get_visible_body_owners") as Array).is_empty():
		_fail("a body layer is still visible immediately after the startup release")

	# First fast_01 frame: exactly one owner.
	_operator.set("_melee_fast_windup", false)
	_operator.set("_melee_active", true)
	_operator.set("_melee_attack_kind", "fast")
	_operator.set("_melee_attack_key", "unarmed_fast_1")
	_operator.call("_update_animation")
	await process_frame
	_assert_single_owner("first fast_01 frame")
	await process_frame
	_operator.call("_update_animation")
	_assert_single_owner("fast_01 frame +1")
	_operator.set("_melee_active", false)

	# idle_ready after the chain settles.
	_operator.call("_update_animation")
	await process_frame
	_assert_single_owner("idle_ready")


# --- modular locomotion ------------------------------------------------------

func _check_modular_locomotion() -> void:
	_operator.set("using_unarmed", true)
	_operator.set("combat_loadout_mode", "melee")
	_operator.set("primary_weapon_equipped", false)
	_operator.set("movement_direction", Vector2.RIGHT)
	_operator.set("velocity", Vector2.RIGHT * 40.0)
	_operator.call("_update_animation")
	await process_frame
	_assert_single_owner("modular locomotion walk")
	if int(_operator.call("get_body_presentation_owner")) == OWNER_MODULAR_BODY:
		_assert_legacy_hidden("modular locomotion walk")
	_operator.set("is_sprinting", true)
	_operator.set("velocity", Vector2.RIGHT * 120.0)
	_operator.call("_update_animation")
	await process_frame
	_assert_single_owner("modular locomotion run")
	_operator.set("is_sprinting", false)
	_operator.set("velocity", Vector2.ZERO)


# --- legacy / special fallbacks ----------------------------------------------

func _check_legacy_fallback_presentations() -> void:
	# The legacy fallback is still a legitimate owner; it must simply be the
	# only one. Each of these claims the body through the central helper.
	_operator.call("_set_body_presentation_owner", OWNER_LEGACY_FULL_BODY)
	_assert_single_owner("legacy fallback claim", OWNER_LEGACY_FULL_BODY)

	# Block.
	_operator.call("_play_block_animation", &"hold")
	await process_frame
	_assert_single_owner("block")

	# Dodge.
	_operator.set("_dodge_active", true)
	_operator.call("_update_animation")
	await process_frame
	_assert_single_owner("dodge")
	_operator.set("_dodge_active", false)

	# Hit reaction.
	_operator.call("take_damage", 1.0, true, {"attack_id": "ownership_smoke"})
	await process_frame
	_assert_single_owner("hit reaction")
	for _i in range(3):
		await process_frame
		_assert_single_owner("hit reaction settling")

	# Death.
	_operator.call("take_damage", 100000.0, true, {"attack_id": "ownership_smoke_death"})
	await process_frame
	_assert_single_owner("death")


# --- overlays are not bodies -------------------------------------------------

func _check_overlays_do_not_count_as_bodies() -> void:
	# Turning every overlay on must not disturb the invariant: one BODY, not
	# one CanvasItem.
	_operator.call("_set_body_presentation_owner", OWNER_LEGACY_FULL_BODY)
	for node_name in OVERLAY_NODE_NAMES:
		var overlay := _operator.get_node_or_null(node_name) as CanvasItem
		if overlay == null:
			_fail("expected overlay node %s is missing" % node_name)
			continue
		overlay.visible = true
	_assert_single_owner("all overlays visible", OWNER_LEGACY_FULL_BODY)


func _check_owner_api() -> void:
	for method in [
		"get_body_presentation_owner",
		"get_visible_body_owners",
		"_set_body_presentation_owner",
		"_claim_modular_body_owner",
		"_release_modular_body_layers",
		"_is_exclusive_body_owner_active",
	]:
		if not _operator.has_method(method):
			_fail("Operator is missing the ownership entry point %s()" % method)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("operator_visual_ownership_smoke: " + message)


func _report() -> void:
	var passed := _failures.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "operator_visual_ownership_smoke",
		"passed": passed,
		"failure_count": _failures.size(),
		"failures": _failures,
	}))
	if passed:
		print("operator_visual_ownership_smoke: PASS")
		quit(0)
		return
	print("operator_visual_ownership_smoke: FAIL (%d)" % _failures.size())
	for message in _failures:
		print("  - %s" % message)
	quit(1)
