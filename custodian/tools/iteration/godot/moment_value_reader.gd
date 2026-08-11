extends RefCounted
class_name MomentValueReader


static func dotted(value: Variant, path: String) -> Variant:
	var cursor: Variant = value
	if path.is_empty():
		return cursor
	for part: String in path.split("."):
		if not cursor is Dictionary or not (cursor as Dictionary).has(part):
			return null
		cursor = (cursor as Dictionary)[part]
	return cursor
