extends SceneTree

const BSM := preload("res://game/actors/enemies/enemy_behavior_state_machine.gd")
const BLACKBOARD := preload("res://game/actors/enemies/components/enemy_blackboard.gd")

func _init() -> void:
	var root := Node2D.new(); get_root().add_child(root)
	var first := _sequence(root, 7)
	var repeated := _sequence(root, 7)
	var other := _sequence(root, 8)
	assert(first == repeated)
	assert(first != other)
	var source := FileAccess.get_file_as_string("res://game/actors/enemies/enemy_behavior_state_machine.gd")
	assert(source.find("Time.get_ticks_msec") < 0)
	assert(source.find("Time.get_ticks_usec") < 0)
	assert(source.find("state_time *") < 0)
	print("enemy_behavior_determinism_smoke: PASS fingerprint=%s" % str(first).sha256_text())
	quit(0)

func _sequence(root: Node, spawn_ordinal: int) -> Array:
	var enemy := Node2D.new(); enemy.set_meta("stable_spawn_ordinal", spawn_ordinal); root.add_child(enemy)
	var board := BLACKBOARD.new(); enemy.add_child(board); board.home_position = Vector2(64, 96); board.camp_id = &"smoke"
	var bsm := BSM.new(); enemy.add_child(bsm); bsm.blackboard = board
	var result: Array = []
	for index in 8:
		result.append(bsm._choose_next_patrol_target(enemy))
	result.append(bsm._deterministic_roll(enemy, &"damage_loot_drop", 3))
	enemy.queue_free()
	return result
