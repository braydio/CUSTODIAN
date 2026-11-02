extends RefCounted
class_name FactionSiteGeometryStamper


func stamp_faction_sites(tilemap: Node, _faction_sites: Array, reserved_regions: Array) -> void:
	if tilemap == null:
		return
	if not tilemap.has_method("claim_procgen_floor_rect_for_authored_scene_tiles"):
		return

	for region in reserved_regions:
		if not (region is Dictionary):
			continue
		if String(region.get("kind", "")) != "faction_site":
			continue

		var center: Vector2i = region.get("center", Vector2i.ZERO)
		var rect: Rect2i = region.get("rect", Rect2i(center - Vector2i(4, 4), Vector2i(9, 9)))
		var faction_id := String(region.get("faction_id", "unknown"))
		tilemap.call(
			"claim_procgen_floor_rect_for_authored_scene_tiles",
			center,
			rect.size,
			"faction_site_floor",
			"faction_%s" % faction_id,
			1
		)
