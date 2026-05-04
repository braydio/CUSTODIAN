extends CanvasLayer

var is_paused := false
var selected_index := 0
var menu_items: Array[Dictionary] = []

@onready var panel: Control = get_node_or_null("PausePanel")
@onready var title_label: Label = get_node_or_null("PausePanel/Title")
@onready var menu_container: Control = get_node_or_null("PausePanel/MenuContainer")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_paused = false

	if panel:
		panel.visible = false

	if title_label:
		title_label.text = "PAUSED"


func _process(_delta: float) -> void:
	if _is_terminal_open():
		return

	if Input.is_action_just_pressed("pause"):
		toggle_pause()
		return

	if not is_paused:
		return

	if Input.is_action_just_pressed("time_shift"):
		cycle_time_scale()
		build_menu()
		update_menu_display()
		return

	handle_input()


func toggle_pause() -> void:
	is_paused = not is_paused

	if panel == null:
		push_warning("PausePanel missing in scene tree.")
		is_paused = false
		get_tree().paused = false
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
	else:
		menu_items.clear()
		selected_index = 0
		_clear_menu_labels()


func handle_input() -> void:
	if menu_items.is_empty():
		return

	if Input.is_action_just_pressed("ui_up"):
		selected_index = max(0, selected_index - 1)
		update_menu_display()
		return

	if Input.is_action_just_pressed("ui_down"):
		selected_index = min(menu_items.size() - 1, selected_index + 1)
		update_menu_display()
		return

	if Input.is_action_just_pressed("ui_accept") and not Input.is_action_just_pressed("pause"):
		execute_selected()


func build_menu() -> void:
	menu_items.clear()

	if menu_container == null:
		return

	_clear_menu_labels()

	var current_scale := Engine.time_scale

	menu_items.append({
		"label": "TIME SCALE: %sx" % _format_time_scale(current_scale),
		"type": "time_scale",
	})

	menu_items.append({
		"label": "OPEN COMMAND TERMINAL FOR POWER / REPAIR / DEPLOYMENT",
		"type": "hint",
	})

	menu_items.append({
		"label": "RESUME",
		"type": "resume",
	})

	for item in menu_items:
		var label := Label.new()
		label.text = "  " + str(item.get("label", ""))
		menu_container.add_child(label)


func _clear_menu_labels() -> void:
	if menu_container == null:
		return

	for child in menu_container.get_children():
		child.queue_free()


func update_menu_display() -> void:
	if menu_container == null:
		return

	var labels := menu_container.get_children()

	if labels.is_empty() or menu_items.is_empty():
		selected_index = 0
		return

	selected_index = clamp(selected_index, 0, min(labels.size(), menu_items.size()) - 1)

	for i in range(labels.size()):
		if not (labels[i] is Label):
			continue

		var label := labels[i] as Label

		if i >= menu_items.size():
			label.text = "  "
			continue

		var item_label := str(menu_items[i].get("label", ""))
		var item_type := str(menu_items[i].get("type", ""))

		if item_type == "hint":
			label.add_theme_color_override("font_color", Color(0.55, 0.7, 0.8))
			label.text = "  " + item_label
			continue

		if i == selected_index:
			label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			label.text = "> " + item_label
		else:
			label.remove_theme_color_override("font_color")
			label.text = "  " + item_label


func execute_selected() -> void:
	if menu_items.is_empty():
		return

	selected_index = clamp(selected_index, 0, menu_items.size() - 1)

	var item: Dictionary = menu_items[selected_index]
	var item_type := str(item.get("type", ""))

	match item_type:
		"time_scale":
			cycle_time_scale()
		"resume":
			toggle_pause()
		"hint":
			pass

	build_menu()
	selected_index = clamp(selected_index, 0, max(0, menu_items.size() - 1))
	update_menu_display()


func cycle_time_scale() -> void:
	var scales := [1.0, 2.0, 4.0, 0.5]
	var current := Engine.time_scale
	var idx := scales.find(current)

	if idx < 0:
		idx = 0

	var new_scale: float = scales[(idx + 1) % scales.size()]
	Engine.time_scale = new_scale
	print("Time scale: ", new_scale)


func _format_time_scale(time_scale: float) -> String:
	if is_equal_approx(time_scale, round(time_scale)):
		return str(int(round(time_scale)))
	return "%.1f" % time_scale


func _is_terminal_open() -> bool:
	var ui = get_node_or_null("/root/GameRoot/UI")
	if ui and ui.has_method("is_terminal_open"):
		return bool(ui.is_terminal_open())
	return false
