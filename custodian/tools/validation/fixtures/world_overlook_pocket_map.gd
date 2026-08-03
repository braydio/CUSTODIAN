extends Node2D

## Minimal procgen-map stand-in for validation fixtures.
##
## The production ProcGenMap exposes `claim_world_overlook_pocket`, which the
## WorldIngressSpawner uses to author a compact walkable pocket for a
## `north_edge_overlook` ingress. This stub mirrors that single API surface
## (no terrain methods, so placement resolvers fall back to `floor_cells`
## from the fixture level data) and records the request so smokes can assert
## that the authored-pocket placement path actually ran.

var authored_pocket_count: int = 0
var last_pocket_center_tile: Vector2i = Vector2i.ZERO
var last_pocket_size_tiles: Vector2i = Vector2i.ZERO


func claim_world_overlook_pocket(
	center_tile: Vector2i,
	size_tiles: Vector2i
) -> Rect2i:
	if size_tiles.x <= 0 or size_tiles.y <= 0:
		return Rect2i()
	authored_pocket_count += 1
	last_pocket_center_tile = center_tile
	last_pocket_size_tiles = size_tiles
	return Rect2i(
		center_tile - Vector2i(size_tiles.x / 2, 0),
		size_tiles
	)
