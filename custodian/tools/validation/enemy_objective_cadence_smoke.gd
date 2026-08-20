extends SceneTree

const BSM := preload("res://game/actors/enemies/enemy_behavior_state_machine.gd")
const BLACKBOARD := preload("res://game/actors/enemies/components/enemy_blackboard.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new(); get_root().add_child(root)
	var enemy := Node2D.new(); root.add_child(enemy)
	var board := BLACKBOARD.new(); enemy.add_child(board)
	var machine := BSM.new(); enemy.add_child(machine); machine.blackboard = board
	var current := Node.new(); root.add_child(current)
	board.current_objective = current; board.current_objective_type = &"vault_storage"; board.current_objective_score = 60.0
	assert(not machine._consider_objective_candidate({"type": &"sabotage_storage", "score": 70.0, "target": current, "scores": {"storage": 60.0}}))
	assert(machine._consider_objective_candidate({"type": &"sabotage_storage", "score": 79.0, "target": current, "scores": {"storage": 60.0}}))
	assert(board.objective_switch_count == 1)
	board.current_objective = null
	assert(machine._consider_objective_candidate({"type": &"storage", "score": 1.0, "target": current, "scores": {"sabotage_storage": 100.0}}))
	var source := FileAccess.get_file_as_string("res://game/actors/enemies/enemy_behavior_state_machine.gd")
	var interrupt_start := source.find("func _evaluate_immediate_interrupts")
	var scorer_start := source.find("func _choose_objective_measured")
	assert(interrupt_start >= 0 and scorer_start > interrupt_start)
	assert(source.substr(interrupt_start, scorer_start - interrupt_start).find("_choose_objective_measured") < 0)
	assert(source.find("idle_rescore_interval_sec: float = 0.65") >= 0)
	print("enemy_objective_cadence_smoke: PASS")
	quit(0)
