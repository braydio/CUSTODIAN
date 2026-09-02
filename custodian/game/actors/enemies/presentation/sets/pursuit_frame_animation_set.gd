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
	_add(&"posture.draw", &"notice_01", &"combat", [&"s"], 4, 10.0, false, &"draw")
	_add(&"posture.alert", &"notice_01", &"combat", [&"s"], 4, 10.0, false, &"alert")
	_add(&"combat.fast_01", &"melee_brace_01", &"combat", [&"e", &"w"], 6, 12.0, false, &"melee")
	_add(&"combat.fast_02", &"intercept_burst_01", &"combat", [&"e", &"w"], 4, 12.0, false, &"intercept")
	_add(&"combat.fast_03", &"melee_brace_01", &"combat", [&"e", &"w"], 6, 12.0, false, &"melee_heavy")
	_add(&"combat.intercept_windup", &"intercept_windup_01", &"combat", [&"e", &"w"], 4, 10.0, false, &"intercept_windup")
	_add(&"combat.intercept_burst", &"intercept_burst_01", &"combat", [&"e", &"w"], 4, 12.0, false, &"intercept_burst")
	_add(&"combat.intercept_recover", &"intercept_recover_01", &"combat", [&"e", &"w"], 5, 10.0, false, &"intercept_recover")
	_add(&"reaction.flinch_01", &"flinch_01", &"reaction", [&"s"], 4, 12.0, false, &"flinch")
	_add(&"reaction.flinch_02", &"flinch_01", &"reaction", [&"s"], 4, 12.0, false, &"flinch_heavy")
	_add(&"reaction.stagger", &"stagger_01", &"reaction", [&"s"], 6, 10.0, false, &"stagger")
	_add(&"reaction.death", &"death_shutdown_01", &"death", [&"s"], 8, 10.0, false, &"death")
	_add(&"activity.checkpoint_halt", &"checkpoint_halt_01", &"activity", [&"s"], 4, 8.0, false, &"checkpoint_halt")
	_add(&"activity.patrol_scan", &"patrol_scan_01", &"activity", [&"s"], 6, 8.0, false, &"patrol_scan")
	_add(&"activity.search_sweep", &"search_sweep_01", &"activity", [&"s"], 6, 8.0, false, &"search_sweep")
	_add(&"activity.investigate_scan", &"investigate_scan_01", &"activity", [&"s"], 6, 8.0, false, &"investigate_scan")
	_add(&"activity.return_to_route", &"return_to_route_01", &"activity", [&"s"], 6, 8.0, false, &"return_to_route")


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
