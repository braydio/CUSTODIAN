class_name BlackReliquaryPanel
extends PanelContainer

const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")

@export var texture_path: String = Catalog.PANEL_DARK_GOLD
@export var deep: bool = false

var _nine_patch: NinePatchRect = null


func _ready() -> void:
	_apply_style()


func set_panel_texture(path: String, use_deep := false) -> void:
	texture_path = path
	deep = use_deep
	if is_inside_tree():
		_apply_style()


func _apply_style() -> void:
	add_theme_stylebox_override("panel", Styles.panel_style(deep))
	_nine_patch = get_node_or_null("NinePatch") as NinePatchRect
	if _nine_patch == null:
		_nine_patch = NinePatchRect.new()
		_nine_patch.name = "NinePatch"
		_nine_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_nine_patch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_nine_patch)
		move_child(_nine_patch, 0)
	var has_texture: bool = Styles.configure_nine_patch(_nine_patch, texture_path)
	if has_texture:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
