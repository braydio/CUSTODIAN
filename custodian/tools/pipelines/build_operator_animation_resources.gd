extends SceneTree

const CATALOG_PATH := "res://content/data/operator/generated/operator_animation_catalog.generated.json"
const OUTPUT_PATH := "res://game/actors/operator/operator_animation_catalog_frames.tres"


func _init() -> void:
	var result := _build()
	quit(0 if result else 1)


func _build() -> bool:
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("Missing Operator animation catalog: %s" % CATALOG_PATH)
		return false
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	var catalog: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if not (catalog is Dictionary) or catalog.get("schema", "") != "custodian.operator_animation_catalog.v2":
		push_error("Invalid Operator animation catalog")
		return false
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var animations: Dictionary = catalog.get("animations", {})
	for semantic_key_variant in animations.keys():
		var semantic_key := String(semantic_key_variant)
		var layers: Dictionary = animations[semantic_key].get("layers", {})
		for layer_variant in layers.keys():
			var layer := String(layer_variant)
			var spec: Dictionary = layers[layer]
			var texture := load(String(spec.get("path", ""))) as Texture2D
			var size: Array = spec.get("frame_size", [])
			var frame_count := int(spec.get("frames", 0))
			if texture == null or size.size() < 2 or frame_count < 1:
				push_error("Invalid catalog layer %s/%s" % [semantic_key, layer])
				return false
			var animation := StringName("%s/%s" % [semantic_key, layer])
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 12.0)
			frames.set_animation_loop(animation, true)
			for frame_index in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(frame_index * int(size[0]), 0, int(size[0]), int(size[1]))
				frames.add_frame(animation, atlas)
	var error := ResourceSaver.save(frames, OUTPUT_PATH)
	if error != OK:
		push_error("Failed saving Operator catalog SpriteFrames: %s" % error_string(error))
		return false
	print("built Operator catalog SpriteFrames: %s" % OUTPUT_PATH)
	return true
