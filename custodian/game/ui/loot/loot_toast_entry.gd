extends PanelContainer

@onready var accent_strip: ColorRect = $Margin/HBox/Accent
@onready var icon: TextureRect = $Margin/HBox/Icon
@onready var title_label: Label = $Margin/HBox/Copy/Title
@onready var detail_label: Label = $Margin/HBox/Copy/Detail


func configure(
	display_name: String,
	quantity: int,
	accent: Color,
	icon_texture: Texture2D = null,
	detail: String = ""
) -> void:
	accent_strip.color = accent
	icon.texture = icon_texture
	icon.visible = icon_texture != null
	title_label.text = display_name
	detail_label.text = detail if not detail.is_empty() else "+%d" % quantity
	title_label.add_theme_color_override("font_color", Color.WHITE)
	detail_label.add_theme_color_override("font_color", accent.lightened(0.12))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.045, 0.92)
	style.border_color = Color(0.30, 0.38, 0.42, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 4
	add_theme_stylebox_override("panel", style)
