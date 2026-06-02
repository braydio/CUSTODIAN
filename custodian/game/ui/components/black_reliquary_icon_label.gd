class_name BlackReliquaryIconLabel
extends HBoxContainer

const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")

@export var icon_path: String = ""
@export var label_text: String = ""
@export var icon_size: Vector2 = Vector2(32, 32)
@export var text_color: Color = Palette.BODY_TEXT
@export var font_size: int = 14

@onready var icon_rect: TextureRect = get_node_or_null("Icon")
@onready var text_label: Label = get_node_or_null("Label")


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_refresh()


func configure(path: String = "", text: String = "", size := Vector2(32, 32), color: Color = Palette.BODY_TEXT) -> void:
	icon_path = path
	label_text = text
	icon_size = size
	text_color = color
	if is_inside_tree():
		_refresh()


func set_icon(path: String, size := Vector2(32, 32)) -> void:
	icon_path = path
	icon_size = size
	if is_inside_tree():
		_refresh()


func set_label(text: String) -> void:
	label_text = text
	if is_inside_tree():
		_refresh()


func _refresh() -> void:
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(icon_rect)
	if text_label == null:
		text_label = Label.new()
		text_label.name = "Label"
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(text_label)

	var texture: Texture2D = Styles.load_texture(icon_path)
	icon_rect.texture = texture
	icon_rect.custom_minimum_size = icon_size
	icon_rect.visible = texture != null
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	text_label.text = label_text
	text_label.visible = not label_text.strip_edges().is_empty()
	Styles.apply_label(text_label, text_color, font_size)
