class_name AshBellLowerQuarter
extends AuthoredLevel2D

const AUTHORING_CELL_SIZE_WORLD := 32.0
const MAP_SIZE_CELLS := Vector2i(128, 96)
const MAP_ORIGIN := Vector2(-2048.0, -1536.0)
const STATION_EXTERIOR_RECT := Rect2i(54, 58, 18, 14)
const DIRECT_BLOCKER_RECT := Rect2i(55, 71, 18, 4)
const WRONG_STREET_RECT := Rect2i(74, 30, 34, 24)
const ANSWERS_COURT_RECT := Rect2i(55, 8, 34, 22)

const WALKABLE_REGIONS: Array[Rect2i] = [
	Rect2i(52, 82, 24, 12), Rect2i(58, 70, 12, 14),
	Rect2i(38, 74, 22, 8), Rect2i(32, 48, 14, 32),
	Rect2i(16, 34, 46, 20), Rect2i(56, 36, 24, 14),
	Rect2i(74, 30, 34, 24), Rect2i(84, 18, 12, 14),
	Rect2i(55, 8, 34, 22), Rect2i(84, 16, 24, 10),
	Rect2i(98, 22, 10, 44), Rect2i(72, 58, 30, 10),
	Rect2i(4, 39, 14, 8),
]

var _evac_annunciator_repaired := false
var _gate_pressure_relay_repaired := false
var _station_ix_transit_interlock_repaired := false

@onready var blockout_grid := $PlayableRoot/BlockoutGrid as AuthoredBlockoutGrid2D
@onready var evac_shutter := $DynamicGates/EvacuationShutter as StaticBody2D
@onready var station_gate := $DynamicGates/StationIXInterlockGate as StaticBody2D
@onready var west_gate_exit := $Exits/Exit_WestGateWorks as GatedLevelExit2D
@onready var station_exit := $Exits/Exit_StationIX as GatedLevelExit2D
@onready var evac_relay := $POIRoot/EvacAnnunciator as CivicRelay2D
@onready var pressure_relay := $POIRoot/GatePressureRelay as CivicRelay2D
@onready var station_relay := $POIRoot/StationIXTransitInterlock as CivicRelay2D


func _ready() -> void:
	blockout_grid.position = MAP_ORIGIN
	blockout_grid.configure(
		AUTHORING_CELL_SIZE_WORLD,
		MAP_SIZE_CELLS,
		WALKABLE_REGIONS,
		[
			{"name": "civic_basin", "rect": Rect2i(61, 39, 10, 8), "color": Color("40565d")},
			{"name": "wrong_street_local", "rect": Rect2i(74, 30, 17, 24), "color": Color("555b60")},
			{"name": "wrong_street_ash_bell", "rect": Rect2i(91, 30, 17, 24), "color": Color("373653")},
			{"name": "eight_answers_court", "rect": ANSWERS_COURT_RECT, "color": Color("454c51")},
		]
	)
	_configure_authored_nodes()
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
		"spawn_from_world": {"kind": "spawn", "node_name": "Spawn_FromWorld", "position": cell_center(Vector2i(64, 87))},
		"spawn_from_west_gate": {"kind": "spawn", "node_name": "Spawn_FromWestGate", "position": cell_center(Vector2i(14, 43))},
		"spawn_from_station_ix": {"kind": "spawn", "node_name": "Spawn_FromStationIX", "position": cell_center(Vector2i(80, 65))},
		"return_world": {"kind": "exit", "node_name": "Exit_ReturnWorld", "position": cell_center(Vector2i(64, 91))},
		"west_gate": {"kind": "exit", "node_name": "Exit_WestGateWorks", "position": cell_center(Vector2i(6, 43))},
		"station_ix": {"kind": "exit", "node_name": "Exit_StationIX", "position": cell_center(Vector2i(74, 65))},
		"station_facade": {"kind": "landmark", "node_name": "StationIXFacade", "position": cell_center(Vector2i(63, 72))},
	}


func capture_route_state() -> Dictionary:
	return {
		"evac_annunciator_repaired": _evac_annunciator_repaired,
		"gate_pressure_relay_repaired": _gate_pressure_relay_repaired,
		"station_ix_transit_interlock_repaired": _station_ix_transit_interlock_repaired,
	}


func restore_route_state(state: Dictionary) -> bool:
	_evac_annunciator_repaired = bool(state.get("evac_annunciator_repaired", false))
	_gate_pressure_relay_repaired = bool(state.get("gate_pressure_relay_repaired", false))
	_station_ix_transit_interlock_repaired = bool(state.get("station_ix_transit_interlock_repaired", false))
	_apply_state(false)
	return true


func debug_get_answers_positions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in 9:
		result.append({"index": index + 1, "missing": index == 8})
	return result


func debug_get_content_strings() -> PackedStringArray:
	return PackedStringArray([
		"MERIDIAN PERSONNEL\nSTATION IX → DIRECT",
		"CIVIL EVACUATION\nLOWER QUARTER ↓",
		"PROVENANCE: LOCAL\nSOURCE INTEGRITY: HIGH",
		"CONTINUITY ORIGIN: ASH-BELL\nLOCAL MANUFACTURE RECORD: ABSENT",
		"ASH-BELL REGIONAL SYNCHRONIZATION\nI ANSWER\nII ANSWER\nIII ANSWER\nIV ANSWER\nV ANSWER\nVI ANSWER\nVII ANSWER\nVIII ANSWER\nIX UNARRIVAL",
	])


func _configure_authored_nodes() -> void:
	evac_relay.position = cell_center(Vector2i(39, 58))
	pressure_relay.position = cell_center(Vector2i(22, 42))
	station_relay.position = cell_center(Vector2i(89, 21))
	evac_relay.repaired_changed.connect(_on_relay_changed)
	pressure_relay.repaired_changed.connect(_on_relay_changed)
	station_relay.repaired_changed.connect(_on_relay_changed)
	_configure_blocker(evac_shutter, cell_center(Vector2i(39, 55)), Vector2(64, 256), Color("7b623d"))
	_configure_blocker(station_gate, cell_center(Vector2i(99, 56)), Vector2(288, 64), Color("7b623d"))
	_configure_blocker($DynamicGates/DirectPersonnelCollapse, _rect_center(DIRECT_BLOCKER_RECT), Vector2(DIRECT_BLOCKER_RECT.size) * AUTHORING_CELL_SIZE_WORLD, Color("574a43"))


func _build_blockout_labels() -> void:
	_add_blockout_label(
		"DirectRouteSign",
		"MERIDIAN PERSONNEL\nSTATION IX → DIRECT\n\nCIVIL EVACUATION\nLOWER QUARTER ↓",
		cell_center(Vector2i(56, 77)),
		Color("d7ddd8")
	)
	_add_blockout_label(
		"WrongStreetLocalEvidence",
		"PROVENANCE: LOCAL\nSOURCE INTEGRITY: HIGH",
		cell_center(Vector2i(76, 48)),
		Color("c8ceca")
	)
	_add_blockout_label(
		"WrongStreetImportedEvidence",
		"CONTINUITY ORIGIN: ASH-BELL\nLOCAL MANUFACTURE RECORD: ABSENT",
		cell_center(Vector2i(92, 48)),
		Color("aaa5d5")
	)
	_add_blockout_label(
		"AnswersCourtPanel",
		"ASH-BELL REGIONAL SYNCHRONIZATION\nI ANSWER  II ANSWER  III ANSWER  IV ANSWER\nV ANSWER  VI ANSWER  VII ANSWER  VIII ANSWER\nIX UNARRIVAL",
		cell_center(Vector2i(58, 11)),
		Color("d3dddc")
	)


func _add_blockout_label(node_name: String, text: String, at: Vector2, color: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = at
	label.modulate = color
	label.add_theme_font_size_override("font_size", 16)
	$PropsRoot.add_child(label)


func _position_pressure_markers() -> void:
	$EventMarkers/PressureSpawn_Arcade_A.position = cell_center(Vector2i(39, 65))
	$EventMarkers/PressureSpawn_Market_A.position = cell_center(Vector2i(28, 43))
	$EventMarkers/PressureSpawn_WrongStreet_A.position = cell_center(Vector2i(88, 42))
	$EventMarkers/PressureSpawn_AnswersCourt_A.position = cell_center(Vector2i(72, 20))


func _on_relay_changed(relay_id: StringName, repaired: bool) -> void:
	match relay_id:
		&"evac_annunciator": _evac_annunciator_repaired = repaired
		&"gate_pressure_relay": _gate_pressure_relay_repaired = repaired
		&"station_ix_transit_interlock": _station_ix_transit_interlock_repaired = repaired
	_apply_state(false)


func _apply_state(emit_relay_signals: bool) -> void:
	evac_relay.set_repaired(_evac_annunciator_repaired, emit_relay_signals)
	pressure_relay.set_repaired(_gate_pressure_relay_repaired, emit_relay_signals)
	station_relay.set_repaired(_station_ix_transit_interlock_repaired, emit_relay_signals)
	_set_blocker_open(evac_shutter, _evac_annunciator_repaired)
	_set_blocker_open(station_gate, _station_ix_transit_interlock_repaired)
	west_gate_exit.set_local_gate_open(_gate_pressure_relay_repaired)
	station_exit.set_local_gate_open(_station_ix_transit_interlock_repaired)


func _configure_blocker(body: StaticBody2D, center: Vector2, size: Vector2, color: Color) -> void:
	body.position = center
	var polygon := body.get_node("Visual") as Polygon2D
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		-size * 0.5, Vector2(size.x * 0.5, -size.y * 0.5),
		size * 0.5, Vector2(-size.x * 0.5, size.y * 0.5),
	])
	var shape := RectangleShape2D.new()
	shape.size = size
	(body.get_node("CollisionShape2D") as CollisionShape2D).shape = shape


func _set_blocker_open(body: StaticBody2D, open: bool) -> void:
	body.visible = not open
	(body.get_node("CollisionShape2D") as CollisionShape2D).disabled = open


func _rect_center(rect: Rect2i) -> Vector2:
	return MAP_ORIGIN + (Vector2(rect.position) + Vector2(rect.size) * 0.5) * AUTHORING_CELL_SIZE_WORLD


func _draw() -> void:
	# Station IX mass is deliberately close to the arrival view but not walkable.
	var station_rect := Rect2(MAP_ORIGIN + Vector2(STATION_EXTERIOR_RECT.position) * 32.0, Vector2(STATION_EXTERIOR_RECT.size) * 32.0)
	draw_rect(station_rect, Color("24292e"), true)
	draw_rect(station_rect, Color("bdc9ca"), false, 8.0)
	# Wrong Street incompatible utility alignment.
	draw_line(cell_center(Vector2i(91, 52)), cell_center(Vector2i(106, 31)), Color("7771aa"), 12.0)
	# Nine technical positions: I–VIII active, IX absent/damaged.
	for index in 9:
		var p := cell_center(Vector2i(59 + index * 3, 16))
		if index < 8:
			draw_circle(p, 18.0, Color(0.75, 0.84, 0.86, 0.72))
		else:
			draw_arc(p, 18.0, 0.0, TAU, 20, Color("5b3436"), 5.0)
