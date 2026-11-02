class_name AshBellStationIX
extends AuthoredLevel2D

const CIVIC_PRESENTER_SCRIPT := preload("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd")
const CIVIC_RELAY := preload("res://content/sprites/environment/props/ash_bell/common/meridian_civic_relay/runtime/body/meridian_civic_relay__body__interaction__idle__omni__1f__96.png")
const SYNC_CORE := preload("res://content/sprites/environment/props/ash_bell/station_ix/station_ix_sync_core/runtime/body/station_ix_sync_core__body__interaction__idle__omni__1f__384x320.png")
const RECEIVER_SHEET := preload("res://content/sprites/environment/props/ash_bell/station_ix/station_ix_receiver/runtime/body/station_ix_receiver__body__interaction__active__omni__8f__96.png")

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
@onready var authored_navigation := $NavigationRoot/AuthoredNavigationProvider as AuthoredNavigationProvider2D
var _receiver: AnimatedSprite2D
var _sync_core: Sprite2D


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
	blockout_grid.visible = false
	for relay in [assembly_a, assembly_b, assembly_c]: relay.presentation_texture = CIVIC_RELAY
	authored_navigation.configure(blockout_grid)
	assembly_a.position = cell_center(Vector2i(24, 33))
	assembly_b.position = cell_center(Vector2i(40, 33))
	assembly_c.position = cell_center(Vector2i(32, 18))
	assembly_a.repaired_changed.connect(_on_assembly_changed)
	assembly_b.repaired_changed.connect(_on_assembly_changed)
	assembly_c.repaired_changed.connect(_on_assembly_changed)
	_build_blockout_labels()
	_build_production_presentation()
	_build_evidence()
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
	var evidence := get_node_or_null("POIRoot/NinthAnswerAfterAction") as WorldEvidenceInteractable2D
	if evidence != null:
		evidence.set_recovered(_answer_archive_recovered)
	return true


func debug_get_final_status_content() -> String:
	return FINAL_STATUS_CONTENT


func debug_get_pre_isolation_content() -> String:
	return "RETURN-PATH CONTACT: UNRESOLVED\nRECIPROCAL ADDRESS: UNRESOLVED\nDO NOT COMPLETE HANDSHAKE"


func debug_get_one_shot_completion_count() -> int:
	return _one_shot_completion_count


func is_station_isolated() -> bool:
	return _station_isolated


func debug_is_answer_archive_recovered() -> bool:
	return _answer_archive_recovered


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
	if _receiver != null:
		if _station_isolated:
			_receiver.stop()
			_receiver.frame = 0
		elif not _receiver.is_playing():
			_receiver.play(&"active")
		_receiver.modulate = Color(0.58, 0.66, 0.68, 0.72) if _station_isolated else Color(0.85, 0.94, 1.0, 1.0)
	if _sync_core != null:
		_sync_core.modulate = Color(0.7, 0.78, 0.8, 0.9) if _station_isolated else Color(1.0, 0.88, 0.66, 1.0)
	queue_redraw()
	var status_label := get_node_or_null("PropsRoot/StationStatus") as Label
	if status_label != null:
		status_label.text = FINAL_STATUS_CONTENT if _station_isolated else debug_get_pre_isolation_content()
	var final_record := get_node_or_null("POIRoot/NinthAnswerAfterAction") as WorldEvidenceInteractable2D
	if final_record != null:
		final_record.set_actionable(_station_isolated)


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


func _build_evidence() -> void:
	_add_evidence(&"orra_duty_record", "STATION IX DUTY RECORD", "PRECENTOR ORRA\nDIRECT ASSIGNMENT: STATION IX", Vector2i(18, 37), false)
	_add_evidence(&"shelter_tally", "EMERGENCY SHELTER TALLY", "Civilian admissions recorded under Precentor Orra's authority.", Vector2i(45, 36), false)
	_add_evidence(&"missed_response_record", "RESPONSE WINDOW LOG", "STATION IX missed its required response window. STATUS: UNARRIVAL.", Vector2i(25, 27), false)
	_add_evidence(&"ninth_answer_after_action", "NINTH ANSWER — AFTER ACTION", "LATE RESPONSE: ACCEPTED\nREGIONAL COUPLING: TERMINATED", Vector2i(32, 9), true)


func _add_evidence(id: StringName, evidence_title: String, content: String, cell: Vector2i, final_record: bool) -> void:
	var evidence := WorldEvidenceInteractable2D.new()
	evidence.name = String(id).to_pascal_case()
	evidence.evidence_id = id
	evidence.title = evidence_title
	evidence.body_text = content
	evidence.position = cell_center(cell)
	if final_record:
		evidence.evidence_recovered.connect(func(_id: StringName) -> void: _answer_archive_recovered = true)
		evidence.set_actionable(_station_isolated)
	$POIRoot.add_child(evidence)


func _position_pressure_markers() -> void:
	$EventMarkers/PressureSpawn_AssemblyA_01.position = cell_center(Vector2i(22, 35))
	$EventMarkers/PressureSpawn_AssemblyA_02.position = cell_center(Vector2i(28, 31))
	$EventMarkers/PressureSpawn_AssemblyB_01.position = cell_center(Vector2i(42, 35))
	$EventMarkers/PressureSpawn_AssemblyB_02.position = cell_center(Vector2i(47, 32))
	$EventMarkers/PressureSpawn_AssemblyC_01.position = cell_center(Vector2i(28, 20))
	$EventMarkers/PressureSpawn_AssemblyC_02.position = cell_center(Vector2i(36, 20))

func _build_production_presentation() -> void:
	var presenter: Node2D = CIVIC_PRESENTER_SCRIPT.new()
	presenter.name = "MeridianCivicArtPresenter"
	presenter.configure(MAP_ORIGIN, WALKABLE_REGIONS, &"station_ix")
	$BackgroundRoot.add_child(presenter)
	_sync_core = Sprite2D.new()
	_sync_core.name = "StationIXSyncCore"
	_sync_core.texture = SYNC_CORE
	_sync_core.position = cell_center(Vector2i(32, 16))
	$PropsRoot.add_child(_sync_core)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"active")
	frames.set_animation_speed(&"active", 9.0)
	frames.set_animation_loop(&"active", true)
	for index in 8:
		var atlas := AtlasTexture.new()
		atlas.atlas = RECEIVER_SHEET
		atlas.region = Rect2(index * 96, 0, 96, 96)
		frames.add_frame(&"active", atlas)
	_receiver = AnimatedSprite2D.new()
	_receiver.name = "ActiveReceiver"
	_receiver.sprite_frames = frames
	_receiver.animation = &"active"
	_receiver.position = cell_center(Vector2i(32, 11))
	_receiver.play()
	$PropsRoot.add_child(_receiver)


func _draw() -> void:
	pass
