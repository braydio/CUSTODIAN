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
@onready var weapon_pressure_bar: ProgressBar = get_node_or_null("Root/TopLeftVitals/Margin/Content/WeaponPressureRow/WeaponPressureBar")
@onready var weapon_pressure_state_label: Label = get_node_or_null("Root/TopLeftVitals/Margin/Content/WeaponPressureRow/WeaponPressureStateLabel")
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
var _weapon_pressure_state: StringName = &"normal"
var _weapon_icon_tween: Tween = null
var _weapon_flash_tween: Tween = null
var _critical_pulse_timer := 0.0
var _stamina_reject_timer := 0.0
var _feedback_operator: Node = null
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


func _process(delta: float) -> void:
	_refresh_operator_status()
	_stamina_reject_timer = maxf(0.0, _stamina_reject_timer - delta)
	if _weapon_pressure_state == &"critical":
		_critical_pulse_timer -= delta
		if _critical_pulse_timer <= 0.0:
			_critical_pulse_timer = 0.55
			_pulse_weapon_icon(0.18, Palette.DANGER)
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


func set_stamina_status(text: String, percent: float, show_percent: bool = true) -> void:
	var safe_percent := clampf(percent, 0.0, 100.0)
	var stamina_color := Palette.DANGER if _stamina_reject_timer > 0.0 else Palette.EVRFOREST_PALE_GREEN
	if stamina_label != null:
		stamina_label.text = "STAMINA %s" % text
		if show_percent:
			stamina_label.text += " %d%%" % int(round(safe_percent))
		stamina_label.add_theme_color_override("font_color", stamina_color)
	if stamina_bar != null:
		stamina_bar.max_value = 100.0
		stamina_bar.value = safe_percent
		stamina_bar.show_percentage = false
		stamina_bar.add_theme_stylebox_override("background", Styles.bar_background_style())
		stamina_bar.add_theme_stylebox_override("fill", Styles.bar_fill_style(stamina_color))
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
	var combined := "%s|%s" % [display_name, ammo_text]
	if combined != _last_weapon_status_text:
		if weapon_name_label != null:
			weapon_name_label.text = display_name
		if weapon_ammo_label != null:
			weapon_ammo_label.text = ammo_text
			if loaded <= 0 and magazine_size > 0:
				weapon_ammo_label.add_theme_color_override("font_color", Palette.GOLD_TEXT)
			else:
				weapon_ammo_label.add_theme_color_override("font_color", Palette.BODY_TEXT)
		_last_weapon_status_text = combined
	if weapon_icon != null and icon_texture != _last_weapon_icon:
		weapon_icon.texture = icon_texture
		weapon_icon.visible = icon_texture != null
		_last_weapon_icon = icon_texture


func consume_weapon_status(snapshot: Dictionary, icon_texture: Texture2D = null) -> void:
	set_weapon_status(
		str(snapshot.get("weapon_name", "UNARMED")),
		int(snapshot.get("loaded_ammo", 0)),
		int(snapshot.get("magazine_size", 0)),
		int(snapshot.get("reserve_ammo", 0)),
		icon_texture,
		bool(snapshot.get("reloading", false)),
		bool(snapshot.get("overheated", false))
	)
	_set_weapon_pressure(snapshot)


func _set_weapon_pressure(snapshot: Dictionary) -> void:
	var state: StringName = &"normal"
	var ratio := clampf(float(snapshot.get("overheat_ratio", 0.0)), 0.0, 1.0)
	var label := "HEAT"
	var color := Palette.BODY_TEXT
	if bool(snapshot.get("overheated", false)):
		state = &"overheated"
		ratio = clampf(float(snapshot.get("overheat_recovery_ratio", 0.0)), 0.0, 1.0)
		label = "VENT"
		color = Palette.DANGER
	elif bool(snapshot.get("reloading", false)):
		state = &"reloading"
		ratio = clampf(float(snapshot.get("reload_ratio", 0.0)), 0.0, 1.0)
		label = "LOAD"
		color = Palette.GOLD_TEXT
	elif int(snapshot.get("magazine_size", 0)) > 0 and int(snapshot.get("loaded_ammo", 0)) <= 0 and int(snapshot.get("reserve_ammo", 0)) <= 0:
		state = &"dry"
		ratio = 0.0
		label = "DRY"
		color = Palette.MUTED_TEXT
	elif str(snapshot.get("heat_band", "normal")) == "critical" or int(snapshot.get("shots_to_overheat", 99)) in [1, 2]:
		state = &"critical"
		label = "CRIT"
		color = Palette.DANGER
	elif str(snapshot.get("heat_band", "normal")) == "hot" or float(snapshot.get("heat", 0.0)) >= float(snapshot.get("heat_warn_threshold", INF)):
		state = &"hot"
		label = "HOT"
		color = Palette.GOLD_TEXT
	if weapon_pressure_bar != null:
		weapon_pressure_bar.max_value = 100.0
		weapon_pressure_bar.value = ratio * 100.0
		weapon_pressure_bar.show_percentage = false
		weapon_pressure_bar.add_theme_stylebox_override("background", Styles.bar_background_style())
		weapon_pressure_bar.add_theme_stylebox_override("fill", Styles.bar_fill_style(color))
	if weapon_pressure_state_label != null:
		weapon_pressure_state_label.text = label
		weapon_pressure_state_label.add_theme_color_override("font_color", color)
	if state != _weapon_pressure_state:
		var previous := _weapon_pressure_state
		_weapon_pressure_state = state
		_on_weapon_pressure_transition(previous, state)


func _on_weapon_pressure_transition(_previous: StringName, current: StringName) -> void:
	if current == &"hot":
		_pulse_weapon_icon(0.28, Palette.GOLD_TEXT)
	elif current == &"critical":
		_critical_pulse_timer = 0.0


func _ensure_weapon_feedback_connection(operator_ref: Node) -> void:
	if operator_ref == _feedback_operator:
		return
	if _feedback_operator != null and is_instance_valid(_feedback_operator) and _feedback_operator.has_signal("weapon_feedback_event"):
		var old_callable := Callable(self, "_on_weapon_feedback_event")
		if _feedback_operator.is_connected("weapon_feedback_event", old_callable):
			_feedback_operator.disconnect("weapon_feedback_event", old_callable)
	if _feedback_operator != null and is_instance_valid(_feedback_operator) and _feedback_operator.has_signal("dodge_charge_cancelled"):
		var old_dodge_callable := Callable(self, "_on_dodge_charge_cancelled")
		if _feedback_operator.is_connected("dodge_charge_cancelled", old_dodge_callable):
			_feedback_operator.disconnect("dodge_charge_cancelled", old_dodge_callable)
	_feedback_operator = operator_ref
	if _feedback_operator != null and _feedback_operator.has_signal("weapon_feedback_event"):
		_feedback_operator.connect("weapon_feedback_event", Callable(self, "_on_weapon_feedback_event"))
	if _feedback_operator != null and _feedback_operator.has_signal("dodge_charge_cancelled"):
		_feedback_operator.connect("dodge_charge_cancelled", Callable(self, "_on_dodge_charge_cancelled"))


func _on_dodge_charge_cancelled(reason: StringName) -> void:
	if reason != &"insufficient_stamina":
		return
	_stamina_reject_timer = 0.18
	if stamina_label != null:
		var tween := create_tween()
		tween.tween_property(stamina_label, "scale", Vector2(1.03, 1.03), 0.06)
		tween.tween_property(stamina_label, "scale", Vector2.ONE, 0.10)


func _on_weapon_feedback_event(event_id: StringName, snapshot: Dictionary) -> void:
	if not bool(snapshot.get("active_weapon", true)):
		return
	match event_id:
		&"dry_fire":
			_kick_weapon_icon()
		&"reload_completed":
			_flash_weapon_row(Palette.GOLD_TEXT, 0.20)
		&"overheated":
			_flash_weapon_row(Palette.DANGER, 0.12)
		&"overheat_recovered":
			_flash_weapon_row(Palette.EVRFOREST_PALE_GREEN, 0.25)


func _pulse_weapon_icon(duration: float, color: Color) -> void:
	if weapon_icon == null:
		return
	if _weapon_icon_tween != null and _weapon_icon_tween.is_valid():
		_weapon_icon_tween.kill()
	weapon_icon.pivot_offset = weapon_icon.size * 0.5
	weapon_icon.scale = Vector2.ONE
	weapon_icon.modulate = Color.WHITE
	_weapon_icon_tween = create_tween()
	_weapon_icon_tween.tween_property(weapon_icon, "scale", Vector2(1.08, 1.08), duration * 0.5)
	_weapon_icon_tween.parallel().tween_property(weapon_icon, "modulate", color, duration * 0.5)
	_weapon_icon_tween.tween_property(weapon_icon, "scale", Vector2.ONE, duration * 0.5)
	_weapon_icon_tween.parallel().tween_property(weapon_icon, "modulate", Color.WHITE, duration * 0.5)


func _kick_weapon_icon() -> void:
	if weapon_icon == null:
		return
	if _weapon_icon_tween != null and _weapon_icon_tween.is_valid():
		_weapon_icon_tween.kill()
	var origin := weapon_icon.position
	_weapon_icon_tween = create_tween()
	_weapon_icon_tween.tween_property(weapon_icon, "position", origin + Vector2(2.0, 0.0), 0.04)
	_weapon_icon_tween.tween_property(weapon_icon, "position", origin + Vector2(-2.0, 0.0), 0.04)
	_weapon_icon_tween.tween_property(weapon_icon, "position", origin, 0.04)


func _flash_weapon_row(color: Color, duration: float) -> void:
	if weapon_icon_frame == null:
		return
	if _weapon_flash_tween != null and _weapon_flash_tween.is_valid():
		_weapon_flash_tween.kill()
	weapon_icon_frame.modulate = color
	_weapon_flash_tween = create_tween()
	_weapon_flash_tween.tween_property(weapon_icon_frame, "modulate", Color.WHITE, duration)


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
	_ensure_weapon_feedback_connection(operator_ref)
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
		var show_stamina_percent := true
		if bool(sprint_status.get("sprint_exhausted", false)):
			mode = "RECOVER"
		if operator_ref.has_method("get_dodge_charge_status"):
			var dodge_charge_status: Dictionary = operator_ref.call("get_dodge_charge_status")
			if bool(dodge_charge_status.get("active", false)):
				if bool(dodge_charge_status.get("ready", false)):
					mode = "DODGE READY"
					show_stamina_percent = false
				else:
					mode = "DODGE"
		set_stamina_status(mode, stamina_pct, show_stamina_percent)
	if operator_ref.has_method("get_weapon_status"):
		var weapon_status: Dictionary = operator_ref.call("get_weapon_status")
		var icon_texture: Texture2D = null
		if operator_ref.has_method("get_active_weapon_icon_texture"):
			var icon_variant: Variant = operator_ref.call("get_active_weapon_icon_texture")
			if icon_variant is Texture2D:
				icon_texture = icon_variant as Texture2D
		consume_weapon_status(weapon_status, icon_texture)


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
