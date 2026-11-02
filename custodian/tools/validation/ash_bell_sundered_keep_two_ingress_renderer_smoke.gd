extends SceneTree

const ASH_BELL_SCENE := preload(
	"res://game/world/approaches/ash_bell/ash_bell_lift_ingress_presentation.tscn"
)
const SUNDERED_KEEP_SCENE := preload(
	"res://game/world/vistas/sundered_keep/sundered_keep_procgen_vista_presentation.tscn"
)
const PROCGEN_SCRIPT := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const FOLIAGE_SPAWNER_SCRIPT := preload(
	"res://game/world/procgen/foliage/procgen_foliage_spawner.gd"
)

class MockMap extends Node2D:
	func get_runtime_tile_size() -> Vector2:
		return Vector2(16.0, 16.0)

	func minimap_tile_to_global(tile: Vector2i) -> Vector2:
		return global_position + Vector2(tile) * 16.0 + Vector2(8.0, 8.0)

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var ash := ASH_BELL_SCENE.instantiate() as AshBellLiftIngressPresentation
	host.add_child(ash)
	ash.global_position = Vector2.ZERO
	var clearance := ash.get_procgen_dressing_clearance_world_rect()
	_assert(clearance == Rect2(Vector2(-416.0, -432.0), Vector2(832.0, 608.0)), "Ash Bell clearance footprint drifted")
	_assert((ash.get_node("RearMassRoot") as Node2D).z_index == -8, "rear mass must remain behind foliage")
	_assert((ash.get_node("EntranceStructureRoot") as Node2D).z_index == 1, "entrance structure must remain behind the live Operator")
	_assert((ash.get_node("ForegroundOccluderRoot") as Node2D).z_index == 1, "idle cave breakup must remain behind the live Operator")

	var operator := Node2D.new()
	operator.global_position = ash.get_boarding_position()
	host.add_child(operator)
	operator.z_index = 2
	_assert(operator.z_index > (ash.get_node("EntranceStructureRoot") as Node2D).z_index, "Operator is not readable in front of idle entrance structure")

	var map := MockMap.new()
	host.add_child(map)
	var sundered := SUNDERED_KEEP_SCENE.instantiate() as SunderedKeepProcgenVistaPresentation
	host.add_child(sundered)
	sundered.set("_operator", operator)
	var frontage := _frontage_fixture()
	var sundered_ingress := Node2D.new()
	host.add_child(sundered_ingress)
	sundered.configure(sundered_ingress, map, {
		"map_size": Vector2i(256, 128),
		"sundered_keep_frontage": frontage,
	})
	await process_frame
	sundered.call("_evaluate_camera")
	var vista_root := sundered.get_node("VistaPresentationRoot") as Node2D
	var vista_state := sundered.get_world_vista_debug_state()
	var ash_camera_frame := Rect2(Vector2(-640.0, -360.0), Vector2(1280.0, 720.0))
	_assert(not vista_root.visible, "Sundered Keep vista remained visible at Ash Bell")
	_assert(not (vista_state.get("vista_clip_bounds", Rect2()) as Rect2).intersects(ash_camera_frame), "Sundered Keep storm/ocean clip reaches the Ash Bell camera frame")

	_validate_clearance_purge(clearance)
	_validate_deferred_guard()
	host.queue_free()
	if _errors.is_empty():
		print("[AshBellSunderedKeepTwoIngressRendererSmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error("[AshBellSunderedKeepTwoIngressRendererSmoke] %s" % error)
	quit(1)


func _validate_clearance_purge(clearance: Rect2) -> void:
	var procgen := PROCGEN_SCRIPT.new() as ProcGenTilemap
	var floor := TileMapLayer.new()
	floor.tile_set = TileSet.new()
	floor.tile_set.tile_size = Vector2i(16, 16)
	procgen.floor_tilemap = floor
	procgen.add_child(floor)
	var navigation := Node2D.new()
	navigation.name = "NavigationRegion2D"
	procgen.add_child(navigation)
	var prop_layer := Node2D.new()
	prop_layer.name = "PropLayer"
	navigation.add_child(prop_layer)
	var inside_tile := Vector2i.ZERO
	var outside_tile := Vector2i(40, 40)
	var inside_foliage := Node2D.new()
	var outside_foliage := Node2D.new()
	procgen.add_child(inside_foliage)
	procgen.add_child(outside_foliage)
	var foliage_nodes := procgen.get("_foliage_nodes") as Dictionary
	foliage_nodes[inside_tile] = inside_foliage
	foliage_nodes[outside_tile] = outside_foliage
	var pending := procgen.get("_pending_foliage_tiles") as Array
	pending.append_array([inside_tile, outside_tile])
	var ruin := Node2D.new()
	ruin.set_meta("source_tile", inside_tile)
	prop_layer.add_child(ruin)
	var claimed := procgen.claim_world_ingress_dressing_clearance(clearance)
	_assert(claimed.has_point(inside_tile), "clearance did not convert to the expected tile footprint")
	_assert(not foliage_nodes.has(inside_tile) and foliage_nodes.has(outside_tile), "existing foliage purge crossed or missed the clearance boundary")
	_assert(not pending.has(inside_tile) and pending.has(outside_tile), "deferred foliage candidates were not filtered")
	_assert(ruin.is_queued_for_deletion(), "ruin prop inside clearance was not purged")
	procgen.free()


func _validate_deferred_guard() -> void:
	var spawner := FOLIAGE_SPAWNER_SCRIPT.new() as ProcgenFoliageSpawner
	var blocked := Callable(func(_tile: Vector2i) -> bool: return true)
	var allowed := Callable(func(_tile: Vector2i) -> bool: return false)
	var base_context := {
		"foliage_density": 1.0,
		"is_inside_world_ingress_dressing_clearance": blocked,
	}
	_assert(not spawner.can_place_at(base_context, Vector2i.ZERO), "regeneration path accepted foliage inside ingress clearance")
	base_context["is_inside_world_ingress_dressing_clearance"] = allowed
	_assert(spawner.can_place_at(base_context, Vector2i.ZERO), "clearance guard rejected an otherwise valid outside tile")


func _frontage_fixture() -> Dictionary:
	var floor_cells := {}
	for x in range(124, 132):
		for y in range(12, 20):
			floor_cells[Vector2i(x, y)] = true
	return {
		"fortress_outward_direction": Vector2i.UP,
		"floor_cells": floor_cells,
		"camera_semantic_anchors": {
			"frontage_entry": Vector2i(124, 36),
			"first_influence_start": Vector2i(125, 32),
			"first_reveal_apex": Vector2i(126, 28),
			"first_return_complete": Vector2i(127, 24),
			"frontage_reveal_start": Vector2i(128, 22),
			"frontage_apex": Vector2i(129, 20),
			"gameplay_return": Vector2i(130, 18),
			"gate_threshold": Vector2i(131, 14),
		},
		"visual_module_anchors": {"fortress_front_anchor": Vector2i(131, 6)},
	}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
