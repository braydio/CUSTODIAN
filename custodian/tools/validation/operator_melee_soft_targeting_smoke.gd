extends SceneTree

const RESOLVER := preload("res://game/systems/combat/melee_target_resolver.gd")
const PROFILE := preload("res://game/actors/operator/attacks/vigil_pattern_dagger_fast_01.tres")

var _failures: Array[String] = []


func _init() -> void:
	var root_node := Node2D.new()
	root.add_child(root_node)
	var near_off_aim := Node2D.new()
	near_off_aim.name = "NearOffAim"
	near_off_aim.position = Vector2.RIGHT.rotated(deg_to_rad(80.0)) * 30.0
	root_node.add_child(near_off_aim)
	var aimed := Node2D.new()
	aimed.name = "Aimed"
	aimed.position = Vector2.RIGHT.rotated(deg_to_rad(8.0)) * 52.0
	root_node.add_child(aimed)
	var candidates: Array[Dictionary] = [
		{"target": near_off_aim, "target_point": near_off_aim.position},
		{"target": aimed, "target_point": aimed.position},
	]
	var reach := RESOLVER.get_reach_model(PROFILE)
	var config := {
		"preview_reach": 125.0,
		"reliable_reach": reach.reliable_reach,
		"acquire_cone_degrees": 42.0,
		"retain_cone_degrees": 58.0,
		"retain_range_bonus_px": 20.0,
		"current_bonus": 0.18,
		"switch_margin": 0.14,
	}
	var selected := RESOLVER.select_target(Vector2.ZERO, Vector2.RIGHT, candidates, null, config)
	_expect(selected.get("target") == aimed, "nearest off-aim enemy stole soft target")

	var current := Node2D.new()
	current.position = Vector2(60.0, 8.0)
	root_node.add_child(current)
	var slightly_better := Node2D.new()
	slightly_better.position = Vector2(58.0, 6.0)
	root_node.add_child(slightly_better)
	var sticky: Array[Dictionary] = [
		{"target": current, "target_point": current.position},
		{"target": slightly_better, "target_point": slightly_better.position},
	]
	selected = RESOLVER.select_target(Vector2.ZERO, Vector2.RIGHT, sticky, current, config)
	_expect(selected.get("target") == current, "small score change bypassed hysteresis")
	current.position = Vector2.RIGHT.rotated(deg_to_rad(55.0)) * 60.0
	sticky[0]["target_point"] = current.position
	slightly_better.position = Vector2(25.0, 0.0)
	sticky[1]["target_point"] = slightly_better.position
	selected = RESOLVER.select_target(Vector2.ZERO, Vector2.RIGHT, sticky, current, config)
	_expect(selected.get("target") == slightly_better, "decisively better target did not switch")

	var target := Node2D.new()
	target.position = Vector2.RIGHT.rotated(deg_to_rad(20.0)) * 65.0
	root_node.add_child(target)
	var solution := RESOLVER.resolve_attack(Vector2.ZERO, Vector2.RIGHT, target, target.position, PROFILE)
	_expect(absf(float(solution.aim_correction_degrees)) <= 12.001, "attack correction exceeded profile cap")
	_expect(is_equal_approx(absf(float(solution.aim_correction_degrees)), 12.0), "attack correction did not reach cap")
	_expect(float(solution.resolved_drive_distance) <= 10.001, "Fast 01 assist exceeded 3 px bonus")
	var outside := Node2D.new()
	outside.position = Vector2.RIGHT.rotated(deg_to_rad(40.0)) * 60.0
	root_node.add_child(outside)
	var outside_solution := RESOLVER.resolve_attack(Vector2.ZERO, Vector2.RIGHT, outside, outside.position, PROFILE)
	_expect((outside_solution.assisted_direction as Vector2).dot(Vector2.RIGHT) > 0.9999, "target outside assist cone changed direction")
	var no_target := RESOLVER.resolve_attack(Vector2.ZERO, Vector2.RIGHT, null, Vector2.ZERO, PROFILE)
	_expect(is_equal_approx(float(no_target.resolved_drive_distance), 7.0), "no-target attack changed authored drive")
	var preview := RESOLVER.build_preview(selected, reach, 125.0, 42.0)
	_expect(float(preview.proximity) >= 0.0 and float(preview.proximity) <= 1.0, "preview proximity escaped normalized range")

	if _failures.is_empty():
		print("operator_melee_soft_targeting_smoke: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
