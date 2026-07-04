extends Node2D
class_name SunderedKeepApproach

const SOFT_RECT_FEATHER_SHADER := preload("res://game/world/approaches/sundered_keep/soft_rect_feather.gdshader")

const OCEAN_UNDERLAY_PATH := "res://content/backgrounds/sundered_keep/ocean_underlay.png"
const CLIFF_DEPTH_UNDERLAY_PATH := "res://content/backgrounds/sundered_keep/cliff_depth_underlay.png"
const HORIZON_SKY_PATH := "res://content/backgrounds/sundered_keep/horizon_sky.png"
const FAR_SEA_PATH := "res://content/backgrounds/sundered_keep/far_sea.png"
const DISTANT_KEEP_PATH := "res://content/backgrounds/sundered_keep/distant_sundered_keep.png"
const VISTA_FOG_BAND_PATH := "res://content/backgrounds/sundered_keep/vista_fog_band.png"
const GRAND_VISTA_PANORAMA := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_panorama.png"
const GRAND_VISTA_FOG := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_fog_overlay.png"
const GRAND_VISTA_PARAPET := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_parapet.png"
const GRAND_VISTA_VIGNETTE := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_shadow_vignette.png"
const GRAND_VISTA_SPRAY := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_ocean_spray_overlay.png"
const GRAND_VISTA_HORIZON_SEAM_FOG := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_horizon_seam_fog.png"
const GRAND_VISTA_PATH_CONTACT_SHADOW := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_path_contact_shadow.png"
const GRAND_VISTA_FOREGROUND_EDGE_MASK := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_edge_mask.png"
const GRAND_VISTA_EDGE_SPRAY_WRAP := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_edge_spray_wrap.png"

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
const RECT_GRAND_VISTA_PANORAMA := Rect2(Vector2(-1280.0, -920.0), Vector2(2560.0, 1440.0))
const RECT_GRAND_VISTA_SPRAY := Rect2(Vector2(-1280.0, -160.0), Vector2(2560.0, 720.0))
const RECT_GRAND_VISTA_FOG := Rect2(Vector2(-1280.0, -520.0), Vector2(2560.0, 480.0))
const RECT_GRAND_VISTA_VIGNETTE := Rect2(Vector2(-1280.0, -920.0), Vector2(2560.0, 1440.0))
const RECT_GRAND_VISTA_PARAPET := Rect2(Vector2(-1280.0, 260.0), Vector2(2560.0, 360.0))
const RECT_GRAND_VISTA_HORIZON_SEAM_FOG := Rect2(Vector2(-1280.0, -460.0), Vector2(2560.0, 320.0))
const RECT_GRAND_VISTA_PATH_CONTACT_SHADOW := Rect2(Vector2(-1280.0, -160.0), Vector2(2560.0, 720.0))
const RECT_GRAND_VISTA_EDGE_SPRAY_WRAP := Rect2(Vector2(-1280.0, -160.0), Vector2(2560.0, 720.0))
const RECT_GRAND_VISTA_FOREGROUND_EDGE_MASK := Rect2(Vector2(-1280.0, 220.0), Vector2(2560.0, 420.0))

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
const SECOND_VISTA_START_POS := Vector2(420.0, -180.0)
const SECOND_VISTA_FULL_POS := Vector2(560.0, -185.0)
const SECOND_VISTA_END_POS := Vector2(700.0, -175.0)

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
var _grand_vista_root: Node2D = null
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
var second_vista_start: Marker2D = null
var second_vista_full: Marker2D = null
var second_vista_end: Marker2D = null
var vista_controller: SunderedKeepVistaController = null
var exit_transition_trigger: SunderedKeepTransitionTrigger = null


func _ready() -> void:
	add_to_group("sundered_keep_approach")
	add_to_group("world_ingress_approach")
	_remove_stale_proxy_nodes()
	_ensure_roots()
	_build_visuals()
	_ensure_vista_controller()
	call_deferred("_finish_physics_setup")


func configure_ingress(config: Dictionary) -> void:
	_ingress_config = config.duplicate(true)
	_apply_ingress_config_to_trigger()


func get_entry_position() -> Vector2:
	if entry_spawn != null:
		return entry_spawn.global_position
	return global_position + ENTRY_SPAWN_POS


func _finish_physics_setup() -> void:
	if not is_inside_tree():
		return
	_build_collision()
	_ensure_exit_transition_trigger()
	_apply_ingress_config_to_trigger()


func _remove_stale_proxy_nodes() -> void:
	for node_name in ["VistaUnderlay", "PathSprites", "Occlusion", "Gameplay", "ApproachVoidBackdrop"]:
		var stale := get_node_or_null(node_name)
		if stale != null:
			stale.queue_free()


func _ensure_roots() -> void:
	underlay_root = _ensure_node2d_root("UnderlayRoot", -300)
	vista_root = _ensure_node2d_root("VistaRoot", -200)
	_grand_vista_root = _ensure_node2d_root("GrandVistaRoot", -220)
	_grand_vista_root.modulate.a = 0.0
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
	second_vista_start = _ensure_marker("SecondVistaStart", SECOND_VISTA_START_POS)
	second_vista_full = _ensure_marker("SecondVistaFull", SECOND_VISTA_FULL_POS)
	second_vista_end = _ensure_marker("SecondVistaEnd", SECOND_VISTA_END_POS)


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


func _ensure_child_node2d_root(parent: Node2D, node_name: String, z: int) -> Node2D:
	var root := parent.get_node_or_null(node_name) as Node2D
	if root == null:
		root = Node2D.new()
		root.name = node_name
		parent.add_child(root)
	root.z_as_relative = false
	root.z_index = z
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
	_clear_children(_grand_vista_root)
	_clear_children(playable_root)
	_clear_children(occlusion_root)
	vista_root.modulate.a = 0.0
	_grand_vista_root.modulate.a = 0.0
	occlusion_root.modulate.a = 0.0

	_add_fitted_sprite(underlay_root, "OceanUnderlay", OCEAN_UNDERLAY_PATH, RECT_OCEAN_UNDERLAY, 0, Color.WHITE)
	_apply_soft_rect_feather(
		_add_fitted_sprite(underlay_root, "CliffDepthUnderlay", CLIFF_DEPTH_UNDERLAY_PATH, RECT_CLIFF_DEPTH_UNDERLAY, 1, Color(0.82, 0.86, 0.92, 0.82)),
		Vector4(0.16, 0.30, 0.20, 0.28)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(underlay_root, "FogUnderlay", UNDERLAY_FOG_BAND_PATH, RECT_FOG_UNDERLAY, 2, Color(1.0, 1.0, 1.0, 0.22)),
		Vector4(0.18, 0.18, 0.36, 0.34)
	)

	_apply_soft_rect_feather(
		_add_fitted_sprite(vista_root, "HorizonSky", HORIZON_SKY_PATH, RECT_HORIZON_SKY, 0, Color(0.86, 0.90, 1.0, 0.92)),
		Vector4(0.06, 0.06, 0.08, 0.24)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(vista_root, "FarSea", FAR_SEA_PATH, RECT_FAR_SEA, 1, Color(0.86, 0.90, 1.0, 0.86)),
		Vector4(0.08, 0.08, 0.28, 0.30)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(vista_root, "DistantSunderedKeep", DISTANT_KEEP_PATH, RECT_DISTANT_KEEP, 2, Color(0.90, 0.94, 1.0, 0.84)),
		Vector4(0.18, 0.18, 0.16, 0.34)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(vista_root, "VistaFogBand", VISTA_FOG_BAND_PATH, RECT_VISTA_FOG_BAND, 3, Color(1.0, 1.0, 1.0, 0.72)),
		Vector4(0.14, 0.14, 0.36, 0.36)
	)

	_apply_soft_rect_feather(
		_add_fitted_sprite(_grand_vista_root, "GrandVistaPanorama", GRAND_VISTA_PANORAMA, RECT_GRAND_VISTA_PANORAMA, 0, Color(0.88, 0.92, 1.0, 0.88)),
		Vector4(0.08, 0.08, 0.10, 0.16)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(_grand_vista_root, "GrandVistaOceanSprayOverlay", GRAND_VISTA_SPRAY, RECT_GRAND_VISTA_SPRAY, 1, Color(1.0, 1.0, 1.0, 0.58)),
		Vector4(0.10, 0.10, 0.28, 0.34)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(_grand_vista_root, "GrandVistaFogOverlay", GRAND_VISTA_FOG, RECT_GRAND_VISTA_FOG, 2, Color(1.0, 1.0, 1.0, 0.48)),
		Vector4(0.10, 0.10, 0.34, 0.36)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(_grand_vista_root, "GrandVistaShadowVignette", GRAND_VISTA_VIGNETTE, RECT_GRAND_VISTA_VIGNETTE, 3, Color(1.0, 1.0, 1.0, 0.42)),
		Vector4(0.08, 0.08, 0.08, 0.08)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(_grand_vista_root, "GrandVistaForegroundParapet", GRAND_VISTA_PARAPET, RECT_GRAND_VISTA_PARAPET, 20, Color(0.90, 0.94, 1.0, 0.92)),
		Vector4(0.08, 0.08, 0.18, 0.08)
	)
	var glue_root := _ensure_child_node2d_root(_grand_vista_root, "GrandVistaGlueRoot", 25)
	_apply_soft_rect_feather(
		_add_fitted_sprite(glue_root, "GrandVistaHorizonSeamFog", GRAND_VISTA_HORIZON_SEAM_FOG, RECT_GRAND_VISTA_HORIZON_SEAM_FOG, 30, Color(1.0, 1.0, 1.0, 0.45)),
		Vector4(0.10, 0.10, 0.28, 0.30)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(glue_root, "GrandVistaPathContactShadow", GRAND_VISTA_PATH_CONTACT_SHADOW, RECT_GRAND_VISTA_PATH_CONTACT_SHADOW, 35, Color(1.0, 1.0, 1.0, 0.50)),
		Vector4(0.08, 0.08, 0.18, 0.26)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(glue_root, "GrandVistaEdgeSprayWrap", GRAND_VISTA_EDGE_SPRAY_WRAP, RECT_GRAND_VISTA_EDGE_SPRAY_WRAP, 40, Color(1.0, 1.0, 1.0, 0.35)),
		Vector4(0.10, 0.10, 0.24, 0.30)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(glue_root, "GrandVistaForegroundEdgeMask", GRAND_VISTA_FOREGROUND_EDGE_MASK, RECT_GRAND_VISTA_FOREGROUND_EDGE_MASK, 80, Color(1.0, 1.0, 1.0, 0.55)),
		Vector4(0.08, 0.08, 0.18, 0.08)
	)

	_add_grounding_shadow("MainlandApproachShadow", PackedVector2Array([
		Vector2(-315.0, 145.0), Vector2(190.0, 250.0), Vector2(120.0, 535.0), Vector2(-330.0, 535.0)
	]), -32, Color(0.02, 0.025, 0.035, 0.30))
	_add_grounding_shadow("OverlookLedgeShadow", PackedVector2Array([
		Vector2(-360.0, -300.0), Vector2(340.0, -315.0), Vector2(330.0, -108.0), Vector2(-280.0, -96.0)
	]), -31, Color(0.015, 0.02, 0.03, 0.36))
	_add_grounding_shadow("LateralTraverseShadow", PackedVector2Array([
		Vector2(245.0, -250.0), Vector2(800.0, -268.0), Vector2(805.0, -72.0), Vector2(275.0, -74.0)
	]), -30, Color(0.015, 0.02, 0.03, 0.34))

	_add_fitted_sprite(playable_root, "MainlandApproachPath", MAINLAND_APPROACH_PATH, RECT_MAINLAND_APPROACH, -24, Color.WHITE)
	_add_fitted_sprite(playable_root, "HillClimbPath", HILL_CLIMB_PATH, RECT_HILL_CLIMB, -23, Color.WHITE)
	_add_fitted_sprite(playable_root, "OverlookLedge", OVERLOOK_LEDGE_PATH, RECT_OVERLOOK_LEDGE, -22, Color.WHITE)
	_add_fitted_sprite(playable_root, "LateralTraversePath", LATERAL_TRAVERSE_PATH, RECT_LATERAL_TRAVERSE, -21, Color.WHITE)
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


func _apply_soft_rect_feather(sprite: Sprite2D, feather: Vector4) -> void:
	if sprite == null:
		return
	var material := ShaderMaterial.new()
	material.shader = SOFT_RECT_FEATHER_SHADER
	material.set_shader_parameter("feather_left", feather.x)
	material.set_shader_parameter("feather_right", feather.y)
	material.set_shader_parameter("feather_top", feather.z)
	material.set_shader_parameter("feather_bottom", feather.w)
	sprite.material = material


func _add_grounding_shadow(node_name: String, points: PackedVector2Array, z: int, color: Color) -> Polygon2D:
	var shadow := playable_root.get_node_or_null(node_name) as Polygon2D
	if shadow == null:
		shadow = Polygon2D.new()
		shadow.name = node_name
		playable_root.add_child(shadow)
	shadow.polygon = points
	shadow.color = color
	shadow.z_as_relative = false
	shadow.z_index = z
	return shadow


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
	vista_controller.grand_vista_root_path = NodePath("../GrandVistaRoot")
	vista_controller.vista_fog_band_path = NodePath("../VistaRoot/VistaFogBand")
	vista_controller.fog_underlay_path = NodePath("../UnderlayRoot/FogUnderlay")
	vista_controller.occlusion_root_path = NodePath("../OcclusionRoot")
	vista_controller.cliff_occluder_path = NodePath("../OcclusionRoot/CliffOccluder")
	vista_controller.wall_shadow_occluder_path = NodePath("../OcclusionRoot/WallShadowOccluder")
	vista_controller.distant_keep_path = NodePath("../VistaRoot/DistantSunderedKeep")
	vista_controller.second_vista_start_marker_path = NodePath("../Markers/SecondVistaStart")
	vista_controller.second_vista_full_marker_path = NodePath("../Markers/SecondVistaFull")
	vista_controller.second_vista_end_marker_path = NodePath("../Markers/SecondVistaEnd")
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
	exit_transition_trigger.set_deferred("monitoring", true)
	exit_transition_trigger.set_deferred("monitorable", true)

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
	shape.set_deferred("disabled", false)


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
