class_name Operator3DPreviewCatalog
extends RefCounted

## Dev-only frame catalog for the playable 3D Operator preview.
##
## Reads the git-ignored staging folder written by the Operator scale-probe export
## (res://.ai/operator_3d_animation_preview). This is a preview-only reader: it is not a
## production SpriteFrames database, not a runtime manifest, and not an animation authority.

const ROOT := "res://.ai/operator_3d_animation_preview"
const DIRECTIONS := ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]

var _meta_cache: Dictionary = {}
var _texture_cache: Dictionary = {}


## Metadata for one action at one scale. scale is 80 or 50.
func meta(scale: int, action: String) -> Dictionary:
	var file := "%s/meta/%s.json" % [ROOT, action] if scale == 80 else "%s/meta/%s_50ppm.json" % [ROOT, action]
	if not _meta_cache.has(file):
		if not FileAccess.file_exists(file):
			push_error("[Operator3DPreviewCatalog] missing metadata %s" % file)
			_meta_cache[file] = {}
		else:
			_meta_cache[file] = JSON.parse_string(FileAccess.get_file_as_string(file))
	return _meta_cache[file]


func has_action(scale: int, action: String) -> bool:
	return not meta(scale, action).is_empty()


func frame_count(scale: int, action: String) -> int:
	return int(meta(scale, action).get("frame_count", 0))


func pivot(scale: int, action: String) -> Vector2:
	var p: Array = meta(scale, action).get("pivot", [0, 0])
	return Vector2(p[0], p[1])


func frame_size(scale: int, action: String) -> Vector2i:
	var s: Array = meta(scale, action).get("frame_size", [128, 128])
	return Vector2i(s[0], s[1])


func loop(scale: int, action: String) -> bool:
	return bool(meta(scale, action).get("loop", true))


## Cell texture for (scale, action, direction, frame index). Loaded once and cached.
func texture(scale: int, action: String, direction: String, index: int) -> ImageTexture:
	var key := "%d/%s/%s/%d" % [scale, action, direction, index]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var m := meta(scale, action)
	if m.is_empty():
		return null
	var folder := "frames80" if scale == 80 else "frames50"
	var path := "%s/%s/%s/%s/%04d.png" % [ROOT, folder, action, direction, index]
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		push_error("[Operator3DPreviewCatalog] could not load %s" % path)
		return null
	var tex := ImageTexture.create_from_image(image)
	_texture_cache[key] = tex
	return tex


## Directional mapping from a 2D movement vector. Screen +y is down, which is the S direction
## (the character faces the viewer), so the angle maps directly to the eight sprite directions.
static func direction_for_velocity(v: Vector2) -> String:
	var angle_deg := rad_to_deg(atan2(v.y, v.x))
	var step := roundi(angle_deg / 45.0)
	match step:
		0:
			return "E"
		1:
			return "SE"
		2:
			return "S"
		3:
			return "SW"
		4, -4:
			return "W"
		-3:
			return "NW"
		-2:
			return "N"
		-1:
			return "NE"
	return "S"
