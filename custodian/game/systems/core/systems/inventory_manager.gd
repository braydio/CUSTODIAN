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
const RELIC_SLOT := &"relic"
const CANONICAL_RESOURCE_ITEMS: Array[StringName] = [&"white_thread_knot"]
const DEFAULT_EQUIPMENT_SLOTS: Array[StringName] = [
	SIDEARM_SLOT,
	RELIC_SLOT,
]


func add_item(item_id: StringName, amount: int = 1) -> int:
	if item_id == &"" or amount <= 0:
		return get_count(item_id)
	if CANONICAL_RESOURCE_ITEMS.has(item_id):
		var ledger := get_node_or_null("/root/ResourceLedger")
		if ledger == null:
			push_warning("[InventoryManager] ResourceLedger unavailable for %s" % item_id)
			return 0
		var old_resource_total := int(ledger.call("get_amount", String(item_id)))
		ledger.call("add", String(item_id), amount)
		var new_resource_total := int(ledger.call("get_amount", String(item_id)))
		item_added.emit(item_id, amount, new_resource_total)
		item_count_changed.emit(item_id, old_resource_total, new_resource_total)
		inventory_changed.emit()
		return new_resource_total

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
	if CANONICAL_RESOURCE_ITEMS.has(item_id):
		var ledger := get_node_or_null("/root/ResourceLedger")
		if ledger == null:
			return false
		var old_resource_total := int(ledger.call("get_amount", String(item_id)))
		if old_resource_total < amount or not bool(ledger.call("pay", {String(item_id): amount})):
			return false
		var new_resource_total := int(ledger.call("get_amount", String(item_id)))
		item_removed.emit(item_id, amount, new_resource_total)
		item_count_changed.emit(item_id, old_resource_total, new_resource_total)
		inventory_changed.emit()
		return true

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
	if CANONICAL_RESOURCE_ITEMS.has(item_id):
		var ledger := get_node_or_null("/root/ResourceLedger")
		return int(ledger.call("get_amount", String(item_id))) if ledger != null else 0
	return int(_items.get(item_id, 0))


func get_all_items() -> Dictionary:
	return _items.duplicate(true)


func clear() -> void:
	_items.clear()
	_equipment_slots.clear()
	inventory_changed.emit()
	equipment_changed.emit(SIDEARM_SLOT, &"")
	equipment_changed.emit(RELIC_SLOT, &"")


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
	var item_data := {}
	for key in _items.keys():
		item_data[String(key)] = int(_items[key])
	var equipment_data := {}
	_init_equipment_slots()
	for slot_name in DEFAULT_EQUIPMENT_SLOTS:
		equipment_data[String(slot_name)] = String(
			_equipment_slots.get(slot_name, &"")
		)
	return {
		"items": item_data,
		"equipment_slots": equipment_data,
	}


func from_save_dict(data: Dictionary) -> void:
	_items.clear()
	_equipment_slots.clear()
	_init_equipment_slots()
	var item_data: Dictionary = data.get("items", data)
	for key in item_data.keys():
		var amount := int(item_data[key])
		if CANONICAL_RESOURCE_ITEMS.has(StringName(str(key))):
			var ledger := get_node_or_null("/root/ResourceLedger")
			if ledger != null and amount > int(ledger.call("get_amount", str(key))):
				ledger.call("add", str(key), amount - int(ledger.call("get_amount", str(key))))
			continue
		if amount > 0:
			_items[StringName(str(key))] = amount
	var equipment_data: Dictionary = data.get("equipment_slots", {})
	for slot_name in DEFAULT_EQUIPMENT_SLOTS:
		var item_id := StringName(str(equipment_data.get(String(slot_name), "")))
		_equipment_slots[slot_name] = item_id
	inventory_changed.emit()
	for slot_name in DEFAULT_EQUIPMENT_SLOTS:
		equipment_changed.emit(
			slot_name,
			StringName(_equipment_slots.get(slot_name, &""))
		)
