extends RefCounted
class_name MomentProbeCollector

var definitions: Array = []
var roles: Dictionary = {}
var records: Array[Dictionary] = []
var failures: Array[String] = []


func configure(items: Array, role_map: Dictionary) -> void:
	definitions = items
	roles = role_map


func sample_tick(tick: int) -> void:
	for definition: Dictionary in definitions:
		if not _should_sample(definition, tick):
			continue
		var role_name := str(definition.get("role", ""))
		var node := roles.get(role_name) as Node
		if node == null or not is_instance_valid(node):
			if bool(definition.get("required", false)):
				failures.append("required probe role unavailable: %s" % role_name)
			continue
		var values := {}
		for field: String in definition.get("fields", []):
			var value: Variant = _read_field(node, field)
			if value == null and bool(definition.get("required", false)):
				failures.append("required probe field unavailable: %s.%s" % [role_name, field])
			else:
				values[field] = _json_value(value)
		records.append({
			"id": str(definition.get("id", "")),
			"role": role_name,
			"tick": tick,
			"values": values,
		})


func _should_sample(definition: Dictionary, tick: int) -> bool:
	if definition.has("ticks"):
		for raw: Variant in definition.ticks:
			if int(raw) == tick:
				return true
		return false
	var start := int(definition.get("start_tick", 0))
	var finish := int(definition.get("end_tick", 2147483647))
	var every := int(definition.get("every_ticks", 1))
	return tick >= start and tick <= finish and (tick - start) % every == 0


func _read_field(node: Node, field: String) -> Variant:
	match field:
		"global_position":
			return node.global_position if node is Node2D else null
		"position":
			return node.position if node is Node2D else null
		"animation":
			if node is AnimatedSprite2D:
				return str(node.animation)
			var sprite := node.find_child("*AnimatedSprite2D*", true, false)
			return str(sprite.animation) if sprite is AnimatedSprite2D else null
		"frame":
			if node is AnimatedSprite2D:
				return node.frame
			var sprite := node.find_child("*AnimatedSprite2D*", true, false)
			return sprite.frame if sprite is AnimatedSprite2D else null
		_:
			return node.get(field)


func _json_value(value: Variant) -> Variant:
	if value is Vector2:
		return [value.x, value.y]
	if value is Vector2i:
		return [value.x, value.y]
	if value is StringName:
		return str(value)
	return value
