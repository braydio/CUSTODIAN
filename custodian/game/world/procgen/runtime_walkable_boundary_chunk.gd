extends StaticBody2D
class_name ProcGenRuntimeWalkableBoundaryChunk

## Non-destructible collision authority derived from authoritative walkable floor.
## Visual wall/cliff tiles are deliberately not consulted.

var segment_count: int = 0


func setup() -> void:
	name = "RuntimeWalkableBoundary"
	add_to_group("runtime_walkable_boundary")
	set_meta("non_destructible_traversal_boundary", true)


func add_segment(center: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	collision.name = "BoundarySegment_%d" % segment_count
	collision.position = center
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	add_child(collision)
	segment_count += 1
