extends SceneTree

const RECLAIM := preload(
	"res://game/actors/operator/combat/"
	+ "operator_integrity_reclaim.gd"
)
const OPERATOR_SCENE := preload(
	"res://game/actors/operator/operator.tscn"
)
const HUD_SCENE := preload(
	"res://game/ui/hud/custodian_hud.tscn"
)
const ENEMY_SCENE := preload(
	"res://game/actors/enemies/enemy.tscn"
)
const BULLET := preload(
	"res://game/actors/projectiles/bullet.gd"
)
const CombatConstants := preload(
	"res://game/systems/combat/combat_constants.gd"
)

var _fixture_root: Node2D


class ReclaimShooter:
	extends Node2D

	var reports: Array[Dictionary] = []

	func report_confirmed_damage_dealt(
		applied_damage: float,
		context: Dictionary
	) -> float:
		reports.append({
			"applied_damage": applied_damage,
			"context": context.duplicate(true),
		})
		return 0.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	_fixture_root = Node2D.new()
	_fixture_root.name = "ReclaimSmokeRoot"
	root.add_child(_fixture_root)
	current_scene = _fixture_root
	_validate_core_math(errors)
	_validate_packet_lifetimes(errors)
	_validate_rehit_forfeit(errors)
	_validate_rejections_and_overkill(errors)
	_validate_projectile_gateway(errors)
	_validate_healing_clamp(errors)
	_validate_determinism(errors)
	await _validate_hud_presentation(errors)
	await _validate_operator_integration(errors)
	_fixture_root.queue_free()
	await process_frame
	_finish(errors)


func _validate_core_math(errors: Array[String]) -> void:
	var reclaim := _fresh()
	reclaim.record_incoming_damage(
		10.0,
		_incoming(100.0)
	)
	_assert_close(
		reclaim.get_active_amount(),
		5.5,
		"ten damage did not create 5.5 reclaim",
		errors
	)
	var melee_restore: float = reclaim.record_confirmed_damage(
		7.0,
		_confirmed(&"melee", 90.0)
	)
	_assert_close(
		melee_restore,
		3.15,
		"seven melee damage did not restore 3.15",
		errors
	)
	_assert_close(
		reclaim.get_active_amount(),
		2.35,
		"melee restore left the wrong pool",
		errors
	)

	reclaim.clear(&"test_reset")
	reclaim.drain_events()
	reclaim.record_incoming_damage(10.0, _incoming(100.0))
	var ranged_restore: float = reclaim.record_confirmed_damage(
		18.0,
		_confirmed(&"ranged", 90.0)
	)
	_assert_close(
		ranged_restore,
		3.6,
		"ranged recovery did not use 20 percent efficiency",
		errors
	)

	reclaim.clear(&"test_reset")
	reclaim.record_incoming_damage(
		100.0,
		_incoming(100.0)
	)
	_assert_close(
		reclaim.get_active_amount(),
		30.0,
		"reclaim pool exceeded its 30 percent cap",
		errors
	)


func _validate_packet_lifetimes(errors: Array[String]) -> void:
	var reclaim := _fresh()
	reclaim.record_incoming_damage(10.0, _incoming(100.0))
	reclaim.advance_fixed(0.50)
	reclaim.record_incoming_damage(10.0, _incoming(90.0))
	reclaim.advance_fixed(1.61)
	if reclaim.get_packet_count() != 1:
		errors.append(
			"new damage refreshed an older packet lifetime"
		)
	if reclaim.get_window_remaining() <= 0.0:
		errors.append("newer packet expired with the older packet")

	var heavy := _fresh()
	heavy.record_incoming_damage(
		10.0,
		_incoming(
			100.0,
			CombatConstants.HitStrength.HEAVY
		)
	)
	_assert_close(
		heavy.get_window_remaining(),
		3.0,
		"heavy damage did not receive a three-second window",
		errors
	)


func _validate_rehit_forfeit(errors: Array[String]) -> void:
	var reclaim := _fresh()
	reclaim.record_incoming_damage(10.0, _incoming(100.0))
	reclaim.record_incoming_damage(10.0, _incoming(90.0))
	_assert_close(
		reclaim.get_active_amount(),
		9.625,
		"second hit did not forfeit 25 percent before adding",
		errors
	)
	var found_forfeit := false
	for event_variant: Variant in reclaim.drain_events():
		var event := event_variant as Dictionary
		if StringName(event.get("kind", &"")) == &"forfeited" \
		and StringName(event.get("reason", &"")) == &"struck_again":
			found_forfeit = true
	if not found_forfeit:
		errors.append("second-hit forfeiture emitted no event")


func _validate_rejections_and_overkill(
	errors: Array[String]
) -> void:
	for mutation: Dictionary in [
		{"passive": true},
		{"hostile": false, "operator_owned": false},
		{"structure": true},
		{"direct": false, "damage_over_time": true},
	]:
		var reclaim := _fresh()
		reclaim.record_incoming_damage(10.0, _incoming(100.0))
		var context := _confirmed(&"melee", 90.0)
		context.merge(mutation, true)
		if reclaim.record_confirmed_damage(20.0, context) > 0.0:
			errors.append(
				"ineligible damage restored reclaim: %s"
				% mutation
			)

	var enemy := ENEMY_SCENE.instantiate()
	enemy.health = 5.0
	enemy.max_health = 5.0
	_fixture_root.add_child(enemy)
	var result: Dictionary = enemy.take_damage(
		20.0,
		CombatConstants.HitStrength.LIGHT
	)
	_assert_close(
		float(result.get("applied_damage", 0.0)),
		5.0,
		"enemy damage result counted overkill",
		errors
	)
	if is_instance_valid(enemy):
		enemy.free()

	var passive_enemy := ENEMY_SCENE.instantiate()
	passive_enemy.health = 10.0
	passive_enemy.passive = true
	_fixture_root.add_child(passive_enemy)
	var passive_result: Dictionary = passive_enemy.take_damage(2.0)
	if bool(passive_result.get("eligible_hostile", true)):
		errors.append("passive enemy was reclaim-eligible")
	passive_enemy.free()


func _validate_healing_clamp(errors: Array[String]) -> void:
	var reclaim := _fresh()
	reclaim.record_incoming_damage(10.0, _incoming(100.0))
	reclaim.advance_fixed(0.25)
	var before_window: float = reclaim.get_window_remaining()
	reclaim.clamp_to_missing_health(2.0)
	_assert_close(
		reclaim.get_active_amount(),
		2.0,
		"healing did not clamp reclaim to missing health",
		errors
	)
	_assert_close(
		reclaim.get_window_remaining(),
		before_window,
		"healing refreshed the reclaim window",
		errors
	)


func _validate_projectile_gateway(errors: Array[String]) -> void:
	var shooter := ReclaimShooter.new()
	_fixture_root.add_child(shooter)
	var bullet := BULLET.new()
	bullet.team = "player"
	bullet.shooter = shooter
	var target := Node2D.new()
	target.add_to_group("enemy")
	_fixture_root.add_child(target)
	bullet.call(
		"_report_operator_confirmed_damage",
		{
			"applied_damage": 4.0,
			"eligible_hostile": true,
			"target_was_alive": true,
			"passive": false,
			"structure": false,
		},
		target
	)
	if shooter.reports.size() != 1:
		errors.append("player bullet did not report confirmed damage")
	else:
		var report := shooter.reports[0]
		_assert_close(
			float(report.get("applied_damage", 0.0)),
			4.0,
			"bullet reported attempted instead of applied damage",
			errors
		)
		var context := report.get("context", {}) as Dictionary
		if StringName(context.get("reclaim_kind", &"")) != &"ranged":
			errors.append("bullet did not classify reclaim as ranged")
	bullet.free()
	target.free()
	shooter.free()


func _validate_determinism(errors: Array[String]) -> void:
	var first := _deterministic_run()
	var second := _deterministic_run()
	if first != second:
		errors.append(
			"fixed-step reclaim results differ across repeated runs"
		)


func _validate_hud_presentation(
	errors: Array[String]
) -> void:
	var hud := HUD_SCENE.instantiate()
	_fixture_root.add_child(hud)
	await process_frame
	var reclaim_bar := hud.get_node_or_null(
		"Root/TopLeftVitals/Margin/Content/"
		+ "HealthBarStack/ReclaimHealthBar"
	) as ProgressBar
	var health_bar := hud.get_node_or_null(
		"Root/TopLeftVitals/Margin/Content/"
		+ "HealthBarStack/HealthBar"
	) as ProgressBar
	if reclaim_bar == null or health_bar == null:
		errors.append("HUD does not layer reclaim behind health")
	else:
		hud.call("set_health", 90, 100)
		hud.call("set_integrity_reclaim", 90.0, 100.0, 5.5)
		_assert_close(
			health_bar.value,
			90.0,
			"HUD solid health value is wrong",
			errors
		)
		_assert_close(
			reclaim_bar.value,
			95.5,
			"HUD reclaim endpoint is wrong",
			errors
		)
	hud.queue_free()
	await process_frame


func _deterministic_run() -> Dictionary:
	var reclaim := _fresh()
	reclaim.record_incoming_damage(14.0, _incoming(100.0))
	for _step in range(37):
		reclaim.advance_fixed(1.0 / 60.0)
	reclaim.record_confirmed_damage(
		6.0,
		_confirmed(&"melee", 86.0)
	)
	for _step in range(73):
		reclaim.advance_fixed(1.0 / 60.0)
	return {
		"amount": snappedf(reclaim.get_active_amount(), 0.000001),
		"packets": reclaim.get_packet_count(),
		"window": snappedf(
			reclaim.get_window_remaining(),
			0.000001
		),
	}


func _validate_operator_integration(
	errors: Array[String]
) -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var operator := OPERATOR_SCENE.instantiate()
	operator.name = "Operator"
	world.add_child(operator)
	await process_frame
	operator.call(
		"take_damage",
		10.0,
		false,
		{
			"reclaim_eligible": true,
			"hit_strength": CombatConstants.HitStrength.LIGHT,
		}
	)
	var status := (
		operator.call("get_integrity_reclaim_status") as Dictionary
	)
	_assert_close(
		float(status.get("active_amount", 0.0)),
		5.5,
		"Operator did not record incoming reclaim",
		errors
	)
	var restored := float(
		operator.call(
			"report_confirmed_damage_dealt",
			7.0,
			_confirmed(&"melee", 90.0)
		)
	)
	_assert_close(
		restored,
		3.15,
		"Operator gateway restored the wrong amount",
		errors
	)
	operator.call(
		"take_damage",
		200.0,
		false,
		{
			"reclaim_eligible": true,
			"hit_strength": CombatConstants.HitStrength.HEAVY,
		}
	)
	if float(operator.call("get_health")) > 0.0:
		errors.append("reclaim prevented fatal damage")
	status = operator.call(
		"get_integrity_reclaim_status"
	) as Dictionary
	if float(status.get("active_amount", 0.0)) > 0.0:
		errors.append("fatal damage retained a reclaim pool")
	game_root.queue_free()
	await process_frame


func _fresh() -> RefCounted:
	var reclaim := RECLAIM.new()
	reclaim.configure(100.0)
	return reclaim


func _incoming(
	health_before: float,
	hit_strength: int = CombatConstants.HitStrength.LIGHT
) -> Dictionary:
	return {
		"reclaim_eligible": true,
		"target_health_before": health_before,
		"hit_strength": hit_strength,
	}


func _confirmed(
	kind: StringName,
	current_health: float
) -> Dictionary:
	return {
		"operator_owned": true,
		"direct": true,
		"hostile": true,
		"passive": false,
		"structure": false,
		"target_was_alive": true,
		"reclaim_kind": kind,
		"current_health": current_health,
	}


func _assert_close(
	actual: float,
	expected: float,
	label: String,
	errors: Array[String]
) -> void:
	if not is_equal_approx(
		snappedf(actual, 0.00001),
		snappedf(expected, 0.00001)
	):
		errors.append(
			"%s: expected %.5f, got %.5f"
			% [label, expected, actual]
		)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[OperatorIntegrityReclaimSmoke] PASS")
		quit(0)
		return
	for error: String in errors:
		push_error(
			"[OperatorIntegrityReclaimSmoke] %s" % error
		)
	quit(1)
