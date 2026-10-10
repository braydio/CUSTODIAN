extends SceneTree

const SCENE_CASES: Array[Dictionary] = [
	{"path": "res://game/actors/enemies/enemy.tscn", "health": 60.0, "drop_min": 0, "drop_max": 0, "fallback": true},
	{"path": "res://game/actors/enemies/enemy_grunt.tscn", "health": 78.0, "drop_min": 1, "drop_max": 3, "fallback": true},
	{"path": "res://game/actors/enemies/enemy_marine.tscn", "health": 96.0, "drop_min": 2, "drop_max": 4, "fallback": true},
	{"path": "res://game/actors/enemies/enemy_savage.tscn", "health": 64.0, "drop_min": 0, "drop_max": 2, "fallback": true},
	{"path": "res://game/actors/enemies/pursuit_frame.tscn", "health": 92.0, "drop_min": 1, "drop_max": 3, "fallback": true},
	{"path": "res://game/actors/enemies/fast_drone.tscn", "health": 42.0, "drop_min": 0, "drop_max": 0, "fallback": true},
	{"path": "res://game/actors/enemies/heavy_drone.tscn", "health": 145.0, "drop_min": 0, "drop_max": 0, "fallback": true},
	{"path": "res://game/actors/enemies/dev/enemy_humanoid_cutout_test.tscn", "health": 50.0, "drop_min": 0, "drop_max": 0, "fallback": false},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var default_config := load(
		"res://game/actors/enemies/components/configs/enemy_lifecycle_default.tres"
	) as EnemyLifecycleConfig
	_assert_true(default_config != null, "default lifecycle config must load")
	if default_config != null:
		_assert_true(is_equal_approx(default_config.starting_health, 50.0), "default health must remain 50")
		_assert_true(is_equal_approx(default_config.maximum_health, 50.0), "default maximum health must remain 50")
		_assert_true(default_config.material_drop_fallback_enabled, "default legacy material fallback must remain enabled")
		_assert_true(is_equal_approx(default_config.empty_corpse_min_lifetime_sec, 8.0), "default corpse minimum lifetime must remain 8 seconds")
		_assert_true(is_equal_approx(default_config.corpse_offscreen_margin_px, 96.0), "default corpse offscreen margin must remain 96 px")
		_assert_true(is_equal_approx(default_config.empty_corpse_hard_lifetime_sec, 45.0), "default corpse hard lifetime must remain 45 seconds")
		_assert_true(is_equal_approx(default_config.corpse_loot_pickup_radius_px, 22.0), "default pickup radius must remain 22 px")
		_assert_true(default_config.corpse_loot_marker_offset == Vector2(0.0, -8.0), "default marker offset must remain unchanged")

	for case in SCENE_CASES:
		_validate_scene_config(case)

	if _failed:
		push_error("enemy_lifecycle_config_smoke failed")
		quit(1)
		return
	print("enemy_lifecycle_config_smoke passed")
	quit()


func _validate_scene_config(case: Dictionary) -> void:
	var scene := load(str(case["path"])) as PackedScene
	_assert_true(scene != null, "%s must load as a PackedScene" % case["path"])
	if scene == null:
		return
	var scene_state := scene.get_state()
	var config: EnemyLifecycleConfig = null
	for node_index in range(scene_state.get_node_count()):
		for property_index in range(scene_state.get_node_property_count(node_index)):
			if String(scene_state.get_node_property_name(node_index, property_index)) == "lifecycle_config":
				config = scene_state.get_node_property_value(node_index, property_index) as EnemyLifecycleConfig
				break
	_assert_true(config != null, "%s must bind a typed lifecycle config" % case["path"])
	if config == null:
		return
	_assert_true(is_equal_approx(config.starting_health, float(case["health"])), "%s starting health changed" % case["path"])
	_assert_true(is_equal_approx(config.maximum_health, float(case["health"])), "%s maximum health changed" % case["path"])
	_assert_true(config.material_drop_min == int(case["drop_min"]), "%s minimum material drop changed" % case["path"])
	_assert_true(config.material_drop_max == int(case["drop_max"]), "%s maximum material drop changed" % case["path"])
	_assert_true(config.material_drop_fallback_enabled == bool(case["fallback"]), "%s material fallback policy changed" % case["path"])
	if str(case["path"]).ends_with("enemy_grunt.tscn"):
		_assert_true(config.loot_table_id == "practical_salvage_x_grunt", "Grunt loot table identity changed")
		_assert_true(config.loot_table.size() == 7, "Grunt loot table entries changed")


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
