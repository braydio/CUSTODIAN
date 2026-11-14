extends SceneTree

const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const FactionSitePlacerScript := preload("res://game/world/procgen/factions/faction_site_placer.gd")
const StoryRoomPlacerScript := preload("res://game/world/procgen/story/story_room_placer.gd")
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
