extends Node
class_name PursuitFrame3DCandidateAdapter
## Debug-only candidate body for the Pursuit Frame 3D preview.
##
## Gameplay semantics stay with the enemy, its behavior state machine and
## EnemyPresentationController. This node only chooses which body is visible:
## it reads the enemy's current presentation action and travel direction through
## public methods, maps them to a staged 3D clip, and draws that frame at the
## enemy's contact shadow. The legacy body is hidden while candidate mode is on
## and restored exactly when it is turned off.

const MANIFEST_PATH := "res://.ai/pursuit_frame_3d_preview/manifest.json"
const FRAMES_DIR := "res://.ai/pursuit_frame_3d_preview/frames"
## Operator contract: game sprite space is 50 px per metre (see the Operator 3D
## contract). Candidate frames are rendered at 80 px/m, so they display at 50/80.
const GAME_PX_PER_M := 50.0
const CANDIDATE_PX_PER_M := 80.0
const SHADOW_OFFSET := Vector2(0.0, 13.0)  # BlobShadow position in pursuit_frame.tscn
const COMPASS := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]  # screen-space, index = angle/45deg
const INSPECT_ACTIONS := [
	"running", "walking", "alert", "agree_gesture", "casual_walk", "arise",
	"attack", "behit_flyup", "skill_01", "skill_03", "triple_combo_attack",
]
const FRAME_CACHE_LIMIT := 48

signal mode_changed(presentation: StringName, mode: StringName)

var presentation: StringName = &"candidate"  # candidate | legacy
var mode: StringName = &"gameplay"  # gameplay | inspect
var paused := false
var native_scale := false
var inspect_action_index := 0
var inspect_dir_index := 2  # E
var fps_override := 0.0  # 0 = use the staged sampling_target_fps for the clip

var manifest: Dictionary = {}
var enemy: CharacterBody2D = null
var candidate_sprite: Sprite2D = null
var legacy_body: CanvasItem = null
var legacy_fx: CanvasItem = null
var legacy_visual: CanvasItem = null
var _legacy_visible := {}

var clip_name := ""
var clip_time := 0.0
var last_mapped_clip := "walking"
var last_dir := "S"
var frame_index := 0
var label := ""
var _cache: Dictionary = {}
var _cache_order: Array[String] = []
var _telemetry_file: FileAccess = null
var _telemetry_tick := 0
var frame_step_request := 0


func _ready() -> void:
	enemy = get_parent() as CharacterBody2D
	assert(enemy != null, "PursuitFrame3DCandidateAdapter must be a child of the enemy body")
	manifest = _load_manifest()
	legacy_body = enemy.get_node_or_null("AnimatedSprite2D")
	legacy_fx = enemy.get_node_or_null("CustomEnemyFxSprite")
	legacy_visual = enemy.get_node_or_null("Visual")
	for node in [legacy_body, legacy_fx, legacy_visual]:
		if node != null:
			_legacy_visible[node] = node.visible
	candidate_sprite = Sprite2D.new()
	candidate_sprite.name = "Candidate3DBody"
	candidate_sprite.centered = false
	candidate_sprite.position = SHADOW_OFFSET
	candidate_sprite.z_index = 0
	enemy.add_child(candidate_sprite)
	_open_telemetry()
	_apply_presentation()


func _exit_tree() -> void:
	if _telemetry_file != null:
		_telemetry_file.close()
		_telemetry_file = null


func _load_manifest() -> Dictionary:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	assert(file != null, "Staged candidate manifest missing: run custodian/tools/character3d/stage/pursuit_frame_stage.py")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "Staged candidate manifest is not a JSON object")
	return parsed


func _open_telemetry() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pf3d-telemetry="):
			var path := arg.trim_prefix("--pf3d-telemetry=")
			_telemetry_file = FileAccess.open(path, FileAccess.WRITE)


# --- public controls (driven by the preview root) --------------------------

func set_presentation(next: StringName) -> void:
	presentation = next
	_apply_presentation()
	mode_changed.emit(presentation, mode)


func toggle_presentation() -> void:
	set_presentation(&"legacy" if presentation == &"candidate" else &"candidate")


func set_mode(next: StringName) -> void:
	mode = next
	clip_time = 0.0
	mode_changed.emit(presentation, mode)


func toggle_mode() -> void:
	set_mode(&"inspect" if mode == &"gameplay" else &"gameplay")


func cycle_inspect_action(step: int) -> void:
	inspect_action_index = posmod(inspect_action_index + step, INSPECT_ACTIONS.size())
	clip_time = 0.0


func cycle_inspect_direction(step: int) -> void:
	inspect_dir_index = posmod(inspect_dir_index + step, COMPASS.size())


func step_frame(step: int) -> void:
	frame_step_request += step


func set_paused(value: bool) -> void:
	paused = value
	enemy.set_physics_process(not paused)


func toggle_paused() -> void:
	set_paused(not paused)


func adjust_fps(delta_fps: float) -> void:
	var current := _current_fps()
	fps_override = clampf(current + delta_fps, 2.0, 30.0)


func toggle_native_scale() -> void:
	native_scale = not native_scale
	_apply_scale()


func current_display_scale() -> float:
	return 1.0 if native_scale else GAME_PX_PER_M / CANDIDATE_PX_PER_M


func visible_body_count() -> int:
	var count := 0
	if legacy_body != null and legacy_body.visible:
		count += 1
	if candidate_sprite != null and candidate_sprite.visible:
		count += 1
	return count


# --- per-frame ------------------------------------------------------------

func _physics_process(delta: float) -> void:
	advance(delta)


## Resolves the presentation for one tick. Public so debug controls and tests can
## apply a state change immediately instead of waiting for the next physics tick.
func advance(delta: float) -> void:
	if enemy == null:
		return
	var resolved := _resolve()
	var clip: String = resolved["clip"]
	var dir: String = resolved["dir"]
	var static_frame: bool = resolved["static"]
	label = resolved["label"]
	if clip != clip_name:
		clip_name = clip
		clip_time = 0.0
	if not static_frame and not paused:
		clip_time += delta
	last_dir = dir
	_update_frame(clip, dir, static_frame, bool(resolved["loop"]))
	_apply_presentation()
	_write_telemetry()


func _process(_delta: float) -> void:
	_apply_presentation()


func _resolve() -> Dictionary:
	if mode == &"inspect":
		var inspected: String = INSPECT_ACTIONS[inspect_action_index]
		return _resolved(inspected, COMPASS[inspect_dir_index], false, _clip_loops(inspected))
	var legacy_action := String(enemy.get_enemy_presentation_action())
	var direction := _travel_direction()
	var dir := _compass(direction)
	match legacy_action:
		"locomotion.run", "locomotion.relaxed_run":
			last_mapped_clip = "running"
			return _resolved("running", dir, false, true, "")
		"locomotion.walk", "locomotion.relaxed_walk":
			last_mapped_clip = "walking"
			return _resolved("walking", dir, false, true, "")
		"posture.alert":
			last_mapped_clip = "alert"
			return _resolved("alert", dir, false, true, "")
		"locomotion.ready_idle", "locomotion.relaxed_idle", "":
			# No authored 3D idle exists yet. Hold one walking frame, labelled as a fallback.
			return _resolved("walking", dir, true, false, "IDLE FALLBACK (static walk frame 0, not an authored idle)")
		_:
			# Attacks, reactions and activities are inspect-only: hold the last mapped pose.
			return _resolved(last_mapped_clip, dir, true, false, "UNMAPPED GAMEPLAY ACTION: %s" % legacy_action)


func _resolved(clip: String, dir: String, static_frame: bool, loops: bool, note := "") -> Dictionary:
	var suffix := note
	if suffix.is_empty():
		suffix = "INSPECT" if mode == &"inspect" else "GAMEPLAY MAPPED"
	return {"clip": clip, "dir": dir, "static": static_frame, "loop": loops, "label": suffix}


func _travel_direction() -> Vector2:
	if enemy.velocity.length() > 0.5:
		return enemy.velocity.normalized()
	var facing: Vector2 = enemy.get_last_move_direction()
	return facing.normalized() if facing.length_squared() > 0.0001 else Vector2.DOWN


func _compass(v: Vector2) -> String:
	var index := int(round(wrapf(v.angle(), 0.0, TAU) / (PI / 4.0))) % 8
	return COMPASS[index]


func _clip_loops(clip: String) -> bool:
	return clip in ["running", "walking"]


func _current_fps() -> float:
	if fps_override > 0.0:
		return fps_override
	var clip_info := _clip_info(clip_name)
	return float(clip_info.get("sampling_target_fps", 24.0))


func _clip_info(clip: String) -> Dictionary:
	var actions: Dictionary = manifest.get("actions", {})
	return actions.get(clip, {})


func _update_frame(clip: String, dir: String, static_frame: bool, loops: bool) -> void:
	var info := _clip_info(clip)
	if info.is_empty():
		return
	var count := int(info.get("frame_count", 1))
	if static_frame:
		frame_index = 0
	else:
		var raw := int(floor(clip_time * _current_fps()))
		if frame_step_request != 0:
			raw = posmod(frame_index + frame_step_request, count)
			clip_time = float(raw) / _current_fps()
			frame_step_request = 0
		frame_index = posmod(raw, count) if loops else mini(raw, count - 1)
	candidate_sprite.texture = _texture_for(clip, dir, frame_index)
	var root: Array = info.get("root_px", [128, 180])
	candidate_sprite.offset = -Vector2(float(root[0]), float(root[1]))
	_apply_scale()


func _texture_for(clip: String, dir: String, index: int) -> Texture2D:
	var info := _clip_info(clip)
	var cls := String(info.get("viewport", "standard_256x256"))
	var key := "%s/%s/%s/%02d" % [cls, clip, dir, index]
	if _cache.has(key):
		return _cache[key]
	var path := "%s/%s/%s/%s/frame_%02d.png" % [ProjectSettings.globalize_path(FRAMES_DIR), cls, clip, dir, index]
	var image := Image.load_from_file(path)
	assert(image != null, "Missing staged candidate frame: %s" % path)
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	_cache_order.append(key)
	while _cache_order.size() > FRAME_CACHE_LIMIT:
		_cache.erase(_cache_order.pop_front())
	return texture


func _apply_scale() -> void:
	if candidate_sprite != null:
		var s := current_display_scale()
		candidate_sprite.scale = Vector2(s, s)


func _apply_presentation() -> void:
	var candidate_on := presentation == &"candidate"
	if candidate_sprite != null:
		candidate_sprite.visible = candidate_on
	for node in _legacy_visible.keys():
		if is_instance_valid(node):
			node.visible = _legacy_visible[node] and not candidate_on


# --- telemetry ------------------------------------------------------------

func _write_telemetry() -> void:
	if _telemetry_file == null:
		return
	_telemetry_tick += 1
	var record := {
		"tick": _telemetry_tick,
		"presentation": String(presentation),
		"mode": String(mode),
		"legacy_action": String(enemy.get_enemy_presentation_action()),
		"clip_3d": clip_name,
		"direction": last_dir,
		"frame": frame_index,
		"fps": _current_fps(),
		"label": label,
		"position": [enemy.global_position.x, enemy.global_position.y],
		"velocity": [enemy.velocity.x, enemy.velocity.y],
		"root_global": [enemy.to_global(candidate_sprite.position).x, enemy.to_global(candidate_sprite.position).y],
		"shadow_global": [enemy.to_global(SHADOW_OFFSET).x, enemy.to_global(SHADOW_OFFSET).y],
		"visible_body_count": visible_body_count(),
		"display_scale": current_display_scale(),
		"paused": paused,
	}
	_telemetry_file.store_line(JSON.stringify(record))
