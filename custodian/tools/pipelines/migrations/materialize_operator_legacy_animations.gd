extends SceneTree
## One-time, explicit SpriteFrames-to-strip migration. Never used by gameplay.

const DEFAULT_MAP := "res://tools/pipelines/migrations/operator_legacy_animation_map.json"


func _init() -> void:
	var map_path := DEFAULT_MAP
	var apply := false
	var args := OS.get_cmdline_user_args()
	for index in args.size():
		if args[index] == "--apply":
			apply = true
		elif args[index] == "--map" and index + 1 < args.size():
			map_path = args[index + 1]
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(map_path))
	if not payload is Dictionary or not payload.get("migrations") is Array:
		push_error("Invalid migration map: %s" % map_path)
		quit(1)
		return
	# Preflight the entire batch before publishing any pixels.
	var plans: Array[Dictionary] = []
	var identities := {}
	for row: Dictionary in payload.migrations:
		var plan := _prepare(row)
		if plan.is_empty():
			quit(1)
			return
		if identities.has(plan.identity):
			push_error("Duplicate migration identity: %s" % plan.identity)
			quit(1)
			return
		identities[plan.identity] = true
		plans.append(plan)
	for plan in plans:
		if apply:
			var error := DirAccess.make_dir_recursive_absolute(plan.path.get_base_dir())
			if error != OK:
				push_error("Cannot create migration destination: %s" % plan.path)
				quit(1)
				return
			if not FileAccess.file_exists(plan.path):
				error = (plan.image as Image).save_png(plan.path)
				if error != OK:
					push_error("Cannot save migration strip: %s" % plan.path)
					quit(1)
					return
			var file := FileAccess.open(plan.metadata_path, FileAccess.WRITE)
			if file == null:
				push_error("Cannot save migration timing metadata: %s" % plan.metadata_path)
				quit(1)
				return
			file.store_string(JSON.stringify(plan.metadata, "\t") + "\n")
		print("%s %s (%d frames @ %.6f fps)" % [
			"materialized" if apply else "dry-run", plan.path,
			plan.metadata.frames, plan.metadata.fps])
	print("materialize_operator_legacy_animations: %d verified plans" % plans.size())
	quit(0)


func _prepare(row: Dictionary) -> Dictionary:
	for field in ["resource", "old_animation", "profile", "group", "action", "direction", "layer", "consumer"]:
		if String(row.get(field, "")).is_empty():
			push_error("Migration row needs explicit %s: %s" % [field, row])
			return {}
	var action := String(row.action)
	var owner := String(row.get("owner", "operator"))
	var token := RegEx.new()
	token.compile("^[a-z0-9_]+$")
	if token.search(owner) == null:
		push_error("Invalid migration owner: %s" % owner)
		return {}
	for field in ["profile", "group", "action", "direction", "layer"]:
		if token.search(String(row[field])) == null:
			push_error("Invalid identity token %s" % row[field])
			return {}
	if action.begins_with("legacy_") or action.contains("_legacy_"):
		push_error("Migration must produce a semantic action: %s" % action)
		return {}
	if not String(row.direction) in ["s", "se", "e", "ne", "n", "nw", "w", "sw", "omni"]:
		push_error("Invalid migration direction")
		return {}
	var resource := load(String(row.resource)) as SpriteFrames
	var old := StringName(row.old_animation)
	if resource == null or not resource.has_animation(old) or resource.get_frame_count(old) < 1:
		push_error("Missing migration animation %s in %s" % [old, row.resource])
		return {}
	var images: Array[Image] = []
	var durations: Array[float] = []
	var hashes: Array[String] = []
	var size := Vector2i.ZERO
	for index in resource.get_frame_count(old):
		var texture := resource.get_frame_texture(old, index)
		if texture == null:
			push_error("Null migration frame %s:%d" % [old, index])
			return {}
		var frame := texture.get_image()
		if frame == null or frame.is_empty():
			push_error("Unreadable migration frame %s:%d" % [old, index])
			return {}
		frame.convert(Image.FORMAT_RGBA8)
		if index == 0:
			size = frame.get_size()
		elif frame.get_size() != size:
			push_error("Variable canvas needs explicit migration review: %s" % old)
			return {}
		images.append(frame)
		durations.append(resource.get_frame_duration(old, index))
		hashes.append(_hash(frame))
	var strip := Image.create(size.x * images.size(), size.y, false, Image.FORMAT_RGBA8)
	for index in images.size():
		strip.blit_rect(images[index], Rect2i(Vector2i.ZERO, size), Vector2i(index * size.x, 0))
		if _hash(strip.get_region(Rect2i(index * size.x, 0, size.x, size.y))) != hashes[index]:
			push_error("Migration pixel verification failed: %s:%d" % [old, index])
			return {}
	var cell := str(size.x) if size.x == size.y else "%dx%d" % [size.x, size.y]
	var identity := "%s/%s/%s/%s/%s" % [row.profile, row.group, action, row.direction, row.layer]
	if owner != "operator":
		identity = "weapon/%s/%s" % [owner, identity]
	var filename := "%s__%s__%s__%s__%s__%s__%df__%s.png" % [
		owner, row.layer, row.profile, row.group, action, row.direction, images.size(), cell]
	var directory := "res://content/sprites/operator/source/animations/%s/%s/%s" % [row.profile, row.group, action]
	if owner != "operator":
		directory = "res://content/sprites/weapons/%s/source/operator/%s/overrides/%s/%s" % [owner, row.profile, row.group, action]
	var path := directory.path_join(filename)
	# Refuse replacement siblings, even if they have a different frame count.
	var existing_files := DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()
	for existing in existing_files:
		if existing.begins_with(filename.get_slice("__", 0) + "__" + String(row.layer) + "__") \
		and existing.ends_with(".png") and existing.contains("__%s__" % row.direction):
			var previous := Image.load_from_file(ProjectSettings.globalize_path(directory.path_join(existing)))
			previous.convert(Image.FORMAT_RGBA8)
			if existing != filename or previous.get_size() != strip.get_size() or _hash(previous) != _hash(strip):
				push_error("Refusing to overwrite existing semantic art: %s" % directory.path_join(existing))
				return {}
	var metadata := {
		"schema": "custodian.operator_animation_timing.v1",
		"frames": images.size(), "fps": resource.get_animation_speed(old),
		"loop": resource.get_animation_loop(old), "durations": durations,
		"frame_rgba_sha256": hashes,
		"migration_source": {"resource": row.resource, "animation": old, "consumer": row.consumer},
	}
	var metadata_path := path.get_basename() + ".animation.json"
	if FileAccess.file_exists(metadata_path):
		var existing_metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		if not existing_metadata is Dictionary or existing_metadata != JSON.parse_string(JSON.stringify(metadata)):
			push_error("Refusing to overwrite different timing metadata: %s" % metadata_path)
			return {}
	return {
		"identity": identity, "path": path, "image": strip,
		"metadata_path": metadata_path, "metadata": metadata,
	}


func _hash(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()
