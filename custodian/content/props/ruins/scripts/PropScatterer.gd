extends Node2D
class_name PropScatterer

const PROCEDURAL_PROP_SCENE := preload("res://content/props/ruins/scenes/ProceduralProp.tscn")

@export var prop_scene: PackedScene = PROCEDURAL_PROP_SCENE
@export var spawn_set: PropSpawnSet
@export var count: int = 12
@export var min_distance_tiles: int = 4
@export var seed: int = 12345
@export var variant_intensity: ProceduralProp.VariantIntensity = ProceduralProp.VariantIntensity.SUBTLE
@export var force_collision_debug: bool = false

var _rng := RandomNumberGenerator.new()


func scatter_on_tiles(tiles: Array[Vector2i], tile_to_position: Callable, blocked_tiles: Dictionary = {}) -> Array[ProceduralProp]:
	clear_spawned()

	var spawned: Array[ProceduralProp] = []
	if prop_scene == null or spawn_set == null or tiles.is_empty() or count <= 0:
		return spawned

	_rng.seed = seed
	var candidates := tiles.duplicate()
	candidates.shuffle()

	var placed_tiles: Array[Vector2i] = []
	var spawn_counts: Dictionary = {}
	var target_count := _resolve_target_count()

	for tile in candidates:
		if spawned.size() >= target_count:
			break
		if blocked_tiles.has(tile):
			continue
		if not _is_far_enough(tile, placed_tiles):
			continue

		var definition := _pick_definition_with_counts(spawn_counts)
		if definition == null:
			continue

		var prop := prop_scene.instantiate() as ProceduralProp
		if prop == null:
			continue

		prop.definition = definition
		prop.variant_intensity = variant_intensity
		prop.variant_seed = PropVariantGenerator.seed_from_world_cell(definition.id, tile, seed)
		prop.generate_on_ready = false
		prop.force_collision_debug = force_collision_debug
		add_child(prop)
		prop.global_position = tile_to_position.call(tile)
		prop.set_meta("source_tile", tile)
		prop.generate_variant()

		placed_tiles.append(tile)
		var definition_id := str(definition.id)
		spawn_counts[definition_id] = int(spawn_counts.get(definition_id, 0)) + 1
		spawned.append(prop)

	return spawned


func clear_spawned() -> void:
	for child in get_children():
		child.queue_free()


func _resolve_target_count() -> int:
	var minimum_total := 0
	var maximum_total := 0
	for entry in spawn_set.entries:
		if entry == null or entry.definition == null or entry.weight <= 0.0:
			continue
		minimum_total += entry.min_count
		maximum_total += max(entry.min_count, entry.max_count)

	if maximum_total <= 0:
		return count

	return clamp(count, minimum_total, maximum_total)


func _is_far_enough(tile: Vector2i, placed_tiles: Array[Vector2i]) -> bool:
	for placed in placed_tiles:
		if tile.distance_to(placed) < float(min_distance_tiles):
			return false
	return true


func _pick_definition_with_counts(spawn_counts: Dictionary) -> PropDefinition:
	var total_weight := 0.0
	for entry in spawn_set.entries:
		if not _entry_can_spawn(entry, spawn_counts):
			continue
		total_weight += entry.weight

	if total_weight <= 0.0:
		return null

	var roll := _rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for entry in spawn_set.entries:
		if not _entry_can_spawn(entry, spawn_counts):
			continue
		cursor += entry.weight
		if roll <= cursor:
			return entry.definition

	return null


func _entry_can_spawn(entry: WeightedPropEntry, spawn_counts: Dictionary) -> bool:
	if entry == null or entry.definition == null or entry.weight <= 0.0:
		return false
	var limit: int = max(entry.min_count, entry.max_count)
	if limit <= 0:
		return true
	return int(spawn_counts.get(str(entry.definition.id), 0)) < limit
