extends AuthoredLevel2D
class_name NpaShowcaseArena

const ROOM_HALF_WIDTH := 512.0
const ROOM_HALF_HEIGHT := 768.0
const ROOM_CENTERS := [-2048.0, -1024.0, 0.0, 1024.0, 2048.0]
const ROOM_DATA: Array[Dictionary] = [
	{"id": &"arrival", "label": "01 · ARRIVAL / ORIENTATION", "color": Color("#383c43")},
	{"id": &"reaction_parry", "label": "02 · REACTION / PARRY", "color": Color("#414047")},
	{"id": &"dash_pounce", "label": "03 · DASH / POUNCE", "color": Color("#3c4245")},
	{"id": &"allegiance_orders", "label": "04 · ALLEGIANCE / ORDERS", "color": Color("#42413c")},
	{"id": &"death_corpse_loot", "label": "05 · DEATH / CORPSE / LOOT", "color": Color("#403a3b")},
]
const ACTOR_SOCKETS: Array[Dictionary] = [
	{"id": &"broken_warrant", "node_name": "BrokenWarrantSocket", "position": Vector2(-1024.0, 32.0)},
	{"id": &"marine", "node_name": "MarineSocket", "position": Vector2(-96.0, -128.0)},
	{"id": &"savage", "node_name": "SavageSocket", "position": Vector2(96.0, 128.0)},
	{"id": &"vaultwing", "node_name": "VaultwingSocket", "position": Vector2(928.0, -128.0)},
	{"id": &"escort_frame_m7", "node_name": "EscortFrameM7Socket", "position": Vector2(1120.0, 128.0)},
]

const BOUNDARY_SEGMENTS := [
	[Vector2(-2560.0, -768.0), Vector2(2560.0, -768.0)],
	[Vector2(2560.0, -768.0), Vector2(2560.0, 768.0)],
	[Vector2(2560.0, 768.0), Vector2(-2560.0, 768.0)],
	[Vector2(-2560.0, 768.0), Vector2(-2560.0, -768.0)],
	[Vector2(-1536.0, -768.0), Vector2(-1536.0, -112.0)],
	[Vector2(-1536.0, 112.0), Vector2(-1536.0, 768.0)],
	[Vector2(-512.0, -768.0), Vector2(-512.0, -112.0)],
	[Vector2(-512.0, 112.0), Vector2(-512.0, 768.0)],
	[Vector2(512.0, -768.0), Vector2(512.0, -112.0)],
	[Vector2(512.0, 112.0), Vector2(512.0, 768.0)],
	[Vector2(1536.0, -768.0), Vector2(1536.0, -112.0)],
	[Vector2(1536.0, 112.0), Vector2(1536.0, 768.0)],
]

const AUTHORING_MARKERS := {
	"spawn": {
		"node_name": "Spawn_Main",
		"label": "MAIN ENTRY",
		"kind": "spawn",
		"position": Vector2(-2200.0, 0.0),
	},
	"return_main": {
		"node_name": "Return_Main",
		"label": "RETURN TO MAIN WORLD",
		"kind": "level_exit",
		"position": Vector2(-2200.0, 300.0),
	},
}


func _ready() -> void:
	super._ready()
	_build_walkable_zones()
	_build_actor_sockets()
	_build_safe_scenario_roots()


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS


func get_showcase_zone_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for room in ROOM_DATA:
		result.append(StringName(room["id"]))
	return result


func _build_walkable_zones() -> void:
	var background := get_node_or_null("BackgroundRoot") as Node2D
	if background == null:
		push_error("[NpaShowcaseArena] BackgroundRoot is missing")
		return
	for index in ROOM_DATA.size():
		var room: Dictionary = ROOM_DATA[index]
		var center_x: float = ROOM_CENTERS[index]
		var zone := Node2D.new()
		zone.name = "Zone_%s" % String(room["id"]).to_pascal_case()
		zone.position = Vector2(center_x, 0.0)
		zone.set_meta("zone_id", room["id"])
		zone.add_to_group("npa_showcase_zone")
		background.add_child(zone)
		var floor := Polygon2D.new()
		floor.name = "WalkableFloor"
		floor.polygon = PackedVector2Array([
			Vector2(-ROOM_HALF_WIDTH, -ROOM_HALF_HEIGHT),
			Vector2(ROOM_HALF_WIDTH, -ROOM_HALF_HEIGHT),
			Vector2(ROOM_HALF_WIDTH, ROOM_HALF_HEIGHT),
			Vector2(-ROOM_HALF_WIDTH, ROOM_HALF_HEIGHT),
		])
		floor.color = room["color"]
		floor.z_index = -20
		zone.add_child(floor)
		var title := Label.new()
		title.name = "ZoneTitle"
		title.text = str(room["label"])
		title.position = Vector2(-420.0, -690.0)
		title.add_theme_font_size_override("font_size", 26)
		title.modulate = Color("#d4cdb5")
		zone.add_child(title)
		_add_route_lane(zone)
	_add_boundary_dressing()


func _add_route_lane(zone: Node2D) -> void:
	var lane := Polygon2D.new()
	lane.name = "ConnectedWalkLane"
	lane.polygon = PackedVector2Array([
		Vector2(-ROOM_HALF_WIDTH, -96.0),
		Vector2(ROOM_HALF_WIDTH, -96.0),
		Vector2(ROOM_HALF_WIDTH, 96.0),
		Vector2(-ROOM_HALF_WIDTH, 96.0),
	])
	lane.color = Color(0.68, 0.62, 0.49, 0.13)
	lane.z_index = -18
	zone.add_child(lane)


func _add_boundary_dressing() -> void:
	var background := get_node_or_null("BackgroundRoot") as Node2D
	if background == null:
		return
	for index in BOUNDARY_SEGMENTS.size():
		var segment: Array = BOUNDARY_SEGMENTS[index]
		var rail := Line2D.new()
		rail.name = "ArenaRail_%02d" % index
		rail.points = PackedVector2Array([segment[0], segment[1]])
		rail.width = 18.0
		rail.default_color = Color("#77756c")
		rail.begin_cap_mode = Line2D.LINE_CAP_BOX
		rail.end_cap_mode = Line2D.LINE_CAP_BOX
		rail.z_index = -5
		background.add_child(rail)


func _build_actor_sockets() -> void:
	var sockets_root := get_node_or_null("EventMarkers/ActorSockets") as Node2D
	if sockets_root == null:
		sockets_root = Node2D.new()
		sockets_root.name = "ActorSockets"
		get_node("EventMarkers").add_child(sockets_root)
	for socket_data in ACTOR_SOCKETS:
		var socket := Marker2D.new()
		socket.name = str(socket_data["node_name"])
		socket.position = socket_data["position"]
		socket.set_meta("actor_id", socket_data["id"])
		socket.set_meta("empty_actor_socket", true)
		sockets_root.add_child(socket)
		var pad := Polygon2D.new()
		pad.name = "%s_Pad" % socket.name
		pad.polygon = _circle_polygon(36.0, 20)
		pad.position = socket.position
		pad.color = Color(0.82, 0.69, 0.38, 0.48)
		pad.z_index = -4
		get_node("PropsRoot").add_child(pad)
		var label := Label.new()
		label.name = "%s_Label" % socket.name
		label.text = String(socket_data["id"]).to_upper().replace("_", " ")
		label.position = socket.position + Vector2(-90.0, 42.0)
		label.add_theme_font_size_override("font_size", 14)
		label.modulate = Color("#cbc2a5")
		get_node("PropsRoot").add_child(label)


func _build_safe_scenario_roots() -> void:
	var root_node := get_node_or_null("EventRuntime/ScenarioRoots") as Node2D
	if root_node == null:
		root_node = Node2D.new()
		root_node.name = "ScenarioRoots"
		get_node("EventRuntime").add_child(root_node)
	for room in ROOM_DATA:
		var scenario_root := Node2D.new()
		scenario_root.name = "%sScenarioRoot" % String(room["id"]).to_pascal_case()
		scenario_root.set_meta("scenario_id", room["id"])
		scenario_root.process_mode = Node.PROCESS_MODE_DISABLED
		root_node.add_child(scenario_root)


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for index in points:
		var angle := TAU * float(index) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon
