extends SceneTree
const PICKUP := preload("res://game/actors/items/cognitive_pickup.gd")
const SENSOR := preload("res://game/actors/enemies/components/enemy_objective_sensor.gd")
const PROFILE := preload("res://game/actors/enemies/components/enemy_behavior_profile.gd")
const BLACKBOARD := preload("res://game/actors/enemies/components/enemy_blackboard.gd")
const BSM := preload("res://game/actors/enemies/enemy_behavior_state_machine.gd")
class Navigation extends Node:
	var reachable := true
	func get_path_to_target(start: Vector2, target: Vector2) -> PackedVector2Array: return PackedVector2Array([start, target]) if reachable else PackedVector2Array()
class TestEnemy extends Node2D:
	var stopped := false
	func behavior_move_toward(_target: Vector2, _speed: float) -> bool: return true
	func behavior_stop() -> void: stopped = true
class Perception extends Node:
	func update_perception(_e, _p, _b, _d): pass
class Objective extends Node:
	func choose_objective(_e, _p, _b): return {}
class Loot extends Node:
	var carried_resources := {}
	func is_carrying_loot(): return false
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var game_root := Node.new(); game_root.name = "GameRoot"; root.add_child(game_root)
	var nav := Navigation.new(); nav.name = "NavigationSystem"; game_root.add_child(nav)
	var enemy := TestEnemy.new(); game_root.add_child(enemy)
	var residue := PICKUP.new(); residue.item_id = &"faint_recollection"; residue.position = Vector2(40, 0); game_root.add_child(residue)
	var sensor := SENSOR.new(); enemy.add_child(sensor); var board := BLACKBOARD.new(); enemy.add_child(board)
	var grunt := PROFILE.create_profile(&"raider_grunt"); var zealot := PROFILE.create_profile(&"zealot_wanderer")
	assert(not grunt.can_seek_cognitive_residue and zealot.can_seek_cognitive_residue)
	assert(float(sensor.choose_objective(enemy, grunt, board).get("scores").cognitive_residue) == 0.0)
	var result := sensor.choose_objective(enemy, zealot, board); assert(result.type == &"cognitive_residue" and result.target == residue)
	nav.reachable = false; assert(float(sensor.choose_objective(enemy, zealot, board).get("scores").cognitive_residue) == 0.0)
	nav.reachable = true; board.is_alerted = true; assert(float(sensor.choose_objective(enemy, zealot, board).get("scores").cognitive_residue) == 0.0); board.is_alerted = false
	var machine := BSM.new(); enemy.add_child(machine); machine.profile = zealot; machine.blackboard = board; machine.perception = Perception.new(); machine.objective_sensor = Objective.new(); machine.loot_carrier = Loot.new()
	machine.call("_apply_objective_choice", result); enemy.position = residue.position; machine.call("_update_seek_cognitive_residue", enemy); machine.call("_update_consume_cognitive_residue", enemy)
	assert(board.cognitive_residue_axis == &"recollection" and board.target_cognitive_residue == null)
	board.cognitive_residue_buff_timer = 0.01; machine.physics_update(enemy, 0.02); assert(board.cognitive_residue_axis == &"")
	print("cognitive_residue_enemy_objective_smoke: PASS"); quit(0)
