extends Node2D
class_name SunderedKeepApproach

const SOFT_RECT_FEATHER_SHADER := preload("res://game/world/approaches/sundered_keep/soft_rect_feather.gdshader")

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

const TARGET_SCENE_PATH := "res://game/world/sundered_keep/sundered_keep_map.gd"
const ROUTE_VERTICAL_OFFSET := 180.0

const RECT_ROUTE_MASTER := Rect2(Vector2(-620.0, -660.0), Vector2(2048.0, 1706.0))
const RECT_APPROACH_UNDERLAY := Rect2(Vector2(-1000.0, -900.0), Vector2(2600.0, 1800.0))
const RECT_FIRST_VISTA_HORIZON := Rect2(Vector2(-1000.0, -980.0), Vector2(2600.0, 1460.0))
const RECT_FIRST_VISTA_FOG_VEIL := Rect2(Vector2(-1000.0, -360.0), Vector2(2600.0, 720.0))
const RECT_FINAL_GATE_SHADOW_VEIL := Rect2(Vector2(-1000.0, -520.0), Vector2(2600.0, 900.0))
const RECT_FOG_STRIP_01 := Rect2(Vector2(-880.0, -430.0), Vector2(1500.0, 520.0))
const RECT_FOG_STRIP_02 := Rect2(Vector2(-260.0, -420.0), Vector2(1500.0, 520.0))
const RECT_FOG_STRIP_03 := Rect2(Vector2(320.0, -410.0), Vector2(1500.0, 520.0))
const RECT_CAMERA_BOUNDS := Rect2(Vector2(-1280.0, -980.0), Vector2(2880.0, 2206.0))
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

const ENTRY_SPAWN_POS := Vector2(45.0, 430.0)
const REVEAL_START_POS := Vector2(-40.0, 120.0)
const REVEAL_FULL_POS := Vector2(-150.0, -175.0)
const MID_GAMEPLAY_START_POS := Vector2(50.0, -235.0)
const SECOND_VISTA_START_POS := Vector2(300.0, -305.0)
const SECOND_VISTA_FULL_POS := Vector2(590.0, -305.0)
const SECOND_VISTA_END_POS := Vector2(830.0, -305.0)
const TRAVERSE_END_POS := Vector2(915.0, -305.0)
const RETURN_TOPDOWN_POS := Vector2(980.0, -305.0)

const BOUNDARY_SEGMENTS := [
	[Vector2(-86.9, 506.4), Vector2(-86.5, 427.2)],
	[Vector2(-148.5, 317.3), Vector2(-78.5, 215.7)],
	[Vector2(-90.5, 167.3), Vector2(-116.1, 125.7)],
	[Vector2(-98.1, 80.1), Vector2(-115.7, 20.0)],
	[Vector2(-150.5, -13.2), Vector2(-228.8, -120.8)],
	[Vector2(-232.8, -140.4), Vector2(-274.5, -194.6)],
	[Vector2(-310.5, -242.2), Vector2(-360.1, -187.0)],
	[Vector2(-350.1, -171.0), Vector2(-373.7, -155.0)],
	[Vector2(-391.7, -183.4), Vector2(-418.5, -225.0)],
	[Vector2(-426.5, -245.4), Vector2(-462.9, -266.2)],
	[Vector2(-475.4, -290.8), Vector2(-491.8, -288.4)],
	[Vector2(-517.8, -281.6), Vector2(-525.4, -297.6)],
	[Vector2(-544.2, -307.6), Vector2(-570.6, -331.1)],
	[Vector2(-551.9, -349.1), Vector2(-550.7, -360.3)],
	[Vector2(-525.1, -386.3), Vector2(-480.3, -400.7)],
	[Vector2(-450.7, -408.7), Vector2(-413.9, -415.5)],
	[Vector2(-296.0, -440.8), Vector2(-179.9, -457.3)],
	[Vector2(-176.3, -412.9), Vector2(-127.1, -466.9)],
	[Vector2(-90.3, -536.1), Vector2(-39.4, -601.6)],
	[Vector2(39.4, -604.4), Vector2(88.8, -582.8)],
	[Vector2(112.8, -574.0), Vector2(129.6, -595.2)],
	[Vector2(156.8, -592.4), Vector2(277.7, -584.4)],
	[Vector2(320.5, -568.4), Vector2(342.5, -564.4)],
	[Vector2(375.7, -572.4), Vector2(417.7, -573.2)],
	[Vector2(509.6, -566.8), Vector2(522.6, -555.6)],
	[Vector2(575.4, -546.8), Vector2(643.0, -538.8)],
	[Vector2(704.7, -526.0), Vector2(729.9, -531.6)],
	[Vector2(814.7, -515.4), Vector2(876.3, -507.4)],
	[Vector2(947.5, -506.6), Vector2(1148.2, -511.8)],
	[Vector2(1147.0, -489.4), Vector2(1124.6, -464.6)],
	[Vector2(1120.6, -433.0), Vector2(1117.8, -415.4)],
	[Vector2(1127.0, -378.6), Vector2(1134.6, -370.2)],
	[Vector2(1174.7, -304.0), Vector2(1189.1, -310.4)],
	[Vector2(1203.1, -313.2), Vector2(1224.7, -318.8)],
	[Vector2(1247.1, -322.8), Vector2(1284.7, -316.0)],
	[Vector2(1299.5, -293.6), Vector2(1323.9, -295.2)],
	[Vector2(1342.3, -276.8), Vector2(1338.3, -262.0)],
	[Vector2(1337.5, -244.8), Vector2(1321.1, -236.0)],
	[Vector2(1307.1, -220.4), Vector2(1277.9, -212.8)],
	[Vector2(1217.9, -228.8), Vector2(1220.3, -251.2)],
	[Vector2(1203.9, -257.2), Vector2(1196.3, -247.6)],
	[Vector2(1183.5, -239.6), Vector2(1160.7, -266.8)],
	[Vector2(1145.5, -276.0), Vector2(1137.5, -298.0)],
	[Vector2(1099.7, -338.0), Vector2(1055.7, -365.2)],
	[Vector2(987.6, -298.8), Vector2(947.2, -317.6)],
	[Vector2(933.6, -309.2), Vector2(896.0, -307.6)],
	[Vector2(879.6, -323.2), Vector2(841.2, -322.8)],
	[Vector2(792.0, -364.4), Vector2(778.0, -361.6)],
	[Vector2(745.6, -366.0), Vector2(735.6, -382.8)],
	[Vector2(732.3, -440.7), Vector2(701.1, -434.7)],
	[Vector2(650.5, -455.1), Vector2(586.9, -448.7)],
	[Vector2(531.6, -450.7), Vector2(496.0, -444.3)],
	[Vector2(461.6, -441.5), Vector2(435.9, -451.9)],
	[Vector2(428.7, -484.7), Vector2(387.9, -455.9)],
	[Vector2(361.5, -447.5), Vector2(346.8, -463.5)],
	[Vector2(314.0, -449.5), Vector2(302.2, -454.7)],
	[Vector2(274.6, -495.5), Vector2(245.0, -505.1)],
	[Vector2(222.6, -480.3), Vector2(120.4, -485.5)],
	[Vector2(100.8, -515.1), Vector2(66.8, -500.3)],
	[Vector2(44.0, -493.5), Vector2(33.2, -488.3)],
	[Vector2(17.6, -487.5), Vector2(-4.8, -485.9)],
	[Vector2(-21.2, -480.7), Vector2(-34.0, -468.3)],
	[Vector2(-50.4, -455.5), Vector2(-118.7, -345.3)],
	[Vector2(-71.5, -326.1), Vector2(-88.7, -300.5)],
	[Vector2(-92.7, -277.7), Vector2(-147.9, -243.7)],
	[Vector2(-174.3, -284.1), Vector2(-205.1, -275.7)],
	[Vector2(-202.7, -245.7), Vector2(-181.1, -185.5)],
	[Vector2(-152.7, -147.9), Vector2(-91.1, -84.7)],
	[Vector2(-70.8, -86.2), Vector2(-58.0, -70.6)],
	[Vector2(-28.4, -23.0), Vector2(-34.4, 5.8)],
	[Vector2(-61.6, 35.0), Vector2(-22.2, 128.6)],
	[Vector2(-31.8, 169.2), Vector2(-33.0, 216.8)],
	[Vector2(-12.2, 225.6), Vector2(-25.8, 284.4)],
	[Vector2(12.3, 320.1), Vector2(13.9, 342.1)],
	[Vector2(-3.7, 395.7), Vector2(10.7, 428.5)],
	[Vector2(-26.5, 429.8), Vector2(-12.9, 503.5)],
	[Vector2(-20.8, 530.6), Vector2(-15.2, 564.6)],
	[Vector2(-0.4, 607.8), Vector2(25.6, 647.8)],
	[Vector2(73.2, 679.0), Vector2(132.4, 759.0)],
	[Vector2(129.2, 790.6), Vector2(141.2, 818.6)],
	[Vector2(130.8, 857.2), Vector2(62.8, 896.0)],
	[Vector2(55.4, 918.9), Vector2(62.2, 949.7)],
	[Vector2(13.8, 968.1), Vector2(-31.8, 986.9)],
	[Vector2(-83.8, 979.7), Vector2(-125.0, 962.9)],
	[Vector2(-151.8, 937.7), Vector2(-143.8, 909.7)],
	[Vector2(-208.8, 861.5), Vector2(-214.5, 829.5)],
	[Vector2(-208.9, 797.5), Vector2(-211.7, 778.9)],
	[Vector2(-215.7, 758.5), Vector2(-148.9, 692.5)],
	[Vector2(-117.2, 662.2), Vector2(-75.2, 621.4)],
	[Vector2(-76.7, 592.7), Vector2(-86.7, 506.7)],
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
var mid_gameplay_start: Marker2D = null
var traverse_end: Marker2D = null
var return_topdown: Marker2D = null
var second_vista_start: Marker2D = null
var second_vista_full: Marker2D = null
var second_vista_end: Marker2D = null
var vista_controller: SunderedKeepVistaController = null
var exit_transition_trigger: SunderedKeepTransitionTrigger = null
var main_map: Node = null
var main_return_position := Vector2.ZERO


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


func configure_connection(p_main_map: Node, p_main_return_position: Vector2) -> void:
	main_map = p_main_map
	main_return_position = p_main_return_position
	_ingress_config["return_world_position"] = p_main_return_position
	_apply_ingress_config_to_trigger()


func enter_from_main(p_actor: Node) -> void:
	if p_actor is Node2D:
		(p_actor as Node2D).global_position = get_entry_position()
	_refresh_camera()


func get_entry_position() -> Vector2:
	if entry_spawn != null:
		return entry_spawn.global_position
	return global_position + ENTRY_SPAWN_POS


func get_camera_bounds() -> Rect2:
	return Rect2(global_position + RECT_CAMERA_BOUNDS.position, RECT_CAMERA_BOUNDS.size)


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

	_add_fitted_sprite(underlay_root, "ApproachOceanVoidUnderlay", APPROACH_OCEAN_VOID_UNDERLAY, RECT_APPROACH_UNDERLAY, -30, Color.WHITE)
	_apply_soft_rect_feather(
		_add_fitted_sprite(underlay_root, "ApproachCliffSpiresUnderlay", APPROACH_CLIFF_SPIRES_UNDERLAY, RECT_APPROACH_UNDERLAY, -20, Color(1.0, 1.0, 1.0, 0.75)),
		Vector4(0.12, 0.12, 0.14, 0.22)
	)
	_add_fitted_sprite(underlay_root, "ApproachRouteContactShadow", APPROACH_ROUTE_CONTACT_SHADOW, _route_rect(RECT_ROUTE_MASTER), -5, Color(1.0, 1.0, 1.0, 0.85))

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
	_add_fitted_sprite(occlusion_root, "ApproachFinalGateShadowVeil", APPROACH_FINAL_GATE_SHADOW_VEIL, _route_rect(RECT_FINAL_GATE_SHADOW_VEIL), 20, Color(1.0, 1.0, 1.0, 0.0))


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


func _refresh_camera() -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", self)


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
			_route_point(segment[0] as Vector2),
			_route_point(segment[1] as Vector2)
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


func _ensure_exit_transition_trigger() -> void:
	exit_transition_trigger = get_node_or_null("ExitTransitionTrigger") as SunderedKeepTransitionTrigger
	if exit_transition_trigger == null:
		exit_transition_trigger = SunderedKeepTransitionTrigger.new()
		exit_transition_trigger.name = "ExitTransitionTrigger"
		add_child(exit_transition_trigger)

	exit_transition_trigger.position = _route_point(RETURN_TOPDOWN_POS)
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


func _route_point(point: Vector2) -> Vector2:
	return point + Vector2(0.0, ROUTE_VERTICAL_OFFSET)


func _route_rect(rect: Rect2) -> Rect2:
	return Rect2(_route_point(rect.position), rect.size)
