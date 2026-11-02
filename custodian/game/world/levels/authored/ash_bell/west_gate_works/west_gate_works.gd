class_name AshBellWestGateWorks
extends AuthoredLevel2D

const CIVIC_PRESENTER_SCRIPT := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd")
const CIVIC_RELAY := preload("res://content/sprites/environment/props/ash_bell/common/meridian_civic_relay/runtime/body/meridian_civic_relay__body__interaction__idle__omni__1f__96.png")

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

enum ClosurePhase { OPEN, CLOSING, CLOSED }

var _gate_motor_repaired := false
var _closure_phase := ClosurePhase.OPEN
var _closure_progress := 0.0
var _closure_archive_read := false
var _slab_open_position := Vector2.ZERO
var _closure_tween: Tween
var _last_navigation_slab_y := -999

@onready var blockout_grid := $PlayableRoot/BlockoutGrid as AuthoredBlockoutGrid2D
@onready var gate_motor := $POIRoot/GateMotorRelay as CivicRelay2D
@onready var closure_slab := $DynamicGates/ClosureSlab as AnimatableBody2D
@onready var authored_navigation := $NavigationRoot/AuthoredNavigationProvider as AuthoredNavigationProvider2D


func _ready() -> void:
	blockout_grid.position = MAP_ORIGIN
	blockout_grid.configure(AUTHORING_CELL_SIZE_WORLD, MAP_SIZE_CELLS, WALKABLE_REGIONS)
	blockout_grid.visible = false
	gate_motor.presentation_texture = CIVIC_RELAY
	gate_motor.position = cell_center(Vector2i(12, 24))
	gate_motor.repaired_changed.connect(_on_gate_motor_repaired)
	_configure_slab()
	_build_production_presentation()
	authored_navigation.configure(blockout_grid)
	_build_evidence()
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
		"closure_phase": _closure_phase,
		"closure_progress": _closure_progress,
		"closure_complete": _closure_phase == ClosurePhase.CLOSED,
		"closure_archive_read": _closure_archive_read,
	}


func restore_route_state(state: Dictionary) -> bool:
	_gate_motor_repaired = bool(state.get("gate_motor_repaired", false))
	_closure_phase = int(state.get("closure_phase", ClosurePhase.CLOSED if bool(state.get("closure_complete", false)) else ClosurePhase.OPEN)) as ClosurePhase
	_closure_progress = clampf(float(state.get("closure_progress", 1.0 if _closure_phase == ClosurePhase.CLOSED else 0.0)), 0.0, 1.0)
	_closure_archive_read = bool(state.get("closure_archive_read", false))
	_apply_state(false)
	var evidence := get_node_or_null("POIRoot/WestGateClosureOrder") as WorldEvidenceInteractable2D
	if evidence != null:
		evidence.set_recovered(_closure_archive_read)
	if _closure_phase == ClosurePhase.CLOSING:
		_begin_closure()
	return true


func debug_is_closure_complete() -> bool:
	return _closure_phase == ClosurePhase.CLOSED


func debug_get_closure_phase() -> int:
	return _closure_phase


func debug_get_closure_progress() -> float:
	return _closure_progress


func debug_get_archive_content() -> String:
	return "WEST GATE CLOSURE ORDER ISSUED BEFORE LOWER QUARTER CLEARANCE COMPLETE"


func debug_is_closure_archive_read() -> bool:
	return _closure_archive_read


func debug_get_closure_slab_position() -> Vector2:
	return closure_slab.position


func debug_get_closed_slab_position() -> Vector2:
	return _slab_open_position + SLAB_TRAVEL


func _build_evidence() -> void:
	var evidence := WorldEvidenceInteractable2D.new()
	evidence.name = "WestGateClosureOrder"
	evidence.evidence_id = &"west_gate_closure_order"
	evidence.title = "WEST GATE CLOSURE ORDER"
	evidence.body_text = "Closure order issued before Lower Quarter clearance was complete."
	evidence.position = cell_center(Vector2i(18, 7))
	evidence.evidence_recovered.connect(func(_id: StringName) -> void: _closure_archive_read = true)
	$POIRoot.add_child(evidence)


func _configure_slab() -> void:
	_slab_open_position = cell_center(Vector2i(31, 30))
	closure_slab.position = _slab_open_position
	var size := Vector2(8, 2) * AUTHORING_CELL_SIZE_WORLD
	var shape := RectangleShape2D.new()
	shape.size = size
	($DynamicGates/ClosureSlab/CollisionShape2D as CollisionShape2D).shape = shape
	var visual := $DynamicGates/ClosureSlab/Visual as Polygon2D
	visual.visible = false
	for index in 8:
		var tile := Sprite2D.new()
		tile.name = "GateTile_%02d" % index
		tile.texture = CIVIC_PRESENTER_SCRIPT.WALL
		tile.region_enabled = true
		tile.region_rect = Rect2(Vector2(7, 7) * 32.0, Vector2.ONE * 32.0)
		tile.position = Vector2((float(index) - 3.5) * 32.0, 0.0)
		closure_slab.add_child(tile)

func _build_production_presentation() -> void:
	var presenter: Node2D = CIVIC_PRESENTER_SCRIPT.new()
	presenter.name = "MeridianCivicArtPresenter"
	presenter.configure(MAP_ORIGIN, WALKABLE_REGIONS, &"west_gate_works")
	$BackgroundRoot.add_child(presenter)


func _on_gate_motor_repaired(_relay_id: StringName, repaired: bool) -> void:
	_gate_motor_repaired = repaired
	if repaired and _closure_phase != ClosurePhase.CLOSED:
		_closure_phase = ClosurePhase.CLOSING
		_begin_closure()


func _begin_closure() -> void:
	if _closure_tween != null and _closure_tween.is_valid():
		_closure_tween.kill()
	_closure_phase = ClosurePhase.CLOSING
	_closure_tween = create_tween()
	_closure_tween.tween_method(_set_closure_progress, _closure_progress, 1.0, CLOSURE_DURATION_SEC * (1.0 - _closure_progress))
	_closure_tween.tween_callback(_complete_closure)


func _set_closure_progress(value: float) -> void:
	_closure_progress = clampf(value, 0.0, 1.0)
	closure_slab.position = _slab_open_position + SLAB_TRAVEL * _closure_progress
	_update_navigation_slab()


func _complete_closure() -> void:
	_closure_phase = ClosurePhase.CLOSED
	_set_closure_progress(1.0)


func _apply_state(emit_relay_signals: bool) -> void:
	gate_motor.set_repaired(_gate_motor_repaired, emit_relay_signals)
	_set_closure_progress(_closure_progress)


func _update_navigation_slab() -> void:
	if authored_navigation == null:
		return
	var slab_cell_y := 30 + roundi(5.0 * _closure_progress)
	if slab_cell_y == _last_navigation_slab_y:
		return
	_last_navigation_slab_y = slab_cell_y
	authored_navigation.set_blocker(&"closure_slab", Rect2i(27, slab_cell_y, 8, 2), true)
