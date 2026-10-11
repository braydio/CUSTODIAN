extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const MARINE_SCENE := preload("res://game/actors/enemies/enemy_marine.tscn")
const SAVAGE_SCENE := preload("res://game/actors/enemies/enemy_savage.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

const STEP_SEC := 1.0 / 60.0
const MAX_ABILITY_STEPS := 180

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "NpaExistingEnemyScenario"
	get_root().add_child(root)
	current_scene = root
	var navigation := Node.new()
	navigation.name = "ScenarioNavigation"
	navigation.add_to_group("navigation")
	root.add_child(navigation)
	await process_frame

	await _exercise_grunt(root)
	await _exercise_marine(root)
	await _exercise_savage(root)
	await _exercise_grunt_loot(root)

	root.queue_free()
	await process_frame
	if _failed:
		push_error("npa_showcase_existing_enemy_smoke failed")
		quit(1)
		return
	print("npa_showcase_existing_enemy_smoke passed")
	quit()


func _new_operator(root: Node, actor_name: String, position: Vector2) -> Node2D:
	var operator := OPERATOR_SCENE.instantiate() as Node2D
	operator.name = actor_name
	operator.global_position = position
	root.add_child(operator)
	operator.set_physics_process(false)
	return operator


func _new_enemy(scene: PackedScene, root: Node, actor_name: String, position: Vector2) -> Enemy:
	var enemy := scene.instantiate() as Enemy
	enemy.name = actor_name
	enemy.global_position = position
	root.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy


func _exercise_grunt(root: Node) -> void:
	var operator := _new_operator(root, "GruntScenarioOperator", Vector2(18.0, 0.0))
	var grunt := _new_enemy(GRUNT_SCENE, root, "ScenarioGrunt", Vector2.ZERO)
	grunt.target = operator
	await process_frame

	var melee := grunt.get_standard_enemy_melee_ability()
	_assert_true(melee.try_start(), "Grunt should accept its first ordinary melee request against the live Operator")
	await _tick_until(func() -> bool: return not melee.is_active(), func(delta: float) -> void: melee.tick(delta), "Grunt melee")
	_assert_true(float(operator.get("health")) < float(operator.get("max_health")), "Grunt ordinary melee should damage the real Operator")

	grunt.request_stagger_reaction(0.5)
	var reaction := grunt.get_reaction_debug_state()
	_assert_true(float(reaction.get("stagger_remaining", 0.0)) > 0.0, "Grunt should enter the public stagger reaction")
	grunt.apply_parry_stagger(Vector2.RIGHT, 0.55, 0.0)
	var parry := grunt.get_parry_critical_debug_state()
	_assert_true(StringName(parry.get("phase", "")) in [&"enter", &"hold"], "Grunt parry should open its critical opportunity")
	_assert_true(grunt.can_receive_parry_critical_from(operator), "the real Operator should qualify for the Grunt critical opportunity")

	operator.queue_free()
	grunt.queue_free()
	await process_frame


func _exercise_marine(root: Node) -> void:
	var operator := _new_operator(root, "MarineScenarioOperator", Vector2(96.0, 0.0))
	var marine := _new_enemy(MARINE_SCENE, root, "ScenarioMarine", Vector2.ZERO)
	marine.target = operator
	await process_frame

	var dash := marine.get_marine_dash_ability()
	dash.try_start(2.0)
	_assert_true(dash.is_active(), "Marine should accept the public dash request")
	await _tick_until(func() -> bool: return dash.terminal_emitted or not dash.is_active(), func(delta: float) -> void: dash.tick(delta), "Marine Dash contact")
	_assert_true(dash.last_attack_hit, "Marine Dash should contact the real Operator during its active travel window")
	_assert_true(StringName(marine.get_marine_dash_debug_state().get("phase", "")) in [&"impact_lock", &"recovery"], "Marine contact should enter its authored impact/recovery lifecycle")
	await _tick_until(func() -> bool: return not dash.is_active(), func(delta: float) -> void: dash.tick(delta), "Marine Dash recovery")
	_assert_true(not dash.is_active(), "Marine Dash should finish recovery")

	operator.queue_free()
	marine.queue_free()
	await process_frame


func _exercise_savage(root: Node) -> void:
	var operator := _new_operator(root, "SavageScenarioOperator", Vector2(48.0, 0.0))
	var savage := _new_enemy(SAVAGE_SCENE, root, "ScenarioSavage", Vector2.ZERO)
	savage.target = operator
	await process_frame

	var pounce := savage.get_savage_pounce_ability()
	_assert_true(pounce.try_start(), "Savage should accept its public pounce request inside the launch band")
	await _tick_until(func() -> bool: return int(pounce.get_debug_state().get("hit_target_count", 0)) > 0 or StringName(pounce.get_debug_state().get("phase", "")) == &"recovery", func(delta: float) -> void: pounce.tick(delta), "Savage Pounce contact")
	_assert_true(float(operator.get("health")) < float(operator.get("max_health")), "Savage Pounce should damage the real Operator")
	_assert_true(StringName(pounce.get_debug_state().get("phase", "")) == &"recovery", "Savage Pounce should enter its authored recovery phase after contact")
	await _tick_until(func() -> bool: return not pounce.is_active(), func(delta: float) -> void: pounce.tick(delta), "Savage Pounce recovery")

	operator.global_position = savage.global_position + Vector2(20.0, 0.0)
	var chain := savage.get_savage_chain_ability()
	var health_before_chain := float(operator.get("health"))
	_assert_true(chain.start(), "Savage should accept its public two-hit chain request")
	await _tick_until(func() -> bool: return StringName(chain.get_debug_state().get("phase", "")) == &"recovery", func(delta: float) -> void: chain.tick(delta), "Savage two-hit chain")
	_assert_true(float(operator.get("health")) <= health_before_chain - 2.0, "Savage chain should resolve both authored hits against the real Operator")
	_assert_true(StringName(chain.get_debug_state().get("phase", "")) == &"recovery", "Savage chain should reach its explicit recovery phase")

	operator.queue_free()
	savage.queue_free()
	await process_frame


func _exercise_grunt_loot(root: Node) -> void:
	var operator := _new_operator(root, "LootScenarioOperator", Vector2.ZERO)
	var grunt := _new_enemy(GRUNT_SCENE, root, "LootScenarioGrunt", Vector2(10000.0, 10000.0))
	var carrier := grunt.get_node("EnemyLootCarrier")
	carrier.call("set_payload", {&"power_components": 1})
	await process_frame

	var lethal := grunt.take_damage(float(grunt.get("health")))
	_assert_true(bool(lethal.get("lethal", false)) and bool(grunt.get("dead")), "lethal damage should enter the real Grunt corpse lifecycle")
	_assert_true(not bool(carrier.call("is_carrying_loot")), "death should transfer the carried resource into the corpse payload once")
	grunt.complete_death_presentation()
	var corpse_loot := grunt.get_node_or_null("CorpseLoot")
	_assert_true(corpse_loot != null and bool(corpse_loot.call("has_loot")), "lethal Grunt should expose its real lootable corpse")
	if corpse_loot != null:
		_assert_true(bool(corpse_loot.call("collect", operator)), "the real Operator should collect the corpse payload")
		var ledger := get_root().get_node_or_null("ResourceLedger")
		var scrap_after_first := int(ledger.call("get_amount", &"ruin_scrap")) if ledger != null else -1
		_assert_true(not bool(corpse_loot.call("collect", operator)), "a second collection request must be rejected")
		var scrap_after_second := int(ledger.call("get_amount", &"ruin_scrap")) if ledger != null else -1
		_assert_true(scrap_after_second == scrap_after_first, "once-only corpse collection must not award a second payload")

	operator.queue_free()
	grunt.queue_free()
	await process_frame


func _tick_until(done: Callable, tick: Callable, label: String) -> void:
	for _step in range(MAX_ABILITY_STEPS):
		if done.call():
			return
		tick.call(STEP_SEC)
		await physics_frame
	_assert_true(done.call(), "%s did not reach its expected semantic state" % label)


func _wait_for_corpse(grunt: Enemy) -> void:
	for _frame in range(120):
		if grunt.get_node_or_null("CorpseLoot") != null or int(grunt.get("life_state")) == 3:
			return
		await process_frame
	_assert_true(grunt.get_node_or_null("CorpseLoot") != null, "Grunt death presentation should finalize into corpse loot")


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
