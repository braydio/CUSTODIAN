extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

const LAYER_RESOURCE_PATHS := {
	"lower_body": "res://game/actors/operator/operator_modular_lower_body_frames.tres",
	"upper_body": "res://game/actors/operator/operator_modular_upper_body_frames.tres",
	"upper_fx": "res://game/actors/operator/operator_modular_upper_fx_frames.tres",
}

const FAST_ATTACK_SPECS := [
	{"layer": "lower_body", "phase": "windup", "action": "fast_windup_01", "base": "unarmed_fast_windup_lower"},
	{"layer": "upper_body", "phase": "windup", "action": "fast_windup_01", "base": "unarmed_fast_windup_upper"},
	{"layer": "lower_body", "phase": "strike", "action": "fast_strike_01", "base": "unarmed_fast_strike_lower"},
	{"layer": "upper_body", "phase": "strike", "action": "fast_strike_01", "base": "unarmed_fast_strike_upper"},
	{"layer": "upper_fx", "phase": "strike", "action": "fast_strike_01", "base": "unarmed_fast_strike_fx_modular", "optional": true},
	{"layer": "lower_body", "phase": "recovery", "action": "fast_recovery_01", "base": "unarmed_fast_recovery_lower"},
	{"layer": "upper_body", "phase": "recovery", "action": "fast_recovery_01", "base": "unarmed_fast_recovery_upper"},
]

var _failed := false
var _directions := {
	"s": {"vector": Vector2.DOWN, "suffix": "down", "alias_base": true},
	"se": {"vector": Vector2(1, 1).normalized(), "suffix": "down_right"},
	"e": {"vector": Vector2.RIGHT, "suffix": "right"},
	"ne": {"vector": Vector2(1, -1).normalized(), "suffix": "up_right"},
	"n": {"vector": Vector2.UP, "suffix": "up"},
	"nw": {"vector": Vector2(-1, -1).normalized(), "suffix": "up_left"},
	"w": {"vector": Vector2.LEFT, "suffix": "left"},
	"sw": {"vector": Vector2(-1, 1).normalized(), "suffix": "down_left"},
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorModularFastAttackSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	_validate_spriteframes_match_existing_runtime_pngs()
	_validate_runtime_phase_playback(operator)
	_validate_fast_attack_entry_points(operator)

	operator.queue_free()
	if _failed:
		push_error("operator_modular_fast_attack_smoke failed")
		quit(1)
		return
	print("operator_modular_fast_attack_smoke passed")
	quit()


func _validate_spriteframes_match_existing_runtime_pngs() -> void:
	for spec in FAST_ATTACK_SPECS:
		var layer := str(spec["layer"])
		var action := str(spec["action"])
		var base := str(spec["base"])
		var frames := load(str(LAYER_RESOURCE_PATHS[layer])) as SpriteFrames
		_assert_true(frames != null, "missing SpriteFrames for %s" % layer)
		if frames == null:
			continue
		for dir in _directions.keys():
			var source_path := _source_png_path(layer, action, dir)
			var runtime_path := _runtime_png_path(layer, action, dir)
			var source_exists := FileAccess.file_exists(source_path)
			var runtime_exists := FileAccess.file_exists(runtime_path)
			if source_exists:
				_assert_true(runtime_exists, "source exists but runtime module missing: %s" % runtime_path)
			if not runtime_exists:
				continue
			var suffix := str(_directions[dir]["suffix"])
			var animation := StringName("%s_%s" % [base, suffix])
			_assert_playable(frames, animation, "%s %s %s should be registered" % [layer, action, dir])
			if bool(_directions[dir].get("alias_base", false)):
				_assert_playable(frames, StringName(base), "%s %s base alias should be registered" % [layer, action])


func _validate_runtime_phase_playback(operator: Node) -> void:
	operator.set("modular_locomotion_layers_enabled", true)
	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("_melee_attack_key", "unarmed_fast_1")
	for dir in _directions.keys():
		operator.set("_melee_forward", _directions[dir]["vector"])
		_assert_true(bool(operator.call("_sync_modular_fast_attack_phase", &"windup")), "windup should play modular body for %s" % dir)
		_assert_layer_animation(operator, "modular_lower_body_sprite", "unarmed_fast_windup_lower", dir)
		_assert_layer_animation(operator, "modular_upper_body_sprite", "unarmed_fast_windup_upper", dir)
		_assert_true(bool(operator.call("_sync_modular_fast_attack_phase", &"strike")), "strike should play modular body for %s" % dir)
		_assert_layer_animation(operator, "modular_lower_body_sprite", "unarmed_fast_strike_lower", dir)
		_assert_layer_animation(operator, "modular_upper_body_sprite", "unarmed_fast_strike_upper", dir)
		if FileAccess.file_exists(_runtime_png_path("upper_fx", "fast_strike_01", dir)):
			_assert_layer_animation(operator, "modular_upper_fx_sprite", "unarmed_fast_strike_fx_modular", dir)
		_assert_true(bool(operator.call("_sync_modular_fast_attack_phase", &"recovery")), "recovery should play modular body for %s" % dir)
		_assert_layer_animation(operator, "modular_lower_body_sprite", "unarmed_fast_recovery_lower", dir)
		_assert_layer_animation(operator, "modular_upper_body_sprite", "unarmed_fast_recovery_upper", dir)
		operator.call("_clear_modular_fast_attack_layers")


func _validate_fast_attack_entry_points(operator: Node) -> void:
	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("_melee_attack_key", "unarmed_fast_1")
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.set("_active_attack_profile", operator.call("get_current_combat_profile"))
	operator.set("_active_melee_attack_profile", null)
	_assert_true(bool(operator.call("_try_start_fast_attack_windup")), "fast windup entry should start")
	_assert_layer_animation(operator, "modular_lower_body_sprite", "unarmed_fast_windup_lower", "e")
	_assert_layer_animation(operator, "modular_upper_body_sprite", "unarmed_fast_windup_upper", "e")
	var legacy_sprite := operator.get("animated_sprite") as AnimatedSprite2D
	_assert_true(legacy_sprite != null and not legacy_sprite.visible, "legacy body should be hidden during modular windup")

	operator.set("_melee_fast_windup", false)
	operator.set("_melee_active", true)
	operator.set("_melee_attack_kind", "fast")
	_assert_true(bool(operator.call("_sync_modular_action_domains")), "strike action domain sync should prefer true modular lower/upper strike")
	_assert_layer_animation(operator, "modular_lower_body_sprite", "unarmed_fast_strike_lower", "e")
	_assert_layer_animation(operator, "modular_upper_body_sprite", "unarmed_fast_strike_upper", "e")
	_assert_layer_animation(operator, "modular_upper_fx_sprite", "unarmed_fast_strike_fx_modular", "e")

	operator.set("_melee_active", false)
	operator.set("_melee_recovery_active", true)
	operator.call("_play_fast_attack_recovery")
	_assert_layer_animation(operator, "modular_lower_body_sprite", "unarmed_fast_recovery_lower", "e")
	_assert_layer_animation(operator, "modular_upper_body_sprite", "unarmed_fast_recovery_upper", "e")
	operator.set("_melee_recovery_active", false)
	operator.call("_reset_melee_overlay_visuals")


func _source_png_path(layer: String, action: String, dir: String) -> String:
	return "res://content/sprites/operator/new_operator/modular/fast_attack/operator__modular_%s__unarmed__%s__%s__3f__96.png" % [layer, action, dir]


func _runtime_png_path(layer: String, action: String, dir: String) -> String:
	return "res://content/sprites/operator/runtime/modules/new_operator/%s/actions/unarmed/fast_attack/%s/operator__modular_%s__unarmed__%s__%s__3f__96.png" % [layer, action, layer, action, dir]


func _assert_layer_animation(operator: Node, sprite_property: String, base: String, dir: String) -> void:
	var sprite := operator.get(sprite_property) as AnimatedSprite2D
	_assert_true(sprite != null, "%s should exist" % sprite_property)
	if sprite == null:
		return
	var expected := StringName("%s_%s" % [base, str(_directions[dir]["suffix"])])
	_assert_true(sprite.visible, "%s should be visible for %s" % [sprite_property, dir])
	_assert_true(sprite.animation == expected, "%s expected %s got %s" % [sprite_property, String(expected), String(sprite.animation)])


func _assert_playable(frames: SpriteFrames, animation_name: StringName, message: String) -> void:
	_assert_true(frames.has_animation(animation_name), "%s: missing %s" % [message, String(animation_name)])
	if frames.has_animation(animation_name):
		_assert_true(frames.get_frame_count(animation_name) > 0, "%s: no frames" % String(animation_name))


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
