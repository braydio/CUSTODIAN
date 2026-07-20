extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CARBINE_DEFINITION := preload("res://game/actors/operator/carbine_rifle_mk1_definition.tres")
const SIDEARM_DEFINITION := preload("res://game/actors/operator/sidearm_pistol_definition.tres")

class ParryProbeAttacker:
	extends Node2D

	var parry_staggered := false
	var parry_duration := 0.0
	var parry_knockback := 0.0

	func apply_parry_stagger(_direction: Vector2, duration: float, knockback_force: float) -> void:
		parry_staggered = true
		parry_duration = duration
		parry_knockback = knockback_force


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorRangedReadyInputSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	_validate_input_bindings()
	_validate_offhand_physical_event_mapping()
	_validate_carbine_intents()
	_validate_sidearm_profile()
	await _validate_offhand_input_actions_trigger_parry(root)
	await _validate_operator_ranged_ready(root)

	if _failed:
		push_error("operator_ranged_ready_input_smoke failed")
		quit(1)
		return
	print("operator_ranged_ready_input_smoke passed")
	quit()


func _validate_input_bindings() -> void:
	_assert_true(_action_has_mouse_button("attack_primary", MOUSE_BUTTON_LEFT), "attack_primary should include left mouse")
	_assert_true(_action_has_mouse_button("attack_secondary", MOUSE_BUTTON_RIGHT), "attack_secondary should include right mouse")
	_assert_true(_action_has_joy_axis("attack_primary", JOY_AXIS_TRIGGER_RIGHT, 1.0), "attack_primary should include right trigger")
	_assert_true(_action_has_joy_axis("attack_secondary", JOY_AXIS_TRIGGER_LEFT, 1.0), "attack_secondary should include left trigger")
	_assert_true(_action_has_mouse_button("fire_primary", MOUSE_BUTTON_LEFT), "fire_primary should include left mouse")
	_assert_true(_action_has_mouse_button("aim_hold", MOUSE_BUTTON_RIGHT), "aim_hold should include right mouse")
	_assert_true(_action_has_joy_axis("fire_primary", JOY_AXIS_TRIGGER_RIGHT, 1.0), "fire_primary should include right trigger")
	_assert_true(_action_has_joy_axis("aim_hold", JOY_AXIS_TRIGGER_LEFT, 1.0), "aim_hold should include left trigger")
	_assert_true(not _action_has_mouse_button("block", MOUSE_BUTTON_RIGHT), "block should not include right mouse")
	_assert_true(not _action_has_key("block", KEY_R), "block should not consume R after reload remap")
	_assert_true(_action_has_key("move_left", KEY_A), "move_left should include A")
	_assert_true(_action_has_key("move_right", KEY_D), "move_right should include D")
	_assert_true(_action_has_key("move_up", KEY_W), "move_up should include W")
	_assert_true(_action_has_key("move_down", KEY_S), "move_down should include S")
	_assert_true(_action_has_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0), "move_left should include left stick left")
	_assert_true(_action_has_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0), "move_right should include left stick right")
	_assert_true(_action_has_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0), "move_up should include left stick up")
	_assert_true(_action_has_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0), "move_down should include left stick down")
	_assert_true(_action_has_joy_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0), "aim_left should include right stick left")
	_assert_true(_action_has_joy_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0), "aim_right should include right stick right")
	_assert_true(_action_has_joy_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0), "aim_up should include right stick up")
	_assert_true(_action_has_joy_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0), "aim_down should include right stick down")
	_assert_true(_action_has_key("dodge", KEY_SPACE), "dodge should include Space")
	_assert_true(_action_has_joy_button("dodge", JOY_BUTTON_B), "dodge should include Xbox B")
	_assert_true(_action_has_key("interact", KEY_E), "interact should include E")
	_assert_true(_action_has_joy_button("interact", JOY_BUTTON_A), "interact should include Xbox A")
	_assert_true(_action_has_key("toggle_inventory", KEY_TAB), "toggle_inventory should include Tab")
	_assert_true(_action_has_key("inventory", KEY_I), "inventory should include I")
	_assert_true(_action_has_joy_button("inventory", JOY_BUTTON_Y), "inventory should include Xbox Y")
	_assert_true(_action_has_key("reload_weapon", KEY_R), "reload_weapon should include R")
	_assert_true(_action_has_key("reload", KEY_R), "reload should include R")
	_assert_true(_action_has_joy_button("reload", JOY_BUTTON_X), "reload should include Xbox X")
	_assert_true(_action_has_key("quick_item", KEY_Q), "quick_item should include Q")
	_assert_true(_action_has_joy_button("quick_item", JOY_BUTTON_DPAD_UP), "quick_item should include D-pad up")
	_assert_true(_action_has_key("cycle_item_left", KEY_Z), "cycle_item_left should include Z")
	_assert_true(_action_has_key("cycle_item_right", KEY_C), "cycle_item_right should include C")
	_assert_true(_action_has_joy_button("cycle_item_left", JOY_BUTTON_DPAD_LEFT), "cycle_item_left should include D-pad left")
	_assert_true(_action_has_joy_button("cycle_item_right", JOY_BUTTON_DPAD_RIGHT), "cycle_item_right should include D-pad right")
	_assert_true(_action_has_key("sneak", KEY_CTRL), "sneak should move to Ctrl")
	_assert_true(not _action_has_key("sneak", KEY_C), "sneak should not consume C after cycle-item remap")
	_assert_true(not _action_has_key("camera_follow_toggle", KEY_C), "camera debug toggle should not consume C")
	_assert_true(not _action_has_key("camera_auto_zoom_toggle", KEY_Z), "camera debug toggle should not consume Z")
	_assert_true(_action_has_key("pause", KEY_ESCAPE), "pause should include Escape")
	_assert_true(_action_has_joy_button("pause", JOY_BUTTON_START), "pause should include Start/Menu")
	_assert_true(_action_has_key("map", KEY_M), "map should include M")
	_assert_true(_action_has_joy_button("map", JOY_BUTTON_BACK), "map should include View/Back")


func _validate_carbine_intents() -> void:
	_assert_true(CARBINE_DEFINITION.secondary_intent == "ranged_ready", "carbine secondary intent should ready/aim, not fire")
	_assert_true(CARBINE_DEFINITION.primary_intent.begins_with("ranged_"), "carbine primary intent should remain ranged")


func _validate_sidearm_profile() -> void:
	_assert_true(SIDEARM_DEFINITION.weapon_id == &"sidearm_pistol", "sidearm should use the dedicated inventory-slot weapon id")
	_assert_true(SIDEARM_DEFINITION.weapon_type == &"ranged_sidearm", "sidearm should not masquerade as a 2h ranged primary")
	_assert_true(SIDEARM_DEFINITION.weapon_data_path == "res://content/weapons/data/pistol_mk1.json", "sidearm should use the pistol default profile")
	_assert_true(SIDEARM_DEFINITION.animation_map.get("ranged_stance", "") == "ranged_2h_stance", "sidearm V1 should use current ranged placeholder stance")
	_assert_true(is_equal_approx(SIDEARM_DEFINITION.get_stat_float("damage", 0.0), 8.0), "sidearm should resolve to the tuned 8 damage")
	_assert_true(SIDEARM_DEFINITION.get_stat_int("magazine_size", 0) == 10, "sidearm should resolve to the tuned 10-round magazine")


func _validate_operator_ranged_ready(root: Node) -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("using_unarmed", true)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.call("_exit_ranged_ready")

	_assert_true(not bool(operator.get("sidearm_slot_equipped")), "sidearm slot should start locked")
	_assert_true(operator.call("_get_offhand_secondary_mode") == &"parry_guard", "melee/unarmed without sidearm should route secondary to parry/guard")
	_assert_true(operator.call("_get_ranged_ready_candidate_weapon_definition") == null, "locked sidearm should not be a ranged-ready fallback")
	_assert_true(not bool(operator.call("_can_enter_ranged_ready")), "locked sidearm should not enter ranged-ready from melee/unarmed fallback")
	operator.call("_enter_ranged_ready")
	_assert_true(not bool(operator.call("_is_ranged_ready_active")), "locked sidearm enter request should do nothing")
	_validate_offhand_parry_guard(operator, root)

	var grant_result: Dictionary = operator.call("grant_sidearm", SIDEARM_DEFINITION)
	_assert_true(bool(grant_result.get("granted", false)), "grant_sidearm should unlock/equip the sidearm slot")
	_assert_true(bool(operator.get("sidearm_slot_equipped")), "sidearm slot should be equipped after grant")
	_assert_true(operator.call("_get_offhand_secondary_mode") == &"sidearm_ready", "melee/unarmed with sidearm should route secondary to sidearm-ready")
	_assert_true(operator.call("_get_ranged_ready_candidate_weapon_definition") == SIDEARM_DEFINITION, "granted sidearm should be the melee/unarmed fallback")
	_assert_true(bool(operator.call("_can_enter_ranged_ready")), "operator should be able to enter ranged-ready after sidearm grant")

	operator.call("_enter_ranged_ready")
	_assert_true(bool(operator.call("_is_ranged_ready_active")), "entering ranged-ready should set the ready state")
	_assert_true(bool(operator.call("_is_ranged_context_active")), "ranged-ready should create an active ranged context")
	_assert_true(not bool(operator.call("_is_using_ranged_2h_primary")), "sidearm-ready should not report the carried 2h primary")
	_assert_true(bool(operator.call("_is_using_ranged_weapon_visual")), "ranged-ready should show a ranged visual layer")
	_assert_true((operator.call("_resolve_dodge_direction") as Vector2).is_equal_approx(Vector2.LEFT), "idle aiming dodge should hop back away from aim")
	_validate_sidearm_fire_buffer(operator)

	operator.call("_exit_ranged_ready")
	_assert_true(not bool(operator.call("_is_ranged_ready_active")), "exiting ranged-ready should clear the ready state")
	operator.set("visual_idle_direction", Vector2.DOWN)
	_assert_true((operator.call("_resolve_dodge_direction") as Vector2).is_equal_approx(Vector2.DOWN), "fully idle dodge should use current facing")
	_validate_dodge_fx_overlay(operator)
	_validate_sidearm_ranged_ready(operator)
	_validate_selected_primary_priority(operator)
	operator.queue_free()


func _validate_sidearm_fire_buffer(operator: Node) -> void:
	var observatory := root.get_node_or_null("DevObservatory")
	var requests_before := int(observatory.counters.get("player_ranged_fire_requests", 0)) if observatory != null else 0
	var deferred_before := int(observatory.counters.get("player_ranged_fire_deferred_sidearm_not_ready", 0)) if observatory != null else 0
	var readiness_failures_before := int(observatory.counters.get("player_ranged_fire_failure_sidearm_not_held", 0)) if observatory != null else 0
	operator.set("_sidearm_action_phase", &"drawing")
	operator.set("_sidearm_fire_buffered", false)
	operator.set("fire_cooldown_remaining", 0.0)
	operator.set("_pending_ranged_shot", {})
	Input.action_release("attack_primary")
	Input.action_press("attack_primary")
	operator.call("_handle_sidearm_fire_input")
	operator.call("_handle_sidearm_fire_input")
	_assert_true(bool(operator.get("_sidearm_fire_buffered")), "one early sidearm press should be buffered during draw")
	if observatory != null:
		_assert_true(int(observatory.counters.get("player_ranged_fire_requests", 0)) == requests_before, "buffered sidearm input must not become an early fire request")
		_assert_true(int(observatory.counters.get("player_ranged_fire_deferred_sidearm_not_ready", 0)) == deferred_before + 1, "repeated sampling of one early sidearm press should defer exactly once")
	operator.set("_sidearm_action_phase", &"held")
	operator.call("_try_consume_sidearm_fire_buffer")
	_assert_true(not bool(operator.get("_sidearm_fire_buffered")), "held sidearm should consume the buffered press")
	if observatory != null:
		_assert_true(int(observatory.counters.get("player_ranged_fire_requests", 0)) == requests_before + 1, "one deferred sidearm press should become exactly one request")
		_assert_true(int(observatory.counters.get("player_ranged_fire_failure_sidearm_not_held", 0)) == readiness_failures_before, "buffered sidearm input must not emit sidearm_not_held failures")
	Input.action_release("attack_primary")


func _validate_sidearm_ranged_ready(operator: Node) -> void:
	operator.call("_exit_ranged_ready")
	operator.set("primary_weapon_definition", CARBINE_DEFINITION)
	operator.set("primary_weapon_equipped", true)
	operator.set("sidearm_weapon_definition", SIDEARM_DEFINITION)
	operator.set("sidearm_slot_equipped", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("equipped_primary_weapon_id", "fists")
	operator.set("using_unarmed", true)
	operator.set("aim_direction", Vector2.RIGHT)
	_assert_true(bool(operator.call("_can_enter_ranged_ready")), "operator should be able to ready sidearm while a carried carbine is not selected")
	operator.call("_enter_ranged_ready")
	_assert_true(bool(operator.call("_is_ranged_ready_active")), "sidearm should enter ranged-ready")
	_assert_true(operator.call("_get_active_ranged_weapon_definition") == SIDEARM_DEFINITION, "active ranged weapon should be the sidearm slot")
	_assert_true(not bool(operator.call("_is_using_ranged_2h_primary")), "sidearm should not report as the 2h primary")
	_assert_true(bool(operator.call("_is_using_ranged_weapon_visual")), "sidearm should still use the ranged visual presentation")
	var profile: Dictionary = operator.call("_get_current_ranged_profile")
	_assert_true(is_equal_approx(float(profile.get("damage", 0.0)), 8.0), "sidearm should read tuned pistol damage profile")
	_assert_true(operator.call("_get_current_magazine_size") == 10, "sidearm should read tuned pistol magazine size")
	operator.call("_exit_ranged_ready")


func _validate_selected_primary_priority(operator: Node) -> void:
	operator.call("_exit_ranged_ready")
	operator.set("primary_weapon_definition", CARBINE_DEFINITION)
	operator.set("primary_weapon_equipped", true)
	operator.set("sidearm_weapon_definition", SIDEARM_DEFINITION)
	operator.set("sidearm_slot_equipped", true)
	operator.set("combat_loadout_mode", "ranged")
	operator.set("equipped_primary_weapon_id", "carbine_rifle")
	operator.set("using_unarmed", false)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("fire_cooldown_remaining", 0.0)
	operator.set("_pending_ranged_shot", {})
	operator.set("_reload_active", false)
	for sprite_name in ["modular_lower_body_sprite", "modular_upper_body_sprite", "modular_sidearm_sprite"]:
		var sprite := operator.get(sprite_name) as AnimatedSprite2D
		if sprite != null:
			_add_placeholder_animation(sprite.sprite_frames, &"ranged_2h_aim_modular_right")
	_assert_true(operator.call("_get_offhand_secondary_mode") == &"primary_ranged_ready", "selected ranged primary should route secondary to primary ranged-ready")
	_assert_true(operator.call("_get_ranged_ready_candidate_weapon_definition") == CARBINE_DEFINITION, "actively selected ranged primary should take priority over sidearm")
	operator.call("_enter_ranged_ready")
	_assert_true(operator.call("_get_active_ranged_weapon_definition") == CARBINE_DEFINITION, "active ranged weapon should remain the selected primary")
	_assert_true(bool(operator.call("_is_using_ranged_2h_primary")), "selected carbine should still report as ranged_2h primary")
	var raising_status: Dictionary = operator.call("get_weapon_status")
	_assert_true(raising_status.get("ranged_posture") == "raising", "carbine aim entry should expose raising posture")
	_assert_true(not bool(raising_status.get("ranged_ready", true)), "raising should not expose ranged_ready")
	_assert_true(not bool(raising_status.get("can_fire_now", true)), "aim raise should expose fire gating")
	_assert_true(raising_status.has("committed_aim_direction"), "weapon status should expose committed aim direction")
	operator.call("_tick_primary_ranged_action_presentation", 10.0)
	var ready_status: Dictionary = operator.call("get_weapon_status")
	_assert_true(ready_status.get("ranged_posture") == "ready", "completed aim entry should expose ready posture")
	_assert_true(bool(ready_status.get("ranged_ready", false)), "ready posture should expose ranged_ready")
	_assert_true(float(ready_status.get("ranged_transition_ratio", -1.0)) == 0.0, "settled ready posture should clear transition ratio")
	operator.call("_exit_ranged_ready")
	var lowering_status: Dictionary = operator.call("get_weapon_status")
	_assert_true(lowering_status.get("ranged_posture") == "lowering", "carbine release should expose lowering posture")


func _validate_offhand_input_actions_trigger_parry(root: Node) -> void:
	await _validate_offhand_input_trigger(root, "aim_hold action", func() -> void:
		Input.action_press("aim_hold")
	, func() -> void:
		Input.action_release("aim_hold")
	)
	await _validate_offhand_input_trigger(root, "attack_secondary action", func() -> void:
		Input.action_press("attack_secondary")
	, func() -> void:
		Input.action_release("attack_secondary")
	)


func _validate_offhand_physical_event_mapping() -> void:
	var right_mouse := InputEventMouseButton.new()
	right_mouse.button_index = MOUSE_BUTTON_RIGHT
	right_mouse.pressed = true
	_assert_true(InputMap.event_is_action(right_mouse, "aim_hold"), "right mouse should map to aim_hold")
	_assert_true(InputMap.event_is_action(right_mouse, "attack_secondary"), "right mouse should map to attack_secondary")

	var left_trigger := InputEventJoypadMotion.new()
	left_trigger.axis = JOY_AXIS_TRIGGER_LEFT
	left_trigger.axis_value = 1.0
	_assert_true(InputMap.event_is_action(left_trigger, "aim_hold"), "left trigger should map to aim_hold")
	_assert_true(InputMap.event_is_action(left_trigger, "attack_secondary"), "left trigger should map to attack_secondary")


func _validate_offhand_input_trigger(root: Node, label: String, press: Callable, release: Callable) -> void:
	_release_offhand_inputs()
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("using_unarmed", true)
	operator.set("sidearm_slot_equipped", false)
	operator.set("stamina", 40.0)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.call("_exit_ranged_ready")

	press.call()
	operator.call("_process", 0.016)
	_assert_true(operator.get("_parry_phase") == &"", "%s should not tap-parry from secondary alone" % label)
	_assert_true(operator.get("_block_phase") in [&"enter", &"hold"], "%s should enter guard through _process input routing" % label)
	_assert_true(not bool(operator.call("_is_ranged_ready_active")), "%s should not enter ranged-ready when offhand mode is parry_guard" % label)
	operator.call("_process", float(operator.get("parry_min_guard_time_sec")) + 0.016)
	Input.action_press("fire_primary")
	operator.call("_process", 0.016)
	_assert_true(operator.get("_parry_phase") == &"windup", "%s + primary should start parry windup through _process input routing" % label)
	_assert_true(operator.get("_block_phase") == &"parry", "%s + primary should host parry in the block state" % label)
	Input.action_release("fire_primary")
	Input.action_release("attack_primary")

	release.call()
	_release_offhand_inputs()
	operator.queue_free()
	await process_frame


func _release_offhand_inputs() -> void:
	Input.action_release("fire_primary")
	Input.action_release("attack_primary")
	Input.action_release("aim_hold")
	Input.action_release("attack_secondary")
	var mouse_release := InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_RIGHT
	mouse_release.pressed = false
	Input.parse_input_event(mouse_release)
	var trigger_release := InputEventJoypadMotion.new()
	trigger_release.axis = JOY_AXIS_TRIGGER_LEFT
	trigger_release.axis_value = 0.0
	Input.parse_input_event(trigger_release)


func _validate_offhand_parry_guard(operator: Node, root: Node) -> void:
	var observatory := operator.get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("clear"):
		observatory.call("clear")
	operator.set("stamina", 40.0)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("aim_direction", Vector2.RIGHT)
	Input.action_press("attack_secondary")
	operator.call("_start_guard_from_secondary")
	operator.set("_guard_held_timer", float(operator.get("parry_min_guard_time_sec")))
	_assert_true(operator.get("_block_phase") in [&"enter", &"hold"], "secondary hold should enter guard before parry")
	_assert_true(bool(operator.call("_can_parry_from_guard")), "melee/unarmed parry should be available from guard without a sidearm")
	_assert_true(bool(operator.call("_can_start_parry")), "melee/unarmed parry should be available without a sidearm")
	_assert_true(bool(operator.call("_try_start_parry")), "primary while guarding should start parry windup")
	_assert_true(operator.get("_parry_phase") == &"windup", "parry should begin in windup")
	_assert_true(operator.get("_block_phase") == &"parry", "block state should host parry without converting it to guard entry")
	operator.call("_update_parry_guard_timers", 0.05)
	_assert_true(operator.get("_parry_phase") == &"active", "parry should become active after windup")
	_assert_true(bool(operator.get("_parry_active")), "parry active flag should be true during the active window")
	operator.call("_update_parry_guard_timers", float(operator.get("parry_active_sec")) + 0.01)
	_assert_true(operator.get("_parry_phase") == &"recovery", "missed active parry should enter recovery")
	_assert_true(not bool(operator.get("_parry_active")), "missed active parry should clear active parry flag")
	_assert_true(operator.get("_block_phase") == &"recovery", "missed active parry should keep block recovery presentation")
	_assert_true(operator.get_tree().get_nodes_in_group("parry_success_world_vfx").is_empty(), "missed active parry should not spawn success burst")
	_assert_true(operator.get_tree().get_nodes_in_group("parry_success_audio").is_empty(), "missed active parry should not play the success sound")
	_assert_true(not operator.get_tree().get_nodes_in_group("parry_miss_world_vfx").is_empty(), "missed active parry should spawn miss feedback")
	if observatory != null:
		var miss_counters: Dictionary = observatory.get("counters")
		_assert_true(int(miss_counters.get("player_parry_started", 0)) == 1, "parry start telemetry should count the attempt")
		_assert_true(int(miss_counters.get("player_parry_active", 0)) == 1, "parry active telemetry should count the timing window")
		_assert_true(int(miss_counters.get("player_parry_expired", 0)) == 1, "parry expiry telemetry should count the miss")
		_assert_true(int(miss_counters.get("player_parry_miss_vfx_spawned", 0)) == 1, "parry miss telemetry should count spawned feedback")

	operator.call("_update_parry_guard_timers", float(operator.get("parry_recovery_sec")) + 0.01)
	operator.set("_guard_held_timer", float(operator.get("parry_min_guard_time_sec")))
	_assert_true(bool(operator.call("_try_start_parry")), "fresh guard press should allow parry after a missed recovery")
	operator.call("_update_parry_guard_timers", 0.05)
	_assert_true(operator.get("_parry_phase") == &"active", "fresh parry should become active after missed recovery setup")

	var attacker := ParryProbeAttacker.new()
	root.add_child(attacker)
	attacker.global_position = operator.global_position + Vector2.RIGHT * 32.0
	var parried: bool = bool(operator.call("try_parry_incoming_attack", attacker, Vector2.LEFT, {"damage": 12.0}))
	_assert_true(parried, "front-facing active parry should catch incoming melee")
	_assert_true(bool(attacker.parry_staggered), "parry should stagger the attacker")
	_assert_true(is_equal_approx(attacker.parry_duration, float(operator.get("parry_enemy_stagger_sec"))), "parry should use exported stagger duration")
	_assert_true(is_equal_approx(attacker.parry_knockback, float(operator.get("parry_enemy_knockback"))), "parry should use exported knockback")
	_assert_true(operator.get("_parry_phase") == &"success", "successful parry should enter success recovery")
	var parry_success_audio := operator.get_tree().get_nodes_in_group("parry_success_audio")
	_assert_true(parry_success_audio.size() == 1, "successful parry should create exactly one positional success sound")
	if parry_success_audio.size() == 1:
		var parry_success_player := parry_success_audio[0] as AudioStreamPlayer2D
		_assert_true(parry_success_player != null and parry_success_player.playing, "successful parry sound should begin playback immediately")
		_assert_true(
			parry_success_player != null \
			and parry_success_player.stream != null \
			and parry_success_player.stream.resource_path == "res://content/audio/sfx/combat/parry_success_01.wav",
			"successful parry should use parry_success_01.wav",
		)
	if observatory != null:
		_assert_true(int(observatory.get("counters").get("player_parry_success", 0)) == 1, "successful parry telemetry should count once")
		_assert_true(int(observatory.get("counters").get("player_parry_success_sfx_played", 0)) == 1, "successful parry sound telemetry should count once")
	_assert_true(float(operator.get("_counter_window_timer")) > 0.0, "successful parry should open a counter window")
	_assert_true(float(operator.get("parry_success_recovery_sec")) <= 0.035, "successful parry should put guard down quickly enough to counter during enemy stagger")
	Input.action_press("fire_primary")
	operator.call("_handle_attack_input")
	Input.action_release("fire_primary")
	_assert_true(operator.get("_buffered_attack_kind") == "fast", "primary during parry success should buffer a fast counter")
	operator.call("_update_parry_guard_timers", 0.02)
	_assert_true(operator.get("_parry_phase") == &"", "queued parry counter should force success state to release on the next frame")
	_assert_true(operator.get("_block_phase") == &"", "queued parry counter should put down guard before the strike starts")
	_assert_true(bool(operator.get("_melee_active")) or bool(operator.get("_melee_fast_windup")), "queued parry counter should start the strike after guard release")
	attacker.queue_free()

	operator.set("_melee_active", false)
	operator.set("_melee_fast_windup", false)
	operator.set("_melee_recovery_active", false)
	operator.call("_clear_attack_buffer")
	operator.call("_start_guard_from_secondary")
	operator.set("_guard_held_timer", float(operator.get("parry_min_guard_time_sec")))
	_assert_true(bool(operator.call("_try_start_parry")), "fresh guard press should allow a second parry")
	operator.call("_update_parry_guard_timers", 0.05)
	var held_block_attacker := ParryProbeAttacker.new()
	root.add_child(held_block_attacker)
	held_block_attacker.global_position = operator.global_position + Vector2.RIGHT * 32.0
	var held_block_parried: bool = bool(operator.call("try_parry_incoming_attack", held_block_attacker, Vector2.LEFT, {"damage": 12.0}))
	_assert_true(held_block_parried, "second parry should catch incoming melee while block is still held")
	operator.call("_handle_offhand_secondary_input", 0.04)
	_assert_true(operator.get("_parry_phase") == &"", "successful parry should finish its success state")
	_assert_true(operator.get("_block_phase") == &"", "held block after successful parry should exit to neutral")
	_assert_true(not bool(operator.get("_block_active")), "held block after successful parry should not remain active")
	operator.call("_handle_offhand_secondary_input", 0.02)
	_assert_true(operator.get("_block_phase") == &"", "continued held block should not re-enter guard after successful parry")
	Input.action_release("attack_secondary")
	operator.call("_handle_offhand_secondary_input", 0.02)
	_assert_true(not bool(operator.get("_guard_repress_required_after_parry_success")), "releasing block after successful parry should clear the required-repress latch")
	operator.call("_start_guard_from_secondary")
	_assert_true(operator.get("_block_phase") in [&"enter", &"hold"], "new block request after release should re-enter guard")
	held_block_attacker.queue_free()

	operator.set("_parry_active", false)
	operator.set("_parry_phase", &"")
	operator.set("_block_active", true)
	operator.set("_block_phase", &"hold")
	operator.set("stamina", 40.0)
	var guard_result: Dictionary = operator.call("try_guard_incoming_attack", 20.0, Vector2.LEFT)
	_assert_true(bool(guard_result.get("blocked", false)), "held guard should block front-facing incoming attacks")
	_assert_true(float(guard_result.get("damage", 20.0)) < 20.0, "guard should reduce but not erase incoming damage")
	_assert_true(float(operator.get("stamina")) < 40.0, "guard should drain stamina on hit")

	operator.set("_block_active", true)
	operator.set("_block_phase", &"hold")
	operator.set("stamina", 40.0)
	operator.set("health", 100.0)
	operator.set("current_health", 100.0)
	var blocked_hit: Dictionary = operator.call("receive_enemy_hit", 20.0, &"melee", "enemy", null, Vector2.LEFT)
	var lower_sprite := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var upper_sprite := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	_assert_true(bool(blocked_hit.get("blocked", false)), "receive_enemy_hit should preserve held guard for front-facing attacks")
	_assert_true(operator.get("_block_phase") == &"hitreact", "blocked chip damage should keep block hitreact instead of normal hit recoil")
	_assert_true(float(operator.get("health")) < 100.0, "blocked chip damage should still reduce health")
	_assert_true(lower_sprite != null and lower_sprite.visible and lower_sprite.animation == &"unarmed_block_hitreact_right", "blocked hit should play lower block hitreact in the guard direction")
	_assert_true(upper_sprite != null and upper_sprite.visible and upper_sprite.animation == &"unarmed_block_hitreact_right", "blocked hit should play upper block hitreact in the guard direction")

	operator.set("_block_active", false)
	operator.set("_block_phase", &"parry")
	operator.set("_parry_active", false)
	operator.set("_parry_phase", &"windup")
	operator.set("_parry_timer", 0.05)
	operator.set("health", 100.0)
	operator.set("current_health", 100.0)
	var failed_parry_hit: Dictionary = operator.call("receive_enemy_hit", 20.0, &"melee", "enemy", null, Vector2.LEFT)
	_assert_true(bool(failed_parry_hit.get("block_hitreact", false)), "failed parry timing should report block-hitreact presentation")
	_assert_true(not bool(failed_parry_hit.get("blocked", false)), "failed parry timing should not report a successful block")
	_assert_true(operator.get("_parry_phase") == &"", "failed parry hit should cancel the committed parry attempt")
	_assert_true(operator.get("_block_phase") == &"hitreact", "failed parry hit should play block hitreact instead of normal hit recoil")
	_assert_true(float(operator.get("health")) < 100.0, "failed parry hit should still apply enemy damage")
	_assert_true(lower_sprite != null and lower_sprite.visible and lower_sprite.animation == &"unarmed_block_hitreact_right", "failed parry hit should play lower block hitreact in the guard direction")
	_assert_true(upper_sprite != null and upper_sprite.visible and upper_sprite.animation == &"unarmed_block_hitreact_right", "failed parry hit should play upper block hitreact in the guard direction")
	operator.set("_block_active", false)
	operator.set("_block_phase", &"")


func _validate_dodge_fx_overlay(operator: Node) -> void:
	var body_sprite := operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var dodge_fx := operator.get_node_or_null("DodgeFXBackSprite") as AnimatedSprite2D
	_assert_true(body_sprite != null, "operator should expose the body sprite")
	_assert_true(dodge_fx != null, "operator should expose a dedicated dodge back FX sprite")
	if body_sprite == null or dodge_fx == null:
		return
	_assert_true(dodge_fx.z_index < body_sprite.z_index, "dodge FX should render behind/under the Custodian body")
	_assert_true(dodge_fx.sprite_frames != null and dodge_fx.sprite_frames.has_animation(&"operator_dodge_full_fx_south"), "dodge FX sprite should own the authored 9-frame south dodge FX animation")
	_assert_true(body_sprite.sprite_frames.has_animation(&"operator_dodge_full_north"), "body should own the authored 9-frame north dodge animation")
	_assert_true(body_sprite.sprite_frames.has_animation(&"operator_dodge_full_south"), "body should own the authored 9-frame south dodge animation")
	_assert_true(body_sprite.sprite_frames.get_frame_count(&"operator_dodge_full_north") == 9, "north dodge should use all 9 authored frames")
	_assert_true(body_sprite.sprite_frames.get_frame_count(&"operator_dodge_full_south") == 9, "south dodge should use all 9 authored frames")
	operator.set("stamina", 100.0)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("aim_direction", Vector2.RIGHT)
	_add_placeholder_animation(body_sprite.sprite_frames, &"operator_dodge_recovery")
	_assert_true(bool(operator.call("_try_start_dodge")), "operator should start a deterministic dodge")
	_assert_true(String(body_sprite.animation) == "operator_dodge_full_south", "east/horizontal dodge should start the authored south body track")
	_assert_true(String(dodge_fx.animation) == "operator_dodge_full_fx_south", "east/horizontal dodge should start the synchronized authored south FX track")
	_assert_true(body_sprite.frame == 0, "body dodge should restart on frame 0")
	_assert_true(dodge_fx.frame == 0, "dodge FX should restart on frame 0")
	_assert_true(dodge_fx.visible, "dodge FX should be visible during dodge")
	_assert_true(dodge_fx.position.x < body_sprite.position.x, "east dodge FX should be offset behind the Custodian")
	operator.call("_update_dodge", 1.0)
	_assert_true(bool(operator.get("_dodge_recovery_active")), "finishing dodge should enter recovery when a recovery animation exists")
	_assert_true(String(body_sprite.animation) == "operator_dodge_full_south", "authored full dodge should continue through recovery instead of restarting a split track")
	_assert_true(dodge_fx.visible, "authored dodge FX should continue through recovery")
	operator.call("_cancel_dodge")
	_assert_true(not dodge_fx.visible, "canceling dodge should hide the dodge FX")


func _add_placeholder_animation(sprite_frames: SpriteFrames, animation_name: StringName) -> void:
	if sprite_frames == null or sprite_frames.has_animation(animation_name):
		return
	var texture := PlaceholderTexture2D.new()
	texture.size = Vector2(96, 96)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, 18.0)
	sprite_frames.add_frame(animation_name, texture)


func _action_has_mouse_button(action_name: StringName, button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		var mouse_event := event as InputEventMouseButton
		if mouse_event != null and mouse_event.button_index == button:
			return true
	return false


func _action_has_key(action_name: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action_name):
		var key_event := event as InputEventKey
		if key_event != null and (key_event.physical_keycode == key or key_event.keycode == key or key_event.key_label == key):
			return true
	return false


func _action_has_joy_axis(action_name: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action_name):
		var axis_event := event as InputEventJoypadMotion
		if axis_event != null and axis_event.axis == axis and is_equal_approx(axis_event.axis_value, axis_value):
			return true
	return false


func _action_has_joy_button(action_name: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		var button_event := event as InputEventJoypadButton
		if button_event != null and button_event.button_index == button:
			return true
	return false


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
