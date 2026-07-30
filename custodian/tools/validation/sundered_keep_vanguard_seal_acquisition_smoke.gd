extends SceneTree

const LEVEL_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_front_gate_large.json"
)
const SUNDERED_KEEP_MAP := preload(
	"res://game/world/sundered_keep/sundered_keep_map.gd"
)
const CACHE_TILE := Vector2i(62, 46)
const SIDEARM_LOCKER_TILE := Vector2i(73, 27)
const TILE_SIZE := 32.0

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level_data := _load_level_data()
	_assert_true(
		_has_authored_entry(
			level_data.get("markers", []),
			"id",
			"vanguard_seal_cache",
			CACHE_TILE
		),
		"cache marker must be authored at [62,46]"
	)
	_assert_true(
		_has_authored_entry(
			level_data.get("interactables", []),
			"kind",
			"vanguard_seal_cache",
			CACHE_TILE
		),
		"cache interaction must be authored beside its marker"
	)
	var cache_definition := _find_authored_entry(
		level_data.get("interactables", []),
		"kind",
		"vanguard_seal_cache"
	)
	_assert_true(
		str(cache_definition.get("name", "")) == "VanguardSealCache" \
		and str(cache_definition.get("prompt", "")) \
			== "OPEN CUSTODIAN COMMAND CACHE" \
		and is_equal_approx(
			float(cache_definition.get("distance", 0.0)),
			72.0
		),
		"cache authored name, prompt, and distance should match the contract"
	)

	var inventory := root.get_node_or_null("InventoryManager")
	_assert_true(inventory != null, "InventoryManager autoload should exist")
	if inventory != null:
		inventory.call("clear")

	var map := SUNDERED_KEEP_MAP.new()
	map.name = "VanguardSealAcquisitionSmokeMap"
	root.add_child(map)
	await process_frame

	var cache := map.get_node_or_null("VanguardSealCache")
	var p9_locker := map.get_node_or_null("SidearmLockerInteraction")
	_assert_true(cache != null, "authored cache interaction should exist")
	_assert_true(
		cache != null and cache.position == _tile_center(CACHE_TILE),
		"cache interaction should resolve to its authored marker tile"
	)
	_assert_true(
		not bool(
			map.call("get_sundered_keep_debug_state").get(
				"vanguard_seal_cache_available",
				true
			)
		),
		"dormant siege cache should be unavailable"
	)
	map.set("_siege_state", "active")
	map.call("_sync_vanguard_seal_cache_state")
	_assert_true(
		cache != null and not cache.is_in_group("interactable"),
		"active siege cache should remain locked"
	)

	map.call("_restore_main_gate_open_without_events", true)
	map.set("_siege_started", true)
	map.call("_complete_siege")
	await process_frame
	_assert_true(
		cache != null and cache.is_in_group("interactable"),
		"secured siege should activate the cache"
	)
	_assert_true(
		bool(
			map.call("get_sundered_keep_debug_state").get(
				"vanguard_seal_cache_available",
				false
			)
		),
		"secured cache should report available"
	)

	map.call("_recover_vanguard_seal")
	var count_after_open := (
		int(inventory.call("get_count", &"vanguard_seal"))
		if inventory != null else -1
	)
	_assert_true(count_after_open == 1, "cache should grant exactly one Vanguard Seal")
	_assert_true(
		inventory != null \
		and StringName(inventory.call("get_equipped", &"relic")) == &"",
		"cache recovery must not auto-equip the Seal"
	)
	_assert_true(
		bool(
			map.call("get_sundered_keep_debug_state").get(
				"vanguard_seal_cache_opened",
				false
			)
		),
		"cache should record opened state"
	)
	map.call("_recover_vanguard_seal")
	_assert_true(
		inventory != null \
		and int(inventory.call("get_count", &"vanguard_seal")) == 1,
		"reopening the cache must not duplicate the Seal"
	)

	var captured: Dictionary = map.call("capture_route_state")
	_assert_true(
		bool(captured.get("vanguard_seal_cache_opened", false)),
		"route capture should persist opened cache state"
	)
	var restored_map := SUNDERED_KEEP_MAP.new()
	restored_map.name = "RestoredVanguardSealAcquisitionSmokeMap"
	root.add_child(restored_map)
	await process_frame
	_assert_true(
		bool(restored_map.call("restore_route_state", captured)),
		"route restore should accept the cache state"
	)
	var restored_cache := restored_map.get_node_or_null("VanguardSealCache")
	_assert_true(
		bool(restored_map.get("_vanguard_seal_cache_opened")),
		"route restore should retain opened cache state"
	)
	_assert_true(
		restored_cache != null \
		and not restored_cache.visible \
		and not restored_cache.is_in_group("interactable"),
		"restored opened cache should remain unavailable"
	)
	_assert_true(
		inventory != null \
		and int(inventory.call("get_count", &"vanguard_seal")) == 1,
		"route restoration must not replay the reward"
	)

	_assert_true(
		not _has_blocker_covering_tile(map, CACHE_TILE),
		"cache tile should not overlap collision"
	)
	_assert_true(
		not _has_static_prop_at_tile(map, CACHE_TILE),
		"cache tile should not overlap an existing authored prop"
	)
	_assert_true(
		map.call(
			"can_traverse_elevation",
			Vector2i(56, 46),
			Vector2i(56, 47)
		),
		"gatehouse stairs should remain traversable"
	)
	_assert_true(
		not _has_blocker_covering_tile(map, Vector2i(56, 50)),
		"secured gatehouse threshold should remain traversable"
	)
	_assert_true(
		p9_locker != null \
		and p9_locker.position == _tile_center(SIDEARM_LOCKER_TILE) \
		and p9_locker.is_in_group("interactable"),
		"P-9 locker should remain independently available at [73,27]"
	)

	if inventory != null:
		inventory.call("clear")
		inventory.call("add_item", &"vanguard_seal", 1)
		_assert_true(
			bool(inventory.call("equip_item", &"vanguard_seal", &"relic")),
			"duplicate guard setup should equip the existing Seal"
		)
	var debug_map := SUNDERED_KEEP_MAP.new()
	debug_map.name = "EquippedSealDuplicateGuardSmokeMap"
	root.add_child(debug_map)
	await process_frame
	debug_map.set("_siege_state", "secured")
	debug_map.call("_sync_vanguard_seal_cache_state")
	debug_map.call("_recover_vanguard_seal")
	_assert_true(
		inventory != null \
		and int(inventory.call("get_count", &"vanguard_seal")) == 0 \
		and StringName(inventory.call("get_equipped", &"relic")) \
			== &"vanguard_seal",
		"equipped Seal should satisfy ownership without granting a duplicate"
	)

	if _failed:
		push_error("[SunderedKeepVanguardSealAcquisitionSmoke] FAIL")
		quit(1)
		return
	print("[SunderedKeepVanguardSealAcquisitionSmoke] PASS")
	quit(0)


func _load_level_data() -> Dictionary:
	var file := FileAccess.open(LEVEL_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _has_authored_entry(
	entries: Array,
	key: String,
	value: String,
	tile: Vector2i
) -> bool:
	for entry_variant: Variant in entries:
		var entry := entry_variant as Dictionary
		var raw_tile := entry.get("tile", []) as Array
		if str(entry.get(key, "")) == value \
		and raw_tile.size() >= 2 \
		and Vector2i(int(raw_tile[0]), int(raw_tile[1])) == tile:
			return true
	return false


func _find_authored_entry(
	entries: Array,
	key: String,
	value: String
) -> Dictionary:
	for entry_variant: Variant in entries:
		var entry := entry_variant as Dictionary
		if str(entry.get(key, "")) == value:
			return entry
	return {}


func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(
		(float(tile.x) + 0.5) * TILE_SIZE,
		(float(tile.y) + 0.5) * TILE_SIZE
	)


func _has_blocker_covering_tile(map: Node, tile: Vector2i) -> bool:
	var collision := map.get_node_or_null("Collision")
	if collision == null:
		return false
	var point := _tile_center(tile)
	for child in collision.get_children():
		if not (child is StaticBody2D):
			continue
		var body := child as StaticBody2D
		for shape_node in body.get_children():
			if not (shape_node is CollisionShape2D):
				continue
			var collision_shape := shape_node as CollisionShape2D
			if not (collision_shape.shape is RectangleShape2D):
				continue
			var rect_shape := collision_shape.shape as RectangleShape2D
			var center := body.position + collision_shape.position
			var rect := Rect2(center - rect_shape.size * 0.5, rect_shape.size)
			if rect.has_point(point):
				return true
	return false


func _has_static_prop_at_tile(map: Node, tile: Vector2i) -> bool:
	var props := map.get_node_or_null("PropsStatic")
	if props == null:
		return false
	var expected_anchor := Vector2(
		(float(tile.x) + 0.5) * TILE_SIZE,
		(float(tile.y) + 1.0) * TILE_SIZE
	)
	for child in props.get_children():
		if child is Sprite2D \
		and (child as Sprite2D).position.is_equal_approx(expected_anchor):
			return true
	return false


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error("[SunderedKeepVanguardSealAcquisitionSmoke] %s" % message)
