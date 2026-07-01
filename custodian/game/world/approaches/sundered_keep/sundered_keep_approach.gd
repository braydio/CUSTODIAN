extends Node2D
class_name SunderedKeepApproach

const OCEAN_UNDERLAY_PATH := "res://content/backgrounds/sundered_keep/ocean_underlay.png"
const CLIFF_DEPTH_UNDERLAY_PATH := "res://content/backgrounds/sundered_keep/cliff_depth_underlay.png"
const HORIZON_SKY_PATH := "res://content/backgrounds/sundered_keep/horizon_sky.png"
const FAR_SEA_PATH := "res://content/backgrounds/sundered_keep/far_sea.png"
const DISTANT_KEEP_PATH := "res://content/backgrounds/sundered_keep/distant_sundered_keep.png"
const VISTA_FOG_BAND_PATH := "res://content/backgrounds/sundered_keep/vista_fog_band.png"

const MAINLAND_APPROACH_PATH := "res://content/sprites/world/return_causeway/path/mainland_approach_path.png"
const HILL_CLIMB_PATH := "res://content/sprites/world/return_causeway/path/hill_climb_path.png"
const OVERLOOK_LEDGE_PATH := "res://content/sprites/world/return_causeway/path/overlook_ledge.png"
const LATERAL_TRAVERSE_PATH := "res://content/sprites/world/return_causeway/path/lateral_traverse_path.png"
const FORTRESS_WALL_MASS_PATH := "res://content/sprites/world/return_causeway/path/fortress_wall_mass.png"

const CLIFF_OCCLUDER_PATH := "res://content/sprites/world/return_causeway/occlusion/cliff_occluder.png"
const WALL_SHADOW_OCCLUDER_PATH := "res://content/sprites/world/return_causeway/occlusion/wall_shadow_occluder.png"
const UNDERLAY_FOG_BAND_PATH := "res://content/sprites/world/return_causeway/underlay/underlay_fog_band.png"

const TARGET_SCENE_PATH := "res://game/world/sundered_keep/sundered_keep_map.gd"

const RECT_OCEAN_UNDERLAY := Rect2(Vector2(-900.0, -700.0), Vector2(2100.0, 1400.0))
const RECT_CLIFF_DEPTH_UNDERLAY := Rect2(Vector2(-500.0, -440.0), Vector2(520.0, 540.0))
const RECT_FOG_UNDERLAY := Rect2(Vector2(-900.0, -620.0), Vector2(2100.0, 360.0))
const RECT_HORIZON_SKY := Rect2(Vector2(-900.0, -700.0), Vector2(2100.0, 380.0))
const RECT_FAR_SEA := Rect2(Vector2(-900.0, -520.0), Vector2(2100.0, 260.0))
const RECT_DISTANT_KEEP := Rect2(Vector2(-260.0, -670.0), Vector2(540.0, 250.0))
const RECT_VISTA_FOG_BAND := Rect2(Vector2(-900.0, -380.0), Vector2(2100.0, 160.0))

const RECT_MAINLAND_APPROACH := Rect2(Vector2(-300.0, 120.0), Vector2(470.0, 400.0))
const RECT_HILL_CLIMB := Rect2(Vector2(-190.0, -120.0), Vector2(400.0, 240.0))
const RECT_OVERLOOK_LEDGE := Rect2(Vector2(-320.0, -320.0), Vector2(640.0, 200.0))
const RECT_LATERAL_TRAVERSE := Rect2(Vector2(260.0, -260.0), Vector2(520.0, 180.0))
const RECT_FORTRESS_WALL_MASS := Rect2(Vector2(650.0, -420.0), Vector2(350.0, 380.0))
const RECT_CLIFF_OCCLUDER := Rect2(Vector2(520.0, -420.0), Vector2(520.0, 540.0))
const RECT_WALL_SHADOW_OCCLUDER := Rect2(Vector2(-900.0, -360.0), Vector2(2100.0, 130.0))

const ENTRY_SPAWN_POS := Vector2(-80.0, 430.0)
const REVEAL_START_POS := Vector2(-40.0, 80.0)
const REVEAL_FULL_POS := Vector2(0.0, -250.0)
const TRAVERSE_START_POS := Vector2(260.0, -180.0)
const TRAVERSE_END_POS := Vector2(760.0, -170.0)
const RETURN_TOPDOWN_POS := Vector2(720.0, -80.0)

const BOUNDARY_SEGMENTS := [
	[Vector2(-280.0, 520.0), Vector2(80.0, 520.0)],
	[Vector2(80.0, 520.0), Vector2(170.0, 280.0)],
	[Vector2(170.0, 280.0), Vector2(80.0, 120.0)],
	[Vector2(-140.0, 120.0), Vector2(-300.0, 300.0)],
	[Vector2(-300.0, 300.0), Vector2(-280.0, 520.0)],
	[Vector2(-140.0, 120.0), Vector2(-190.0, -120.0)],
	[Vector2(130.0, 120.0), Vector2(210.0, -120.0)],
	[Vector2(-260.0, -120.0), Vector2(-320.0, -320.0)],
	[Vector2(-320.0, -320.0), Vector2(320.0, -320.0)],
	[Vector2(320.0, -320.0), Vector2(300.0, -260.0)],
	[Vector2(260.0, -260.0), Vector2(780.0, -260.0)],
	[Vector2(780.0, -260.0), Vector2(780.0, -80.0)],
	[Vector2(780.0, -80.0), Vector2(300.0, -80.0)],
]

var _ingress_config: Dictionary = {}

var underlay_root: Node2D = null
var vista_root: Node2D = null
var playable_root: Node2D = null
var occlusion_root: Node2D = null
var collision_root: Node2D = null
var markers_root: Node2D = null

var entry_spawn: Marker2D = null
var reveal_start: Marker2D = null
var reveal_full: Marker2D = null
var traverse_start: Marker2D = null
var traverse_end: Marker2D = null
var return_topdown: Marker2D = null
var vista_controller: SunderedKeepVistaController = null
var exit_transition_trigger: SunderedKeepTransitionTrigger = null


func _ready() -> void:
	add_to_group("sundered_keep_approach")
	add_to_group("world_ingress_approach")
	_remove_stale_proxy_nodes()
	_ensure_roots()
	_build_visuals()
	_build_collision()
	_ensure_vista_controller()
	_ensure_exit_transition_trigger()
	_apply_ingress_config_to_trigger()


func configure_ingress(config: Dictionary) -> void:
	_ingress_config = config.duplicate(true)
	_apply_ingress_config_to_trigger()


func get_entry_position() -> Vector2:
	if entry_spawn != null:
		return entry_spawn.global_position
	return global_position + ENTRY_SPAWN_POS


func _remove_stale_proxy_nodes() -> void:
	for node_name in ["VistaUnderlay", "PathSprites", "Occlusion", "Gameplay", "ApproachVoidBackdrop"]:
		var stale := get_node_or_null(node_name)
		if stale != null:
			stale.queue_free()


func _ensure_roots() -> void:
	underlay_root = _ensure_node2d_root("UnderlayRoot", -300)
	vista_root = _ensure_node2d_root("VistaRoot", -200)
	playable_root = _ensure_node2d_root("PlayableRoot", 0)
	occlusion_root = _ensure_node2d_root("OcclusionRoot", 100)
	collision_root = _ensure_plain_node2d("Collision")
	markers_root = _ensure_plain_node2d("Markers")

	entry_spawn = _ensure_marker("EntrySpawn", ENTRY_SPAWN_POS)
	reveal_start = _ensure_marker("RevealStart", REVEAL_START_POS)
	reveal_full = _ensure_marker("RevealFull", REVEAL_FULL_POS)
	traverse_start = _ensure_marker("TraverseStart", TRAVERSE_START_POS)
	traverse_end = _ensure_marker("TraverseEnd", TRAVERSE_END_POS)
	return_topdown = _ensure_marker("ReturnTopdown", RETURN_TOPDOWN_POS)


func _ensure_node2d_root(node_name: String, z: int) -> Node2D:
	var root := get_node_or_null(node_name) as Node2D
	if root == null:
		root = Node2D.new()
		root.name = node_name
		add_child(root)
	root.z_as_relative = false
	root.z_index = z
	return root


func _ensure_plain_node2d(node_name: String) -> Node2D:
	var root := get_node_or_null(node_name) as Node2D
	if root == null:
		root = Node2D.new()
		root.name = node_name
		add_child(root)
	return root


func _ensure_marker(node_name: String, marker_position: Vector2) -> Marker2D:
	var marker := markers_root.get_node_or_null(node_name) as Marker2D
	if marker == null:
		marker = Marker2D.new()
		marker.name = node_name
		markers_root.add_child(marker)
	marker.position = marker_position
	return marker


func _build_visuals() -> void:
	_clear_children(underlay_root)
	_clear_children(vista_root)
	_clear_children(playable_root)
	_clear_children(occlusion_root)
	vista_root.modulate.a = 0.0
	occlusion_root.modulate.a = 0.0

	_add_fitted_sprite(underlay_root, "OceanUnderlay", OCEAN_UNDERLAY_PATH, RECT_OCEAN_UNDERLAY, 0, Color.WHITE)
	_add_fitted_sprite(underlay_root, "CliffDepthUnderlay", CLIFF_DEPTH_UNDERLAY_PATH, RECT_CLIFF_DEPTH_UNDERLAY, 1, Color.WHITE)
	_add_fitted_sprite(underlay_root, "FogUnderlay", UNDERLAY_FOG_BAND_PATH, RECT_FOG_UNDERLAY, 2, Color(1.0, 1.0, 1.0, 0.28))

	_add_fitted_sprite(vista_root, "HorizonSky", HORIZON_SKY_PATH, RECT_HORIZON_SKY, 0, Color.WHITE)
	_add_fitted_sprite(vista_root, "FarSea", FAR_SEA_PATH, RECT_FAR_SEA, 1, Color.WHITE)
	_add_fitted_sprite(vista_root, "DistantSunderedKeep", DISTANT_KEEP_PATH, RECT_DISTANT_KEEP, 2, Color.WHITE)
	_add_fitted_sprite(vista_root, "VistaFogBand", VISTA_FOG_BAND_PATH, RECT_VISTA_FOG_BAND, 3, Color.WHITE)

	_add_fitted_sprite(playable_root, "MainlandApproachPath", MAINLAND_APPROACH_PATH, RECT_MAINLAND_APPROACH, 0, Color.WHITE)
	_add_fitted_sprite(playable_root, "HillClimbPath", HILL_CLIMB_PATH, RECT_HILL_CLIMB, 1, Color.WHITE)
	_add_fitted_sprite(playable_root, "OverlookLedge", OVERLOOK_LEDGE_PATH, RECT_OVERLOOK_LEDGE, 2, Color.WHITE)
	_add_fitted_sprite(playable_root, "LateralTraversePath", LATERAL_TRAVERSE_PATH, RECT_LATERAL_TRAVERSE, 3, Color.WHITE)
	_add_fitted_sprite(playable_root, "FortressWallMass", FORTRESS_WALL_MASS_PATH, RECT_FORTRESS_WALL_MASS, 30, Color.WHITE)

	_add_fitted_sprite(occlusion_root, "CliffOccluder", CLIFF_OCCLUDER_PATH, RECT_CLIFF_OCCLUDER, 120, Color(1.0, 1.0, 1.0, 0.0))
	_add_fitted_sprite(occlusion_root, "WallShadowOccluder", WALL_SHADOW_OCCLUDER_PATH, RECT_WALL_SHADOW_OCCLUDER, 130, Color(1.0, 1.0, 1.0, 0.0))


func _add_fitted_sprite(
	parent: Node,
	node_name: String,
	texture_path: String,
	rect: Rect2,
	z: int,
	tint: Color
) -> Sprite2D:
	var sprite := parent.get_node_or_null(node_name) as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = node_name
		parent.add_child(sprite)

	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("[SunderedKeepApproach] Missing texture for %s: %s" % [node_name, texture_path])
		sprite.texture = null
		return sprite

	sprite.texture = texture
	sprite.centered = false
	sprite.position = rect.position
	sprite.z_as_relative = false
	sprite.z_index = z
	sprite.modulate = tint

	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		push_error("[SunderedKeepApproach] Invalid texture size for %s: %s" % [node_name, texture_path])
		sprite.scale = Vector2.ONE
		return sprite

	sprite.scale = Vector2(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	return sprite


func _build_collision() -> void:
	_clear_children(collision_root)

	var body := StaticBody2D.new()
	body.name = "PathBoundaryCollision"
	# Project world/terrain solids currently use layer 1; Operator collision is expected to include it.
	body.collision_layer = 1
	body.collision_mask = 1
	collision_root.add_child(body)

	var index := 1
	for segment_variant: Variant in BOUNDARY_SEGMENTS:
		var segment := segment_variant as Array
		_add_boundary_segment(
			body,
			"BoundarySegment_%03d" % index,
			segment[0] as Vector2,
			segment[1] as Vector2
		)
		index += 1


func _add_boundary_segment(parent: StaticBody2D, node_name: String, a: Vector2, b: Vector2) -> CollisionShape2D:
	var segment := SegmentShape2D.new()
	segment.a = a
	segment.b = b

	var col := CollisionShape2D.new()
	col.name = node_name
	col.shape = segment
	parent.add_child(col)
	return col


func _ensure_vista_controller() -> void:
	vista_controller = get_node_or_null("VistaController") as SunderedKeepVistaController
	if vista_controller == null:
		vista_controller = SunderedKeepVistaController.new()
		vista_controller.name = "VistaController"
		add_child(vista_controller)

	vista_controller.start_marker_path = NodePath("../Markers/RevealStart")
	vista_controller.end_marker_path = NodePath("../Markers/ReturnTopdown")
	vista_controller.vista_root_path = NodePath("../VistaRoot")
	vista_controller.vista_fog_band_path = NodePath("../VistaRoot/VistaFogBand")
	vista_controller.fog_underlay_path = NodePath("../UnderlayRoot/FogUnderlay")
	vista_controller.occlusion_root_path = NodePath("../OcclusionRoot")
	vista_controller.cliff_occluder_path = NodePath("../OcclusionRoot/CliffOccluder")
	vista_controller.wall_shadow_occluder_path = NodePath("../OcclusionRoot/WallShadowOccluder")
	vista_controller.distant_keep_path = NodePath("../VistaRoot/DistantSunderedKeep")
	vista_controller.refresh_bindings()
	vista_controller.apply_progress(0.0)


func _ensure_exit_transition_trigger() -> void:
	exit_transition_trigger = get_node_or_null("ExitTransitionTrigger") as SunderedKeepTransitionTrigger
	if exit_transition_trigger == null:
		exit_transition_trigger = SunderedKeepTransitionTrigger.new()
		exit_transition_trigger.name = "ExitTransitionTrigger"
		add_child(exit_transition_trigger)

	exit_transition_trigger.position = TRAVERSE_END_POS
	exit_transition_trigger.target_scene_path = TARGET_SCENE_PATH
	exit_transition_trigger.vista_controller_path = NodePath("../VistaController")
	exit_transition_trigger.monitoring = true
	exit_transition_trigger.monitorable = true

	var shape := exit_transition_trigger.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		exit_transition_trigger.add_child(shape)
	var rectangle := shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		shape.shape = rectangle
	rectangle.size = Vector2(144.0, 190.0)
	shape.position = Vector2.ZERO


func _apply_ingress_config_to_trigger() -> void:
	if exit_transition_trigger == null:
		return
	if _ingress_config.has("target_scene_path"):
		exit_transition_trigger.target_scene_path = String(_ingress_config["target_scene_path"])
	if _ingress_config.has("target_spawn_id"):
		exit_transition_trigger.target_spawn_id = _ingress_config["target_spawn_id"]
	if _ingress_config.has("return_world_position"):
		exit_transition_trigger.return_world_position = _ingress_config["return_world_position"]


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		child.queue_free()
