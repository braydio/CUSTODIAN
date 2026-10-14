extends Control

const ENTRY_SCENE := preload("res://game/ui/loot/loot_toast_entry.tscn")
const MAX_VISIBLE := 4
const MERGE_WINDOW_SEC := 0.75
const ENTER_SEC := 0.12
const HOLD_SEC := 1.80
const EXIT_SEC := 0.25
const HORIZONTAL_INSET := 18.0
const FALLBACK_TOP := 126.0
const HUD_CLEARANCE_GAP := 11.0

var _entries: Array[Dictionary] = []
@onready var _entries_root: VBoxContainer = $Entries
var _hud_clearance_provider: Node
var _minimum_visible_stack_height := 0.0


func _ready() -> void:
	add_to_group("loot_toast_queue")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_clearance_provider = get_parent()
	if _hud_clearance_provider != null:
		if _hud_clearance_provider.has_signal("loot_toast_hud_clearance_changed"):
			var callback := Callable(self, "_refresh_layout")
			if not _hud_clearance_provider.is_connected("loot_toast_hud_clearance_changed", callback):
				_hud_clearance_provider.connect("loot_toast_hud_clearance_changed", callback)
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	_minimum_visible_stack_height = _measure_visible_stack_height()
	_refresh_layout()


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
	_refresh_layout()
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
	_refresh_layout()


func _measure_visible_stack_height() -> float:
	var probe := ENTRY_SCENE.instantiate() as Control
	var entry_height := probe.get_combined_minimum_size().y
	probe.free()
	var separation := float(_entries_root.get_theme_constant("separation"))
	return entry_height * MAX_VISIBLE + separation * (MAX_VISIBLE - 1)


func _refresh_layout() -> void:
	if _entries_root == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var width := minf(320.0, viewport_size.x)
	size.x = width
	position.x = clampf(HORIZONTAL_INSET, 0.0, maxf(0.0, viewport_size.x - width))
	var reserved_height := maxf(size.y, _minimum_visible_stack_height)
	var max_top := maxf(0.0, viewport_size.y - reserved_height)
	var hud_rect := Rect2()
	if _hud_clearance_provider != null and is_instance_valid(_hud_clearance_provider):
		if _hud_clearance_provider.has_method("get_loot_toast_hud_clearance_rect"):
			var value: Variant = _hud_clearance_provider.call("get_loot_toast_hud_clearance_rect")
			if value is Rect2:
				hud_rect = value
	var top := FALLBACK_TOP
	if hud_rect.size.y > 0.0:
		var below_hud := maxf(FALLBACK_TOP, hud_rect.end.y + HUD_CLEARANCE_GAP)
		if below_hud <= max_top:
			top = below_hud
		else:
			var above_hud := hud_rect.position.y - HUD_CLEARANCE_GAP - reserved_height
			if above_hud >= 0.0:
				top = minf(FALLBACK_TOP, above_hud)
			else:
				top = max_top
	position.y = clampf(top, 0.0, max_top)


func _on_viewport_size_changed() -> void:
	_refresh_layout()


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
