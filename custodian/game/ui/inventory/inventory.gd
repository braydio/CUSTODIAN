extends Node
class_name Inventory

signal inventory_changed()

@export var max_slots: int = 20

var slots: Array = []  # Array of dictionaries: {item: ItemResource, quantity: int}

func _ready():
	initialize_slots()

func initialize_slots():
	slots.clear()
	for i in max_slots:
		slots.append({"item": null, "quantity": 0})

func add_item(item: ItemResource, quantity: int = 1) -> bool:
	# Try to stack with existing items first
	if item.stackable:
		for i in range(max_slots):
			var slot = slots[i]
			if slot.item and slot.item.item_id == item.item_id:
				var can_add = item.stack_size - slot.quantity
				var to_add = min(quantity, can_add)
				if to_add > 0:
					slot.quantity += to_add
					quantity -= to_add
					inventory_changed.emit()
					if quantity <= 0:
						return true
	
	# Add to empty slots
	for i in range(max_slots):
		var slot = slots[i]
		if slot.item == null:
			slot.item = item
			slot.quantity = min(quantity, item.stack_size)
			quantity -= slot.quantity
			inventory_changed.emit()
			if quantity <= 0:
				return true
	
	return false  # Couldn't add all items

func remove_item(slot_index: int, quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= max_slots:
		return false
	
	var slot = slots[slot_index]
	if slot.item == null or slot.quantity == 0:
		return false
	
	slot.quantity -= quantity
	if slot.quantity <= 0:
		slot.item = null
		slot.quantity = 0
	
	inventory_changed.emit()
	return true

func get_item_at(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= max_slots:
		return {"item": null, "quantity": 0}
	return slots[slot_index]

func has_empty_slot() -> bool:
	for slot in slots:
		if slot.item == null:
			return true
	return false

func clear():
	initialize_slots()
	inventory_changed.emit()
