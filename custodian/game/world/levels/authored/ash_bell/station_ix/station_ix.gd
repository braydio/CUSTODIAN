class_name AshBellStationIX
extends AuthoredLevel2D

const AUTHORING_CELL_SIZE_WORLD := 32.0
const MAP_SIZE_CELLS := Vector2i(64, 56)
const MAP_ORIGIN := Vector2(-1024.0, -896.0)
const FINAL_STATUS_CONTENT := "STATION IX\nRESPONSE WINDOW: MISSED\nSTATUS: UNARRIVAL\nLATE RESPONSE:\nACCEPTED\nREGIONAL COUPLING:\nTERMINATED"
const WALKABLE_REGIONS: Array[Rect2i] = [
	Rect2i(24, 44, 16, 10), Rect2i(8, 32, 20, 12),
	Rect2i(22, 24, 20, 16), Rect2i(40, 30, 16, 12),
	Rect2i(15, 2, 34, 28), Rect2i(30, 39, 4, 6),
]

var _assembly_a_repaired := false
var _assembly_b_repaired := false
var _assembly_c_repaired := false
var _station_isolated := false
var _answer_archive_recovered := false
var _one_shot_completion_count := 0

@onready var blockout_grid := $PlayableRoot/BlockoutGrid as AuthoredBlockoutGrid2D
@onready var assembly_a := $POIRoot/AssemblyA as CivicRelay2D
@onready var assembly_b := $POIRoot/AssemblyB as CivicRelay2D
@onready var assembly_c := $POIRoot/AssemblyC as CivicRelay2D


func _ready() -> void:
	blockout_grid.position = MAP_ORIGIN
	blockout_grid.configure(
		AUTHORING_CELL_SIZE_WORLD,
		MAP_SIZE_CELLS,
		WALKABLE_REGIONS,
		[
			{"name": "answer_chamber", "rect": Rect2i(15, 2, 34, 28), "color": Color("41494d")},
			{"name": "sync_plant", "rect": Rect2i(22, 24, 20, 16), "color": Color("35454a")},
		]
	)
	assembly_a.position = cell_center(Vector2i(24, 33))
	assembly_b.position = cell_center(Vector2i(40, 33))
	assembly_c.position = cell_center(Vector2i(32, 18))
	assembly_a.repaired_changed.connect(_on_assembly_changed)
	assembly_b.repaired_changed.connect(_on_assembly_changed)
	assembly_c.repaired_changed.connect(_on_assembly_changed)
	_build_blockout_labels()
	_position_pressure_markers()
	super._ready()
	_apply_state(false)
	queue_redraw()


func cell_center(cell: Vector2i) -> Vector2:
	return MAP_ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * AUTHORING_CELL_SIZE_WORLD


func get_boundary_segments() -> Array:
	return blockout_grid.get_boundary_segments() if blockout_grid != null else []


func get_authoring_markers() -> Dictionary:
	return {
		"spawn_from_lower_quarter": {"kind": "spawn", "node_name": "Spawn_FromLowerQuarter", "position": cell_center(Vector2i(32, 50))},
		"backtrack": {"kind": "exit", "node_name": "Exit_Backtrack", "position": cell_center(Vector2i(32, 53))},
		"precentor_orra_record": {"kind": "poi", "node_name": "PrecentorOrraRecord", "position": cell_center(Vector2i(18, 37))},
	}


func capture_route_state() -> Dictionary:
	return {
		"assembly_a_repaired": _assembly_a_repaired,
		"assembly_b_repaired": _assembly_b_repaired,
		"assembly_c_repaired": _assembly_c_repaired,
		"station_isolated": _station_isolated,
		"answer_archive_recovered": _answer_archive_recovered,
	}


func restore_route_state(state: Dictionary) -> bool:
	_assembly_a_repaired = bool(state.get("assembly_a_repaired", false))
	_assembly_b_repaired = bool(state.get("assembly_b_repaired", false))
	_assembly_c_repaired = bool(state.get("assembly_c_repaired", false))
	_station_isolated = bool(state.get("station_isolated", false))
	_answer_archive_recovered = bool(state.get("answer_archive_recovered", false))
	_apply_state(false)
	return true


func debug_get_final_status_content() -> String:
	return FINAL_STATUS_CONTENT


func debug_get_pre_isolation_content() -> String:
	return "RETURN-PATH CONTACT: UNRESOLVED\nRECIPROCAL ADDRESS: UNRESOLVED\nDO NOT COMPLETE HANDSHAKE"


func debug_get_one_shot_completion_count() -> int:
	return _one_shot_completion_count


func is_station_isolated() -> bool:
	return _station_isolated


func _on_assembly_changed(relay_id: StringName, repaired: bool) -> void:
	match relay_id:
		&"assembly_a": _assembly_a_repaired = repaired
		&"assembly_b": _assembly_b_repaired = repaired
		&"assembly_c":
			_assembly_c_repaired = repaired
			if repaired and not _station_isolated:
				_station_isolated = true
				_one_shot_completion_count += 1
	_apply_state(false)


func _apply_state(emit_relay_signals: bool) -> void:
	assembly_a.set_repaired(_assembly_a_repaired, emit_relay_signals)
	assembly_b.set_repaired(_assembly_b_repaired, emit_relay_signals)
	assembly_c.set_repaired(_assembly_c_repaired, emit_relay_signals)
	assembly_a.set_actionable(not _assembly_a_repaired)
	assembly_b.set_actionable(_assembly_a_repaired and not _assembly_b_repaired)
	assembly_c.set_actionable(_assembly_b_repaired and not _assembly_c_repaired)
	queue_redraw()
	var status_label := get_node_or_null("PropsRoot/StationStatus") as Label
	if status_label != null:
		status_label.text = FINAL_STATUS_CONTENT if _station_isolated else debug_get_pre_isolation_content()


func _build_blockout_labels() -> void:
	var workplace := Label.new()
	workplace.name = "DutyBoard"
	workplace.text = "MERIDIAN OFFICE — STATION IX\nDUTY PRECENTOR: PRECENTOR ORRA"
	workplace.position = cell_center(Vector2i(26, 48))
	workplace.modulate = Color("ced8d5")
	workplace.add_theme_font_size_override("font_size", 16)
	$PropsRoot.add_child(workplace)
	var status := Label.new()
	status.name = "StationStatus"
	status.position = cell_center(Vector2i(22, 8))
	status.modulate = Color("c7d8d8")
	status.add_theme_font_size_override("font_size", 16)
	$PropsRoot.add_child(status)


func _position_pressure_markers() -> void:
	$EventMarkers/PressureSpawn_AssemblyA_01.position = cell_center(Vector2i(22, 35))
	$EventMarkers/PressureSpawn_AssemblyA_02.position = cell_center(Vector2i(28, 31))
	$EventMarkers/PressureSpawn_AssemblyB_01.position = cell_center(Vector2i(42, 35))
	$EventMarkers/PressureSpawn_AssemblyB_02.position = cell_center(Vector2i(47, 32))
	$EventMarkers/PressureSpawn_AssemblyC_01.position = cell_center(Vector2i(28, 20))
	$EventMarkers/PressureSpawn_AssemblyC_02.position = cell_center(Vector2i(36, 20))


func _draw() -> void:
	# Workplace-first blockout fixtures at Ground Intake.
	for index in 6:
		var locker := Rect2(cell_center(Vector2i(25 + index * 2, 47)) - Vector2(12, 22), Vector2(24, 44))
		draw_rect(locker, Color("566168"), true)
	# Restrained answer chamber status; final isolation adds a cold-white ring.
	var chamber_center := cell_center(Vector2i(32, 16))
	draw_arc(chamber_center, 220.0, 0.0, TAU, 48, Color("95a8aa"), 5.0)
	if _station_isolated:
		draw_arc(chamber_center, 170.0, 0.0, TAU, 48, Color(0.76, 0.88, 0.9, 0.8), 8.0)
