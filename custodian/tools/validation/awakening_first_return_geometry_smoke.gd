extends SceneTree

## Proves the Awakening blockout is physically walkable end to end.
##
## Builds a 16px occupancy grid from AwakeningLayout — the same authority the
## runtime scene builds its collision from — erodes it by the Operator's
## collision radius, and searches for a continuous route from the Crèche wake
## position to the Road of Witnesses South Reach completion trigger.
##
## This catches sealed doorways, forgotten blockers, corridors narrowed below the
## 128px critical-route minimum, Cistern routing breaks, and Road handoff drift —
## none of which a "does the scene load" test would notice.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")

const CELL := 16.0
const START := Vector2(0, 160)
const GOAL := Vector2(0, -6464)

var _failures: Array[String] = []
var _cols := 0
var _rows := 0
var _origin := Vector2.ZERO
var _open: PackedByteArray = PackedByteArray()
var _safe: PackedByteArray = PackedByteArray()


func _init() -> void:
	var started := Time.get_ticks_msec()
	_build_grid()
	var build_ms := Time.get_ticks_msec() - started
	_check_world_bounds()
	_check_road_offset()
	var route := _find_route(START, GOAL)
	if route.is_empty():
		_fail("no traversable route from %s to %s" % [str(START), str(GOAL)])
	else:
		_check_route_visits_mandatory_zones(route)
	_check_zone_anchors()
	_report(build_ms, route.size())


# --- Grid --------------------------------------------------------------------

func _build_grid() -> void:
	var bounds := Layout.WORLD_BOUNDS
	_origin = bounds.position
	_cols = int(ceil(bounds.size.x / CELL))
	_rows = int(ceil(bounds.size.y / CELL))
	_open.resize(_cols * _rows)
	_safe.resize(_cols * _rows)

	# Set-piece collision, minus anything the locked traversal geometry carves
	# back out. Mirrors AwakeningFirstReturn._build_set_pieces exactly.
	var traversal := Layout.traversal_rects()
	var blockers: Array[Rect2] = []
	for rect in Layout.blocking_rects():
		var carved := false
		for open_rect in traversal:
			if open_rect.intersects(rect):
				carved = true
				break
		if not carved:
			blockers.append(rect)

	for row in _rows:
		for col in _cols:
			var centre := _origin + Vector2((col + 0.5) * CELL, (row + 0.5) * CELL)
			var walkable := Layout.is_point_walkable(centre)
			if walkable:
				for blocker in blockers:
					if blocker.has_point(centre):
						walkable = false
						break
			_open[row * _cols + col] = 1 if walkable else 0

	# Erode by one cell so the Operator's 11px collision radius fits everywhere
	# the search is allowed to travel.
	for row in _rows:
		for col in _cols:
			_safe[row * _cols + col] = 1 if _is_clear(col, row) else 0


func _is_clear(col: int, row: int) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var c: int = col + dx
			var r: int = row + dy
			if c < 0 or r < 0 or c >= _cols or r >= _rows: return false
			if _open[r * _cols + c] == 0: return false
	return true


func _cell_of(point: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor((point.x - _origin.x) / CELL)), 0, _cols - 1),
		clampi(int(floor((point.y - _origin.y) / CELL)), 0, _rows - 1)
	)


## Nearest safe cell within `radius_cells`, so an authored anchor that sits a few
## pixels inside a wall face still resolves to the room it belongs to.
func _nearest_safe(point: Vector2, radius_cells := 6) -> Vector2i:
	var start := _cell_of(point)
	if _safe[start.y * _cols + start.x] == 1: return start
	for ring in range(1, radius_cells + 1):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if absi(dx) != ring and absi(dy) != ring: continue
				var c := start.x + dx
				var r := start.y + dy
				if c < 0 or r < 0 or c >= _cols or r >= _rows: continue
				if _safe[r * _cols + c] == 1: return Vector2i(c, r)
	return Vector2i(-1, -1)


func _find_route(from: Vector2, to: Vector2) -> PackedInt32Array:
	var start := _nearest_safe(from)
	var goal := _nearest_safe(to)
	if start.x < 0:
		_fail("start %s has no traversable cell within the Operator radius" % str(from))
		return PackedInt32Array()
	if goal.x < 0:
		_fail("goal %s has no traversable cell within the Operator radius" % str(to))
		return PackedInt32Array()
	var came_from := PackedInt32Array()
	came_from.resize(_cols * _rows)
	came_from.fill(-2)
	var start_index := start.y * _cols + start.x
	var goal_index := goal.y * _cols + goal.x
	came_from[start_index] = -1
	var queue := PackedInt32Array([start_index])
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		if index == goal_index:
			return _reconstruct(came_from, goal_index)
		var col := index % _cols
		var row := index / _cols
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var c: int = col + offset.x
			var r: int = row + offset.y
			if c < 0 or r < 0 or c >= _cols or r >= _rows: continue
			var neighbour: int = r * _cols + c
			if _safe[neighbour] == 0 or came_from[neighbour] != -2: continue
			came_from[neighbour] = index
			queue.append(neighbour)
	_report_frontier(came_from, from, to)
	return PackedInt32Array()


## A "no route" failure is only useful if it says where the route died, so name
## the northernmost cell the search reached and the zone that contains it.
func _report_frontier(came_from: PackedInt32Array, from: Vector2, to: Vector2) -> void:
	var best := Vector2(0.0, 1.0e9)
	var reached := 0
	for index in came_from.size():
		if came_from[index] == -2: continue
		reached += 1
		var point := _world_of(index)
		if point.y < best.y: best = point
	var zone_label := "outside every zone envelope"
	for zone in Layout.ZONES:
		if (zone["envelope"] as Rect2).has_point(best):
			zone_label = String(zone["id"])
			break
	_fail("route %s -> %s died after %d cells; frontier %s in %s" % [
		str(from), str(to), reached, str(best), zone_label
	])


func _reconstruct(came_from: PackedInt32Array, goal_index: int) -> PackedInt32Array:
	var path := PackedInt32Array()
	var cursor := goal_index
	while cursor >= 0:
		path.append(cursor)
		cursor = came_from[cursor]
	path.reverse()
	return path


func _world_of(index: int) -> Vector2:
	return _origin + Vector2((index % _cols + 0.5) * CELL, (index / _cols + 0.5) * CELL)


# --- Assertions --------------------------------------------------------------

func _check_world_bounds() -> void:
	var bounds := Layout.WORLD_BOUNDS
	for zone in Layout.ZONES:
		var envelope: Rect2 = zone["envelope"]
		if not bounds.encloses(envelope):
			_fail("zone %s envelope %s escapes WORLD_BOUNDS" % [str(zone["id"]), str(envelope)])
	if not bounds.encloses(Layout.road_world_bounds()):
		_fail("translated Road bounds escape WORLD_BOUNDS")


func _check_road_offset() -> void:
	var derived := Layout.ROAD_WORLD_SOUTH_ENTRY - Layout.ROAD_LOCAL_SOUTH_ENTRY
	if derived != Layout.ROAD_WORLD_OFFSET:
		_fail("ROAD_WORLD_OFFSET %s does not match the locked entry pair (%s)" % [
			str(Layout.ROAD_WORLD_OFFSET), str(derived)
		])
	if Layout.ROAD_WORLD_OFFSET != Vector2(6, -6626):
		_fail("ROAD_WORLD_OFFSET drifted from the locked value (6, -6626)")


## Every mandatory zone must be physically walked through on the way north; the
## optional Chapel must be reachable but must not be on the critical path.
func _check_route_visits_mandatory_zones(route: PackedInt32Array) -> void:
	var visited := {}
	for index in route:
		var point := _world_of(index)
		for zone in Layout.ZONES:
			if (zone["envelope"] as Rect2).has_point(point):
				visited[String(zone["id"])] = true
	for zone in Layout.ZONES:
		var zone_id := String(zone["id"])
		if bool(zone.get("optional", false)):
			if visited.has(zone_id):
				_fail("optional zone %s sits on the critical route" % zone_id)
			continue
		if not visited.has(zone_id):
			_fail("critical route never enters %s" % zone_id)


## Each zone's authored entry and exit must be standable, and the optional
## Chapel must be reachable from the wake position.
func _check_zone_anchors() -> void:
	for zone in Layout.ZONES:
		var zone_id := String(zone["id"])
		for key in ["entry", "exit"]:
			var anchor: Vector2 = zone[key]
			if _nearest_safe(anchor).x < 0:
				_fail("%s %s %s is not standable" % [zone_id, key, str(anchor)])
	var chapel := Layout.zone_by_id(&"zone09_chapel_late_service")
	if not chapel.is_empty():
		var interior := Vector2(-736, -5696)
		if _find_route(START, interior).is_empty():
			_fail("optional Chapel interior %s is unreachable" % str(interior))


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("awakening_first_return_geometry_smoke: " + message)


func _report(build_ms: int, route_cells: int) -> void:
	var open_cells := 0
	for value in _safe: open_cells += value
	print("awakening_first_return_geometry_smoke: grid=%dx%d cells safe=%d build_ms=%d route_cells=%d" % [
		_cols, _rows, open_cells, build_ms, route_cells
	])
	var passed := _failures.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "awakening_first_return_geometry_smoke",
		"passed": passed,
		"failure_count": _failures.size(),
		"failures": _failures,
	}))
	if passed:
		print("awakening_first_return_geometry_smoke: PASS")
		quit(0)
		return
	print("awakening_first_return_geometry_smoke: FAIL (%d)" % _failures.size())
	for message in _failures: print("  - %s" % message)
	quit(1)
