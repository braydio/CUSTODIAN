extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory == null:
		push_error("[OperatorDodgeOverlapTelemetrySmoke] DevObservatory autoload missing")
		quit(1)
		return
	observatory.clear()
	var scene_root := Node2D.new()
	scene_root.name = "DodgeOverlapSmokeRoot"
	root.add_child(scene_root)
	current_scene = scene_root
	var operator := OPERATOR_SCENE.instantiate()
	operator.name = "DodgeOperator"
	scene_root.add_child(operator)
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
		})
		if StringName(result.get("result", &"")) != expected_result:
			failures.append("overlap %d resolved %s instead of %s" % [attempt, result.get("result", ""), expected_result])

	operator.set("_dodge_active", false)
	operator.set("_dodge_recovery_active", false)
	var classified: Array = observatory.get_recent_events(30, &"incoming_dodge_timing_classified")
	if classified.size() != 20:
		failures.append("20 overlapping hits must produce exactly 20 canonical dodge classifications")
	var classification_counts := {}
	var seen_attack_ids := {}
	for event in classified:
		var data := (event as Dictionary).get("data", {}) as Dictionary
		var classification := String(data.get("classification", ""))
		classification_counts[classification] = int(classification_counts.get(classification, 0)) + 1
		var attack_id := String(data.get("attack_id", ""))
		if attack_id.is_empty() or seen_attack_ids.has(attack_id):
			failures.append("canonical dodge classification lost or duplicated attack_id %s" % attack_id)
		seen_attack_ids[attack_id] = true
	if int(classification_counts.get("iframe_avoid", 0)) != 8:
		failures.append("iframe overlaps did not classify 8/8 as iframe_avoid")
	if int(classification_counts.get("miss_late", 0)) != 6:
		failures.append("late active overlaps did not classify 6/6 as miss_late")
	if int(classification_counts.get("recovery_hit", 0)) != 6:
		failures.append("recovery overlaps did not classify 6/6 as recovery_hit")
	if int(observatory.counters.get("player_iframe_avoids", 0)) != 8:
		failures.append("iframe avoid counter did not reconcile to canonical classifications")
	if int(observatory.counters.get("dodge_timing_miss_late", 0)) != 12:
		failures.append("late/recovery legacy timing counter did not reconcile")

	if not failures.is_empty():
		for failure in failures:
			push_error("[OperatorDodgeOverlapTelemetrySmoke] %s" % failure)
		quit(1)
		return
	print("OPERATOR_DODGE_OVERLAP_TELEMETRY_SMOKE: PASS")
	quit(0)
