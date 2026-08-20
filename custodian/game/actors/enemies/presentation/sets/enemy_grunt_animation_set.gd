extends EnemyAnimationSet

const ROOT := "res://content/sprites/enemies/enemy_grunt/runtime"


func _init() -> void:
	set_id = &"enemy_grunt"
	default_frame_size = Vector2i(96, 96)
	_add_legacy_body(
		&"locomotion.ready_idle", &"idle_01", &"s", 10, 6.0, true,
		"%s/body/enemy_grunt__body__locomotion__idle_01__s__10f__96.png",
		&"idle_s"
	)
	_add_generated_pair(&"locomotion.relaxed_idle", &"unarmed_idle_01", &"locomotion", 5, 6.0, true)
	_add_generated_pair(&"locomotion.ready_idle", &"idle_01", &"locomotion", 5, 6.0, true)
	_add_generated_pair(&"locomotion.walk", &"walk_01", &"locomotion", 5, 8.0, true)
	_add_generated_pair(&"locomotion.run", &"run_01", &"locomotion", 6, 10.0, true)
	_add_generated_pair(&"posture.alert", &"alert_01", &"melee", 5, 10.0, false)
	_add_generated_pair(&"posture.draw", &"draw_01", &"melee", 5, 10.0, false)
	_add_generated_pair(&"combat.fast_01", &"fast_01", &"melee", 9, 12.0, false, true)
	_add_generated_pair(&"combat.fast_02", &"fast_02", &"melee", 7, 12.0, false, true)
	_add_generated_pair(&"combat.fast_03", &"fast_03", &"melee", 8, 12.0, false, true)
	_add_generated_pair(&"reaction.flinch_01", &"flinch_01", &"melee", 5, 12.0, false)
	_add_generated_pair(&"reaction.flinch_02", &"flinch_02", &"melee", 5, 12.0, false)
	_add_legacy_body(
		&"reaction.flinch_01", &"flinch_01", &"s", 6, 12.0, false,
		"%s/body/enemy_grunt__body__melee__flinch_01__s__6f__96.png",
		&"flinch_s",
		"%s/fx/enemy_grunt__fx__melee__flinch_01__s__5f__96.png",
		&"flinch_fx_s"
	)
	_add_generated_pair(&"reaction.stagger", &"stagger_01", &"melee", 8, 10.0, false, true)
	_add_legacy_body(
		&"reaction.stagger", &"stagger_01", &"s", 8, 10.0, false,
		"%s/body/enemy_grunt__body__melee__stagger_01__s__8f__96.png",
		&"stagger_s"
	)
	_add_generated_pair(&"reaction.death", &"death_01", &"melee", 5, 10.0, false, true)
	_add_generated_pair(&"reaction.knockdown_01", &"knockdown_01", &"melee", 6, 10.0, false, true)
	_add_generated_pair(&"reaction.knockdown_02", &"knockdown_02", &"melee", 6, 10.0, false, true)
	_add_generated_pair(&"reaction.stand_up", &"stand_up_01", &"melee", 5, 10.0, false)
	_add_generated_pair(&"flavor.bark", &"bark_01", &"melee", 8, 8.0, false)
	_add_generated_pair(&"flavor.taunt_bark", &"taunt_bark_01", &"melee", 8, 8.0, false)
	_add_generated_pair(&"flavor.taunt_brandish", &"taunt_brandish_01", &"melee", 8, 8.0, false)
	_add_generated_pair(&"flavor.taunt_point", &"taunt_point_01", &"melee", 8, 8.0, false)

	_add_existing_pair(&"combat.fast_01", &"fast_01", &"se", 10, 12.0, false, true)
	_add_existing_pair(&"combat.fast_01", &"fast_01", &"sw", 10, 12.0, false, true)
	_add_existing(&"combat.falcon.windup", &"special_windup_01", &"e", 6, 8.0)
	_add_existing(&"combat.falcon.windup", &"special_windup_01", &"w", 6, 8.0)
	_add_existing(&"combat.falcon.inflight", &"special_inflight_01", &"e", 6, 21.428571)
	_add_existing(&"combat.falcon.inflight", &"special_inflight_01", &"w", 6, 21.428571)
	_add_existing(&"combat.falcon.recovery", &"special_recovery_01", &"e", 6, 8.571429)
	_add_existing(&"combat.falcon.recovery", &"special_recovery_01", &"w", 6, 8.571429)
	_add_existing(&"reaction.critical", &"crit_01", &"s", 8, 10.0)
	_add_existing(&"reaction.critical_recovery", &"crit_recovery_01", &"s", 5, 8.0)
	_add_existing(&"reaction.critical_open_enter", &"parry_critical_open_enter_01", &"s", 5, 12.0)
	_add_existing(&"reaction.critical_open_hold", &"parry_critical_open_hold_01", &"s", 4, 6.0, true)
	_add_existing(&"reaction.critical_open_recover", &"parry_critical_recover_01", &"s", 5, 10.0)
	_add_existing(&"reaction.execution_victim", &"critical_execution_victim_01", &"s", 8, 12.0)
	_add_existing(&"reaction.execution_victim", &"critical_execution_victim_01", &"e", 12, 12.0)
	_add_existing(&"reaction.execution_victim", &"critical_execution_victim_01", &"w", 12, 12.0)
	_add_existing(&"reaction.falcon_reversal_victim", &"falcon_reversal_victim_01", &"e", 8, 12.0, false, Vector2i(156, 156), "body/melee")
	_add_existing(&"reaction.falcon_reversal_victim", &"falcon_reversal_victim_01", &"w", 8, 12.0, false, Vector2i(156, 156), "body/melee")
	_add_legacy_fx(
		&"reaction.critical", &"crit_01", &"s", 8, 12.0,
		"%s/fx/enemy_grunt__fx__melee__crit_01__s__8f__96.png",
		&"crit_fx_s"
	)


func _add_generated_pair(action: StringName, variant: StringName, group: StringName, frames: int, fps: float, loop: bool, with_fx := false) -> void:
	for direction in [&"e", &"w"]:
		var clip := {
			"action": action, "variant": variant, "direction": direction,
			"body_path": "%s/body/%s/enemy_grunt__body__%s__%s__%s__%df__96.png" % [ROOT, group, group, variant, direction, frames],
			"body_name": _compatibility_name(action, direction, &"body"),
			"fps": fps, "loop": loop,
		}
		if with_fx:
			clip["fx_path"] = "%s/fx/%s/enemy_grunt__fx__%s__%s__%s__%df__96.png" % [ROOT, group, group, variant, direction, frames]
			clip["fx_name"] = _compatibility_name(action, direction, &"fx")
		clips.append(clip)


func _add_existing(action: StringName, variant: StringName, direction: StringName, frames: int, fps: float, loop := false, frame_size := Vector2i(96, 96), subdir := "body") -> void:
	var size_token := str(frame_size.x) if frame_size.x == frame_size.y else "%dx%d" % [frame_size.x, frame_size.y]
	clips.append({
		"action": action, "variant": variant, "direction": direction,
		"body_path": "%s/%s/enemy_grunt__body__melee__%s__%s__%df__%s.png" % [ROOT, subdir, variant, direction, frames, size_token],
		"body_name": _compatibility_name(action, direction, &"body"),
		"fps": fps, "loop": loop, "frame_size": frame_size,
	})


func _add_existing_pair(action: StringName, variant: StringName, direction: StringName, frames: int, fps: float, loop: bool, with_fx: bool) -> void:
	var clip := {
		"action": action, "variant": variant, "direction": direction,
		"body_path": "%s/body/enemy_grunt__body__melee__%s__%s__%df__96.png" % [ROOT, variant, direction, frames],
		"body_name": _compatibility_name(action, direction, &"body"),
		"fps": fps, "loop": loop,
	}
	if with_fx:
		clip["fx_path"] = "%s/fx/enemy_grunt__fx__melee__%s__%s__%df__96.png" % [ROOT, variant, direction, frames]
		clip["fx_name"] = _compatibility_name(action, direction, &"fx")
	clips.append(clip)


func _add_legacy_body(action: StringName, variant: StringName, direction: StringName, _frames: int, fps: float, loop: bool, path_template: String, animation_name: StringName, fx_path_template := "", fx_name: StringName = &"") -> void:
	var clip := {
		"action": action, "variant": variant, "direction": direction,
		"body_path": path_template % ROOT,
		"body_name": animation_name,
		"fps": fps, "loop": loop,
	}
	if not fx_path_template.is_empty():
		clip["fx_path"] = fx_path_template % ROOT
		clip["fx_name"] = fx_name
	clips.append(clip)


func _add_legacy_fx(action: StringName, variant: StringName, direction: StringName, _frames: int, fps: float, path_template: String, animation_name: StringName) -> void:
	clips.append({
		"action": action, "variant": variant, "direction": direction,
		"fx_path": path_template % ROOT,
		"fx_name": animation_name,
		"fps": fps, "loop": false,
	})


func _compatibility_name(action: StringName, direction: StringName, layer: StringName) -> StringName:
	var action_text := String(action)
	if layer == &"fx":
		if action_text.begins_with("combat.fast_"):
			return StringName("melee_fx_%s" % String(direction)) if action == &"combat.fast_01" else StringName("%s_fx_%s" % [action_text.get_slice(".", 1), direction])
		return StringName("%s_fx_%s" % [action_text.replace(".", "_"), direction])
	match action:
		&"locomotion.ready_idle": return StringName("idle_%s" % direction)
		&"locomotion.relaxed_idle": return StringName("unarmed_idle_%s" % direction)
		&"locomotion.walk": return StringName("walk_%s" % direction)
		&"locomotion.run": return StringName("run_%s" % direction)
		&"combat.fast_01": return StringName("melee_%s" % direction)
		&"reaction.stagger": return StringName("stagger_%s" % direction)
		&"reaction.death": return StringName("death_%s" % direction)
		&"reaction.flinch_01": return StringName("flinch_%s" % direction)
		&"reaction.critical": return StringName("crit_%s" % direction)
		&"reaction.critical_recovery": return StringName("crit_recovery_%s" % direction)
		&"reaction.critical_open_enter": return StringName("critical_open_enter_%s" % direction)
		&"reaction.critical_open_hold": return StringName("critical_open_hold_%s" % direction)
		&"reaction.critical_open_recover": return StringName("critical_open_recover_%s" % direction)
		&"reaction.execution_victim": return StringName("critical_execution_victim_%s" % direction)
		&"reaction.falcon_reversal_victim": return StringName("falcon_reversal_victim_%s" % direction)
		&"combat.falcon.windup": return StringName("special_windup_%s" % direction)
		&"combat.falcon.inflight": return StringName("special_inflight_%s" % direction)
		&"combat.falcon.recovery": return StringName("special_recovery_%s" % direction)
	return StringName("%s_%s" % [action_text.replace(".", "_"), direction])
