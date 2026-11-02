class_name ConstructionPlacementController
extends Node

signal placement_started(build_id: StringName, definition: StructureDefinition)
signal placement_updated(snapshot: Dictionary)
signal placement_committed(instance: Node2D, build_id: StringName)
signal placement_cancelled(build_id: StringName)
signal placement_failed(build_id: StringName, reason: StringName)
signal placement_mode_changed(active: bool)

const CATALOG := preload("res://game/infrastructure/construction_catalog.gd")
const VALIDATOR := preload("res://game/infrastructure/construction_placement_validator.gd")
const PREVIEW := preload("res://game/infrastructure/construction_placement_preview.gd")

var _validator: ConstructionPlacementValidator = VALIDATOR.new()
var _selected_build_id: StringName
var _definition: StructureDefinition
var _rotation_degrees := 0
var _active := false
var _preview: ConstructionPlacementPreview
var _snapshot: Dictionary = {}
var _preview_override_active := false
var _preview_override_position := Vector2.ZERO
var _reopen_terminal_on_cancel := false


func _ready() -> void:
	add_to_group("construction_placement_controller")
	set_process_input(true)
	set_process(true)


func _process(_delta: float) -> void:
	if not _active:
		return
	set_preview_world_position(
		_preview_override_position if _preview_override_active else _get_world_mouse_position()
	)


func _input(event: InputEvent) -> void:
	if not _active or event.is_echo():
		return
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		attempt_commit_at(_get_world_mouse_position())
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			rotate_clockwise()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_Q, KEY_ESCAPE]:
			cancel_placement()
			get_viewport().set_input_as_handled()


func can_handle_build_token(build_id: StringName) -> bool:
	return CATALOG.has_build(build_id)


func enter_build_token_placement(build_id: StringName) -> bool:
	if _active or not can_handle_build_token(build_id):
		return false
	var inventory := _get_build_inventory()
	if inventory == null or int(inventory.call("get_amount", String(build_id))) <= 0:
		placement_failed.emit(build_id, &"token_unavailable")
		return false
	_definition = CATALOG.get_definition(build_id)
	if _definition == null or CATALOG.get_scene(build_id) == null:
		placement_failed.emit(build_id, &"catalog_invalid")
		return false
	_selected_build_id = build_id
	_rotation_degrees = _normalized_allowed_rotation(0)
	_active = true
	_reopen_terminal_on_cancel = _is_terminal_open()
	_create_preview()
	_set_zone_presentation(true)
	placement_mode_changed.emit(true)
	placement_started.emit(build_id, _definition)
	var ui := _get_ui()
	if ui != null and ui.has_method("enter_construction_placement_ui"):
		ui.call("enter_construction_placement_ui", get_preview_snapshot())
	set_preview_world_position(_get_world_mouse_position())
	return true


func cancel_placement() -> void:
	if not _active:
		return
	var cancelled_id := _selected_build_id
	_exit_mode()
	var ui := _get_ui()
	if ui != null and ui.has_method("exit_construction_placement_ui"):
		ui.call("exit_construction_placement_ui", _reopen_terminal_on_cancel)
	placement_cancelled.emit(cancelled_id)


func is_placing() -> bool:
	return _active


func get_selected_build_id() -> StringName:
	return _selected_build_id


func get_rotation_degrees() -> int:
	return _rotation_degrees


func rotate_clockwise() -> void:
	if not _active or _definition == null:
		return
	var rotations := _definition.allowed_rotations
	if rotations.is_empty():
		_rotation_degrees = 0
	else:
		var index := rotations.find(_rotation_degrees)
		_rotation_degrees = rotations[(index + 1) % rotations.size()]
	set_preview_world_position(
		_preview_override_position if _preview_override_active else _get_world_mouse_position()
	)


func set_preview_world_position(world_position: Vector2) -> Dictionary:
	if not _active:
		return {}
	_snapshot = _validator.validate(
		world_position, _definition, _rotation_degrees, get_tree(),
		_get_floor_tilemap(), _get_construction_zones(), _get_operator()
	)
	_snapshot["build_id"] = _selected_build_id
	_snapshot["display_name"] = _definition.display_name
	_snapshot["category"] = _definition.category
	_snapshot["rotation_degrees"] = _rotation_degrees
	_snapshot["footprint_tiles"] = _validator.get_rotated_footprint_tiles(_definition, _rotation_degrees)
	_snapshot["ready_count"] = _get_ready_count()
	if _preview != null:
		_preview.apply_snapshot(_snapshot)
	placement_updated.emit(get_preview_snapshot())
	var ui := _get_ui()
	if ui != null and ui.has_method("update_construction_placement_ui"):
		ui.call("update_construction_placement_ui", get_preview_snapshot())
	return get_preview_snapshot()


func set_preview_override(world_position: Vector2) -> Dictionary:
	_preview_override_active = true
	_preview_override_position = world_position
	return set_preview_world_position(world_position)


func clear_preview_override() -> void:
	_preview_override_active = false


func get_preview_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


func attempt_commit_at(world_position: Vector2) -> bool:
	if not _active or _definition == null:
		return false
	var validation := set_preview_world_position(world_position)
	if not bool(validation.get("valid", false)):
		placement_failed.emit(_selected_build_id, StringName(str(validation.get("reason", "invalid_site"))))
		return false
	var scene := CATALOG.get_scene(_selected_build_id)
	var instance := scene.instantiate() as Node2D if scene != null else null
	if instance == null:
		placement_failed.emit(_selected_build_id, &"scene_instantiate_failed")
		return false
	var inventory := _get_build_inventory()
	if inventory == null or not bool(inventory.call("remove", String(_selected_build_id), 1)):
		instance.free()
		placement_failed.emit(_selected_build_id, &"token_unavailable")
		return false
	var committed_id := _selected_build_id
	var parent := get_parent()
	if parent == null:
		inventory.call("add", String(committed_id), 1)
		instance.free()
		placement_failed.emit(committed_id, &"world_unavailable")
		return false
	parent.add_child(instance)
	var world_rect := validation.get("world_rect", Rect2()) as Rect2
	instance.global_position = world_rect.get_center()
	instance.rotation_degrees = _rotation_degrees
	if not instance.has_method("begin_construction") or not bool(instance.call("begin_construction")):
		parent.remove_child(instance)
		instance.queue_free()
		inventory.call("add", String(committed_id), 1)
		placement_failed.emit(committed_id, &"construction_initialization_failed")
		return false
	_exit_mode()
	var ui := _get_ui()
	if ui != null and ui.has_method("exit_construction_placement_ui"):
		ui.call("exit_construction_placement_ui", false)
	placement_committed.emit(instance, committed_id)
	_observe(&"infrastructure_foundation_committed", {
		"build_token_id": String(committed_id),
		"position": instance.global_position,
		"rotation_degrees": instance.rotation_degrees,
		"world_rect": world_rect,
	})
	return true


func _exit_mode() -> void:
	_active = false
	_set_zone_presentation(false)
	if _preview != null:
		_preview.queue_free()
	_preview = null
	_snapshot.clear()
	_selected_build_id = &""
	_definition = null
	_preview_override_active = false
	placement_mode_changed.emit(false)


func _create_preview() -> void:
	_preview = PREVIEW.new() as ConstructionPlacementPreview
	_preview.name = "ConstructionPlacementPreview"
	get_parent().add_child(_preview)
	_preview.configure(_definition)


func _get_construction_zones() -> Array[Node]:
	var result: Array[Node] = []
	for node in get_tree().get_nodes_in_group("construction_zone"):
		result.append(node)
	return result


func _set_zone_presentation(visible: bool) -> void:
	for zone in _get_construction_zones():
		if zone.has_method("set_placement_presentation_visible"):
			zone.call("set_placement_presentation_visible", visible)


func _get_floor_tilemap() -> TileMapLayer:
	for map_node in get_tree().get_nodes_in_group("procgen_tilemap"):
		if map_node.has_method("get_floor_tilemap"):
			return map_node.call("get_floor_tilemap") as TileMapLayer
	return null


func _get_operator() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _get_build_inventory() -> Node:
	return get_node_or_null("/root/BuildInventory")


func _get_ready_count() -> int:
	var inventory := _get_build_inventory()
	return int(inventory.call("get_amount", String(_selected_build_id))) if inventory != null else 0


func _get_ui() -> Node:
	return get_node_or_null("/root/GameRoot/UI")


func _is_terminal_open() -> bool:
	var ui := _get_ui()
	return ui != null and ui.has_method("is_terminal_open") and bool(ui.call("is_terminal_open"))


func _normalized_allowed_rotation(requested: int) -> int:
	if _definition == null or _definition.allowed_rotations.is_empty():
		return 0
	return requested if _definition.allowed_rotations.has(requested) else _definition.allowed_rotations[0]


func _get_world_mouse_position() -> Vector2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()


func _observe(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)
