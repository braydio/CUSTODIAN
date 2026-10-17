extends RefCounted
class_name ProcgenExhibitCatalog

const MANIFEST_PATH := "res://content/data/dev/procgen_showcase/exhibits.v1.json"
const WINGS: Array[String] = ["terrain", "topology", "sites", "population", "presentation"]
const BIOME_SCRIPT := preload("res://game/world/procgen/biomes/biome_profile.gd")
const REGION_SCRIPT := preload("res://game/world/procgen/terrain/terrain_region.gd")
const STAMP_SCRIPT := preload("res://game/world/procgen/presentation/terrain_stamp_profile.gd")
const STAMP_CATALOG_SCRIPT := preload("res://game/world/procgen/presentation/terrain_stamp_catalog.gd")
const STAMP_CATALOG := preload("res://content/procgen/presentation/terrain_stamp_catalog_v1.tres")


static func load_report(manifest_path: String = MANIFEST_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		return {"valid": [], "failures": ["manifest root is not a JSON object"]}
	return validate_manifest(parsed)


static func validate_manifest(manifest: Dictionary) -> Dictionary:
	var failures: Array[String] = []
	var exhibits: Array = manifest.get("exhibits", [])
	var seen_ids: Dictionary = {}
	var counts: Dictionary = {}
	var resolved: Array[Dictionary] = []
	if manifest.get("schema") != "custodian.procgen_showcase_exhibits.v1":
		failures.append("invalid exhibit manifest schema")
	if manifest.get("wings") != WINGS:
		failures.append("manifest wing list must match the five gallery wings")
	for raw: Variant in exhibits:
		if not raw is Dictionary:
			failures.append("exhibit entry is not an object")
			continue
		var entry: Dictionary = raw.duplicate(true)
		var exhibit_id := String(entry.get("exhibit_id", ""))
		var wing := String(entry.get("wing", ""))
		if exhibit_id.is_empty() or seen_ids.has(exhibit_id):
			failures.append("missing or duplicate exhibit_id: %s" % exhibit_id)
		seen_ids[exhibit_id] = true
		if not WINGS.has(wing):
			failures.append("unknown wing for %s: %s" % [exhibit_id, wing])
			continue
		counts[wing] = int(counts.get(wing, 0)) + 1
		if String(entry.get("selector_capability", "")) not in ["inspect_only", "candidate_query"]:
			failures.append("invalid selector capability for %s" % exhibit_id)
		if entry.get("status") == "na":
			if String(entry.get("reason", "")).strip_edges().is_empty():
				failures.append("N/A exhibit needs a reason: %s" % exhibit_id)
			if not String(entry.get("preview_resource", "")).is_empty():
				failures.append("N/A exhibit cannot claim a preview: %s" % exhibit_id)
			resolved.append(entry)
			continue
		if entry.get("status") != "available":
			failures.append("invalid availability state for %s" % exhibit_id)
		var resource_path := String(entry.get("preview_resource", ""))
		if not resource_path.begins_with("res://") or not ResourceLoader.exists(resource_path):
			failures.append("missing runtime preview resource for %s" % exhibit_id)
			continue
		var resource := load(resource_path)
		if resource == null:
			failures.append("failed to load preview resource for %s" % exhibit_id)
			continue
		if wing == "terrain":
			if resource.get_script() != BIOME_SCRIPT or String(resource.biome_id) != String(entry.get("source_authority_id", "")):
				failures.append("terrain provenance does not resolve for %s" % exhibit_id)
			entry["readout"] = "Biome %s · foliage %.2f · trees %.2f" % [String(resource.biome_id), resource.foliage_density_ceiling, resource.tree_probability]
		elif wing == "topology":
			var kind_name := String(entry.get("source_authority_id", ""))
			var kind := _region_kind(kind_name)
			if resource != REGION_SCRIPT or kind < 0 or REGION_SCRIPT.kind_to_string(kind) != kind_name:
				failures.append("topology semantic does not resolve for %s" % exhibit_id)
			entry["readout"] = "TerrainRegion.RegionKind.%s" % kind_name.to_upper()
		elif wing == "sites":
			var expected_script := "FactionSitePlacer" if exhibit_id == "sites.faction_worksite" else "StoryRoomPlacer"
			if resource is Script and resource.get_global_name() == StringName(expected_script):
				var source_method := "place_sites" if expected_script == "FactionSitePlacer" else "place_story_rooms"
				var api_instance: Object = resource.new()
				if not api_instance.has_method(source_method) or entry.get("source_authority_id") != "%s.%s" % [expected_script, source_method]:
					failures.append("site API method does not resolve for %s" % exhibit_id)
			else:
				failures.append("site API reference does not resolve for %s" % exhibit_id)
		elif wing == "presentation":
			var profile: Variant = STAMP_CATALOG.get_profile(StringName(entry.get("source_authority_id", ""))) if STAMP_CATALOG.get_script() == STAMP_CATALOG_SCRIPT else null
			if profile == null or profile.resource_path != resource_path or profile.texture == null:
				failures.append("presentation stamp is not a registered runtime profile for %s" % exhibit_id)
			else:
				entry["texture"] = profile.texture
				entry["readout"] = "Stamp %s · %s · %s px" % [String(profile.stamp_id), String(profile.family_id), str(profile.canvas_px)]
		resolved.append(entry)
	for wing in WINGS:
		if int(counts.get(wing, 0)) == 0:
			failures.append("wing has no truthful catalog entry: %s" % wing)
		if wing in ["terrain", "topology", "sites", "presentation"] and int(counts.get(wing, 0)) < 2:
			failures.append("wing needs two canonical examples: %s" % wing)
	return {"valid": resolved if failures.is_empty() else [], "failures": failures}


static func _region_kind(kind_name: String) -> int:
	for value in range(REGION_SCRIPT.RegionKind.size()):
		if REGION_SCRIPT.kind_to_string(value) == kind_name:
			return value
	return -1
