extends Control

const ENTRY_SCENE := preload("res://game/ui/loot/loot_toast_entry.tscn")
const MAX_VISIBLE := 4
const MERGE_WINDOW_SEC := 0.75
const ENTER_SEC := 0.12
const HOLD_SEC := 1.80
const EXIT_SEC := 0.25

var _entries: Array[Dictionary] = []
@onready var _entries_root: VBoxContainer = $Entries


func _ready() -> void:
	add_to_group("loot_toast_queue")
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func push_pickup(
	item_id: StringName,
	display_name: String,
	quantity: int,
	accent: Color,
	icon: Texture2D = null,
	detail: String = ""
) -> void:
	if quantity == 0:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not _entries.is_empty():
		var last: Dictionary = _entries[-1]
		if last.get("item_id", &"") == item_id and now - float(last.get("time", 0.0)) <= MERGE_WINDOW_SEC:
			last["quantity"] = int(last.get("quantity", 0)) + quantity
			last["time"] = now
			last["detail"] = detail
			_entries[-1] = last
			_refresh_entry(last.get("node"))
			return
	var entry := {
		"item_id": item_id,
		"display_name": display_name,
		"quantity": quantity,
		"accent": accent,
		"icon": icon,
		"detail": detail,
		"time": now,
		"node": null,
	}
	_entries.append(entry)
	while _entries.size() > MAX_VISIBLE + 2:
		var dropped: Dictionary = _entries.pop_front()
		if is_instance_valid(dropped.get("node")):
			dropped["node"].queue_free()
	_rebuild_entries()


func _rebuild_entries() -> void:
	for child in _entries_root.get_children():
		child.queue_free()
	for index in range(_entries.size()):
		var entry: Dictionary = _entries[index]
		var node := ENTRY_SCENE.instantiate()
		_entries_root.add_child(node)
		entry["node"] = node
		_entries[index] = entry
		node.configure(entry.display_name, entry.quantity, entry.accent, entry.icon, entry.detail)
		node.modulate.a = 0.0
		node.position.x = -24.0
		var tween := create_tween()
		tween.tween_interval(float(index) * 0.02)
		tween.tween_property(node, "position:x", 0.0, ENTER_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(node, "modulate:a", 1.0, ENTER_SEC)
		tween.tween_interval(HOLD_SEC)
		tween.tween_property(node, "position:y", -8.0, EXIT_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(node, "modulate:a", 0.0, EXIT_SEC)
		tween.tween_callback(_expire_entry.bind(entry.item_id, entry.time))


func _refresh_entry(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		_rebuild_entries()
		return
	var entry: Dictionary = _entries[-1]
	node.configure(entry.display_name, entry.quantity, entry.accent, entry.icon, entry.detail)


func _expire_entry(item_id: StringName, timestamp: float) -> void:
	for index in range(_entries.size() - 1, -1, -1):
		var entry: Dictionary = _entries[index]
		if entry.item_id == item_id and is_equal_approx(float(entry.time), timestamp):
			_entries.remove_at(index)
			_rebuild_entries()
			return
