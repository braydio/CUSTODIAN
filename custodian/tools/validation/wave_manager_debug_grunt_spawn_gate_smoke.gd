extends SceneTree

const WAVE_MANAGER_SCRIPT := preload("res://game/systems/core/systems/wave_manager.gd")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)

	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)

	var enemies := Node2D.new()
	enemies.name = "Enemies"
	world.add_child(enemies)

	var operator := Node2D.new()
	operator.name = "Operator"
	operator.global_position = Vector2(100.0, 200.0)
	world.add_child(operator)

	var wave_manager := WAVE_MANAGER_SCRIPT.new()
	wave_manager.name = "WaveManager"
	wave_manager.grunt_scene = GRUNT_SCENE
	wave_manager.debug_spawn_grunt_on_start = true
	wave_manager.debug_start_grunt_offset = Vector2(96.0, 0.0)
	wave_manager.debug_start_grunt_trigger_distance = 128.0
	root.add_child(wave_manager)

	await process_frame
	await process_frame
	await process_frame

	if enemies.get_child_count() != 0:
		push_error("debug startup grunt should not spawn while operator remains inside spawn threshold")
		quit(1)
		return

	operator.global_position += Vector2(160.0, 0.0)
	await process_frame
	await process_frame

	if enemies.get_child_count() != 1:
		push_error("debug startup grunt should spawn once after operator crosses spawn threshold; count=%d" % enemies.get_child_count())
		quit(1)
		return

	var grunt := enemies.get_child(0) as Node2D
	var expected_position := Vector2(196.0, 200.0)
	if grunt == null or not grunt.global_position.is_equal_approx(expected_position):
		push_error("debug startup grunt should spawn at original spawn-zone offset; got=%s expected=%s" % [str(grunt.global_position if grunt != null else Vector2.INF), str(expected_position)])
		quit(1)
		return

	print("wave_manager_debug_grunt_spawn_gate_smoke passed")
	quit()
