extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const BULLET_SCRIPT := preload("res://game/actors/projectiles/bullet.gd")
const GRUNT_ANIMATION_SET: EnemyAnimationSet = preload(
	"res://game/actors/enemies/presentation/sets/enemy_grunt_animation_set.tres"
)

var _failed := false
var _root: Node2D
var _grunt: Enemy
var _behavior: EnemyBehaviorStateMachine
var _blackboard: EnemyBlackboard
var _shooter: CharacterBody2D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_root = Node2D.new()
	_root.name = "EnemyGruntBehaviorPresentationSmoke"
	get_root().add_child(_root)
	current_scene = _root

	_grunt = GRUNT_SCENE.instantiate() as Enemy
	_root.add_child(_grunt)
	_shooter = CharacterBody2D.new()
	_shooter.name = "Shooter"
	_shooter.add_to_group("player")
	_shooter.global_position = Vector2(160.0, 0.0)
	_root.add_child(_shooter)
	await process_frame
	_grunt.set_physics_process(false)
	_behavior = _grunt.get_node("EnemyBehaviorStateMachine") as EnemyBehaviorStateMachine
	_blackboard = _grunt.get_node("EnemyBlackboard") as EnemyBlackboard

	_test_notice_duration_contract()
	_test_fresh_patrol_detection()
	_test_deescalation_and_redraw()
	_test_direct_projectile_hit_memory()
	_test_ready_hit_uses_alert()
	_test_invalid_target_uses_return_home()
	_test_reaction_pauses_draw()
	_test_taunt_interruption()
	_test_debug_snapshot()

	if _failed:
		quit(1)
		return
	print("enemy_grunt_behavior_presentation_smoke: PASS")
	quit(0)


func _test_notice_duration_contract() -> void:
	var draw_duration := GRUNT_ANIMATION_SET.get_clip_duration(&"posture.draw", &"s")
	var alert_duration := GRUNT_ANIMATION_SET.get_clip_duration(&"posture.alert", &"s")
	_expect_near(_behavior.notice_duration_sec, draw_duration, 0.001, "grunt NOTICE must match posture.draw")
	_expect_near(_behavior.notice_duration_sec, alert_duration, 0.001, "grunt NOTICE must match posture.alert")


func _test_fresh_patrol_detection() -> void:
	_reset_relaxed_patrol()
	_behavior.force_notice(_shooter)
	_expect(_behavior.current_state == EnemyBehaviorStateMachine.NOTICE, "fresh detection must enter NOTICE")
	_expect(_grunt._grunt_weapon_posture == Enemy.GruntWeaponPosture.DRAWING, "fresh NOTICE must enter DRAWING")
	_expect(_grunt._grunt_expression_action == &"posture.draw", "fresh NOTICE must play posture.draw")
	_expect(_grunt.velocity.is_zero_approx(), "NOTICE must stop locomotion")
	_behavior.state_time = 0.49
	_behavior.call("_update_notice", _grunt, 0.0)
	_expect(_behavior.current_state == EnemyBehaviorStateMachine.NOTICE, "NOTICE must not finish before 0.50 seconds")
	_grunt._update_grunt_expression(0.50)
	_expect(_grunt._grunt_weapon_posture == Enemy.GruntWeaponPosture.READY, "completed draw must enter READY")
	_behavior.state_time = 0.50
	_behavior.call("_update_notice", _grunt, 0.0)
	_expect(_behavior.current_state == EnemyBehaviorStateMachine.ENGAGE_OPERATOR, "completed NOTICE must engage")
	_grunt.velocity = Vector2(75.0, 0.0)
	_expect(_grunt._get_grunt_locomotion_action() == &"locomotion.run", "READY engage must use armed locomotion")


func _test_deescalation_and_redraw() -> void:
	_behavior.change_state(EnemyBehaviorStateMachine.SEARCH)
	_behavior.change_state(EnemyBehaviorStateMachine.RETURN_HOME)
	_grunt.global_position = _blackboard.home_position
	_blackboard.is_alerted = true
	_blackboard.has_seen_operator = true
	_blackboard.target_visible = true
	_blackboard.pursuit_timer = 1.0
	_blackboard.search_timer = 1.0
	_behavior.call("_update_return_home", _grunt, 0.0)
	_expect(_behavior.current_state == EnemyBehaviorStateMachine.PATROL, "RETURN_HOME arrival must enter PATROL")
	_expect(_grunt._grunt_weapon_posture == Enemy.GruntWeaponPosture.RELAXED, "RETURN_HOME -> PATROL must relax posture")
	_expect(not _blackboard.is_alerted and not _blackboard.has_seen_operator, "de-escalation must clear alerts")
	_expect(not _blackboard.target_visible and _blackboard.pursuit_timer == 0.0, "de-escalation must clear perception memory")
	_behavior.force_notice(_shooter)
	_expect(_grunt._grunt_expression_action == &"posture.draw", "fresh engagement after de-escalation must draw again")


func _test_direct_projectile_hit_memory() -> void:
	_reset_relaxed_patrol()
	_blackboard.target_visible = false
	var bullet := BULLET_SCRIPT.new()
	bullet.shooter = _shooter
	bullet.team = "player"
	_root.add_child(bullet)
	bullet.call("_notify_direct_hit_awareness", _grunt)
	_expect(_blackboard.operator_ref == _shooter, "direct hit must retain attacker identity")
	_expect(_blackboard.is_alerted and _blackboard.is_suspicious, "direct hit must alert and suspect")
	_expect(not _blackboard.target_visible, "direct hit must not fabricate LOS")
	_expect(_blackboard.target_last_seen_position == _shooter.global_position, "direct hit must store shooter position")
	_expect(_blackboard.pursuit_timer >= _behavior.profile.lost_sight_memory_sec, "direct hit must initialize pursuit memory")
	var draw_remaining := _grunt._grunt_expression_timer
	_grunt._recoil_timer = 0.20
	_grunt._update_grunt_expression(0.10)
	_expect_near(_grunt._grunt_expression_timer, draw_remaining, 0.001, "recoil must not consume draw time")
	_grunt._recoil_timer = 0.0
	_grunt._update_grunt_expression(draw_remaining)
	_expect(_grunt._grunt_weapon_posture == Enemy.GruntWeaponPosture.READY, "full draw must follow recoil")
	_behavior.state_time = _behavior.notice_duration_sec
	_behavior.call("_update_notice", _grunt, 0.0)
	_expect(_behavior.current_state == EnemyBehaviorStateMachine.ENGAGE_OPERATOR, "direct hit NOTICE must engage")
	_behavior.call("_update_engage_operator", _grunt, 0.01)
	_expect(_behavior.current_state == EnemyBehaviorStateMachine.ENGAGE_OPERATOR, "stored pursuit memory must prevent immediate SEARCH")
	_expect(_grunt.velocity.x > 0.0, "blind pursuit must move toward stored shooter position")
	_blackboard.pursuit_timer = 0.0
	_behavior.call("_update_engage_operator", _grunt, 0.01)
	_expect(_behavior.current_state == EnemyBehaviorStateMachine.SEARCH, "expired pursuit memory must enter SEARCH")
	bullet.queue_free()


func _test_ready_hit_uses_alert() -> void:
	_grunt._grunt_weapon_posture = Enemy.GruntWeaponPosture.READY
	_behavior.change_state(EnemyBehaviorStateMachine.SEARCH)
	_blackboard.target_visible = false
	_behavior.force_notice(_shooter)
	_expect(_grunt._grunt_expression_action == &"posture.alert", "armed hit notice must alert instead of redraw")
	_expect(_blackboard.pursuit_timer >= _behavior.profile.lost_sight_memory_sec, "armed hit must refresh pursuit memory")


func _test_invalid_target_uses_return_home() -> void:
	_grunt._grunt_weapon_posture = Enemy.GruntWeaponPosture.READY
	_blackboard.operator_ref = null
	_blackboard.investigation_position = Vector2.ZERO
	_behavior.change_state(EnemyBehaviorStateMachine.ENGAGE_OPERATOR)
	_behavior.call("_update_engage_operator", _grunt, 0.01)
	_expect(_behavior.current_state == EnemyBehaviorStateMachine.RETURN_HOME, "invalid engage target must use RETURN_HOME de-escalation")
	_expect(_grunt._grunt_weapon_posture == Enemy.GruntWeaponPosture.READY, "RETURN_HOME must retain armed posture")


func _test_reaction_pauses_draw() -> void:
	_reset_relaxed_patrol()
	_behavior.force_notice(_shooter)
	var before := _grunt._grunt_expression_timer
	_grunt._stagger_timer = 0.25
	_grunt._update_grunt_expression(0.20)
	_expect_near(_grunt._grunt_expression_timer, before, 0.001, "stagger must pause a non-flavor transition")
	_grunt._stagger_timer = 0.0
	_grunt._update_grunt_expression(before)
	_expect(_grunt._grunt_weapon_posture == Enemy.GruntWeaponPosture.READY, "draw must complete after stagger releases presentation")


func _test_taunt_interruption() -> void:
	_reset_relaxed_patrol()
	_grunt._grunt_expression_action = &"flavor.taunt"
	_grunt._grunt_expression_timer = 1.0
	_grunt._grunt_expression_is_flavor = true
	_behavior.force_notice(_shooter)
	_expect(not _grunt._grunt_expression_is_flavor, "NOTICE must cancel flavor immediately")
	_expect(_grunt._grunt_expression_action == &"posture.draw", "draw must own presentation after flavor cancellation")


func _test_debug_snapshot() -> void:
	var snapshot := _grunt.get_debug_snapshot()
	for field in [
		"grunt_weapon_posture", "grunt_expression_action", "grunt_expression_timer",
		"behavior_state", "target_visible", "is_alerted", "is_suspicious",
		"pursuit_timer", "search_timer", "operator_ref_valid",
	]:
		_expect(snapshot.has(field), "debug snapshot must expose %s" % field)


func _reset_relaxed_patrol() -> void:
	_grunt._recoil_timer = 0.0
	_grunt._stagger_timer = 0.0
	_grunt._attack_windup_timer = 0.0
	_grunt._pending_attack_id = ""
	_grunt._grunt_weapon_posture = Enemy.GruntWeaponPosture.RELAXED
	_grunt._grunt_expression_action = &""
	_grunt._grunt_expression_timer = 0.0
	_grunt._grunt_expression_is_flavor = false
	_blackboard.reset_alerts()
	_behavior.change_state(EnemyBehaviorStateMachine.PATROL)
	_grunt.global_position = Vector2.ZERO
	_grunt.velocity = Vector2.ZERO


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _expect_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	_expect(absf(actual - expected) <= tolerance, "%s: got %.4f, expected %.4f" % [message, actual, expected])
