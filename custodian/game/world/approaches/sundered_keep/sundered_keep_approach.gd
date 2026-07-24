extends Node2D
class_name SunderedKeepApproach

const SOFT_RECT_FEATHER_SHADER := preload("res://game/world/approaches/sundered_keep/soft_rect_feather.gdshader")
const REVEAL_DIRECTOR_SCRIPT := preload("res://game/world/approaches/sundered_keep/sundered_keep_reveal_director.gd")
const PARALLAX_LAYER_SCRIPT := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_parallax_layer.gd"
)
const ROOF_OCCLUDER_SCRIPT := preload(
	"res://game/world/common/roof_occluder_2d.gd"
)
const ROUTE_MASTER_OCCLUSION_SHADER := preload(
	"res://game/world/approaches/sundered_keep/route_master_occlusion_mask.gdshader"
)
const PARALLAX_RIG_SCRIPT := preload(
	"res://game/world/sundered_keep/presentation/sundered_keep_parallax_rig.gd"
)
const VISTA_DEBUG_PROBE_SCRIPT := preload(
	"res://game/world/approaches/sundered_keep/"
	+ "sundered_keep_vista_debug_probe.gd"
)

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

const ROUTE_VERTICAL_OFFSET := 180.0
const BOUNDARY_RAIL_RADIUS := 10.0

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
const RECT_LABYRINTH_CONTACT_FOG := Rect2(
	Vector2(430.0, -500.0),
	Vector2(1250.0, 560.0)
)

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
const FIRST_REVEAL_TRIGGER_POS := Vector2(-150.0, -175.0)
const FIRST_REVEAL_CAMERA_ANCHOR_POS := Vector2(210.0, -300.0)
const FIRST_REVEAL_TRIGGER_SIZE := Vector2(190.0, 120.0)
const REVEAL_CONTROL_START_POS := REVEAL_FULL_POS
const REVEAL_CONTROL_END_POS := MID_GAMEPLAY_START_POS
const RETURN_TO_GAMEPLAY_TRIGGER_POS := MID_GAMEPLAY_START_POS
const RETURN_TO_GAMEPLAY_TRIGGER_SIZE := Vector2(140.0, 120.0)
const SECOND_REVEAL_TRIGGER_POS := SECOND_VISTA_START_POS
const SECOND_REVEAL_CAMERA_ANCHOR_POS := Vector2(650.0, -420.0)
const SECOND_REVEAL_TRIGGER_SIZE := Vector2(170.0, 140.0)
const FINAL_FOG_OVERSCAN := Vector4(
	384.0,
	320.0,
	896.0,
	640.0
)

const LABYRINTH_ROOF_RECTS := {
	"WestKeepRoof": Rect2(
		Vector2(515.0, -445.0),
		Vector2(460.0, 210.0)
	),
	"CentralKeepRoof": Rect2(
		Vector2(900.0, -455.0),
		Vector2(360.0, 235.0)
	),
	"ExitKeepRoof": Rect2(
		Vector2(1120.0, -355.0),
		Vector2(280.0, 260.0)
	),
}

const LABYRINTH_OCCLUSION_ZONES := {
	"WestKeepRoof": Rect2(
		Vector2(565.0, -250.0),
		Vector2(330.0, 190.0)
	),
	"CentralKeepRoof": Rect2(
		Vector2(860.0, -235.0),
		Vector2(300.0, 205.0)
	),
	"ExitKeepRoof": Rect2(
		Vector2(1090.0, -220.0),
		Vector2(250.0, 220.0)
	),
}

const BOUNDARY_SEGMENTS := [
	[Vector2(-215.0, 514.2), Vector2(-241.7, 418.6)],
	[Vector2(-241.7, 418.6), Vector2(-260.7, 312.3)],
	[Vector2(-260.7, 312.3), Vector2(-299.7, 232.6)],
	[Vector2(-299.7, 232.6), Vector2(-230.8, 138.7)],
	[Vector2(-230.8, 138.7), Vector2(-263.6, 82.7)],
	[Vector2(-263.6, 82.7), Vector2(-249.7, 8.2)],
	[Vector2(-249.7, 8.2), Vector2(-398.7, -175.5)],
	[Vector2(-398.7, -175.5), Vector2(-453.1, -166.1)],
	[Vector2(-453.1, -166.1), Vector2(-597.5, -247.3)],
	[Vector2(-597.5, -247.3), Vector2(-533.3, -306.9)],
	[Vector2(-533.3, -306.9), Vector2(-373.8, -344.3)],
	[Vector2(-373.8, -344.3), Vector2(-322.5, -331.1)],
	[Vector2(-322.5, -331.1), Vector2(-187.4, -446.3)],
	[Vector2(-187.4, -446.3), Vector2(243.0, -428.5)],
	[Vector2(243.0, -428.5), Vector2(685.8, -501.0)],
	[Vector2(685.8, -501.0), Vector2(782.3, -348.6)],
	[Vector2(782.3, -348.6), Vector2(975.8, -323.9)],
	[Vector2(975.8, -323.9), Vector2(1006.3, -240.4)],
	[Vector2(1006.3, -240.4), Vector2(779.8, -196.4)],
	[Vector2(779.8, -196.4), Vector2(723.0, -244.8)],
	[Vector2(723.0, -244.8), Vector2(672.7, -283.3)],
	[Vector2(672.7, -283.3), Vector2(446.0, -252.2)],
	[Vector2(446.0, -252.2), Vector2(212.0, -292.4)],
	[Vector2(212.0, -292.4), Vector2(-23.0, -316.8)],
	[Vector2(-23.0, -316.8), Vector2(-184.9, -321.0)],
	[Vector2(-184.9, -321.0), Vector2(-231.9, -286.4)],
	[Vector2(-231.9, -286.4), Vector2(-275.8, -211.7)],
	[Vector2(-275.8, -211.7), Vector2(-316.1, -180.4)],
	[Vector2(-316.1, -180.4), Vector2(-146.0, -37.9)],
	[Vector2(-146.0, -37.9), Vector2(-162.6, 23.7)],
	[Vector2(-162.6, 23.7), Vector2(-124.0, 127.2)],
	[Vector2(-124.0, 127.2), Vector2(-126.6, 218.0)],
	[Vector2(-126.6, 218.0), Vector2(-107.6, 278.3)],
	[Vector2(-107.6, 278.3), Vector2(-103.8, 418.4)],
	[Vector2(-103.8, 418.4), Vector2(-68.8, 518.1)],
	[Vector2(-68.8, 518.1), Vector2(12.0, 575.4)],
	[Vector2(12.0, 575.4), Vector2(107.2, 711.8)],
	[Vector2(107.2, 711.8), Vector2(-154.2, 870.8)],
	[Vector2(-154.2, 870.8), Vector2(-330.4, 799.0)],
	[Vector2(-330.4, 799.0), Vector2(-410.4, 692.8)],
	[Vector2(-410.4, 692.8), Vector2(-347.9, 591.7)],
	[Vector2(-347.9, 591.7), Vector2(-213.8, 512.5)],
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
		"position": Vector2(751.4, -286.8),
	},
	"level_exit": {
		"node_name": "LevelExit",
		"label": "LEVEL EXIT",
		"kind": "level_exit",
		"position": Vector2(914.9, -273.5),
	},
	"first_reveal_trigger": {
		"node_name": "FirstVistaRevealTrigger",
		"label": "FIRST REVEAL TRIGGER",
		"kind": "presentation_trigger",
		"position": Vector2(-284.4, -292.0),
	},
	"first_reveal_camera_anchor": {
		"node_name": "FirstRevealCameraAnchor",
		"label": "FIRST CAMERA ANCHOR",
		"kind": "camera_anchor",
		"position": Vector2(-135.9, -658.3),
	},
	"reveal_control_start": {
		"node_name": "RevealControlStart",
		"label": "REVEAL CONTROL START",
		"kind": "camera_control",
		"position": REVEAL_CONTROL_START_POS,
	},
	"reveal_control_end": {
		"node_name": "RevealControlEnd",
		"label": "REVEAL CONTROL END",
		"kind": "camera_control",
		"position": REVEAL_CONTROL_END_POS,
	},
	"return_to_gameplay_trigger": {
		"node_name": "ReturnToGameplayTrigger",
		"label": "RETURN TO GAMEPLAY",
		"kind": "presentation_trigger",
		"position": RETURN_TO_GAMEPLAY_TRIGGER_POS,
	},
	"second_reveal_trigger": {
		"node_name": "SecondVistaRevealTrigger",
		"label": "SECOND REVEAL TRIGGER",
		"kind": "presentation_trigger",
		"position": Vector2(595.8, -375.9),
	},
	"second_reveal_camera_anchor": {
		"node_name": "SecondVistaCameraAnchor",
		"label": "SECOND CAMERA ANCHOR",
		"kind": "camera_anchor",
		"position": Vector2(664.5, -660.0),
	},
}

@export_group("Shared Parallax Review Gates")
@export var show_far_cliff_islands := false
@export var show_causeway_far_arches := false
@export var show_lower_cliff_depth := false
@export var show_ocean_mist := false
@export var show_near_edge_mist := false
@export var show_foreground_ruined_arch := false

var underlay_root: Node2D = null
var parallax_root: SunderedKeepParallaxRig = null
var vista_root: Node2D = null
var _grand_vista_root: Node2D = null
var playable_root: Node2D = null
var occlusion_root: Node2D = null
var collision_root: Node2D = null
var markers_root: Node2D = null
var event_markers_root: Node2D = null
var event_runtime_root: Node2D = null
var sequence_triggers_root: Node2D = null
var roof_occlusion_root: Node2D = null

var entry_spawn: Marker2D = null
var reveal_start: Marker2D = null
var reveal_full: Marker2D = null
var mid_gameplay_start: Marker2D = null
var reveal_control_start: Marker2D = null
var reveal_control_end: Marker2D = null
var traverse_end: Marker2D = null
var return_topdown: Marker2D = null
var second_vista_start: Marker2D = null
var second_vista_full: Marker2D = null
var second_vista_end: Marker2D = null
var vista_controller: SunderedKeepVistaController = null
var reveal_director: Node = null
var first_reveal_trigger: Area2D = null
var return_to_gameplay_trigger: Area2D = null
var first_reveal_camera_anchor: Marker2D = null
var second_reveal_trigger: Area2D = null
var second_reveal_camera_anchor: Marker2D = null
var vista_debug_probe: CanvasLayer = null
var _continue_exit: LevelExit2D = null
var _return_world_exit: LevelExit2D = null
var _final_fog_coverage_rect := Rect2()


func _ready() -> void:
	add_to_group("sundered_keep_approach")
	add_to_group("world_ingress_approach")
	_remove_stale_proxy_nodes()
	_ensure_roots()
	_build_visuals()
	_ensure_vista_controller()
	_ensure_reveal_director()
	_ensure_debug_probe()
	_apply_vista_presentation_mode()
	call_deferred("_finish_physics_setup")


func enter_from_main(p_actor: Node) -> void:
	if p_actor is Node2D:
		(p_actor as Node2D).global_position = get_entry_position()
	_refresh_camera()
	_apply_initial_camera_state()
	_apply_vista_presentation_mode()


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
	_build_sequence_triggers()
	if reveal_director != null:
		reveal_director.refresh_bindings()


func _remove_stale_proxy_nodes() -> void:
	for node_name in ["VistaUnderlay", "PathSprites", "Occlusion", "Gameplay", "ApproachVoidBackdrop"]:
		var stale := get_node_or_null(node_name)
		if stale != null:
			stale.queue_free()


func _ensure_roots() -> void:
	parallax_root = get_node_or_null(
		"ParallaxRoot"
	) as SunderedKeepParallaxRig
	if parallax_root == null:
		parallax_root = (
			PARALLAX_RIG_SCRIPT.new()
			as SunderedKeepParallaxRig
		)
		parallax_root.name = "ParallaxRoot"
		add_child(parallax_root)

	underlay_root = _ensure_node2d_root("UnderlayRoot", -300)
	vista_root = _ensure_node2d_root("VistaRoot", -200)
	_grand_vista_root = _ensure_node2d_root("GrandVistaRoot", -220)
	_grand_vista_root.modulate.a = 0.0
	playable_root = _ensure_node2d_root("PlayableRoot", 0)
	occlusion_root = _ensure_node2d_root("OcclusionRoot", 100)
	collision_root = _ensure_plain_node2d("Collision")
	markers_root = _ensure_plain_node2d("Markers")
	event_markers_root = _ensure_plain_node2d("EventMarkers")
	event_runtime_root = _ensure_plain_node2d("EventRuntimeRoot")
	sequence_triggers_root = _ensure_plain_node2d("SequenceTriggers")
	roof_occlusion_root = _ensure_node2d_root("RoofOcclusionRoot", 90)

	entry_spawn = _ensure_marker("EntrySpawn", _route_point(ENTRY_SPAWN_POS))
	reveal_start = _ensure_marker("RevealStart", _route_point(REVEAL_START_POS))
	reveal_full = _ensure_marker("RevealFull", _route_point(REVEAL_FULL_POS))
	mid_gameplay_start = _ensure_marker("MidGameplayStart", _route_point(MID_GAMEPLAY_START_POS))
	reveal_control_start = _ensure_marker(
		"RevealControlStart",
		_route_point(
			_get_authoring_marker_position(
				"reveal_control_start",
				REVEAL_CONTROL_START_POS
			)
		)
	)
	reveal_control_end = _ensure_marker(
		"RevealControlEnd",
		_route_point(
			_get_authoring_marker_position(
				"reveal_control_end",
				REVEAL_CONTROL_END_POS
			)
		)
	)
	second_vista_start = _ensure_marker("SecondVistaStart", _route_point(SECOND_VISTA_START_POS))
	second_vista_full = _ensure_marker("SecondVistaFull", _route_point(SECOND_VISTA_FULL_POS))
	second_vista_end = _ensure_marker("SecondVistaEnd", _route_point(SECOND_VISTA_END_POS))
	traverse_end = _ensure_marker("TraverseEnd", _route_point(TRAVERSE_END_POS))
	return_topdown = _ensure_marker("ReturnTopdown", _route_point(RETURN_TOPDOWN_POS))
	first_reveal_camera_anchor = _ensure_marker(
		"FirstRevealCameraAnchor",
		_route_point(
			_get_authoring_marker_position(
				"first_reveal_camera_anchor",
				FIRST_REVEAL_CAMERA_ANCHOR_POS
			)
		)
	)
	second_reveal_camera_anchor = _ensure_marker(
		"SecondVistaCameraAnchor",
		_route_point(
			_get_authoring_marker_position(
				"second_reveal_camera_anchor",
				SECOND_REVEAL_CAMERA_ANCHOR_POS
			)
		)
	)


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
	_clear_children(roof_occlusion_root)
	vista_root.modulate.a = 0.0
	_grand_vista_root.modulate.a = 0.0
	occlusion_root.modulate.a = 1.0

	if parallax_root != null:
		parallax_root.show_far_cliff_islands = (
			show_far_cliff_islands
		)
		parallax_root.show_causeway_far_arches = (
			show_causeway_far_arches
		)
		parallax_root.show_lower_cliff_depth = (
			show_lower_cliff_depth
		)
		parallax_root.show_ocean_mist = show_ocean_mist
		parallax_root.show_near_edge_mist = (
			show_near_edge_mist
		)
		parallax_root.show_foreground_ruined_arch = (
			show_foreground_ruined_arch
		)
		parallax_root.build(
			SunderedKeepParallaxRig.Profile.VISTA_APPROACH,
			RECT_CAMERA_BOUNDS
		)

	_add_backdrop_void_fill()
	_add_fitted_sprite(underlay_root, "ApproachOceanVoidUnderlay", APPROACH_OCEAN_VOID_UNDERLAY, RECT_APPROACH_UNDERLAY, -30, Color.WHITE)
	_apply_soft_rect_feather(
		_add_fitted_sprite(underlay_root, "ApproachCliffSpiresUnderlay", APPROACH_CLIFF_SPIRES_UNDERLAY, RECT_APPROACH_UNDERLAY, -20, Color(1.0, 1.0, 1.0, 0.42)),
		Vector4(0.12, 0.12, 0.14, 0.22)
	)
	_add_fitted_sprite(underlay_root, "ApproachRouteContactShadow", APPROACH_ROUTE_CONTACT_SHADOW, _route_rect(RECT_ROUTE_MASTER), -5, Color(1.0, 1.0, 1.0, 0.85))

	var first_vista_far := _add_parallax_layer(
		vista_root,
		"FirstVistaFarParallax",
		-20,
		Vector2(0.18, 0.07)
	)
	var first_vista_mist := _add_parallax_layer(
		vista_root,
		"FirstVistaMistParallax",
		10,
		Vector2(0.10, 0.035),
		Vector2(8.0, 3.0),
		0.08
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(first_vista_far, "ApproachFirstVistaHorizon", APPROACH_FIRST_VISTA_HORIZON, RECT_FIRST_VISTA_HORIZON, 0, Color.WHITE),
		Vector4(0.06, 0.06, 0.08, 0.18)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(first_vista_mist, "ApproachFirstVistaFogVeil", APPROACH_FIRST_VISTA_FOG_VEIL, RECT_FIRST_VISTA_FOG_VEIL, 10, Color(1.0, 1.0, 1.0, 0.38)),
		Vector4(0.08, 0.08, 0.18, 0.24)
	)

	var labyrinth_far := _add_parallax_layer(
		_grand_vista_root,
		"LabyrinthFarParallax",
		0,
		Vector2(0.15, 0.05)
	)
	var labyrinth_mist := _add_parallax_layer(
		_grand_vista_root,
		"LabyrinthMistParallax",
		10,
		Vector2(0.08, 0.025),
		Vector2(12.0, 4.0),
		0.065
	)
	var labyrinth_near := _add_parallax_layer(
		_grand_vista_root,
		"LabyrinthNearRoot",
		20,
		Vector2(0.025, 0.01)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_far, "GrandVistaPanorama", GRAND_VISTA_PANORAMA, RECT_GRAND_VISTA_PANORAMA, 0, Color(0.72, 0.80, 0.92, 0.88)),
		Vector4(0.08, 0.08, 0.10, 0.16)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_mist, "GrandVistaOceanSprayOverlay", GRAND_VISTA_SPRAY, RECT_GRAND_VISTA_SPRAY, 1, Color(1.0, 1.0, 1.0, 0.58)),
		Vector4(0.10, 0.10, 0.28, 0.34)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_mist, "GrandVistaFogOverlay", GRAND_VISTA_FOG, RECT_GRAND_VISTA_FOG, 2, Color(1.0, 1.0, 1.0, 0.48)),
		Vector4(0.10, 0.10, 0.34, 0.36)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_far, "GrandVistaShadowVignette", GRAND_VISTA_VIGNETTE, RECT_GRAND_VISTA_VIGNETTE, 3, Color(1.0, 1.0, 1.0, 0.52)),
		Vector4(0.08, 0.08, 0.08, 0.08)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_near, "GrandVistaForegroundParapet", GRAND_VISTA_PARAPET, RECT_GRAND_VISTA_PARAPET, 20, Color(0.90, 0.94, 1.0, 0.92)),
		Vector4(0.08, 0.08, 0.18, 0.08)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_mist, "GrandVistaHorizonSeamFog", GRAND_VISTA_HORIZON_SEAM_FOG, RECT_GRAND_VISTA_HORIZON_SEAM_FOG, 30, Color(1.0, 1.0, 1.0, 0.45)),
		Vector4(0.10, 0.10, 0.28, 0.30)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_near, "GrandVistaPathContactShadow", GRAND_VISTA_PATH_CONTACT_SHADOW, RECT_GRAND_VISTA_PATH_CONTACT_SHADOW, 35, Color(1.0, 1.0, 1.0, 0.50)),
		Vector4(0.08, 0.08, 0.18, 0.26)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_near, "GrandVistaEdgeSprayWrap", GRAND_VISTA_EDGE_SPRAY_WRAP, RECT_GRAND_VISTA_EDGE_SPRAY_WRAP, 40, Color(1.0, 1.0, 1.0, 0.35)),
		Vector4(0.10, 0.10, 0.24, 0.30)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(labyrinth_near, "GrandVistaForegroundEdgeMask", GRAND_VISTA_FOREGROUND_EDGE_MASK, RECT_GRAND_VISTA_FOREGROUND_EDGE_MASK, 80, Color(1.0, 1.0, 1.0, 0.55)),
		Vector4(0.08, 0.08, 0.18, 0.08)
	)

	if USE_ROUTE_MASTER:
		var route_master := _add_fitted_sprite(
			playable_root,
			"ApproachRouteMaster",
			APPROACH_ROUTE_MASTER,
			_route_rect(RECT_ROUTE_MASTER),
			0,
			Color.WHITE
		)
		_build_labyrinth_roof_occlusion(route_master)
	else:
		_build_legacy_path_chunks()

	_add_fitted_sprite(occlusion_root, "ApproachEdgeMistWrap", APPROACH_EDGE_MIST_WRAP, _route_rect(RECT_ROUTE_MASTER), 5, Color(1.0, 1.0, 1.0, 0.10))
	_add_fitted_sprite(occlusion_root, "ApproachFogStrip01", APPROACH_FOG_STRIP_01, _route_rect(RECT_FOG_STRIP_01), 8, Color(1.0, 1.0, 1.0, 0.10))
	_add_fitted_sprite(occlusion_root, "ApproachFogStrip02", APPROACH_FOG_STRIP_02, _route_rect(RECT_FOG_STRIP_02), 9, Color(1.0, 1.0, 1.0, 0.08))
	_add_fitted_sprite(occlusion_root, "ApproachFogStrip03", APPROACH_FOG_STRIP_03, _route_rect(RECT_FOG_STRIP_03), 10, Color(1.0, 1.0, 1.0, 0.06))
	_add_labyrinth_depth_pass()
	_add_reveal_moonlight_cue()
	_final_fog_coverage_rect = _compute_final_fog_coverage_rect()
	_add_fitted_sprite(
		occlusion_root,
		"ApproachFinalGateShadowVeil",
		APPROACH_FINAL_GATE_SHADOW_VEIL,
		_final_fog_coverage_rect,
		20,
		Color(1.0, 1.0, 1.0, 0.0)
	)


func _add_parallax_layer(
	parent: Node2D,
	node_name: String,
	z: int,
	follow_ratio: Vector2,
	drift_amplitude := Vector2.ZERO,
	drift_speed := 0.0
) -> Node2D:
	var layer := PARALLAX_LAYER_SCRIPT.new() as Node2D
	layer.name = node_name
	layer.z_as_relative = true
	layer.z_index = z
	layer.set("follow_ratio", follow_ratio)
	layer.set("drift_amplitude", drift_amplitude)
	layer.set("drift_speed", drift_speed)
	parent.add_child(layer)
	return layer


func _add_labyrinth_depth_pass() -> void:
	var fog := _add_fitted_sprite(
		occlusion_root,
		"LabyrinthContactFog",
		GRAND_VISTA_HORIZON_SEAM_FOG,
		_route_rect(RECT_LABYRINTH_CONTACT_FOG),
		34,
		Color(0.78, 0.88, 1.0, 0.22)
	)
	_apply_soft_rect_feather(
		fog,
		Vector4(0.14, 0.18, 0.30, 0.34)
	)
	_add_labyrinth_light(
		"LabyrinthMoonRimLight",
		_route_point(Vector2(760.0, -480.0)),
		Color(0.50, 0.70, 1.0, 1.0),
		0.24,
		4.8
	)
	_add_labyrinth_light(
		"LabyrinthGateLight",
		_route_point(Vector2(1110.0, -290.0)),
		Color(0.76, 0.64, 0.42, 1.0),
		0.08,
		1.8
	)


func _add_labyrinth_light(
	node_name: String,
	light_position: Vector2,
	light_color: Color,
	energy: float,
	texture_scale: float
) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = node_name
	light.position = light_position
	light.color = light_color
	light.energy = energy
	light.texture_scale = texture_scale

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.62),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])

	var texture := GradientTexture2D.new()
	texture.width = 1024
	texture.height = 1024
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient

	light.texture = texture
	occlusion_root.add_child(light)
	return light


func _build_labyrinth_roof_occlusion(route_master: Sprite2D) -> void:
	if route_master == null or route_master.texture == null:
		return

	var rendered_rect := _route_rect(RECT_ROUTE_MASTER)
	var material := ShaderMaterial.new()
	material.shader = ROUTE_MASTER_OCCLUSION_SHADER
	var roof_names := LABYRINTH_ROOF_RECTS.keys()
	for index in roof_names.size():
		var roof_name := str(roof_names[index])
		var roof_rect := LABYRINTH_ROOF_RECTS[roof_name] as Rect2
		material.set_shader_parameter(
			"cutout_%d" % index,
			_runtime_rect_to_uv(roof_rect, rendered_rect)
		)
	route_master.material = material

	var texture_size := route_master.texture.get_size()
	for index in roof_names.size():
		var roof_name := str(roof_names[index])
		var roof_rect := LABYRINTH_ROOF_RECTS[roof_name] as Rect2
		var source_region := _runtime_rect_to_source_region(
			roof_rect,
			rendered_rect,
			texture_size
		)
		var roof_sprite := Sprite2D.new()
		roof_sprite.name = roof_name
		roof_sprite.texture = route_master.texture
		roof_sprite.region_enabled = true
		roof_sprite.region_rect = source_region
		roof_sprite.centered = false
		roof_sprite.position = roof_rect.position
		roof_sprite.scale = Vector2(
			roof_rect.size.x / source_region.size.x,
			roof_rect.size.y / source_region.size.y
		)
		roof_sprite.z_as_relative = true
		roof_sprite.z_index = 90 + index
		roof_sprite.set_meta("coverage_rect", roof_rect)
		roof_occlusion_root.add_child(roof_sprite)

		var zone_rect := LABYRINTH_OCCLUSION_ZONES[roof_name] as Rect2
		var occluder := ROOF_OCCLUDER_SCRIPT.new() as Area2D
		occluder.name = "%sOccluder" % roof_name
		occluder.position = zone_rect.get_center()
		occluder.collision_layer = 0
		occluder.collision_mask = 1
		occluder.monitoring = true
		occluder.monitorable = false
		var shape_node := CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = zone_rect.size
		shape_node.shape = shape
		occluder.add_child(shape_node)
		roof_occlusion_root.add_child(occluder)
		occluder.call("configure", [roof_sprite] as Array[CanvasItem])


func _runtime_rect_to_source_region(
	runtime_rect: Rect2,
	rendered_rect: Rect2,
	texture_size: Vector2
) -> Rect2:
	var normalized_position := Vector2(
		(runtime_rect.position.x - rendered_rect.position.x)
			/ rendered_rect.size.x,
		(runtime_rect.position.y - rendered_rect.position.y)
			/ rendered_rect.size.y
	)
	var normalized_size := Vector2(
		runtime_rect.size.x / rendered_rect.size.x,
		runtime_rect.size.y / rendered_rect.size.y
	)
	return Rect2(
		normalized_position * texture_size,
		normalized_size * texture_size
	)


func _runtime_rect_to_uv(
	runtime_rect: Rect2,
	rendered_rect: Rect2
) -> Vector4:
	return Vector4(
		(runtime_rect.position.x - rendered_rect.position.x)
			/ rendered_rect.size.x,
		(runtime_rect.position.y - rendered_rect.position.y)
			/ rendered_rect.size.y,
		runtime_rect.size.x / rendered_rect.size.x,
		runtime_rect.size.y / rendered_rect.size.y
	)


func _compute_visual_coverage_rect() -> Rect2:
	var result := Rect2()
	var initialized := false
	for root_node in [
		underlay_root,
		vista_root,
		_grand_vista_root,
		playable_root,
	]:
		for child in root_node.find_children("*"):
			if not child.has_meta("coverage_rect"):
				continue
			var rect := child.get_meta("coverage_rect") as Rect2
			if not initialized:
				result = rect
				initialized = true
			else:
				result = result.merge(rect)
	if not initialized:
		result = RECT_CAMERA_BOUNDS
	return result


func _compute_final_fog_coverage_rect() -> Rect2:
	var combined := _compute_visual_coverage_rect().merge(
		RECT_CAMERA_BOUNDS
	)
	return combined.grow_individual(
		FINAL_FOG_OVERSCAN.x,
		FINAL_FOG_OVERSCAN.y,
		FINAL_FOG_OVERSCAN.z,
		FINAL_FOG_OVERSCAN.w
	)


func get_final_fog_coverage_rect() -> Rect2:
	return _final_fog_coverage_rect


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
	sprite.set_meta("coverage_rect", rect)

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
	for candidate in get_tree().get_nodes_in_group(
		"sundered_keep_parallax_layer"
	):
		if candidate is Node and is_ancestor_of(candidate as Node):
			(candidate as Node).call("rebase")


func _apply_initial_camera_state() -> void:
	if vista_controller == null:
		return
	var state := vista_controller.get_reveal_choreography_state()
	if not bool(state.get("first_reveal_complete", false)):
		vista_controller.enter_intro_tight_mode()


func _apply_vista_presentation_mode() -> void:
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


func _build_sequence_triggers() -> void:
	_clear_children(sequence_triggers_root)

	first_reveal_trigger = Area2D.new()
	first_reveal_trigger.name = "FirstVistaRevealTrigger"
	first_reveal_trigger.position = _route_point(
		_get_authoring_marker_position(
			"first_reveal_trigger",
			FIRST_REVEAL_TRIGGER_POS
		)
	)
	first_reveal_trigger.collision_layer = 0
	first_reveal_trigger.collision_mask = 1
	first_reveal_trigger.monitoring = true
	first_reveal_trigger.monitorable = false
	sequence_triggers_root.add_child(first_reveal_trigger)

	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = FIRST_REVEAL_TRIGGER_SIZE
	shape_node.shape = shape
	first_reveal_trigger.add_child(shape_node)
	first_reveal_trigger.body_entered.connect(
		_on_first_reveal_trigger_body_entered
	)

	return_to_gameplay_trigger = Area2D.new()
	return_to_gameplay_trigger.name = "ReturnToGameplayTrigger"
	return_to_gameplay_trigger.position = _route_point(
		_get_authoring_marker_position(
			"return_to_gameplay_trigger",
			RETURN_TO_GAMEPLAY_TRIGGER_POS
		)
	)
	return_to_gameplay_trigger.collision_layer = 0
	return_to_gameplay_trigger.collision_mask = 1
	return_to_gameplay_trigger.monitoring = true
	return_to_gameplay_trigger.monitorable = false
	sequence_triggers_root.add_child(
		return_to_gameplay_trigger
	)

	var return_shape_node := CollisionShape2D.new()
	return_shape_node.name = "CollisionShape2D"
	var return_shape := RectangleShape2D.new()
	return_shape.size = RETURN_TO_GAMEPLAY_TRIGGER_SIZE
	return_shape_node.shape = return_shape
	return_to_gameplay_trigger.add_child(
		return_shape_node
	)
	return_to_gameplay_trigger.body_entered.connect(
		_on_return_to_gameplay_trigger_body_entered
	)

	second_reveal_trigger = Area2D.new()
	second_reveal_trigger.name = "SecondVistaRevealTrigger"
	second_reveal_trigger.position = _route_point(
		_get_authoring_marker_position(
			"second_reveal_trigger",
			SECOND_REVEAL_TRIGGER_POS
		)
	)
	second_reveal_trigger.collision_layer = 0
	second_reveal_trigger.collision_mask = 1
	second_reveal_trigger.monitoring = true
	second_reveal_trigger.monitorable = false
	sequence_triggers_root.add_child(second_reveal_trigger)

	var second_shape_node := CollisionShape2D.new()
	second_shape_node.name = "CollisionShape2D"
	var second_shape := RectangleShape2D.new()
	second_shape.size = SECOND_REVEAL_TRIGGER_SIZE
	second_shape_node.shape = second_shape
	second_reveal_trigger.add_child(second_shape_node)
	second_reveal_trigger.body_entered.connect(
		_on_second_reveal_trigger_body_entered
	)


func _on_first_reveal_trigger_body_entered(body: Node) -> void:
	if not _is_player_body(body):
		return
	if reveal_director == null:
		return
	reveal_director.call("play_first_reveal")


func _on_second_reveal_trigger_body_entered(body: Node) -> void:
	if not _is_player_body(body):
		return
	if reveal_director == null:
		return
	reveal_director.call("play_second_reveal")


func _on_return_to_gameplay_trigger_body_entered(
	body: Node
) -> void:
	if not _is_player_body(body):
		return
	if reveal_director == null:
		return
	reveal_director.call(
		"return_first_reveal_to_gameplay"
	)


func _build_event_markers() -> void:
	if event_markers_root == null or event_runtime_root == null:
		return
	_clear_children(event_markers_root)
	for child: Node in event_runtime_root.get_children():
		if child.name != &"Exits":
			child.free()
	_continue_exit = null
	_return_world_exit = null
	# This is the visual Vista Approach, not the Keep gatehouse/causeway level.
	# Keep-specific key, gate, enemy-spawn, and authoring-marker runtime was
	# previously placed here by mistake and made the vista route impassable.
	_bind_authored_route_exits()


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


func _bind_authored_route_exits() -> void:
	_continue_exit = get_node_or_null("EventRuntimeRoot/Exits/Exit_Continue") as LevelExit2D
	_return_world_exit = get_node_or_null("EventRuntimeRoot/Exits/Exit_ReturnWorld") as LevelExit2D
	if _continue_exit == null:
		push_error("[SunderedKeepApproach] Missing authored Exit_Continue")
		return
	if _return_world_exit == null:
		push_error("[SunderedKeepApproach] Missing authored Exit_ReturnWorld")
		return
	_continue_exit.position = _route_point(
		_get_authoring_marker_position("level_exit", LEVEL_EXIT_POS)
	)
	_return_world_exit.position = entry_spawn.position + Vector2(-48.0, 32.0)
	_build_level_exit_affordance(_continue_exit.position)


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
	prompt.text = "CONTINUE TO RETURN CAUSEWAY  >"
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
	vista_controller.reveal_control_start_marker_path = NodePath(
		"../Markers/RevealControlStart"
	)
	vista_controller.reveal_control_end_marker_path = NodePath(
		"../Markers/RevealControlEnd"
	)
	vista_controller.vista_root_path = NodePath("../VistaRoot")
	vista_controller.grand_vista_root_path = NodePath("../GrandVistaRoot")
	vista_controller.vista_fog_band_path = NodePath(
		"../VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil"
	)
	vista_controller.fog_underlay_path = NodePath("")
	vista_controller.occlusion_root_path = NodePath("../OcclusionRoot")
	vista_controller.cliff_occluder_path = NodePath("../OcclusionRoot/ApproachEdgeMistWrap")
	vista_controller.wall_shadow_occluder_path = NodePath("../OcclusionRoot/ApproachFinalGateShadowVeil")
	vista_controller.final_gate_shadow_veil_path = NodePath("../OcclusionRoot/ApproachFinalGateShadowVeil")
	vista_controller.distant_keep_path = NodePath(
		"../ParallaxRoot/RevealDepth/"
		+ "DistantKeep_Parallax2D/"
		+ "DistantSunderedKeepLandmark"
	)
	vista_controller.second_vista_start_marker_path = NodePath("../Markers/SecondVistaStart")
	vista_controller.second_vista_full_marker_path = NodePath("../Markers/SecondVistaFull")
	vista_controller.second_vista_end_marker_path = NodePath("../Markers/SecondVistaEnd")
	vista_controller.first_reveal_camera_anchor_path = NodePath(
		"../Markers/FirstRevealCameraAnchor"
	)
	vista_controller.second_reveal_camera_anchor_path = NodePath(
		"../Markers/SecondVistaCameraAnchor"
	)
	vista_controller.parallax_reveal_root_path = NodePath(
		"../ParallaxRoot/RevealDepth"
	)
	vista_controller.parallax_foreground_root_path = NodePath(
		"../ParallaxRoot/ForegroundDepth"
	)
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
	reveal_director.destination_prompt_path = NodePath("../EventRuntimeRoot/LevelExitAffordance")
	reveal_director.refresh_bindings()


func _ensure_debug_probe() -> void:
	var dev_mode := get_node_or_null("/root/DevMode")
	if dev_mode == null or not bool(dev_mode.get("debug_ui_enabled")):
		return
	vista_debug_probe = get_node_or_null(
		"VistaDebugProbe"
	) as CanvasLayer
	if vista_debug_probe == null:
		vista_debug_probe = VISTA_DEBUG_PROBE_SCRIPT.new() as CanvasLayer
		vista_debug_probe.name = "VistaDebugProbe"
		add_child(vista_debug_probe)


func _is_player_body(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("operator") or String(body.name) == "Operator"


func _get_authoring_marker_position(marker_id: String, fallback: Vector2) -> Vector2:
	var marker_data: Variant = AUTHORING_MARKERS.get(marker_id, {})
	if marker_data is Dictionary:
		var position: Variant = (marker_data as Dictionary).get("position", fallback)
		if position is Vector2:
			return position
	return fallback


func has_spawn(spawn_id: StringName) -> bool:
	return markers_root != null and markers_root.get_node_or_null(String(spawn_id)) is Node2D


func get_spawn_position(spawn_id: StringName) -> Vector2:
	var marker := markers_root.get_node_or_null(String(spawn_id)) as Node2D if markers_root != null else null
	return marker.global_position if marker != null else global_position


func activate_route_node(actor: Node, spawn_id: StringName) -> bool:
	if not (actor is Node2D) or not has_spawn(spawn_id):
		return false
	(actor as Node2D).global_position = get_spawn_position(spawn_id)
	_refresh_camera()
	_apply_initial_camera_state()
	_apply_vista_presentation_mode()
	return true


func capture_route_state() -> Dictionary:
	return {}


func restore_route_state(_state: Dictionary) -> bool:
	return true


func prepare_route_deactivation(_context: Dictionary) -> void:
	if reveal_director != null \
			and reveal_director.has_method(
				"release_presentation_constraints"
			):
		reveal_director.call("release_presentation_constraints")


func complete_route_activation(_context: Dictionary) -> bool:
	_refresh_camera()
	_apply_initial_camera_state()
	_apply_vista_presentation_mode()
	return true


func refresh_route_camera(_actor: Node) -> bool:
	_refresh_camera()
	_apply_initial_camera_state()
	return true


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
