extends SceneTree

const PRESENTATION_SCENE := preload(
	"res://game/world/vistas/sundered_keep/"
	+ "sundered_keep_procgen_vista_presentation.tscn"
)
const ROUTE_PATH := "res://content/routes/sundered_keep/sundered_keep_route.json"

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_route_authority()
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
	_assert(wall != null and wall.scale.is_equal_approx(Vector2(0.35, 0.35)), "outer wall must retain reviewed distant scale")
	_assert(citadel != null and citadel.scale.is_equal_approx(Vector2(0.33, 0.33)), "central citadel must retain reviewed distant scale")
	_assert(wall != null and wall.modulate.is_equal_approx(Color(0.40, 0.48, 0.58, 1.0)), "outer wall must retain distant secondary palette")
	_assert(citadel != null and citadel.modulate.is_equal_approx(Color(0.44, 0.51, 0.61, 1.0)), "central citadel must retain distant hero palette")
	_assert(wall != null and wall.position.is_equal_approx(Vector2(-150.0, -80.0)), "outer wall local composition was overwritten by semantic world anchors")
	_assert(citadel != null and citadel.position.is_equal_approx(Vector2(160.0, -150.0)), "central citadel local composition was overwritten by semantic world anchors")
	presentation.call("_set_ingress_presentation_visible", false)
	_assert(not ingress.visible, "ingress presentation must hide during vista camera ownership")
	presentation.call("_set_ingress_presentation_visible", true)
	_assert(ingress.visible, "ingress presentation must restore after vista camera release")
	presentation.set("_camera_state", {"first_enter_progress": 1.0, "frontage_enter_progress": 1.0})
	presentation.call("_apply_visual_state", 1.0, 1.0)
	var landmark := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/DistantKeep")
	var ruins := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/OceanRuinsPresentation") as Node2D
	var arch := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/OceanRuinsPresentation/BrokenArchWalkway") as Sprite2D
	var storm := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/StormHorizon") as Sprite2D
	var reveal_fog := presentation.get_node_or_null("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/RevealFog") as Sprite2D
	_assert(landmark == null, "procgen DistantKeep must be retired")
	_assert(ruins != null and arch != null and arch.texture != null, "offshore ruins composition must resolve")
	_assert(storm != null and storm.material is ShaderMaterial, "StormHorizon must own ocean mask material")
	_assert(ruins != null and ruins.modulate.a >= 0.20 and ruins.modulate.a <= 0.30, "ruins must recede without fully retiring")
	presentation.set("_camera_state", {"first_enter_progress": 1.0, "frontage_enter_progress": 0.45})
	presentation.call("_apply_visual_state", 1.0, 0.45)
	_assert(ruins != null and ruins.modulate.a > 0.20, "ruins should remain faint through takeover")
	_assert(reveal_fog != null and reveal_fog.modulate.a <= 0.051, "first reveal veil must clear before fortress composition")
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
	return {
		"landmark_id": &"sundered_keep_frontage",
		"gate_anchor": Vector2i(74, 14),
		"fortress_outward_direction": Vector2i.UP,
		"floor_cells": {Vector2i(74, 14): true},
		"ocean_cells": ocean_cells,
		"camera_semantic_anchors": {
			"frontage_entry": Vector2i(52, 52),
			"first_influence_start": Vector2i(56, 45),
			"first_reveal_apex": Vector2i(60, 38),
			"first_return_complete": Vector2i(64, 32),
			"frontage_reveal_start": Vector2i(68, 26),
			"frontage_apex": Vector2i(71, 21),
			"gameplay_return": Vector2i(73, 17),
			"gate_threshold": Vector2i(74, 14),
		},
		"visual_module_anchors": {
			"fortress_front_anchor": Vector2i(74, 6),
		},
	}


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
