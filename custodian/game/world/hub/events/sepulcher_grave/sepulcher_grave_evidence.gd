class_name SepulcherGraveEvidence
extends Node2D

const LAYOUT := preload("res://game/world/hub/first_set/hub_first_set_layout.gd")
const CATALOG := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")

const EVENT_ID: StringName = &"hub_sepulcher_grave_v1"
const RECORD_SCHEMA := "custodian.hub_authored_event.sepulcher_grave.v1"
const INTERACTION_DISTANCE := 80.0
const GRAVE_POSITION: Vector2 = Vector2(-1984.0, -3200.0)
const READING_OFFSETS: Array[Vector2] = [
	Vector2(-320.0, 0.0),
	Vector2(448.0, 0.0),
	Vector2(448.0, 512.0),
]
const READING_IDS: Array[StringName] = [&"record_a", &"record_b", &"record_c"]
const READING_READOUTS: Array[String] = [
	"WEST FACE / CYCLE 184 · NINTH WATCH\nRECORD A: ELIAN VALE / WITNESS\n\nThe date is cut cleanly into the stone. A witness identity occupies the first line.",
	"NORTH APPROACH / CYCLE 184 · NINTH WATCH\nRECORD B: MARROW SEN / RELAY KEEPER\n\nThe date is unchanged. A different office and identity are entered beneath it.",
	"SOUTH APPROACH / CYCLE 184 · NINTH WATCH\nRECORD C: IDENTITY HELD / NO VERIFIED CLAIMANT\n\nThe date remains legible. The name field ends in an unresolved continuity mark.",
]

class InspectionPoint extends Node2D:
	var controller: Node
	var reading_index := -1

	func _ready() -> void:
		add_to_group("interactable")

	func can_interact(actor: Node) -> bool:
		return is_instance_valid(controller) \
			and bool(controller.call("can_inspect", reading_index, actor))

	func get_interaction_prompt() -> String:
		if not is_instance_valid(controller):
			return ""
		return str(controller.call("get_inspection_prompt", reading_index))

	func get_interaction_position() -> Vector2:
		return global_position

	func get_interaction_distance() -> float:
		return INTERACTION_DISTANCE

	func interact(actor: Node) -> void:
		if is_instance_valid(controller):
			controller.call("inspect", reading_index, actor)

	func _draw() -> void:
		var active := is_instance_valid(controller) \
			and int(controller.call("get_completed_readings")) == reading_index
		var stone_color := Color("aaa58d") if active else Color("777b72")
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-20.0, 10.0), Vector2(-13.0, -14.0),
				Vector2(13.0, -14.0), Vector2(20.0, 10.0),
			]), stone_color
		)
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 32, Color("d3c897") if active else Color("656b62"), 2.0)
		var font := ThemeDB.fallback_font
		if font != null:
			draw_string(
				font, Vector2(-5.0, 6.0), String(READING_IDS[reading_index]).right(1).to_upper(),
				HORIZONTAL_ALIGNMENT_CENTER, 12.0, 16, Color("272b2a")
			)


var _hub_state: HubState
var _hub_map: CanvasItem
var _event_record: Dictionary = {}
var _inspection_points: Array[InspectionPoint] = []


func configure(hub_state: HubState, hub_map: CanvasItem) -> void:
	_hub_state = hub_state
	_hub_map = hub_map


func get_inspection_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for offset in READING_OFFSETS:
		positions.append(GRAVE_POSITION + offset)
	return positions


func get_inspection_point(reading_index: int) -> Node2D:
	if reading_index < 0 or reading_index >= _inspection_points.size():
		return null
	return _inspection_points[reading_index]


func get_inspection_readout(reading_index: int) -> String:
	if reading_index < 0 or reading_index >= READING_READOUTS.size():
		return ""
	return READING_READOUTS[reading_index]


func get_completed_readings() -> int:
	return int(_event_record.get("completed_readings", 0))


func get_event_snapshot() -> Dictionary:
	return {
		"event_id": EVENT_ID,
		"completed_readings": get_completed_readings(),
		"last_reading_id": str(_event_record.get("last_reading_id", "")),
		"inspection_positions": get_inspection_positions(),
	}


func can_inspect(reading_index: int, actor: Node) -> bool:
	return _hub_state != null \
		and _hub_map != null \
		and _hub_map.is_visible_in_tree() \
		and is_instance_valid(actor) \
		and actor.is_in_group("player") \
		and reading_index == get_completed_readings() \
		and reading_index >= 0 \
		and reading_index < READING_READOUTS.size()


func get_inspection_prompt(reading_index: int) -> String:
	if reading_index != get_completed_readings() \
		or reading_index < 0 \
		or reading_index >= READING_READOUTS.size():
		return ""
	return "INSPECT THE GRAVE · READING %d OF 3" % (reading_index + 1)


func inspect(reading_index: int, actor: Node) -> void:
	if not can_inspect(reading_index, actor) or not actor is Node2D:
		return
	var point := get_inspection_point(reading_index)
	if not is_instance_valid(point) \
		or (actor as Node2D).global_position.distance_to(point.global_position) > INTERACTION_DISTANCE:
		return

	var next_count := reading_index + 1
	_event_record["completed_readings"] = next_count
	_event_record["last_reading_id"] = String(READING_IDS[reading_index])
	if not _hub_state.set_authored_event_record(EVENT_ID, _event_record):
		_event_record["completed_readings"] = reading_index
		_event_record["last_reading_id"] = String(READING_IDS[reading_index - 1]) if reading_index > 0 else ""
		return
	for inspection_point in _inspection_points:
		inspection_point.queue_redraw()
	_show_readout(reading_index)


func _ready() -> void:
	if _hub_state == null or _hub_map == null:
		push_error("[SepulcherGraveEvidence] HubState and the active Hub map are required")
		return
	_event_record = _normalize_record(_hub_state.get_authored_event_record(EVENT_ID))
	for reading_index in READING_READOUTS.size():
		var point := InspectionPoint.new()
		point.name = "InspectionPoint_%s" % String(READING_IDS[reading_index]).to_pascal_case()
		point.controller = self
		point.reading_index = reading_index
		point.position = get_inspection_positions()[reading_index]
		add_child(point)
		_inspection_points.append(point)


func _draw() -> void:
	draw_rect(Rect2(GRAVE_POSITION + Vector2(-62.0, -34.0), Vector2(124.0, 68.0)), Color("343b38"), true)
	draw_rect(Rect2(GRAVE_POSITION + Vector2(-50.0, -24.0), Vector2(100.0, 48.0)), Color("898878"), true)
	draw_line(GRAVE_POSITION + Vector2(-39.0, -8.0), GRAVE_POSITION + Vector2(39.0, -8.0), Color("d0c9a8"), 2.0)
	draw_line(GRAVE_POSITION + Vector2(-26.0, 8.0), GRAVE_POSITION + Vector2(26.0, 8.0), Color("676b61"), 2.0)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, GRAVE_POSITION + Vector2(-54.0, 51.0), "SEPULCHER", HORIZONTAL_ALIGNMENT_CENTER, 108.0, 14, Color("d9d4bf"))


func _normalize_record(record: Dictionary) -> Dictionary:
	var schema := str(record.get("schema", ""))
	if not schema.is_empty() and schema != RECORD_SCHEMA:
		return _default_record()
	var completed := clampi(int(record.get("completed_readings", 0)), 0, READING_READOUTS.size())
	return {
		"schema": RECORD_SCHEMA,
		"completed_readings": completed,
		"last_reading_id": String(READING_IDS[completed - 1]) if completed > 0 else "",
	}


func _default_record() -> Dictionary:
	return {
		"schema": RECORD_SCHEMA,
		"completed_readings": 0,
		"last_reading_id": "",
	}


func _show_readout(reading_index: int) -> void:
	var hud := get_node_or_null("/root/GameRoot/CustodianHUD")
	if hud == null:
		return
	var title := "GRAVE INSCRIPTION · READING %d OF 3" % (reading_index + 1)
	var body := READING_READOUTS[reading_index]
	if hud.has_method("show_latched_interaction"):
		hud.call("show_latched_interaction", title, body, _interaction_key(), CATALOG.ICON_OBJECTIVE, get_inspection_point(reading_index), 4.0)
	else:
		hud.call("show_interaction", title, body, _interaction_key(), CATALOG.ICON_OBJECTIVE)


func _interaction_key() -> String:
	if not InputMap.has_action("interact"):
		return "G"
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			return OS.get_keycode_string(
				key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			)
	return "G"
