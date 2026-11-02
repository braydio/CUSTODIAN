extends RefCounted
class_name FactionActivitySite

var site_id: String = ""
var faction_id: String = "none"
var activity_id: String = "ambient"
var cell: Vector2i = Vector2i.ZERO
var radius_tiles: int = 4
var band_id: String = ""
var style_id: String = ""
var escalation_radius_tiles: int = 6
var noncombat_first: bool = true


func to_dictionary() -> Dictionary:
	return {
		"site_id": site_id,
		"faction_id": faction_id,
		"activity_id": activity_id,
		"cell": cell,
		"radius_tiles": radius_tiles,
		"band_id": band_id,
		"style_id": style_id,
		"escalation_radius_tiles": escalation_radius_tiles,
		"noncombat_first": noncombat_first,
	}
