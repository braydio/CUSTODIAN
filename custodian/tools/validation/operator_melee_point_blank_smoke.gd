extends SceneTree
func _init() -> void:
	var authored_range := 72.0; var center := authored_range * 0.50; var radius := authored_range * 0.55
	assert(absf(16.0 - center) <= radius); assert(absf(52.0 - center) <= radius)
	assert(80.0 > authored_range); assert(-8.0 < 0.0)
	var source := FileAccess.get_file_as_string("res://game/actors/operator/operator.gd")
	assert(source.contains("_melee_range_current * 0.50")); assert(source.contains("_melee_range_current * 0.55"))
	assert(source.contains("dist > _melee_range_current")); assert(source.contains("if _melee_hit_targets.has(contact_key):"))
	print("operator_melee_point_blank_smoke: PASS"); quit(0)
