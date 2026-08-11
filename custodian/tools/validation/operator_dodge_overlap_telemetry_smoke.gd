extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const HARNESS := preload("res://tools/validation/support/headless_test_harness.gd")

var _harness: RefCounted


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_harness = HARNESS.new()
	_harness.configure(self, "operator_dodge_overlap_telemetry_smoke")
	var observatory: Node = _harness.observatory
	if observatory == null:
		_harness.expect(false, "DevObservatory autoload missing")
		_harness.finish()
		return
	var operator: Node = _harness.instantiate_scene(OPERATOR_SCENE, null, "DodgeOperator")
	await process_frame
	operator.current_health = operator.max_health
	operator.health = operator.max_health

	for attempt in range(20):
		var expected_result := &"damaged"
		if attempt < 8:
			operator.set("_dodge_active", true)
			operator.set("_dodge_iframe_timer", 0.1)
			operator.set("_dodge_recovery_active", false)
			expected_result = &"dodged"
		elif attempt < 14:
			operator.set("_dodge_active", true)
			operator.set("_dodge_iframe_timer", 0.0)
			operator.set("_dodge_recovery_active", false)
		else:
			operator.set("_dodge_active", false)
			operator.set("_dodge_iframe_timer", 0.0)
			operator.set("_dodge_recovery_active", true)
		var result: Dictionary = operator.receive_enemy_hit(1.0, &"melee", "enemy", null, Vector2.RIGHT, -1.0, {
			"attack_id": "dodge-overlap:%d" % attempt,
			"attacker_id": 9001,
			"target_id": operator.get_instance_id(),
			"contact_model": "directional_lane",
			"spatial_valid": true,
			"attacker_position": operator.global_position - Vector2.RIGHT,
			"target_position": operator.global_position,
			"contact_position": operator.global_position,
			"separation_px": 1.0,
		})
		if StringName(result.get("result", &"")) != expected_result:
			_harness.expect(false, "overlap %d resolved %s instead of %s" % [attempt, result.get("result", ""), expected_result])

	operator.set("_dodge_active", false)
	operator.set("_dodge_recovery_active", false)
	var classified: Array = observatory.get_recent_events(30, &"incoming_dodge_timing_classified")
	if classified.size() != 20:
		_harness.expect(false, "20 overlapping hits must produce exactly 20 canonical dodge classifications")
	var classification_counts := {}
	var seen_attack_ids := {}
	for event in classified:
		var data := (event as Dictionary).get("data", {}) as Dictionary
		var classification := String(data.get("classification", ""))
		classification_counts[classification] = int(classification_counts.get(classification, 0)) + 1
		var attack_id := String(data.get("attack_id", ""))
		if attack_id.is_empty() or seen_attack_ids.has(attack_id):
			_harness.expect(false, "canonical dodge classification lost or duplicated attack_id %s" % attack_id)
		seen_attack_ids[attack_id] = true
	if int(classification_counts.get("iframe_avoid", 0)) != 8:
		_harness.expect(false, "iframe overlaps did not classify 8/8 as iframe_avoid")
	if int(classification_counts.get("miss_late", 0)) != 6:
		_harness.expect(false, "late active overlaps did not classify 6/6 as miss_late")
	if int(classification_counts.get("recovery_hit", 0)) != 6:
		_harness.expect(false, "recovery overlaps did not classify 6/6 as recovery_hit")
	if int(observatory.counters.get("player_iframe_avoids", 0)) != 8:
		_harness.expect(false, "iframe avoid counter did not reconcile to canonical classifications")
	if int(observatory.counters.get("dodge_timing_miss_late", 0)) != 12:
		_harness.expect(false, "late/recovery legacy timing counter did not reconcile")
	var incoming: Array = observatory.get_recent_events(30, &"incoming_hit_result")
	if incoming.size() != 20:
		_harness.expect(false, "20 overlaps must retain exactly 20 incoming hit results")
	var incoming_classifications := {}
	for event in incoming:
		var data := (event as Dictionary).get("data", {}) as Dictionary
		var classification := String(data.get("dodge_classification", ""))
		incoming_classifications[classification] = int(incoming_classifications.get(classification, 0)) + 1
		if String(data.get("player_dodge_phase", "")).is_empty():
			_harness.expect(false, "incoming result lost canonical player_dodge_phase")
		if not bool(data.get("spatial_valid", false)):
			_harness.expect(false, "incoming result lost authoritative spatial validity")
	if int(incoming_classifications.get("iframe_avoid", 0)) != 8:
		_harness.expect(false, "incoming iframe results lost iframe_avoid classification")
	if int(incoming_classifications.get("recovery_hit", 0)) != 6:
		_harness.expect(false, "incoming recovery hits lost recovery_hit classification")

	operator.current_health = 1.0
	operator.health = 1.0
	operator.receive_enemy_hit(2.0, &"dash", "enemy", null, Vector2.RIGHT, -1.0, {
		"attack_id": "dodge-overlap:lethal",
		"attack_type": "marine_dash",
		"contact_model": "directional_lane",
		"spatial_valid": true,
		"attacker_position": operator.global_position - Vector2.RIGHT,
		"target_position": operator.global_position,
		"contact_position": operator.global_position,
		"separation_px": 1.0,
	})
	var deaths: Array = observatory.get_recent_events(2, &"player_death")
	if deaths.size() != 1:
		_harness.expect(false, "lethal hit should emit one player_death record")
	else:
		var death_data := (deaths[0] as Dictionary).get("data", {}) as Dictionary
		var lethal_context := death_data.get("lethal_attack_context", {}) as Dictionary
		if String(lethal_context.get("attack_id", "")) != "dodge-overlap:lethal":
			_harness.expect(false, "player_death lost lethal attack correlation")
		if not bool(lethal_context.get("lethal", false)) or float(lethal_context.get("target_health_after", -1.0)) != 0.0:
			_harness.expect(false, "player_death lethal context lost predicted health transition")

	_harness.finish()
