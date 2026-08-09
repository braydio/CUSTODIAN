class_name SimulationCanonicalJson
extends RefCounted

const FLOAT_PRECISION := 6

static func normalize(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		var keys: Array = value.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
		for key in keys: result[String(key)] = normalize(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(normalize(item))
		return result
	if value is float:
		if not is_finite(value): return null
		var rounded := snappedf(value, pow(10.0, -FLOAT_PRECISION))
		return int(rounded) if is_equal_approx(rounded, roundf(rounded)) else rounded
	return value

static func encode(value: Variant) -> String:
	return JSON.stringify(normalize(value), "", false)

static func sha256(value: Variant) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(encode(value).to_utf8_buffer())
	return context.finish().hex_encode()
