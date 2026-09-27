extends Resource
class_name DressingClusterChild

enum Kind { FOLIAGE_TREE, FOLIAGE_SHRUB }

@export var kind: Kind = Kind.FOLIAGE_SHRUB
@export var offset_cells: Vector2i = Vector2i.ZERO
@export var required: bool = true


func foliage_kind() -> StringName:
	return &"tree" if kind == Kind.FOLIAGE_TREE else &"shrub"
