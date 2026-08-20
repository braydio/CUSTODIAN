class_name AshBellWestGateWorks
extends AuthoredLevel2D

const AUTHORING_CELL_SIZE_WORLD := 32.0
const MAP_SIZE_CELLS := Vector2i(64, 48)
const MAP_ORIGIN := Vector2(-1024.0, -768.0)
const SLAB_TRAVEL := Vector2(0.0, 5.0 * AUTHORING_CELL_SIZE_WORLD)
const CLOSURE_DURATION_SEC := 2.4
const WALKABLE_REGIONS: Array[Rect2i] = [
	Rect2i(48, 18, 12, 12), Rect2i(34, 16, 16, 16),
	Rect2i(20, 12, 16, 24), Rect2i(8, 16, 14, 16),
	Rect2i(14, 4, 16, 8), Rect2i(20, 32, 28, 10),
]

var _gate_motor_repaired := false
var _closure_complete := false
var _closure_archive_read := false
var _slab_open_position := Vector2.ZERO

@onready var blockout_grid := $PlayableRoot/BlockoutGrid as AuthoredBlockoutGrid2D
@onready var gate_motor := $POIRoot/GateMotorRelay as CivicRelay2D
@onready var closure_slab := $DynamicGates/ClosureSlab as AnimatableBody2D


func _ready() -> void:
	blockout_grid.position = MAP_ORIGIN
	blockout_grid.configure(AUTHORING_CELL_SIZE_WORLD, MAP_SIZE_CELLS, WALKABLE_REGIONS)
	gate_motor.position = cell_center(Vector2i(12, 24))
	gate_motor.repaired_changed.connect(_on_gate_motor_repaired)
	_configure_slab()
	$EventMarkers/PressureSpawn_GateMotor_01.position = cell_center(Vector2i(18, 20))
	$EventMarkers/PressureSpawn_GateMotor_02.position = cell_center(Vector2i(24, 34))
	super._ready()
	_apply_state(false)


func cell_center(cell: Vector2i) -> Vector2:
	return MAP_ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * AUTHORING_CELL_SIZE_WORLD


func get_boundary_segments() -> Array:
	return blockout_grid.get_boundary_segments() if blockout_grid != null else []


func get_authoring_markers() -> Dictionary:
	return {
		"spawn_from_lower_quarter": {"kind": "spawn", "node_name": "Spawn_FromLowerQuarter", "position": cell_center(Vector2i(55, 24))},
		"backtrack": {"kind": "exit", "node_name": "Exit_Backtrack", "position": cell_center(Vector2i(58, 24))},
		"gate_motor": {"kind": "poi", "node_name": "GateMotorRelay", "position": cell_center(Vector2i(12, 24))},
	}


func capture_route_state() -> Dictionary:
	return {
		"gate_motor_repaired": _gate_motor_repaired,
		"closure_complete": _closure_complete,
		"closure_archive_read": _closure_archive_read,
	}


func restore_route_state(state: Dictionary) -> bool:
	_gate_motor_repaired = bool(state.get("gate_motor_repaired", false))
	_closure_complete = bool(state.get("closure_complete", false))
	_closure_archive_read = bool(state.get("closure_archive_read", false))
	_apply_state(false)
	return true


func debug_is_closure_complete() -> bool:
	return _closure_complete


func debug_get_archive_content() -> String:
	return "WEST GATE CLOSURE ORDER ISSUED BEFORE LOWER QUARTER CLEARANCE COMPLETE"


func debug_get_closure_slab_position() -> Vector2:
	return closure_slab.position


func debug_get_closed_slab_position() -> Vector2:
	return _slab_open_position + SLAB_TRAVEL


func _configure_slab() -> void:
	_slab_open_position = cell_center(Vector2i(31, 30))
	closure_slab.position = _slab_open_position
	var size := Vector2(8, 2) * AUTHORING_CELL_SIZE_WORLD
	var shape := RectangleShape2D.new()
	shape.size = size
	($DynamicGates/ClosureSlab/CollisionShape2D as CollisionShape2D).shape = shape
	var visual := $DynamicGates/ClosureSlab/Visual as Polygon2D
	visual.color = Color("60676b")
	visual.polygon = PackedVector2Array([-size * 0.5, Vector2(size.x * 0.5, -size.y * 0.5), size * 0.5, Vector2(-size.x * 0.5, size.y * 0.5)])


func _on_gate_motor_repaired(_relay_id: StringName, repaired: bool) -> void:
	_gate_motor_repaired = repaired
	if repaired and not _closure_complete:
		_begin_closure()


func _begin_closure() -> void:
	var tween := create_tween()
	tween.tween_property(closure_slab, "position", _slab_open_position + SLAB_TRAVEL, CLOSURE_DURATION_SEC)
	tween.tween_callback(_complete_closure)


func _complete_closure() -> void:
	_closure_complete = true


func _apply_state(emit_relay_signals: bool) -> void:
	gate_motor.set_repaired(_gate_motor_repaired, emit_relay_signals)
	closure_slab.position = _slab_open_position + (SLAB_TRAVEL if _closure_complete else Vector2.ZERO)
