extends Resource
class_name LocalTransitStation2D

## Stable local-travel endpoint. Positions are in the lift owner's local space.
@export var station_id: StringName
@export var arrival_position := Vector2.ZERO
@export_range(1.0, 256.0, 1.0) var interaction_radius := 48.0


func _init(id: StringName = &"", position: Vector2 = Vector2.ZERO, radius: float = 48.0) -> void:
	station_id = id
	arrival_position = position
	interaction_radius = radius
