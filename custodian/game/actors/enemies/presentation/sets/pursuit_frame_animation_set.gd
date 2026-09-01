extends EnemyAnimationSet

const ROOT := "res://content/sprites/enemies/pursuit_frame/runtime/body"


func _init() -> void:
	set_id = &"pursuit_frame"
	default_frame_size = Vector2i(96, 96)
	_add(&"locomotion.relaxed_idle", &"idle_ready_01", &"posture", [&"n", &"e", &"s", &"w"], 4, 6.0, true, &"relaxed_idle")
	_add(&"locomotion.ready_idle", &"idle_ready_01", &"posture", [&"n", &"e", &"s", &"w"], 4, 6.0, true, &"idle")
	_add(&"locomotion.relaxed_walk", &"patrol_walk_01", &"locomotion", [&"s"], 8, 8.0, true, &"relaxed_walk")
	_add(&"locomotion.relaxed_run", &"pursuit_run_01", &"locomotion", [&"s"], 8, 10.0, true, &"relaxed_run")
	_add(&"locomotion.walk", &"patrol_walk_01", &"locomotion", [&"s"], 8, 8.0, true, &"walk")
	_add(&"locomotion.run", &"pursuit_run_01", &"locomotion", [&"s"], 8, 10.0, true, &"run")
	_add(&"combat.fast_01", &"melee_brace_01", &"combat", [&"e", &"w"], 6, 12.0, false, &"melee")
	_add(&"combat.fast_02", &"intercept_burst_01", &"combat", [&"e", &"w"], 4, 12.0, false, &"intercept")
	_add(&"combat.fast_03", &"melee_brace_01", &"combat", [&"e", &"w"], 6, 12.0, false, &"melee_heavy")
	_add(&"reaction.flinch_01", &"flinch_01", &"reaction", [&"s"], 4, 12.0, false, &"flinch")
	_add(&"reaction.flinch_02", &"flinch_01", &"reaction", [&"s"], 4, 12.0, false, &"flinch_heavy")
	_add(&"reaction.stagger", &"stagger_01", &"reaction", [&"s"], 6, 10.0, false, &"stagger")
	_add(&"reaction.death", &"death_shutdown_01", &"death", [&"s"], 8, 10.0, false, &"death")


func _add(
	action: StringName,
	variant: StringName,
	group: StringName,
	directions: Array[StringName],
	frame_count: int,
	fps: float,
	loop: bool,
	compatibility_prefix: StringName
) -> void:
	for direction in directions:
		clips.append({
			"action": action,
			"variant": variant,
			"direction": direction,
			"body_path": "%s/%s/pursuit_frame__body__%s__%s__%s__%df__96.png" % [
				ROOT, group, group, variant, direction, frame_count,
			],
			"body_name": StringName("%s_%s" % [compatibility_prefix, direction]),
			"frame_count": frame_count,
			"fps": fps,
			"loop": loop,
		})
