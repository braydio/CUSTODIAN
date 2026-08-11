extends RefCounted
class_name MomentProbeCollector

const VALUE_READER := preload("res://tools/iteration/godot/moment_value_reader.gd")

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
		var snapshot: Variant = null
		if str(definition.get("snapshot", "")) == "debug":
			if not node.has_method("get_debug_snapshot"):
				if bool(definition.get("required", false)):
					failures.append("required debug snapshot unavailable: %s" % role_name)
				continue
			snapshot = node.call("get_debug_snapshot")
		for field: String in definition.get("fields", []):
			var value: Variant = VALUE_READER.dotted(snapshot, field) if snapshot != null else _read_field(node, field)
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
		"visible_visual_anchor_delta_px":
			return _visible_visual_anchor_delta_px(node)
		"visible_visual_anchor_nodes":
			return _visible_visual_anchor_nodes(node)
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


func _visible_visual_anchor_delta_px(node: Node) -> Variant:
	var sprites := _operator_visual_sprites(node)
	if sprites.is_empty():
		return null
	var canonical := Vector2(0.0, -18.0)
	var maximum_delta := 0.0
	var visible_count := 0
	for sprite: AnimatedSprite2D in sprites:
		if not sprite.visible:
			continue
		visible_count += 1
		maximum_delta = maxf(
			maximum_delta,
			maxf(
				sprite.position.distance_to(canonical),
				sprite.offset.length()
			)
		)
	return maximum_delta if visible_count > 0 else null


func _visible_visual_anchor_nodes(node: Node) -> Array[String]:
	var names: Array[String] = []
	for sprite: AnimatedSprite2D in _operator_visual_sprites(node):
		if sprite.visible:
			names.append(str(sprite.name))
	return names


func _operator_visual_sprites(node: Node) -> Array[AnimatedSprite2D]:
	var sprites: Array[AnimatedSprite2D] = []
	for child_name: String in [
		"AnimatedSprite2D",
		"DodgeFXBackSprite",
		"ModularCapeSprite",
		"ModularLowerBodySprite",
		"ModularUpperBodySprite",
		"ModularHeadSprite",
		"ModularSidearmSprite",
		"ModularUpperFxSprite",
		"MeleeWeaponOverlaySprite",
		"MeleeFxOverlaySprite",
	]:
		var sprite := node.get_node_or_null(child_name) as AnimatedSprite2D
		if sprite != null:
			sprites.append(sprite)
	return sprites


func _json_value(value: Variant) -> Variant:
	if value is Vector2:
		return [value.x, value.y]
	if value is Vector2i:
		return [value.x, value.y]
	if value is StringName:
		return str(value)
	if value is Dictionary:
		var output := {}
		for key in value:
			output[str(key)] = _json_value(value[key])
		return output
	if value is Array:
		var output := []
		for item in value:
			output.append(_json_value(item))
		return output
	return value
