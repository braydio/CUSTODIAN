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
const BODY_PLAN := preload(
	"res://game/actors/operator/presentation/operator_body_presentation_plan.gd"
)

const OWNER_NONE := 0
const OWNER_LEGACY_FULL_BODY := 1
const OWNER_MODULAR_BODY := 2
const OWNER_VIGIL_POSTURE_TRANSITION := 3
const OWNER_VIGIL_FAST_STARTUP := 4
const OWNER_VIGIL_GUARD := 5

const OWNER_NAMES := {
	OWNER_NONE: "NONE",
	OWNER_LEGACY_FULL_BODY: "LEGACY_FULL_BODY",
	OWNER_MODULAR_BODY: "MODULAR_BODY",
	OWNER_VIGIL_POSTURE_TRANSITION: "VIGIL_POSTURE_TRANSITION",
	OWNER_VIGIL_FAST_STARTUP: "VIGIL_FAST_STARTUP",
	OWNER_VIGIL_GUARD: "VIGIL_GUARD",
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
	_check_present_is_transactional()
	await _check_legacy_clock_is_gone()
	await _check_preempted_startup_lifecycle()
	await _check_owner_scoped_overlays()
	await _check_preempted_rig_lifecycle()
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


# --- the hidden legacy animation clock is gone -------------------------------

## Under modular presentation the legacy body must be invisible AND stopped.
##
## It used to be left playing while hidden because overlay synchronization and
## the melee hit-window scan both read its frame. A renderer nobody can see was
## therefore the timing authority for visible animation and for gameplay, which
## is exactly what OPERATOR_MELEE_CONTACT_TIMING_AND_CADENCE.md forbids.
func _check_legacy_clock_is_gone() -> void:
	# Establish the precondition the bug needs: the legacy body actually PLAYING
	# while it owns the body. Without this the assertion below is vacuous — it
	# was, until reintroducing the bug failed to trip it.
	_operator.call("_set_body_presentation_owner", OWNER_LEGACY_FULL_BODY)
	var legacy_body := _legacy_body()
	if legacy_body == null or legacy_body.sprite_frames == null:
		_fail("legacy clock: legacy body has no frames to play")
		return
	var clip := StringName("")
	for candidate in legacy_body.sprite_frames.get_animation_names():
		if legacy_body.sprite_frames.get_frame_count(candidate) > 1:
			clip = StringName(candidate)
			break
	if clip.is_empty():
		_fail("legacy clock: no multi-frame legacy clip available to play")
		return
	legacy_body.play(clip)
	if not legacy_body.is_playing():
		_fail("legacy clock: could not start legacy playback for the precondition")
		return

	# Exercise the exact handoff that used to leave the clock running. A full
	# `present()` retires everything anyway, so only the modular claim isolates
	# the invariant: hiding the legacy body must also STOP it.
	_operator.call("_claim_modular_body_owner")
	if legacy_body.visible:
		_fail("legacy clock: modular claim left the legacy body visible")
	if legacy_body.is_playing():
		_fail("legacy clock: modular claim left the legacy body PLAYING while hidden")

	_operator.set("using_unarmed", true)
	_operator.set("combat_loadout_mode", "melee")
	_operator.set("primary_weapon_equipped", false)
	_operator.set("movement_direction", Vector2.RIGHT)
	_operator.set("velocity", Vector2.RIGHT * 40.0)
	_operator.call("_update_animation")
	await process_frame

	if int(_operator.call("get_body_presentation_owner")) != OWNER_MODULAR_BODY:
		# Modular art is unavailable in this fixture; the invariant is untestable
		# rather than satisfied, so say so instead of passing silently.
		_fail("legacy clock: modular presentation did not take the body")
		return

	var legacy := _legacy_body()
	if legacy == null:
		_fail("legacy clock: legacy body node is missing")
		return
	if legacy.visible:
		_fail("legacy clock: legacy body is visible under modular presentation")
	if legacy.is_playing():
		_fail("legacy clock: legacy body is still PLAYING under modular presentation")

	# The visible modular body must advance on its own.
	var lower := _operator.get_node_or_null("ModularLowerBodySprite") as AnimatedSprite2D
	if lower == null or not lower.visible:
		_fail("legacy clock: modular lower body is not the visible clock")
		return
	if not lower.is_playing():
		_fail("legacy clock: the visible modular clock is not playing")

	# A tick from the dormant legacy sprite must change nothing at all.
	var weapon := _operator.get_node_or_null("MeleeWeaponOverlaySprite") as AnimatedSprite2D
	var before_frame := weapon.frame if weapon != null else -1
	var before_progress := weapon.frame_progress if weapon != null else -1.0
	var before_flip := weapon.flip_h if weapon != null else false
	legacy.frame_changed.emit()
	if weapon != null:
		if weapon.frame != before_frame or not is_equal_approx(weapon.frame_progress, before_progress):
			_fail("legacy clock: a dormant legacy tick still moved the weapon overlay")
		if weapon.flip_h != before_flip:
			_fail("legacy clock: a dormant legacy tick still corrupted weapon facing")
	_assert_single_owner("modular presentation with the legacy clock retired", OWNER_MODULAR_BODY)

	_operator.set("velocity", Vector2.ZERO)


# --- preempting the ready_to_fast startup ------------------------------------

## The startup rig gets the same lifecycle guarantee as the posture bridge.
##
## Preempting it must retire its body AND its weapon, invalidate its token, and
## leave no stranded windup: an expired startup coroutine waking later must not
## change presentation, and `_melee_fast_windup` must not be left true, which
## would block every subsequent attack.
func _check_preempted_startup_lifecycle() -> void:
	_install_vigil_posture_art()
	if not _failures.is_empty():
		return
	var posture_state = _operator.get("_melee_posture_state")
	if posture_state == null:
		_fail("startup preempt: melee posture state is unavailable")
		return
	posture_state.begin_draw_grace(3.0)
	posture_state.resolve(0.0, true, true, false)
	_operator.set("_melee_fast_combo_step", 0)
	_operator.set("_skip_next_fast_attack_windup", false)
	for key in ["aim_direction", "movement_direction", "visual_idle_direction", "_melee_forward"]:
		_operator.set(key, Vector2.RIGHT)

	if not bool(_operator.call("_try_start_vigil_ready_fast_startup")):
		_fail("startup preempt: ready_to_fast startup did not start")
		return
	_assert_single_owner("startup running", OWNER_VIGIL_FAST_STARTUP)

	var startup_lower := _operator.get("_vigil_startup_lower") as AnimatedSprite2D
	var startup_weapon := _operator.get("_vigil_startup_weapon") as AnimatedSprite2D
	var stale_token := int(_operator.get("_vigil_ready_fast_startup_token"))
	var clock_animation: StringName = startup_lower.animation

	# A legitimate gameplay action takes the body.
	_operator.call("_claim_modular_body_owner")
	if startup_lower != null and startup_lower.visible:
		_fail("startup preempt: preempted startup body is still visible")
	if startup_weapon != null and startup_weapon.visible:
		_fail("startup preempt: preempted startup weapon is still visible")
	if not (_operator.call("get_visible_body_overlays", OWNER_VIGIL_FAST_STARTUP) as Array).is_empty():
		_fail("startup preempt: preempted startup still reports a visible overlay")
	if int(_operator.get("_vigil_ready_fast_startup_token")) == stale_token:
		_fail("startup preempt: startup token was not invalidated by the preempting caller")

	# Drive the abandoned lifecycle past its own duration: it must change nothing.
	var owner_before := int(_operator.call("get_body_presentation_owner"))
	await _operator.call("_finish_vigil_ready_fast_startup", stale_token, clock_animation)
	if int(_operator.call("get_body_presentation_owner")) != owner_before:
		_fail("startup preempt: expired startup lifecycle changed the body owner")
	if startup_weapon != null and startup_weapon.visible:
		_fail("startup preempt: expired startup lifecycle re-showed its weapon")
	if bool(_operator.get("_melee_fast_windup")):
		_fail("startup preempt: _melee_fast_windup was stranded true after preemption")

	# The Operator must still be able to act.
	_operator.set("_melee_active", false)
	_operator.call("_update_animation")
	await process_frame
	_assert_single_owner("after a preempted startup settles")


# --- present() is transactional ----------------------------------------------

## A rejected plan must change nothing.
##
## Validation used to happen mid-mutation: an unregistered layer defaulted to
## looking valid, so the presenter retired the old owner and moved `_owner`
## before `show_layer()` finally refused the bad renderer, leaving the body
## owned by a presentation that never drew.
func _check_present_is_transactional() -> void:
	_operator.call("_set_body_presentation_owner", OWNER_LEGACY_FULL_BODY)
	_assert_single_owner("transactional baseline", OWNER_LEGACY_FULL_BODY)
	var legacy := _legacy_body()

	# An unregistered renderer must be rejected, not adopted.
	var stranger := AnimatedSprite2D.new()
	stranger.name = "UnregisteredStranger"
	_operator.add_child(stranger)
	var plan = BODY_PLAN.create(OWNER_MODULAR_BODY, [stranger])
	# Reporting is suppressed: this drives the real rejection path, and the strict
	# harness reads deliberate engine errors as failures.
	if _operator.call("_can_present_body", plan):
		_fail("transactional: an unregistered body layer was considered valid")
	var accepted: bool = bool(_operator.call("_present_body", plan, false))
	if accepted:
		_fail("transactional: a plan naming an unregistered body layer was accepted")
	if int(_operator.call("get_body_presentation_owner")) != OWNER_LEGACY_FULL_BODY:
		_fail("transactional: a rejected plan still changed the body owner")
	if legacy != null and not legacy.visible:
		_fail("transactional: a rejected plan retired the previous owner's body")
	_assert_single_owner("after rejected plan", OWNER_LEGACY_FULL_BODY)

	# A body layer belonging to another owner must also be rejected outright.
	var modular_lower := _operator.get_node_or_null("ModularLowerBodySprite")
	var cross_plan = BODY_PLAN.create(OWNER_VIGIL_FAST_STARTUP, [modular_lower])
	if bool(_operator.call("_present_body", cross_plan, false)):
		_fail("transactional: a plan reaching for another owner's body layer was accepted")
	if int(_operator.call("get_body_presentation_owner")) != OWNER_LEGACY_FULL_BODY:
		_fail("transactional: a cross-owner plan still changed the body owner")

	stranger.queue_free()


# --- owner-scoped overlays ---------------------------------------------------

## Releasing one owner must never retire another owner's overlay.
##
## A single global overlay pool made `release_modular()` blank the *active*
## authored rig's weapon, which is a floating-sword bug that counting bodies
## cannot see: the bridge body stays correctly visible while its sword vanishes.
func _check_owner_scoped_overlays() -> void:
	_install_vigil_posture_art()
	if not _failures.is_empty():
		return

	if not bool(_operator.call("_start_vigil_posture_bridge", &"relaxed_to_ready_01")):
		_fail("owner-scoped overlays: relaxed_to_ready_01 bridge did not start")
		return
	_assert_single_owner("bridge started", OWNER_VIGIL_POSTURE_TRANSITION)

	var bridge_weapon := _operator.get("_vigil_posture_bridge_weapon") as AnimatedSprite2D
	if bridge_weapon == null:
		_fail("owner-scoped overlays: bridge weapon overlay is missing")
		return
	if not bridge_weapon.visible:
		_fail("owner-scoped overlays: bridge weapon is not visible while the bridge owns the body")
	if (_operator.call("get_visible_body_overlays", OWNER_VIGIL_POSTURE_TRANSITION) as Array).is_empty():
		_fail("owner-scoped overlays: bridge reports no visible owner-scoped overlay")

	# An unrelated modular-release helper must leave this owner entirely alone.
	_operator.call("_release_modular_body_layers")
	_assert_single_owner("after unrelated modular release", OWNER_VIGIL_POSTURE_TRANSITION)
	if not bridge_weapon.visible:
		_fail("owner-scoped overlays: modular release retired the active bridge weapon")

	# The same must hold for the helper that routes through it.
	_operator.call("_hide_modular_locomotion_layers")
	_assert_single_owner("after modular locomotion hide", OWNER_VIGIL_POSTURE_TRANSITION)
	if not bridge_weapon.visible:
		_fail("owner-scoped overlays: modular locomotion hide retired the active bridge weapon")

	_abandon_posture_bridge()
	_check_shared_overlay_survives_handoff()


## An overlay worn by several owners must survive a handoff between them.
##
## Owner-scoping overlays introduces the opposite hazard to the global pool it
## replaces: retiring "every overlay that is not the incoming owner's" blanks a
## cosmetic the incoming owner also wears. The cape rides both the legacy strips
## and the modular rig, so claiming modular must leave it alone.
func _check_shared_overlay_survives_handoff() -> void:
	var cape := _operator.get_node_or_null("ModularCapeSprite") as AnimatedSprite2D
	if cape == null:
		return
	_operator.call("_set_body_presentation_owner", OWNER_LEGACY_FULL_BODY)
	if not _operator.call("_show_presentation_layer", cape):
		_fail("shared overlay: the legacy owner could not show the cape it wears")
		return
	if not cape.visible:
		_fail("shared overlay: cape did not become visible for the legacy owner")
		return
	_operator.call("_claim_modular_body_owner")
	if not cape.visible:
		_fail("shared overlay: claiming modular retired a cape the modular rig also wears")
	# `claim_modular()` deliberately leaves the modular body layers for the caller
	# to fill, so assert the owner rather than a visible body here.
	if int(_operator.call("get_body_presentation_owner")) != OWNER_MODULAR_BODY:
		_fail("shared overlay: modular did not become the body owner")


# --- preemption retires the whole owner, and cancels its lifecycle -----------

## Preempting an owner must retire BOTH its body and its owner-scoped overlays,
## and the abandoned rig's lifecycle must not wake up later and reclaim the
## presentation it no longer owns.
func _check_preempted_rig_lifecycle() -> void:
	if not bool(_operator.call("_start_vigil_posture_bridge", &"relaxed_to_ready_01")):
		_fail("preemption: relaxed_to_ready_01 bridge did not start")
		return
	var bridge_lower := _operator.get("_vigil_posture_bridge_lower") as AnimatedSprite2D
	var bridge_weapon := _operator.get("_vigil_posture_bridge_weapon") as AnimatedSprite2D
	var stale_token := int(_operator.get("_vigil_posture_bridge_token"))
	var clock_animation: StringName = bridge_lower.animation

	# Explicit preemption: the modular composition takes the body.
	_operator.call("_claim_modular_body_owner")
	if int(_operator.call("get_body_presentation_owner")) != OWNER_MODULAR_BODY:
		_fail("preemption: modular did not become the body owner")
	if bridge_lower != null and bridge_lower.visible:
		_fail("preemption: preempted bridge body is still visible")
	if bridge_weapon != null and bridge_weapon.visible:
		_fail("preemption: preempted bridge weapon is still visible")
	if not (_operator.call("get_visible_body_overlays", OWNER_VIGIL_POSTURE_TRANSITION) as Array).is_empty():
		_fail("preemption: preempted bridge still reports a visible overlay")

	# The caller that took the body must have invalidated the bridge lifecycle.
	if int(_operator.get("_vigil_posture_bridge_token")) == stale_token:
		_fail("preemption: bridge token was not invalidated by the preempting caller")
	if String(_operator.get("_vigil_posture_bridge_action")) != "":
		_fail("preemption: preempted bridge still has a pending action")

	# Drive the abandoned lifecycle to completion: it must change nothing.
	var owner_before := int(_operator.call("get_body_presentation_owner"))
	# Yields until the expired bridge's own timer elapses.
	await _operator.call("_finish_vigil_posture_bridge", stale_token, clock_animation)
	if int(_operator.call("get_body_presentation_owner")) != owner_before:
		_fail("preemption: expired bridge lifecycle changed the body owner after waking")
	if bridge_weapon != null and bridge_weapon.visible:
		_fail("preemption: expired bridge lifecycle re-showed its weapon")
	_assert_single_owner("after expired bridge lifecycle woke")


## Retire a bridge the test started, without relying on its timer.
func _abandon_posture_bridge() -> void:
	_operator.set("_vigil_posture_bridge_token",
		int(_operator.get("_vigil_posture_bridge_token")) + 1)
	_operator.call("_release_vigil_rig", [
		_operator.get("_vigil_posture_bridge_lower"),
		_operator.get("_vigil_posture_bridge_upper"),
		_operator.get("_vigil_posture_bridge_weapon"),
	], OWNER_VIGIL_POSTURE_TRANSITION)
	_operator.set("_vigil_posture_bridge_action", &"")
	_operator.set("_vigil_posture_bridge_attack_queued", false)


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
