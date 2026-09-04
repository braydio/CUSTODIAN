extends AmbientCreatureAnimationSet

const ROOT := "res://content/sprites/ambient_creatures/baby_opossum/runtime"
const LOOP_ACTIONS := {"idle":true,"idle_south":true,"idle_alt":true,"look":true,"sniff":true,"waddle":true,"scurry":true,"sit_idle":true,"freeze":true,"play_dead_hold":true,"hide_hold":true,"eat":true,"wait":true,"follow":true,"search":true,"excited_idle":true,"retrieve":true}

func _init() -> void:
	set_id = &"ambient_baby_opossum"
	default_frame_size = Vector2i(96, 96)
	aliases = {"idle":"idle_south","move":"waddle","walk":"waddle","run":"scurry","flee":"scurry","play_dead":"play_dead_hold","hide":"hide_hold","reject_melee":"reject_hit","reject_projectile":"reject_hit","point":"find_target"}
	_scan_directory(ROOT)

func _scan_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null: return
	for filename in directory.get_files():
		if not filename.ends_with(".png"): continue
		var parts := filename.trim_suffix(".png").split("__")
		if parts.size() != 7 or parts[0] != "baby_opossum": continue
		var frame_size := parts[6].split("x")
		var size := Vector2i(int(frame_size[0]), int(frame_size[1])) if frame_size.size() == 2 else Vector2i(int(parts[6]), int(parts[6]))
		var action := StringName(parts[3])
		var direction := StringName(parts[4])
		clips.append({
			"action": action, "variant": action, "direction": direction,
			"path": "%s/%s" % [path, filename], "frame_count": int(parts[5].trim_suffix("f")),
			"frame_size": size, "fps": _fps(action), "loop": LOOP_ACTIONS.has(String(action)),
			"animation_name": StringName("%s__%s" % [String(action), String(direction)])
		})
	for directory_name in directory.get_directories(): _scan_directory("%s/%s" % [path, directory_name])

func _fps(action: StringName) -> float:
	return 12.0 if action in [&"scurry", &"startle", &"panic", &"flee_start"] else 8.0
