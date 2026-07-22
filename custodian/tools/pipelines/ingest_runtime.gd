extends SceneTree

const SUPPORTED_IMAGE_EXTENSIONS := [".png"]
const POST_PROCESS_OPERATOR_CURATED := "operator_curated_resources"
const POST_PROCESS_OPERATOR_MODULAR_RUNTIME := "operator_modular_runtime"
const POST_PROCESS_ENEMY_RUNTIME_IMPORT := "enemy_runtime_import"
const POST_PROCESS_VEHICLE_RUNTIME_IMPORT := "vehicle_runtime_import"
const POST_PROCESS_ACTOR_SPRITEFRAMES_PREFIX := "actor_spriteframes:"

var _project_root: String
var _sprites_root: String
var _pipeline_root: String
var _inbox_dir: String
var _normalized_dir: String
var _logs_dir: String
var _archive_dir: String

var _dry_run := false
var _skip_post := false
var _remove_superseded := false
var _manifest_paths: Array[String] = []
var _had_error := false
var _pending_post_process_steps: Array[String] = []
var _pending_finalizations: Array[Dictionary] = []
var _pending_cleanup_superseded := false


func _init() -> void:
	_project_root = ProjectSettings.globalize_path("res://")
	_sprites_root = _join_path(_project_root, "content/sprites")
	_pipeline_root = _join_path(_sprites_root, "_pipeline")
	_inbox_dir = _join_path(_pipeline_root, "inbox")
	_normalized_dir = _join_path(_pipeline_root, "normalized")
	_logs_dir = _join_path(_pipeline_root, "logs")
	_archive_dir = _join_path(_pipeline_root, "archive")

	_ensure_directories()
	_parse_args(OS.get_cmdline_user_args())

	var manifests := _resolve_manifest_paths()
	if manifests.is_empty():
		print("No manifests found in %s" % _inbox_dir)
		quit()
		return

	for manifest_path in manifests:
		var result := _process_manifest(manifest_path)
		if not result:
			_had_error = true

	if not _had_error and not _skip_post:
		for step in _pending_post_process_steps:
			var post_result := _run_post_process(step, _pending_cleanup_superseded)
			if not post_result.get("ok", false):
				push_error("batched post-process %s: %s" % [step, post_result.get("error", "post-process failed")])
				_had_error = true
				break

	if not _had_error:
		_finalize_pending_manifests()

	quit(1 if _had_error else 0)


func _parse_args(args: PackedStringArray) -> void:
	var index := 0
	while index < args.size():
		var arg := args[index]
		match arg:
			"--dry-run":
				_dry_run = true
			"--skip-post":
				_skip_post = true
			"--remove-superseded":
				_remove_superseded = true
			"--manifest":
				index += 1
				if index >= args.size():
					push_error("--manifest requires a path")
					_had_error = true
					return
				_manifest_paths.append(_resolve_manifest_arg(args[index]))
			_:
				push_warning("Ignoring unknown ingest argument: %s" % arg)
		index += 1


func _ensure_directories() -> void:
	for path in [_pipeline_root, _inbox_dir, _normalized_dir, _logs_dir, _archive_dir]:
		DirAccess.make_dir_recursive_absolute(path)


func _resolve_manifest_paths() -> Array[String]:
	if not _manifest_paths.is_empty():
		return _manifest_paths

	var manifests: Array[String] = []
	var dir := DirAccess.open(_inbox_dir)
	if dir == null:
		return manifests

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".json"):
			manifests.append(_join_path(_inbox_dir, entry))
		entry = dir.get_next()
	dir.list_dir_end()
	manifests.sort()
	return manifests


func _process_manifest(manifest_path: String) -> bool:
	var manifest_result := _load_manifest(manifest_path)
	if not manifest_result.get("ok", false):
		push_error("%s: %s" % [manifest_path.get_file(), manifest_result.get("error", "manifest load failed")])
		return false

	var manifest: Dictionary = manifest_result["data"]
	var source_path := _resolve_source_path(manifest_path, manifest)
	if source_path.is_empty():
		push_error("%s: could not resolve source image" % manifest_path.get_file())
		return false

	var image := Image.new()
	var load_error := image.load(source_path)
	if load_error != OK:
		push_error("%s: failed to load source image %s" % [manifest_path.get_file(), source_path])
		return false

	var frames_result := _build_source_frames(image, manifest)
	if not frames_result.get("ok", false):
		push_error("%s: %s" % [manifest_path.get_file(), frames_result.get("error", "frame parse failed")])
		return false

	var source_frames: Array = frames_result["frames"]
	var outputs_data = manifest.get("outputs", [])
	if not (outputs_data is Array) or outputs_data.is_empty():
		push_error("%s: manifest must define a non-empty outputs array" % manifest_path.get_file())
		return false

	var output_paths: Array[String] = []
	var cleanup_superseded := _remove_superseded or bool(manifest.get("remove_superseded", false))
	for output_spec_variant in outputs_data:
		if not (output_spec_variant is Dictionary):
			push_error("%s: output entries must be dictionaries" % manifest_path.get_file())
			return false
		var output_result := _write_output(
			manifest_path.get_file(),
			output_spec_variant as Dictionary,
			source_frames,
			cleanup_superseded
		)
		if not output_result.get("ok", false):
			push_error("%s: %s" % [manifest_path.get_file(), output_result.get("error", "write failed")])
			return false
		output_paths.append(output_result["path"])

	_write_preview(manifest_path, source_frames)

	var post_process_steps: Array = manifest.get("post_process", [])
	if not _skip_post:
		for step_variant in post_process_steps:
			var step := str(step_variant)
			if not _pending_post_process_steps.has(step):
				_pending_post_process_steps.append(step)
	_pending_cleanup_superseded = _pending_cleanup_superseded or cleanup_superseded
	_pending_finalizations.append({
		"manifest_path": manifest_path,
		"source_path": source_path,
		"output_paths": output_paths,
		"post_process_steps": post_process_steps,
	})
	return true


func _finalize_pending_manifests() -> void:
	for record in _pending_finalizations:
		var manifest_path := str(record.get("manifest_path", ""))
		var source_path := str(record.get("source_path", ""))
		var output_paths: Array[String] = []
		for output_path in record.get("output_paths", []):
			output_paths.append(str(output_path))
		var post_process_steps: Array = record.get("post_process_steps", [])
		_write_log(manifest_path, source_path, output_paths, post_process_steps)
		_archive_file(manifest_path)
		_archive_file(source_path)
		_remove_source_import_sidecar(source_path)
		print("[DONE] %s" % manifest_path.get_file())


func _load_manifest(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "unable to open manifest"}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {"ok": false, "error": "manifest root must be a JSON object"}
	return {"ok": true, "data": parsed}


func _resolve_source_path(manifest_path: String, manifest: Dictionary) -> String:
	if manifest.has("source"):
		return _resolve_input_path(str(manifest["source"]), manifest_path.get_base_dir())

	var base_path: String = manifest_path.get_basename()
	for extension in SUPPORTED_IMAGE_EXTENSIONS:
		var candidate: String = base_path + extension
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


func _build_source_frames(image: Image, manifest: Dictionary) -> Dictionary:
	var mode := str(manifest.get("mode", "copy"))
	match mode:
		"copy":
			return {"ok": true, "frames": [image.duplicate()]}
		"strip":
			return _build_strip_frames(image, manifest)
		"grid":
			return _build_grid_frames(image, manifest)
		_:
			return {"ok": false, "error": "unsupported mode %s" % mode}


func _build_strip_frames(image: Image, manifest: Dictionary) -> Dictionary:
	var frame_size_result := _parse_frame_size(manifest)
	if not frame_size_result.get("ok", false):
		return frame_size_result
	var frame_size: Vector2i = frame_size_result["frame_size"]
	if image.get_height() != frame_size.y or image.get_width() % frame_size.x != 0:
		return {"ok": false, "error": "strip mode source dimensions do not match frame_size"}

	var frame_count := image.get_width() / frame_size.x
	var frames: Array = []
	for frame_index in range(frame_count):
		var frame := image.get_region(Rect2i(frame_index * frame_size.x, 0, frame_size.x, frame_size.y))
		frames.append(frame)
	return {"ok": true, "frames": frames}


func _build_grid_frames(image: Image, manifest: Dictionary) -> Dictionary:
	var frame_size_result := _parse_frame_size(manifest)
	if not frame_size_result.get("ok", false):
		return frame_size_result
	var frame_size: Vector2i = frame_size_result["frame_size"]
	var columns := int(manifest.get("columns", 0))
	var rows := int(manifest.get("rows", 0))
	if columns <= 0 or rows <= 0:
		return {"ok": false, "error": "grid mode requires positive columns and rows"}
	if image.get_width() != columns * frame_size.x or image.get_height() != rows * frame_size.y:
		return {"ok": false, "error": "grid mode source dimensions do not match frame_size * columns/rows"}

	var frames: Array = []
	for row_index in range(rows):
		for column_index in range(columns):
			var frame := image.get_region(
				Rect2i(column_index * frame_size.x, row_index * frame_size.y, frame_size.x, frame_size.y)
			)
			frames.append(frame)
	return {"ok": true, "frames": frames}


func _parse_frame_size(manifest: Dictionary) -> Dictionary:
	var frame_size_data = manifest.get("frame_size", null)
	if frame_size_data == null:
		return {"ok": false, "error": "frame_size is required"}
	if not (frame_size_data is Array) or frame_size_data.size() != 2:
		return {"ok": false, "error": "frame_size must be [width, height]"}
	var frame_size := Vector2i(int(frame_size_data[0]), int(frame_size_data[1]))
	if frame_size.x <= 0 or frame_size.y <= 0:
		return {"ok": false, "error": "frame_size values must be positive"}
	return {"ok": true, "frame_size": frame_size}


func _write_output(
	manifest_name: String,
	output_spec: Dictionary,
	source_frames: Array,
	cleanup_superseded: bool
) -> Dictionary:
	var relative_path := str(output_spec.get("path", ""))
	if relative_path.is_empty():
		return {"ok": false, "error": "every output requires a relative path"}

	var output_path := _join_path(_sprites_root, relative_path)
	var selected_frames_result := _select_frames(source_frames, output_spec.get("select", null))
	if not selected_frames_result.get("ok", false):
		return selected_frames_result
	var transformed_frames: Array = []
	for frame_variant in selected_frames_result["frames"]:
		transformed_frames.append(_apply_transform(frame_variant, output_spec.get("transform", null)))

	var image_result := _encode_frames(transformed_frames, str(output_spec.get("layout", "horizontal_strip")))
	if not image_result.get("ok", false):
		return image_result

	if _dry_run:
		if cleanup_superseded:
			_cleanup_superseded_outputs(output_path, manifest_name, true)
		print("[DRY RUN] %s" % relative_path)
		return {"ok": true, "path": output_path}

	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	if cleanup_superseded:
		_cleanup_superseded_outputs(output_path, manifest_name, false)
	var save_error := (image_result["image"] as Image).save_png(output_path)
	if save_error != OK:
		return {"ok": false, "error": "failed to save output %s" % relative_path}
	return {"ok": true, "path": output_path}


func _cleanup_superseded_outputs(output_path: String, manifest_name: String, dry_run: bool) -> void:
	var target_identity := _canonical_output_identity(output_path.get_file())
	if target_identity.is_empty():
		return
	var directory := DirAccess.open(output_path.get_base_dir())
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if not directory.current_is_dir() and entry.ends_with(".png") and entry != output_path.get_file():
			if _canonical_output_identity(entry) == target_identity:
				var candidate := _join_path(output_path.get_base_dir(), entry)
				if dry_run:
					print("[DRY RUN] remove superseded %s for %s" % [_format_log_path(candidate), manifest_name])
				else:
					DirAccess.remove_absolute(candidate)
					var import_path := candidate + ".import"
					if FileAccess.file_exists(import_path):
						DirAccess.remove_absolute(import_path)
					print("[REMOVED SUPERSEDED] %s" % _format_log_path(candidate))
		entry = directory.get_next()
	directory.list_dir_end()


func _canonical_output_identity(filename: String) -> String:
	if not filename.ends_with(".png"):
		return ""
	var parts := filename.trim_suffix(".png").split("__")
	if parts.size() < 5:
		return ""
	var frames_token := parts[parts.size() - 2]
	var size_token := parts[parts.size() - 1]
	if not frames_token.ends_with("f") or not frames_token.trim_suffix("f").is_valid_int():
		return ""
	var size_parts := size_token.to_lower().split("x")
	if size_parts.size() < 1 or size_parts.size() > 2:
		return ""
	for size_part in size_parts:
		if not size_part.is_valid_int() or int(size_part) <= 0:
			return ""
	return "__".join(parts.slice(0, parts.size() - 2))


func _select_frames(source_frames: Array, selector_variant: Variant) -> Dictionary:
	if selector_variant == null:
		return {"ok": true, "frames": source_frames.duplicate(true)}
	if not (selector_variant is Dictionary):
		return {"ok": false, "error": "select must be an object"}

	var selector := selector_variant as Dictionary
	var selector_type := str(selector.get("type", "indices"))
	match selector_type:
		"range":
			var start := int(selector.get("start", 0))
			var count := int(selector.get("count", 0))
			if count <= 0:
				return {"ok": false, "error": "range selector requires count > 0"}
			if start < 0 or start + count > source_frames.size():
				return {"ok": false, "error": "range selector is out of bounds"}
			return {"ok": true, "frames": source_frames.slice(start, start + count)}
		"indices":
			var indices = selector.get("indices", [])
			if not (indices is Array) or indices.is_empty():
				return {"ok": false, "error": "indices selector requires a non-empty indices array"}
			var frames: Array = []
			for index_variant in indices:
				var index := int(index_variant)
				if index < 0 or index >= source_frames.size():
					return {"ok": false, "error": "frame index %d is out of bounds" % index}
				frames.append((source_frames[index] as Image).duplicate())
			return {"ok": true, "frames": frames}
		"all":
			return {"ok": true, "frames": source_frames.duplicate(true)}
		_:
			return {"ok": false, "error": "unsupported selector type %s" % selector_type}


func _apply_transform(frame_variant: Variant, transform_variant: Variant) -> Image:
	var frame := (frame_variant as Image).duplicate()
	if transform_variant == null:
		return frame
	if not (transform_variant is Dictionary):
		return frame

	var transform := transform_variant as Dictionary
	if transform.has("resize"):
		var resize_data = transform["resize"]
		if resize_data is Array and resize_data.size() == 2:
			frame.resize(int(resize_data[0]), int(resize_data[1]), Image.INTERPOLATE_NEAREST)

	if transform.has("canvas"):
		var canvas_data = transform["canvas"]
		var offset_data = transform.get("offset", [0, 0])
		if canvas_data is Array and canvas_data.size() == 2 and offset_data is Array and offset_data.size() == 2:
			var composed := Image.create_empty(int(canvas_data[0]), int(canvas_data[1]), false, Image.FORMAT_RGBA8)
			composed.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(int(offset_data[0]), int(offset_data[1])))
			frame = composed

	return frame


func _encode_frames(frames: Array, layout: String) -> Dictionary:
	if frames.is_empty():
		return {"ok": false, "error": "output produced zero frames"}
	if layout == "copy":
		if frames.size() != 1:
			return {"ok": false, "error": "copy layout requires a single frame"}
		return {"ok": true, "image": (frames[0] as Image).duplicate()}

	var first_frame := frames[0] as Image
	var frame_width := first_frame.get_width()
	var frame_height := first_frame.get_height()

	for frame_variant in frames:
		var frame := frame_variant as Image
		if frame.get_width() != frame_width or frame.get_height() != frame_height:
			return {"ok": false, "error": "all output frames must have the same size"}

	var result: Image
	match layout:
		"horizontal_strip":
			result = Image.create_empty(frame_width * frames.size(), frame_height, false, Image.FORMAT_RGBA8)
			for frame_index in range(frames.size()):
				var frame := frames[frame_index] as Image
				result.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(frame_index * frame_width, 0))
		"vertical_strip":
			result = Image.create_empty(frame_width, frame_height * frames.size(), false, Image.FORMAT_RGBA8)
			for frame_index in range(frames.size()):
				var frame := frames[frame_index] as Image
				result.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(0, frame_index * frame_height))
		_:
			return {"ok": false, "error": "unsupported layout %s" % layout}
	return {"ok": true, "image": result}


func _write_preview(manifest_path: String, source_frames: Array) -> void:
	if _dry_run or source_frames.is_empty():
		return
	var preview_result := _encode_frames(source_frames, "horizontal_strip")
	if not preview_result.get("ok", false):
		return
	var preview_path := _join_path(_normalized_dir, manifest_path.get_file().get_basename() + ".png")
	(preview_result["image"] as Image).save_png(preview_path)


func _run_post_process(step: String, cleanup_superseded: bool) -> Dictionary:
	if step.begins_with(POST_PROCESS_ACTOR_SPRITEFRAMES_PREFIX):
		return _run_actor_spriteframes_post_process(step)

	match step:
		POST_PROCESS_OPERATOR_CURATED:
			if _dry_run:
				print("[DRY RUN] post_process %s" % step)
				return {"ok": true}
			var output: Array = []
			var exit_code := OS.execute(
				"godot",
				[
					"--headless",
					"--path",
					_project_root,
					"--log-file",
					_project_root.path_join(".godot/sprite_pipeline_post_process.log"),
					"--script",
					"res://tools/pipelines/update_operator_curated_resources.gd"
				],
				output,
				true
			)
			if exit_code != 0:
				return {"ok": false, "error": "operator curated rebuild failed:\n%s" % "\n".join(output)}
			return {"ok": true}
		POST_PROCESS_OPERATOR_MODULAR_RUNTIME:
			if _dry_run:
				print("[DRY RUN] post_process %s" % step)
				return {"ok": true}
			var build_output: Array = []
			var build_args := [
				ProjectSettings.globalize_path("res://tools/pipelines/build_operator_modular_runtime.py")
			]
			var build_exit_code := OS.execute(
				"python3",
				build_args,
				build_output,
				true
			)
			if build_exit_code != 0:
				return {"ok": false, "error": "operator modular runtime build failed:\n%s" % "\n".join(build_output)}
			var curated_output: Array = []
			var curated_exit_code := OS.execute(
				"godot",
				[
					"--headless",
					"--path",
					_project_root,
					"--log-file",
					_project_root.path_join(".godot/sprite_pipeline_post_process.log"),
					"--script",
					"res://tools/pipelines/update_operator_curated_resources.gd"
				],
				curated_output,
				true
			)
			if curated_exit_code != 0:
				return {"ok": false, "error": "operator modular SpriteFrames rebuild failed:\n%s" % "\n".join(curated_output)}
			if cleanup_superseded:
				var cleanup_output: Array = []
				var cleanup_exit_code := OS.execute(
					"python3",
					[
						ProjectSettings.globalize_path("res://tools/pipelines/build_operator_modular_runtime.py"),
						"--remove-superseded"
					],
					cleanup_output,
					true
				)
				if cleanup_exit_code != 0:
					return {"ok": false, "error": "operator modular cleanup failed:\n%s" % "\n".join(cleanup_output)}
			return {"ok": true}
		POST_PROCESS_ENEMY_RUNTIME_IMPORT:
			if _dry_run:
				print("[DRY RUN] post_process %s" % step)
				return {"ok": true}
			var output: Array = []
			var exit_code := OS.execute(
				"godot",
				[
					"--headless",
					"--path",
					_project_root,
					"--log-file",
					_project_root.path_join(".godot/sprite_pipeline_post_process.log"),
					"--import"
				],
				output,
				true
			)
			if exit_code != 0:
				return {"ok": false, "error": "enemy runtime import failed:\n%s" % "\n".join(output)}
			return {"ok": true}
		POST_PROCESS_VEHICLE_RUNTIME_IMPORT:
			if _dry_run:
				print("[DRY RUN] post_process %s" % step)
				return {"ok": true}
			var output: Array = []
			var exit_code := OS.execute(
				"godot",
				[
					"--headless",
					"--path",
					_project_root,
					"--log-file",
					_project_root.path_join(".godot/sprite_pipeline_post_process.log"),
					"--script",
					"res://tools/pipelines/update_vehicle_runtime_resources.gd"
				],
				output,
				true
			)
			if exit_code != 0:
				return {"ok": false, "error": "vehicle runtime rebuild failed:\n%s" % "\n".join(output)}
			return {"ok": true}
		_:
			return {"ok": false, "error": "unsupported post_process step %s" % step}


func _run_actor_spriteframes_post_process(step: String) -> Dictionary:
	var parts := step.split(":")
	if parts.size() != 3:
		return {"ok": false, "error": "actor_spriteframes post_process expects actor_spriteframes:<domain>:<owner>"}

	if _dry_run:
		print("[DRY RUN] post_process %s" % step)
		return {"ok": true}

	var output: Array = []
	var exit_code := OS.execute(
		"python3",
		[
			ProjectSettings.globalize_path("res://tools/pipelines/build_actor_spriteframes.py"),
			"--domain",
			str(parts[1]),
			"--owner",
			str(parts[2])
		],
		output,
		true
	)
	if exit_code != 0:
		return {"ok": false, "error": "actor SpriteFrames rebuild failed:\n%s" % "\n".join(output)}
	for line in output:
		print(line)
	return {"ok": true}


func _write_log(manifest_path: String, source_path: String, outputs: Array[String], post_process_steps: Array) -> void:
	if _dry_run:
		return
	var payload := {
		"timestamp_utc": Time.get_datetime_string_from_system(true, true),
		"manifest": _format_log_path(manifest_path),
		"source": _format_log_path(source_path),
		"outputs": outputs.map(func(path: String) -> String: return _format_log_path(path)),
		"post_process": post_process_steps
	}
	var log_path := _join_path(_logs_dir, manifest_path.get_file().get_basename() + ".log.json")
	var file := FileAccess.open(log_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload, "\t") + "\n")


func _archive_file(path: String) -> void:
	if _dry_run:
		return
	var target_path := _join_path(_archive_dir, path.get_file())
	if FileAccess.file_exists(target_path):
		DirAccess.remove_absolute(target_path)
	DirAccess.rename_absolute(path, target_path)


func _remove_source_import_sidecar(source_path: String) -> void:
	if _dry_run:
		return
	var import_path := source_path + ".import"
	if FileAccess.file_exists(import_path):
		DirAccess.remove_absolute(import_path)


func _resolve_input_path(path: String, base_dir: String = "") -> String:
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	if path.is_absolute_path():
		return path
	if base_dir.is_empty():
		return _join_path(_inbox_dir, path)
	return _join_path(base_dir, path)


func _resolve_manifest_arg(path: String) -> String:
	if path.begins_with("res://"):
		return path
	if path.is_absolute_path():
		return path
	var project_relative := _join_path(_project_root, path)
	if FileAccess.file_exists(project_relative):
		return ProjectSettings.localize_path(project_relative)
	return _join_path(_inbox_dir, path)


func _join_path(base: String, leaf: String) -> String:
	if base.ends_with("/"):
		return base + leaf
	return base + "/" + leaf


func _format_log_path(path: String) -> String:
	if path.begins_with("res://"):
		return path
	if path.begins_with(_project_root):
		return "res://" + path.trim_prefix(_project_root).trim_prefix("/")
	return path
