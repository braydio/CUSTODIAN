class_name ForlornRitualantDialoguePresenter
extends Node2D

signal sequence_finished(node_id: StringName)
signal sequence_cancelled(node_id: StringName)

@export_file("*.json") var dialogue_path := "res://content/dialogue/ash_bell/forlorn_ritualant_dialogue.json"
@export var actor_cancel_distance := 280.0
@export var site_path: NodePath
@export var label_path: NodePath = NodePath("AshBellDialogueLabel")
@export var background_path: NodePath = NodePath("Background")

@onready var label: Label = get_node_or_null(label_path)
@onready var background: CanvasItem = get_node_or_null(background_path)

var _nodes: Dictionary = {}
var _active_node := &""
var _lines: Array = []
var _line_index := -1
var _actor: Node2D


func _ready() -> void:
	_load_dialogue()
	_set_visible(false)
	set_process_unhandled_input(true)
	set_process(true)


func _process(_delta: float) -> void:
	if _active_node == &"" or _actor == null:
		return
	var site := get_node_or_null(site_path) as Node2D
	if site != null and _actor.global_position.distance_to(site.global_position) > actor_cancel_distance:
		cancel()


func _unhandled_input(event: InputEvent) -> void:
	if _active_node == &"" or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	advance()


func start(node_id: StringName, actor: Node2D = null) -> bool:
	var source: Variant = _nodes.get(String(node_id), [])
	if not (source is Array) or (source as Array).is_empty():
		return false
	_active_node = node_id
	_lines = (source as Array).duplicate(true)
	_line_index = 0
	_actor = actor
	_set_visible(true)
	_show_current_line()
	return true


func advance() -> void:
	if _active_node == &"":
		return
	_line_index += 1
	if _line_index >= _lines.size():
		finish()
	else:
		_show_current_line()


func finish() -> void:
	if _active_node == &"":
		return
	var completed := _active_node
	_clear()
	sequence_finished.emit(completed)


func cancel() -> void:
	if _active_node == &"":
		return
	var cancelled := _active_node
	_clear()
	sequence_cancelled.emit(cancelled)


func is_active() -> bool:
	return _active_node != &""


func get_active_node() -> StringName:
	return _active_node


func get_current_text() -> String:
	return label.text if label != null else ""


func _load_dialogue() -> void:
	if not FileAccess.file_exists(dialogue_path):
		push_error("[RitualantDialogue] Missing dialogue data: %s" % dialogue_path)
		return
	var file := FileAccess.open(dialogue_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if parsed is Dictionary:
		_nodes = ((parsed as Dictionary).get("nodes", {}) as Dictionary).duplicate(true)


func _show_current_line() -> void:
	if label == null or _line_index < 0 or _line_index >= _lines.size():
		return
	var line: Variant = _lines[_line_index]
	if line is Dictionary:
		var speaker := str((line as Dictionary).get("speaker", "Forlorn-Ritualant"))
		var text := str((line as Dictionary).get("text", ""))
		label.text = "%s: %s\n\n[E] CONTINUE" % [speaker, text]
	else:
		label.text = "Forlorn-Ritualant: %s\n\n[E] CONTINUE" % str(line)


func _clear() -> void:
	_active_node = &""
	_lines.clear()
	_line_index = -1
	_actor = null
	if label != null:
		label.text = ""
	_set_visible(false)


func _set_visible(value: bool) -> void:
	visible = value
	if background != null:
		background.visible = value
