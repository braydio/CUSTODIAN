extends SceneTree

const PRESENTATION_SCENE := preload(
	"res://game/world/vistas/sundered_keep/"
	+ "sundered_keep_procgen_vista_presentation.tscn"
)
const ROUTE_PATH := "res://content/routes/sundered_keep/sundered_keep_route.json"
const CAMERA_DIRECTOR := preload("res://game/world/procgen/landmarks/sundered_keep/sundered_keep_frontage_camera_director.gd")
const VISTA_CONTRACT := preload("res://game/world/procgen/landmarks/sundered_keep/sundered_keep_vista_contract.gd")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_route_authority()
	_assert_camera_director_contract()
	var host := Node2D.new()
	host.name = "SunderedKeepProcgenVistaLayeringSmokeRoot"
	root.add_child(host)
	var map_instance := Node2D.new()
	map_instance.name = "GeneratedMap"
	host.add_child(map_instance)
	var ingress := Node2D.new()
	ingress.name = "SunderedKeepIngressSite"
	host.add_child(ingress)
	var presentation := PRESENTATION_SCENE.instantiate() as Node2D
	host.add_child(presentation)
	var frontage := _frontage_fixture()
	var level_data := {
		"map_size": Vector2i(96, 96),
		"floor_cells": [Vector2i(74, 14)],
		"sundered_keep_frontage": frontage,
	}
	presentation.call("configure", ingress, map_instance, level_data)
	await process_frame

	_assert(not frontage.is_empty(), "generated level data must retain sundered_keep_frontage")
	_assert((frontage.get("floor_cells", {}) as Dictionary).has(Vector2i(74, 14)), "frontage gate floor must be generated walkable authority")
	var vista_root := presentation.get_node_or_null("VistaPresentationRoot") as Node2D
	var clip := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip") as Polygon2D
	var wall := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/FortressPresentation/OuterWall") as Sprite2D
	var citadel := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/FortressPresentation/CentralCitadel") as Sprite2D
	_assert(vista_root != null and vista_root.z_index < 0 and not vista_root.z_as_relative, "vista root must use absolute depth behind gameplay")
	_assert(clip != null and clip.clip_children == CanvasItem.CLIP_CHILDREN_ONLY, "vista must use its exterior-facing clip")
	_assert(presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/GateShadow") == null, "procgen vista must not restore the route-owned gate-shadow handoff")
	_assert(wall != null and wall.scale.is_equal_approx(Vector2(0.24, 0.24)), "outer wall baseline scale mismatch")
	_assert(citadel != null and citadel.scale.is_equal_approx(Vector2(0.22, 0.22)), "central citadel baseline scale mismatch")
	_assert(wall != null and wall.modulate.is_equal_approx(Color(0.40, 0.48, 0.58, 1.0)), "outer wall must retain distant secondary palette")
	_assert(citadel != null and citadel.modulate.is_equal_approx(Color(0.44, 0.51, 0.61, 1.0)), "central citadel must retain distant hero palette")
	_assert(wall != null and wall.position.is_equal_approx(Vector2(-170.0, 30.0)), "outer wall local composition mismatch")
	_assert(citadel != null and citadel.position.is_equal_approx(Vector2(145.0, -80.0)), "central citadel local composition mismatch")
	presentation.call("_set_ingress_presentation_visible", false)
	_assert(not ingress.visible, "ingress presentation must hide during vista camera ownership")
	presentation.call("_set_ingress_presentation_visible", true)
	_assert(ingress.visible, "ingress presentation must restore after vista camera release")
	presentation.set("_camera_state", {"route_s_cells": 36.0})
	presentation.call("_apply_visual_state", 36.0)
	var landmark := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/DistantKeep")
	var ruins := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/OceanRuinsPresentation") as Node2D
	var arch := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/OceanRuinsPresentation/BrokenArchWalkway") as Sprite2D
	var storm := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/StormHorizon") as Sprite2D
	var reveal_fog := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/RevealFog") as Sprite2D
	_assert(landmark == null, "procgen DistantKeep must be retired")
	_assert(ruins != null and arch != null and arch.texture != null, "offshore ruins composition must resolve")
	_assert(storm != null and storm.material is ShaderMaterial, "StormHorizon must own ocean mask material")
	_assert(ruins != null and ruins.modulate.a >= 0.20 and ruins.modulate.a <= 0.30, "ruins must recede without fully retiring")
	presentation.set("_camera_state", {"route_s_cells": 16.0})
	presentation.call("_apply_visual_state", 16.0)
	_assert(ruins != null and ruins.modulate.a > 0.20, "ruins should remain faint through takeover")
	_assert(reveal_fog != null and not reveal_fog.visible, "first reveal veil must remain hidden")
	for node in _all_descendants(presentation):
		_assert(not (node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D or node is NavigationRegion2D), "vista presentation must not own collision/navigation: %s" % node.name)
		if node is Sprite2D:
			_assert(vista_root != null and vista_root.is_ancestor_of(node), "vista sprite escaped presentation-only root: %s" % node.name)
	var state := presentation.call("get_world_vista_debug_state") as Dictionary
	var clip_bounds: Rect2 = state.get("vista_clip_bounds", Rect2())
	var playable_bounds: Rect2 = state.get("playable_floor_bounds", Rect2())
	var ocean_bounds: Rect2 = state.get("ocean_bounds", Rect2())
	_assert(clip_bounds.has_area(), "vista exterior clip bounds must be configured")
	_assert(playable_bounds.has_area(), "playable frontage bounds must be configured")
	_assert(ocean_bounds.has_area(), "resolved ocean bounds must be configured")
	_assert(not clip_bounds.intersects(playable_bounds), "ocean/storm clip must not cover playable frontage floor bounds")
	_assert(clip_bounds.intersects(ocean_bounds), "vista clip does not correspond to resolved ocean geography")
	_assert(int(state.get("ocean_cell_count", 0)) > 0, "vista debug state omitted resolved ocean cells")
	_assert(bool(state.get("ocean_mask_configured", false)), "generated ocean mask was not configured")
	_assert(is_equal_approx(float(presentation.call("get_ocean_mask_alpha", Vector2i(60, 6))), 1.0), "ocean mask sample is not opaque")
	_assert(is_equal_approx(float(presentation.call("get_ocean_mask_alpha", Vector2i(74, 14))), 0.0), "floor mask sample is not transparent")
	var ruins_cell: Vector2i = state.get("ocean_ruins_anchor_cell", Vector2i(-1, -1))
	_assert((frontage.get("ocean_cells", {}) as Dictionary).has(ruins_cell), "ruins anchor is not authoritative ocean")
	_assert(not (frontage.get("floor_cells", {}) as Dictionary).has(ruins_cell), "ruins anchor overlaps floor")

	host.queue_free()
	if _errors.is_empty():
		print("[SunderedKeepProcgenVistaLayeringSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[SunderedKeepProcgenVistaLayeringSmoke] %s" % error)
	quit(1)


func _assert_route_authority() -> void:
	var file := FileAccess.open(ROUTE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	_assert(parsed is Dictionary, "production route JSON must parse")
	if not parsed is Dictionary:
		return
	var placement := ((parsed as Dictionary).get("ingress", {}) as Dictionary).get("placement", {}) as Dictionary
	_assert(String(placement.get("strategy", "")) == "procgen_landmark_terminal", "production ingress must use procgen_landmark_terminal")
	_assert(String(placement.get("landmark_data_key", "")) == "sundered_keep_frontage", "production ingress must resolve generated frontage metadata")


func _frontage_fixture() -> Dictionary:
	var ocean_cells: Dictionary = {}
	for y in range(0, 14):
		for x in range(54, 94):
			ocean_cells[Vector2i(x, y)] = true
	var centerline: Array[Vector2i] = []
	for y in range(66, 13, -1):
		centerline.append(Vector2i(74, y))
	return {
		"landmark_id": &"sundered_keep_frontage",
		"gate_anchor": Vector2i(74, 14),
		"fortress_outward_direction": Vector2i.UP,
		"floor_cells": {Vector2i(74, 14): true},
		"ocean_cells": ocean_cells,
		"route_centerline": centerline,
		"camera_semantic_indices": {"first_influence_start": 0, "gameplay_return": 36, "gate_threshold": 52},
		"camera_semantic_anchors": {
			"frontage_entry": Vector2i(74, 66),
			"first_influence_start": Vector2i(74, 66),
			"frontage_reveal_start": Vector2i(74, 58),
			"first_reveal_apex": Vector2i(74, 50),
			"vista_apex": Vector2i(74, 50),
			"frontage_apex": Vector2i(74, 46),
			"moonlight_anchor": Vector2i(74, 46),
			"vista_apex_plateau_end": Vector2i(74, 42),
			"first_return_complete": Vector2i(74, 30),
			"gameplay_return": Vector2i(74, 30),
			"gate_threshold": Vector2i(74, 14),
		},
		"visual_module_anchors": {
			"fortress_front_anchor": Vector2i(74, 6),
		},
	}


func _assert_camera_director_contract() -> void:
	var director := CAMERA_DIRECTOR.new()
	var cardinal_cells: Array = [Vector2i(0, 0), Vector2i(4, 0)]
	var cardinal_world := PackedVector2Array([Vector2(0, 0), Vector2(128, 0)])
	var cardinal := director.call("project_onto_centerline", Vector2(64, 20), cardinal_cells, cardinal_world) as Dictionary
	_assert(absf(float(cardinal.get("route_arc_cells", 0.0)) - 2.0) < 0.01, "cardinal/off-center projection is incorrect")
	var diagonal_cells: Array = [Vector2i(0, 0), Vector2i(4, 4)]
	var diagonal_world := PackedVector2Array([Vector2(0, 0), Vector2(128, 128)])
	var diagonal := director.call("project_onto_centerline", Vector2(64, 64), diagonal_cells, diagonal_world) as Dictionary
	_assert(absf(float(diagonal.get("route_arc_cells", 0.0)) - sqrt(8.0)) < 0.01, "diagonal projection is incorrect")
	var cells: Array = [Vector2i(0, 0), Vector2i(4, 0), Vector2i(8, 4), Vector2i(12, 4)]
	var world := PackedVector2Array([Vector2(0, 0), Vector2(128, 0), Vector2(256, 128), Vector2(384, 128)])
	var projection := director.call("project_onto_centerline", Vector2(256, 140), cells, world) as Dictionary
	_assert(absf(float(projection.get("route_arc_cells", 0.0)) - (4.0 + sqrt(32.0))) < 0.01, "curved/off-center polyline projection lost tile arc length")
	for key in VISTA_CONTRACT.CAMERA_WEIGHT_KEYS:
		var s := float(key[0])
		_assert(is_equal_approx(VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.CAMERA_WEIGHT_KEYS, s), float(key[1])), "camera weight key mismatch at S%.0f" % s)
	for keys in [VISTA_CONTRACT.CAMERA_ZOOM_KEYS, VISTA_CONTRACT.CAMERA_OFFSET_Y_KEYS]:
		for key in keys:
			_assert(is_equal_approx(VISTA_CONTRACT.sample_spatial_key_curve(keys, float(key[0])), float(key[1])), "spatial camera key mismatch at S%.0f" % float(key[0]))
	_assert(is_equal_approx(VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.CAMERA_WEIGHT_KEYS, 18.0), 1.0), "camera apex is not stable S16-S24")
	_assert(is_zero_approx(VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.CAMERA_WEIGHT_KEYS, 36.0)), "camera does not return at S36")


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		result.append(current)
		for child in current.get_children():
			pending.append(child)
	return result


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
