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
	_validate_roll_exit_ingest_registration()
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


func _validate_roll_exit_ingest_registration() -> void:
	var body_frames := load("res://game/actors/operator/operator_runtime_frames.tres") as SpriteFrames
	var fx_frames := load("res://game/actors/operator/operator_melee_overlay_frames.tres") as SpriteFrames
	var cape_frames := load("res://game/actors/operator/operator_modular_cape_frames.tres") as SpriteFrames
	for direction in ["e", "w"]:
		var suffix := "right" if direction == "e" else "left"
		var body_path := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__dodge_fast_attack_01__%s__11f__96.png" % direction
		var fx_path := "res://content/sprites/operator/runtime/overlays/unarmed/operator__fx__unarmed__dodge_fast_attack_01__%s__11f__96.png" % direction
		if FileAccess.file_exists(body_path):
			_assert_playable(body_frames, StringName("unarmed_dodge_fast_attack_%s" % suffix), "roll-exit body should be registered")
		if FileAccess.file_exists(fx_path):
			_assert_playable(fx_frames, StringName("unarmed_dodge_fast_attack_fx_%s" % suffix), "roll-exit FX should be registered")
	var cape_path := "res://content/sprites/operator/runtime/modules/new_operator/wardrobe_cape/actions/unarmed/dodge_fast_attack_01/operator__modular_wardrobe_cape__unarmed__dodge_fast_attack_01__w__11f__96.png"
	if FileAccess.file_exists(cape_path):
		_assert_playable(cape_frames, &"unarmed_dodge_fast_attack_cape_left", "west roll-exit cape should be registered")


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

	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)
	operator.set("_melee_recovery_active", false)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.set("_dodge_recovery_active", true)
	operator.set("_dodge_recovery_timer", 0.12)
	operator.set("_dodge_cooldown_remaining", 0.9)
	operator.call("_try_melee_attack", "unarmed_fast")
	_assert_true(not bool(operator.get("_dodge_recovery_active")), "fast attack during dodge recovery should cancel the recovery phase")
	_assert_true(not bool(operator.get("_melee_fast_windup")), "fast attack from dodge recovery should skip unarmed windup")
	_assert_true(bool(operator.get("_melee_active")), "fast attack from dodge recovery should enter the strike immediately")
	_assert_true(float(operator.get("_dodge_cooldown_remaining")) > 0.0, "roll-exit attack cancel must preserve dodge cooldown")
	_assert_true(bool(operator.call("_sync_modular_action_domains")), "roll-exit strike should claim the modular action presentation on the next visual sync")
	if bool(operator.get("_dodge_fast_attack_presentation_active")):
		_assert_true(legacy_sprite.visible and String(legacy_sprite.animation).begins_with("unarmed_dodge_fast_attack_"), "ingested roll-exit body should own the full-body presentation")
	else:
		var roll_exit_suffix := str(operator.call("_get_direction_suffix", operator.get("_melee_forward")))
		_assert_layer_animation_suffix(operator, "modular_lower_body_sprite", "unarmed_fast_strike_lower", roll_exit_suffix)
		_assert_layer_animation_suffix(operator, "modular_upper_body_sprite", "unarmed_fast_strike_upper", roll_exit_suffix)

	operator.set("_melee_active", false)
	operator.set("_melee_recovery_active", false)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.set("_dodge_active", true)
	operator.set("_dodge_timer", 0.08)
	operator.set("_dodge_cooldown_remaining", 0.9)
	operator.call("_try_melee_attack", "unarmed_fast")
	_assert_true(bool(operator.get("_dodge_fast_attack_buffered")), "fast attack pressed during active roll should buffer until roll exit")
	_assert_true(not bool(operator.get("_melee_active")), "buffered roll-exit attack should not begin during active dodge/iframes")
	operator.set("_dodge_active", false)
	operator.call("_start_dodge_recovery")
	_assert_true(not bool(operator.get("_dodge_fast_attack_buffered")), "roll recovery entry should consume the buffered fast attack")
	_assert_true(bool(operator.get("_melee_active")), "buffered fast attack should begin as the roll exits")


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


func _assert_layer_animation_suffix(operator: Node, sprite_property: String, base: String, suffix: String) -> void:
	var sprite := operator.get(sprite_property) as AnimatedSprite2D
	_assert_true(sprite != null, "%s should exist" % sprite_property)
	if sprite == null:
		return
	var expected := StringName("%s_%s" % [base, suffix])
	_assert_true(sprite.visible, "%s should be visible for %s" % [sprite_property, suffix])
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
