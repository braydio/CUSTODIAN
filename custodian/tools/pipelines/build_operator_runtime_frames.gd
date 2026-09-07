extends SceneTree
## Generates the sole Operator runtime SpriteFrames from the runtime manifest.
##
## Identity is `profile/group/action/direction/layer`, prefixed with
## `weapon/<weapon_id>/` for weapon-owned layers. Every presentation node shares
## this one resource and simply selects a different animation.

const MANIFEST_PATH := (
	"res://content/sprites/operator/runtime/"
	+ "operator_runtime_manifest.generated.json"
)

const OUTPUT_PATH := (
	"res://content/sprites/operator/runtime/"
	+ "operator_runtime_frames.tres"
)

const MANIFEST_SCHEMA := "custodian.operator_runtime_manifest.v1"
const DEFAULT_FPS := 12.0


func _init() -> void:
	quit(0 if _build() else 1)


func _build() -> bool:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("Missing Operator runtime manifest: %s" % MANIFEST_PATH)
		return false
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	var manifest: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if not (manifest is Dictionary) or manifest.get("schema", "") != MANIFEST_SCHEMA:
		push_error("Invalid Operator runtime manifest schema")
		return false

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var animations: Dictionary = manifest.get("animations", {})
	for identity_variant in animations.keys():
		var identity := String(identity_variant)
		var layers: Dictionary = animations[identity_variant].get("layers", {})
		for layer_variant in layers.keys():
			if not _add_layer(frames, "%s/%s" % [identity, layer_variant], layers[layer_variant], identity):
				return false

	var weapons: Dictionary = manifest.get("weapons", {})
	for weapon_variant in weapons.keys():
		var weapon_id := String(weapon_variant)
		var weapon: Dictionary = weapons[weapon_variant]
		var profile := String(weapon.get("animation_profile", ""))
		if profile.is_empty():
			push_error("Weapon %s has no animation profile" % weapon_id)
			return false
		var held: Dictionary = weapon.get("held", {})
		for direction_variant in held.keys():
			var identity := "%s/presentation/held_01/%s" % [profile, direction_variant]
			var name := "weapon/%s/%s/weapon" % [weapon_id, identity]
			if not _add_layer(frames, name, held[direction_variant], identity):
				return false
		var overrides: Dictionary = weapon.get("overrides", {})
		for slot_variant in overrides.keys():
			var identity := "%s/%s" % [profile, slot_variant]
			var slot_layers: Dictionary = overrides[slot_variant]
			for layer_variant in slot_layers.keys():
				var name := "weapon/%s/%s/%s" % [weapon_id, identity, layer_variant]
				if not _add_layer(frames, name, slot_layers[layer_variant], identity):
					return false

	var error := ResourceSaver.save(frames, OUTPUT_PATH)
	if error != OK:
		push_error("Failed saving Operator runtime SpriteFrames: %s" % error_string(error))
		return false
	print("built Operator runtime SpriteFrames: %s (%d animations)" % [
		OUTPUT_PATH, frames.get_animation_names().size()])
	return true


func _add_layer(
	frames: SpriteFrames, animation_name: String, spec: Dictionary, identity: String
) -> bool:
	var path := String(spec.get("path", ""))
	# The manifest is runtime authority; refuse anything that is not runtime art.
	if not path.contains("/runtime/"):
		push_error("non-runtime animation entered runtime frames: %s" % path)
		return false
	var texture := load(path) as Texture2D
	var size: Array = spec.get("frame_size", [])
	var frame_count := int(spec.get("frames", 0))
	if texture == null or size.size() < 2 or frame_count < 1:
		push_error("Invalid runtime manifest layer %s" % animation_name)
		return false
	var animation := StringName(animation_name)
	if frames.has_animation(animation):
		push_error("Duplicate runtime animation identity: %s" % animation_name)
		return false
	frames.add_animation(animation)
	# Authored timing wins; the sidecar is the only place real FPS/loop survive.
	frames.set_animation_speed(animation, float(spec.get("fps", DEFAULT_FPS)))
	frames.set_animation_loop(
		animation,
		bool(spec["loop"]) if spec.has("loop") else _should_loop_animation(identity)
	)
	var durations: Array = spec.get("durations", [])
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * int(size[0]), 0, int(size[0]), int(size[1]))
		var duration := float(durations[frame_index]) if frame_index < durations.size() else 1.0
		frames.add_frame(animation, atlas, duration)
	return true


func _should_loop_animation(identity: String) -> bool:
	var parts := identity.split("/")
	if parts.size() < 3:
		return false
	var group := parts[1]
	var action := parts[2]
	match group:
		"locomotion":
			return not action.contains("hitreact")
		"posture":
			return not (
				action.begins_with("draw_")
				or action.begins_with("ready_up_")
				or action.begins_with("relax_")
				or action.begins_with("sheathe_")
			)
		"defense":
			return action.contains("block_hold")
		_:
			return false
