extends RefCounted
class_name ProcgenMacroPresentationComposer

const REGION_EXTRACTOR_SCRIPT := preload("res://game/world/procgen/presentation/terrain_region_extractor.gd")
const STAMP_PLACER_SCRIPT := preload("res://game/world/procgen/presentation/terrain_stamp_placer.gd")


func build_plan(context: Dictionary, catalog: Resource) -> Dictionary:
	var regions: Array[Dictionary] = REGION_EXTRACTOR_SCRIPT.new().extract(context)
	return STAMP_PLACER_SCRIPT.new().build_plan(
		int(context.get("seed", 0)), regions, catalog as TerrainStampCatalog,
		context, int(context.get("max_stamps", 12))
	)


func apply_plan(
	plan: Dictionary,
	catalog: Resource,
	roots: Dictionary,
	floor_tilemap: TileMapLayer,
	walls_tilemap: TileMapLayer,
	presentation_world_scale: Vector2
) -> Dictionary:
	clear(roots)
	var created := 0
	var by_stamp: Dictionary = {}
	var safe_scale := Vector2(maxf(absf(presentation_world_scale.x), 0.001), maxf(absf(presentation_world_scale.y), 0.001))
	var tile_size := Vector2(32.0, 32.0)
	if floor_tilemap != null and floor_tilemap.tile_set != null:
		tile_size = Vector2(floor_tilemap.tile_set.tile_size)
	for placement: Dictionary in plan.get("placements", []):
		var profile := (catalog as TerrainStampCatalog).get_profile(StringName(placement.get("stamp_id", &""))) if catalog != null else null
		if profile == null or profile.texture == null:
			continue
		var root := _root_for_band(roots, int(placement.get("depth_band", 0)))
		if root == null:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "MacroStamp_%04d_%s" % [created, String(profile.stamp_id)]
		sprite.texture = profile.texture
		sprite.centered = false
		sprite.offset = -profile.pivot_px
		sprite.position = Vector2(placement.get("anchor_cell", Vector2i.ZERO)) * tile_size
		sprite.scale = Vector2.ONE / safe_scale
		sprite.flip_h = bool(placement.get("flip_h", false))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.visible = not bool(plan.get("streaming_enabled", false))
		sprite.set_meta("macro_stamp_id", profile.stamp_id)
		sprite.set_meta("macro_region_id", placement.get("region_id", ""))
		sprite.set_meta("macro_reveal_probe_cells", placement.get("reveal_probe_cells", []).duplicate())
		root.add_child(sprite)
		by_stamp[String(profile.stamp_id)] = sprite
		created += 1
	return {"sprite_count": created, "sprites_by_stamp": by_stamp}


func clear(roots: Dictionary) -> void:
	for root: Node2D in roots.values():
		if root == null:
			continue
		for child: Node in root.get_children():
			root.remove_child(child)
			child.queue_free()


func refresh_streaming_visibility(plan: Dictionary, roots: Dictionary, floor_tilemap: TileMapLayer, walls_tilemap: TileMapLayer) -> void:
	var streaming := bool(plan.get("streaming_enabled", false))
	for root: Node2D in roots.values():
		if root == null:
			continue
		for child: Node in root.get_children():
			if not child is Sprite2D or not child.has_meta("macro_reveal_probe_cells"):
				continue
			var visible_now := true
			if streaming:
				for cell: Vector2i in child.get_meta("macro_reveal_probe_cells", []):
					if not _cell_is_painted(cell, floor_tilemap, walls_tilemap):
						visible_now = false
						break
			child.visible = visible_now


func plan_fingerprint(plan: Dictionary) -> String:
	return STAMP_PLACER_SCRIPT.new().plan_fingerprint(plan)


func _root_for_band(roots: Dictionary, band: int) -> Node2D:
	match band:
		TerrainStampProfile.DepthBand.GROUND: return roots.get("ground") as Node2D
		TerrainStampProfile.DepthBand.FRONT: return roots.get("front") as Node2D
		_: return roots.get("back") as Node2D


func _cell_is_painted(cell: Vector2i, floor_tilemap: TileMapLayer, walls_tilemap: TileMapLayer) -> bool:
	return (floor_tilemap != null and floor_tilemap.get_cell_source_id(cell) >= 0) or (walls_tilemap != null and walls_tilemap.get_cell_source_id(cell) >= 0)

