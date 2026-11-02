@tool
extends RefCounted
class_name SunderedKeepCliffAssetCatalog

const ROOT := "res://content/runtime/sundered_keep/terrain/cliffs/"
const CANVAS := Vector2(64.0, 96.0)
const PIVOT := Vector2(32.0, 94.0)

const KEYS: Array[String] = [
	"edge_n", "edge_e", "edge_s", "edge_w",
	"face_slice_01", "face_slice_wet_01", "face_slice_mossy_01",
	"inner_corner_ne", "inner_corner_nw", "inner_corner_se", "inner_corner_sw",
	"outer_corner_ne", "outer_corner_nw", "outer_corner_se", "outer_corner_sw",
]


static func all_specs() -> Dictionary:
	var specs: Dictionary = {}
	for direction in ["n", "e", "s", "w"]:
		_add(specs, "edge_%s" % direction, "edge", direction)
	for suffix in ["01", "wet_01", "mossy_01"]:
		_add(specs, "face_slice_%s" % suffix, "face_slice", "")
	for direction in ["ne", "nw", "se", "sw"]:
		_add(specs, "inner_corner_%s" % direction, "inner_corner", direction)
		_add(specs, "outer_corner_%s" % direction, "outer_corner", direction)
	return specs


static func get_spec(key: String) -> Dictionary:
	return (all_specs().get(key, {}) as Dictionary).duplicate(true)


static func keys_for_kind(kind: String) -> Array[String]:
	var result: Array[String] = []
	var specs := all_specs()
	for key in KEYS:
		if String((specs[key] as Dictionary).get("kind", "")) == kind:
			result.append(key)
	return result


static func _add(
	specs: Dictionary,
	key: String,
	kind: String,
	direction: String
) -> void:
	var filename := "cliff_%s.png" % key
	specs[key] = {
		"key": key,
		"kind": kind,
		"texture": load(ROOT + filename) as Texture2D,
		"direction": direction,
		"canvas_px": CANVAS,
		"pivot_px": PIVOT,
		"anchor": "bottom_center",
		"metadata_path": ROOT + "cliff_%s.game32.json" % key,
	}
