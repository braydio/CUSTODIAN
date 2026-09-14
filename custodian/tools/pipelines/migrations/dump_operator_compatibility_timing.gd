extends SceneTree
## Migration-only: dump authored timing + texture provenance from every Operator
## compatibility SpriteFrames, so the timing-preservation tool can compare it
## against what the canonical pipeline currently generates.
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


func _init() -> void:
	var canonical: SpriteFrames = load(CANONICAL)
	var payload := {
		"schema": "custodian.operator_compatibility_timing.v1",
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
	payload["canonical"] = generated

	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file == null:
		push_error("cannot write %s" % OUT)
		quit(1)
		return
	file.store_string(JSON.stringify(payload, "  ") + "\n")
	file.close()
	print("wrote %s (%d compatibility resources, %d canonical animations)" % [
		OUT, payload["resources"].size(), generated.size()
	])
	quit()
