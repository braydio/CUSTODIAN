extends SceneTree

const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const FactionSitePlacerScript := preload("res://game/world/procgen/factions/faction_site_placer.gd")
const StoryRoomPlacerScript := preload("res://game/world/procgen/story/story_room_placer.gd")
const StoryRoomGeometryStamperScript := preload("res://game/world/procgen/story/story_room_geometry_stamper.gd")
const IntentGraphScript := preload("res://game/world/procgen/intent/worldgen_intent_graph.gd")
const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")
const IntentEdgeScript := preload("res://game/world/procgen/intent/worldgen_intent_edge.gd")
const AmbientActivityAnchorScript := preload("res://game/actors/enemies/ambient/ambient_activity_anchor.gd")


func _init() -> void:
	var profile = WorldProgressProfileScript.load_from_path("res://content/procgen/world_profiles/sundered_keep_ascent.json")
	var floor_cells: Array[Vector2i] = []
	for x in range(0, 320):
		for y in range(0, 32):
			floor_cells.append(Vector2i(x, y))
	var faction_context := {
		"seed": 444,
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"required_cells": [Vector2i.ZERO],
		"count": 12,
		"world_progress_profile": profile,
	}
	var sites: Array = FactionSitePlacerScript.new().place_sites(faction_context)
	var repeated_sites: Array = FactionSitePlacerScript.new().place_sites(faction_context)
	assert(sites.size() > 0)
	assert(sites == repeated_sites)
	assert((sites[0] as Dictionary).has("activity_id"))
	var rooms: Array = StoryRoomPlacerScript.new().place_story_rooms({
		"seed": 777,
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"required_cells": [Vector2i.ZERO],
		"count": 6,
		"world_progress_profile": profile,
		"faction_sites": sites,
	})
	assert(rooms.size() > 0)
	assert((rooms[0] as Dictionary).has("story_id"))

	var story_regions := [
		_story_region("story_b", Rect2i(30, 30, 9, 9), Vector2i(34, 34)),
		_story_region("story_a", Rect2i(10, 10, 9, 9), Vector2i(14, 14)),
	]
	var story_context := {
		"seed": 777,
		"identity_seed": 9001,
		"region_identity": "alpine_plateau/test-region",
		"map_size": Vector2i(64, 64),
		"worldgen_intent_enabled": true,
		"world_progress_profile": profile,
		"reserved_regions": story_regions,
		"intent_graph": _story_graph_for(story_regions),
	}
	var placer := StoryRoomPlacerScript.new()
	var projection: Dictionary = placer.project_story_rooms(story_context)
	var repeated: Dictionary = placer.project_story_rooms(story_context)
	var shuffled_context := story_context.duplicate(true)
	shuffled_context.reserved_regions.reverse()
	var shuffled: Dictionary = placer.project_story_rooms(shuffled_context)
	var intent_sites: Array = projection.get("sites", [])
	assert(intent_sites.size() == 2)
	assert(intent_sites == repeated.get("sites", []))
	assert(intent_sites == shuffled.get("sites", []))
	assert(JSON.stringify(intent_sites) == JSON.stringify(repeated.get("sites", [])))
	assert(JSON.stringify(intent_sites) == JSON.stringify(shuffled.get("sites", [])))
	assert(projection.get("skipped", []) == repeated.get("skipped", []))
	assert(JSON.stringify(projection.get("skipped", [])) == JSON.stringify(shuffled.get("skipped", [])))
	var site_ids: Dictionary = {}
	for site: Dictionary in intent_sites:
		assert(site.get("schema_version") == 1)
		assert(site.get("scope_kind") == "f02_generated_region")
		assert(not site.has("f15_location"))
		assert(site.get("intent_node_id", "") != "")
		assert(site.get("rect") is Rect2i)
		var node_id := String(site.intent_node_id)
		var source_region := _find_story_region(story_context.reserved_regions, node_id)
		assert(source_region.get("rect") == site.rect)
		assert(source_region.get("center") == site.cell)
		assert(not site_ids.has(site.site_id))
		site_ids[site.site_id] = true
	assert(String(intent_sites[0].intent_node_id) == "story_a")
	assert(String(intent_sites[0].site_id) != String(intent_sites[1].site_id))
	assert(StoryRoomGeometryStamperScript.new().validate_story_site_bindings(
		intent_sites, story_context.reserved_regions
	).is_empty())
	var mismatched_site_rects := intent_sites.duplicate(true)
	mismatched_site_rects[0].rect = Rect2i(0, 0, 1, 1)
	var binding_errors: Array[String] = StoryRoomGeometryStamperScript.new().validate_story_site_bindings(
		mismatched_site_rects, story_context.reserved_regions
	)
	assert(binding_errors.has("story_a:rect_mismatch"))
	var blocked_context := story_context.duplicate(true)
	blocked_context.blocked_cells = [Vector2i(14, 14)]
	var blocked_result: Dictionary = placer.project_story_rooms(blocked_context)
	assert(blocked_result.sites.size() == 1)
	assert(blocked_result.skipped.size() == 1)
	assert(blocked_result.skipped[0].intent_node_id == "story_a")
	assert(blocked_result.skipped[0].reason == "blocked_anchor")
	var clipped_context := story_context.duplicate(true)
	clipped_context.reserved_regions = [_story_region("clipped", Rect2i(0, 0, 4, 9), Vector2i(0, 4))]
	var clipped_result: Dictionary = placer.project_story_rooms(clipped_context)
	assert(clipped_result.sites.is_empty())
	assert(clipped_result.skipped[0].reason == "clipped_rect")
	var overlap_context := story_context.duplicate(true)
	overlap_context.reserved_regions = [
		_story_region("story_a", Rect2i(10, 10, 9, 9), Vector2i(14, 14)),
		_story_region("story_overlap", Rect2i(15, 15, 9, 9), Vector2i(19, 19)),
	]
	overlap_context.intent_graph = _story_graph_for(overlap_context.reserved_regions)
	var overlap_result: Dictionary = placer.project_story_rooms(overlap_context)
	var overlap_shuffled_context := overlap_context.duplicate(true)
	overlap_shuffled_context.reserved_regions.reverse()
	var overlap_shuffled: Dictionary = placer.project_story_rooms(overlap_shuffled_context)
	assert(overlap_result.sites.size() == 1)
	assert(overlap_result.skipped[0].intent_node_id == "story_overlap")
	assert(overlap_result.skipped[0].reason == "overlapping_story_rect")
	assert(JSON.stringify(overlap_result) == JSON.stringify(overlap_shuffled))
	var protected_context := story_context.duplicate(true)
	protected_context.required_cells = [Vector2i(13, 13)]
	var protected_result: Dictionary = placer.project_story_rooms(protected_context)
	assert(protected_result.sites.size() == 1)
	assert(protected_result.skipped[0].reason == "protected_rect_overlap")
	var collision_context := story_context.duplicate(true)
	collision_context.collision_cells = [Vector2i(13, 13)]
	var collision_result: Dictionary = placer.project_story_rooms(collision_context)
	assert(collision_result.sites.size() == 1)
	assert(collision_result.skipped[0].reason == "collision_rect_overlap")
	var void_context := story_context.duplicate(true)
	void_context.void_cells = [Vector2i(13, 13)]
	var void_result: Dictionary = placer.project_story_rooms(void_context)
	assert(void_result.sites.size() == 1)
	assert(void_result.skipped[0].reason == "void_rect_overlap")
	var approach_context := story_context.duplicate(true)
	approach_context.intent_graph = _story_graph_for(approach_context.reserved_regions)
	approach_context.intent_graph.edges.clear()
	var approach_result: Dictionary = placer.project_story_rooms(approach_context)
	assert(approach_result.sites.is_empty())
	assert(approach_result.skipped[0].reason == "missing_story_approach")
	var invalid_context := story_context.duplicate(true)
	invalid_context.reserved_regions = [_story_region("outside", Rect2i(60, 60, 9, 9), Vector2i(64, 64))]
	var invalid_result: Dictionary = placer.project_story_rooms(invalid_context)
	var invalid_repeated: Dictionary = placer.project_story_rooms(invalid_context)
	assert(invalid_result.sites.is_empty())
	assert(invalid_result == invalid_repeated)
	assert(invalid_result.skipped[0].reason == "out_of_bounds_rect")
	var changed_seed_context := story_context.duplicate(true)
	changed_seed_context.identity_seed += 1
	var changed_seed: Dictionary = placer.project_story_rooms(changed_seed_context)
	assert(changed_seed.sites[0].site_id != intent_sites[0].site_id)
	var legacy_without_intent := story_context.duplicate(true)
	legacy_without_intent.erase("worldgen_intent_enabled")
	legacy_without_intent.erase("reserved_regions")
	legacy_without_intent.merge({
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"required_cells": [Vector2i.ZERO],
		"count": 6,
		"faction_sites": sites,
	}, true)
	assert(placer.place_story_rooms(legacy_without_intent).size() > 0)
	var anchor := AmbientActivityAnchorScript.new()
	var actor := Node.new()
	assert(anchor.claim(actor))
	assert(anchor.can_claim(actor))
	anchor.release(actor)
	var other_actor := Node.new()
	assert(anchor.can_claim(other_actor))
	other_actor.free()
	actor.free()
	anchor.free()
	print("faction_story_sites_smoke: PASS")
	quit()


func _story_region(node_id: String, rect: Rect2i, center: Vector2i) -> Dictionary:
	return {
		"id": node_id,
		"kind": "story_room",
		"rect": rect,
		"center": center,
		"radius_tiles": 4,
		"band_id": "upper_exhaustion",
		"style_id": "rocky_upland",
		"story_id": "",
		"required": false,
	}


func _story_graph_for(regions: Array) -> RefCounted:
	var graph := IntentGraphScript.new()
	var parent = IntentNodeScript.new()
	parent.id = "approach_parent"
	parent.kind = IntentNodeScript.NodeKind.ASCENT_BEAT
	parent.cell = Vector2i(20, 20)
	graph.add_node(parent)
	for region: Dictionary in regions:
		var node = IntentNodeScript.new()
		node.id = String(region.get("id", ""))
		node.kind = IntentNodeScript.NodeKind.STORY_ROOM
		node.cell = region.get("center", Vector2i.ZERO)
		node.radius_tiles = int(region.get("radius_tiles", 0))
		graph.add_node(node)
		var edge = IntentEdgeScript.new()
		edge.id = "approach_parent_to_%s" % node.id
		edge.from_id = parent.id
		edge.to_id = node.id
		edge.kind = IntentEdgeScript.EdgeKind.STORY_APPROACH
		graph.add_edge(edge)
	return graph


func _find_story_region(regions: Array, node_id: String) -> Dictionary:
	for region: Dictionary in regions:
		if String(region.get("id", "")) == node_id:
			return region
	return {}
