extends SceneTree

## Windowed motion capture for the dev-only playable 3D Operator preview.
##
## Drives real mapped inputs through the Operator's own controller and records telemetry on every physics
## tick: world position, velocity, animation state, frame index, presentation owner, and body offset.
## Sequence: walk east, change direction to south, sprint south-west. Screenshots are saved every few ticks.
## Output: res://.ai/operator_3d_animation_preview/motion/ (telemetry.json, frames/*.png)
## Run (needs a display): godot --path custodian --script res://tools/validation/operator_3d_playable_motion_capture.gd

const SCENE := "res://scenes/debug/operator_3d_playable_preview_awakening.tscn"
const OUT := "res://.ai/operator_3d_animation_preview/motion"
const SPAWN := Vector2(0.0, -1824.0)
const LAYOUT := preload("res://game/world/awakening/awakening_layout.gd")
const SHOT_EVERY := 3
const SEGMENTS := [
	{"name": "walk_east", "inputs": ["move_right"], "ticks": 90},
	{"name": "walk_south", "inputs": ["move_down"], "ticks": 60},
	{"name": "sprint_south_west", "inputs": ["move_left", "move_down", "sprint"], "ticks": 90},
]

var _failures: Array[String] = []
var _telemetry: Array = []


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)
		push_error("[operator_3d_playable_motion_capture] FAIL: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out_abs := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(out_abs + "/frames")
	var root := (load(SCENE) as PackedScene).instantiate()
	get_root().add_child(root)
	for _i in 10:
		await process_frame
	var operator := root.get_node("Awakening/World/Operator") as CharacterBody2D
	var presenter = operator.get("_body_presenter")
	var owner3d := OperatorBodyPresenter.Owner.PREVIEW_3D_CANDIDATE
	_check(LAYOUT.is_point_walkable(SPAWN), "spawn is not walkable")
	operator.global_position = SPAWN
	operator.velocity = Vector2.ZERO
	for _i in 30:
		await physics_frame

	var tick := 0
	for seg in SEGMENTS:
		var seg_name: String = seg["name"]
		var inputs: Array = seg["inputs"]
		for a in inputs:
			Input.action_press(a)
		var seg_start_x := operator.global_position.x
		var seg_start_y := operator.global_position.y
		var saw_moving := 0
		var prev_frame := -1
		var frame_changes := 0
		var seen_actions := {}
		for _i in int(seg["ticks"]):
			await physics_frame
			await process_frame
			var pos := operator.global_position
			var vel := operator.velocity
			var record := {
				"tick": tick, "segment": seg_name,
				"pos": [snappedf(pos.x, 0.01), snappedf(pos.y, 0.01)],
				"velocity": [snappedf(vel.x, 0.01), snappedf(vel.y, 0.01)],
				"speed": snappedf(vel.length(), 0.01),
				"action": str(root.get("current_action")), "direction": str(root.get("current_direction")),
				"frame": int(root.get("current_frame")), "idle": bool(root.get("idle")),
				"owner": int(presenter.call("current_owner")), "visible_owners": presenter.call("visible_owners"),
				"preempted": int(root.get("preempted_count")),
			}
			var body := operator.get_node_or_null("Operator3DPreviewBody") as Sprite2D
			if body != null:
				record["body_position"] = [body.position.x, body.position.y]
				record["body_offset"] = [body.offset.x, body.offset.y]
				record["body_visible"] = body.visible
			_telemetry.append(record)
			if vel.length() >= 8.0:
				saw_moving += 1
				seen_actions[record["action"]] = int(seen_actions.get(record["action"], 0)) + 1
			if prev_frame >= 0 and record["frame"] != prev_frame:
				frame_changes += 1
			prev_frame = record["frame"]
			if tick % SHOT_EVERY == 0:
				var image := get_root().get_texture().get_image()
				image.save_png("%s/frames/%s_%04d.png" % [out_abs, seg_name, tick])
			tick += 1
		for a in inputs:
			Input.action_release(a)
		var displaced := Vector2(operator.global_position.x - seg_start_x, operator.global_position.y - seg_start_y).length()
		print("SEGMENT %s moving_ticks=%d displaced_px=%.1f frame_changes=%d actions=%s" % [seg_name, saw_moving, displaced, frame_changes, str(seen_actions)])
		_check(saw_moving > 0, "%s: no nonzero velocity" % seg_name)
		_check(displaced > 10.0, "%s: world position did not change (%.1f px)" % [seg_name, displaced])
		_check(frame_changes > 0, "%s: sprite frame index did not advance" % seg_name)
		for _j in 10:
			await physics_frame

	# Owner, body and collision invariants across the whole run.
	for rec in _telemetry:
		_check(int(rec["owner"]) == owner3d, "tick %d owner %s" % [rec["tick"], rec["owner"]])
		_check((rec["visible_owners"] as Array) == [owner3d], "tick %d visible owners %s" % [rec["tick"], str(rec["visible_owners"])])
		_check(rec.get("body_position", [0, 0]) == [0.0, 0.0], "tick %d body position not zero (duplicate displacement?)" % rec["tick"])
	_check(operator.collision_layer != 0 and operator.find_children("*", "CollisionShape2D", true, false).size() > 0,
		"collision disabled")

	var sprint_ok := false
	for rec in _telemetry:
		if rec["segment"] == "sprint_south_west" and rec["action"] == "running" and rec["speed"] >= 8.0:
			sprint_ok = true
	_check(sprint_ok, "sprint segment never selected running at speed")
	var diagonal_ok := false
	for rec in _telemetry:
		if rec["segment"] == "sprint_south_west" and rec["speed"] >= 8.0 and rec["direction"] == "SW" and rec["action"] == "running":
			diagonal_ok = true
	_check(diagonal_ok, "sprint segment never presented running SW at speed (diagonal not demonstrated)")
	var walk_ok := false
	for rec in _telemetry:
		if rec["segment"] == "walk_east" and rec["action"] == "walking" and rec["speed"] >= 8.0 and rec["direction"] == "E":
			walk_ok = true
	_check(walk_ok, "walk_east never presented walking E at speed")

	var file := FileAccess.open(out_abs + "/telemetry.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"ticks": _telemetry.size(), "failures": _failures, "telemetry": _telemetry}, "  "))
	file.close()
	print("MOTION_CAPTURE ticks=%d failures=%d" % [_telemetry.size(), _failures.size()])
	root.queue_free()
	quit(0 if _failures.is_empty() else 1)
