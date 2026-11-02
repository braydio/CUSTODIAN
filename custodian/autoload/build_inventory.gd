extends Node

signal changed(snapshot: Dictionary)
signal item_added(item_id: String, amount: int, new_total: int)
signal item_removed(item_id: String, amount: int, new_total: int)

var _items: Dictionary = {}


func add(item_id: String, amount: int = 1) -> void:
	if amount <= 0 or item_id.is_empty():
		return

	var new_total := get_amount(item_id) + amount
	_items[item_id] = new_total

	item_added.emit(item_id, amount, new_total)
	changed.emit(get_snapshot())


func remove(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or item_id.is_empty():
		return false
	if get_amount(item_id) < amount:
		return false

	var new_total := get_amount(item_id) - amount
	if new_total <= 0:
		_items.erase(item_id)
	else:
		_items[item_id] = new_total

	item_removed.emit(item_id, amount, new_total)
	changed.emit(get_snapshot())
	return true


func get_amount(item_id: String) -> int:
	return int(_items.get(item_id, 0))


func get_snapshot() -> Dictionary:
	return _items.duplicate(true)


func clear() -> void:
	_items.clear()
	changed.emit(get_snapshot())
