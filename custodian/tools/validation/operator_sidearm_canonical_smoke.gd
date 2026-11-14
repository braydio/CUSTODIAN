extends SceneTree

## C2a-R1: modular_sidearm_sprite is canonical, and its authored-facing policy holds.
##
## The P-9 Sidearm is authored for four diagonals only. The eight runtime sectors
## project onto those four by an explicit authoring decision, resolved ONCE per
## action so the whole authored stack agrees. This asserts the ACTUAL canonical
## animation selected for the renderer, not merely that some animation exists —
## a test that only checks existence would pass with the projection inverted.

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CANONICAL_FRAMES_PATH := "res://content/sprites/operator/runtime/operator_runtime_frames.tres"

## The authoring decision, restated here so the test fails if the table is edited
## without the decision being revisited.
const EXPECTED_SECTOR := {
	&"n": &"ne", &"ne": &"ne",
	&"e": &"se", &"se": &"se", &"s": &"se",
	&"sw": &"sw", &"w": &"sw",
	&"nw": &"nw",
}

const SECTOR_VECTORS := {
	&"e": Vector2(1, 0), &"se": Vector2(1, 1), &"s": Vector2(0, 1), &"sw": Vector2(-1, 1),
	&"w": Vector2(-1, 0), &"nw": Vector2(-1, -1), &"n": Vector2(0, -1), &"ne": Vector2(1, -1),
}

var _failures: Array[String] = []
var _operator: Node = null


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorSidearmCanonicalSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	_operator = OPERATOR_SCENE.instantiate()
	root.add_child(_operator)
	await process_frame

	_check_renderer_is_canonical()
	_check_authored_sector_policy()
	_check_stack_shares_one_sector()
	_check_ranged_2h_stays_distinct()
	_report()


## The renderer must be bound to the generated canonical SpriteFrames, not to a
## compatibility resource.
func _check_renderer_is_canonical() -> void:
	var sidearm := _operator.get_node_or_null("ModularSidearmSprite") as AnimatedSprite2D
	if sidearm == null or sidearm.sprite_frames == null:
		_fail("ModularSidearmSprite has no SpriteFrames")
		return
	if sidearm.sprite_frames.resource_path != CANONICAL_FRAMES_PATH:
		_fail("ModularSidearmSprite is bound to %s, expected the canonical %s" % [
			sidearm.sprite_frames.resource_path, CANONICAL_FRAMES_PATH])
	# A legacy name must no longer be playable on this renderer at all.
	for legacy in ["sidearm_draw", "sidearm_draw_down_right", "ranged_2h_aim_modular"]:
		if sidearm.sprite_frames.has_animation(StringName(legacy)):
			_fail("legacy clip %s is still playable on the canonical renderer" % legacy)


## Every requested sector must select the canonical identity for its AUTHORED
## facing — the actual animation, not just a non-empty result.
func _check_authored_sector_policy() -> void:
	for requested in SECTOR_VECTORS:
		var projected: StringName = _operator.call(
			"_sidearm_authored_sector", SECTOR_VECTORS[requested]
		)
		var expected: StringName = EXPECTED_SECTOR[requested]
		if projected != expected:
			_fail("sector %s projected to %s, expected %s" % [requested, projected, expected])
			continue
		for pair in [[&"posture", &"draw_sidearm_01"], [&"cosmetic", &"fire_sidearm_01"]]:
			var selected: StringName = _operator.call(
				"_resolve_sidearm_weapon_animation", pair[0], pair[1], projected
			)
			var wanted := StringName("sidearm/%s/%s/%s/weapon" % [pair[0], pair[1], expected])
			if selected != wanted:
				_fail("sector %s selected %s, expected %s" % [requested, selected, wanted])


## One authored sector must drive the whole stack; independent per-layer
## resolution is what let the layers drift apart.
func _check_stack_shares_one_sector() -> void:
	for requested in SECTOR_VECTORS:
		var sector: StringName = _operator.call("_sidearm_authored_sector", SECTOR_VECTORS[requested])
		var suffix: String = _operator.call("_sidearm_legacy_sector_suffix", sector)
		var expected_suffix: String = {
			&"ne": "up_right", &"nw": "up_left", &"se": "down_right", &"sw": "down_left",
		}[EXPECTED_SECTOR[requested]]
		if suffix != expected_suffix:
			_fail("sector %s gave legacy suffix %s, expected %s for the same authored facing" % [
				requested, suffix, expected_suffix])


## Despite its name this renderer also carries the ranged_2h weapon layer. A
## ranged_2h request must resolve a ranged_2h identity, never P-9 art.
func _check_ranged_2h_stays_distinct() -> void:
	for action in [&"aim_01", &"stance_01", &"relaxed_01"]:
		for requested in SECTOR_VECTORS:
			var sector: StringName = _operator.call(
				"_ranged_2h_authored_sector", action, SECTOR_VECTORS[requested]
			)
			var group: StringName = &"cosmetic" if action == &"aim_01" else &"posture"
			var selected: StringName = _operator.call(
				"_resolve_ranged_2h_weapon_animation", group, action, sector
			)
			if selected.is_empty():
				_fail("ranged_2h %s sector %s resolved nothing" % [action, requested])
				continue
			if not String(selected).begins_with("ranged_2h/"):
				_fail("ranged_2h %s sector %s resolved non-ranged art: %s" % [
					action, requested, selected])
			if String(selected).contains("sidearm"):
				_fail("ranged_2h %s sector %s resolved P-9 Sidearm art: %s" % [
					action, requested, selected])


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("operator_sidearm_canonical_smoke: " + message)


func _report() -> void:
	var passed := _failures.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "operator_sidearm_canonical_smoke",
		"passed": passed, "failure_count": _failures.size(), "failures": _failures,
	}))
	if passed:
		print("operator_sidearm_canonical_smoke: PASS")
		quit(0)
		return
	print("operator_sidearm_canonical_smoke: FAIL (%d)" % _failures.size())
	for message in _failures:
		print("  - %s" % message)
	quit(1)
