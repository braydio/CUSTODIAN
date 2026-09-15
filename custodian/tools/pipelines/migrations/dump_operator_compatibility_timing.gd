extends SceneTree
## Migration-only: capture the FROZEN authored-timing baseline for the Operator
## migration, by dumping timing and texture provenance from every compatibility
## SpriteFrames.
##
## The output is evidence, not a build product. Compatibility `.tres` files are
## generated machinery that `update_operator_compatibility_resources.py`
## legitimately refreshes from canonical assets, so they cannot serve as the
## historical record of what the art was authored to do -- a refresh silently
## rewrites the very values a cutover is supposed to preserve. The baseline is
## captured once and then frozen; `--refresh-baseline` is required to replace it.
##
## It retires when C2b deletes the compatibility migration surface.
##
## Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md

const OUT := "res://../reports/operator/operator_compatibility_timing.json"
const CANONICAL := "res://content/sprites/operator/runtime/operator_runtime_frames.tres"
const RESOURCES := {
	"modular_lower_body_sprite": "res://game/actors/operator/operator_modular_lower_body_frames.tres",
	"modular_upper_body_sprite": "res://game/actors/operator/operator_modular_upper_body_frames.tres",
	"modular_sidearm_sprite": "res://game/actors/operator/operator_modular_sidearm_frames.tres",
	"modular_upper_fx_sprite": "res://game/actors/operator/operator_modular_upper_fx_frames.tres",
}


func _provenance(sprite_frames: SpriteFrames, animation: StringName) -> Dictionary:
	## The atlas filename is the only reliable record of which authored sheet a
	## compatibility clip actually draws; clip names have proven unreliable.
	var texture := sprite_frames.get_frame_texture(animation, 0)
	var atlas := texture as AtlasTexture
	if atlas == null or atlas.atlas == null:
		return {}
	var file := atlas.atlas.resource_path.get_file().replace(".png", "")
	var parts := file.split("__")
	if parts.size() < 6:
		return {}
	return {
		"layer": parts[1], "profile": parts[2], "group": parts[3],
		"action": parts[4], "direction": parts[5],
	}


func _git_head() -> String:
	var output: Array = []
	var exit_code := OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"),
		"rev-parse", "HEAD"], output, true)
	if exit_code != 0 or output.is_empty():
		return ""
	return String(output[0]).strip_edges()


func _init() -> void:
	var refresh := false
	for argument in OS.get_cmdline_user_args():
		if argument == "--refresh-baseline":
			refresh = true
	if FileAccess.file_exists(OUT) and not refresh:
		push_error(
			"%s is frozen migration evidence: the authored timing it records is what " % OUT
			+ "renderer cutovers are validated against, and compatibility resources are "
			+ "regenerated machinery that can no longer reproduce it. Re-capture only "
			+ "deliberately, with --refresh-baseline."
		)
		quit(1)
		return

	var canonical: SpriteFrames = load(CANONICAL)
	var payload := {
		"schema": "custodian.operator_compatibility_timing.v1",
		"baseline_purpose":
			"Frozen authored timing captured from the Operator compatibility SpriteFrames "
			+ "before their renderers were cut over. This is the oracle for "
			+ "operator_timing_preservation_smoke.gd; the live compatibility resources are "
			+ "regenerated machinery and are NOT authoritative.",
		"frozen": true,
		"captured_from_commit": _git_head(),
		"resources": {},
	}
	for renderer in RESOURCES:
		var sprite_frames: SpriteFrames = load(RESOURCES[renderer])
		if sprite_frames == null:
			push_error("missing compatibility resource for %s" % renderer)
			continue
		var clips := {}
		var names := sprite_frames.get_animation_names()
		names.sort()
		for name in names:
			var animation := StringName(name)
			var frame_count := sprite_frames.get_frame_count(animation)
			if frame_count == 0:
				continue
			var durations: Array = []
			for index in frame_count:
				durations.append(sprite_frames.get_frame_duration(animation, index))
			clips[String(name)] = {
				"frames": frame_count,
				"fps": sprite_frames.get_animation_speed(animation),
				"loop": sprite_frames.get_animation_loop(animation),
				"durations": durations,
				"art": _provenance(sprite_frames, animation),
			}
		payload["resources"][renderer] = {
			"path": RESOURCES[renderer],
			"clips": clips,
		}

	var generated := {}
	for name in canonical.get_animation_names():
		var animation := StringName(name)
		var frame_count := canonical.get_frame_count(animation)
		var durations: Array = []
		for index in frame_count:
			durations.append(canonical.get_frame_duration(animation, index))
		generated[String(name)] = {
			"frames": frame_count,
			"fps": canonical.get_animation_speed(animation),
			"loop": canonical.get_animation_loop(animation),
			"durations": durations,
		}
	# Informational only. The gate must read current canonical timing from the
	# live generated resource, never from this snapshot, or it would compare a
	# stale canonical against itself and pass through real drift.
	payload["canonical_snapshot_informational_only"] = generated

	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file == null:
		push_error("cannot write %s" % OUT)
		quit(1)
		return
	file.store_string(JSON.stringify(payload, "  ") + "\n")
	file.close()
	print("wrote frozen baseline %s (%d compatibility resources, %d canonical animations)" % [
		OUT, payload["resources"].size(), generated.size()
	])
	quit()
