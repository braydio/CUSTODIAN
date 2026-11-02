class_name ProcGenVisualFrontier
extends RefCounted

## Archive Resolve (AR4) presentation frontier: decides which committed cells
## may BEGIN resolving. Presentation-only; it never reads or writes streaming
## lifecycle, collision, navigation, or gameplay state. A cell is eligible when
## it is (1) inside a hard, deterministically irregular distance cap around the
## Operator, (2) visible from the Operator across the opaque-tile occluder
## callable (bounded grid line-of-sight over the local window, rebuilt only when
## the Operator tile changes or on a slow revision tick, never per ready tile),
## and (3) inside the camera tile rect plus a margin when a camera exists.
##
## It keeps no per-tile event log; only aggregate counters.

const NO_CENTER := Vector2i(999999, 999999)

var radius_tiles: int = 11
var fringe_tiles: int = 2
var camera_margin_tiles: int = 2
## Slow revision tick (presentation seconds) that notices wall changes such as
## destroyed walls without hooking every wall-authority funnel.
var revision_interval_sec: float = 0.2

var eligible_count: int = 0
var ineligible_distance_count: int = 0
var ineligible_occlusion_count: int = 0
var ineligible_camera_count: int = 0
var mask_rebuild_count: int = 0
var mask_rebuild_usec: int = 0

var _center: Vector2i = NO_CENTER
var _visible: Dictionary = {}
var _opaque: Callable = Callable()
var _opaque_cells: Dictionary = {}
var _camera_rect: Rect2i = Rect2i()
var _last_rebuild_time: float = -1000.0


func reset() -> void:
	_center = NO_CENTER
	_visible.clear()
	_opaque_cells.clear()
	_camera_rect = Rect2i()
	_last_rebuild_time = -1000.0
	eligible_count = 0
	ineligible_distance_count = 0
	ineligible_occlusion_count = 0
	ineligible_camera_count = 0
	mask_rebuild_count = 0
	mask_rebuild_usec = 0


func set_occluder(opaque: Callable) -> void:
	_opaque = opaque
	_last_rebuild_time = -1000.0


## Per-frame input. `camera_rect` is a tile rect (size zero = camera unknown).
## Returns true when the visibility mask was rebuilt this call.
func update(center: Vector2i, camera_rect: Rect2i, now: float) -> bool:
	_camera_rect = camera_rect
	if center == NO_CENTER:
		_center = NO_CENTER
		_visible.clear()
		return false
	if center == _center and now - _last_rebuild_time < revision_interval_sec:
		return false
	_center = center
	_last_rebuild_time = now
	_rebuild()
	return true


func has_center() -> bool:
	return _center != NO_CENTER


func center_tile() -> Vector2i:
	return _center


## Locally visible from the Operator (opaque tiles themselves are visible).
func is_visible_from_center(tile: Vector2i) -> bool:
	if _center == NO_CENTER:
		return true
	if tile == _center:
		return true
	return _visible.has(tile)


## Deterministic per-tile irregular distance limit, tiles.
func distance_limit(tile: Vector2i) -> float:
	var h: float = ProcGenRevealPresentation.cell_identity_hash(tile)
	return float(radius_tiles) + (h - 0.5) * 2.0 * float(fringe_tiles)


## Full ordinary-start eligibility. Counts the first failing reason.
func check(tile: Vector2i) -> bool:
	if _center == NO_CENTER:
		eligible_count += 1
		return true
	if Vector2(tile - _center).length() > distance_limit(tile):
		ineligible_distance_count += 1
		return false
	if _camera_rect.has_area() and not _camera_rect.has_point(tile):
		ineligible_camera_count += 1
		return false
	if not is_visible_from_center(tile):
		ineligible_occlusion_count += 1
		return false
	eligible_count += 1
	return true


func get_snapshot() -> Dictionary:
	return {
		"eligible": eligible_count,
		"ineligible_distance": ineligible_distance_count,
		"ineligible_occlusion": ineligible_occlusion_count,
		"ineligible_camera": ineligible_camera_count,
		"mask_rebuilds": mask_rebuild_count,
		"mask_rebuild_usec": mask_rebuild_usec,
		"visible_cells": _visible.size(),
	}


func _rebuild() -> void:
	var t0 := Time.get_ticks_usec()
	_visible.clear()
	var reach := radius_tiles + fringe_tiles + 1
	_opaque_cells.clear()
	if _opaque.is_valid():
		# One occluder query per window tile; the line walks read this snapshot.
		for x in range(_center.x - reach, _center.x + reach + 1):
			for y in range(_center.y - reach, _center.y + reach + 1):
				var probe := Vector2i(x, y)
				if bool(_opaque.call(probe)):
					_opaque_cells[probe] = true
	# Fail open: an Operator standing on an opaque tile has no meaningful view
	# origin, so occlusion is dropped rather than veiling everything around them.
	if _opaque_cells.has(_center):
		_opaque_cells.clear()
	for x in range(_center.x - reach, _center.x + reach + 1):
		for y in range(_center.y - reach, _center.y + reach + 1):
			var tile := Vector2i(x, y)
			if tile != _center and _line_clear(_center, tile):
				_visible[tile] = true
	mask_rebuild_count += 1
	mask_rebuild_usec += Time.get_ticks_usec() - t0


## Integer Bresenham from `a` toward `b`; clear when no opaque tile lies
## strictly between the endpoints. The target itself may be opaque (a wall
## face is seen). With no occluder callable everything is visible.
func _line_clear(a: Vector2i, b: Vector2i) -> bool:
	if _opaque_cells.is_empty():
		return true
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	var x := a.x
	var y := a.y
	while true:
		if x == b.x and y == b.y:
			return true
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
		if x == b.x and y == b.y:
			return true
		if _opaque_cells.has(Vector2i(x, y)):
			return false
	return true
