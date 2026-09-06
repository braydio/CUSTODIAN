extends AmbientCreatureAnimationSet

## Baby Opossum runtime clip discovery.
##
## Strips follow the canonical Asset V2 filename contract
## `<owner>__<layer>__<action_group>__<variant>__<direction>__<N>f__<WxH>.png`
## (see tools/assets/asset_naming.py). The variant is the semantic action and
## the layer is part of clip identity, so `baby_opossum__body__fear__hide_enter…`
## and `baby_opossum__barrel_prop__fear__hide_enter…` stay distinct clips on
## distinct presentation layers.

const ROOT := "res://content/sprites/ambient_creatures/baby_opossum/runtime"
const OWNER := "baby_opossum"
const PROP_LAYER := &"barrel_prop"
const VALID_DIRECTIONS := {"omni":true,"n":true,"ne":true,"e":true,"se":true,"s":true,"sw":true,"w":true,"nw":true}
const LOOP_ACTIONS := {"idle":true,"idle_south":true,"idle_alt":true,"look":true,"sniff":true,"waddle":true,"scurry":true,"sit_idle":true,"freeze":true,"play_dead_hold":true,"hide_hold":true,"eat":true,"wait":true,"follow":true,"search":true,"excited_idle":true,"retrieve":true}
const DEFAULT_FPS := 8.0

# Mirrors `content/metadata/assets/families/ambient_baby_opossum.asset.json`.
# Any action absent here falls back to the family's 8 FPS baseline.
const ACTION_FPS := {
	"idle_south":8.0,"idle_alt":8.0,"look":8.0,"sniff":8.0,"waddle":8.0,"scurry":12.0,
	"sit_enter":10.0,"sit_idle":8.0,"sit_exit":10.0,
	"alert":10.0,"startle":12.0,"freeze":8.0,"hiss":10.0,"panic":12.0,"flee_start":12.0,
	"play_dead_enter":10.0,"play_dead_hold":8.0,"play_dead_peek":10.0,"play_dead_exit":10.0,
	"hide_enter":10.0,"hide_hold":8.0,"hide_peek":10.0,"hide_exit":10.0,
	"reject_hit":12.0,"disapprove":8.0,"disapprove_hold":8.0,
	"notice_treat":10.0,"approach_wary":8.0,"sniff_treat":10.0,"take_treat":10.0,"eat":8.0,
	"friend_happy":10.0,"greet":10.0,"approach_player":8.0,"follow":8.0,"wait":8.0,
	"search":8.0,"dig":10.0,"find_target":8.0,"look_back":8.0,"excited_idle":8.0,
	"groom":8.0,"scratch":8.0,
	"danger_sense":10.0,"retrieve":8.0,"gift_drop":10.0
}

func _init() -> void:
	set_id = &"ambient_baby_opossum"
	default_frame_size = Vector2i(96, 96)
	aliases = {"idle":"idle_south","move":"waddle","walk":"waddle","run":"scurry","flee":"scurry","play_dead":"play_dead_hold","hide":"hide_hold","reject_melee":"reject_hit","reject_projectile":"reject_hit","point":"find_target"}
	_scan_directory(ROOT)
	refresh()

func _scan_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null: return
	for filename in directory.get_files():
		if not filename.ends_with(".png"): continue
		var clip := _parse_clip(path, filename)
		if not clip.is_empty(): clips.append(clip)
	for directory_name in directory.get_directories(): _scan_directory("%s/%s" % [path, directory_name])

func _parse_clip(path: String, filename: String) -> Dictionary:
	var parts := filename.trim_suffix(".png").split("__")
	if parts.size() != 7 or parts[0] != OWNER: return {}
	var direction := String(parts[4])
	var frames_token := String(parts[5])
	if not VALID_DIRECTIONS.has(direction) or not frames_token.ends_with("f"): return {}
	var frame_count := int(frames_token.trim_suffix("f"))
	if frame_count <= 0: return {}
	var frame_size := parts[6].split("x")
	var size := Vector2i(int(frame_size[0]), int(frame_size[1])) if frame_size.size() == 2 else Vector2i(int(parts[6]), int(parts[6]))
	if size.x <= 0 or size.y <= 0: return {}
	var layer := StringName(parts[1])
	var action := StringName(parts[3])
	return {
		"action": action, "variant": action, "layer": layer, "action_group": StringName(parts[2]),
		"direction": StringName(direction), "path": "%s/%s" % [path, filename],
		"frame_count": frame_count, "frame_size": size,
		"fps": float(ACTION_FPS.get(String(action), DEFAULT_FPS)),
		"loop": LOOP_ACTIONS.has(String(action)),
		"animation_name": StringName("%s__%s" % [String(action), direction])
	}
