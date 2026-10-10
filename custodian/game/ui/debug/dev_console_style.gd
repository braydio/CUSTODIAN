class_name DevConsoleStyle
extends RefCounted
## Console-specific presentation built from the canonical Black Reliquary
## palette. Do not create a second competing color palette here -- every
## color used below is `BlackReliquaryPalette`, not a local literal.

const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")

const MAX_WIDTH := 1120.0
const SIDE_MARGIN := 32.0
const HEIGHT_RATIO := 0.38
const MIN_HEIGHT := 230.0
const MAX_HEIGHT := 360.0
const BOTTOM_OFFSET := 24.0


static func frame_size_and_position(viewport_size: Vector2) -> Dictionary:
	var width := minf(MAX_WIDTH, viewport_size.x - SIDE_MARGIN)
	var height := clampf(viewport_size.y * HEIGHT_RATIO, MIN_HEIGHT, MAX_HEIGHT)
	var position := Vector2(
		(viewport_size.x - width) * 0.5,
		viewport_size.y - height - BOTTOM_OFFSET
	)
	return {"size": Vector2(width, height), "position": position}


static func frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL_DEEP
	style.border_color = Palette.BORDER
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_width_top = 2
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	return style


static func apply_heading(label: Label) -> void:
	label.text = label.text.to_upper()
	label.add_theme_color_override("font_color", Palette.GOLD_TEXT)
	label.add_theme_font_size_override("font_size", 13)


static func apply_mode_indicator(label: Label) -> void:
	label.text = label.text.to_upper()
	label.add_theme_color_override("font_color", Palette.MUTED_TEXT)
	label.add_theme_font_size_override("font_size", 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


static func apply_separator(separator: HSeparator) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BORDER
	style.content_margin_top = 1.0
	separator.add_theme_stylebox_override("separator", style)


static func apply_output(output: RichTextLabel) -> void:
	output.bbcode_enabled = true
	output.scroll_following = true
	output.selection_enabled = true
	output.focus_mode = Control.FOCUS_NONE
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.add_theme_color_override("default_color", Palette.BODY_TEXT)
	output.add_theme_font_size_override("normal_font_size", 14)


static func apply_input_frame(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BG_DARK
	style.border_color = Palette.BORDER_DIM
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(0.0, 42.0)


static func apply_focused_input_frame(panel: PanelContainer, focused: bool) -> void:
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style == null:
		return
	style.border_color = Palette.BLUE_TECH if focused else Palette.BORDER_DIM
	panel.add_theme_stylebox_override("panel", style)


static func apply_prompt(label: Label) -> void:
	label.add_theme_color_override("font_color", Palette.BORDER)
	label.add_theme_font_size_override("font_size", 16)


static func apply_command_input(input: LineEdit) -> void:
	input.placeholder_text = "Enter command… (try help)"
	input.add_theme_color_override("font_color", Palette.BODY_TEXT)
	input.add_theme_color_override("font_placeholder_color", Palette.MUTED_TEXT)
	input.add_theme_color_override("caret_color", Palette.BLUE_TECH)
	input.add_theme_font_size_override("font_size", 16)
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	flat.content_margin_left = 4.0
	input.add_theme_stylebox_override("normal", flat)
	input.add_theme_stylebox_override("focus", flat)


static func apply_footer_label(label: Label, align_right := false) -> void:
	label.add_theme_color_override("font_color", Palette.MUTED_TEXT)
	label.add_theme_font_size_override("font_size", 11)
	if align_right:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


static func apply_suggestions(list: ItemList) -> void:
	list.focus_mode = Control.FOCUS_NONE
	list.max_text_lines = 1
	list.add_theme_color_override("font_color", Palette.BODY_TEXT)
	list.add_theme_color_override("font_selected_color", Palette.GOLD_TEXT)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = Palette.BORDER_DIM
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	list.add_theme_stylebox_override("panel", style)


static func level_color(level: String) -> Color:
	match level:
		"ERROR":
			return Palette.DANGER
		"SUCCESS":
			return Palette.GREEN_SIGNAL
		"WARNING":
			return Palette.GOLD_TEXT
		"INPUT":
			return Palette.MUTED_TEXT
		_:
			return Palette.BODY_TEXT
