extends Resource
class_name PropSpawnSet

@export var entries: Array[WeightedPropEntry] = []


func get_total_weight() -> float:
	var total := 0.0
	for entry in entries:
		if entry != null and entry.definition != null and entry.weight > 0.0:
			total += entry.weight
	return total


func pick_weighted(rng: RandomNumberGenerator) -> PropDefinition:
	var total := get_total_weight()
	if total <= 0.0:
		return null

	var roll := rng.randf_range(0.0, total)
	var cursor := 0.0
	for entry in entries:
		if entry == null or entry.definition == null or entry.weight <= 0.0:
			continue
		cursor += entry.weight
		if roll <= cursor:
			return entry.definition

	return null
