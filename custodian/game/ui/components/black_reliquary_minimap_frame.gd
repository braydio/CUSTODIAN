class_name BlackReliquaryMinimapFrame
extends Control

const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")
const LiveMinimapScene := preload("res://game/ui/minimap/minimap_panel.tscn")

@onready var plate: Panel = get_node_or_null("Plate")
@onready var title_label: Label = get_node_or_null("Plate/TitlePlaque/Title")
@onready var fill_rect: TextureRect = get_node_or_null("Plate/MapArea/Fill")
@onready var map_area: Control = get_node_or_null("Plate/MapArea")

var live_minimap: Control = null


func _ready() -> void:
	_apply_style()
	_mount_live_minimap()


func set_title(text: String) -> void:
	if title_label != null:
		title_label.text = text.to_upper()


func _apply_style() -> void:
	if plate != null:
		plate.add_theme_stylebox_override("panel", Styles.panel_style(true))
	if title_label != null:
		Styles.apply_label(title_label, Palette.GOLD_TEXT, 11, true)
	if fill_rect != null:
		fill_rect.texture = Styles.load_texture(Catalog.MINIMAP_FILL_DARK)
		fill_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fill_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fill_rect.stretch_mode = TextureRect.STRETCH_TILE
		fill_rect.visible = false


func _mount_live_minimap() -> void:
	if map_area == null:
		return
	live_minimap = LiveMinimapScene.instantiate() as Control
	if live_minimap == null:
		push_warning("[BlackReliquaryMinimapFrame] Unable to instantiate live minimap")
		if fill_rect != null:
			fill_rect.visible = true
		return
	live_minimap.name = "LiveMinimap"
	live_minimap.layout_mode = 1
	live_minimap.anchors_preset = PRESET_FULL_RECT
	live_minimap.anchor_right = 1.0
	live_minimap.anchor_bottom = 1.0
	live_minimap.offset_left = 0.0
	live_minimap.offset_top = 0.0
	live_minimap.offset_right = 0.0
	live_minimap.offset_bottom = 0.0
	live_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	live_minimap.custom_minimum_size = Vector2(112, 112)
	if "enable_expand_toggle" in live_minimap:
		live_minimap.set("enable_expand_toggle", false)
	if "compact_size" in live_minimap:
		live_minimap.set("compact_size", Vector2(112, 112))
	map_area.add_child(live_minimap)
	_strip_embedded_minimap_chrome()
	if live_minimap.has_method("refresh_now"):
		live_minimap.call_deferred("refresh_now")


func get_live_minimap() -> Control:
	return live_minimap


func _strip_embedded_minimap_chrome() -> void:
	if live_minimap == null:
		return
	for child_name in ["Background", "Frame"]:
		var chrome := live_minimap.get_node_or_null(child_name)
		if chrome is CanvasItem:
			(chrome as CanvasItem).visible = false
	var view := live_minimap.get_node_or_null("MinimapView") as Control
	if view == null:
		return
	view.anchor_left = 0.0
	view.anchor_top = 0.0
	view.anchor_right = 1.0
	view.anchor_bottom = 1.0
	view.offset_left = 0.0
	view.offset_top = 0.0
	view.offset_right = 0.0
	view.offset_bottom = 0.0
	if "map_padding_px" in view:
		view.set("map_padding_px", 3.0)
	if "player_pip_radius_px" in view:
		view.set("player_pip_radius_px", 2.4)
	if "enemy_pip_radius_px" in view:
		view.set("enemy_pip_radius_px", 1.6)
	if "utility_marker_radius_px" in view:
		view.set("utility_marker_radius_px", 2.0)
