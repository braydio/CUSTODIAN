extends SceneTree

const BSM := preload("res://game/actors/enemies/enemy_behavior_state_machine.gd")
const BLACKBOARD := preload("res://game/actors/enemies/components/enemy_blackboard.gd")
const PROFILE := preload("res://game/actors/enemies/components/enemy_behavior_profile.gd")

class NoPathEnemy extends Node2D:
	var attempts := 0
	func behavior_move_toward(_target: Vector2, _speed: float) -> bool:
		attempts += 1
		return false
	func behavior_stop() -> void:
		pass

func _init() -> void:
	var enemy := NoPathEnemy.new()
	var machine := BSM.new()
	enemy.add_child(machine)
	root.add_child(enemy)
	var blackboard := BLACKBOARD.new()
	machine.blackboard = blackboard
	machine.profile = PROFILE.create_profile(&"raider_grunt")
	machine._rescore_timer = 1.0
	machine._patrol_target = Vector2(96, 0)
	machine._update_patrol(enemy, 0.016)
	assert(enemy.attempts == 1)
	assert(machine._patrol_target == Vector2.ZERO)
	var source := FileAccess.get_file_as_string("res://game/actors/enemies/enemy.gd")
	assert(source.find("func behavior_move_toward(target_position: Vector2, desired_speed: float) -> bool:") >= 0)
	assert(source.count("if current_path.is_empty():\n\t\treturn Vector2.ZERO") >= 2)
	print("enemy_patrol_navigation_smoke: PASS")
	enemy.free()
	blackboard.free()
	quit(0)
