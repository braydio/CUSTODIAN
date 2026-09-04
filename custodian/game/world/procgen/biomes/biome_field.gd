extends RefCounted
class_name BiomeField

const TerrainBuilderScript := preload("res://game/world/procgen/terrain/terrain_builder.gd")
const BIOME_SCRUBLAND: StringName = &"scrubland"
const BIOME_WOODLAND: StringName = &"woodland"
const BIOME_WETLAND: StringName = &"wetland"
const BIOME_ROCKY_UPLAND: StringName = &"rocky_upland"
const BIOME_ORDER: Array[StringName] = [BIOME_SCRUBLAND, BIOME_WOODLAND, BIOME_WETLAND, BIOME_ROCKY_UPLAND]
const ROCK_TYPES := [5, 6, 7, 8]
const MOISTURE_FREQUENCY := 0.018
const EXPOSURE_FREQUENCY := 0.014
const SMOOTHING_PASSES := 2
const SMOOTHING_REQUIRED_NEIGHBORS := 5

func build(floor_cells: Dictionary, terrain_result: Dictionary, seed: int, world_profile: Dictionary) -> Dictionary:
	var result := {}
	if floor_cells.is_empty(): return {"biome_id_by_cell":result,"counts":{},"seed":seed}
	var moisture_noise := _make_noise(seed ^ 0x13579BDF, MOISTURE_FREQUENCY)
	var exposure_noise := _make_noise(seed ^ 0x2468ACE1, EXPOSURE_FREQUENCY)
	var moisture_bias := float(world_profile.get("biome_moisture_bias", 0.0))
	var exposure_bias := float(world_profile.get("biome_exposure_bias", 0.0))
	var types: Dictionary = terrain_result.get("terrain_type_by_cell", {})
	var heights: Dictionary = terrain_result.get("height_by_cell", {})
	for value in floor_cells:
		if not value is Vector2i: continue
		var cell := value as Vector2i
		var moisture := clampf(0.5 + moisture_noise.get_noise_2d(cell.x, cell.y) * 0.5 + moisture_bias, 0.0, 1.0)
		var exposure := clampf(0.5 + exposure_noise.get_noise_2d(cell.x, cell.y) * 0.5 + exposure_bias, 0.0, 1.0)
		result[cell] = _classify(int(types.get(cell, 0)), int(heights.get(cell, 0)), moisture, exposure)
	for _pass in SMOOTHING_PASSES: result = _smooth_once(result, floor_cells)
	return {"biome_id_by_cell":result,"counts":_count_biomes(result),"seed":seed,"moisture_bias":moisture_bias,"exposure_bias":exposure_bias}

func _make_noise(seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new(); noise.seed = seed; noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH; noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM; noise.fractal_octaves = 3; noise.fractal_gain = 0.52; noise.fractal_lacunarity = 2.0
	return noise

func _classify(terrain_type: int, height: int, moisture: float, exposure: float) -> StringName:
	if terrain_type in ROCK_TYPES or exposure >= 0.74: return BIOME_ROCKY_UPLAND
	if height <= 0 and moisture >= 0.68: return BIOME_WETLAND
	if moisture >= 0.42: return BIOME_WOODLAND
	return BIOME_SCRUBLAND

func _smooth_once(source: Dictionary, floor_cells: Dictionary) -> Dictionary:
	var result := source.duplicate()
	for value in source:
		if not value is Vector2i: continue
		var cell := value as Vector2i; var counts := {}
		for y in range(-1, 2):
			for x in range(-1, 2):
				if x == 0 and y == 0: continue
				var neighbor := cell + Vector2i(x, y)
				if floor_cells.has(neighbor):
					var biome: StringName = source.get(neighbor, BIOME_SCRUBLAND)
					counts[biome] = int(counts.get(biome, 0)) + 1
		var best: StringName = source.get(cell, BIOME_SCRUBLAND); var best_count := 0
		for biome in BIOME_ORDER:
			var count := int(counts.get(biome, 0))
			if count > best_count: best_count = count; best = biome
		if best_count >= SMOOTHING_REQUIRED_NEIGHBORS: result[cell] = best
	return result

func _count_biomes(source: Dictionary) -> Dictionary:
	var counts := {}
	for value in source.values():
		var biome := StringName(value); counts[biome] = int(counts.get(biome, 0)) + 1
	return counts
