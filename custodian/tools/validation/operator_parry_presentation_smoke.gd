extends SceneTree

## Combat tempo + impact feedback pass: parry success presentation was
## reduced (world VFX scale ~40% down, camera impulse removed) while parry
## mechanics (window, counter window, stagger duration, stamina refund,
## critical-open) stay untouched. This smoke covers the presentation change
## directly; grunt_parry_crit_reaction_smoke.gd covers the critical-open flow.

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

var _failed := false


class CameraImpactProbe:
	extends Node2D
	var impact_calls := 0
	var damage_calls := 0

	func on_attack_impact(_direction: Vector2, _is_heavy: bool = false) -> void:
		impact_calls += 1

	func on_damage_taken(_direction: Vector2) -> void:
		damage_calls += 1


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	get_root().add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var camera_probe := CameraImpactProbe.new()
	camera_probe.name = "Camera2D"
	world.add_child(camera_probe)

	var operator := OPERATOR_SCENE.instantiate()
	world.add_child(operator)
	await process_frame

	var attacker := Node2D.new()
	attacker.name = "DummyAttacker"
	world.add_child(attacker)
	attacker.global_position = operator.global_position + Vector2(30.0, 0.0)

	operator.set("stamina", 10.0)

	operator.call(
		"guard_apply_parry_success",
		attacker,
		Vector2.LEFT,
		{"impact_position": operator.global_position}
	)
	await process_frame

	_assert(
		camera_probe.impact_calls == 0,
		"parry success must not trigger the generic attack-impact camera impulse"
	)

	var burst_root := _find_burst_root(world)
	_assert(burst_root != null, "parry success must spawn its world VFX burst")
	if burst_root != null:
		_assert(
			burst_root.scale.is_equal_approx(Vector2(0.6, 0.6)),
			"parry success burst VFX scale must be reduced ~40%% (expected 0.6, got %s)" % burst_root.scale
		)

	_assert(
		float(operator.get("stamina")) > 10.0,
		"parry stamina refund must be unaffected by the presentation change"
	)

	# Presentation must fire exactly once per call -- a second, independent
	# call spawns exactly one more burst (no doubling within a single call).
	var bursts_after_first := _count_bursts(world)
	operator.call(
		"guard_apply_parry_success",
		attacker,
		Vector2.LEFT,
		{"impact_position": operator.global_position}
	)
	await process_frame
	var bursts_after_second := _count_bursts(world)
	_assert(
		bursts_after_second - bursts_after_first == 1,
		"each parry success call must spawn exactly one presentation burst"
	)

	game_root.queue_free()
	await process_frame
	if _failed:
		push_error("operator_parry_presentation_smoke failed")
		quit(1)
		return
	print("[OperatorParryPresentationSmoke] PASS")
	quit(0)


func _find_burst_root(node: Node) -> Node2D:
	for child in node.get_children():
		if child.name != "DummyAttacker" and child.name != "Camera2D" and child is Node2D and child.get_script() != null and child != node:
			var script := child.get_script() as Script
			if script != null and String(script.resource_path).contains("parry_success_burst_vfx"):
				return child as Node2D
		var found := _find_burst_root(child)
		if found != null:
			return found
	return null


func _count_bursts(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		var script := child.get_script() as Script
		if script != null and String(script.resource_path).contains("parry_success_burst_vfx"):
			count += 1
		count += _count_bursts(child)
	return count


func _assert(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
