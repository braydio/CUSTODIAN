extends SceneTree

const PREVIEW_SCENE := preload("res://scenes/debug/operator_3d_animation_preview_awakening.tscn")
const OBSTRUCTION_PATH := NodePath("Awakening/World/AwakeningZones/Zone03_Attestation/SetPieces/RuinFloorCrackC")
const OBSTRUCTION_TEXTURE := "res://content/tiles/awakening/ruin_decals/awakening_ruin_decal_floor_crack_c_64.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var arg_index := args.find("--request")
	if arg_index < 0 or arg_index + 1 >= args.size():
		_fail("comparison smoke requires --request res://.ai/.../comparison_request.json")
		return
	var request_path := String(args[arg_index + 1])
	var preview := PREVIEW_SCENE.instantiate()
	root.add_child(preview)
	await process_frame
	await process_frame
	var obstruction := preview.get_node_or_null(OBSTRUCTION_PATH)
	var obstruction_result := {"state": "already_absent_from_scene"}
	if obstruction != null:
		if not obstruction is Sprite2D:
			_fail("obstruction path resolves to a non-Sprite2D node")
			return
		var prop := obstruction as Sprite2D
		if prop.texture == null or prop.texture.resource_path != OBSTRUCTION_TEXTURE or prop.position != Vector2(0.0, -1872.0):
			_fail("obstruction identity/transform differs; refusing to hide an unexpected scene object")
			return
		var was_visible := prop.visible
		prop.visible = false
		if prop.visible:
			_fail("temporary obstruction suppression failed")
			return
		obstruction_result = {
			"state": "temporarily_hidden_for_comparison_capture",
			"path": String(OBSTRUCTION_PATH),
			"texture": prop.texture.resource_path,
			"authored_position": [prop.position.x, prop.position.y],
			"was_visible": was_visible,
			"collision_owner": "none; Sprite2D detail only",
		}
	var report: Dictionary = preview.call("run_awakening_smoke_check")
	report["comparison_background_obstruction"] = obstruction_result
	var output_path := request_path.get_base_dir().path_join("comparison_smoke_result.json")
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	if output == null:
		_fail("could not write comparison smoke result")
		return
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	if report.get("ok") != true:
		_fail(String(report.get("error", "preview or accepted-source smoke failed")))
		return
	if report.get("preview", {}).get("accepted_2d_source_checked_frames") != 120:
		_fail("smoke did not verify all 120 accepted 2.5D frames")
		return
	if report.get("preview", {}).get("candidate_sprite_scale") != [1.0, 1.0] or report.get("preview", {}).get("candidate_sprite_position") != [0.0, -42.0]:
		_fail("candidate is not aligned to the accepted 128px presentation transform")
		return
	print("operator_3d_animation_comparison_smoke: PASS ", JSON.stringify(report))
	quit(0)


func _fail(message: String) -> void:
	push_error("operator_3d_animation_comparison_smoke: " + message)
	quit(1)
