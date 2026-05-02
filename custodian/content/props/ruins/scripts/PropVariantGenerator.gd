extends Node
class_name PropVariantGenerator

static func seed_from_world_cell(prop_id: StringName, cell: Vector2i, salt: int = 0) -> int:
	var seed_string := "%s:%d:%d:%d" % [
		str(prop_id),
		cell.x,
		cell.y,
		salt
	]

	return hash(seed_string)


static func seed_from_position(prop_id: StringName, world_position: Vector2, salt: int = 0) -> int:
	var rounded := world_position.round()
	var seed_string := "%s:%d:%d:%d" % [
		str(prop_id),
		int(rounded.x),
		int(rounded.y),
		salt
	]

	return hash(seed_string)
