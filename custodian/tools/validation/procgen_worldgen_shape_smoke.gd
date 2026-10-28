extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate()
	root.add_child(map)

	var tilemap = map as ProcGenTilemap
	assert(tilemap != null)

	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	if procgen == null:
		procgen = map.find_child("ProcGen", true, false) as ProcGen
	assert(procgen != null)

	procgen.generate_seed = false
	procgen.seed = 20260615
	procgen.map_size = Vector2i(160, 160)

	tilemap.world_shape_mode = ProcGenTilemap.WorldShapeMode.ASCENT_FIELD
	tilemap.worldgen_intent_enabled = true
	tilemap.world_progression_enabled = true
	tilemap.ascent_route_enabled = true
	tilemap.story_rooms_enabled = true
	tilemap.faction_ambient_sites_enabled = true
	tilemap.generate()

	for _i in range(120):
		await process_frame

	var data: Dictionary = tilemap.get_level_data()
	assert(String(data.get("world_shape_mode", "")) == "ascent_field")
	assert(bool(data.get("worldgen_intent_enabled", false)))
	assert(not (data.get("worldgen_intent_graph", {}) as Dictionary).is_empty())
	assert(not (data.get("ascent_field_summary", {}) as Dictionary).is_empty())
	assert((data.get("main_route_cells", []) as Array).size() > 0)
	assert((data.get("worldgen_reserved_regions", []) as Array).size() > 0)
	assert((data.get("world_progress_samples", {}) as Dictionary).size() > 0)
	var reserved_by_id := _story_reservations_by_id(data.get("worldgen_reserved_regions", []))
	var exported_sites: Array = data.get("story_room_sites", [])
	assert(exported_sites.is_empty())
	var site_ids: Dictionary = {}
	for site: Dictionary in exported_sites:
		var node_id := String(site.get("intent_node_id", ""))
		assert(not node_id.is_empty())
		assert(site.get("schema_version") == 1)
		assert(site.get("metadata_only_v1") == false)
		assert(reserved_by_id.has(node_id))
		var reservation: Dictionary = reserved_by_id[node_id]
		assert(site.get("reserved_rect") == reservation.get("rect"))
		assert(site.get("rect") == reservation.get("rect"))
		assert(site.get("cell") == reservation.get("center"))
		assert(not site_ids.has(site.get("site_id")))
		site_ids[site.get("site_id")] = true
	var exported_skips: Array = data.get("story_room_site_skips", [])
	assert(exported_skips.size() == 1)
	assert(String(exported_skips[0].get("intent_node_id", "")) == "story_room_required_11")
	assert(String(exported_skips[0].get("reason", "")) == "clipped_rect")
	for skipped: Dictionary in exported_skips:
		assert(not String(skipped.get("reason", "")).is_empty())
	var marker_parent := tilemap.get_node_or_null("WorldProgressMarkers")
	assert(marker_parent != null)
	for marker in marker_parent.get_children():
		assert(not String(marker.name).begins_with("StoryRoom_"))
	var repeated_data: Dictionary = tilemap.get_level_data()
	assert(exported_sites == repeated_data.get("story_room_sites", []))
	assert(exported_skips == repeated_data.get("story_room_site_skips", []))
	(exported_skips[0] as Dictionary)["reason"] = "caller_mutation"
	var detached_data: Dictionary = tilemap.get_level_data()
	assert(String(detached_data.story_room_site_skips[0].reason) == "clipped_rect")

	print("procgen_worldgen_shape_smoke: PASS")
	quit(0)


func _story_reservations_by_id(regions: Array) -> Dictionary:
	var result := {}
	for raw_region in regions:
		if not raw_region is Dictionary:
			continue
		var region: Dictionary = raw_region
		if String(region.get("kind", "")) == "story_room":
			result[String(region.get("id", ""))] = region
	return result
