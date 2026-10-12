extends SceneTree

const BROKEN_WARRANT_SCENE := preload("res://game/actors/enemies/npa_broken_warrant.tscn")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const WAVE_MANAGER_SCRIPT := preload("res://game/systems/core/systems/wave_manager.gd")

const STEP_SEC := 1.0 / 60.0
const MAX_ABILITY_STEPS := 180

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "NpaBrokenWarrantSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	var navigation := Node.new()
	navigation.name = "ScenarioNavigation"
	navigation.add_to_group("navigation")
	root.add_child(navigation)
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	root.add_child(enemies)
	var operator := OPERATOR_SCENE.instantiate() as Node2D
	operator.name = "Operator"
	operator.global_position = Vector2(18.0, 0.0)
	root.add_child(operator)
	operator.set_physics_process(false)
	var wave_manager := WAVE_MANAGER_SCRIPT.new()
	wave_manager.name = "WaveManager"
	wave_manager.enemy_container_path = NodePath("../Enemies")
	wave_manager.grunt_scene = GRUNT_SCENE
	wave_manager.automatic_cadence_enabled = false
	root.add_child(wave_manager)
	await process_frame

	_assert_dev_only_registration(wave_manager)
	var warrant := await _spawn_warrant(wave_manager, operator, Vector2.ZERO)
	if warrant != null:
		await _exercise_combat(warrant, operator)
		warrant.queue_free()
		await process_frame
	await _exercise_corpse_loot(root, operator)

	root.queue_free()
	await process_frame
	if _failed:
		push_error("npa_broken_warrant_smoke failed")
		quit(1)
		return
	print("npa_broken_warrant_smoke passed")
	quit()


func _assert_dev_only_registration(wave_manager: Node) -> void:
	_assert_true(
		wave_manager.call("_scene_for_enemy_type", "broken_warrant") == null,
		"Broken Warrant must not be registered in normal wave composition"
	)
	_assert_true(
		FileAccess.get_file_as_string("res://game/ui/hud/ui.gd").contains('"spawn_broken_warrant"'),
		"Broken Warrant must have an explicit DevConsole spawn command"
	)


func _spawn_warrant(wave_manager: Node, operator: Node2D, position: Vector2) -> Enemy:
	var before := wave_manager.get_node("../Enemies").get_child_count()
	var spawned := bool(wave_manager.call("debug_spawn_enemy_type", "broken_warrant", position))
	await process_frame
	var enemies := wave_manager.get_node("../Enemies")
	_assert_true(spawned and enemies.get_child_count() == before + 1, "dev spawn should create one Broken Warrant")
	if not spawned or enemies.get_child_count() != before + 1:
		return null
	var warrant := enemies.get_child(enemies.get_child_count() - 1) as Enemy
	warrant.set_physics_process(false)
	warrant.target = operator
	return warrant


func _exercise_combat(warrant: Enemy, operator: Node2D) -> void:
	_assert_true(warrant.name == "BrokenWarrant", "scene should carry the BrokenWarrant identity")
	_assert_true(warrant.enemy_name == "BROKEN WARRANT", "combat/log identity should be Broken Warrant")
	_assert_true(warrant.behavior_profile_id == &"raider_broken_warrant", "actor should use its dedicated typed behavior profile")
	var behavior := warrant.get_behavior_snapshot()
	_assert_true(behavior.get("profile_id", "") == "raider_broken_warrant", "diagnostics should expose the dedicated profile identity")
	_assert_true(not warrant.grunt_falcon_punch_enabled, "the Warrant must not inherit Grunt Falcon Punch behavior")
	_assert_true(warrant.custom_enemy_animation_set == "enemy_grunt", "temporary donor animation should be explicit and compatible")
	_assert_true(warrant.get_meta("art_status", "") == "PROVISIONAL_GRUNT_DONOR", "scene must identify donor visuals as provisional")
	_assert_true(warrant.get_meta("art_family_id", "") == "npa_broken_warrant", "missing original art family must remain visible in metadata")
	var collision := warrant.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_assert_true(collision != null and collision.shape != null and collision.disabled == false, "Warrant should retain the real Grunt collision body")
	_assert_true(warrant.collision_layer != 0 and warrant.is_in_group("enemy"), "Warrant should retain enemy collision and relationship registration")
	var melee := warrant.get_standard_enemy_melee_ability()
	_assert_true(melee != null and melee.try_start(), "Warrant should accept the shared ordinary melee request")
	if melee != null:
		await _tick_until(func() -> bool: return not melee.is_active(), func(delta: float) -> void: melee.tick(delta), "Warrant melee")
	_assert_true(float(operator.get("health")) < float(operator.get("max_health")), "Warrant melee should damage the real Operator")

	warrant.request_stagger_reaction(0.5)
	_assert_true(float(warrant.get_reaction_debug_state().get("stagger_remaining", 0.0)) > 0.0, "Warrant should use the shared stagger reaction owner")
	warrant.apply_parry_stagger(Vector2.RIGHT, 0.55, 0.0)
	var parry := warrant.get_parry_critical_debug_state()
	_assert_true(StringName(parry.get("phase", "")) in [&"enter", &"hold"], "Warrant should open the shared parry-critical opportunity")
	_assert_true(warrant.can_receive_parry_critical_from(operator), "the real Operator should qualify for the Warrant critical opportunity")


func _exercise_corpse_loot(root: Node, operator: Node2D) -> void:
	var warrant := BROKEN_WARRANT_SCENE.instantiate() as Enemy
	warrant.name = "BrokenWarrantLootScenario"
	warrant.global_position = Vector2(10000.0, 10000.0)
	root.add_child(warrant)
	warrant.set_physics_process(false)
	var lethal := warrant.take_damage(warrant.health)
	_assert_true(bool(lethal.get("lethal", false)) and warrant.dead, "lethal damage should enter the shared EnemyLifecycle")
	var pending := warrant.get_lifecycle_debug_state().get("pending_payload", {}) as Dictionary
	var resource_payload := pending.get("resource_ledger", {}) as Dictionary
	_assert_true(int(resource_payload.get(&"ruin_scrap", 0)) >= 2, "Warrant should roll guaranteed typed field salvage")
	warrant.complete_death_presentation()
	var corpse_loot := warrant.get_node_or_null("CorpseLoot")
	_assert_true(corpse_loot != null and bool(corpse_loot.call("has_loot")), "lethal Warrant should produce the real lootable corpse")
	if corpse_loot == null:
		return
	var ledger := get_root().get_node_or_null("ResourceLedger")
	_assert_true(ledger != null, "the existing ResourceLedger should own corpse reward delivery")
	if ledger == null:
		return
	var before := int(ledger.call("get_amount", &"ruin_scrap"))
	_assert_true(bool(corpse_loot.call("collect", operator)), "the real Operator should collect Warrant salvage")
	var after_first := int(ledger.call("get_amount", &"ruin_scrap"))
	_assert_true(after_first - before >= 2, "first collection should award the guaranteed Warrant salvage")
	_assert_true(not bool(corpse_loot.call("collect", operator)), "duplicate collection must be rejected")
	_assert_true(int(ledger.call("get_amount", &"ruin_scrap")) == after_first, "duplicate collection must not award a second payload")


func _tick_until(done: Callable, tick: Callable, label: String) -> void:
	for _step in range(MAX_ABILITY_STEPS):
		if done.call():
			return
		tick.call(STEP_SEC)
		await physics_frame
	_assert_true(done.call(), "%s did not reach its expected semantic state" % label)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
