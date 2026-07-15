extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const WAVE_MANAGER_SCRIPT := preload("res://game/systems/core/systems/wave_manager.gd")

const PHASE_ENTER := 1
const PHASE_HOLD := 2
const PHASE_RECOVER := 3

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	current_scene = game_root
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	world.add_child(enemies)

	var operator := OPERATOR_SCENE.instantiate() as Node2D
	operator.name = "Operator"
	world.add_child(operator)
	var wave_manager := WAVE_MANAGER_SCRIPT.new()
	wave_manager.name = "WaveManager"
	wave_manager.grunt_scene = GRUNT_SCENE
	game_root.add_child(wave_manager)
	await process_frame

	await _assert_mode(wave_manager, enemies, operator, &"critical_enter", PHASE_ENTER, &"critical_open_enter_s")
	await _assert_mode(wave_manager, enemies, operator, &"critical_hold", PHASE_HOLD, &"critical_open_hold_s")
	await _assert_mode(wave_manager, enemies, operator, &"critical_recover", PHASE_RECOVER, &"critical_open_recover_s")
	await _assert_mode(wave_manager, enemies, operator, &"execution_ready", PHASE_HOLD, &"critical_open_hold_s")

	var lethal_grunt: Node2D = await _spawn_mode(wave_manager, enemies, operator, &"execution_lethal")
	_assert_true(lethal_grunt != null, "execution_lethal should be accepted")
	if lethal_grunt != null:
		_assert_true(int(lethal_grunt.get("_parry_critical_phase")) == PHASE_HOLD, "execution_lethal should enter hold")
		_assert_true(is_equal_approx(float(lethal_grunt.get("health")), 1.0), "execution_lethal should prepare one-health victim")
		_assert_true(bool(lethal_grunt.call("can_receive_parry_critical_from", operator)), "execution_lethal should remain reservable")

	var child_count_before_unknown := enemies.get_child_count()
	_assert_true(
		not bool(wave_manager.call("debug_spawn_enemy_type", "grunt", operator.global_position + Vector2(48.0, 0.0), 1.0, &"", &"unknown_mode")),
		"unknown debug mode should be rejected"
	)
	_assert_true(enemies.get_child_count() == child_count_before_unknown, "rejected debug mode should not leave a spawned enemy")

	if _failed:
		push_error("debug_grunt_spawn_modes_smoke failed")
		quit(1)
		return
	print("debug_grunt_spawn_modes_smoke ok")
	quit(0)


func _assert_mode(
	wave_manager: Node,
	enemies: Node2D,
	operator: Node2D,
	mode: StringName,
	expected_phase: int,
	expected_animation: StringName
) -> void:
	var grunt: Node2D = await _spawn_mode(wave_manager, enemies, operator, mode)
	_assert_true(grunt != null, "%s should be accepted" % String(mode))
	if grunt == null:
		return
	var body := grunt.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(int(grunt.get("_parry_critical_phase")) == expected_phase, "%s phase mismatch" % String(mode))
	_assert_true(body != null and body.animation == expected_animation, "%s animation mismatch" % String(mode))
	var should_show_opportunity := expected_phase in [PHASE_ENTER, PHASE_HOLD]
	_assert_true(bool(grunt.call("has_active_critical_target_reticle")) == should_show_opportunity, "%s reticle contract mismatch" % String(mode))
	if should_show_opportunity:
		_assert_true(bool(grunt.call("can_receive_parry_critical_from", operator)), "%s should be reservable" % String(mode))


func _spawn_mode(wave_manager: Node, enemies: Node2D, operator: Node2D, mode: StringName) -> Node2D:
	var child_count_before := enemies.get_child_count()
	var spawned := bool(wave_manager.call(
		"debug_spawn_enemy_type",
		"grunt",
		operator.global_position + Vector2(48.0, 0.0),
		1.0,
		&"",
		mode
	))
	await process_frame
	if not spawned or enemies.get_child_count() != child_count_before + 1:
		return null
	return enemies.get_child(enemies.get_child_count() - 1) as Node2D


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
