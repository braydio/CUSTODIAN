class_name MapperCollisionModel
extends RefCounted

## Authoring-only collision representation. Runtime levels continue to expose
## their existing flat segment arrays.
static func compile_polylines(polylines: Array, include_active: Array = []) -> Array:
	var result: Array = []
	var all := polylines.duplicate(true)
	if include_active.size() >= 2:
		all.append(include_active.duplicate())
	for value: Variant in all:
		if not value is Array:
			continue
		var points := value as Array
		for index in range(points.size() - 1):
			var a := points[index] as Vector2
			var b := points[index + 1] as Vector2
			if a == null or b == null or a.is_equal_approx(b):
				continue
			result.append([a, b])
	return result

static func reconstruct_polylines(segments: Array, epsilon := 0.001) -> Array:
	var unused: Array = []
	for value: Variant in segments:
		if not value is Array or (value as Array).size() < 2:
			continue
		var pair := value as Array
		var a := pair[0] as Vector2
		var b := pair[1] as Vector2
		if a == null or b == null or a.distance_squared_to(b) <= epsilon * epsilon:
			continue
		unused.append([a, b])
	var result: Array = []
	while not unused.is_empty():
		var seed := unused.pop_front() as Array
		var chain: Array = [seed[0], seed[1]]
		var extended := true
		while extended:
			extended = false
			for index in range(unused.size()):
				var candidate := unused[index] as Array
				if (candidate[0] as Vector2).is_equal_approx(chain[-1] as Vector2):
					chain.append(candidate[1]); unused.remove_at(index); extended = true; break
				if (candidate[1] as Vector2).is_equal_approx(chain[-1] as Vector2):
					chain.append(candidate[0]); unused.remove_at(index); extended = true; break
			if extended:
				continue
			for index in range(unused.size()):
				var candidate := unused[index] as Array
				if (candidate[1] as Vector2).is_equal_approx(chain[0] as Vector2):
					chain.push_front(candidate[0]); unused.remove_at(index); extended = true; break
				if (candidate[0] as Vector2).is_equal_approx(chain[0] as Vector2):
					chain.push_front(candidate[1]); unused.remove_at(index); extended = true; break
		result.append(chain)
	return result

