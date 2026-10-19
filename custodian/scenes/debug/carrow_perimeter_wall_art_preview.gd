extends Node2D

const WALL_ROOT := "res://asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/"
const WALL_SOURCES := {
	"EW A": {"file": "wall_walkway_ew_source.png", "position": Vector2(-1200, -350)},
	"EW B repeated": {"file": "wall_walkway_ew_source.png", "position": Vector2(232, -350)},
	"Corner": {"file": "wall_walkway_corner_source.png", "position": Vector2(1664, -517)},
	"NS": {"file": "wall_walkway_ns_source.png", "position": Vector2(2291, -311)},
}
const GRID_STEP := 32

var _art_root: Node2D


func _ready() -> void:
	_art_root = $World/PreviewArt
	for label in WALL_SOURCES:
		_add_source(label, WALL_SOURCES[label])
	_add_screen_note()
	queue_redraw()


func _add_source(label: String, record: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.name = label.replace(" ", "_")
	var image := Image.load_from_file(ProjectSettings.globalize_path(WALL_ROOT + String(record.file)))
	if image != null and not image.is_empty():
		sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	sprite.position = record.position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_art_root.add_child(sprite)
	var title := Label.new()
	title.text = label + " · " + String(record.file).replace("_source.png", "")
	title.position = record.position + Vector2(24, -32)
	title.add_theme_color_override("font_color", Color(1.0, 0.87, 0.48))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.02, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	_art_root.add_child(title)


func _add_screen_note() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PreviewNotes"
	add_child(layer)
	var note := Label.new()
	note.position = Vector2(28, 22)
	note.text = "CARROW YARD · SOURCE CANDIDATE REVIEW   |   Camera2D   |   ground grid 32 px\nRaw source art shown at 1:1 world scale. Connector placement is provisional; assembly is not approved."
	note.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	note.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	note.add_theme_constant_override("shadow_offset_x", 2)
	note.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(note)


func _draw() -> void:
	draw_rect(Rect2(-1800, -1250, 5200, 2250), Color("22262a"), true)
	for x in range(-1800, 3401, GRID_STEP):
		draw_line(Vector2(x, -1250), Vector2(x, 1000), Color(0.52, 0.57, 0.62, 0.18), 1.0)
	for y in range(-1250, 1001, GRID_STEP):
		draw_line(Vector2(-1800, y), Vector2(3400, y), Color(0.52, 0.57, 0.62, 0.18), 1.0)

	# Geometry-derived 16×6 and 6×6 footprints are references only. They do not
	# imply walkability, production collision, or elevated navigation semantics.
	var footprint_color := Color(0.28, 0.85, 0.95, 0.9)
	draw_rect(Rect2(-460, 34, 512, 192), footprint_color, false, 2.0)
	draw_rect(Rect2(972, 34, 512, 192), footprint_color, false, 2.0)
	draw_rect(Rect2(2111, 34, 512, 192), footprint_color, false, 2.0)
	draw_rect(Rect2(2111, 34, 192, 512), footprint_color, false, 2.0)
	for anchor in [Vector2(-460, 34), Vector2(972, 34), Vector2(2111, 34), Vector2(2651, 343)]:
		draw_circle(anchor, 7.0, Color(1.0, 0.3, 0.22, 1.0))
		draw_line(anchor + Vector2(-13, 0), anchor + Vector2(13, 0), Color(1.0, 0.3, 0.22), 2.0)
		draw_line(anchor + Vector2(0, -13), anchor + Vector2(0, 13), Color(1.0, 0.3, 0.22), 2.0)


func _get_operator_preview_state() -> Dictionary:
	var operator := $World/Operator as CharacterBody2D
	var camera := $World/Camera2D as Camera2D
	return {
		"operator_instance": operator != null,
		"operator_ground_position": operator.global_position if operator != null else Vector2.ZERO,
		"camera_zoom": camera.zoom if camera != null else Vector2.ZERO,
		"grid_step": GRID_STEP,
		"source_module_count": _art_root.get_child_count() / 2,
	}
