extends Node

signal item_added(item_id: StringName, amount: int, new_total: int)
signal item_removed(item_id: StringName, amount: int, new_total: int)
signal item_count_changed(item_id: StringName, old_total: int, new_total: int)
signal inventory_changed

var _items: Dictionary = {}


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
	inventory_changed.emit()


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
