extends SceneTree

const VAULT_STORAGE_SCRIPT := preload("res://game/actors/storage/vault_storage.gd")
const LOOT_CARRIER_SCRIPT := preload("res://game/actors/enemies/components/enemy_loot_carrier.gd")
const PROFILE_SCRIPT := preload("res://game/actors/enemies/components/enemy_behavior_profile.gd")
const BLACKBOARD_SCRIPT := preload("res://game/actors/enemies/components/enemy_blackboard.gd")
const OBJECTIVE_SENSOR_SCRIPT := preload("res://game/actors/enemies/components/enemy_objective_sensor.gd")

var _failed := false


func _init() -> void:
	var root := Node2D.new()
	root.name = "EnemyBehaviorVaultSmokeRoot"
	get_root().add_child(root)

	var storage := VAULT_STORAGE_SCRIPT.new()
	storage.name = "SmokeVaultStorage"
	storage.resources = {}
	root.add_child(storage)
	storage.add_resources({&"ruin_scrap": 12, &"structural_alloy": 4})
	_assert_true(storage.has_resources(), "storage should report resources")

	var stolen := storage.remove_resources(2, 10)
	_assert_eq(int(stolen.get(&"ruin_scrap", 0)), 10, "storage should remove capped highest-count resource")
	_assert_eq(int(storage.resources.get(&"ruin_scrap", 0)), 2, "storage should retain leftover scrap")
	storage.add_resources(stolen)
	_assert_eq(int(storage.resources.get(&"ruin_scrap", 0)), 12, "recovered payload should restore storage")
	_assert_true(storage.apply_enemy_damage(25, null), "storage should accept enemy damage")
	_assert_eq(int(storage.integrity), 75, "storage integrity should decrease after damage")
	storage.apply_enemy_damage(100, null)
	_assert_true(storage.is_destroyed(), "storage should report destroyed after lethal sabotage damage")
	_assert_true(not storage.has_resources(), "destroyed storage should clear resources")

	var profile = PROFILE_SCRIPT.create_profile(&"iconoclast_looter")
	_assert_true(profile != null, "profile factory should create iconoclast profile")
	_assert_true(bool(profile.get("can_steal_resources")), "iconoclast should be able to steal")
	_assert_true(float(profile.get("theft_weight")) > float(profile.get("aggression_weight")), "iconoclast theft weight should exceed aggression")
	_assert_true(bool(profile.get("can_sabotage_storage")), "iconoclast should be able to sabotage storage")
	_assert_true(float(profile.get("operator_awareness_bubble_px")) > 0.0, "profile should expose close-operator awareness bubble")

	var enemy := Node2D.new()
	enemy.name = "SmokeEnemy"
	root.add_child(enemy)
	var carrier := LOOT_CARRIER_SCRIPT.new()
	carrier.name = "EnemyLootCarrier"
	enemy.add_child(carrier)
	carrier.set_payload({&"ruin_scrap": 3})
	_assert_true(carrier.is_carrying_loot(), "loot carrier should report payload")
	carrier.drop_payload(enemy)
	_assert_true(not carrier.is_carrying_loot(), "loot carrier should clear payload after drop")
	_assert_operator_bubble_overrides_storage(root, profile)

	if _failed:
		push_error("enemy_behavior_vault_smoke failed")
		quit(1)
		return
	print("enemy_behavior_vault_smoke passed")
	quit()


func _assert_operator_bubble_overrides_storage(root: Node2D, profile: Resource) -> void:
	var enemy := Node2D.new()
	enemy.name = "BubbleEnemy"
	enemy.global_position = Vector2.ZERO
	root.add_child(enemy)
	var operator := Node2D.new()
	operator.name = "Operator"
	operator.global_position = Vector2(float(profile.get("operator_awareness_bubble_px")) * 0.5, 0.0)
	operator.add_to_group("player")
	root.add_child(operator)
	var blackboard := BLACKBOARD_SCRIPT.new()
	enemy.add_child(blackboard)
	blackboard.operator_ref = operator
	var sensor := OBJECTIVE_SENSOR_SCRIPT.new()
	enemy.add_child(sensor)
	var objective: Dictionary = sensor.choose_objective(enemy, profile, blackboard)
	_assert_eq(StringName(str(objective.get("type", "none"))), &"operator", "close Operator should override storage objective")
	_assert_true(bool(blackboard.get("is_alerted")), "close Operator bubble should mark blackboard alerted")
	_assert_true(blackboard.get("operator_ref") == operator, "close Operator bubble should set operator_ref")


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
