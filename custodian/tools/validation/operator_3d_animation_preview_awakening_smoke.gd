extends SceneTree

const PREVIEW_SCENE := preload("res://scenes/debug/operator_3d_animation_preview_awakening.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var arg_index := args.find("--request")
	if arg_index < 0 or arg_index + 1 >= args.size():
		push_error("Awakening preview smoke requires --request res://.ai/.../request.json")
		quit(2)
		return
	var preview := PREVIEW_SCENE.instantiate()
	root.add_child(preview)
	await process_frame
	await process_frame
	var report: Dictionary = preview.call("run_awakening_smoke_check")
	var output_path := String(args[arg_index + 1]).get_base_dir().path_join("awakening_smoke_result.json")
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("cannot write Awakening preview smoke result")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	if report.get("ok") != true:
		push_error("Awakening preview smoke failed: " + String(report.get("error", "unknown failure")))
		quit(1)
		return
	print("operator_3d_animation_preview_awakening_smoke: PASS ", JSON.stringify(report))
	quit(0)
