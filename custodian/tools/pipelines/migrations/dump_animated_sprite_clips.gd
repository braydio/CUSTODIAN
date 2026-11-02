extends SceneTree
## C2a-R4 evidence input: every clip the `animated_sprite` compatibility resource
## carries, with the authored art each one actually draws.
##
## Clip names have proven unreliable as semantic authority throughout this
## migration, so the atlas filename is recorded as the provenance of record.
## Existing in this resource does NOT mean a clip is live; the consumer graph in
## `operator_animated_sprite_cutover_evidence.py` decides that.

const RESOURCE := "res://game/actors/operator/operator_runtime_frames.tres"
const CANONICAL := "res://content/sprites/operator/runtime/operator_runtime_frames.tres"
const OUT := "res://../reports/operator/operator_animated_sprite_clips.json"


func _init() -> void:
	var legacy: SpriteFrames = load(RESOURCE)
	var canonical: SpriteFrames = load(CANONICAL)
	var clips := {}
	var names := legacy.get_animation_names()
	names.sort()
	for name in names:
		var clip := StringName(name)
		var frame_count := legacy.get_frame_count(clip)
		var art := {}
		if frame_count > 0:
			var texture := legacy.get_frame_texture(clip, 0)
			var atlas := texture as AtlasTexture
			if atlas != null and atlas.atlas != null:
				var parts := atlas.atlas.resource_path.get_file().replace(".png", "").split("__")
				if parts.size() >= 6:
					art = {
						"layer": parts[1], "profile": parts[2], "group": parts[3],
						"action": parts[4], "direction": parts[5],
						"sheet": atlas.atlas.resource_path,
					}
		var durations: Array = []
		for index in frame_count:
			durations.append(legacy.get_frame_duration(clip, index))
		var canonical_identity := ""
		if not art.is_empty():
			canonical_identity = "%s/%s/%s/%s/%s" % [
				art["profile"], art["group"], art["action"], art["direction"], art["layer"]]
		clips[String(name)] = {
			"frames": frame_count,
			"fps": legacy.get_animation_speed(clip),
			"loop": legacy.get_animation_loop(clip),
			"durations": durations,
			"art": art,
			"canonical_identity": canonical_identity,
			"canonical_published": canonical_identity != "" \
				and canonical.has_animation(StringName(canonical_identity)),
		}
	var payload := {
		"schema": "custodian.operator_animated_sprite_clips.v1",
		"resource": RESOURCE,
		"clips": clips,
	}
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file == null:
		push_error("cannot write %s" % OUT)
		quit(1)
		return
	file.store_string(JSON.stringify(payload, "  ") + "\n")
	file.close()
	print("wrote %s (%d clips)" % [OUT, clips.size()])
	quit()
