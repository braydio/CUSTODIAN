extends SceneTree

const SUNDERED_KEEP_MAP := preload("res://game/world/sundered_keep/sundered_keep_map.gd")


func _init() -> void:
	var map := SUNDERED_KEEP_MAP.new()
	root.add_child(map)
	await process_frame

	var missing := _collect_missing_sprite_textures(map)
	if not missing.is_empty():
		for path in missing:
			push_error("[SunderedKeepAssetSmoke] Missing Sprite2D texture: %s" % path)
		quit(1)
		return

	print("[SunderedKeepAssetSmoke] OK: %d Sprite2D nodes have live textures" % _count_sprites(map))
	quit(0)


func _collect_missing_sprite_textures(node: Node, path := "") -> Array[String]:
	var current_path := path
	if current_path.is_empty():
		current_path = node.name
	else:
		current_path = "%s/%s" % [current_path, node.name]

	var missing: Array[String] = []
	if node is Sprite2D and (node as Sprite2D).texture == null:
		missing.append(current_path)
	for child in node.get_children():
		missing.append_array(_collect_missing_sprite_textures(child, current_path))
	return missing


func _count_sprites(node: Node) -> int:
	var count := 0
	if node is Sprite2D:
		count += 1
	for child in node.get_children():
		count += _count_sprites(child)
	return count
