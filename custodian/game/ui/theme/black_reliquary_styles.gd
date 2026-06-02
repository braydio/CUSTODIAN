class_name BlackReliquaryStyles
extends RefCounted

const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")

static var _warned_missing: Dictionary = {}


static func load_texture(path: String) -> Texture2D:
	if path.strip_edges().is_empty():
		return null
	if ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is Texture2D:
			return resource as Texture2D
	_warn_once(path, "Missing or invalid Black Reliquary texture")
	return null


static func panel_style(deep := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL_DEEP if deep else Palette.PANEL
	style.border_color = Palette.BORDER_DIM if deep else Palette.BORDER
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.shadow_color = Palette.BLACK_SHADOW
	style.shadow_size = 5
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


static func bar_background_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL_DEEP
	style.border_color = Palette.BORDER_DIM
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


static func bar_fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


static func apply_label(label: Label, color: Color = Palette.BODY_TEXT, font_size := 14, uppercase := false) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	if uppercase:
		label.text = label.text.to_upper()


static func configure_nine_patch(rect: NinePatchRect, texture_path: String, fallback_margins := Vector4i(32, 32, 32, 32)) -> bool:
	if rect == null:
		return false
	var texture := load_texture(texture_path)
	if texture == null:
		rect.visible = false
		return false
	rect.texture = texture
	var margins := _read_nine_patch_margins(texture_path, fallback_margins)
	rect.patch_margin_left = margins.x
	rect.patch_margin_top = margins.y
	rect.patch_margin_right = margins.z
	rect.patch_margin_bottom = margins.w
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.visible = true
	return true


static func _read_nine_patch_margins(texture_path: String, fallback: Vector4i) -> Vector4i:
	var metadata_path := texture_path.get_basename() + ".game32.json"
	if not ResourceLoader.exists(metadata_path):
		return fallback
	var file := FileAccess.open(metadata_path, FileAccess.READ)
	if file == null:
		return fallback
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return fallback
	var ninepatch: Dictionary = (parsed as Dictionary).get("ninepatch", {})
	if ninepatch.is_empty():
		return fallback
	return Vector4i(
		int(ninepatch.get("godot_patch_margin_left", fallback.x)),
		int(ninepatch.get("godot_patch_margin_top", fallback.y)),
		int(ninepatch.get("godot_patch_margin_right", fallback.z)),
		int(ninepatch.get("godot_patch_margin_bottom", fallback.w))
	)


static func _warn_once(key: String, message: String) -> void:
	if _warned_missing.has(key):
		return
	_warned_missing[key] = true
	push_warning("[BlackReliquaryUI] %s: %s" % [message, key])
