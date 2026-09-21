extends SceneTree
## An armed melee swing must actually be drawn, not merely started.
##
## `OperatorBodyPresenter.present()` retires every outgoing renderer, and retiring
## stops playback. So a full-body attack clip started while the modular rig still
## owns the body is killed by the very next ownership transfer: the presenter
## stops `animated_sprite` mid-swing and re-shows it without restarting anything.
## Gameplay proceeds, the FX overlay still flashes because it is a separate layer,
## and the sword swings invisibly.
##
## Every existing melee gate missed this because they all assert gameplay phases --
## `_melee_active`, anticipation, chain steps -- and none asserted that the body
## renderer was visible, playing, and owned. This one does, for each link of the
## real chain and for the heavy attack's active phase.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const SWORD_CLEAVER := preload("res://game/actors/operator/sword_cleaver_definition.tres")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorArmedMeleeBodyVisibilityRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	if await _select_melee(operator):
		await _check_fast_chain_body_is_drawn(operator)
		await _check_heavy_active_body_is_drawn(operator)

	operator.queue_free()
	if _failures.is_empty():
		print("operator_armed_melee_body_visibility_smoke passed")
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator_armed_melee_body_visibility_smoke: %d failure(s)" % _failures.size())
	quit(1)


## Select the Sword-Cleaver specifically, not merely the first melee weapon.
##
## The Vigil dagger routes a fast attack from RELAXED through its authored
## relaxed-to-ready bridge and queues the swing behind it, so `_melee_active` is
## deliberately false on the requesting frame and the bridge owns the body. That
## is correct vigil behaviour, and testing it here would measure the bridge rather
## than the ownership handoff this gate exists for. The Cleaver swings directly.
func _select_melee(operator: Node) -> bool:
	var armed: Array = operator.get("armed_weapons")
	if armed == null:
		_failures.append("armed_weapons should exist")
		return false
	# The shipped scene equips the Vigil dagger, so the Cleaver is installed here
	# through the actor's own loadout rebuild rather than assumed present.
	operator.set("melee_weapon_definition", SWORD_CLEAVER)
	operator.call("_rebuild_armed_weapon_list")
	await process_frame
	armed = operator.get("armed_weapons")
	for index in armed.size():
		var profile = armed[index]
		if profile != null and String(profile.weapon_id) == "sword_cleaver":
			operator.call("_apply_armed_selection", index)
			await process_frame
			var current = operator.call("get_current_combat_profile")
			_check(
				current != null and String(current.weapon_id) == "sword_cleaver",
				"the Sword-Cleaver should be the active profile"
			)
			return true
	_failures.append("Sword-Cleaver not in armed_weapons; the body visibility check did not run")
	return false


## Settle into the ordinary modular melee posture first.
##
## This is the state the bug needed: the modular rig owns the body when the swing
## starts, so the attack's own ownership transfer is what stops it. Starting from
## an already-legacy owner would hide the defect entirely.
func _settle_into_posture(operator: Node) -> void:
	operator.set("velocity", Vector2.ZERO)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.set("_melee_active", false)
	operator.set("_melee_heavy_anticipating", false)
	operator.set("_melee_recovery_active", false)
	operator.set("melee_cooldown_remaining", 0.0)
	for _i in 3:
		operator.call("_update_animation")
		await process_frame


func _assert_body_is_drawn(operator: Node, context: String) -> void:
	var body := operator.get("animated_sprite") as AnimatedSprite2D
	var presenter = operator.get("_body_presenter")
	_check(body != null, "%s: the legacy full body renderer should exist" % context)
	if body == null:
		return

	_check(
		presenter == null
			or int(presenter.call("current_owner")) == OperatorBodyPresenter.Owner.LEGACY_FULL_BODY,
		"%s: the legacy full body should own the body, owner is %s"
			% [context, "unknown" if presenter == null else presenter.call("current_owner")]
	)
	_check(body.visible, "%s: the attacking body should be visible" % context)
	_check(
		body.is_playing(),
		"%s: the attack clip should still be playing, not stopped by an ownership "
			% context
			+ "transfer (showing %s)" % String(body.animation)
	)
	_check(
		not String(body.animation).is_empty(),
		"%s: the body should be showing an attack clip" % context
	)
	var clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
	_check(
		clock == body,
		"%s: the attacking body should own the presentation clock, otherwise the chain "
			% context
			+ "loses its cadence"
	)
	if presenter != null:
		var owners: Array = presenter.call("visible_owners")
		_check(
			owners.size() <= 1,
			"%s: at most one body owner should be visible, saw %s" % [context, owners]
		)


func _check_fast_chain_body_is_drawn(operator: Node) -> void:
	## Each link of the real chain, driven through `_try_melee_attack`.
	for link in 3:
		await _settle_into_posture(operator)
		var context := "fast chain link %d" % (link + 1)
		# Set the aim immediately before the swing. `_get_melee_forward_direction()`
		# reads live aim, and the settle frames above can recompute it; a degenerate
		# facing would send the vigil startup at an unauthored sector and drown the
		# real assertions in unrelated missing-animation errors.
		operator.set("aim_direction", Vector2.RIGHT)
		operator.call("_try_melee_attack", "melee_fast")
		await process_frame
		if not bool(operator.get("_melee_active")):
			_failures.append("%s: the attack should start" % context)
			continue
		var attack_key := String(operator.get("_melee_attack_key"))
		_assert_body_is_drawn(operator, "%s (%s)" % [context, attack_key])

		# The body must survive the frame that transfers ownership, which is when
		# the presenter retires the outgoing renderers.
		operator.call("_update_animation")
		await process_frame
		_assert_body_is_drawn(operator, "%s after the ownership transfer" % context)

		# Advance the real chain so the next link starts from a genuine mid-chain
		# state rather than a fresh attack.
		var guard := 0
		while bool(operator.get("_melee_active")) and guard < 240:
			operator.call("_update_melee_attack", 0.05)
			guard += 1
		await process_frame


func _check_heavy_active_body_is_drawn(operator: Node) -> void:
	await _settle_into_posture(operator)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.call("_start_heavy_attack")
	await process_frame
	if not bool(operator.get("_melee_heavy_anticipating")):
		_failures.append("heavy: anticipation should start")
		return
	_assert_body_is_drawn(operator, "heavy anticipation")

	operator.call("_update_animation")
	await process_frame
	_assert_body_is_drawn(operator, "heavy anticipation after the ownership transfer")

	var clock := operator.call("_presentation_clock_sprite") as AnimatedSprite2D
	operator.call("_on_operator_animation_finished", clock)
	await process_frame
	if not bool(operator.get("_melee_active")):
		_failures.append("heavy: the active phase should begin after anticipation")
		return
	_assert_body_is_drawn(operator, "heavy active phase")
	operator.call("_update_animation")
	await process_frame
	_assert_body_is_drawn(operator, "heavy active phase after the ownership transfer")
