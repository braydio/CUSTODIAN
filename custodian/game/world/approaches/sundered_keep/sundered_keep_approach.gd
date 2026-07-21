extends Node2D
class_name SunderedKeepApproach

const SOFT_RECT_FEATHER_SHADER := preload("res://game/world/approaches/sundered_keep/soft_rect_feather.gdshader")
const REVEAL_DIRECTOR_SCRIPT := preload("res://game/world/approaches/sundered_keep/sundered_keep_reveal_director.gd")

const USE_ROUTE_MASTER := true

const APPROACH_ROUTE_MASTER := "res://content/sprites/world/return_causeway/path/sundered_keep_approach_route_master.png"

const APPROACH_OCEAN_VOID_UNDERLAY := "res://content/backgrounds/sundered_keep/approach/approach_ocean_void_underlay.png"
const APPROACH_CLIFF_SPIRES_UNDERLAY := "res://content/backgrounds/sundered_keep/approach/approach_cliff_spires_underlay.png"
const APPROACH_ROUTE_CONTACT_SHADOW := "res://content/backgrounds/sundered_keep/approach/approach_route_contact_shadow.png"
const APPROACH_EDGE_MIST_WRAP := "res://content/backgrounds/sundered_keep/approach/approach_edge_mist_wrap.png"
const APPROACH_FIRST_VISTA_HORIZON := "res://content/backgrounds/sundered_keep/approach/approach_first_vista_horizon.png"
const APPROACH_FIRST_VISTA_FOG_VEIL := "res://content/backgrounds/sundered_keep/approach/approach_first_vista_fog_veil.png"
const APPROACH_FINAL_GATE_SHADOW_VEIL := "res://content/backgrounds/sundered_keep/approach/approach_final_gate_shadow_veil.png"

const APPROACH_FOG_STRIP_01 := "res://content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_01.png"
const APPROACH_FOG_STRIP_02 := "res://content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_02.png"
const APPROACH_FOG_STRIP_03 := "res://content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_03.png"

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

const RETURN_CAUSEWAY_SCENE_PATH := "res://game/world/sundered_keep/return_causeway/ReturnCausewayApproach.tscn"
const SUNDERED_KEEP_MAP_SCRIPT_PATH := "res://game/world/sundered_keep/sundered_keep_map.gd"
# Temporary production sanity switch. Keep the authored Return Causeway branch
# available for focused testing while the default ingress goes straight to the Keep.
const BYPASS_RETURN_CAUSEWAY_FOR_KEEP_TESTING := false
const ROUTE_VERTICAL_OFFSET := 180.0
const BOUNDARY_RAIL_RADIUS := 10.0

@export var bypass_return_causeway_for_keep_testing := BYPASS_RETURN_CAUSEWAY_FOR_KEEP_TESTING

const RECT_ROUTE_MASTER := Rect2(Vector2(-620.0, -660.0), Vector2(2048.0, 1706.0))
const RECT_APPROACH_UNDERLAY := Rect2(Vector2(-1536.0, -1236.0), Vector2(3392.0, 2718.0))
const RECT_FIRST_VISTA_HORIZON := Rect2(Vector2(-1000.0, -980.0), Vector2(2600.0, 1460.0))
const RECT_FIRST_VISTA_FOG_VEIL := Rect2(Vector2(-1000.0, -360.0), Vector2(2600.0, 720.0))
const RECT_FINAL_GATE_SHADOW_VEIL := Rect2(Vector2(-1000.0, -520.0), Vector2(2600.0, 900.0))
const RECT_FOG_STRIP_01 := Rect2(Vector2(-880.0, -430.0), Vector2(1500.0, 520.0))
const RECT_FOG_STRIP_02 := Rect2(Vector2(-260.0, -420.0), Vector2(1500.0, 520.0))
const RECT_FOG_STRIP_03 := Rect2(Vector2(320.0, -410.0), Vector2(1500.0, 520.0))
const RECT_CAMERA_BOUNDS := Rect2(Vector2(-1280.0, -980.0), Vector2(2880.0, 2206.0))
const RECT_BACKDROP_VOID_FILL := Rect2(Vector2(-2048.0, -1748.0), Vector2(4416.0, 3742.0))
const BACKDROP_VOID_COLOR := Color(0.018, 0.043, 0.057, 1.0)
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

const ENTRY_SPAWN_POS := Vector2(-163.0, 430.0)
const REVEAL_START_POS := Vector2(-40.0, 120.0)
const REVEAL_FULL_POS := Vector2(-150.0, -175.0)
const MID_GAMEPLAY_START_POS := Vector2(50.0, -235.0)
const SECOND_VISTA_START_POS := Vector2(300.0, -305.0)
const SECOND_VISTA_FULL_POS := Vector2(590.0, -305.0)
const SECOND_VISTA_END_POS := Vector2(830.0, -305.0)
const TRAVERSE_END_POS := Vector2(915.0, -305.0)
const RETURN_TOPDOWN_POS := Vector2(980.0, -305.0)
const LEVEL_EXIT_POS := Vector2(1240.0, -218.0)

const BOUNDARY_SEGMENTS := [
	[Vector2(-214.3, 515.0), Vector2(-240.7, 420.5)],
	[Vector2(-240.7, 420.5), Vector2(-245.7, 304.7)],
	[Vector2(-245.7, 304.7), Vector2(-285.9, 247.3)],
	[Vector2(-285.9, 247.3), Vector2(-210.5, 150.2)],
	[Vector2(-210.5, 150.2), Vector2(-253.5, 85.0)],
	[Vector2(-253.5, 85.0), Vector2(-236.5, 43.0)],
	[Vector2(-236.5, 43.0), Vector2(-245.3, 1.8)],
	[Vector2(-245.3, 1.8), Vector2(-276.9, -23.0)],
	[Vector2(-276.9, -23.0), Vector2(-405.5, -197.8)],
	[Vector2(-405.5, -197.8), Vector2(-438.9, -165.4)],
	[Vector2(-438.9, -165.4), Vector2(-577.3, -251.2)],
	[Vector2(-577.3, -251.2), Vector2(-543.5, -287.0)],
	[Vector2(-543.5, -287.0), Vector2(-394.7, -320.4)],
	[Vector2(-394.7, -320.4), Vector2(-330.0, -324.8)],
	[Vector2(-330.0, -324.8), Vector2(-305.2, -314.4)],
	[Vector2(-305.2, -314.4), Vector2(-207.5, -433.1)],
	[Vector2(-207.5, -433.1), Vector2(-150.7, -441.1)],
	[Vector2(-150.7, -441.1), Vector2(-94.5, -427.5)],
	[Vector2(-94.5, -427.5), Vector2(-26.5, -432.7)],
	[Vector2(-26.5, -432.7), Vector2(199.3, -421.9)],
	[Vector2(199.3, -421.9), Vector2(503.8, -392.9)],
	[Vector2(503.8, -392.9), Vector2(972.4, -509.4)],
	[Vector2(972.4, -509.4), Vector2(997.5, -366.3)],
	[Vector2(997.5, -366.3), Vector2(1086.9, -338.5)],
	[Vector2(1086.9, -338.5), Vector2(1232.7, -300.2)],
	[Vector2(1232.7, -300.2), Vector2(1223.1, -225.2)],
	[Vector2(1223.1, -225.2), Vector2(983.3, -270.4)],
	[Vector2(983.3, -270.4), Vector2(945.9, -314.2)],
	[Vector2(945.9, -314.2), Vector2(901.7, -342.4)],
	[Vector2(901.7, -342.4), Vector2(803.0, -311.4)],
	[Vector2(803.0, -311.4), Vector2(479.7, -298.8)],
	[Vector2(479.7, -298.8), Vector2(225.4, -312.0)],
	[Vector2(225.4, -312.0), Vector2(-96.1, -338.8)],
	[Vector2(-96.1, -338.8), Vector2(-194.4, -332.2)],
	[Vector2(-194.4, -332.2), Vector2(-239.0, -286.0)],
	[Vector2(-239.0, -286.0), Vector2(-241.8, -255.2)],
	[Vector2(-241.8, -255.2), Vector2(-285.2, -202.2)],
	[Vector2(-285.2, -202.2), Vector2(-320.4, -228.4)],
	[Vector2(-320.4, -228.4), Vector2(-318.4, -180.0)],
	[Vector2(-318.4, -180.0), Vector2(-155.5, -41.8)],
	[Vector2(-155.5, -41.8), Vector2(-183.6, 30.4)],
	[Vector2(-183.6, 30.4), Vector2(-139.2, 126.1)],
	[Vector2(-139.2, 126.1), Vector2(-115.8, 138.7)],
	[Vector2(-115.8, 138.7), Vector2(-150.8, 222.2)],
	[Vector2(-150.8, 222.2), Vector2(-110.8, 244.0)],
	[Vector2(-110.8, 244.0), Vector2(-132.6, 433.6)],
	[Vector2(-132.6, 433.6), Vector2(-93.3, 532.6)],
	[Vector2(-93.3, 532.6), Vector2(-4.3, 581.4)],
	[Vector2(-4.3, 581.4), Vector2(98.3, 708.5)],
	[Vector2(98.3, 708.5), Vector2(-3.7, 777.3)],
	[Vector2(-3.7, 777.3), Vector2(-31.5, 810.9)],
	[Vector2(-31.5, 810.9), Vector2(-156.5, 844.3)],
	[Vector2(-156.5, 844.3), Vector2(-298.2, 790.1)],
	[Vector2(-298.2, 790.1), Vector2(-371.0, 703.2)],
	[Vector2(-371.0, 703.2), Vector2(-377.6, 664.5)],
	[Vector2(-377.6, 664.5), Vector2(-342.6, 614.2)],
	[Vector2(-342.6, 614.2), Vector2(-214.6, 516.6)],
]

const AUTHORING_MARKERS := {
	"spawn": {
		"node_name": "EntrySpawn",
		"label": "SPAWN",
		"kind": "spawn",
		"position": Vector2(-159.4, 667.0),
	},
	"return_causeway": {
		"node_name": "ReturnTopdown",
		"label": "RETURN CAUSEWAY",
		"kind": "return_causeway",
		"position": Vector2(1132.7, -285.5),
	},
	"level_exit": {
		"node_name": "LevelExit",
		"label": "LEVEL EXIT",
		"kind": "level_exit",
		"position": Vector2(1131.7, -287.6),
	},
}

var _ingress_config: Dictionary = {}

var underlay_root: Node2D = null
var vista_root: Node2D = null
var _grand_vista_root: Node2D = null
var playable_root: Node2D = null
var occlusion_root: Node2D = null
var collision_root: Node2D = null
var markers_root: Node2D = null
var event_markers_root: Node2D = null
var event_runtime_root: Node2D = null

var entry_spawn: Marker2D = null
var reveal_start: Marker2D = null
var reveal_full: Marker2D = null
var mid_gameplay_start: Marker2D = null
var traverse_end: Marker2D = null
var return_topdown: Marker2D = null
var second_vista_start: Marker2D = null
var second_vista_full: Marker2D = null
var second_vista_end: Marker2D = null
var vista_controller: SunderedKeepVistaController = null
var reveal_director: Node = null
var exit_transition_trigger: SunderedKeepTransitionTrigger = null
var main_map: Node = null
var main_return_position := Vector2.ZERO
var _level_exit_trigger: Area2D = null


func _ready() -> void:
	add_to_group("sundered_keep_approach")
	add_to_group("world_ingress_approach")
	_remove_stale_proxy_nodes()
	_ensure_roots()
	_build_visuals()
	_ensure_vista_controller()
	_ensure_reveal_director()
	_enforce_presentation_isolation()
	call_deferred("_finish_physics_setup")


func configure_ingress(config: Dictionary) -> void:
	_ingress_config = config.duplicate(true)
	_apply_ingress_config_to_trigger()


func configure_connection(p_main_map: Node, p_main_return_position: Vector2) -> void:
	main_map = p_main_map
	main_return_position = p_main_return_position
	_ingress_config["return_world_position"] = p_main_return_position
	_apply_ingress_config_to_trigger()


func enter_from_main(p_actor: Node) -> void:
	if p_actor is Node2D:
		(p_actor as Node2D).global_position = get_entry_position()
	_refresh_camera()
	_enforce_presentation_isolation()


func get_entry_position() -> Vector2:
	var marker_position := _get_authoring_marker_position("spawn", ENTRY_SPAWN_POS)
	return global_position + _route_point(marker_position)


func get_camera_bounds() -> Rect2:
	return Rect2(global_position + RECT_CAMERA_BOUNDS.position, RECT_CAMERA_BOUNDS.size)


func _finish_physics_setup() -> void:
	if not is_inside_tree():
		return
	_build_collision()
	_build_event_markers()
	_apply_ingress_config_to_trigger()
	if reveal_director != null:
		reveal_director.refresh_bindings()


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
	event_markers_root = _ensure_plain_node2d("EventMarkers")
	event_runtime_root = _ensure_plain_node2d("EventRuntime")

	entry_spawn = _ensure_marker("EntrySpawn", _route_point(ENTRY_SPAWN_POS))
	reveal_start = _ensure_marker("RevealStart", _route_point(REVEAL_START_POS))
	reveal_full = _ensure_marker("RevealFull", _route_point(REVEAL_FULL_POS))
	mid_gameplay_start = _ensure_marker("MidGameplayStart", _route_point(MID_GAMEPLAY_START_POS))
	second_vista_start = _ensure_marker("SecondVistaStart", _route_point(SECOND_VISTA_START_POS))
	second_vista_full = _ensure_marker("SecondVistaFull", _route_point(SECOND_VISTA_FULL_POS))
	second_vista_end = _ensure_marker("SecondVistaEnd", _route_point(SECOND_VISTA_END_POS))
	traverse_end = _ensure_marker("TraverseEnd", _route_point(TRAVERSE_END_POS))
	return_topdown = _ensure_marker("ReturnTopdown", _route_point(RETURN_TOPDOWN_POS))


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
	root.z_as_relative = true
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
	occlusion_root.modulate.a = 1.0

	_add_backdrop_void_fill()
	_add_fitted_sprite(underlay_root, "ApproachOceanVoidUnderlay", APPROACH_OCEAN_VOID_UNDERLAY, RECT_APPROACH_UNDERLAY, -30, Color.WHITE)
	_apply_soft_rect_feather(
		_add_fitted_sprite(underlay_root, "ApproachCliffSpiresUnderlay", APPROACH_CLIFF_SPIRES_UNDERLAY, RECT_APPROACH_UNDERLAY, -20, Color(1.0, 1.0, 1.0, 0.75)),
		Vector4(0.12, 0.12, 0.14, 0.22)
	)
	_add_fitted_sprite(underlay_root, "ApproachRouteContactShadow", APPROACH_ROUTE_CONTACT_SHADOW, _route_rect(RECT_ROUTE_MASTER), -5, Color(1.0, 1.0, 1.0, 0.85))

	_apply_soft_rect_feather(
		_add_fitted_sprite(vista_root, "FarKeepSilhouetteLayerA", APPROACH_FIRST_VISTA_HORIZON, Rect2(-1120.0, -1040.0, 2840.0, 1540.0), -20, Color(0.30, 0.42, 0.52, 0.24)),
		Vector4(0.10, 0.10, 0.12, 0.22)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(vista_root, "FarKeepSilhouetteLayerB", APPROACH_FIRST_VISTA_HORIZON, Rect2(-1060.0, -1008.0, 2720.0, 1500.0), -10, Color(0.42, 0.53, 0.62, 0.32)),
		Vector4(0.08, 0.08, 0.10, 0.20)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(vista_root, "ApproachFirstVistaHorizon", APPROACH_FIRST_VISTA_HORIZON, RECT_FIRST_VISTA_HORIZON, 0, Color.WHITE),
		Vector4(0.06, 0.06, 0.08, 0.18)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(vista_root, "ApproachFirstVistaFogVeil", APPROACH_FIRST_VISTA_FOG_VEIL, RECT_FIRST_VISTA_FOG_VEIL, 10, Color(1.0, 1.0, 1.0, 0.65)),
		Vector4(0.08, 0.08, 0.18, 0.24)
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

	if USE_ROUTE_MASTER:
		_add_fitted_sprite(playable_root, "ApproachRouteMaster", APPROACH_ROUTE_MASTER, _route_rect(RECT_ROUTE_MASTER), 0, Color.WHITE)
	else:
		_build_legacy_path_chunks()

	_add_fitted_sprite(occlusion_root, "ApproachEdgeMistWrap", APPROACH_EDGE_MIST_WRAP, _route_rect(RECT_ROUTE_MASTER), 5, Color(1.0, 1.0, 1.0, 0.55))
	_add_fitted_sprite(occlusion_root, "ApproachFogStrip01", APPROACH_FOG_STRIP_01, _route_rect(RECT_FOG_STRIP_01), 8, Color(1.0, 1.0, 1.0, 0.28))
	_add_fitted_sprite(occlusion_root, "ApproachFogStrip02", APPROACH_FOG_STRIP_02, _route_rect(RECT_FOG_STRIP_02), 9, Color(1.0, 1.0, 1.0, 0.22))
	_add_fitted_sprite(occlusion_root, "ApproachFogStrip03", APPROACH_FOG_STRIP_03, _route_rect(RECT_FOG_STRIP_03), 10, Color(1.0, 1.0, 1.0, 0.18))
	_add_reveal_moonlight_cue()
	_add_fitted_sprite(occlusion_root, "ApproachFinalGateShadowVeil", APPROACH_FINAL_GATE_SHADOW_VEIL, _route_rect(RECT_FINAL_GATE_SHADOW_VEIL), 20, Color(1.0, 1.0, 1.0, 0.0))


func _add_reveal_moonlight_cue() -> PointLight2D:
	var light := PointLight2D.new()
	light.name = "RevealMoonlightCue"
	light.position = Vector2(250.0, -310.0)
	light.color = Color(0.56, 0.78, 1.0, 1.0)
	light.energy = 0.0
	light.texture_scale = 3.2
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 0.72), Color(1.0, 1.0, 1.0, 0.0)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var texture := GradientTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	light.texture = texture
	occlusion_root.add_child(light)
	return light


func _build_legacy_path_chunks() -> void:
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
	sprite.z_as_relative = true
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
	shadow.z_as_relative = true
	shadow.z_index = z
	return shadow


func _add_backdrop_void_fill() -> Polygon2D:
	var fill := Polygon2D.new()
	fill.name = "BackdropVoidFill"
	fill.polygon = PackedVector2Array([
		RECT_BACKDROP_VOID_FILL.position,
		Vector2(RECT_BACKDROP_VOID_FILL.end.x, RECT_BACKDROP_VOID_FILL.position.y),
		RECT_BACKDROP_VOID_FILL.end,
		Vector2(RECT_BACKDROP_VOID_FILL.position.x, RECT_BACKDROP_VOID_FILL.end.y),
	])
	fill.color = BACKDROP_VOID_COLOR
	fill.z_as_relative = true
	fill.z_index = -100
	fill.set_meta("coverage_rect", RECT_BACKDROP_VOID_FILL)
	underlay_root.add_child(fill)
	return fill


func _refresh_camera() -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", self)


func _enforce_presentation_isolation() -> void:
	_set_world_branch_visible(get_node_or_null("/root/GameRoot/World/ProcGenRuntime"), false)
	_set_world_branch_visible(get_node_or_null("/root/GameRoot/World/ConnectedMaps"), false)
	var ui := get_node_or_null("/root/GameRoot/UI")
	if ui != null and ui.has_method("set_world_presentation_mode"):
		ui.call("set_world_presentation_mode", &"vista_approach")
	var actor := get_node_or_null("/root/GameRoot/World/Operator")
	if actor != null and actor.has_method("set_vista_presentation_mode"):
		actor.call("set_vista_presentation_mode", true)


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
		if segment.size() < 2:
			continue
		_add_boundary_segment(
			body,
			"BoundarySegment_%03d" % index,
			_route_point(segment[0] as Vector2),
			_route_point(segment[1] as Vector2)
		)
		index += 1


func _build_event_markers() -> void:
	if event_markers_root == null or event_runtime_root == null:
		return
	_clear_children(event_markers_root)
	_clear_children(event_runtime_root)
	_level_exit_trigger = null
	# This is the visual Vista Approach, not the Keep gatehouse/causeway level.
	# Keep-specific key, gate, enemy-spawn, and authoring-marker runtime was
	# previously placed here by mistake and made the vista route impassable.
	_build_level_exit_trigger()


func _add_event_marker(marker_id: String, marker_data: Dictionary) -> Marker2D:
	var position := _route_point(marker_data.get("position", Vector2.ZERO) as Vector2)
	var kind := str(marker_data.get("kind", marker_id))
	var label := str(marker_data.get("label", marker_id.to_upper()))
	var marker := Marker2D.new()
	marker.name = marker_id.to_pascal_case()
	marker.position = position
	marker.set_meta("marker_id", marker_id)
	marker.set_meta("marker_kind", kind)
	marker.set_meta("label", label)
	event_markers_root.add_child(marker)
	_add_event_marker_visual(marker, label, _event_marker_color(kind))
	return marker


func _add_event_marker_visual(parent: Node2D, label: String, color: Color) -> void:
	var ring := Polygon2D.new()
	ring.name = "MarkerSwatch"
	ring.polygon = PackedVector2Array([
		Vector2(0.0, -14.0),
		Vector2(14.0, 0.0),
		Vector2(0.0, 14.0),
		Vector2(-14.0, 0.0),
	])
	ring.color = color
	ring.z_as_relative = true
	ring.z_index = 180
	parent.add_child(ring)
	var text := Label.new()
	text.name = "MarkerLabel"
	text.text = label
	text.position = Vector2(18.0, -18.0)
	text.z_as_relative = true
	text.z_index = 181
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78, 0.94))
	parent.add_child(text)


func _event_marker_color(kind: String) -> Color:
	match kind:
		"spawn":
			return Color(0.42, 0.85, 1.0, 0.85)
		"return_causeway":
			return Color(0.56, 0.72, 1.0, 0.85)
		"key":
			return Color(1.0, 0.82, 0.30, 0.90)
		"gate":
			return Color(1.0, 0.42, 0.24, 0.90)
		"level_exit":
			return Color(0.46, 1.0, 0.58, 0.90)
		"enemy_spawn":
			return Color(1.0, 0.20, 0.24, 0.90)
		_:
			return Color(0.92, 0.92, 0.92, 0.85)


func _build_level_exit_trigger() -> void:
	var trigger := SunderedKeepTransitionTrigger.new()
	if bypass_return_causeway_for_keep_testing:
		trigger.target_scene_path = SUNDERED_KEEP_MAP_SCRIPT_PATH
		trigger.target_node_name = &"SunderedKeepMap"
		trigger.target_level_id = &"sundered_keep_front_gate"
	else:
		trigger.target_scene_path = RETURN_CAUSEWAY_SCENE_PATH
		trigger.target_node_name = &"ReturnCausewayApproach"
		trigger.target_level_id = &"return_causeway"
	trigger.vista_controller_path = NodePath("../../VistaController")
	trigger.source_scene_path = NodePath("../..")
	trigger.return_world_position = main_return_position
	trigger.deactivate_source_on_transition = true
	trigger.free_source_on_transition = true
	_level_exit_trigger = trigger
	exit_transition_trigger = trigger
	_level_exit_trigger.name = "LevelExitTrigger"
	_level_exit_trigger.position = _route_point(_get_authoring_marker_position("level_exit", LEVEL_EXIT_POS))
	_level_exit_trigger.required_entry_direction = Vector2.RIGHT
	event_runtime_root.add_child(_level_exit_trigger)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(72.0, 104.0)
	shape.shape = rectangle
	_level_exit_trigger.add_child(shape)
	_build_level_exit_affordance(_level_exit_trigger.position)


func _build_level_exit_affordance(exit_position: Vector2) -> void:
	var affordance := Node2D.new()
	affordance.name = "LevelExitAffordance"
	affordance.position = exit_position
	affordance.z_index = 130
	event_runtime_root.add_child(affordance)

	var threshold := Polygon2D.new()
	threshold.name = "WalkableThreshold"
	threshold.polygon = PackedVector2Array([
		Vector2(-38.0, -54.0), Vector2(38.0, -54.0),
		Vector2(38.0, 54.0), Vector2(-38.0, 54.0),
	])
	threshold.color = Color(0.20, 0.42, 0.46, 0.38)
	affordance.add_child(threshold)

	var prompt_back := Polygon2D.new()
	prompt_back.name = "PromptBackdrop"
	prompt_back.polygon = PackedVector2Array([
		Vector2(-92.0, -92.0), Vector2(92.0, -92.0),
		Vector2(92.0, -62.0), Vector2(-92.0, -62.0),
	])
	prompt_back.color = Color(0.01, 0.025, 0.035, 0.88)
	affordance.add_child(prompt_back)

	var prompt := Label.new()
	prompt.name = "DestinationPrompt"
	prompt.text = "ENTER SUNDERED KEEP  >"
	prompt.position = Vector2(-82.0, -88.0)
	prompt.size = Vector2(164.0, 24.0)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_color_override("font_color", Color(0.78, 0.91, 0.90, 1.0))
	affordance.add_child(prompt)


func _add_boundary_segment(parent: StaticBody2D, node_name: String, a: Vector2, b: Vector2) -> CollisionShape2D:
	var direction := b - a
	var length := direction.length()
	var rail := CapsuleShape2D.new()
	rail.radius = BOUNDARY_RAIL_RADIUS
	rail.height = maxf(length + BOUNDARY_RAIL_RADIUS * 2.0, BOUNDARY_RAIL_RADIUS * 2.0)

	var col := CollisionShape2D.new()
	col.name = node_name
	col.shape = rail
	col.position = (a + b) * 0.5
	if length > 0.001:
		col.rotation = direction.angle() - PI * 0.5
	col.set_meta("boundary_a", a)
	col.set_meta("boundary_b", b)
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
	vista_controller.camera_path = NodePath("/root/GameRoot/World/Camera2D")
	vista_controller.entry_marker_path = NodePath("../Markers/EntrySpawn")
	vista_controller.reveal_full_marker_path = NodePath("../Markers/RevealFull")
	vista_controller.mid_gameplay_marker_path = NodePath("../Markers/MidGameplayStart")
	vista_controller.vista_root_path = NodePath("../VistaRoot")
	vista_controller.grand_vista_root_path = NodePath("../GrandVistaRoot")
	vista_controller.vista_fog_band_path = NodePath("../VistaRoot/ApproachFirstVistaFogVeil")
	vista_controller.fog_underlay_path = NodePath("")
	vista_controller.occlusion_root_path = NodePath("../OcclusionRoot")
	vista_controller.cliff_occluder_path = NodePath("../OcclusionRoot/ApproachEdgeMistWrap")
	vista_controller.wall_shadow_occluder_path = NodePath("../OcclusionRoot/ApproachFinalGateShadowVeil")
	vista_controller.final_gate_shadow_veil_path = NodePath("../OcclusionRoot/ApproachFinalGateShadowVeil")
	vista_controller.distant_keep_path = NodePath("../VistaRoot/ApproachFirstVistaHorizon")
	vista_controller.second_vista_start_marker_path = NodePath("../Markers/SecondVistaStart")
	vista_controller.second_vista_full_marker_path = NodePath("../Markers/SecondVistaFull")
	vista_controller.second_vista_end_marker_path = NodePath("../Markers/SecondVistaEnd")
	vista_controller.refresh_bindings()
	vista_controller.apply_progress(0.0)


func _ensure_reveal_director() -> void:
	reveal_director = get_node_or_null("RevealDirector")
	if reveal_director == null:
		reveal_director = REVEAL_DIRECTOR_SCRIPT.new()
		reveal_director.name = "RevealDirector"
		add_child(reveal_director)
	reveal_director.player_path = NodePath("/root/GameRoot/World/Operator")
	reveal_director.entry_marker_path = NodePath("../Markers/EntrySpawn")
	reveal_director.threshold_marker_path = NodePath("../Markers/RevealStart")
	reveal_director.vista_controller_path = NodePath("../VistaController")
	reveal_director.near_fog_path = NodePath("../OcclusionRoot/ApproachFogStrip01")
	reveal_director.mid_fog_path = NodePath("../OcclusionRoot/ApproachFogStrip02")
	reveal_director.far_fog_path = NodePath("../OcclusionRoot/ApproachFogStrip03")
	reveal_director.edge_mist_path = NodePath("../OcclusionRoot/ApproachEdgeMistWrap")
	reveal_director.reveal_light_path = NodePath("../OcclusionRoot/RevealMoonlightCue")
	reveal_director.destination_prompt_path = NodePath("../EventRuntime/LevelExitAffordance")
	reveal_director.refresh_bindings()


func _apply_ingress_config_to_trigger() -> void:
	if exit_transition_trigger == null:
		return
	if _ingress_config.has("return_world_position"):
		exit_transition_trigger.return_world_position = _ingress_config["return_world_position"]


func _is_player_body(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("operator") or String(body.name) == "Operator"


func _set_world_branch_visible(branch: Node, value: bool) -> void:
	if branch == null:
		return
	if branch is CanvasItem:
		(branch as CanvasItem).visible = value
	branch.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED


func _get_authoring_marker_position(marker_id: String, fallback: Vector2) -> Vector2:
	var marker_data: Variant = AUTHORING_MARKERS.get(marker_id, {})
	if marker_data is Dictionary:
		var position: Variant = (marker_data as Dictionary).get("position", fallback)
		if position is Vector2:
			return position
	return fallback


func get_authoring_marker_state() -> Dictionary:
	var result := {}
	for marker_id: String in AUTHORING_MARKERS.keys():
		var marker_data := AUTHORING_MARKERS[marker_id] as Dictionary
		var source_position := marker_data.get("position", Vector2.ZERO) as Vector2
		var runtime_position := _route_point(source_position)
		result[marker_id] = {
			"kind": str(marker_data.get("kind", marker_id)),
			"label": str(marker_data.get("label", marker_id)),
			"source_position": source_position,
			"runtime_position": runtime_position,
		}
	return result


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS


func get_authoring_marker_schema() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for marker_id: String in AUTHORING_MARKERS.keys():
		var data := (AUTHORING_MARKERS[marker_id] as Dictionary).duplicate(true)
		data["id"] = marker_id
		result.append(data)
	return result


func authoring_to_runtime_point(point: Vector2) -> Vector2:
	return _route_point(point)


func runtime_to_authoring_point(point: Vector2) -> Vector2:
	return point - Vector2(0.0, ROUTE_VERTICAL_OFFSET)


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		child.queue_free()


func _route_point(point: Vector2) -> Vector2:
	return point + Vector2(0.0, ROUTE_VERTICAL_OFFSET)


func _route_rect(rect: Rect2) -> Rect2:
	return Rect2(_route_point(rect.position), rect.size)
