extends Node2D

const OCEAN_ROOT := "res://content/runtime/sundered_keep/terrain/ocean/ocean_foam_"
const PIECES := [
	"edge_n", "edge_e", "edge_s", "edge_w",
	"corner_ne", "corner_nw", "corner_se", "corner_sw",
	"inner_corner_ne", "inner_corner_nw", "inner_corner_se", "inner_corner_sw",
	"endcap_n", "endcap_e", "endcap_s", "endcap_w",
	"t_junction_n", "t_junction_e", "t_junction_s", "t_junction_w",
]


func _ready() -> void:
	for index in range(PIECES.size()):
		var cell := Vector2i(index % 4, index / 4)
		var base := ColorRect.new()
		base.position = Vector2(cell) * Vector2(112.0, 88.0)
		base.size = Vector2(96.0, 72.0)
		base.color = Color("182b38")
		add_child(base)
		var floor_reference := ColorRect.new()
		floor_reference.position = base.position + _floor_reference_position(PIECES[index])
		floor_reference.size = Vector2(20.0, 20.0)
		floor_reference.color = Color("8b887b")
		add_child(floor_reference)
		var sprite := Sprite2D.new()
		sprite.texture = load(OCEAN_ROOT + PIECES[index] + ".png") as Texture2D
		sprite.position = base.position + Vector2(48.0, 36.0)
		sprite.scale = Vector2(2.0, 2.0)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		var label := Label.new()
		label.text = PIECES[index].to_upper()
		label.position = base.position + Vector2(0.0, 72.0)
		label.size = Vector2(104.0, 16.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		add_child(label)


func _floor_reference_position(piece: String) -> Vector2:
	if piece.ends_with("_n"):
		return Vector2(38.0, 0.0)
	if piece.ends_with("_e"):
		return Vector2(76.0, 26.0)
	if piece.ends_with("_s"):
		return Vector2(38.0, 52.0)
	if piece.ends_with("_w"):
		return Vector2(0.0, 26.0)
	return Vector2(76.0, 0.0) if piece.ends_with("ne") else Vector2(0.0, 0.0)
