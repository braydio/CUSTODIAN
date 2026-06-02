class_name BlackReliquaryMinimapFrame
extends Control

const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")

@onready var plate: Panel = get_node_or_null("Plate")
@onready var title_label: Label = get_node_or_null("Plate/TitlePlaque/Title")
@onready var fill_rect: TextureRect = get_node_or_null("Plate/MapArea/Fill")


func _ready() -> void:
	_apply_style()
	_place_marker("PlayerMarker", Catalog.MARKER_PLAYER, Vector2(0.50, 0.70), Vector2(18, 18))
	_place_marker("GateLockedMarker", Catalog.MARKER_GATE_LOCKED, Vector2(0.50, 0.36), Vector2(20, 20))
	_place_marker("ReturnMooringMarker", Catalog.MARKER_RETURN_MOORING, Vector2(0.28, 0.62), Vector2(18, 18))
	_place_marker("ObjectiveMarker", Catalog.MARKER_OBJECTIVE, Vector2(0.56, 0.22), Vector2(18, 18))
	_place_marker("StairUpMarker", Catalog.MARKER_STAIR_UP, Vector2(0.68, 0.46), Vector2(16, 16))
	_place_marker("StairDownMarker", Catalog.MARKER_STAIR_DOWN, Vector2(0.30, 0.36), Vector2(16, 16))


func set_title(text: String) -> void:
	if title_label != null:
		title_label.text = text.to_upper()


func _apply_style() -> void:
	if plate != null:
		plate.add_theme_stylebox_override("panel", Styles.panel_style(true))
	if title_label != null:
		Styles.apply_label(title_label, Palette.GOLD_TEXT, 13, true)
	if fill_rect != null:
		fill_rect.texture = Styles.load_texture(Catalog.MINIMAP_FILL_DARK)
		fill_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fill_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fill_rect.stretch_mode = TextureRect.STRETCH_TILE


func _place_marker(node_name: String, path: String, normalized_position: Vector2, size: Vector2) -> void:
	var map_area := get_node_or_null("Plate/MapArea") as Control
	if map_area == null:
		return
	var marker := map_area.get_node_or_null(node_name) as TextureRect
	if marker == null:
		marker = TextureRect.new()
		marker.name = node_name
		marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_area.add_child(marker)
	marker.texture = Styles.load_texture(path)
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marker.custom_minimum_size = size
	marker.size = size
	marker.anchor_left = normalized_position.x
	marker.anchor_top = normalized_position.y
	marker.anchor_right = normalized_position.x
	marker.anchor_bottom = normalized_position.y
	marker.offset_left = -size.x * 0.5
	marker.offset_top = -size.y * 0.5
	marker.offset_right = size.x * 0.5
	marker.offset_bottom = size.y * 0.5
	marker.visible = marker.texture != null
