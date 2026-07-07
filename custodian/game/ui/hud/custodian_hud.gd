class_name CustodianHUD
extends CanvasLayer

const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")
const Styles := preload("res://game/ui/theme/black_reliquary_styles.gd")
const InventoryAssets := preload("res://game/ui/inventory/inventory_asset_catalog.gd")

@onready var health_label: Label = get_node_or_null("Root/TopLeftVitals/Margin/Content/HealthLabel")
@onready var health_bar: ProgressBar = get_node_or_null("Root/TopLeftVitals/Margin/Content/HealthBar")
@onready var stamina_label: Label = get_node_or_null("Root/TopLeftVitals/Margin/Content/StaminaLabel")
@onready var stamina_bar: ProgressBar = get_node_or_null("Root/TopLeftVitals/Margin/Content/StaminaBar")
@onready var weapon_icon_frame: PanelContainer = get_node_or_null("Root/TopLeftVitals/Margin/Content/WeaponStatusRow/WeaponIconFrame")
@onready var weapon_icon: TextureRect = get_node_or_null("Root/TopLeftVitals/Margin/Content/WeaponStatusRow/WeaponIconFrame/WeaponIcon")
@onready var weapon_name_label: Label = get_node_or_null("Root/TopLeftVitals/Margin/Content/WeaponStatusRow/WeaponText/WeaponNameLabel")
@onready var weapon_ammo_label: Label = get_node_or_null("Root/TopLeftVitals/Margin/Content/WeaponStatusRow/WeaponText/WeaponAmmoLabel")
@onready var loadout_primary_icon: TextureRect = get_node_or_null("Root/TopLeftLoadout/Margin/Content/PrimaryRow/IconFrame/Icon")
@onready var loadout_primary_name: Label = get_node_or_null("Root/TopLeftLoadout/Margin/Content/PrimaryRow/Text/Name")
@onready var loadout_primary_status: Label = get_node_or_null("Root/TopLeftLoadout/Margin/Content/PrimaryRow/Text/Status")
@onready var loadout_secondary_icon: TextureRect = get_node_or_null("Root/TopLeftLoadout/Margin/Content/SecondaryRow/IconFrame/Icon")
@onready var loadout_secondary_name: Label = get_node_or_null("Root/TopLeftLoadout/Margin/Content/SecondaryRow/Text/Name")
@onready var loadout_secondary_status: Label = get_node_or_null("Root/TopLeftLoadout/Margin/Content/SecondaryRow/Text/Status")
@onready var minimap_frame: Node = get_node_or_null("Root/TopRightPanel/Margin/BlackReliquaryMinimapFrame")
@onready var prompt: Node = get_node_or_null("Root/BottomLeftPrompt/BlackReliquaryPrompt")
@onready var debug_overlay: Panel = get_node_or_null("Root/DebugOverlay")
@onready var debug_label: Label = get_node_or_null("Root/DebugOverlay/Margin/DebugLabel")

var _health_current := 100
var _health_max := 100
var _last_weapon_status_text := ""
var _last_weapon_icon: Texture2D = null
var _last_primary_loadout_text := ""
var _last_secondary_loadout_text := ""
var _last_prompt_frame := -1
var _context_active := true
var _externally_suppressed := false
var _inventory_manager: Node = null


func _ready() -> void:
	add_to_group("custodian_hud")
	add_to_group("gameplay_overlay")
	_apply_theme()
	set_health(100, 100)
	set_stamina_status("READY", 100.0)
	set_weapon_status("CARBINE", 24, 24, 48, null, false, false)
	_refresh_loadout_section()
	set_location("FIELD OPERATIONS")
	set_phase("FREE ROAM PREP")
	set_objective("Open the main gate")
	set_key_item_status(false)
	set_main_gate_status(false, true)
	set_return_mooring_status(true, true)
	set_debug_overlay_visible(false)
	hide_interaction()


func _process(_delta: float) -> void:
	_refresh_operator_status()
	if prompt != null and visible and _last_prompt_frame >= 0 and Engine.get_process_frames() - _last_prompt_frame > 2:
		hide_interaction()


func set_health(current: int, max_value: int) -> void:
	_health_current = max(0, current)
	_health_max = max(1, max_value)
	var ratio := float(_health_current) / float(_health_max)
	if health_label != null:
		health_label.text = "HEALTH %d/%d" % [_health_current, _health_max]
		if ratio <= 0.3:
			health_label.add_theme_color_override("font_color", Palette.DANGER)
		elif ratio <= 0.6:
			health_label.add_theme_color_override("font_color", Palette.GOLD_TEXT)
		else:
			health_label.add_theme_color_override("font_color", Palette.BODY_TEXT)
	if health_bar != null:
		health_bar.max_value = 100.0
		health_bar.value = clampf(ratio * 100.0, 0.0, 100.0)
		health_bar.show_percentage = false
		health_bar.add_theme_stylebox_override("background", Styles.bar_background_style())
		health_bar.add_theme_stylebox_override("fill", Styles.bar_fill_style(Palette.DANGER))
	_forward_inventory_status("set_health", [current, max_value])


func set_stamina_status(text: String, percent: float) -> void:
	var safe_percent := clampf(percent, 0.0, 100.0)
	if stamina_label != null:
		stamina_label.text = "STAMINA %s %d%%" % [text, int(round(safe_percent))]
		stamina_label.add_theme_color_override("font_color", Palette.EVRFOREST_PALE_GREEN)
	if stamina_bar != null:
		stamina_bar.max_value = 100.0
		stamina_bar.value = safe_percent
		stamina_bar.show_percentage = false
		stamina_bar.add_theme_stylebox_override("background", Styles.bar_background_style())
		stamina_bar.add_theme_stylebox_override("fill", Styles.bar_fill_style(Palette.EVRFOREST_PALE_GREEN))
	_forward_inventory_status("set_stamina_status", [text, safe_percent])


func set_weapon_status(
	weapon_name: String,
	loaded: int,
	magazine_size: int,
	reserve: int,
	icon_texture: Texture2D = null,
	reloading: bool = false,
	overheated: bool = false
) -> void:
	var display_name := weapon_name.strip_edges().to_upper()
	if display_name.is_empty():
		display_name = "UNARMED"
	display_name = _fit_hud_text(display_name, 18)
	var ammo_text := "MELEE READY"
	if magazine_size > 0:
		ammo_text = "MAG %d/%d  RES %d" % [maxi(0, loaded), maxi(1, magazine_size), maxi(0, reserve)]
		if reloading:
			ammo_text = "RELOADING  %d/%d" % [maxi(0, loaded), maxi(1, magazine_size)]
		elif overheated:
			ammo_text = "OVERHEATED  %d/%d" % [maxi(0, loaded), maxi(1, magazine_size)]
	var combined := "%s|%s" % [display_name, ammo_text]
	if combined != _last_weapon_status_text:
		if weapon_name_label != null:
			weapon_name_label.text = display_name
		if weapon_ammo_label != null:
			weapon_ammo_label.text = ammo_text
			if overheated:
				weapon_ammo_label.add_theme_color_override("font_color", Palette.DANGER)
			elif reloading or loaded <= 0 and magazine_size > 0:
				weapon_ammo_label.add_theme_color_override("font_color", Palette.GOLD_TEXT)
			else:
				weapon_ammo_label.add_theme_color_override("font_color", Palette.BODY_TEXT)
		_last_weapon_status_text = combined
	if weapon_icon != null and icon_texture != _last_weapon_icon:
		weapon_icon.texture = icon_texture
		weapon_icon.visible = icon_texture != null
		_last_weapon_icon = icon_texture


func set_location(text: String) -> void:
	_forward_inventory_status("set_location", [text])


func set_phase(text: String) -> void:
	_forward_inventory_status("set_phase", [text])


func set_objective(text: String) -> void:
	_forward_inventory_status("set_objective", [text])


func show_interaction(title: String, body: String, input_hint: String = "G", icon_path: String = "") -> void:
	_last_prompt_frame = Engine.get_process_frames()
	if prompt != null:
		prompt.call("show_prompt", title, body, input_hint, icon_path)


func hide_interaction() -> void:
	_last_prompt_frame = -1
	if prompt != null:
		prompt.call("hide_prompt")


func set_key_item_status(has_key: bool, item_name: String = "Sundered Gate Key") -> void:
	_forward_inventory_status("set_key_item_status", [has_key, item_name])


func set_main_gate_status(open: bool, locked: bool) -> void:
	_forward_inventory_status("set_main_gate_status", [open, locked])


func set_return_mooring_status(active: bool, attuned: bool) -> void:
	_forward_inventory_status("set_return_mooring_status", [active, attuned])


func set_status_line(slot: String, icon_path: String, text: String, color: Color = Palette.BODY_TEXT) -> void:
	_forward_inventory_status("set_status_line", [slot, icon_path, text, color])


func set_minimap_visible(p_visible: bool) -> void:
	if minimap_frame != null:
		(minimap_frame as CanvasItem).visible = p_visible


func set_context_active(active: bool) -> void:
	_context_active = active
	if not active:
		hide_interaction()
	_apply_effective_visibility()


func set_external_overlay_hidden(hidden: bool) -> void:
	_externally_suppressed = hidden
	_apply_effective_visibility()


func is_context_active() -> bool:
	return _context_active


func set_debug_overlay_visible(p_visible: bool) -> void:
	if debug_overlay != null:
		debug_overlay.visible = p_visible


func set_debug_text(text: String) -> void:
	if debug_label != null:
		debug_label.text = text


func _apply_theme() -> void:
	for label in [health_label, stamina_label, weapon_name_label, weapon_ammo_label, debug_label]:
		Styles.apply_label(label, Palette.BODY_TEXT, 14)
	Styles.apply_label(health_label, Palette.BODY_TEXT, 13, true)
	Styles.apply_label(stamina_label, Palette.EVRFOREST_PALE_GREEN, 12, true)
	Styles.apply_label(weapon_name_label, Palette.GOLD_TEXT, 11, true)
	Styles.apply_label(weapon_ammo_label, Palette.BODY_TEXT, 11, true)
	Styles.apply_label(loadout_primary_name, Palette.GOLD_TEXT, 11, true)
	Styles.apply_label(loadout_primary_status, Palette.BODY_TEXT, 10, true)
	Styles.apply_label(loadout_secondary_name, Palette.BODY_TEXT, 10, true)
	Styles.apply_label(loadout_secondary_status, Palette.BODY_TEXT, 9, true)
	Styles.apply_label(debug_label, Palette.BODY_TEXT, 14)
	if weapon_icon_frame != null:
		weapon_icon_frame.add_theme_stylebox_override("panel", Styles.panel_style(true))
	if weapon_icon != null:
		weapon_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if loadout_primary_icon != null:
		loadout_primary_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if loadout_secondary_icon != null:
		loadout_secondary_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if debug_overlay != null:
		debug_overlay.add_theme_stylebox_override("panel", Styles.panel_style(true))


func _refresh_operator_status() -> void:
	var operator_ref := get_node_or_null("/root/GameRoot/World/Operator")
	if operator_ref == null:
		return
	var current := _health_current
	var max_value := _health_max
	if operator_ref.has_method("get_health"):
		current = int(round(float(operator_ref.call("get_health"))))
	elif "health" in operator_ref:
		current = int(round(float(operator_ref.get("health"))))
	if operator_ref.has_method("get_max_health"):
		max_value = int(round(float(operator_ref.call("get_max_health"))))
	elif "max_health" in operator_ref:
		max_value = int(round(float(operator_ref.get("max_health"))))
	if current != _health_current or max_value != _health_max:
		set_health(current, max_value)
	if operator_ref.has_method("get_sprint_status"):
		var sprint_status: Dictionary = operator_ref.call("get_sprint_status")
		var stamina_max: float = max(1.0, float(sprint_status.get("stamina_max", 1.0)))
		var stamina_pct: float = clampf(float(sprint_status.get("stamina", 0.0)) / stamina_max * 100.0, 0.0, 100.0)
		var mode: String = "SPRINT" if bool(sprint_status.get("is_sprinting", false)) else "READY"
		if bool(sprint_status.get("sprint_exhausted", false)):
			mode = "RECOVER"
		set_stamina_status(mode, stamina_pct)
	if operator_ref.has_method("get_weapon_status"):
		var weapon_status: Dictionary = operator_ref.call("get_weapon_status")
		var icon_texture: Texture2D = null
		if operator_ref.has_method("get_active_weapon_icon_texture"):
			var icon_variant: Variant = operator_ref.call("get_active_weapon_icon_texture")
			if icon_variant is Texture2D:
				icon_texture = icon_variant as Texture2D
		set_weapon_status(
			str(weapon_status.get("weapon_name", "UNARMED")),
			int(weapon_status.get("loaded_ammo", 0)),
			int(weapon_status.get("magazine_size", 0)),
			int(weapon_status.get("reserve_ammo", 0)),
			icon_texture,
			bool(weapon_status.get("reloading", false)),
			bool(weapon_status.get("overheated", false))
		)


func _refresh_loadout_section(operator_ref: Node = null) -> void:
	if loadout_primary_name == null or loadout_primary_status == null or loadout_secondary_name == null or loadout_secondary_status == null:
		return
	if operator_ref == null:
		operator_ref = get_node_or_null("/root/GameRoot/World/Operator")
	if operator_ref == null:
		return
	if _inventory_manager == null:
		_inventory_manager = get_node_or_null("/root/InventoryManager")

	var weapon_status: Dictionary = {}
	if operator_ref.has_method("get_weapon_status"):
		weapon_status = operator_ref.call("get_weapon_status")
	var primary_name := str(weapon_status.get("weapon_name", "UNARMED")).to_upper()
	var primary_ammo := "MELEE READY"
	if int(weapon_status.get("magazine_size", 0)) > 0:
		primary_ammo = "MAG %d/%d  RES %d" % [
			maxi(0, int(weapon_status.get("loaded_ammo", 0))),
			maxi(1, int(weapon_status.get("magazine_size", 0))),
			maxi(0, int(weapon_status.get("reserve_ammo", 0))),
		]
		if bool(weapon_status.get("reloading", false)):
			primary_ammo = "RELOADING"
		elif bool(weapon_status.get("overheated", false)):
			primary_ammo = "OVERHEATED"
	var primary_key := "%s|%s" % [primary_name, primary_ammo]
	if primary_key != _last_primary_loadout_text:
		loadout_primary_name.text = _fit_hud_text(primary_name, 18)
		loadout_primary_status.text = primary_ammo
		_last_primary_loadout_text = primary_key
	if loadout_primary_icon != null and weapon_status.has("weapon_name"):
		if operator_ref.has_method("get_active_weapon_icon_texture"):
			var primary_icon_variant: Variant = operator_ref.call("get_active_weapon_icon_texture")
			loadout_primary_icon.texture = primary_icon_variant if primary_icon_variant is Texture2D else null

	var sidearm_equipped := false
	var sidearm_available := false
	if _inventory_manager != null and _inventory_manager.has_method("get_equipped"):
		var equipped_id := str(_inventory_manager.call("get_equipped", &"sidearm"))
		sidearm_equipped = equipped_id == "p9_sidearm"
		sidearm_available = sidearm_equipped or bool(_inventory_manager.call("has_item", &"p9_sidearm", 1))
	var secondary_name := "P-9 FIELD SIDEARM"
	var secondary_status := "EMPTY"
	var secondary_icon: Texture2D = InventoryAssets.item_hud_icon(&"p9_sidearm") if sidearm_available else null
	if sidearm_equipped:
		secondary_status = "EQUIPPED"
	elif sidearm_available:
		secondary_status = "RECOVERED"
	else:
		secondary_name = "SIDEARM SLOT"
		secondary_status = "UNFILLED"
	var secondary_key := "%s|%s|%s" % [secondary_name, secondary_status, str(sidearm_equipped)]
	if secondary_key != _last_secondary_loadout_text:
		loadout_secondary_name.text = _fit_hud_text(secondary_name, 18)
		loadout_secondary_status.text = secondary_status
		_last_secondary_loadout_text = secondary_key
	if loadout_secondary_icon != null:
		loadout_secondary_icon.texture = secondary_icon
		loadout_secondary_icon.visible = secondary_icon != null


func _fit_hud_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(1, max_chars - 1)) + "."


func _forward_inventory_status(method_name: String, args: Array) -> void:
	var inventory_ui := _get_inventory_ui()
	if inventory_ui != null and inventory_ui.has_method(method_name):
		inventory_ui.callv(method_name, args)


func _get_inventory_ui() -> Node:
	var ui := get_node_or_null("/root/GameRoot/UI/InventoryUI")
	if ui != null:
		return ui
	var group_matches := get_tree().get_nodes_in_group("inventory_ui")
	for node in group_matches:
		if node is Node and is_instance_valid(node):
			return node
	return null


func _apply_effective_visibility() -> void:
	visible = _context_active and not _externally_suppressed
