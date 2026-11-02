class_name BlackReliquaryPrompt
extends Control

const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")

@onready var header_patch: NinePatchRect = get_node_or_null("Stack/HeaderPlaque")
@onready var body_patch: NinePatchRect = get_node_or_null("Stack/BodyPlaque")
@onready var title_label: Label = get_node_or_null("Stack/HeaderPlaque/Title")
@onready var icon_rect: TextureRect = get_node_or_null("Stack/BodyPlaque/BodyRow/Icon")
@onready var body_label: Label = get_node_or_null("Stack/BodyPlaque/BodyRow/Body")
@onready var badge_rect: TextureRect = get_node_or_null("Stack/BodyPlaque/BodyRow/KeyBadge")
@onready var key_label: Label = get_node_or_null("Stack/BodyPlaque/BodyRow/KeyBadge/Key")

var _locked := false
var _action_name: StringName = &""
var _literal_hint := ""


func _ready() -> void:
	_apply_assets()
	var prompt_service := get_node_or_null("/root/InputPromptService")
	if prompt_service != null and prompt_service.has_signal("device_family_changed"):
		prompt_service.device_family_changed.connect(_on_device_family_changed)
	hide_prompt()


func show_prompt(title: String, body: String, input_hint: String = "G", icon_path: String = "") -> void:
	_locked = false
	_action_name = &""
	_literal_hint = input_hint
	_set_content(title, body, input_hint, icon_path)
	visible = true


func show_action_prompt(title: String, body: String, action_name: StringName = &"interact", icon_path: String = "") -> void:
	_locked = false
	_action_name = action_name
	_literal_hint = ""
	_set_content(title, body, _resolve_action_hint(), icon_path)
	visible = true


func hide_prompt() -> void:
	visible = false


func set_locked(title: String, body: String, input_hint: String = "G") -> void:
	_locked = true
	_set_content(title, body, input_hint, Catalog.ICON_GATE_LOCKED)
	visible = true


func set_active(title: String, body: String, input_hint: String = "G") -> void:
	_locked = false
	_set_content(title, body, input_hint, Catalog.ICON_GATE_OPEN)
	visible = true


func _apply_assets() -> void:
	if header_patch != null:
		if not Styles.configure_nine_patch(header_patch, Catalog.prompt_header(), Vector4i(18, 12, 18, 12)):
			header_patch.self_modulate = Palette.PANEL
	if body_patch != null:
		if not Styles.configure_nine_patch(body_patch, Catalog.prompt_body(), Vector4i(18, 18, 18, 18)):
			body_patch.self_modulate = Palette.PANEL_DEEP
	if badge_rect != null:
		var badge_path: String = Catalog.prompt_key_badge()
		var badge_texture: Texture2D = Styles.load_texture(badge_path)
		badge_rect.texture = badge_texture
		badge_rect.visible = badge_texture != null
		badge_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Styles.apply_label(title_label, Palette.GOLD_TEXT, 15, true)
	Styles.apply_label(body_label, Palette.BODY_TEXT, 14)
	Styles.apply_label(key_label, Palette.BG_DARK, 15, true)


func _set_content(title: String, body: String, input_hint: String, icon_path: String) -> void:
	if title_label != null:
		title_label.text = title.to_upper()
		title_label.add_theme_color_override("font_color", Palette.DANGER if _locked else Palette.GOLD_TEXT)
	if body_label != null:
		body_label.text = body
	if key_label != null:
		key_label.text = input_hint.to_upper()
	var texture: Texture2D = Styles.load_texture(icon_path)
	if icon_rect != null:
		icon_rect.texture = texture
		icon_rect.visible = texture != null
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _resolve_action_hint() -> String:
	var prompt_service := get_node_or_null("/root/InputPromptService")
	if prompt_service != null and prompt_service.has_method("resolve_action_label"):
		return str(prompt_service.resolve_action_label(_action_name))
	return String(_action_name).to_upper().replace("_", " ")


func _on_device_family_changed(_device_family: StringName) -> void:
	if _action_name.is_empty() or key_label == null:
		return
	key_label.text = _resolve_action_hint()
