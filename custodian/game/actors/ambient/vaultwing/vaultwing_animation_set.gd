extends AmbientCreatureAnimationSet

## Runtime semantic discovery for the Asset V2 Common Vaultwing family.

const ROOT := "res://content/sprites/ambient_creatures/vaultwing_common/runtime"
const OWNER := "vaultwing_common"
const VALID_DIRECTIONS := {"n":true, "s":true, "e":true, "w":true, "omni":true}
const LOOP_ACTIONS := {"glide":true, "flap":true, "perch_idle":true, "ground_idle":true, "ground_walk":true}
const ACTION_FPS := {
	"glide":8.0, "flap":10.0, "dive_windup":10.0, "dive_strike":14.0,
	"climb_out":12.0, "land":10.0, "takeoff":12.0, "perch_idle":6.0,
	"ground_idle":6.0, "ground_walk":8.0, "bite_attack":12.0,
	"air_stagger":12.0, "hurt":12.0, "death":10.0
}

func _init() -> void:
	set_id = &"ambient_vaultwing_common"
	default_frame_size = Vector2i(256, 256)
	aliases = {"idle":"ground_idle", "move":"ground_walk", "attack":"bite_attack"}
	rescan_runtime()

## Asset V2 runtime files may be imported after this Resource is preloaded.
## Re-scan at actor initialization so published clips become visible without
## requiring a second process/editor restart.
func rescan_runtime() -> void:
	clips.clear()
	_scan_directory(ROOT)
	refresh()

func _scan_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null: return
	for filename in directory.get_files():
		if filename.ends_with(".png"):
			var clip := _parse_clip(path, filename)
			if not clip.is_empty(): clips.append(clip)
	for child in directory.get_directories(): _scan_directory("%s/%s" % [path, child])

func _parse_clip(path: String, filename: String) -> Dictionary:
	var parts := filename.trim_suffix(".png").split("__")
	if parts.size() != 7 or parts[0] != OWNER or not VALID_DIRECTIONS.has(parts[4]): return {}
	var frame_count := int(String(parts[5]).trim_suffix("f"))
	var dimensions := String(parts[6]).split("x")
	if frame_count <= 0 or dimensions.is_empty() or dimensions.size() > 2: return {}
	var width := int(dimensions[0])
	var height := width if dimensions.size() == 1 else int(dimensions[1])
	var size := Vector2i(width, height)
	if size != default_frame_size: return {}
	var action := StringName(parts[3])
	return {
		"action": action, "variant": action, "layer": StringName(parts[1]),
		"action_group": StringName(parts[2]), "direction": StringName(parts[4]),
		"path": "%s/%s" % [path, filename], "frame_count": frame_count,
		"frame_size": size, "fps": float(ACTION_FPS.get(String(action), 8.0)),
		"loop": LOOP_ACTIONS.has(String(action)),
		"animation_name": StringName("%s__%s" % [String(action), parts[4]])
	}
