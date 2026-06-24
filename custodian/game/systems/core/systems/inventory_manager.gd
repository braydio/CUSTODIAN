extends Node

signal item_added(item_id: StringName, amount: int, new_total: int)
signal item_removed(item_id: StringName, amount: int, new_total: int)
signal item_count_changed(item_id: StringName, old_total: int, new_total: int)
signal inventory_changed
signal equipment_changed(slot_name: StringName, item_id: StringName)

var _items: Dictionary = {}

## Equipment slot mapping: slot_name → item_id.
## Empty slot = &"" (empty StringName). Extensible for future slots.
var _equipment_slots: Dictionary = {}

const SIDEARM_SLOT := &"sidearm"
const DEFAULT_EQUIPMENT_SLOTS: Array[StringName] = [&"sidearm"]


func add_item(item_id: StringName, amount: int = 1) -> int:
	if item_id == &"" or amount <= 0:
		return get_count(item_id)

	var old_total := get_count(item_id)
	var new_total := old_total + amount
	_items[item_id] = new_total

	item_added.emit(item_id, amount, new_total)
	item_count_changed.emit(item_id, old_total, new_total)
	inventory_changed.emit()

	return new_total


func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if item_id == &"" or amount <= 0:
		return false

	var old_total := get_count(item_id)
	if old_total < amount:
		return false

	var new_total := old_total - amount
	if new_total <= 0:
		_items.erase(item_id)
	else:
		_items[item_id] = new_total

	item_removed.emit(item_id, amount, new_total)
	item_count_changed.emit(item_id, old_total, new_total)
	inventory_changed.emit()

	return true


func has_item(item_id: StringName, amount: int = 1) -> bool:
	return get_count(item_id) >= amount


func get_count(item_id: StringName) -> int:
	return int(_items.get(item_id, 0))


func get_all_items() -> Dictionary:
	return _items.duplicate(true)


func clear() -> void:
	_items.clear()
	_equipment_slots.clear()
	inventory_changed.emit()
	equipment_changed.emit(SIDEARM_SLOT, &"")


## Equipment API — extensible slot-based system for equipping items.

## Initialize equipment slots on first access.
func _init_equipment_slots() -> void:
	if _equipment_slots.is_empty():
		for slot in DEFAULT_EQUIPMENT_SLOTS:
			_equipment_slots[slot] = &""


## Return the item_id equipped in the given slot, or &"" if empty.
func get_equipped(slot_name: StringName) -> StringName:
	_init_equipment_slots()
	return StringName(_equipment_slots.get(slot_name, &""))


## Return true if the given equipment slot is occupied.
func is_slot_filled(slot_name: StringName) -> bool:
	return get_equipped(slot_name) != &""


## Equip an item from inventory into the given equipment slot.
## Removes the item from inventory. Returns true on success.
func equip_item(item_id: StringName, slot_name: StringName) -> bool:
	_init_equipment_slots()
	if not _equipment_slots.has(slot_name):
		return false
	if not has_item(item_id, 1):
		return false
	if is_slot_filled(slot_name):
		return false
	
	remove_item(item_id, 1)
	_equipment_slots[slot_name] = item_id
	equipment_changed.emit(slot_name, item_id)
	return true


## Unequip the item in the given slot, returning it to inventory.
## Returns true on success.
func unequip_slot(slot_name: StringName) -> bool:
	_init_equipment_slots()
	if not _equipment_slots.has(slot_name):
		return false
	var item_id := StringName(_equipment_slots[slot_name])
	if item_id == &"":
		return false
	
	_equipment_slots[slot_name] = &""
	add_item(item_id, 1)
	equipment_changed.emit(slot_name, &"")
	return true


## Get all currently equipped items as {slot_name: item_id}.
func get_all_equipped() -> Dictionary:
	_init_equipment_slots()
	return _equipment_slots.duplicate(true)


func to_save_dict() -> Dictionary:
	var out := {}
	for key in _items.keys():
		out[String(key)] = int(_items[key])
	return out


func from_save_dict(data: Dictionary) -> void:
	_items.clear()
	for key in data.keys():
		var amount := int(data[key])
		if amount > 0:
			_items[StringName(str(key))] = amount
	inventory_changed.emit()
