extends RefCounted
class_name ProcgenAlpineCliffContactComposer

const CONTACT_TEXTURES := {
	"south_broad_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/south_broad_01.png",
	"south_broken_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/south_broken_01.png",
	"south_rooted_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/south_rooted_01.png",
	"east_broad_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/east_broad_01.png",
	"west_broad_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/west_broad_01.png",
	"north_broad_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/north_broad_01.png",
	"corner_se_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/corner_se_01.png",
	"corner_sw_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/corner_sw_01.png",
	"corner_ne_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/corner_ne_01.png",
	"corner_nw_01": "res://content/tiles/procgen_macro/runtime/alpine_cliff_contact/corner_nw_01.png",
}
const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const CONTACT_META := &"alpine_cliff_contact"

var _fascia_core_frontiers: Dictionary = {}
var _fascia_shoulder_frontiers: Dictionary = {}


func apply_frontier_plan(
	paint_plan: Dictionary,
	exterior_chasm_cells: Dictionary,
	blocked_cells: Dictionary,
	root: Node2D,
	seed: int,
	streaming_enabled: bool,
	world_scale: Vector2 = Vector2.ONE,
	profile: ProcgenCliffFasciaProfile = null,
	tile_to_world: Callable = Callable()
) -> Dictionary:
	clear(root)
	_fascia_core_frontiers.clear()
	_fascia_shoulder_frontiers.clear()
	if root == null or exterior_chasm_cells.is_empty():
		return _summary(0, 0)
	if profile != null and profile.contact_shoulder_tiles < 1:
		return _summary(0, 0, {}, false)
	if profile != null and not profile.ensure_cardinal_broad_contact:
		return _summary(0, 0)
	var by_direction: Dictionary = {Vector2i.UP: [], Vector2i.RIGHT: [], Vector2i.DOWN: [], Vector2i.LEFT: []}
	for paint_cell: Variant in paint_plan:
		var entry := paint_plan[paint_cell] as Dictionary
		var frontier := entry.get("frontier_cell", Vector2i.ZERO) as Vector2i
		var direction := entry.get("outward_direction", Vector2i.ZERO) as Vector2i
		if not exterior_chasm_cells.has(frontier) or blocked_cells.has(frontier) or bool(entry.get("wall_backed", false)):
			continue
		if by_direction.has(direction):
			(by_direction[direction] as Array).append(frontier)
	var runs_by_direction: Dictionary = {}
	var longest_run_by_direction := {"north": 0, "east": 0, "south": 0, "west": 0}
	var minimum_run := profile.contact_min_run_tiles if profile != null else 14
	for direction: Vector2i in by_direction:
		var cells: Array[Vector2i] = _unique_sorted(by_direction[direction] as Array)
		var current: Array[Vector2i] = []
		for cell: Vector2i in cells:
			var tangent_delta := Vector2i.RIGHT if direction in [Vector2i.UP, Vector2i.DOWN] else Vector2i.DOWN
			if not current.is_empty() and cell != current[-1] + tangent_delta:
				longest_run_by_direction[_direction_name(direction)] = maxi(int(longest_run_by_direction[_direction_name(direction)]), current.size())
				if current.size() >= minimum_run:
					_store_longest_run(runs_by_direction, direction, current)
				current.clear()
			current.append(cell)
		if current.size() >= minimum_run:
			_store_longest_run(runs_by_direction, direction, current)
		longest_run_by_direction[_direction_name(direction)] = maxi(int(longest_run_by_direction[_direction_name(direction)]), current.size())
	var safe_scale := Vector2(maxf(absf(world_scale.x), 0.001), maxf(absf(world_scale.y), 0.001))
	var created := 0
	var shoulder_tiles := profile.contact_shoulder_tiles if profile != null else 2
	var direction_counts := {"north": 0, "east": 0, "south": 0, "west": 0}
	var frontier_centers := {}
	var placements: Array[Dictionary] = []
	var attached_frontiers: Dictionary = {}
	var minimum_embed := profile.contact_socket_min_embed_px if profile != null else 24
	for direction in CARDINALS:
		if not runs_by_direction.has(direction):
			continue
		var cells := (runs_by_direction[direction] as Dictionary).cells as Array[Vector2i]
		var state := _state_for_run(direction, cells, seed)
		var texture := load(String(CONTACT_TEXTURES[state])) as Texture2D
		if texture == null:
			continue
		var texture_image := texture.get_image()
		var alpha_bounds := texture_image.get_used_rect() if texture_image != null else Rect2i(Vector2i.ZERO, texture.get_size())
		if alpha_bounds.size.x <= 0 or alpha_bounds.size.y <= 0:
			continue
		var socket_px := Vector2.INF
		if profile != null and profile.contact_socket_by_state.has(StringName(state)):
			socket_px = profile.contact_socket_by_state[StringName(state)] as Vector2
		if not is_finite(socket_px.x) or not is_finite(socket_px.y) or socket_px.x < 0.0 or socket_px.y < 0.0 or socket_px.x >= texture.get_width() or socket_px.y >= texture.get_height():
			placements.append({"frontier_cell": cells[cells.size() / 2], "outward_direction": direction, "contact_state": state, "attached": false, "reason": "missing_or_invalid_authored_socket", "socket_error_px": INF})
			continue
		var socket_embed_depth := _socket_embed_depth(texture_image, state, Vector2i(roundi(socket_px.x), roundi(socket_px.y)))
		if socket_embed_depth < minimum_embed:
			placements.append({"frontier_cell": cells[cells.size() / 2], "outward_direction": direction, "contact_state": state, "attached": false, "reason": "contact_frontier_socket_only_touches_silhouette", "socket_error_px": INF, "socket_embed_depth_px": socket_embed_depth})
			continue
		var midpoint := cells[cells.size() / 2]
		var scale_factor := _contact_scale(direction, alpha_bounds.size, cells.size())
		var local_scale := Vector2.ONE * scale_factor / safe_scale
		var sprite := Sprite2D.new()
		sprite.name = "AlpineCliffContact_%s_%s" % [_direction_name(direction), state]
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = local_scale
		var frontier_world := Vector2.ZERO
		if tile_to_world.is_valid():
			frontier_world = tile_to_world.call(midpoint) - Vector2(direction) * 16.0 * safe_scale
		else:
			frontier_world = root.to_global(Vector2(midpoint) * 32.0 + Vector2(16.0, 16.0) - Vector2(direction) * 16.0)
		var frontier_local := root.to_local(frontier_world)
		var socket_world := frontier_world
		sprite.position = frontier_local - socket_px * local_scale
		var resolved_socket_world := root.to_global(sprite.position + socket_px * local_scale)
		var socket_error_px := resolved_socket_world.distance_to(socket_world)
		if socket_error_px > 8.0:
			placements.append({"frontier_cell": midpoint, "outward_direction": direction, "contact_state": state, "socket_world_position": socket_world, "sprite_world_position": root.to_global(sprite.position), "attached": false, "reason": "contact_frontier_socket_misaligned", "socket_error_px": socket_error_px})
			sprite.free()
			continue
		sprite.visible = not streaming_enabled
		sprite.set_meta(CONTACT_META, true)
		sprite.set_meta("frontier_probes", _probe_cells(cells, direction))
		root.add_child(sprite)
		var placement := {
			"frontier_cell": midpoint,
			"outward_direction": direction,
			"contact_state": state,
			"socket_world_position": socket_world,
			"sprite_world_position": root.to_global(sprite.position),
			"socket_error_px": socket_error_px,
			"socket_embed_depth_px": socket_embed_depth,
			"attached": true,
		}
		sprite.set_meta("placement", placement)
		placements.append(placement)
		_record_fascia_blend_for_contact(cells, shoulder_tiles)
		for frontier_cell: Vector2i in cells:
			attached_frontiers[frontier_cell] = true
		created += 1
		direction_counts[_direction_name(direction)] = 1
		frontier_centers[_direction_name(direction)] = midpoint
	refresh_streaming_visibility(root, streaming_enabled, null, null)
	var summary := _summary(created, runs_by_direction.size(), direction_counts, true, longest_run_by_direction)
	summary["socket_embed_min_px"] = minimum_embed
	summary["frontier_centers"] = frontier_centers
	summary["placements"] = placements
	summary["attached_frontiers"] = attached_frontiers
	summary["attached_contact_count"] = created
	var max_socket_error := 0.0
	for placement: Dictionary in placements:
		if bool(placement.get("attached", false)):
			max_socket_error = maxf(max_socket_error, float(placement.get("socket_error_px", 0.0)))
	summary["max_socket_error_px"] = max_socket_error
	return summary


func get_fascia_blend_frontiers() -> Dictionary:
	return {"core": _fascia_core_frontiers.duplicate(true), "shoulder": _fascia_shoulder_frontiers.duplicate(true)}


func refresh_streaming_visibility(root: Node2D, streaming: bool, floor_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		if not child is Sprite2D or not child.has_meta(CONTACT_META):
			continue
		var visible_now := not streaming
		if streaming:
			visible_now = true
			for cell: Vector2i in child.get_meta("frontier_probes", []):
				if not _cell_visible(cell, floor_layer, wall_layer):
					visible_now = false
					break
		child.visible = visible_now


func clear(root: Node2D) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		if child.has_meta(CONTACT_META):
			root.remove_child(child)
			child.queue_free()


func _state_for_run(direction: Vector2i, cells: Array[Vector2i], seed: int) -> String:
	if direction == Vector2i.RIGHT: return "east_broad_01"
	if direction == Vector2i.LEFT: return "west_broad_01"
	if direction == Vector2i.UP: return "north_broad_01"
	var center := cells[cells.size() / 2]
	var variant := _stable_hash(center, seed ^ 0x3a7d91) % 3
	return ["south_broad_01", "south_broken_01", "south_rooted_01"][variant]


func _contact_scale(direction: Vector2i, alpha_size: Vector2i, run_tiles: int) -> float:
	var tangential_pixels := alpha_size.x if direction in [Vector2i.UP, Vector2i.DOWN] else alpha_size.y
	# Fit the full transparent canvas to the reserved frontier run. Its authored
	# side margins then tuck into the two-cell fascia shoulders while the opaque
	# geological silhouette owns the central core.
	return float(maxi(1, run_tiles) * 32) / float(maxi(1, tangential_pixels))


func _socket_embed_depth(image: Image, state: String, socket: Vector2i) -> int:
	if image == null or image.is_empty():
		return 0
	var inward_directions: Array[Vector2i] = []
	match state:
		"south_broad_01", "south_broken_01", "south_rooted_01": inward_directions = [Vector2i.UP]
		"east_broad_01": inward_directions = [Vector2i.LEFT]
		"west_broad_01": inward_directions = [Vector2i.RIGHT]
		"north_broad_01": inward_directions = [Vector2i.DOWN]
		"corner_se_01": inward_directions = [Vector2i.LEFT, Vector2i.UP]
		"corner_sw_01": inward_directions = [Vector2i.RIGHT, Vector2i.UP]
		"corner_ne_01": inward_directions = [Vector2i.LEFT, Vector2i.DOWN]
		"corner_nw_01": inward_directions = [Vector2i.RIGHT, Vector2i.DOWN]
		_: return 0
	var minimum_depth := 2147483647
	for direction: Vector2i in inward_directions:
		var cell := socket
		var depth := 0
		while cell.x >= 0 and cell.y >= 0 and cell.x < image.get_width() and cell.y < image.get_height() and image.get_pixelv(cell).a > 0.0:
			depth += 1
			cell += direction
		minimum_depth = mini(minimum_depth, depth)
	return minimum_depth if minimum_depth != 2147483647 else 0


func _record_fascia_blend_for_contact(covered_frontier: Array[Vector2i], shoulder_tiles: int) -> void:
	if covered_frontier.is_empty(): return
	var shoulder := mini(maxi(1, shoulder_tiles), maxi(1, covered_frontier.size() / 3))
	for index in covered_frontier.size():
		var cell := covered_frontier[index]
		if index < shoulder or index >= covered_frontier.size() - shoulder:
			_fascia_shoulder_frontiers[cell] = true
		else:
			_fascia_core_frontiers[cell] = true


func _store_longest_run(runs: Dictionary, direction: Vector2i, candidate: Array[Vector2i]) -> void:
	var existing := runs.get(direction, {}) as Dictionary
	var existing_cells: Array = existing.get("cells", [])
	if candidate.size() > existing_cells.size() or (candidate.size() == existing_cells.size() and (existing_cells.is_empty() or candidate[0] < existing_cells[0])):
		runs[direction] = {"direction": direction, "cells": candidate.duplicate()}


func _direction_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP: return "north"
	if direction == Vector2i.RIGHT: return "east"
	if direction == Vector2i.DOWN: return "south"
	return "west"


func _summary(created: int, qualified: int, direction_counts: Dictionary = {}, contract_valid := true, longest_run_by_direction: Dictionary = {}) -> Dictionary:
	return {
		"sprite_count": created,
		"qualified_runs": qualified,
		"direction_counts": direction_counts if not direction_counts.is_empty() else {"north": 0, "east": 0, "south": 0, "west": 0},
		"core_frontier_count": _fascia_core_frontiers.size(),
		"shoulder_frontier_count": _fascia_shoulder_frontiers.size(),
		"placement_contract_valid": contract_valid,
		"longest_eligible_run_tiles": longest_run_by_direction if not longest_run_by_direction.is_empty() else {"north": 0, "east": 0, "south": 0, "west": 0},
		"frontier_centers": {},
		"placements": [],
		"attached_frontiers": {},
		"attached_contact_count": 0,
		"max_socket_error_px": 0.0,
		"socket_embed_min_px": 24,
	}


func _probe_cells(cells: Array[Vector2i], outward: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for index in range(5):
		result.append(cells[roundi(float(index) * float(cells.size() - 1) / 4.0)] - outward)
	return result


func _cell_visible(cell: Vector2i, floor_layer: TileMapLayer, wall_layer: TileMapLayer) -> bool:
	return (floor_layer != null and floor_layer.get_cell_source_id(cell) >= 0) or (wall_layer != null and wall_layer.get_cell_source_id(cell) >= 0)


func _unique_sorted(values: Array) -> Array[Vector2i]:
	var set: Dictionary = {}
	for value: Variant in values:
		if value is Vector2i:
			set[value] = true
	var result: Array[Vector2i] = []
	for value: Variant in set:
		result.append(value as Vector2i)
	result.sort()
	return result


func _stable_hash(cell: Vector2i, seed: int) -> int:
	var value := seed ^ (cell.x * 73856093) ^ (cell.y * 19349663)
	return absi(value)
