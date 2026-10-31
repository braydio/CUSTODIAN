extends RefCounted
class_name StoryRoomGeometryStamper


func stamp_story_rooms(tilemap: Node, _story_rooms: Array, reserved_regions: Array) -> void:
	if tilemap == null:
		return
	if not tilemap.has_method("claim_procgen_floor_rect_for_authored_scene_tiles"):
		return
	var binding_errors := validate_story_site_bindings(_story_rooms, reserved_regions)
	assert(binding_errors.is_empty(), "story site/reservation identity mismatch: %s" % ", ".join(binding_errors))

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


## Floor claims remain owned by F02 reservations. Any projected site that is
## present must point back to the exact reservation, so metadata can never
## silently redirect the physical claim to another rectangle.
func validate_story_site_bindings(story_rooms: Array, reserved_regions: Array) -> Array[String]:
	var reservations_by_id: Dictionary = {}
	for region in reserved_regions:
		if not region is Dictionary or String(region.get("kind", "")) != "story_room":
			continue
		var node_id := String(region.get("id", ""))
		if not node_id.is_empty():
			reservations_by_id[node_id] = region
	var errors: Array[String] = []
	for site in story_rooms:
		if not site is Dictionary or not (site as Dictionary).has("intent_node_id"):
			continue
		var record: Dictionary = site
		var node_id := String(record.get("intent_node_id", ""))
		if not reservations_by_id.has(node_id):
			errors.append("%s:missing_reservation" % node_id)
			continue
		var reservation: Dictionary = reservations_by_id[node_id]
		if record.get("rect") != reservation.get("rect"):
			errors.append("%s:rect_mismatch" % node_id)
		if record.get("reserved_rect") != reservation.get("rect"):
			errors.append("%s:reserved_rect_mismatch" % node_id)
		if record.get("cell") != reservation.get("center"):
			errors.append("%s:center_mismatch" % node_id)
	return errors
