extends SceneTree
const BULLET := preload("res://game/actors/projectiles/bullet.gd")
const BSM := preload("res://game/actors/enemies/enemy_behavior_state_machine.gd")
const BLACKBOARD := preload("res://game/actors/enemies/components/enemy_blackboard.gd")
class Victim extends Node2D:
	func _ready() -> void: add_to_group("enemy")
	func receive_projectile_hit(_damage: float, _team: String) -> Dictionary: return {"blocked": true}
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var shooter := Node2D.new(); root.add_child(shooter)
	var victim := Victim.new(); var behavior := BSM.new(); behavior.name = "EnemyBehaviorStateMachine"; behavior.blackboard = BLACKBOARD.new(); victim.add_child(behavior); root.add_child(victim)
	var nearby := Victim.new(); var nearby_behavior := BSM.new(); nearby_behavior.name = "EnemyBehaviorStateMachine"; nearby_behavior.blackboard = BLACKBOARD.new(); nearby.add_child(nearby_behavior); root.add_child(nearby)
	assert(not behavior.blackboard.is_alerted)
	var bullet := BULLET.new(); bullet.team = "player"; bullet.shooter = shooter; root.add_child(bullet)
	assert(bool(bullet.call("_handle_body_hit", victim, Vector2.ZERO)))
	assert(behavior.blackboard.operator_ref == shooter); assert(behavior.blackboard.has_seen_operator); assert(behavior.blackboard.is_alerted)
	assert(behavior.current_state == EnemyBehaviorStateMachine.NOTICE); assert(not nearby_behavior.blackboard.is_alerted)
	print("enemy_direct_hit_awareness_smoke: PASS"); quit(0)
