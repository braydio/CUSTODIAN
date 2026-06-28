extends Node

const COND_FIRST_USE_EVER := 4

var _layout_connected := false
var _imgui_available := false
var _active_tab := "World"


func _ready() -> void:
	_try_connect_imgui()


func _process(_delta: float) -> void:
	if not _layout_connected:
		_try_connect_imgui()


func _try_connect_imgui() -> void:
	var imgui := _imgui()
	if imgui == null:
		return
	if not imgui.has_signal("imgui_layout"):
		return
	if not imgui.imgui_layout.is_connected(_on_imgui_layout):
		imgui.imgui_layout.connect(_on_imgui_layout)
	_layout_connected = true
	_imgui_available = true


func _on_imgui_layout() -> void:
	var bus := _debug_bus()
	if bus == null or not bool(bus.get("enabled")):
		return

	var imgui := _imgui()
	if imgui == null:
		return

	if imgui.has_method("dockspace_over_main_viewport"):
		imgui.call("dockspace_over_main_viewport")
	if imgui.has_method("set_next_window_size"):
		imgui.call("set_next_window_size", 580.0, 420.0, COND_FIRST_USE_EVER)
	if not bool(imgui.call("begin", "CUSTODIAN Director Console")):
		imgui.call("end")
		return

	_draw_header(imgui, bus)
	if bool(bus.get("minimal_mode")):
		_draw_minimal(imgui, bus)
	else:
		_draw_tab_selector(imgui)
		if imgui.has_method("separator"):
			imgui.call("separator")
		match _active_tab:
			"World":
				_draw_world_tab(imgui, bus)
			"Sectors":
				_draw_sector_tab(imgui, bus)
			"Combat":
				_draw_combat_tab(imgui, bus)
			"Actors":
				_draw_actor_tab(imgui, bus)
			"Animation":
				_draw_animation_tab(imgui, bus)
			"Events":
				_draw_events_tab(imgui, bus)

	imgui.call("end")


func _draw_header(imgui: Node, bus: Node) -> void:
	imgui.call("text", "F3 toggle | Shift+F3 minimal | F4 overlays | F5 lock inspector")
	if not _imgui_available:
		imgui.call("text", "Dear ImGui unavailable; install/enable addons/dear-imgui-godot.")
	if imgui.has_method("separator"):
		imgui.call("separator")


func _draw_tab_selector(imgui: Node) -> void:
	var labels: Array[String] = ["World", "Sectors", "Combat", "Actors", "Animation", "Events"]
	for index in range(labels.size()):
		var label: String = labels[index]
		var button_label: String = "[%s]" % label if label == _active_tab else label
		if bool(imgui.call("button", button_label, 0.0, 0.0)):
			_active_tab = label
		if imgui.has_method("same_line") and index < labels.size() - 1:
			imgui.call("same_line")


func _draw_minimal(imgui: Node, bus: Node) -> void:
	var stats: Dictionary = bus.get("stats")
	for category in stats.keys():
		imgui.call("text", "[%s]" % str(category))
		var value = stats[category]
		if value is Dictionary:
			for key in (value as Dictionary).keys():
				imgui.call("text", "  %s: %s" % [str(key), str((value as Dictionary)[key])])
		else:
			imgui.call("text", "  %s" % str(value))


func _draw_world_tab(imgui: Node, bus: Node) -> void:
	var world: Dictionary = _category(bus, "WORLD", {})
	imgui.call("text", "Seed: %s" % str(world.get("seed", "unknown")))
	imgui.call("text", "Profile: %s" % str(world.get("profile", "unknown")))
	imgui.call("text", "Map Size: %s" % str(world.get("map_size", "unknown")))
	imgui.call("text", "Generation Mode: %s" % str(world.get("generation_mode", "unknown")))
	imgui.call("text", "Terrain Connectivity: %s" % str(world.get("terrain_connectivity", true)))
	imgui.call("text", "Terrain Fallback: %s" % str(world.get("terrain_fallback", false)))
	imgui.call("text", "Required Cells: %s" % str(world.get("required_cell_count", 0)))
	imgui.call("text", "Missing Required: %s" % str(world.get("missing_required_count", 0)))
	imgui.call("text", "Rescue Carved Cells: %s" % str(world.get("rescue_carved_cells", 0)))
	if bool(imgui.call("button", "Copy ProcGen Report", 0.0, 0.0)):
		DisplayServer.clipboard_set(JSON.stringify(world, "\t"))


func _draw_sector_tab(imgui: Node, bus: Node) -> void:
	var sectors: Array = _category(bus, "SECTORS", []) as Array
	imgui.call("text", "Sector | Threat | Enemies | Power | Defenses | Damage | Pathable")
	if imgui.has_method("separator"):
		imgui.call("separator")
	for sector_variant in sectors:
		if not (sector_variant is Dictionary):
			continue
		var sector := sector_variant as Dictionary
		imgui.call("text", "%s | %s | %s | %s | %s | %s%% | %s" % [
			str(sector.get("name", "?")),
			str(sector.get("threat", "?")),
			str(sector.get("enemy_count", 0)),
			str(sector.get("power", "?")),
			str(sector.get("defenses", "?")),
			str(sector.get("damage_pct", 0)),
			str(sector.get("pathable", false)),
		])


func _draw_combat_tab(imgui: Node, bus: Node) -> void:
	var combat: Dictionary = _category(bus, "COMBAT", {}) as Dictionary
	imgui.call("text", "Enemies Alive: %s" % str(combat.get("enemies_alive", 0)))
	imgui.call("text", "Projectiles: %s" % str(combat.get("projectiles", 0)))
	imgui.call("text", "Operator Heat: %.2f" % float(combat.get("operator_heat", 0.0)))
	imgui.call("text", "Operator Ammo: %s" % str(combat.get("operator_ammo", "")))

	var overrides: Dictionary = bus.get("debug_overrides")
	var slowmo := bool(overrides.get("slowmo", false))
	var next_slowmo := bool(imgui.call("checkbox", "Slow Motion Override", slowmo))
	if next_slowmo != slowmo:
		bus.call("set_debug_override", "slowmo", next_slowmo)


func _draw_actor_tab(imgui: Node, bus: Node) -> void:
	var actor: Dictionary = bus.get("selected_entity_snapshot")
	if actor.is_empty():
		imgui.call("text", "No actor selected.")
	else:
		for key in actor.keys():
			imgui.call("text", "%s: %s" % [str(key), str(actor[key])])

	if imgui.has_method("separator"):
		imgui.call("separator")
	imgui.call("text", "Recent actor summaries:")
	var actors: Array = _category(bus, "ACTORS", []) as Array
	for index in range(mini(actors.size(), 12)):
		imgui.call("text", str(actors[index]))


func _draw_animation_tab(imgui: Node, bus: Node) -> void:
	var actor: Dictionary = bus.get("selected_entity_snapshot")
	if actor.is_empty():
		imgui.call("text", "Select/lock an actor to inspect animation timing.")
		return
	imgui.call("text", "Actor: %s" % str(actor.get("node", "?")))
	var weapon: Dictionary = actor.get("weapon", {}) as Dictionary
	if not weapon.is_empty():
		imgui.call("text", "Weapon: %s" % str(weapon.get("weapon_name", "?")))
		imgui.call("text", "Ammo: %s/%s reserve %s" % [
			str(weapon.get("magazine_loaded", 0)),
			str(weapon.get("magazine_size", 0)),
			str(weapon.get("reserve_ammo", 0)),
		])
	imgui.call("text", "Animation frame stepping is deferred to actor-specific adapters.")


func _draw_events_tab(imgui: Node, bus: Node) -> void:
	var events: Array = bus.get("events")
	for index in range(events.size() - 1, maxi(-1, events.size() - 80), -1):
		imgui.call("text", str(events[index]))


func _category(bus: Node, category: String, fallback: Variant) -> Variant:
	var stats: Dictionary = bus.get("stats")
	return stats.get(category, fallback)


func _imgui() -> Node:
	return get_node_or_null("/root/ImGui")


func _debug_bus() -> Node:
	return get_node_or_null("/root/DebugBus")
