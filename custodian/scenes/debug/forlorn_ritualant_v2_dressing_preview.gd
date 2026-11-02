class_name ForlornRitualantV2DressingPreview
extends Node2D

const MANIFEST_PATH := (
	"res://content/metadata/assets/"
	+ "lower_quarter_gothic_scifi_v2_extract.semantic.json"
)

const PLACEMENT_PATH := (
	"res://scenes/debug/config/"
	+ "forlorn_ritualant_v2_dressing_placements.json"
)

var _props_root: Node2D
var _walls_root: Node2D

var _asset_index: Dictionary = {}
var _errors := PackedStringArray()


func _ready() -> void:
	_props_root = Node2D.new()
	_props_root.name = "Props"

	_walls_root = Node2D.new()
	_walls_root.name = "Walls"

	add_child(_walls_root)
	add_child(_props_root)

	rebuild()


func rebuild() -> bool:
	for child in _props_root.get_children():
		child.free()

	for child in _walls_root.get_children():
		child.free()

	_asset_index.clear()
	_errors.clear()

	var manifest := _load_json(MANIFEST_PATH)
	if manifest.is_empty():
		return false

	_index_manifest_group(
		manifest.get("props", []) as Array,
		&"prop"
	)

	_index_manifest_group(
		manifest.get("walls", []) as Array,
		&"wall"
	)

	var placement_doc := _load_json(PLACEMENT_PATH)
	if placement_doc.is_empty():
		return false

	for value: Variant in placement_doc.get(
		"placements",
		[]
	):
		if value is Dictionary:
			_spawn_record(value as Dictionary)

	return _errors.is_empty()


func _index_manifest_group(
	records: Array,
	kind: StringName
) -> void:
	for value: Variant in records:
		if not value is Dictionary:
			continue

		var entry := value as Dictionary
		var key := String(
			entry.get("variant_key", "")
		)

		if key.is_empty():
			continue

		var indexed := entry.duplicate(true)
		indexed["asset_kind"] = kind

		_asset_index[key] = indexed


func _spawn_record(record: Dictionary) -> void:
	if not bool(record.get("enabled", true)):
		return

	var variant := String(
		record.get("variant_key", "")
	)

	var asset := (
		_asset_index.get(
			variant,
			{}
		) as Dictionary
	)

	if asset.is_empty():
		_fail(
			"Unknown V2 asset: %s"
			% variant
		)
		return

	var texture_path := String(
		asset.get("runtime_path", "")
	)

	var texture := load(texture_path) as Texture2D

	if texture == null:
		_fail(
			"Missing V2 texture: %s"
			% texture_path
		)
		return

	var sprite := Sprite2D.new()

	sprite.name = String(
		record.get(
			"id",
			variant
		)
	).to_pascal_case()

	sprite.texture = texture
	sprite.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	sprite.centered = false
	sprite.flip_h = bool(
		record.get("flip_h", false)
	)

	var anchor := _vector2(
		record.get(
			"position",
			[0, 0]
		)
	)

	var anchor_mode := String(
		record.get(
			"anchor",
			"bottom_center"
		)
	)

	var size := texture.get_size()

	match anchor_mode:
		"center":
			sprite.position = (
				anchor
				- size * 0.5
			)

		"top_center":
			sprite.position = (
				anchor
				- Vector2(
					size.x * 0.5,
					0.0
				)
			)

		_:
			# Treat authored position as the physical
			# floor-contact point.
			sprite.position = (
				anchor
				- Vector2(
					size.x * 0.5,
					size.y
				)
			)

	sprite.z_as_relative = false
	sprite.z_index = int(
		record.get("z_index", 5)
	)

	sprite.modulate.a = float(
		record.get("alpha", 1.0)
	)

	sprite.set_meta(
		&"preview_placement_id",
		String(record.get("id", ""))
	)

	sprite.set_meta(
		&"variant_key",
		variant
	)

	var kind := StringName(
		asset.get(
			"asset_kind",
			&"prop"
		)
	)

	if kind == &"wall":
		_walls_root.add_child(sprite)
	else:
		_props_root.add_child(sprite)


func _unhandled_input(
	event: InputEvent
) -> void:
	if not (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		return

	match event.keycode:
		KEY_F5:
			visible = not visible

		KEY_F6:
			_props_root.visible = (
				not _props_root.visible
			)

		KEY_F7:
			_walls_root.visible = (
				not _walls_root.visible
			)


func get_debug_state() -> Dictionary:
	return {
		"visible": visible,
		"props_visible":
			_props_root.visible,
		"walls_visible":
			_walls_root.visible,
		"prop_count":
			_props_root.get_child_count(),
		"wall_count":
			_walls_root.get_child_count(),
		"errors":
			Array(_errors),
	}


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fail("Missing JSON: %s" % path)
		return {}

	var value: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(path)
	)

	if not value is Dictionary:
		_fail("Invalid JSON: %s" % path)
		return {}

	return value as Dictionary


func _vector2(value: Variant) -> Vector2:
	if value is Array:
		var array := value as Array

		if array.size() == 2:
			return Vector2(
				float(array[0]),
				float(array[1])
			)

	return Vector2.ZERO


func _fail(message: String) -> void:
	_errors.append(message)
	push_error(
		"[RitualantV2Preview] %s"
		% message
	)

