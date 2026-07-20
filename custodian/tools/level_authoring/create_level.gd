extends SceneTree

const GENERATOR_SCRIPT := preload("res://tools/level_authoring/level_scaffold_generator.gd")


func _init() -> void:
	var parsed := _parse_args(OS.get_cmdline_user_args())
	if not bool(parsed.get("ok", false)):
		_finish(parsed, 2)
		return
	var generator: RefCounted = GENERATOR_SCRIPT.new()
	var result: Dictionary = generator.call("generate", parsed.request)
	var report_path := str(parsed.request.get("json_report_path", ""))
	if not report_path.is_empty():
		var resolved := ProjectSettings.globalize_path(report_path) if report_path.begins_with("res://") or report_path.begins_with("user://") else report_path
		DirAccess.make_dir_recursive_absolute(resolved.get_base_dir())
		var file := FileAccess.open(resolved, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(result, "  ") + "\n")
			file.close()
	_finish(result, 0 if bool(result.get("ok", false)) else 1)


func _parse_args(args: PackedStringArray) -> Dictionary:
	var request := {}
	var index := 0
	while index < args.size():
		var flag := args[index]
		if flag in ["--dry-run", "--no-register", "--force-generated", "--adopt-existing"]:
			match flag:
				"--dry-run": request.dry_run = true
				"--no-register": request.register_level = false
				"--force-generated": request.force_generated = true
				"--adopt-existing": request.adopt_existing = true
			index += 1
			continue
		if index + 1 >= args.size():
			return {"ok": false, "errors": PackedStringArray(["missing value for %s" % flag])}
		var value := args[index + 1]
		match flag:
			"--level-id": request.level_id = value
			"--display-name": request.display_name = value
			"--region": request.region = value
			"--class-name": request.class_name = value
			"--spawn-id": request.spawn_id = value
			"--return-spawn-id": request.return_spawn_id = value
			"--ingress-prompt": request.ingress_prompt = value
			"--world-context": request.world_context = value
			"--placement-strategy": request.placement_strategy = value
			"--placement-offset": request.placement_offsets = _parse_offsets(value)
			"--interaction-distance": request.interaction_distance = value.to_float()
			"--playtest-profile": request.playtest_profile = value
			"--canvas-size": request.canvas_size = _parse_size(value)
			"--output-root": request.output_root = value
			"--json-report": request.json_report_path = value
			_: return {"ok": false, "errors": PackedStringArray(["unknown option: %s" % flag])}
		index += 2
	return {"ok": true, "request": request}


func _parse_offsets(value: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pair in value.split(";"):
		var parts := pair.split(",")
		if parts.size() == 2: result.append(Vector2i(parts[0].to_int(), parts[1].to_int()))
	return result


func _parse_size(value: String) -> Vector2i:
	var parts := value.to_lower().split("x")
	return Vector2i(parts[0].to_int(), parts[1].to_int()) if parts.size() == 2 else Vector2i.ZERO


func _finish(result: Dictionary, code: int) -> void:
	print(JSON.stringify(result, "  "))
	quit(code)
