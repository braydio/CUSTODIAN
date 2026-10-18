extends RefCounted
class_name CarrowInteriorLayoutDraft

const TILE_SIZE := 32
const SCHEMA := "custodian.carrow_layout_draft.v1"
const CATALOG_PATH := "res://content/metadata/assets/generated/asset_catalog.generated.json"
const FLOOR_FAMILY := "carrow_machine_house_floor"
const WALL_FAMILY := "carrow_machine_house_walls"
const PROP_FAMILY := "carrow_machine_house_props"
const ROOM_IDS := ["west_draft_house", "east_machine_house", "operations_house"]

const ROOM_CONFIGS := {
	"west_draft_house": {
		"grid_wh": Vector2i(24, 18),
		"scene": "res://scenes/debug/carrow_machine_house_scale_24x18.tscn",
		"offmap_origin_cell": Vector2i(90, 38),
		"storage": [
			{"storage_id": "carrow_draft_filter_cradle", "display_name": "Service Filter Cradle", "resources": {"ruin_scrap": 18, "structural_alloy": 2}},
			{"storage_id": "carrow_emergency_parts_rack", "display_name": "Emergency Parts Rack", "resources": {"structural_alloy": 6, "power_components": 1, "ruin_scrap": 8}},
		],
	},
	"east_machine_house": {
		"grid_wh": Vector2i(30, 22),
		"scene": "res://scenes/debug/carrow_machine_house_scale_30x22.tscn",
		"offmap_origin_cell": Vector2i(90, 8),
		"storage": [
			{"storage_id": "carrow_service_parts_locker", "display_name": "Service Parts Locker", "resources": {"ruin_scrap": 52, "structural_alloy": 4}},
			{"storage_id": "carrow_structural_spares_rack", "display_name": "Structural Spares Rack", "resources": {"structural_alloy": 14, "ruin_scrap": 16}},
			{"storage_id": "carrow_power_components_cabinet", "display_name": "Power Components Cabinet", "resources": {"power_components": 4, "capacitor_dust": 3, "ruin_scrap": 10}},
		],
	},
	"operations_house": {
		"grid_wh": Vector2i(36, 26),
		"scene": "res://scenes/debug/carrow_machine_house_scale_36x26.tscn",
		"offmap_origin_cell": Vector2i(90, 64),
		"storage": [
			{"storage_id": "carrow_operations_emergency_spares", "display_name": "Emergency Spares Rack", "resources": {"ruin_scrap": 22, "structural_alloy": 3, "power_components": 1}},
		],
	},
}


static func room_config(room_id: String) -> Dictionary:
	return (ROOM_CONFIGS.get(room_id, {}) as Dictionary).duplicate(true)


static func asset_records() -> Array[Dictionary]:
	var catalog := _read_catalog()
	var families := catalog.get("families", {}) as Dictionary
	var result: Array[Dictionary] = []
	for family_id in [FLOOR_FAMILY, WALL_FAMILY, PROP_FAMILY]:
		var family := families.get(family_id, {}) as Dictionary
		var assets := family.get("assets", {}) as Dictionary
		var keys: Array = assets.keys()
		keys.sort()
		for key_variant in keys:
			var key := String(key_variant)
			var record := (assets[key] as Dictionary).duplicate(true)
			var asset_id := "%s/%s" % [family_id, key]
			var path := "res://%s" % String(record.get("path", ""))
			if not ResourceLoader.exists(path, "Texture2D"):
				continue
			result.append({
				"asset_id": asset_id,
				"family_id": family_id,
				"state_id": String(record.get("state_id", "")),
				"direction": String(record.get("direction", "")),
				"path": path,
				"frame_size": record.get("frame_size", []),
				"sha256": String(record.get("sha256", "")),
			})
	return result


static func asset_record(asset_id: String) -> Dictionary:
	for value in asset_records():
		if String(value.asset_id) == asset_id:
			return value
	return {}


static func floor_asset_ids() -> Array[String]:
	var result: Array[String] = []
	for value in asset_records():
		if String(value.asset_id).begins_with(FLOOR_FAMILY + "/"):
			result.append(String(value.asset_id))
	return result


static func source_refs() -> Array[Dictionary]:
	var paths := {
		"asset_catalog": CATALOG_PATH,
		"operator_scene": "res://game/actors/operator/operator.tscn",
		"operator_script": "res://game/actors/operator/operator.gd",
		"camera_script": "res://game/world/camera.gd",
		"fixture_script": "res://tools/level_authoring/carrow_machine_house_scale_fixture.gd",
		"production_room_registry": "res://game/world/gothic_compound/gothic_compound_map.gd",
		"floor_slab_plain_01": "res://content/tiles/interiors/runtime/floor_carrow_slab_plain_01_32.png",
	}
	for room_id in ROOM_IDS:
		paths["fixture_" + room_id] = String(ROOM_CONFIGS[room_id].scene)
	var ids: Array = paths.keys()
	ids.sort()
	var result: Array[Dictionary] = []
	for id_variant in ids:
		var id := String(id_variant)
		var path := String(paths[id])
		result.append({"id": id, "path": path, "sha256": _resource_sha256(path)})
	return result


static func create_draft(room_id: String) -> Dictionary:
	var config := room_config(room_id)
	if config.is_empty():
		return {}
	var grid: Vector2i = config.grid_wh
	var door_y := grid.y - 1
	var door_left := (grid.x / 2) - 1
	var storage: Array = []
	for value: Dictionary in config.storage:
		storage.append({
			"storage_id": String(value.storage_id),
			"display_name": String(value.display_name),
			"resources": (value.resources as Dictionary).duplicate(true),
			"art_placement_id": "",
			"anchor_cell": [],
		})
	var draft := {
		"schema": SCHEMA,
		"room_id": room_id,
		"grid_wh": [grid.x, grid.y],
		"tile_size": TILE_SIZE,
		"offmap_origin_cell": [config.offmap_origin_cell.x, config.offmap_origin_cell.y],
		"base_floor_state": "slab_plain_01",
		"source_refs": source_refs(),
		"floor_regions": [],
		"art_placements": [],
		"collision_shapes": _default_collision_shapes(grid, door_left),
		"portal_cells": [[door_left, door_y], [door_left + 1, door_y], [door_left + 2, door_y]],
		"storage_anchors": storage,
		"waypoints": [],
		"content_sha256": "",
	}
	return with_digest(draft)


static func paint_floor_cell(draft: Dictionary, cell: Vector2i, state_id: String) -> bool:
	var config := room_config(String(draft.get("room_id", "")))
	var grid: Vector2i = config.get("grid_wh", Vector2i.ZERO)
	if config.is_empty() or not _cell_in_bounds(cell, grid) or not floor_asset_ids().has(FLOOR_FAMILY + "/" + state_id + "::omni"):
		return false
	var regions: Array = draft.get("floor_regions", []).duplicate(true)
	for region_variant in regions.duplicate():
		if not region_variant is Dictionary:
			continue
		var region := region_variant as Dictionary
		var cells: Array = region.get("cells", []).duplicate(true)
		for index in range(cells.size() - 1, -1, -1):
			if _cell(cells[index]) == cell:
				cells.remove_at(index)
		region["cells"] = cells
		if cells.is_empty():
			regions.erase(region)
	var target_id := "floor_%s" % state_id
	var target: Dictionary = {}
	for region_variant in regions:
		if String((region_variant as Dictionary).get("id", "")) == target_id:
			target = region_variant
			break
	if target.is_empty():
		target = {"id": target_id, "state_id": state_id, "cells": []}
		regions.append(target)
	var target_cells: Array = target.get("cells", [])
	target_cells.append([cell.x, cell.y])
	target["cells"] = target_cells
	draft["floor_regions"] = regions
	return true


static func erase_floor_cell(draft: Dictionary, cell: Vector2i) -> bool:
	var changed := false
	var regions: Array = draft.get("floor_regions", []).duplicate(true)
	for region_variant in regions.duplicate():
		if not region_variant is Dictionary:
			continue
		var region := region_variant as Dictionary
		var cells: Array = region.get("cells", []).duplicate(true)
		for index in range(cells.size() - 1, -1, -1):
			if _cell(cells[index]) == cell:
				cells.remove_at(index)
				changed = true
		region["cells"] = cells
		if cells.is_empty():
			regions.erase(region)
	draft["floor_regions"] = regions
	return changed


static func place_art(draft: Dictionary, placement_id: String, asset_id: String, anchor: Vector2i, scale := Vector2.ONE, z_index := -10) -> bool:
	if placement_id.is_empty() or asset_record(asset_id).is_empty():
		return false
	for value: Dictionary in draft.get("art_placements", []):
		if String(value.get("placement_id", "")) == placement_id:
			return false
	var family := asset_id.get_slice("/", 0)
	var default_z := -18 if family == WALL_FAMILY else -10
	var placements: Array = draft.get("art_placements", []).duplicate(true)
	placements.append({
		"placement_id": placement_id,
		"asset_id": asset_id,
		"anchor_cell": [anchor.x, anchor.y],
		"anchor_mode": "bottom_center",
		"scale": [scale.x, scale.y],
		"z_index": default_z if z_index == -10 else z_index,
	})
	draft["art_placements"] = placements
	return true


static func move_art(draft: Dictionary, placement_id: String, anchor: Vector2i) -> bool:
	var found := false
	var placements: Array = draft.get("art_placements", []).duplicate(true)
	for value: Dictionary in placements:
		if String(value.get("placement_id", "")) == placement_id:
			value["anchor_cell"] = [anchor.x, anchor.y]
			found = true
	if not found:
		return false
	draft["art_placements"] = placements
	for value: Dictionary in draft.get("storage_anchors", []):
		if String(value.get("art_placement_id", "")) == placement_id:
			value["anchor_cell"] = [anchor.x, anchor.y]
	return true


static func delete_art(draft: Dictionary, placement_id: String) -> bool:
	var placements: Array = draft.get("art_placements", []).duplicate(true)
	var removed := false
	for index in range(placements.size() - 1, -1, -1):
		if String((placements[index] as Dictionary).get("placement_id", "")) == placement_id:
			placements.remove_at(index)
			removed = true
	if not removed:
		return false
	draft["art_placements"] = placements
	for value: Dictionary in draft.get("storage_anchors", []):
		if String(value.get("art_placement_id", "")) == placement_id:
			value["art_placement_id"] = ""
			value["anchor_cell"] = []
	return true


static func add_collision_rect(draft: Dictionary, shape_id: String, rect: Rect2i) -> bool:
	if shape_id.is_empty() or rect.size.x <= 0 or rect.size.y <= 0:
		return false
	for value: Dictionary in draft.get("collision_shapes", []):
		if String(value.get("id", "")) == shape_id:
			return false
	var shapes: Array = draft.get("collision_shapes", []).duplicate(true)
	shapes.append({"id": shape_id, "kind": "rect", "owner": "user", "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	draft["collision_shapes"] = shapes
	return true


static func move_collision_rect(draft: Dictionary, shape_id: String, origin: Vector2i) -> bool:
	for value: Dictionary in draft.get("collision_shapes", []):
		if String(value.get("id", "")) != shape_id:
			continue
		var rect: Array = value.get("rect", [])
		if rect.size() != 4:
			return false
		value["rect"] = [origin.x, origin.y, int(rect[2]), int(rect[3])]
		return true
	return false


static func delete_collision_shape(draft: Dictionary, shape_id: String) -> bool:
	var shapes: Array = draft.get("collision_shapes", []).duplicate(true)
	for index in range(shapes.size() - 1, -1, -1):
		if String((shapes[index] as Dictionary).get("id", "")) == shape_id:
			shapes.remove_at(index)
			draft["collision_shapes"] = shapes
			return true
	return false


static func set_portal_center(draft: Dictionary, center_x: int) -> bool:
	var config := room_config(String(draft.get("room_id", "")))
	if config.is_empty():
		return false
	var grid: Vector2i = config.grid_wh
	var left := center_x - 1
	if left < 1 or left + 3 > grid.x - 1:
		return false
	var door_y := grid.y - 1
	draft["portal_cells"] = [[left, door_y], [left + 1, door_y], [left + 2, door_y]]
	var shapes: Array = draft.get("collision_shapes", []).duplicate(true)
	for index in range(shapes.size() - 1, -1, -1):
		var id := String((shapes[index] as Dictionary).get("id", ""))
		if id == "wall_south_west" or id == "wall_south_east":
			shapes.remove_at(index)
	shapes.append({"id": "wall_south_west", "kind": "rect", "owner": "perimeter", "rect": [0, door_y, left, 1]})
	shapes.append({"id": "wall_south_east", "kind": "rect", "owner": "perimeter", "rect": [left + 3, door_y, grid.x - left - 3, 1]})
	draft["collision_shapes"] = shapes
	return true


static func bind_storage(draft: Dictionary, storage_id: String, placement_id: String) -> bool:
	var placement: Dictionary = {}
	for value: Dictionary in draft.get("art_placements", []):
		if String(value.get("placement_id", "")) == placement_id:
			placement = value
			break
	if placement.is_empty():
		return false
	for value: Dictionary in draft.get("storage_anchors", []):
		if String(value.get("storage_id", "")) == storage_id:
			value["art_placement_id"] = placement_id
			value["anchor_cell"] = placement.get("anchor_cell", []).duplicate()
			return true
	return false


static func unbind_storage(draft: Dictionary, storage_id: String) -> bool:
	for value: Dictionary in draft.get("storage_anchors", []):
		if String(value.get("storage_id", "")) == storage_id:
			value["art_placement_id"] = ""
			value["anchor_cell"] = []
			return true
	return false


static func set_waypoint(draft: Dictionary, waypoint_id: String, cell: Vector2i) -> bool:
	if waypoint_id.strip_edges().is_empty():
		return false
	var waypoints: Array = draft.get("waypoints", []).duplicate(true)
	for value: Dictionary in waypoints:
		if String(value.get("id", "")) == waypoint_id:
			value["cell"] = [cell.x, cell.y]
			draft["waypoints"] = waypoints
			return true
	waypoints.append({"id": waypoint_id, "cell": [cell.x, cell.y]})
	draft["waypoints"] = waypoints
	return true


static func delete_waypoint(draft: Dictionary, waypoint_id: String) -> bool:
	var waypoints: Array = draft.get("waypoints", []).duplicate(true)
	for index in range(waypoints.size() - 1, -1, -1):
		if String((waypoints[index] as Dictionary).get("id", "")) == waypoint_id:
			waypoints.remove_at(index)
			draft["waypoints"] = waypoints
			return true
	return false


static func is_safe_output_path(path: String) -> bool:
	var repo_root := ProjectSettings.globalize_path("res://").get_base_dir().simplify_path()
	var safe_root := repo_root.path_join("reports/carrow_layout_authoring").simplify_path()
	var candidate := path.simplify_path()
	return candidate == safe_root or candidate.begins_with(safe_root + "/")


static func draft_path(room_id: String) -> String:
	if not ROOM_IDS.has(room_id):
		return ""
	var repo_root := ProjectSettings.globalize_path("res://").get_base_dir()
	return repo_root.path_join("reports/carrow_layout_authoring/%s.draft.json" % room_id)


static func _default_collision_shapes(grid: Vector2i, door_left: int) -> Array[Dictionary]:
	return [
		{"id": "wall_north", "kind": "rect", "owner": "perimeter", "rect": [0, 0, grid.x, 1]},
		{"id": "wall_west", "kind": "rect", "owner": "perimeter", "rect": [0, 1, 1, grid.y - 2]},
		{"id": "wall_east", "kind": "rect", "owner": "perimeter", "rect": [grid.x - 1, 1, 1, grid.y - 2]},
		{"id": "wall_south_west", "kind": "rect", "owner": "perimeter", "rect": [0, grid.y - 1, door_left, 1]},
		{"id": "wall_south_east", "kind": "rect", "owner": "perimeter", "rect": [door_left + 3, grid.y - 1, grid.x - door_left - 3, 1]},
	]


static func with_digest(source: Dictionary) -> Dictionary:
	var result := canonical_copy(source)
	result.erase("content_sha256")
	result["content_sha256"] = _sha256(JSON.stringify(result, "", true, true))
	return result


static func canonical_copy(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	for field in ["grid_wh", "offmap_origin_cell"]:
		var pair: Variant = result.get(field, [])
		if pair is Array and (pair as Array).size() == 2:
			result[field] = [int(pair[0]), int(pair[1])]
	if result.has("tile_size"):
		result["tile_size"] = int(result.tile_size)
	_sort_records(result, "source_refs", "id")
	_sort_records(result, "floor_regions", "id")
	_sort_records(result, "art_placements", "placement_id")
	_sort_records(result, "collision_shapes", "id")
	_sort_records(result, "storage_anchors", "storage_id")
	_sort_records(result, "waypoints", "id")
	for region_variant in result.get("floor_regions", []):
		if region_variant is Dictionary:
			(region_variant as Dictionary)["cells"] = _sort_cells((region_variant as Dictionary).get("cells", []))
	result["portal_cells"] = _sort_cells(result.get("portal_cells", []))
	for placement_variant in result.get("art_placements", []):
		var placement := placement_variant as Dictionary
		placement["anchor_cell"] = _int_pair(placement.get("anchor_cell", []))
		if placement.has("z_index"):
			placement["z_index"] = int(placement.z_index)
	for shape_variant in result.get("collision_shapes", []):
		var shape := shape_variant as Dictionary
		var rect: Variant = shape.get("rect", [])
		if rect is Array and (rect as Array).size() == 4:
			shape["rect"] = [int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3])]
	for storage_variant in result.get("storage_anchors", []):
		var storage := storage_variant as Dictionary
		if storage.get("anchor_cell", []) is Array and (storage.get("anchor_cell", []) as Array).size() == 2:
			storage["anchor_cell"] = _int_pair(storage.anchor_cell)
		var resources: Variant = storage.get("resources", {})
		if resources is Dictionary:
			for resource_id in (resources as Dictionary).keys():
				(resources as Dictionary)[resource_id] = int((resources as Dictionary)[resource_id])
	for waypoint_variant in result.get("waypoints", []):
		var waypoint := waypoint_variant as Dictionary
		waypoint["cell"] = _int_pair(waypoint.get("cell", []))
	return result


static func serialize(source: Dictionary) -> String:
	var result := with_digest(source)
	return JSON.stringify(result, "\t", true, true) + "\n"


static func has_valid_digest(source: Dictionary) -> bool:
	var given := String(source.get("content_sha256", ""))
	if given.length() != 64:
		return false
	var copy := source.duplicate(true)
	copy.erase("content_sha256")
	return _sha256(JSON.stringify(canonical_copy(copy), "", true, true)) == given


static func validate(source: Dictionary, operator_shape: CapsuleShape2D, shape_offset := Vector2.ZERO, operator_scale := Vector2.ONE) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var checks: Array[Dictionary] = []
	var room_id := String(source.get("room_id", ""))
	var config := room_config(room_id)
	if config.is_empty():
		errors.append("unknown room_id")
		return _report(errors, warnings, checks)
	var grid: Vector2i = config.grid_wh
	if source.get("schema") != SCHEMA:
		errors.append("unsupported draft schema")
	if source.get("grid_wh") != [grid.x, grid.y]:
		errors.append("room grid does not match the approved size")
	if int(source.get("tile_size", -1)) != TILE_SIZE:
		errors.append("tile_size must be 32")
	if source.get("offmap_origin_cell") != [config.offmap_origin_cell.x, config.offmap_origin_cell.y]:
		errors.append("off-map allocation is stale or differs from the deterministic plan")
	if not has_valid_digest(source):
		errors.append("content_sha256 does not match canonical draft content")
	if source.get("source_refs") != source_refs():
		errors.append("source references are stale or do not match registered source hashes")
	if String(source.get("base_floor_state", "")) != "slab_plain_01":
		errors.append("base floor must remain registered slab_plain_01")
	var floor_assets := floor_asset_ids()
	var floor_cells := {}
	for region_variant in source.get("floor_regions", []):
		if not region_variant is Dictionary:
			errors.append("floor region is not an object")
			continue
		var region := region_variant as Dictionary
		var state_id := String(region.get("state_id", ""))
		if not floor_assets.has(FLOOR_FAMILY + "/" + state_id + "::omni"):
			errors.append("unregistered floor state: " + state_id)
		for cell_variant in region.get("cells", []):
			var cell := _cell(cell_variant)
			if not _cell_in_bounds(cell, grid):
				errors.append("floor cell outside room bounds: %s" % str(cell))
				continue
			var key := "%d,%d" % [cell.x, cell.y]
			if floor_cells.has(key):
				errors.append("overlapping floor regions at %s" % key)
			floor_cells[key] = state_id
	var placement_ids := {}
	var placement_by_id := {}
	var art_bounds: Array[Dictionary] = []
	var catalog := _asset_lookup()
	for placement_variant in source.get("art_placements", []):
		if not placement_variant is Dictionary:
			errors.append("art placement is not an object")
			continue
		var placement := placement_variant as Dictionary
		var placement_id := String(placement.get("placement_id", ""))
		var asset_id := String(placement.get("asset_id", ""))
		if placement_id.is_empty() or placement_ids.has(placement_id):
			errors.append("art placement IDs must be non-empty and unique: " + placement_id)
		placement_ids[placement_id] = true
		placement_by_id[placement_id] = placement
		var asset: Dictionary = catalog.get(asset_id, {})
		if asset.is_empty():
			errors.append("unregistered or missing art asset: " + asset_id)
			continue
		if not ResourceLoader.exists(String(asset.path), "Texture2D"):
			errors.append("art texture does not exist: " + asset_id)
		var anchor := _cell(placement.get("anchor_cell", []))
		if not _cell_in_bounds(anchor, grid):
			errors.append("art anchor outside room bounds: " + placement_id)
		var scale_value := placement.get("scale", [1.0, 1.0]) as Array
		if scale_value.size() != 2 or float(scale_value[0]) <= 0.0 or float(scale_value[1]) <= 0.0:
			errors.append("art scale must contain two positive values: " + placement_id)
			continue
		var size := Vector2(float(asset.frame_size[0]), float(asset.frame_size[1]))
		var scale := Vector2(float(scale_value[0]), float(scale_value[1]))
		var rect := Rect2(Vector2(anchor.x * TILE_SIZE, anchor.y * TILE_SIZE) - Vector2(size.x * scale.x * 0.5, size.y * scale.y), size * scale)
		if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > grid.x * TILE_SIZE or rect.end.y > grid.y * TILE_SIZE:
			errors.append("art image bounds clip the room edge: " + placement_id)
		art_bounds.append({"placement_id": placement_id, "asset_id": asset_id, "rect": rect})
		var alpha_rect := _alpha_bounds(String(asset.path), Vector2i(int(size.x), int(size.y)))
		if alpha_rect.size != Vector2.ZERO:
			var alpha_world := Rect2(
				rect.position + Vector2(alpha_rect.position.x * scale.x, alpha_rect.position.y * scale.y),
				Vector2(alpha_rect.size.x * scale.x, alpha_rect.size.y * scale.y)
			)
			var covered := _covered_cells(alpha_world, grid)
			checks.append({"check": "art_alpha_cell_coverage", "placement_id": placement_id, "cells": covered})
		for existing in art_bounds:
			if String(existing.placement_id) == placement_id:
				continue
			if rect.intersects(existing.rect):
				warnings.append("art image bounds overlap: %s / %s" % [placement_id, existing.placement_id])
	var shapes: Array[Dictionary] = []
	var shape_ids := {}
	for shape_variant in source.get("collision_shapes", []):
		if not shape_variant is Dictionary:
			errors.append("collision shape is not an object")
			continue
		var shape := shape_variant as Dictionary
		var shape_id := String(shape.get("id", ""))
		if shape_id.is_empty() or shape_ids.has(shape_id):
			errors.append("collision shape IDs must be non-empty and unique: " + shape_id)
		shape_ids[shape_id] = true
		if String(shape.get("kind", "")) != "rect":
			errors.append("unsupported collision shape kind: " + shape_id)
			continue
		var cells := shape.get("rect", []) as Array
		if cells.size() != 4:
			errors.append("collision rect must be [x,y,width,height]: " + shape_id)
			continue
		var x := int(cells[0]); var y := int(cells[1]); var width := int(cells[2]); var height := int(cells[3])
		if width <= 0 or height <= 0 or x < 0 or y < 0 or x + width > grid.x or y + height > grid.y:
			errors.append("collision rect outside room bounds or empty: " + shape_id)
			continue
		var rect := Rect2(Vector2(x, y) * TILE_SIZE, Vector2(width, height) * TILE_SIZE)
		for existing in shapes:
			if rect.intersects(existing.rect):
				errors.append("collision rectangles overlap: %s / %s" % [shape_id, existing.id])
		shapes.append({"id": shape_id, "rect": rect})
	var portal: Array[Vector2i] = []
	for portal_variant in source.get("portal_cells", []):
		portal.append(_cell(portal_variant))
	portal.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x if a.y == b.y else a.y < b.y)
	if portal.size() != 3:
		errors.append("portal must contain exactly three cells")
	elif portal[0].y != grid.y - 1 or portal[1].y != grid.y - 1 or portal[2].y != grid.y - 1 or portal[1].x != portal[0].x + 1 or portal[2].x != portal[1].x + 1:
		errors.append("portal must be three contiguous cells in the south wall")
	else:
		for cell in portal:
			if cell.x <= 0 or cell.x >= grid.x - 1:
				errors.append("portal cannot remove a corner support")
			for shape in shapes:
				if shape.rect.intersects(Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)):
					errors.append("portal cell is still blocked by collision: %s" % str(cell))
			if operator_shape != null and _capsule_overlaps_any(operator_shape, shape_offset, operator_scale, Vector2(cell) * TILE_SIZE + Vector2.ONE * TILE_SIZE * 0.5, shapes):
				errors.append("actual Operator capsule cannot clear portal cell: %s" % str(cell))
			else:
				checks.append({"check": "operator_portal_clearance", "cell": [cell.x, cell.y], "clear": true})
	var storage_defaults := _storage_defaults(room_id)
	var storage_seen := {}
	for storage_variant in source.get("storage_anchors", []):
		if not storage_variant is Dictionary:
			errors.append("storage anchor is not an object")
			continue
		var storage := storage_variant as Dictionary
		var storage_id := String(storage.get("storage_id", ""))
		if storage_seen.has(storage_id):
			errors.append("duplicate storage resource ID: " + storage_id)
		storage_seen[storage_id] = true
		if not storage_defaults.has(storage_id) or storage.get("resources") != storage_defaults.get(storage_id, {}).get("resources"):
			errors.append("storage identity or starting resource contents changed: " + storage_id)
		var art_id := String(storage.get("art_placement_id", ""))
		var anchor_value := storage.get("anchor_cell", []) as Array
		if art_id.is_empty() and anchor_value.is_empty():
			warnings.append("storage anchor awaits user placement: " + storage_id)
			continue
		if not placement_by_id.has(art_id):
			errors.append("storage anchor must reference exactly one named art placement: " + storage_id)
			continue
		var art_anchor := _cell(placement_by_id[art_id].get("anchor_cell", []))
		if _cell(anchor_value) != art_anchor:
			errors.append("storage anchor does not match its named art placement: " + storage_id)
	for storage_id_variant in storage_defaults.keys():
		if not storage_seen.has(String(storage_id_variant)):
			errors.append("required existing storage ID missing: " + String(storage_id_variant))
	for waypoint_variant in source.get("waypoints", []):
		if not waypoint_variant is Dictionary:
			errors.append("waypoint is not an object")
			continue
		var waypoint := waypoint_variant as Dictionary
		var waypoint_id := String(waypoint.get("id", ""))
		var cell := _cell(waypoint.get("cell", []))
		if waypoint_id.is_empty() or cell.x <= 0 or cell.y <= 0 or cell.x >= grid.x - 1 or cell.y >= grid.y - 1:
			errors.append("waypoint name/cell is invalid: " + waypoint_id)
		elif operator_shape == null or _capsule_overlaps_any(operator_shape, shape_offset, operator_scale, Vector2(cell) * TILE_SIZE + Vector2.ONE * TILE_SIZE * 0.5, shapes):
			errors.append("actual Operator capsule is blocked at waypoint: " + waypoint_id)
		else:
			checks.append({"check": "operator_waypoint_clearance", "id": waypoint_id, "cell": [cell.x, cell.y], "clear": true})
	var camera_regions := _camera_regions()
	for first in range(camera_regions.size()):
		for second in range(first + 1, camera_regions.size()):
			if camera_regions[first].rect.intersects(camera_regions[second].rect):
				errors.append("proposed off-map camera regions overlap: %s / %s" % [camera_regions[first].room_id, camera_regions[second].room_id])
	checks.append({"check": "camera_regions_disjoint", "regions": _camera_regions_json(camera_regions), "clear": errors.filter(func(message: String) -> bool: return message.begins_with("proposed off-map camera regions overlap")).is_empty()})
	return _report(errors, warnings, checks)


static func camera_regions() -> Array[Dictionary]:
	return _camera_regions_json(_camera_regions())


static func _camera_regions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for room_id in ROOM_IDS:
		var config := room_config(room_id)
		var size: Vector2i = config.grid_wh
		var origin: Vector2i = config.offmap_origin_cell
		result.append({"room_id": room_id, "rect": Rect2(origin, size)})
	return result


static func _camera_regions_json(regions: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in regions:
		var rect: Rect2 = value.rect
		result.append({"room_id": String(value.room_id), "cells": [int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y)]})
	return result


static func _capsule_overlaps_any(shape: CapsuleShape2D, local_offset: Vector2, scale: Vector2, center: Vector2, rects: Array[Dictionary]) -> bool:
	var radius := shape.radius * maxf(scale.x, scale.y)
	var half_segment := maxf(0.0, shape.height * scale.y * 0.5 - shape.radius * scale.y)
	var capsule_center := center + local_offset * scale
	var a := capsule_center + Vector2.UP * half_segment
	var b := capsule_center + Vector2.DOWN * half_segment
	for value in rects:
		if _segment_rect_distance_squared(a, b, value.rect) <= radius * radius:
			return true
	return false


static func _segment_rect_distance_squared(a: Vector2, b: Vector2, rect: Rect2) -> float:
	if rect.has_point(a) or rect.has_point(b) or _segment_intersects_rect(a, b, rect):
		return 0.0
	var best := minf(_point_rect_distance_squared(a, rect), _point_rect_distance_squared(b, rect))
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for corner in corners:
		best = minf(best, _point_segment_distance_squared(corner, a, b))
	return best


static func _segment_intersects_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var delta := b - a
	var t_min := 0.0
	var t_max := 1.0
	for axis in 2:
		var origin := a.x if axis == 0 else a.y
		var direction := delta.x if axis == 0 else delta.y
		var low := rect.position.x if axis == 0 else rect.position.y
		var high := rect.end.x if axis == 0 else rect.end.y
		if is_zero_approx(direction):
			if origin < low or origin > high:
				return false
		else:
			var first := (low - origin) / direction
			var second := (high - origin) / direction
			if first > second:
				var swap := first; first = second; second = swap
			t_min = maxf(t_min, first)
			t_max = minf(t_max, second)
			if t_min > t_max:
				return false
	return true


static func _point_rect_distance_squared(point: Vector2, rect: Rect2) -> float:
	var closest := Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
	return point.distance_squared_to(closest)


static func _point_segment_distance_squared(point: Vector2, a: Vector2, b: Vector2) -> float:
	var delta := b - a
	var denominator := delta.length_squared()
	if denominator <= 0.000001:
		return point.distance_squared_to(a)
	var factor := clampf((point - a).dot(delta) / denominator, 0.0, 1.0)
	return point.distance_squared_to(a + delta * factor)


static func _covered_cells(rect: Rect2, grid: Vector2i) -> Array:
	var result: Array = []
	for y in range(maxi(0, floori(rect.position.y / TILE_SIZE)), mini(grid.y, ceili(rect.end.y / TILE_SIZE))):
		for x in range(maxi(0, floori(rect.position.x / TILE_SIZE)), mini(grid.x, ceili(rect.end.x / TILE_SIZE))):
			var tile_rect := Rect2(Vector2(x, y) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			if rect.intersects(tile_rect):
				result.append([x, y])
	return result


static func _alpha_bounds(path: String, frame_size: Vector2i) -> Rect2:
	var texture := ResourceLoader.load(path, "Texture2D") as Texture2D
	if texture == null:
		return Rect2()
	var image := texture.get_image()
	if image == null:
		return Rect2()
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Rect2()
	var ratio := Vector2(frame_size) / Vector2(image.get_size())
	return Rect2(Vector2(used.position) * ratio, Vector2(used.size) * ratio)


static func _storage_defaults(room_id: String) -> Dictionary:
	var config := room_config(room_id)
	var result := {}
	for value: Dictionary in config.get("storage", []):
		result[String(value.storage_id)] = value
	return result


static func _asset_lookup() -> Dictionary:
	var result := {}
	for value in asset_records():
		result[String(value.asset_id)] = value
	return result


static func _read_catalog() -> Dictionary:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


static func _resource_sha256(path: String) -> String:
	var absolute := ProjectSettings.globalize_path(path)
	var bytes := FileAccess.get_file_as_bytes(absolute)
	return _sha256_bytes(bytes)


static func _sha256(text: String) -> String:
	return _sha256_bytes(text.to_utf8_buffer())


static func _sha256_bytes(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()


static func _sort_records(source: Dictionary, field: String, key: String) -> void:
	var records: Array = source.get(field, []).duplicate(true)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get(key, "")) < String(b.get(key, "")))
	source[field] = records


static func _sort_cells(source: Variant) -> Array:
	var cells: Array = (source as Array).duplicate(true) if source is Array else []
	cells.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ca := _cell(a); var cb := _cell(b)
		return ca.y < cb.y if ca.y != cb.y else ca.x < cb.x
	)
	var normalized: Array = []
	for value in cells:
		var cell := _cell(value)
		normalized.append([cell.x, cell.y])
	return normalized


static func _int_pair(value: Variant) -> Array:
	if value is Array and (value as Array).size() == 2:
		return [int((value as Array)[0]), int((value as Array)[1])]
	return []


static func _cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and (value as Array).size() == 2:
		return Vector2i(int((value as Array)[0]), int((value as Array)[1]))
	return Vector2i(-1, -1)


static func _cell_in_bounds(cell: Vector2i, grid: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid.x and cell.y < grid.y


static func _report(errors: Array[String], warnings: Array[String], checks: Array[Dictionary]) -> Dictionary:
	return {"schema": "custodian.carrow_layout_validation.v1", "passed": errors.is_empty(), "status": "PASS" if errors.is_empty() else "BLOCKED", "errors": errors, "warnings": warnings, "checks": checks}
