extends Control
class_name InventoryUI

signal closed()

@export var inventory: Inventory

@onready var grid_container: GridContainer = $Panel/MarginContainer/GridContainer
@onready var title_label: Label = $Panel/TitleBar/TitleLabel
@onready var close_button: Button = $Panel/TitleBar/CloseButton

const COLUMNS: int = 5

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Connect signals
	close_button.pressed.connect(_on_close_pressed)
	if inventory == null:
		inventory = get_node_or_null("Inventory") as Inventory
	_connect_inventory_signal()
	
	# Setup grid
	grid_container.columns = COLUMNS
	
	# Populate slots
	populate_slots()
	
	# Hide by default
	visible = false

func open(inv: Inventory = null):
	if inv:
		inventory = inv
		_connect_inventory_signal()
	else:
		# Load sample items for testing
		_load_sample_items()
	
	visible = true
	populate_slots()

func _load_sample_items():
	# Create inventory if it doesn't exist
	if not inventory:
		inventory = Inventory.new()
		# Connect signal after creating
		_connect_inventory_signal()
	
	# Avoid re-adding items
	if inventory.slots.size() >0 and inventory.slots[0].item != null:
		return
	
	var items = ItemFactory.load_all_items()
	for item in items:
		inventory.add_item(item, 3)

func close():
	visible = false
	closed.emit()

func populate_slots():
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	if not inventory:
		return
	
	# Create slots
	for i in range(inventory.max_slots):
		var slot_data = inventory.get_item_at(i)
		var slot = create_slot(slot_data)
		grid_container.add_child(slot)

func create_slot(slot_data: Dictionary) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Background
	var bg = TextureRect.new()
	bg.texture = load("res://content/ui/inventory/slot_empty.png")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(bg)
	slot.set_meta("bg", bg)
	
	# Item icon
	if slot_data.item:
		var icon = TextureRect.new()
		icon.texture = slot_data.item.icon if slot_data.item.icon else load("res://content/ui/inventory/icons/icon_placeholder.png")
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(icon)
		slot.set_meta("icon", icon)
		
		# Quantity label
		if slot_data.quantity > 1:
			var label = Label.new()
			label.text = str(slot_data.quantity)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_font_size_override("font_size", 12)
			slot.add_child(label)
	
	# Hover effect
	slot.gui_input.connect(_on_slot_input.bind(slot, slot_data))
	slot.mouse_entered.connect(_on_slot_hovered.bind(slot))
	slot.mouse_exited.connect(_on_slot_unhovered.bind(slot))
	
	return slot

func _on_slot_input(event: InputEvent, slot: Control, slot_data: Dictionary):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if slot_data.item:
				print("Clicked on: ", slot_data.item.display_name)

func _on_slot_hovered(slot: Control):
	var bg = slot.get_meta("bg")
	if bg and bg.texture.resource_path == "res://content/ui/inventory/slot_empty.png":
		bg.texture = load("res://content/ui/inventory/slot_highlighted.png")

func _on_slot_unhovered(slot: Control):
	var bg = slot.get_meta("bg")
	if bg and bg.texture.resource_path == "res://content/ui/inventory/slot_highlighted.png":
		bg.texture = load("res://content/ui/inventory/slot_empty.png")

func _on_inventory_changed():
	populate_slots()

func _connect_inventory_signal() -> void:
	if inventory and not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)

func _on_close_pressed():
	close()

func _input(event):
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var pressed_inventory_action: bool = InputMap.has_action("toggle_inventory") and key_event.is_action_pressed("toggle_inventory")
		var pressed_inventory_key: bool = key_event.keycode == KEY_I and key_event.pressed
		if (pressed_inventory_action or pressed_inventory_key) and not key_event.echo:
			if visible:
				close()
			else:
				open()
			get_viewport().set_input_as_handled()
