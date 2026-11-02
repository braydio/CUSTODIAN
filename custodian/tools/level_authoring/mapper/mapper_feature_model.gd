class_name MapperFeatureModel
extends RefCounted

static func descriptor(id: String, label: String, kind: String, anchor: Vector2, bounds := Rect2(), movable := true, duplicable := true) -> Dictionary:
	return {"id": id, "section": "", "label": label, "kind": kind, "anchor": anchor, "bounds": bounds, "movable": movable, "duplicable": duplicable}

