class_name ForlornRitualantDialoguePresenter
extends Node2D

signal sequence_finished(node_id: StringName)
signal sequence_cancelled(node_id: StringName)
signal sequence_ended(node_id: StringName, completed: bool)
signal topic_requested(node_id: StringName, return_menu_id: StringName)
signal menu_closed(menu_id: StringName)
signal line_ended(node_id: StringName, line_index: int)

enum Mode { NONE, MANUAL, AMBIENT, MENU }
const MANUAL_PANEL_TOP := -204.0
const MANUAL_LABEL_TOP := -180.0
const MENU_PANEL_TOP := -268.0
const MENU_LABEL_TOP := -244.0
const PANEL_BOTTOM := 0.0
const LABEL_BOTTOM := -18.0
@export_file("*.json") var dialogue_path := "res://content/dialogue/ash_bell/forlorn_ritualant_dialogue.json"
@export var actor_cancel_distance := 280.0
@export var site_path: NodePath
@export var label_path: NodePath = NodePath("AshBellDialogueLabel")
@export var background_path: NodePath = NodePath("Background")
@export var input_debounce_msec := 140
@onready var label: Label = get_node_or_null(label_path)
@onready var background: CanvasItem = get_node_or_null(background_path)
var _nodes := {}; var _menus := {}; var _mode := Mode.NONE; var _active_node: StringName = &""; var _active_menu: StringName = &""; var _return_menu: StringName = &""; var _lines: Array = []; var _line_index := -1; var _menu_options: Array = []; var _menu_index := 0; var _actor: Node2D; var _locked_actor: Node; var _snapshot := {}; var _generation := 0; var _ambient_lock := false; var _pending: StringName = &""; var _pending_actor: Node2D; var _pending_interrupt := false; var _pending_lock := false; var _not_before := 0

func _ready() -> void:
	_load_dialogue(); _set_visible(false); set_process_unhandled_input(true)
func _process(_delta: float) -> void:
	if _mode == Mode.NONE or _actor == null or (_mode == Mode.AMBIENT and _ambient_lock): return
	var site := get_node_or_null(site_path) as Node2D
	if site != null and _actor.global_position.distance_to(site.global_position) > actor_cancel_distance:
		if _mode == Mode.MENU:
			close_menu()
		else:
			cancel()
func _unhandled_input(event: InputEvent) -> void:
	if Time.get_ticks_msec() < _not_before: return
	if _mode == Mode.MANUAL:
		if event.is_action_pressed(&"interact"): get_viewport().set_input_as_handled(); advance()
		elif event.is_action_pressed(&"dodge"): get_viewport().set_input_as_handled(); cancel()
	elif _mode == Mode.MENU:
		if event.is_action_pressed(&"move_up"): get_viewport().set_input_as_handled(); _move_menu(-1)
		elif event.is_action_pressed(&"move_down"): get_viewport().set_input_as_handled(); _move_menu(1)
		elif event.is_action_pressed(&"interact"): get_viewport().set_input_as_handled(); _select_menu()
		elif event.is_action_pressed(&"dodge"): get_viewport().set_input_as_handled(); close_menu()

func start(node_id: StringName, actor: Node2D = null, return_menu_id: StringName = &"") -> bool:
	var d := _definition(node_id)
	if d.is_empty(): return false
	if str(d.get("delivery", "manual")) == "ambient": return start_ambient(node_id, actor, bool(d.get("interrupt_ambient", false)), bool(d.get("lock_actor", false)))
	return start_manual(node_id, actor, return_menu_id)
func start_manual(node_id: StringName, actor: Node2D = null, return_menu_id: StringName = &"") -> bool:
	var source := _get_lines(node_id)
	if source.is_empty() or _mode == Mode.MANUAL: return false
	var conversation_actor := actor if actor != null else _actor
	_clear(true); _mode = Mode.MANUAL; _active_node = node_id; _return_menu = return_menu_id; _lines = source; _line_index = 0; _actor = conversation_actor; _arm(); _apply_layout_for_mode(); _set_visible(true); _show_line(); return true
func start_ambient(node_id: StringName, actor: Node2D = null, interrupt_ambient := false, lock_actor := false) -> bool:
	var source := _get_lines(node_id)
	if source.is_empty(): return false
	if _active_node == node_id and _mode == Mode.AMBIENT: return true
	if _mode == Mode.MANUAL or _mode == Mode.MENU or (_mode == Mode.AMBIENT and not interrupt_ambient): _pending = node_id; _pending_actor = actor; _pending_interrupt = interrupt_ambient; _pending_lock = lock_actor; return true
	if _mode == Mode.AMBIENT: _clear(_ambient_lock)
	_mode = Mode.AMBIENT
	_active_node = node_id
	_lines = source
	_line_index = 0
	_actor = actor
	_ambient_lock = lock_actor
	_generation += 1
	var g := _generation
	if lock_actor: _lock(actor)
	_apply_layout_for_mode()
	_set_visible(true)
	_run_ambient(g)
	return true
func _run_ambient(g: int) -> void:
	while _mode == Mode.AMBIENT and g == _generation and _line_index < _lines.size():
		_show_line(); await get_tree().create_timer(_hold()).timeout
		if _mode != Mode.AMBIENT or g != _generation: return
		line_ended.emit(_active_node, _line_index)
		_line_index += 1
	if _mode == Mode.AMBIENT and g == _generation: finish()
func open_menu(menu_id: StringName, actor: Node2D = null) -> bool:
	var source: Variant = _menus.get(String(menu_id), [])
	if not source is Array: return false
	var conversation_actor := actor if actor != null else _actor
	_clear(true); _mode = Mode.MENU; _active_menu = menu_id; _actor = conversation_actor; _menu_options.clear()
	for value in source:
		if value is Dictionary and _available(value): _menu_options.append((value as Dictionary).duplicate(true))
	if _menu_options.is_empty(): _clear(true); return false
	_menu_index = 0; _arm(); _apply_layout_for_mode(); _set_visible(true); _show_menu(); return true
func advance() -> void:
	if _mode != Mode.MANUAL: return
	_line_index += 1
	if _line_index >= _lines.size(): finish()
	else: _show_line()
func finish() -> void:
	if _active_node == &"": return
	var done := _active_node; var next := _return_menu; var actor := _actor; var manual := _mode == Mode.MANUAL; _clear(true); sequence_finished.emit(done); sequence_ended.emit(done, true); if manual and next != &"": open_menu(next, actor)
	else: _play_pending()
func cancel() -> void:
	if _mode == Mode.MENU: close_menu(); return
	if _active_node == &"": return
	var cancelled := _active_node; _clear(true); sequence_cancelled.emit(cancelled); sequence_ended.emit(cancelled, false); _play_pending()
func close_menu() -> void:
	if _mode != Mode.MENU: return
	var menu := _active_menu; _clear(true); menu_closed.emit(menu); _play_pending()
func force_close() -> void:
	var ended_node := _active_node
	var ended_menu := _active_menu
	_pending = &""
	_pending_actor = null
	_pending_interrupt = false
	_pending_lock = false
	_clear(true)
	if ended_node != &"":
		sequence_cancelled.emit(ended_node)
		sequence_ended.emit(ended_node, false)
	if ended_menu != &"":
		menu_closed.emit(ended_menu)
func is_active() -> bool: return _mode != Mode.NONE
func is_manual_active() -> bool: return _mode == Mode.MANUAL
func is_menu_active() -> bool: return _mode == Mode.MENU
func captures_interaction_input() -> bool: return _mode == Mode.MANUAL or _mode == Mode.MENU
func blocks_world_interaction() -> bool: return captures_interaction_input() or (_mode == Mode.AMBIENT and _ambient_lock)
func get_active_node() -> StringName: return _active_node
func get_active_menu() -> StringName: return _active_menu
func get_current_text() -> String: return label.text if label != null else ""
func debug_get_mode() -> int: return _mode
func debug_get_menu_labels() -> Array[String]:
	var out: Array[String] = []
	for option in _menu_options: out.append(str((option as Dictionary).get("label", "")))
	return out
func debug_select_menu_option(index: int) -> void:
	if _mode == Mode.MENU and not _menu_options.is_empty(): _menu_index = clampi(index, 0, _menu_options.size()-1); _select_menu()
func wait_for_node_end(node_id: StringName) -> void:
	while _active_node == node_id: await sequence_ended
func wait_for_line_end(node_id: StringName, target_line_index: int) -> void:
	while _active_node == node_id and _line_index <= target_line_index:
		var ended: Array = await line_ended
		if ended.size() >= 2 and ended[0] == node_id and int(ended[1]) >= target_line_index:
			return

func _select_menu() -> void:
	if _menu_options.is_empty(): return
	var option := _menu_options[_menu_index] as Dictionary
	if bool(option.get("close", false)): close_menu(); return
	var menu := StringName(str(option.get("menu", "")))
	if menu != &"": open_menu(menu, _actor); return
	var node := StringName(str(option.get("node", "")))
	if node == &"": return
	if _seen(node):
		var recap := StringName(str(option.get("recap_node", "")))
		if recap != &"":
			topic_requested.emit(recap, &"")
			return
	if bool(option.get("skip_if_seen", false)) and _seen(node): open_menu(StringName(str(option.get("next_menu", ""))), _actor); return
	topic_requested.emit(node, StringName(str(option.get("next_menu", ""))))
func _show_menu() -> void:
	if label == null: return
	var rows := PackedStringArray(["Forlorn-Ritualant", ""])
	for i in range(_menu_options.size()):
		var option := _menu_options[i] as Dictionary; rows.append(("> " if i == _menu_index else "  ") + str(option.get("label", "")) + ("  ·" if _seen(StringName(str(option.get("node", "")))) else ""))
	rows.append(""); rows.append("[W/S / STICK] SELECT    [E / A] ASK    [SPACE / B] LEAVE"); label.text = "\n".join(rows)
func _show_line() -> void:
	if label == null or _line_index < 0 or _line_index >= _lines.size(): return
	var line := _lines[_line_index] as Dictionary; label.text = "%s: %s%s" % [str(line.get("speaker", "Forlorn-Ritualant")), str(line.get("text", "")), "\n\n[E / A] CONTINUE    [SPACE / B] CLOSE" if _mode == Mode.MANUAL else ""]
func _hold() -> float:
	return maxf(0.25, float((_lines[_line_index] as Dictionary).get("hold", 2.2)))
func _move_menu(direction: int) -> void:
	if not _menu_options.is_empty(): _menu_index = wrapi(_menu_index + direction, 0, _menu_options.size()); _show_menu()
func _available(option: Dictionary) -> bool: return str(option.get("requires_seen", "")) == "" or _seen(StringName(str(option.get("requires_seen", ""))))
func _seen(node_id: StringName) -> bool:
	var site := get_node_or_null(site_path); var value: Variant = site.get("event_state") if site != null else null
	return value is AshBellEventState and (value as AshBellEventState).has_seen_dialogue(node_id)
func _load_dialogue() -> void:
	if not FileAccess.file_exists(dialogue_path): return
	var f := FileAccess.open(dialogue_path, FileAccess.READ); var data: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
	if data is Dictionary: _nodes = (data as Dictionary).get("nodes", {}).duplicate(true); _menus = (data as Dictionary).get("menus", {}).duplicate(true)
func _definition(node_id: StringName) -> Dictionary:
	var value: Variant = _nodes.get(String(node_id), {})
	if value is Dictionary: return (value as Dictionary).duplicate(true)
	if value is Array: return {"lines":value}
	return {}
func _get_lines(node_id: StringName) -> Array:
	var value: Variant = _definition(node_id).get("lines", []); return value.duplicate(true) if value is Array else []
func _play_pending() -> void:
	if _pending == &"": return
	var n := _pending; var a := _pending_actor; var i := _pending_interrupt; var l := _pending_lock; _pending = &""; _pending_actor = null; _pending_interrupt = false; _pending_lock = false; start_ambient(n, a, i, l)
func _arm() -> void: _not_before = Time.get_ticks_msec() + input_debounce_msec
func _lock(actor: Node) -> void:
	if actor == null: return
	_unlock(); _locked_actor = actor; _snapshot = {"p":actor.is_processing(),"ph":actor.is_physics_processing(),"i":actor.is_processing_input(),"u":actor.is_processing_unhandled_input(),"k":actor.is_processing_unhandled_key_input()}; actor.set_process(false); actor.set_physics_process(false); actor.set_process_input(false); actor.set_process_unhandled_input(false); actor.set_process_unhandled_key_input(false); if actor is CharacterBody2D: (actor as CharacterBody2D).velocity = Vector2.ZERO
func _unlock() -> void:
	if _locked_actor == null or not is_instance_valid(_locked_actor): _locked_actor = null; _snapshot.clear(); return
	_locked_actor.set_process(bool(_snapshot.get("p", true))); _locked_actor.set_physics_process(bool(_snapshot.get("ph", true))); _locked_actor.set_process_input(bool(_snapshot.get("i", true))); _locked_actor.set_process_unhandled_input(bool(_snapshot.get("u", true))); _locked_actor.set_process_unhandled_key_input(bool(_snapshot.get("k", true))); _locked_actor = null; _snapshot.clear()
func _clear(unlock: bool) -> void:
	_generation += 1; _mode = Mode.NONE; _active_node = &""; _active_menu = &""; _return_menu = &""; _lines.clear(); _line_index = -1; _menu_options.clear(); _actor = null; _ambient_lock = false; if unlock: _unlock(); if label != null: label.text = ""; _set_visible(false)
func _set_visible(value: bool) -> void: visible = value; if background != null: background.visible = value


func _apply_layout_for_mode() -> void:
	if background == null or label == null:
		return
	var panel := background as Control
	var text := label as Control
	if panel == null or text == null:
		return
	if _mode == Mode.MENU:
		panel.offset_top = MENU_PANEL_TOP
		text.offset_top = MENU_LABEL_TOP
	else:
		panel.offset_top = MANUAL_PANEL_TOP
		text.offset_top = MANUAL_LABEL_TOP
	panel.offset_bottom = PANEL_BOTTOM
	text.offset_bottom = LABEL_BOTTOM
