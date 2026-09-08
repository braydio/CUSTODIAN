extends Node2D
class_name AwakeningFirstReturn

## CUSTODIAN Awakening / The First Return — orchestration for sections 01-10.
##
## This controller owns progression, HUD state, and one-shot presentation beats.
## It owns no geometry: every coordinate comes from AwakeningLayout, and the
## blockout bodies are built from that same authority at _ready.
##
## The Field Terminal, Ashen Forum, Continuity Port, first Contract, and the
## campaign handoff belong to later sections and are deliberately absent here.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const Catalog := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const Palette := preload("res://game/ui/theme/black_reliquary_palette.gd")
const Plaque := preload("res://game/world/awakening/awakening_plaque_interactable.gd")
const TransitLift := preload("res://game/world/awakening/awakening_transit_lift.gd")
const RECOVERY_ALCOVE_IDLE := preload("res://content/sprites/environment/props/awakening/awakening_creche_recovery_alcove/runtime/body/awakening_creche_recovery_alcove__body__state__idle__omni__1f__192x256.png")
const RECOVERY_ALCOVE_WAKE := preload("res://content/sprites/environment/props/awakening/awakening_creche_recovery_alcove/runtime/body/awakening_creche_recovery_alcove__body__interaction__wake__omni__8f__192x256.png")
const GATE_BODY_IDLE_SEALED := preload("res://content/sprites/environment/props/awakening/gate_of_dust/runtime/body/gate_of_dust__body__state__idle_sealed__omni__1f__768x512.png")
const GATE_WEST_PYLON := preload("res://content/sprites/environment/props/awakening/gate_of_dust/runtime/body/gate_of_dust__body__component__west_pylon__omni__1f__256x512.png")
const GATE_EAST_PYLON := preload("res://content/sprites/environment/props/awakening/gate_of_dust/runtime/body/gate_of_dust__body__component__east_pylon__omni__1f__256x512.png")
const GATE_SEALED_APERTURE := preload("res://content/sprites/environment/props/awakening/gate_of_dust/runtime/body/gate_of_dust__body__component__sealed_aperture__omni__1f__512.png")
const GATE_REST_THRESHOLD := preload("res://content/sprites/environment/props/awakening/gate_of_dust/runtime/body/gate_of_dust__body__component__rest_threshold__omni__1f__128x160.png")

const OBJECTIVE_RECOVERY := "Wake and read the crèche console"
const OBJECTIVE_RETURN_TO_POST := "RETURN TO POST"

const CRECHE_READOUT := "FIELD RECALL DETECTED\nCUSTODIAN AUTHORITY: VALID\nPERSONAL CONTINUITY: UNRESOLVED\n\nRETURN TO SERVICE"
const CRECHE_READOUT_AGAIN := "CUSTODIAN AUTHORITY: VALID\nPERSONAL CONTINUITY: UNRESOLVED\n\nRETURN TO SERVICE"
const PORT_READOUT := "PORT AUTHORITY: SUSPENDED\nROUTE INDEX: UNAVAILABLE\nPOST STATUS: UNMANNED"

signal zone_entered(zone_id: StringName, index: int)
signal console_acknowledged()
signal sidearm_recovered()
signal blockout_completed()

@export var build_blockout_presentation := true

@onready var world: Node2D = $World
@onready var zones_root: Node2D = $World/AwakeningZones
@onready var operator_ref: Node2D = get_node_or_null("World/Operator") as Node2D
@onready var camera_ref: Camera2D = get_node_or_null("World/Camera2D") as Camera2D
@onready var hud: Node = get_node_or_null("CustodianHUD")

var current_zone_index := 1
var visited_zones := {}
var completed := false
var opening_console_acknowledged := false
var p9_recovered := false

var _zone_bodies := {}
var _fired_reveals := {}
var _occupied_zones := {}
var _transit_lift: Node = null
var _recovery_alcove: AnimatedSprite2D = null
var _reveal_release_pending := false


func _ready() -> void:
	_build_world_geometry()
	_build_hero_presentation()
	_build_interactables()
	_build_triggers()
	_place_operator()
	_apply_camera_bounds()
	_configure_hud()
	_enter_zone(&"zone01_creche")


func _place_operator() -> void:
	if operator_ref != null:
		operator_ref.global_position = Layout.OPERATOR_WAKE_POSITION


func _apply_camera_bounds() -> void:
	# AwakeningFirstReturn owns the combined world bounds; the Road instance is
	# configured with apply_camera_bounds = false so it cannot clamp us to itself.
	if camera_ref != null and camera_ref.has_method("set_authored_map_bounds"):
		camera_ref.call("set_authored_map_bounds", Layout.WORLD_BOUNDS)


# --- Geometry construction ---------------------------------------------------

func _build_world_geometry() -> void:
	if zones_root == null:
		push_error("[AwakeningFirstReturn] World/AwakeningZones missing")
		return
	for zone in Layout.ZONES:
		var zone_id := StringName(zone["id"])
		var node_name := String(zone["node"])
		var zone_node := zones_root.get_node_or_null(NodePath(node_name)) as Node2D
		if zone_node == null:
			zone_node = Node2D.new()
			zone_node.name = node_name
			zones_root.add_child(zone_node)
		_build_zone(zone_node, zone_id, zone)
	_build_traversal_presentation()
	_build_south_reach_barrier()


func _build_zone(zone_node: Node2D, zone_id: StringName, zone: Dictionary) -> void:
	var art_underlay := _ensure_child(zone_node, "ArtUnderlay", Node2D.new())
	art_underlay.z_index = Layout.Z_FLOOR - 1
	var presentation := _ensure_child(zone_node, "BlockoutPresentation", Node2D.new())
	presentation.visible = build_blockout_presentation and art_underlay.get_node_or_null("Underlay") == null
	var collision := _ensure_child(zone_node, "Collision", StaticBody2D.new()) as StaticBody2D
	_ensure_child(zone_node, "Occlusion", Node2D.new()).z_index = Layout.Z_FOREGROUND
	_ensure_child(zone_node, "SetPieces", Node2D.new())
	_ensure_child(zone_node, "Interactables", Node2D.new())
	_ensure_child(zone_node, "Triggers", Node2D.new())
	var markers := _ensure_child(zone_node, "Markers", Node2D.new())
	_ensure_child(zone_node, "Audio", Node2D.new())

	# Section 10 reuses the Road prototype's own floor art and collision.
	if zone_id != &"zone10_road_south_reach":
		_build_floor(presentation, collision, zone_id, zone)
		_build_set_pieces(presentation, collision, zone_id)
	_build_markers(markers, zone_id)
	_build_zone_region(zone_node, zone_id, zone)
	_zone_bodies[zone_id] = collision


func _build_floor(presentation: Node2D, collision: StaticBody2D, zone_id: StringName, zone: Dictionary) -> void:
	var envelope: Rect2 = zone["envelope"]
	# Solid architecture fills the envelope; the walkable floor is punched out of
	# it, so anything not authored as floor reads and collides as wall.
	var wall := Polygon2D.new()
	wall.name = "EnvelopeWall"
	wall.polygon = Layout.rect_to_polygon(envelope)
	wall.color = Layout.COLOR_DEEP_WALL
	wall.z_index = Layout.Z_FLOOR
	presentation.add_child(wall)

	for index in Layout.floors_for(zone_id).size():
		var area: Variant = Layout.floors_for(zone_id)[index]
		var polygon := Layout.rect_to_polygon(area) if area is Rect2 else Layout.to_polygon(area as Array)
		var floor_poly := Polygon2D.new()
		floor_poly.name = "Floor_%02d" % index
		floor_poly.polygon = polygon
		floor_poly.color = Layout.COLOR_FLOOR
		floor_poly.z_index = Layout.Z_FLOOR
		presentation.add_child(floor_poly)
		_add_wall_facade(presentation, polygon, "FloorFacade_%02d" % index)

	for index in Layout.VOID_POLYGONS.get(zone_id, []).size():
		var hole := Layout.to_polygon(Layout.VOID_POLYGONS[zone_id][index] as Array)
		var void_poly := Polygon2D.new()
		void_poly.name = "Void_%02d" % index
		void_poly.polygon = hole
		void_poly.color = Layout.COLOR_VOID
		void_poly.z_index = Layout.Z_WORLD_PROPS
		presentation.add_child(void_poly)
		var body := CollisionPolygon2D.new()
		body.name = "VoidCollision_%02d" % index
		body.polygon = hole
		collision.add_child(body)

	_build_envelope_walls(collision, zone_id, envelope)


## Collision for "everything in the envelope that is not walkable". Built as a
## coarse 32px occupancy sweep so irregular octagonal rooms wall themselves
## correctly without hand-authored wall segments.
func _build_envelope_walls(collision: StaticBody2D, zone_id: StringName, envelope: Rect2) -> void:
	var step := Layout.WORLD_TILE
	var cols := int(ceil(envelope.size.x / step))
	var rows := int(ceil(envelope.size.y / step))
	for row in rows:
		var run_start := -1
		for col in range(cols + 1):
			var solid := false
			if col < cols:
				var centre := envelope.position + Vector2((col + 0.5) * step, (row + 0.5) * step)
				solid = not Layout.is_point_walkable(centre)
			if solid and run_start < 0:
				run_start = col
			elif not solid and run_start >= 0:
				var shape := CollisionShape2D.new()
				var rectangle := RectangleShape2D.new()
				rectangle.size = Vector2((col - run_start) * step, step)
				shape.shape = rectangle
				shape.position = envelope.position + Vector2(
					(run_start + (col - run_start) * 0.5) * step,
					(row + 0.5) * step
				)
				shape.name = "Wall_%s_%02d_%02d" % [String(zone_id).substr(0, 6), row, run_start]
				collision.add_child(shape)
				run_start = -1


func _add_wall_facade(presentation: Node2D, polygon: PackedVector2Array, node_name: String) -> void:
	# South-facing edges get a shallow facade band so the blockout reads as 2.5D
	# architecture rather than a flat floor plan.
	var facade := Line2D.new()
	facade.name = node_name
	facade.width = Layout.WALL_CAP_DEPTH
	facade.default_color = Layout.COLOR_ELEVATED_FACADE
	facade.z_index = Layout.Z_WORLD_PROPS
	facade.closed = true
	facade.points = polygon
	presentation.add_child(facade)


func _build_set_pieces(presentation: Node2D, collision: StaticBody2D, zone_id: StringName) -> void:
	for piece in Layout.set_pieces_for(zone_id):
		# Prop-backed set pieces are instanced in the .tscn and bring their own
		# art and collision; the layout lists them only so the geometry validator
		# accounts for them.
		if bool(piece.get("prop", false)):
			continue
		var rect := Layout.set_piece_rect(piece)
		var visual := Polygon2D.new()
		visual.name = String(piece.get("id", "set_piece"))
		visual.polygon = Layout.rect_to_polygon(rect)
		visual.color = Layout.COLOR_ELEVATED_FACADE if bool(piece.get("blocking", false)) else Layout.COLOR_DUST
		visual.z_index = Layout.Z_WORLD_PROPS
		presentation.add_child(visual)
		if not bool(piece.get("blocking", false)):
			continue
		# Locked traversal geometry always wins over a set piece.
		if _overlaps_traversal(rect):
			continue
		var shape := CollisionShape2D.new()
		shape.name = "%s_body" % String(piece.get("id", "set_piece"))
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		shape.position = rect.get_center()
		collision.add_child(shape)


func _overlaps_traversal(rect: Rect2) -> bool:
	for traversal in Layout.traversal_rects():
		if traversal.intersects(rect): return true
	return false


func _build_markers(markers: Node2D, zone_id: StringName) -> void:
	for marker in Layout.markers_for(zone_id):
		var node := Marker2D.new()
		node.name = String(marker.get("id", "marker"))
		node.position = marker.get("position", Vector2.ZERO)
		node.set_meta("label", String(marker.get("label", "")))
		node.set_meta("kind", String(marker.get("kind", "marker")))
		markers.add_child(node)


func _build_zone_region(zone_node: Node2D, zone_id: StringName, zone: Dictionary) -> void:
	var region := _ensure_child(zone_node, "ZoneRegion", Area2D.new()) as Area2D
	region.monitoring = false
	region.monitorable = false
	region.collision_layer = 0
	region.collision_mask = 0
	if region.get_node_or_null("Shape") == null:
		var envelope: Rect2 = zone["envelope"]
		var shape := CollisionShape2D.new()
		shape.name = "Shape"
		var rectangle := RectangleShape2D.new()
		rectangle.size = envelope.size
		shape.shape = rectangle
		shape.position = envelope.get_center()
		region.add_child(shape)
	region.set_meta("zone_id", zone_id)


## Connectors and thresholds are drawn as floor so the locked route reads as one
## continuous space, and are carved out of collision by _overlaps_traversal.
func _build_traversal_presentation() -> void:
	var root := _ensure_child(zones_root, "Traversal", Node2D.new())
	for rect in Layout.traversal_rects():
		var poly := Polygon2D.new()
		poly.polygon = Layout.rect_to_polygon(rect)
		poly.color = Layout.COLOR_FLOOR
		poly.z_index = Layout.Z_FLOOR
		root.add_child(poly)
		var inlay := Line2D.new()
		inlay.width = 3.0
		inlay.default_color = Layout.COLOR_OLD_BRASS
		inlay.default_color.a = 0.35
		inlay.z_index = Layout.Z_WORLD_PROPS
		inlay.points = PackedVector2Array([
			Vector2(rect.get_center().x, rect.position.y),
			Vector2(rect.get_center().x, rect.end.y),
		])
		root.add_child(inlay)


## Temporary visible ruin closing the Road north of the South Reach. Deliberately
## a solid blockout mass, not an invisible wall.
func _build_south_reach_barrier() -> void:
	var zone_node := zones_root.get_node_or_null("Zone10_RoadSouthReach") as Node2D
	if zone_node == null:
		return
	var rect := Layout.south_reach_barrier_rect()
	var set_pieces := _ensure_child(zone_node, "SetPieces", Node2D.new())
	var visual := Polygon2D.new()
	visual.name = "SouthReachCollapse"
	visual.polygon = Layout.rect_to_polygon(rect)
	visual.color = Layout.COLOR_DUST
	visual.z_index = Layout.Z_WORLD_PROPS
	set_pieces.add_child(visual)
	var collision := _ensure_child(zone_node, "Collision", StaticBody2D.new()) as StaticBody2D
	var shape := CollisionShape2D.new()
	shape.name = "SouthReachCollapseBody"
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.get_center()
	collision.add_child(shape)


func _build_hero_presentation() -> void:
	_build_recovery_alcove_presentation()
	_build_gate_of_dust_presentation()


func _build_recovery_alcove_presentation() -> void:
	var set_pieces := _zone_child(&"zone01_creche", "SetPieces")
	if set_pieces == null or set_pieces.get_node_or_null("RecoveryAlcove") != null:
		return
	_recovery_alcove = AnimatedSprite2D.new()
	_recovery_alcove.name = "RecoveryAlcove"
	_recovery_alcove.position = _set_piece_position(&"zone01_creche", "active_alcove")
	_recovery_alcove.z_index = Layout.Z_WORLD_PROPS
	_recovery_alcove.sprite_frames = _build_recovery_alcove_frames()
	_recovery_alcove.play(&"idle")
	set_pieces.add_child(_recovery_alcove)
	_hide_blockout_set_piece(&"zone01_creche", "active_alcove")


func _build_recovery_alcove_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.add_frame(&"idle", RECOVERY_ALCOVE_IDLE)
	frames.add_animation(&"wake")
	frames.set_animation_loop(&"wake", false)
	frames.set_animation_speed(&"wake", 8.0)
	for frame_index in 8:
		var frame := AtlasTexture.new()
		frame.atlas = RECOVERY_ALCOVE_WAKE
		frame.region = Rect2(frame_index * 192, 0, 192, 256)
		frames.add_frame(&"wake", frame)
	return frames


func _build_gate_of_dust_presentation() -> void:
	var set_pieces := _zone_child(&"zone07_gate_of_dust", "SetPieces")
	if set_pieces == null or set_pieces.get_node_or_null("GateOfDustProductionArt") != null:
		return
	var art := Node2D.new()
	art.name = "GateOfDustProductionArt"
	set_pieces.add_child(art)
	_add_hero_sprite(art, "BodyIdleSealed", GATE_BODY_IDLE_SEALED, _marker_position(&"zone07_gate_of_dust", "gate_aperture"), Layout.Z_WORLD_PROPS)
	_add_hero_sprite(art, "WestPylon", GATE_WEST_PYLON, _set_piece_position(&"zone07_gate_of_dust", "gate_pylon_west"), Layout.Z_WORLD_PROPS)
	_add_hero_sprite(art, "EastPylon", GATE_EAST_PYLON, _set_piece_position(&"zone07_gate_of_dust", "gate_pylon_east"), Layout.Z_WORLD_PROPS)
	_add_hero_sprite(art, "SealedAperture", GATE_SEALED_APERTURE, _marker_position(&"zone07_gate_of_dust", "gate_aperture"), Layout.Z_WORLD_PROPS)
	_add_hero_sprite(art, "RestThreshold", GATE_REST_THRESHOLD, _set_piece_position(&"zone07_gate_of_dust", "rest_checkpoint"), Layout.Z_FLOOR)
	for piece_id in ["gate_pylon_west", "gate_pylon_east", "rest_checkpoint"]:
		_hide_blockout_set_piece(&"zone07_gate_of_dust", piece_id)


func _add_hero_sprite(parent: Node2D, node_name: String, texture: Texture2D, position: Vector2, z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position
	sprite.z_index = z
	parent.add_child(sprite)


func _set_piece_position(zone_id: StringName, piece_id: String) -> Vector2:
	for piece in Layout.set_pieces_for(zone_id):
		if String(piece.get("id", "")) == piece_id:
			return piece.get("position", Vector2.ZERO)
	return Vector2.ZERO


func _marker_position(zone_id: StringName, marker_id: String) -> Vector2:
	for marker in Layout.markers_for(zone_id):
		if String(marker.get("id", "")) == marker_id:
			return marker.get("position", Vector2.ZERO)
	return Vector2.ZERO


func _hide_blockout_set_piece(zone_id: StringName, piece_id: String) -> void:
	var blockout := _zone_child(zone_id, "BlockoutPresentation")
	var visual := blockout.get_node_or_null(piece_id) as CanvasItem if blockout != null else null
	if visual != null:
		visual.visible = false


func _ensure_child(parent: Node, node_name: String, template: Node) -> Node:
	var existing := parent.get_node_or_null(NodePath(node_name))
	if existing != null:
		template.free()
		return existing
	template.name = node_name
	parent.add_child(template)
	return template


# --- Interactables and triggers ----------------------------------------------

func _build_interactables() -> void:
	var creche := _zone_child(&"zone01_creche", "Interactables")
	if creche != null and creche.get_node_or_null("CrecheConsole") == null:
		var console := Plaque.new()
		console.name = "CrecheConsole"
		console.position = Vector2(112, 144)
		console.title = "CRÈCHE CONSOLE"
		console.readout = CRECHE_READOUT
		console.acknowledged_readout = CRECHE_READOUT_AGAIN
		creche.add_child(console)
		console.acknowledged.connect(_on_console_acknowledged)

	var undergate := _zone_child(&"zone06_undergate", "Interactables")
	if undergate != null and undergate.get_node_or_null("PortStatusPlaque") == null:
		var plaque := Plaque.new()
		plaque.name = "PortStatusPlaque"
		plaque.position = Vector2(128, -4016)
		plaque.title = "DAMAGED PORT CONSOLE"
		plaque.readout = PORT_READOUT
		undergate.add_child(plaque)

	var cistern := _zone_child(&"zone05_dust_lung", "Interactables")
	if cistern != null and cistern.get_node_or_null("TransitLift") == null:
		var lift := TransitLift.new()
		lift.name = "TransitLift"
		lift.lower_station = Vector2(384, -3008)
		lift.upper_station = Vector2(384, -3424)
		cistern.add_child(lift)
		_transit_lift = lift

	var locker := _find_sidearm_locker()
	if locker != null and locker.has_signal("sidearm_taken"):
		if not locker.is_connected("sidearm_taken", _on_sidearm_taken):
			locker.connect("sidearm_taken", _on_sidearm_taken)


func _find_sidearm_locker() -> Node:
	return zones_root.get_node_or_null("Zone04_LockerReliquary/SidearmLocker")


func get_transit_lift() -> Node:
	if _transit_lift == null or not is_instance_valid(_transit_lift):
		_transit_lift = zones_root.get_node_or_null("Zone05_DustLung/Interactables/TransitLift")
	return _transit_lift


## One Area2D per zone drives the HUD location/phase, plus the authored camera
## reveals and the first-pass completion trigger.
func _build_triggers() -> void:
	for zone in Layout.ZONES:
		var zone_id := StringName(zone["id"])
		var region := _zone_child_node(zone_id, "ZoneRegion") as Area2D
		if region == null: continue
		region.monitoring = true
		region.collision_layer = 0
		region.collision_mask = 0xFFFFFFFF
		if not region.body_entered.is_connected(_on_zone_body_entered):
			region.body_entered.connect(_on_zone_body_entered.bind(zone_id))
		if not region.body_exited.is_connected(_on_zone_body_exited):
			region.body_exited.connect(_on_zone_body_exited.bind(zone_id))
		var reveal: Dictionary = Layout.CAMERA_REVEALS.get(zone_id, {})
		if not reveal.is_empty():
			_add_trigger_area(zone_id, "CameraReveal", reveal["trigger"], reveal["size"],
				_on_reveal_triggered.bind(zone_id))
	_add_trigger_area(&"zone10_road_south_reach", "SouthReachCompletion",
		Layout.SOUTH_REACH_COMPLETION_CENTER, Layout.SOUTH_REACH_COMPLETION_SIZE,
		_on_south_reach_reached)


func _add_trigger_area(zone_id: StringName, node_name: String, centre: Vector2, size: Vector2, callback: Callable) -> void:
	var triggers := _zone_child(zone_id, "Triggers")
	if triggers == null or triggers.get_node_or_null(NodePath(node_name)) != null:
		return
	var area := Area2D.new()
	area.name = node_name
	area.position = centre
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	area.add_child(shape)
	triggers.add_child(area)
	area.body_entered.connect(callback)


func _zone_child(zone_id: StringName, child_name: String) -> Node2D:
	return _zone_child_node(zone_id, child_name) as Node2D


func _zone_child_node(zone_id: StringName, child_name: String) -> Node:
	var zone := Layout.zone_by_id(zone_id)
	if zone.is_empty() or zones_root == null: return null
	return zones_root.get_node_or_null(NodePath("%s/%s" % [String(zone["node"]), child_name]))


func _is_operator(body: Node) -> bool:
	return body == operator_ref or (body != null and body.is_in_group("player"))


## Section envelopes deliberately overlap where one space opens into the next
## (the Approach sits inside the Road's map rectangle, for one), so track every
## region the Operator occupies and let the furthest-along section win.
func _on_zone_body_entered(body: Node, zone_id: StringName) -> void:
	if not _is_operator(body): return
	_occupied_zones[zone_id] = true
	_resolve_occupied_zone()


func _on_zone_body_exited(body: Node, zone_id: StringName) -> void:
	if not _is_operator(body): return
	_occupied_zones.erase(zone_id)
	_resolve_occupied_zone()


func _resolve_occupied_zone() -> void:
	var best_index := -1
	var best_id := &""
	var position := operator_ref.global_position if operator_ref != null else Vector2.ZERO
	for zone_id in _occupied_zones.keys():
		var zone := Layout.zone_by_id(zone_id)
		# Debug teleports (and any other instant relocation) move the Operator
		# without an exit event, so verify containment rather than trusting the
		# region bookkeeping alone.
		if zone.is_empty() or not (zone["envelope"] as Rect2).has_point(position):
			_occupied_zones.erase(zone_id)
			continue
		if int(zone["index"]) > best_index:
			best_index = int(zone["index"])
			best_id = zone_id
	if best_index > 0:
		_enter_zone(best_id)


func _on_console_acknowledged(_actor: Node) -> void:
	if opening_console_acknowledged: return
	opening_console_acknowledged = true
	if _recovery_alcove != null:
		_recovery_alcove.play(&"wake")
	_set_objective(OBJECTIVE_RETURN_TO_POST)
	if hud != null:
		hud.call("set_status_line", "key", Catalog.ICON_OBJECTIVE, "CONTINUITY: UNRESOLVED", Palette.GOLD_TEXT)
		hud.call("set_status_line", "gate", Catalog.ICON_KEY_ITEM, "AUTHORITY: VALID", Palette.GREEN_SIGNAL)
	console_acknowledged.emit()


func _on_sidearm_taken(_actor: Node) -> void:
	if p9_recovered: return
	p9_recovered = true
	if hud != null:
		hud.call("set_status_line", "return", Catalog.COMPASS_ROSE_SMALL, "P-9: RECOVERED", Palette.GREEN_SIGNAL)
	sidearm_recovered.emit()


## Authored reveal: framing eases out, holds, then hands the camera back. The
## player keeps control throughout — they discover the vista while walking.
func _on_reveal_triggered(body: Node, zone_id: StringName) -> void:
	if not _is_operator(body) or _fired_reveals.has(zone_id): return
	_fired_reveals[zone_id] = true
	play_camera_reveal(zone_id)


func play_camera_reveal(zone_id: StringName) -> bool:
	var reveal: Dictionary = Layout.CAMERA_REVEALS.get(zone_id, {})
	if reveal.is_empty() or camera_ref == null: return false
	if not camera_ref.has_method("set_presentation_framing_transition"): return false
	camera_ref.call("set_presentation_framing_transition",
		reveal["offset"], reveal["zoom"], float(reveal["transition_sec"]))
	_release_reveal_after(float(reveal["transition_sec"]) + float(reveal["hold_sec"]))
	return true


func _release_reveal_after(seconds: float) -> void:
	_reveal_release_pending = true
	await get_tree().create_timer(seconds).timeout
	if camera_ref != null and camera_ref.has_method("clear_presentation_framing"):
		camera_ref.call("clear_presentation_framing", true)
	_reveal_release_pending = false


func _on_south_reach_reached(body: Node) -> void:
	if completed or not _is_operator(body): return
	completed = true
	if hud != null and OS.is_debug_build():
		hud.call("show_interaction", "AWAKENING BLOCKOUT COMPLETE",
			"ROAD OF WITNESSES // SOUTH REACH", "", Catalog.ICON_OBJECTIVE)
	blockout_completed.emit()


# --- Progression -------------------------------------------------------------

func _enter_zone(zone_id: StringName) -> void:
	var zone := Layout.zone_by_id(zone_id)
	if zone.is_empty():
		return
	if current_zone_index == int(zone["index"]) and visited_zones.has(zone_id):
		return
	current_zone_index = int(zone["index"])
	visited_zones[zone_id] = true
	_set_hud_zone(zone)
	zone_entered.emit(zone_id, current_zone_index)


func _configure_hud() -> void:
	if hud == null:
		return
	hud.set_minimap_visible(true)
	hud.set_debug_overlay_visible(false)
	hud.call("set_status_line", "key", Catalog.ICON_OBJECTIVE, "CONTINUITY: UNRESOLVED", Palette.MUTED_TEXT)
	hud.call("set_status_line", "gate", Catalog.ICON_HAZARD, "AUTHORITY: UNVERIFIED", Palette.DANGER)
	hud.call("set_status_line", "return", Catalog.COMPASS_ROSE_SMALL, "POST: UNMANNED", Palette.BLUE_TECH)
	_set_objective(OBJECTIVE_RECOVERY)


func _set_objective(text: String) -> void:
	if hud != null: hud.set_objective(text)


func _set_hud_zone(zone: Dictionary) -> void:
	if hud == null:
		return
	hud.call("set_location", String(zone.get("location", "")))
	hud.set_phase(String(zone.get("phase", "")))


# --- Authoring / debug contract ----------------------------------------------

func get_boundary_segments() -> Array:
	var bounds := Layout.WORLD_BOUNDS
	return [
		[bounds.position, Vector2(bounds.end.x, bounds.position.y)],
		[Vector2(bounds.end.x, bounds.position.y), bounds.end],
		[bounds.end, Vector2(bounds.position.x, bounds.end.y)],
		[Vector2(bounds.position.x, bounds.end.y), bounds.position],
	]


func get_zone_specs() -> Array:
	var result: Array = []
	for zone in Layout.ZONES:
		result.append((zone as Dictionary).duplicate(true))
	return result


func get_landmark_specs() -> Array:
	var result: Array = []
	for zone in Layout.ZONES:
		var zone_id := StringName(zone["id"])
		for marker in Layout.markers_for(zone_id):
			var data := (marker as Dictionary).duplicate(true)
			data["zone_id"] = String(zone_id)
			result.append(data)
	return result


func get_authoring_marker_schema() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in get_landmark_specs():
		var data := entry as Dictionary
		result.append({
			"id": String(data.get("id", "")),
			"label": String(data.get("label", "")),
			"kind": String(data.get("kind", "marker")),
			"node_name": String(data.get("id", "")),
			"position": data.get("position", Vector2.ZERO),
		})
	return result


func get_authoring_marker_state() -> Dictionary:
	var result := {}
	for entry in get_landmark_specs():
		var data := entry as Dictionary
		var marker_id := String(data.get("id", ""))
		result[marker_id] = {
			"kind": String(data.get("kind", "marker")),
			"label": String(data.get("label", "")),
			"node_name": marker_id,
			"source_position": data.get("position", Vector2.ZERO),
			"runtime_position": data.get("position", Vector2.ZERO),
		}
	return result


func teleport_operator_to_zone(index: int) -> bool:
	var zone := Layout.zone_by_index(index)
	if zone.is_empty() or operator_ref == null:
		return false
	operator_ref.global_position = zone.get("entry", Layout.OPERATOR_WAKE_POSITION)
	_enter_zone(StringName(zone["id"]))
	return true


func get_awakening_state() -> Dictionary:
	return {
		"current_zone_index": current_zone_index,
		"visited_zones": visited_zones.keys(),
		"completed": completed,
		"opening_console_acknowledged": opening_console_acknowledged,
		"p9_recovered": p9_recovered,
		"fired_reveals": _fired_reveals.keys(),
		"world_bounds": Layout.WORLD_BOUNDS,
		"operator_position": operator_ref.global_position if operator_ref != null else Vector2.ZERO,
	}


## Debug tour support: drops progression back to the wake state without
## reloading the scene.
func reset_progression() -> void:
	current_zone_index = 1
	visited_zones.clear()
	_fired_reveals.clear()
	_occupied_zones.clear()
	completed = false
	opening_console_acknowledged = false
	p9_recovered = false
	if _recovery_alcove != null:
		_recovery_alcove.play(&"idle")
	_place_operator()
	_configure_hud()
	_enter_zone(&"zone01_creche")
