extends SceneTree

## C2a-R2: modular_upper_fx_sprite is canonical, and the FX authoring decisions hold.
##
## Asserts the ACTUAL canonical identity each path selects, not merely that some
## animation exists. FX is optional presentation: a sector with no authored effect
## must render nothing and let gameplay continue, never raise a selector error.

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CANONICAL_FRAMES_PATH := "res://content/sprites/operator/runtime/operator_runtime_frames.tres"

const SECTOR_VECTORS := {
	&"e": Vector2(1, 0), &"se": Vector2(1, 1), &"s": Vector2(0, 1), &"sw": Vector2(-1, 1),
	&"w": Vector2(-1, 0), &"nw": Vector2(-1, -1), &"n": Vector2(0, -1), &"ne": Vector2(1, -1),
}

## The 2026-09-13 decision: parry-success FX is authored e/w, and the historical
## left/right selection is preserved as caller-owned policy.
const EXPECTED_PARRY_SUCCESS_SECTOR := {
	&"nw": &"w", &"w": &"w", &"sw": &"w",
	&"n": &"e", &"ne": &"e", &"e": &"e", &"se": &"e", &"s": &"e",
}

## Sidearm FX must reuse R1's authored action sector, not resolve its own.
const EXPECTED_SIDEARM_SECTOR := {
	&"n": &"ne", &"ne": &"ne",
	&"e": &"se", &"se": &"se", &"s": &"se",
	&"sw": &"sw", &"w": &"sw",
	&"nw": &"nw",
}

## Ranged fire FX always rendered something; the compatibility renderer fell to
## left/right for the sectors it did not author directly.
const EXPECTED_RANGED_FIRE_FX_SECTOR := {
	&"n": &"e", &"ne": &"e", &"e": &"e", &"se": &"se",
	&"s": &"e", &"sw": &"sw", &"w": &"w", &"nw": &"w",
}

var _failures: Array[String] = []
var _operator: Node = null


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorUpperFxCanonicalSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	_operator = OPERATOR_SCENE.instantiate()
	root.add_child(_operator)
	await process_frame

	_check_renderer_is_canonical()
	_check_parry_family()
	_check_sidearm_fx_shares_r1_sector()
	_check_ranged_fire_fx()
	_check_fast_strike_fx()
	_check_optional_fx_is_silent()
	_check_no_runtime_spriteframes_mutation()
	_report()


func _fx() -> AnimatedSprite2D:
	return _operator.get_node_or_null("ModularUpperFxSprite") as AnimatedSprite2D


func _check_renderer_is_canonical() -> void:
	var fx := _fx()
	if fx == null or fx.sprite_frames == null:
		_fail("ModularUpperFxSprite has no SpriteFrames")
		return
	if fx.sprite_frames.resource_path != CANONICAL_FRAMES_PATH:
		_fail("ModularUpperFxSprite is bound to %s, expected %s" % [
			fx.sprite_frames.resource_path, CANONICAL_FRAMES_PATH])
	for legacy in [
		"unarmed_fast_strike_fx_modular", "unarmed_parry_fx", "unarmed_parry_success_01_fx",
		"sidearm_draw_fx", "ranged_2h_fire_modular", "field_patch_use_fx",
		"operator_critical_hitspark_right",
	]:
		if fx.sprite_frames.has_animation(StringName(legacy)):
			_fail("legacy FX clip %s is still playable on the canonical renderer" % legacy)


## parry_01 for an attempt, parry_success_01 for a success, and NO FX for
## failed-parry recovery: the guard contract keeps the original attempt through
## recovery and defines no separate recovery beat.
func _check_parry_family() -> void:
	for requested in SECTOR_VECTORS:
		var expected_success: StringName = EXPECTED_PARRY_SUCCESS_SECTOR[requested]
		var projected: StringName = _operator.call(
			"_reduced_horizontal_sector", SECTOR_VECTORS[requested]
		)
		if projected != expected_success:
			_fail("parry success sector %s projected to %s, expected %s" % [
				requested, projected, expected_success])
			continue
		var selected: StringName = _operator.call(
			"_resolve_fx_animation", &"unarmed", &"defense", &"parry_success_01", projected
		)
		var wanted := StringName("unarmed/defense/parry_success_01/%s/fx" % expected_success)
		if selected != wanted:
			_fail("parry success %s selected %s, expected %s" % [requested, selected, wanted])
		if String(selected).contains("interaction") or String(selected).contains("success_01/") \
		and String(selected).begins_with("unarmed/interaction"):
			_fail("parry success resolved dormant interaction art: %s" % selected)
		if String(selected).contains("parry_recovery"):
			_fail("parry success resolved parry_recovery art: %s" % selected)

	# The attempt itself uses parry_01, which is authored e/n/w.
	for requested in [&"e", &"n", &"w"]:
		var attempt: StringName = _operator.call(
			"_resolve_fx_animation", &"unarmed", &"defense", &"parry_01", requested
		)
		var wanted := StringName("unarmed/defense/parry_01/%s/fx" % requested)
		if attempt != wanted:
			_fail("parry attempt %s selected %s, expected %s" % [requested, attempt, wanted])

	# Failed-parry recovery must present no FX. Asserted on the decision itself:
	# the modular parry path never reaches recovery today because no modular body
	# art exists for that base, so driving it through the whole function would
	# assert nothing at all.
	var fx := _fx()
	if fx != null:
		fx.visible = true
		var recovery: StringName = _operator.call(
			"_present_parry_fx", "unarmed_parry_recovery", Vector2.RIGHT)
		if not recovery.is_empty():
			_fail("failed-parry recovery presented FX %s; the contract defines no recovery beat"
				% recovery)
		if fx.visible:
			_fail("failed-parry recovery left the FX layer visible")
	# The published recovery art must still exist, dormant rather than deleted.
	if not bool(_operator.call(
		"_has_fx_animation", &"unarmed", &"attack", &"parry_recovery_01", &"e")):
		_fail("parry_recovery_01 fx should remain published for a future contract")
	# And the success path must route through the same decision.
	var success: StringName = _operator.call(
		"_present_parry_fx", "unarmed_parry_success_01", Vector2.LEFT)
	if success != &"unarmed/defense/parry_success_01/w/fx":
		_fail("parry success decision presented %s" % success)


func _check_sidearm_fx_shares_r1_sector() -> void:
	for requested in SECTOR_VECTORS:
		var sector: StringName = _operator.call("_sidearm_authored_sector", SECTOR_VECTORS[requested])
		if sector != EXPECTED_SIDEARM_SECTOR[requested]:
			_fail("sidearm FX sector %s projected to %s, expected %s" % [
				requested, sector, EXPECTED_SIDEARM_SECTOR[requested]])
			continue
		for pair in [[&"posture", &"draw_sidearm_01"], [&"cosmetic", &"fire_sidearm_01"]]:
			if not bool(_operator.call("_has_fx_animation", &"sidearm", pair[0], pair[1], sector)):
				continue
			var selected: StringName = _operator.call(
				"_resolve_fx_animation", &"sidearm", pair[0], pair[1], sector)
			var wanted := StringName("sidearm/%s/%s/%s/fx" % [pair[0], pair[1], sector])
			if selected != wanted:
				_fail("sidearm FX %s selected %s, expected %s" % [requested, selected, wanted])


func _check_ranged_fire_fx() -> void:
	for requested in SECTOR_VECTORS:
		var sector: StringName = _operator.call(
			"_ranged_2h_fx_authored_sector", &"fire_01", SECTOR_VECTORS[requested])
		var expected: StringName = EXPECTED_RANGED_FIRE_FX_SECTOR[requested]
		if sector != expected:
			_fail("ranged fire FX sector %s projected to %s, expected %s" % [
				requested, sector, expected])
			continue
		var selected: StringName = _operator.call(
			"_resolve_fx_animation", &"ranged_2h", &"cosmetic", &"fire_01", sector)
		var wanted := StringName("ranged_2h/cosmetic/fire_01/%s/fx" % expected)
		if selected != wanted:
			_fail("ranged fire FX %s selected %s, expected %s" % [requested, selected, wanted])
		if String(selected).contains("sidearm"):
			_fail("ranged fire FX resolved Sidearm art: %s" % selected)


## fast_strike_01 fx is authored for all eight sectors, so every one is exact.
func _check_fast_strike_fx() -> void:
	for requested in SECTOR_VECTORS:
		var selected: StringName = _operator.call(
			"_resolve_fx_animation", &"unarmed", &"attack", &"fast_strike_01", requested)
		var wanted := StringName("unarmed/attack/fast_strike_01/%s/fx" % requested)
		if selected != wanted:
			_fail("fast strike FX %s selected %s, expected %s" % [requested, selected, wanted])


## An unauthored optional FX identity must hide the layer, not error.
func _check_optional_fx_is_silent() -> void:
	if bool(_operator.call("_has_fx_animation", &"unarmed", &"defense", &"parry_success_01", &"n")):
		_fail("fixture assumption broken: parry_success_01 fx should not be authored for n")
		return
	var fx := _fx()
	if fx == null:
		return
	fx.visible = true
	var played: bool = bool(_operator.call(
		"_play_optional_fx", &"unarmed", &"defense", &"parry_success_01", &"n", 1.0))
	if played:
		_fail("optional FX reported playing an unauthored identity")
	if fx.visible:
		_fail("optional missing FX left the layer visible instead of rendering nothing")


## The canonical SpriteFrames is shared; nothing may build into it at runtime.
func _check_no_runtime_spriteframes_mutation() -> void:
	var fx := _fx()
	if fx == null or fx.sprite_frames == null:
		return
	var before := fx.sprite_frames.get_animation_names().size()
	_operator.call("_play_operator_critical_hitspark", Vector2.RIGHT)
	_operator.call("_play_operator_critical_hitspark", Vector2.LEFT)
	var after := fx.sprite_frames.get_animation_names().size()
	if after != before:
		_fail("critical hitspark mutated the shared canonical SpriteFrames (%d -> %d)" % [
			before, after])
	var selected: StringName = _operator.call(
		"_resolve_fx_animation", &"unarmed", &"cosmetic", &"critical_hitspark_01", &"e")
	if selected != &"unarmed/cosmetic/critical_hitspark_01/e/fx":
		_fail("critical hitspark selected %s" % selected)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("operator_upper_fx_canonical_smoke: " + message)


func _report() -> void:
	var passed := _failures.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "operator_upper_fx_canonical_smoke",
		"passed": passed, "failure_count": _failures.size(), "failures": _failures,
	}))
	if passed:
		print("operator_upper_fx_canonical_smoke: PASS")
		quit(0)
		return
	print("operator_upper_fx_canonical_smoke: FAIL (%d)" % _failures.size())
	for message in _failures:
		print("  - %s" % message)
	quit(1)
