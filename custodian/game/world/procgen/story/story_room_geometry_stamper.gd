extends RefCounted
class_name StoryRoomGeometryStamper


func stamp_story_rooms(tilemap: Node, _story_rooms: Array, reserved_regions: Array) -> void:
	if tilemap == null:
		return
	if not tilemap.has_method("claim_procgen_floor_rect_for_authored_scene_tiles"):
		return

	for region in reserved_regions:
		if not (region is Dictionary):
			continue
		if String(region.get("kind", "")) != "story_room":
			continue

		var center: Vector2i = region.get("center", Vector2i.ZERO)
		var rect: Rect2i = region.get("rect", Rect2i(center - Vector2i(5, 5), Vector2i(11, 11)))
		tilemap.call(
			"claim_procgen_floor_rect_for_authored_scene_tiles",
			center,
			rect.size,
			"story_room_floor",
			"story_room",
			1
		)
