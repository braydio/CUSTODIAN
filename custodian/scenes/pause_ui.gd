extends CanvasLayer

var is_paused := false
var selected_index := 0
var menu_items: Array = []

@onready var panel = get_node_or_null("PausePanel")
@onready var title_label = get_node_or_null("PausePanel/Title")
@onready var menu_container = get_node_or_null("PausePanel/MenuContainer")

# Signals available for external systems
# signal time_scale_changed(scale: float)
# signal sector_toggled(sector_name: String)
# signal repair_requested(sector_name: String)

func _ready():
	# Pause UI must keep processing while the tree is paused so it can unpause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_paused = false
	if panel:
		panel.visible = false

func _process(_delta):
	var ui = get_node_or_null("/root/GameRoot/UI")
	var terminal_open := false
	if ui and ui.has_method("is_terminal_open"):
		terminal_open = bool(ui.is_terminal_open())
	if terminal_open:
		return

	# Check for pause toggle
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
		# Prevent the same keypress (Space = ui_accept) from also activating menu actions.
		return
	if is_paused and Input.is_action_just_pressed("time_shift"):
		cycle_time_scale()
		build_menu()
		update_menu_display()
	
	# Handle menu navigation when paused
	if is_paused:
		handle_input()

func toggle_pause():
	is_paused = !is_paused
	if panel == null:
		push_warning("PausePanel missing in scene tree.")
		is_paused = false
		return
	get_tree().paused = is_paused
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.paused = is_paused
	panel.visible = is_paused
	if is_paused:
		build_menu()
		selected_index = 0
		update_menu_display()

func handle_input():
	if menu_items.is_empty():
		return
	if Input.is_action_just_pressed("ui_up"):
		selected_index = max(0, selected_index - 1)
		update_menu_display()
	elif Input.is_action_just_pressed("ui_down"):
		selected_index = min(menu_items.size() - 1, selected_index + 1)
		update_menu_display()
	elif Input.is_action_just_pressed("ui_accept") and not Input.is_action_just_pressed("pause"):
		execute_selected()

func build_menu():
	menu_items.clear()
	if menu_container == null:
		return
	
	# Clear existing labels
	for child in menu_container.get_children():
		child.queue_free()
	
	# Get simulation for time scale
	var current_scale = Engine.time_scale
	
	# Time scale options
	menu_items.append({
		"label": "TIME SCALE: %dx" % current_scale,
		"type": "time_scale",
		"action": "cycle_time"
	})
	
	# Get sectors
	var sectors = get_sectors()
	for sector in sectors:
		var power_state = "ON" if sector.powered else "OFF"
		menu_items.append({
			"label": "%s POWER: %s" % [sector.sector_name, power_state],
			"type": "toggle_power",
			"sector": sector.sector_name
		})
		menu_items.append({
			"label": "  REPAIR %s (25 power)" % sector.sector_name,
			"type": "repair",
			"sector": sector.sector_name
		})
	
	# Resume
	menu_items.append({
		"label": "RESUME",
		"type": "resume"
	})
	
	# Create labels
	for item in menu_items:
		var label = Label.new()
		label.text = "  " + item.label
		menu_container.add_child(label)

func get_sectors():
	var world = get_node_or_null("/root/GameRoot/World/Sectors")
	if world:
		# Filter to only include nodes with 'powered' property (actual sectors)
		var all_children = world.get_children()
		var sectors = []
		for child in all_children:
			if child.has_method("toggle_power"):
				sectors.append(child)
		return sectors
	return []

func update_menu_display():
	if menu_container == null:
		return
	var labels = menu_container.get_children()
	if labels.is_empty() or menu_items.is_empty():
		selected_index = 0
		return
	selected_index = clamp(selected_index, 0, min(labels.size(), menu_items.size()) - 1)
	for i in range(labels.size()):
		if i >= menu_items.size():
			labels[i].text = "  "
			continue
		if i == selected_index:
			labels[i].add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			labels[i].text = "> " + menu_items[i].label
		else:
			labels[i].remove_theme_color_override("font_color")
			labels[i].text = "  " + menu_items[i].label

func execute_selected():
	if menu_items.is_empty():
		return
	selected_index = clamp(selected_index, 0, menu_items.size() - 1)
	var item = menu_items[selected_index]
	var type = item.type
	
	match type:
		"time_scale":
			cycle_time_scale()
		"toggle_power":
			toggle_sector_power(item.sector)
		"repair":
			request_repair(item.sector)
		"resume":
			toggle_pause()
	
	build_menu()
	selected_index = clamp(selected_index, 0, max(0, menu_items.size() - 1))
	update_menu_display()

func cycle_time_scale():
	var scales = [1.0, 2.0, 4.0, 0.5]
	var current = Engine.time_scale
	var idx = scales.find(current)
	var new_scale = scales[(idx + 1) % scales.size()]
	Engine.time_scale = new_scale
	print("Time scale: ", new_scale)

func toggle_sector_power(sector_name: String):
	var power = get_node_or_null("/root/GameRoot/Power")
	if power:
		power.toggle_sector_power(sector_name)
		print("Toggled power for: ", sector_name)

func request_repair(sector_name: String):
	var power = get_node_or_null("/root/GameRoot/Power")
	if power:
		if power.total_power >= 25:
			power.total_power -= 25
			var sectors = get_sectors()
			for sector in sectors:
				if sector.sector_name == sector_name:
					sector.heal(50.0)
					print("Repaired sector: ", sector_name)
		else:
			print("Not enough power to repair!")
