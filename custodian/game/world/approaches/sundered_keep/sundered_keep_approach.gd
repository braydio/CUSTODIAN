extends Node2D
class_name SunderedKeepApproach

signal approach_visuals_ready

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
const FORTRESS_VISTA_SCRIPT := preload(
	"res://game/world/approaches/sundered_keep/"
	+ "sundered_keep_fortress_vista.gd"
)
const APPROACH_OUTSKIRTS_MAStER := (
	"res://content/backgrounds/sundered_keep/approach/underlay/"
	+ "sundered_keep_approach_outskirts_master.png"
)
const USE_ROUTE_MASTER := true
const APPROACH_LAYOUT_DATA := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_approach_outskirts.json"
)
const APPROACH_COLLISION_DATA := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_approach_collision.json"
)
const APPROACH_OCCLUSION_DATA := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_approach_occlusion.json"
)
const AUTHORED_GRUNT_SCENE := preload(
	"res://game/actors/enemies/enemy_grunt.tscn"
)

const APPROACH_ROUTE_MASTER := "res://content/sprites/world/return_causeway/path/sundered_keep_approach_route_master.png"

const APPROACH_OCEAN_VOID_UNDERLAY := "res://content/backgrounds/sundered_keep/approach/underlay/approach_ocean_void_underlay.png"
const APPROACH_CLIFF_SPIRES_UNDERLAY := "res://content/backgrounds/sundered_keep/approach/underlay/approach_cliff_spires_underlay.png"
const APPROACH_ROUTE_CONTACT_SHADOW := "res://content/backgrounds/sundered_keep/approach/underlay/approach_route_contact_shadow.png"
const APPROACH_EDGE_MIST_WRAP := "res://content/backgrounds/sundered_keep/approach/occlusion/approach_edge_mist_wrap.png"
const FIRST_VISTA_BASE_STORM_HORIZON := (
	"res://content/backgrounds/sundered_keep/approach/underlay/"
	+ "first_vista_base_storm_horizon.png"
)
const FIRST_VISTA_REVEAL_VEIL := (
	"res://content/backgrounds/sundered_keep/approach/fog/"
	+ "first_vista_reveal_veil.png"
)
const APPROACH_FINAL_GATE_SHADOW_VEIL := "res://content/backgrounds/sundered_keep/approach/occlusion/approach_final_gate_shadow_veil.png"

const APPROACH_FOG_STRIP_01 := "res://content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_01.png"
const APPROACH_FOG_STRIP_02 := "res://content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_02.png"
const APPROACH_FOG_STRIP_03 := "res://content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_03.png"

const GRAND_VISTA_PANORAMA := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_panorama.png"
const GRAND_VISTA_FOG := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_fog_overlay.png"
const GRAND_VISTA_PARAPET := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_foreground_parapet.png"
const GRAND_VISTA_VIGNETTE := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_shadow_vignette.png"
const GRAND_VISTA_SPRAY := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_ocean_spray_overlay.png"
const GRAND_VISTA_HORIZON_SEAM_FOG := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_horizon_seam_fog.png"
const GRAND_VISTA_PATH_CONTACT_SHADOW := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_path_contact_shadow.png"
const GRAND_VISTA_FOREGROUND_EDGE_MASK := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_foreground_edge_mask.png"
const GRAND_VISTA_EDGE_SPRAY_WRAP := "res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_edge_spray_wrap.png"

const MAINLAND_APPROACH_PATH := "res://content/sprites/world/return_causeway/path/mainland_approach_path.png"
const HILL_CLIMB_PATH := "res://content/sprites/world/return_causeway/path/hill_climb_path.png"
const OVERLOOK_LEDGE_PATH := "res://content/sprites/world/return_causeway/path/overlook_ledge.png"
const LATERAL_TRAVERSE_PATH := "res://content/sprites/world/return_causeway/path/lateral_traverse_path.png"
const FORTRESS_WALL_MASS_PATH := "res://content/sprites/world/return_causeway/path/fortress_wall_mass.png"

const ROUTE_VERTICAL_OFFSET := 180.0
const BOUNDARY_RAIL_RADIUS := 10.0

const RECT_ROUTE_MASTER := Rect2(Vector2(-1644.0, -1513.0), Vector2(4096.0, 3412.0))
const RECT_APPROACH_UNDERLAY := Rect2(
Vector2(-1536.0, -1236.0),
Vector2(4608.0, 3072.0)
)
const RECT_FIRST_VISTA_HORIZON := Rect2(Vector2(-1000.0, -980.0), Vector2(2600.0, 1460.0))
const RECT_FIRST_VISTA_FOG_VEIL := Rect2(Vector2(-1000.0, -360.0), Vector2(2600.0, 720.0))
const RECT_FINAL_GATE_SHADOW_VEIL := Rect2(Vector2(-1000.0, -520.0), Vector2(2600.0, 900.0))
const RECT_FOG_STRIP_01 := Rect2(Vector2(-880.0, -430.0), Vector2(1500.0, 520.0))
const RECT_FOG_STRIP_02 := Rect2(Vector2(-260.0, -420.0), Vector2(1500.0, 520.0))
const RECT_FOG_STRIP_03 := Rect2(Vector2(320.0, -410.0), Vector2(1500.0, 520.0))
const RECT_CAMERA_BOUNDS := Rect2(Vector2(-1280.0, -980.0), Vector2(4096.0, 2560.0))
const RECT_BACKDROP_VOID_FILL := Rect2(
	Vector2(-2048.0, -1748.0),
	Vector2(5632.0, 4096.0)
)
const BACKDROP_VOID_COLOR := Color(0.018, 0.043, 0.057, 1.0)
const RECT_GRAND_VISTA_PANORAMA := Rect2(Vector2(-1280.0, -920.0), Vector2(2560.0, 1440.0))
const RECT_GRAND_VISTA_SPRAY := Rect2(Vector2(-1280.0, -160.0), Vector2(2560.0, 720.0))
const RECT_GRAND_VISTA_FOG := Rect2(Vector2(-1280.0, -520.0), Vector2(2560.0, 480.0))
const RECT_GRAND_VISTA_VIGNETTE := Rect2(Vector2(-1280.0, -920.0), Vector2(2560.0, 1440.0))
const RECT_GRAND_VISTA_PARAPET := Rect2(Vector2(-1280.0, 260.0), Vector2(2560.0, 360.0))
const RECT_GRAND_VISTA_HORIZON_SEAM_FOG := Rect2(Vector2(-1280.0, -560.0), Vector2(2560.0, 420.0))
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
const REVEAL_CONTROL_START_POS := REVEAL_FULL_POS
const REVEAL_CONTROL_END_POS := MID_GAMEPLAY_START_POS
const RETURN_TO_GAMEPLAY_TRIGGER_POS := MID_GAMEPLAY_START_POS
const SECOND_REVEAL_TRIGGER_POS := SECOND_VISTA_START_POS
const SECOND_REVEAL_CAMERA_ANCHOR_POS := Vector2(650.0, -420.0)
const SECOND_REVEAL_TRIGGER_SIZE := Vector2(170.0, 140.0)
const SECOND_RETURN_TRIGGER_SIZE := Vector2(150.0, 120.0)
const FORTRESS_VISTA_ORIGIN_SOURCE := Vector2(-360.0, -1280.0)
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

@export_group("Shared Parallax Review Gates")
@export var show_far_cliff_islands := false
@export var show_causeway_far_arches := false
@export var show_lower_cliff_depth := false
@export var show_ocean_mist := false
@export var show_near_edge_mist := false
@export var show_foreground_ruined_arch := false

@export_group("Production Performance")
@export var enable_authored_vista_enemies := false

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
var grand_vista_cinematic_root: Node2D = null
var fortress_vista_root: Node2D = null

var entry_spawn: Marker2D = null
var reveal_start: Marker2D = null
var reveal_full: Marker2D = null
var mid_gameplay_start: Marker2D = null
var reveal_control_start: Marker2D = null
var reveal_control_end: Marker2D = null
var first_camera_control_start: Marker2D = null
var first_camera_return_complete: Marker2D = null
var traverse_end: Marker2D = null
var return_topdown: Marker2D = null
var second_vista_start: Marker2D = null
var second_vista_full: Marker2D = null
var second_vista_end: Marker2D = null
var vista_controller: SunderedKeepVistaController = null
var reveal_director: Node = null
var first_reveal_camera_anchor: Marker2D = null
var second_reveal_trigger: Area2D = null
var second_return_to_gameplay_trigger: Area2D = null
var second_reveal_camera_anchor: Marker2D = null
var vista_debug_probe: CanvasLayer = null
var _continue_exit: LevelExit2D = null
var _return_world_exit: LevelExit2D = null
var _final_fog_coverage_rect := Rect2()
var _layout_document: Dictionary = {}
var _collision_document: Dictionary = {}
var _occlusion_document: Dictionary = {}
var _runtime_authoring_markers: Dictionary = {}
var _runtime_boundary_segments: Array = []
var _runtime_roof_records: Array = []
var _subregions_root: Node2D = null
var _approach_visuals_ready := false
var _mapper_preview_config: Dictionary = {}


func _ready() -> void:
	add_to_group("sundered_keep_approach")
	add_to_group("world_ingress_approach")
	_mapper_preview_config = get_meta("mapper_preview_config", {}) as Dictionary
	_load_mapper_authority()
	_remove_stale_proxy_nodes()
	_ensure_roots()
	_build_visuals()
	if _preview_option("vista_controller", true):
		_ensure_vista_controller()
	if _preview_option("reveal_director", true):
		_ensure_reveal_director()
	if _preview_option("debug_probe", true):
		_ensure_debug_probe()
	if not _is_mapper_preview():
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
	if _preview_option("sequence_triggers", true):
		_build_sequence_triggers()
	if reveal_director != null:
		reveal_director.refresh_bindings()
	_mark_approach_visuals_ready()
	if _is_mapper_preview() and not _preview_option("live_processing", false):
		process_mode = Node.PROCESS_MODE_DISABLED


func is_visual_ready() -> bool:
	return _approach_visuals_ready


func _mark_approach_visuals_ready() -> void:
	if _is_mapper_preview():
		_approach_visuals_ready = markers_root != null and collision_root != null
		if _approach_visuals_ready:
			approach_visuals_ready.emit()
		return
	var required_nodes: Array[Node] = [
		playable_root,
		vista_root,
		playable_root.get_node_or_null("ApproachRouteMaster")
			if playable_root != null else null,
		underlay_root.get_node_or_null("ApproachRouteShadow")
			if underlay_root != null else null,
		collision_root.get_node_or_null("PathBoundaryCollision")
			if collision_root != null else null,
		markers_root.get_node_or_null("EntrySpawn")
			if markers_root != null else null,
	]
	for required_node in required_nodes:
		if required_node == null:
			push_error(
				"[SunderedKeepApproach] Required visual or traversal node "
				+ "missing; arrival remains covered"
			)
			_approach_visuals_ready = false
			return
	if _approach_visuals_ready:
		return
	_approach_visuals_ready = true
	approach_visuals_ready.emit()


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
	_grand_vista_root.modulate.a = 1.0
	_grand_vista_root.visible = false
	playable_root = _ensure_node2d_root("PlayableRoot", 0)
	occlusion_root = _ensure_node2d_root("OcclusionRoot", 100)
	collision_root = _ensure_plain_node2d("Collision")
	markers_root = _ensure_plain_node2d("Markers")
	event_markers_root = _ensure_plain_node2d("EventMarkers")
	event_runtime_root = _ensure_plain_node2d("EventRuntimeRoot")
	sequence_triggers_root = _ensure_plain_node2d("SequenceTriggers")
	roof_occlusion_root = _ensure_node2d_root("RoofOcclusionRoot", 90)
	_subregions_root = _ensure_plain_node2d("AuthoredSubregions")
	_build_authored_subregions()

	entry_spawn = _ensure_marker(
		"EntrySpawn",
		_route_point(_get_authoring_marker_position("spawn", ENTRY_SPAWN_POS))
	)
	reveal_start = _ensure_marker(
		"RevealStart",
		_route_point(_get_authoring_marker_position("reveal_start", REVEAL_START_POS))
	)
	reveal_full = _ensure_marker(
		"RevealFull",
		_route_point(_get_authoring_marker_position("reveal_full", REVEAL_FULL_POS))
	)
	mid_gameplay_start = _ensure_marker(
		"MidGameplayStart",
		_route_point(
			_get_authoring_marker_position("mid_gameplay_start", MID_GAMEPLAY_START_POS)
		)
	)
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
	first_camera_control_start = _ensure_marker(
		"FirstCameraControlStart",
		_route_point(
			_get_authoring_marker_position(
				"first_reveal_trigger",
				FIRST_REVEAL_TRIGGER_POS
			)
		)
	)
	first_camera_return_complete = _ensure_marker(
		"FirstCameraReturnComplete",
		_route_point(
			_get_authoring_marker_position(
				"return_to_gameplay_trigger",
				RETURN_TO_GAMEPLAY_TRIGGER_POS
			)
		)
	)
	second_vista_start = _ensure_marker(
		"SecondVistaStart",
		_route_point(
			_get_authoring_marker_position(
				"second_vista_start",
				SECOND_VISTA_START_POS
			)
		)
	)
	second_vista_full = _ensure_marker(
		"SecondVistaFull",
		_route_point(
			_get_authoring_marker_position(
				"second_vista_full",
				SECOND_VISTA_FULL_POS
			)
		)
	)
	second_vista_end = _ensure_marker(
		"SecondVistaEnd",
		_route_point(
			_get_authoring_marker_position(
				"second_vista_end",
				SECOND_VISTA_END_POS
			)
		)
	)
	traverse_end = _ensure_marker(
		"TraverseEnd",
		_route_point(_get_authoring_marker_position("traverse_end", TRAVERSE_END_POS))
	)
	return_topdown = _ensure_marker(
		"ReturnTopdown",
		_route_point(
			_get_authoring_marker_position("return_causeway", RETURN_TOPDOWN_POS)
		)
	)
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
	_grand_vista_root.modulate.a = 1.0
	occlusion_root.modulate.a = 1.0
	if _is_mapper_preview():
		_build_mapper_preview_visuals()
		return

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
		_add_fitted_sprite(
			underlay_root,
			"FirstVistaBaseStormHorizon",
			FIRST_VISTA_BASE_STORM_HORIZON,
			RECT_FIRST_VISTA_HORIZON,
			-25,
			Color.WHITE
		),
		Vector4(0.06, 0.06, 0.08, 0.18)
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(underlay_root, "ApproachCliffSpiresUnderlay", APPROACH_CLIFF_SPIRES_UNDERLAY, RECT_APPROACH_UNDERLAY, -20, Color(1.0, 1.0, 1.0, 0.42)),
		Vector4(0.12, 0.12, 0.14, 0.22)
	)
	_add_fitted_sprite(underlay_root, "ApproachRouteShadow", APPROACH_ROUTE_CONTACT_SHADOW, _route_rect(RECT_ROUTE_MASTER), -5, Color.WHITE)

	var first_vista_mist := _add_parallax_layer(
		vista_root,
		"FirstVistaMistParallax",
		10,
		Vector2(0.10, 0.035),
		Vector2(8.0, 3.0),
		0.08
	)
	_apply_soft_rect_feather(
		_add_fitted_sprite(
			first_vista_mist,
			"ApproachFirstVistaFogVeil",
			FIRST_VISTA_REVEAL_VEIL,
			RECT_FIRST_VISTA_FOG_VEIL,
			10,
			Color(1.0, 1.0, 1.0, 0.68)
		),
		Vector4(0.08, 0.08, 0.18, 0.24)
	)

	grand_vista_cinematic_root = _ensure_child_node2d_root(
		_grand_vista_root,
		"GrandVistaCinematicRoot",
		0
	)
	grand_vista_cinematic_root.modulate.a = 0.0

	fortress_vista_root = _ensure_child_node2d_root(
		_grand_vista_root,
		"FortressVistaRoot",
		0
	)
	fortress_vista_root.position = _route_point(
		FORTRESS_VISTA_ORIGIN_SOURCE
	) + Vector2(70.0, 0.0)
	# Preserve open sky and rebalance the western mass without resizing pieces
	# independently. This is ~93% of the former 0.88 review scale.
	fortress_vista_root.scale = Vector2(0.82, 0.82)
	fortress_vista_root.modulate.a = 1.0

	var labyrinth_far := _add_parallax_layer(
		grand_vista_cinematic_root,
		"LabyrinthFarParallax",
		0,
		Vector2(0.15, 0.05)
	)
	var labyrinth_mist := _add_parallax_layer(
		grand_vista_cinematic_root,
		"LabyrinthMistParallax",
		12,
		Vector2(0.08, 0.025),
		Vector2(12.0, 4.0),
		0.065
	)
	var labyrinth_near := _add_parallax_layer(
		grand_vista_cinematic_root,
		"LabyrinthNearRoot",
		20,
		Vector2(0.025, 0.01)
	)

	var fortress_far := _add_parallax_layer(
		fortress_vista_root,
		"FortressFarParallax",
		4,
		Vector2(0.18, 0.06)
	)
	var fortress_mid := _add_parallax_layer(
		fortress_vista_root,
		"FortressMidParallax",
		8,
		Vector2(0.11, 0.04)
	)
	var fortress_near := _add_parallax_layer(
		fortress_vista_root,
		"FortressNearParallax",
		16,
		Vector2(0.045, 0.018)
	)
	fortress_far.modulate.a = 0.0
	fortress_mid.modulate.a = 0.0
	fortress_near.modulate.a = 0.0
	var fortress_builder := FORTRESS_VISTA_SCRIPT.new()
	fortress_builder.name = "FortressVistaComposer"
	fortress_vista_root.add_child(fortress_builder)
	var component_count := fortress_builder.build(
		fortress_far,
		fortress_mid,
		fortress_near
	)
	var panorama_alpha := 0.22 if component_count == 30 else 0.88

	_apply_soft_rect_feather(
		_add_fitted_sprite(
			labyrinth_far,
			"GrandVistaPanorama",
			GRAND_VISTA_PANORAMA,
			RECT_GRAND_VISTA_PANORAMA,
			0,
			Color(0.72, 0.80, 0.92, panorama_alpha)
		),
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
		_add_fitted_sprite(labyrinth_mist, "GrandVistaHorizonSeamFog", GRAND_VISTA_HORIZON_SEAM_FOG, RECT_GRAND_VISTA_HORIZON_SEAM_FOG, 30, Color(0.78, 0.86, 0.94, 0.56)),
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
		_build_authored_visual_overlays("ground_overlay")
		var route_master := _add_fitted_sprite(
			playable_root,
			"ApproachRouteMaster",
			_get_route_floor_texture_path(),
			_route_rect(_get_route_floor_rect()),
			0,
			Color.WHITE
		)
		_build_labyrinth_roof_occlusion(route_master)
	else:
		_build_legacy_path_chunks()
	_build_authored_visual_overlays("background_detail")
	_build_authored_visual_overlays("animated_sheet")

	_add_labyrinth_depth_pass()
	_add_reveal_moonlight_cue()
	# Production uses a normal route fade. The former full-screen final veil is
	# intentionally not built because it made the player navigate while hidden.
	_final_fog_coverage_rect = Rect2()


func _build_mapper_preview_visuals() -> void:
	_add_backdrop_void_fill()
	if _preview_option("parallax", false) and parallax_root != null:
		parallax_root.build(
			SunderedKeepParallaxRig.Profile.VISTA_APPROACH,
			RECT_CAMERA_BOUNDS
		)
	if _preview_option("base_underlays", false):
		_add_fitted_sprite(
			underlay_root, "ApproachOceanVoidUnderlay",
			APPROACH_OCEAN_VOID_UNDERLAY, RECT_APPROACH_UNDERLAY, -30, Color.WHITE
		)
		_add_fitted_sprite(
			underlay_root, "FirstVistaBaseStormHorizon",
			FIRST_VISTA_BASE_STORM_HORIZON, RECT_FIRST_VISTA_HORIZON, -25, Color.WHITE
		)
		_add_fitted_sprite(
			underlay_root, "ApproachCliffSpiresUnderlay",
			APPROACH_CLIFF_SPIRES_UNDERLAY, RECT_APPROACH_UNDERLAY, -20,
			Color(1.0, 1.0, 1.0, 0.42)
		)
	if _preview_option("route_contact_shadow", false):
		_add_fitted_sprite(
			underlay_root, "ApproachRouteShadow", APPROACH_ROUTE_CONTACT_SHADOW,
			_route_rect(RECT_ROUTE_MASTER), -5, Color.WHITE
		)
	if _preview_option("first_vista_presentation", false):
		_add_fitted_sprite(
			vista_root, "ApproachFirstVistaFogVeil", FIRST_VISTA_REVEAL_VEIL,
			RECT_FIRST_VISTA_FOG_VEIL, 10, Color(1.0, 1.0, 1.0, 0.68)
		)
	if _preview_option("grand_vista_presentation", false):
		var fortress_far := _ensure_child_node2d_root(
			_grand_vista_root, "MapperFortressFar", 4
		)
		var fortress_mid := _ensure_child_node2d_root(
			_grand_vista_root, "MapperFortressMid", 8
		)
		var fortress_near := _ensure_child_node2d_root(
			_grand_vista_root, "MapperFortressNear", 16
		)
		var fortress_builder := FORTRESS_VISTA_SCRIPT.new()
		fortress_builder.name = "FortressVistaComposer"
		_grand_vista_root.add_child(fortress_builder)
		fortress_builder.build(fortress_far, fortress_mid, fortress_near)
	if _preview_option("authored_ground_overlays", true):
		_build_authored_visual_overlays("ground_overlay")
	if _preview_option("route_master", true):
		var route_master := _add_fitted_sprite(
			playable_root, "ApproachRouteMaster", _get_route_floor_texture_path(),
			_route_rect(_get_route_floor_rect()), 0, Color.WHITE
		)
		if _preview_option("roof_occlusion", false):
			_build_labyrinth_roof_occlusion(route_master)
	if _preview_option("authored_background_overlays", false):
		_build_authored_visual_overlays("background_detail")
	if _preview_option("animated_overlays", false):
		_build_authored_visual_overlays("animated_sheet")
	if _preview_option("edge_mist_wrap", false):
		_add_fitted_sprite(
			occlusion_root, "ApproachEdgeMistWrap", APPROACH_EDGE_MIST_WRAP,
			_route_rect(RECT_ROUTE_MASTER), 5, Color(1.0, 1.0, 1.0, 0.10)
		)
	if _preview_option("fog_strips", false):
		_add_fitted_sprite(occlusion_root, "ApproachFogStrip01", APPROACH_FOG_STRIP_01, _route_rect(RECT_FOG_STRIP_01), 8, Color(1.0, 1.0, 1.0, 0.10))
		_add_fitted_sprite(occlusion_root, "ApproachFogStrip02", APPROACH_FOG_STRIP_02, _route_rect(RECT_FOG_STRIP_02), 9, Color(1.0, 1.0, 1.0, 0.08))
		_add_fitted_sprite(occlusion_root, "ApproachFogStrip03", APPROACH_FOG_STRIP_03, _route_rect(RECT_FOG_STRIP_03), 10, Color(1.0, 1.0, 1.0, 0.06))
	if _preview_option("lights", false):
		_add_labyrinth_depth_pass()
		_add_reveal_moonlight_cue()
	_final_fog_coverage_rect = Rect2()


func _is_mapper_preview() -> bool:
	return bool(_mapper_preview_config.get("enabled", false))


func _preview_option(option: String, production_default: bool) -> bool:
	if not _is_mapper_preview():
		return production_default
	return bool(_mapper_preview_config.get(option, production_default))


func _build_authored_visual_overlays(kind: String) -> void:
	for overlay_variant in _layout_document.get("visual_overlays", []):
		if not overlay_variant is Dictionary:
			continue
		var overlay := overlay_variant as Dictionary
		if str(overlay.get("kind", "")) != kind:
			continue
		var target_rect := _route_rect(
			_rect_from_array(overlay.get("rect", []), Rect2())
		)
		if target_rect.size.x <= 0.0 or target_rect.size.y <= 0.0:
			continue
		var parent := underlay_root if kind != "ground_overlay" else playable_root
		if kind == "animated_sheet":
			_add_authored_animated_overlay(parent, overlay, target_rect)
		else:
			var sprite := _add_fitted_sprite(
				parent,
				str(overlay.get("id", "AuthoredOverlay")).to_pascal_case(),
				str(overlay.get("texture_path", "")),
				target_rect,
				int(overlay.get("z_index", -1)),
				Color.WHITE
			)
			sprite.set_meta("authored_overlay_id", str(overlay.get("id", "")))
			sprite.set_meta("semantic_subregion", str(overlay.get("semantic_subregion", "")))
			sprite.set_meta("collision_authority", false)


func _add_authored_animated_overlay(
	parent: Node2D,
	overlay: Dictionary,
	target_rect: Rect2
) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = str(overlay.get("id", "AnimatedOverlay")).to_pascal_case()
	sprite.centered = false
	sprite.position = target_rect.position
	sprite.z_as_relative = true
	sprite.z_index = int(overlay.get("z_index", -1))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var texture := load(str(overlay.get("texture_path", ""))) as Texture2D
	var frame_size_data := overlay.get("frame_size", [1, 1]) as Array
	var frame_size := Vector2(
		float(frame_size_data[0]),
		float(frame_size_data[1])
	)
	var frames := SpriteFrames.new()
	frames.add_animation(&"loop")
	frames.set_animation_speed(&"loop", float(overlay.get("fps", 7.0)))
	frames.set_animation_loop(&"loop", bool(overlay.get("loop", true)))
	var frame_count := int(overlay.get("frame_count", 1))
	if texture != null:
		for frame_index in frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				Vector2(frame_size.x * float(frame_index), 0.0),
				frame_size
			)
			frames.add_frame(&"loop", atlas)
	sprite.sprite_frames = frames
	sprite.scale = Vector2(
		target_rect.size.x / maxf(1.0, frame_size.x),
		target_rect.size.y / maxf(1.0, frame_size.y)
	)
	sprite.modulate.a = clampf(float(overlay.get("maximum_alpha", 0.3)), 0.0, 0.3)
	sprite.set_meta("authored_overlay_id", str(overlay.get("id", "")))
	sprite.set_meta("semantic_subregion", str(overlay.get("semantic_subregion", "")))
	sprite.set_meta("collision_authority", false)
	parent.add_child(sprite)
	sprite.play(&"loop")
	return sprite


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
	texture.width = 256
	texture.height = 256
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
	for index in _runtime_roof_records.size():
		var roof_record := _runtime_roof_records[index] as Dictionary
		var roof_rect := _rect_from_array(
			roof_record.get("roof_rect", []),
			Rect2()
		)
		material.set_shader_parameter(
			"cutout_%d" % index,
			_runtime_rect_to_uv(roof_rect, rendered_rect)
		)
	route_master.material = material

	var texture_size := route_master.texture.get_size()
	for index in _runtime_roof_records.size():
		var roof_record := _runtime_roof_records[index] as Dictionary
		var roof_name := str(roof_record.get("id", "ApproachRoof%02d" % index))
		var roof_rect := _rect_from_array(
			roof_record.get("roof_rect", []),
			Rect2()
		)
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

		var zone_rect := _rect_from_array(
			roof_record.get("fade_region", []),
			roof_rect
		)
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
		occluder.set("faded_alpha", float(roof_record.get("faded_alpha", 0.08)))
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
	for segment_variant: Variant in _runtime_boundary_segments:
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

	second_return_to_gameplay_trigger = Area2D.new()
	second_return_to_gameplay_trigger.name = (
		"SecondReturnToGameplayTrigger"
	)
	second_return_to_gameplay_trigger.position = second_vista_end.position
	second_return_to_gameplay_trigger.collision_layer = 0
	second_return_to_gameplay_trigger.collision_mask = 1
	second_return_to_gameplay_trigger.monitoring = true
	second_return_to_gameplay_trigger.monitorable = false
	sequence_triggers_root.add_child(
		second_return_to_gameplay_trigger
	)

	var second_return_shape_node := CollisionShape2D.new()
	second_return_shape_node.name = "CollisionShape2D"
	var second_return_shape := RectangleShape2D.new()
	second_return_shape.size = SECOND_RETURN_TRIGGER_SIZE
	second_return_shape_node.shape = second_return_shape
	second_return_to_gameplay_trigger.add_child(
		second_return_shape_node
	)
	second_return_to_gameplay_trigger.body_entered.connect(
		_on_second_return_to_gameplay_trigger_body_entered
	)


func _on_second_reveal_trigger_body_entered(body: Node) -> void:
	if not _is_player_body(body):
		return
	if reveal_director == null:
		return
	reveal_director.call("play_second_reveal")


func _on_second_return_to_gameplay_trigger_body_entered(
	body: Node
) -> void:
	if not _is_player_body(body):
		return
	if reveal_director == null:
		return
	reveal_director.call(
		"return_second_reveal_to_gameplay"
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
	_build_authored_vista_enemies()


func _build_authored_vista_enemies() -> void:
	if not enable_authored_vista_enemies:
		return
	if not _preview_option("authored_enemies", true):
		return
	var enemies_root := Node2D.new()
	enemies_root.name = "AuthoredEnemies"
	event_runtime_root.add_child(enemies_root)
	var subregions := _authored_subregion_rects()
	for raw_enemy: Variant in _layout_document.get("authored_enemies", []):
		if not (raw_enemy is Dictionary):
			continue
		var record := raw_enemy as Dictionary
		if str(record.get("enemy_type", "")) != "grunt":
			push_warning(
				"[SunderedKeepApproach] Unsupported authored enemy type: %s"
				% str(record.get("enemy_type", ""))
			)
			continue
		var subregion_id := str(record.get("subregion_id", ""))
		if not subregions.has(subregion_id):
			push_warning(
				"[SunderedKeepApproach] Authored enemy has unknown subregion: %s"
				% subregion_id
			)
			continue
		var enemy := AUTHORED_GRUNT_SCENE.instantiate() as Node2D
		if enemy == null:
			continue
		var encounter_id := str(record.get("id", "vista_grunt"))
		enemy.name = encounter_id.to_pascal_case()
		enemy.position = _route_point((subregions[subregion_id] as Rect2).get_center())
		enemy.set_meta("authored_encounter_id", encounter_id)
		enemy.set_meta("subregion_id", subregion_id)
		enemy.add_to_group("authored_vista_enemy")
		enemies_root.add_child(enemy)
		if enemy.has_method("set_behavior_profile"):
			enemy.call(
				"set_behavior_profile",
				StringName(str(record.get("behavior_profile", "raider_grunt")))
			)


func _authored_subregion_rects() -> Dictionary:
	var result: Dictionary = {}
	for raw_region: Variant in _layout_document.get("subregions", []):
		if not (raw_region is Dictionary):
			continue
		var record := raw_region as Dictionary
		result[str(record.get("id", ""))] = _rect_from_array(
			record.get("rect", []),
			Rect2()
		)
	return result


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
	vista_controller.reveal_control_start_marker_path = NodePath(
		"../Markers/RevealControlStart"
	)
	vista_controller.reveal_control_end_marker_path = NodePath(
		"../Markers/RevealControlEnd"
	)
	vista_controller.vista_root_path = NodePath("../VistaRoot")
	vista_controller.grand_vista_root_path = NodePath("../GrandVistaRoot")
	vista_controller.grand_vista_cinematic_root_path = NodePath(
		"../GrandVistaRoot/GrandVistaCinematicRoot"
	)
	vista_controller.fortress_vista_root_path = NodePath(
		"../GrandVistaRoot/FortressVistaRoot"
	)
	vista_controller.vista_fog_band_path = NodePath(
		"../VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil"
	)
	vista_controller.fog_underlay_path = NodePath("")
	vista_controller.occlusion_root_path = NodePath("../OcclusionRoot")
	vista_controller.cliff_occluder_path = NodePath("")
	vista_controller.wall_shadow_occluder_path = NodePath("")
	vista_controller.final_gate_shadow_veil_path = NodePath("")
	vista_controller.distant_keep_path = NodePath(
		"../ParallaxRoot/RevealDepth/"
		+ "DistantKeep_Parallax2D/"
		+ "DistantSunderedKeepLandmark"
	)
	vista_controller.first_reveal_light_path = NodePath(
		"../OcclusionRoot/RevealMoonlightCue"
	)
	vista_controller.second_vista_start_marker_path = NodePath("../Markers/SecondVistaStart")
	vista_controller.second_vista_full_marker_path = NodePath("../Markers/SecondVistaFull")
	vista_controller.second_vista_end_marker_path = NodePath("../Markers/SecondVistaEnd")
	vista_controller.first_camera_control_start_marker_path = NodePath(
		"../Markers/FirstCameraControlStart"
	)
	vista_controller.first_camera_return_complete_marker_path = NodePath(
		"../Markers/FirstCameraReturnComplete"
	)
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
	reveal_director.near_fog_path = NodePath("")
	reveal_director.mid_fog_path = NodePath("")
	reveal_director.far_fog_path = NodePath("")
	reveal_director.edge_mist_path = NodePath("")
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
	var marker_data: Variant = _runtime_authoring_markers.get(marker_id, {})
	if marker_data is Dictionary:
		var position: Variant = (marker_data as Dictionary).get("position", fallback)
		if position is Vector2:
			return position
		if position is Array and (position as Array).size() >= 2:
			return Vector2(float(position[0]), float(position[1]))
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
	if not _approach_visuals_ready:
		_finish_physics_setup()
	_refresh_camera()
	_apply_initial_camera_state()
	_apply_vista_presentation_mode()
	return _approach_visuals_ready


func refresh_route_camera(actor: Node) -> bool:
	_refresh_camera()
	_apply_initial_camera_state()
	return finalize_blackout_arrival(actor)


func finalize_blackout_arrival(actor: Node) -> bool:
	if not _approach_visuals_ready or not (actor is Node2D):
		return false
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera == null:
		return false
	if camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", self)
	if camera.has_method("clear_presentation_framing"):
		camera.call("clear_presentation_framing", true)
	if camera.has_method("set_follow_target"):
		camera.call("set_follow_target", actor)
	if camera.has_method("snap_to_player_spawn"):
		camera.call(
			"snap_to_player_spawn",
			(actor as Node2D).global_position
		)
	return true


func get_authoring_marker_state() -> Dictionary:
	var result := {}
	for marker_id: String in _runtime_authoring_markers.keys():
		var marker_data := _runtime_authoring_markers[marker_id] as Dictionary
		var source_position := _get_authoring_marker_position(marker_id, Vector2.ZERO)
		var runtime_position := _route_point(source_position)
		result[marker_id] = {
			"kind": str(marker_data.get("kind", marker_id)),
			"label": str(marker_data.get("label", marker_id)),
			"source_position": source_position,
			"runtime_position": runtime_position,
		}
	return result


func get_boundary_segments() -> Array:
	return _runtime_boundary_segments


func get_authoring_markers() -> Dictionary:
	return _runtime_authoring_markers


func get_authoring_marker_schema() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var marker_ids := _runtime_authoring_markers.keys()
	marker_ids.sort()
	for marker_id: String in marker_ids:
		var data := (_runtime_authoring_markers[marker_id] as Dictionary).duplicate(true)
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


func _load_mapper_authority() -> void:
	_layout_document = _read_json_dictionary(APPROACH_LAYOUT_DATA)
	_collision_document = _read_json_dictionary(APPROACH_COLLISION_DATA)
	_occlusion_document = _read_json_dictionary(APPROACH_OCCLUSION_DATA)
	_runtime_authoring_markers = _decode_markers(
		_layout_document.get("markers", {})
	)
	_runtime_boundary_segments = _decode_segments(
		_collision_document.get("segments", [])
	)
	_runtime_roof_records = (
		_occlusion_document.get("roof_occluders", []) as Array
	).duplicate(true)
	if _runtime_authoring_markers.is_empty():
		push_error("[SunderedKeepApproach] Mapper layout has no markers")
	if _runtime_boundary_segments.is_empty():
		push_error("[SunderedKeepApproach] Mapper collision has no rails")


func _read_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SunderedKeepApproach] Missing mapper authority: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	push_error("[SunderedKeepApproach] Invalid mapper JSON: %s" % path)
	return {}


func _decode_markers(source: Variant) -> Dictionary:
	var decoded: Dictionary = {}
	if not (source is Dictionary):
		return decoded
	for marker_id: String in (source as Dictionary).keys():
		var record := ((source as Dictionary)[marker_id] as Dictionary).duplicate(true)
		var raw_position := record.get("position", []) as Array
		if raw_position.size() >= 2:
			record["position"] = Vector2(
				float(raw_position[0]),
				float(raw_position[1])
			)
		decoded[marker_id] = record
	return decoded


func _decode_segments(source: Variant) -> Array:
	var decoded: Array = []
	if not (source is Array):
		return decoded
	for raw_segment: Variant in source:
		if not (raw_segment is Array) or (raw_segment as Array).size() < 2:
			continue
		var raw_a := (raw_segment as Array)[0] as Array
		var raw_b := (raw_segment as Array)[1] as Array
		if raw_a.size() < 2 or raw_b.size() < 2:
			continue
		decoded.append([
			Vector2(float(raw_a[0]), float(raw_a[1])),
			Vector2(float(raw_b[0]), float(raw_b[1])),
		])
	return decoded


func _rect_from_array(source: Variant, fallback: Rect2) -> Rect2:
	if not (source is Array) or (source as Array).size() < 4:
		return fallback
	var values := source as Array
	return Rect2(
		float(values[0]),
		float(values[1]),
		float(values[2]),
		float(values[3])
	)


func _build_authored_subregions() -> void:
	if _subregions_root == null:
		return
	_clear_children(_subregions_root)
	for raw_region: Variant in _layout_document.get("subregions", []):
		if not (raw_region is Dictionary):
			continue
		var record := raw_region as Dictionary
		var region := Node2D.new()
		region.name = str(record.get("node_name", record.get("id", "Region")))
		region.set_meta("region_id", str(record.get("id", "")))
		region.set_meta("region_kind", str(record.get("kind", "approach_subregion")))
		region.set_meta("authoring_rect", _rect_from_array(record.get("rect", []), Rect2()))
		_subregions_root.add_child(region)


func get_mapper_authority_paths() -> PackedStringArray:
	return PackedStringArray([
		APPROACH_LAYOUT_DATA,
		APPROACH_COLLISION_DATA,
		APPROACH_OCCLUSION_DATA,
	])


func _get_route_floor_texture_path() -> String:
	var route_floor := _layout_document.get("route_floor", {}) as Dictionary
	return str(route_floor.get("texture_path", APPROACH_ROUTE_MASTER))


func _get_route_floor_rect() -> Rect2:
	var route_floor := _layout_document.get("route_floor", {}) as Dictionary
	return _rect_from_array(
		route_floor.get("rect", []),
		RECT_ROUTE_MASTER
	)
