class_name MapperHistory
extends RefCounted

var capacity := 200
var _undo: Array = []
var _redo: Array = []

func push(snapshot: Variant) -> void:
	_undo.append(snapshot)
	if _undo.size() > capacity:
		_undo.pop_front()
	_redo.clear()

func undo(current: Variant) -> Variant:
	if _undo.is_empty():
		return current
	_redo.append(current)
	return _undo.pop_back()

func redo(current: Variant) -> Variant:
	if _redo.is_empty():
		return current
	_undo.append(current)
	return _redo.pop_back()

func clear() -> void:
	_undo.clear(); _redo.clear()

