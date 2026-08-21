extends SceneTree

const CONTRACT := preload("res://game/systems/combat/enemy_hit_spatial_contract.gd")
const MARINE_SCENE := preload("res://game/actors/enemies/enemy_marine.tscn")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")

class DummyTarget:
	extends CharacterBody2D

	var contexts: Array[Dictionary] = []
	var result_mode: StringName = &"damaged"

	func receive_enemy_hit(amount: float, hit_kind: StringName = &"melee", _team: String = "enemy", _attacker: Node2D = null, _direction: Vector2 = Vector2.ZERO, _guard_cost: float = -1.0, attack_context: Dictionary = {}) -> Dictionary:
		contexts.append(attack_context.duplicate(true))
		return {
			"result": result_mode,
			"hit_kind": hit_kind,
			"dodged": result_mode == &"dodged",
			"blocked": false,
			"parried": false,
			"applied_damage": amount if result_mode == &"damaged" else 0.0,
		}


var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_contract_boundaries()
	await _test_standard_melee_range_isolation()
	await _test_marine_hit_and_whiff()
	if not _failed:
		print("ENEMY_HIT_SPATIAL_TELEMETRY_SMOKE: PASS")
	quit(1 if _failed else 0)


func _test_contract_boundaries() -> void:
	var radial_valid := CONTRACT.radial_arc(Vector2.ZERO, Vector2(9.999, 0.0), Vector2.RIGHT, 10.0, 1.0, 0.0, 90.0)
	var radial_boundary := CONTRACT.radial_arc(Vector2.ZERO, Vector2(10.0, 0.0), Vector2.RIGHT, 10.0, 1.0, 0.0, 90.0)
	var radial_out := CONTRACT.radial_arc(Vector2.ZERO, Vector2(10.001, 0.0), Vector2.RIGHT, 10.0, 1.0, 0.0, 90.0)
	var radial_arc_out := CONTRACT.radial_arc(Vector2.ZERO, Vector2(0.0, 5.0), Vector2.RIGHT, 10.0, 1.0, 0.0, 60.0)
	_assert_true(bool(radial_valid.spatial_valid), "radial just-inside should be valid")
	_assert_true(bool(radial_boundary.spatial_valid), "radial exact boundary should be valid")
	_assert_true(not bool(radial_out.spatial_valid) and String(radial_out.spatial_reason) == "target_out_of_range", "radial just-outside should fail range")
	_assert_true(not bool(radial_arc_out.spatial_valid) and String(radial_arc_out.spatial_reason) == "target_out_of_arc", "radial outside arc should fail arc")

	var lane_valid := CONTRACT.directional_lane(Vector2.ZERO, Vector2(9.999, 4.999), Vector2.RIGHT, 4.0, 10.0, 5.0)
	var lane_boundary := CONTRACT.directional_lane(Vector2.ZERO, Vector2(10.0, 5.0), Vector2.RIGHT, 4.0, 10.0, 5.0)
	var lane_forward_out := CONTRACT.directional_lane(Vector2.ZERO, Vector2(10.001, 0.0), Vector2.RIGHT, 4.0, 10.0, 5.0)
	var lane_lateral_out := CONTRACT.directional_lane(Vector2.ZERO, Vector2(5.0, 5.001), Vector2.RIGHT, 4.0, 10.0, 5.0)
	_assert_true(bool(lane_valid.spatial_valid), "lane just-inside should be valid")
	_assert_true(bool(lane_boundary.spatial_valid), "lane exact boundary should be valid")
	_assert_true(not bool(lane_forward_out.spatial_valid) and String(lane_forward_out.spatial_reason) == "outside_forward_lane", "lane forward overflow should fail")
	_assert_true(not bool(lane_lateral_out.spatial_valid) and String(lane_lateral_out.spatial_reason) == "outside_lateral_lane", "lane lateral overflow should fail")


func _test_standard_melee_range_isolation() -> void:
	var scene_root := Node2D.new()
	root.add_child(scene_root)
	current_scene = scene_root
	var grunt := GRUNT_SCENE.instantiate()
	var target := DummyTarget.new()
	target.add_to_group("player")
	scene_root.add_child(grunt)
	scene_root.add_child(target)
	await process_frame
	grunt.set_physics_process(false)
	grunt.global_position = Vector2.ZERO
	target.global_position = Vector2(159.939, 0.0)
	grunt.set("target", target)
	var falcon := grunt.get_grunt_falcon_punch_ability() as GruntFalconPunch
	falcon.normal_attacks_since_special = 1
	falcon.cadence_credit = 1.0
	falcon.cooldown_timer = 0.0
	falcon.recent_parry_timer = 0.0
	_assert_true(is_equal_approx(float(grunt.call("_get_attack_range", target)), 184.0), "Falcon eligibility should still expose its 184px AI launch range")
	grunt.call("_capture_pending_attack_context")
	_assert_true(is_equal_approx(float(grunt.get("_pending_attack_range_px")), 40.0), "ordinary melee must capture the 40px player contact range")
	_assert_true(String(grunt.get("_pending_attack_range_source")) == "standard_melee", "ordinary player melee should identify its contact-range source")
	var spatial := grunt.call("_get_pending_attack_spatial_context", target) as Dictionary
	_assert_true(not bool(spatial.get("spatial_valid", true)), "159.939px ordinary melee must be rejected")
	_assert_true(is_equal_approx(float(spatial.get("allowed_range_px", 0.0)), 56.0), "ordinary melee grace should resolve to 56px")
	_assert_true(is_equal_approx(float(spatial.get("base_contact_range_px", 0.0)), 40.0), "telemetry should retain base melee contact range")
	_assert_true(String(spatial.get("contact_range_source", "")) == "standard_melee", "telemetry should retain standard melee source")
	scene_root.queue_free()
	await process_frame


func _test_marine_hit_and_whiff() -> void:
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory != null and observatory.has_method("clear"):
		observatory.call("clear")
	var scene_root := Node2D.new()
	root.add_child(scene_root)
	current_scene = scene_root
	var marine := MARINE_SCENE.instantiate()
	var target := DummyTarget.new()
	scene_root.add_child(marine)
	scene_root.add_child(target)
	await process_frame
	marine.set_physics_process(false)
	marine.global_position = Vector2.ZERO
	target.global_position = Vector2(20.0, 4.0)
	marine.set("target", target)
	marine.call("_start_marine_dash_windup", Vector2.RIGHT, 20.0)
	var attack_id := String(marine.get("_marine_dash_attack_id"))
	marine.call("_start_marine_dash_travel")
	marine.set("_marine_dash_timer", float(marine.get("marine_dash_time")) * 0.5)
	marine.call("_try_apply_marine_dash_hit")
	_assert_true(target.contexts.size() == 1, "Marine dash should pass one hit context")
	if not target.contexts.is_empty():
		var context := target.contexts[0]
		_assert_true(String(context.get("attack_id", "")) == attack_id, "incoming context should retain Marine attack ID")
		for key in ["attacker_position", "target_position", "separation_px", "forward_distance_px", "allowed_forward_px", "lateral_distance_px", "allowed_lateral_px"]:
			_assert_true(context.has(key), "Marine context should include %s" % key)
		_assert_true(bool(context.get("spatial_valid", false)), "Marine accepted hit should carry spatial_valid=true")
	var hit_events: Array = observatory.call("get_recent_events", 50, &"marine_dash_hit_resolved") if observatory != null else []
	_assert_true(hit_events.size() == 1, "Marine hit should emit exactly one hit terminal")
	if not hit_events.is_empty():
		_assert_true(String((hit_events[0] as Dictionary).get("data", {}).get("attack_id", "")) == attack_id, "Marine lifecycle and hit terminal IDs should match")
	marine.call("_finish_marine_dash_attack")

	if observatory != null and observatory.has_method("clear"):
		observatory.call("clear")
	target.contexts.clear()
	target.global_position = Vector2(200.0, 100.0)
	marine.call("_start_marine_dash_windup", Vector2.RIGHT, 200.0)
	var miss_id := String(marine.get("_marine_dash_attack_id"))
	marine.call("_start_marine_dash_travel")
	marine.set("_marine_dash_timer", float(marine.get("marine_dash_time")) * 0.5)
	marine.call("_try_apply_marine_dash_hit")
	marine.call("_finish_marine_dash_attack")
	var whiffs: Array = observatory.call("get_recent_events", 50, &"marine_dash_whiff") if observatory != null else []
	var hits: Array = observatory.call("get_recent_events", 50, &"marine_dash_hit_resolved") if observatory != null else []
	_assert_true(whiffs.size() == 1 and hits.is_empty(), "Marine miss should emit one whiff and zero hit terminals")
	if not whiffs.is_empty():
		_assert_true(String((whiffs[0] as Dictionary).get("data", {}).get("attack_id", "")) == miss_id, "Marine whiff should retain lifecycle attack ID")
	scene_root.queue_free()


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("enemy_hit_spatial_telemetry_smoke: %s" % message)
