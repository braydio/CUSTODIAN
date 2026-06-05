extends SceneTree

const SUNDERED_KEEP_MAP := preload("res://game/world/sundered_keep/sundered_keep_map.gd")
const DEFAULT_OUTPUT_PATH := "res://artifacts/sundered_keep/sundered_keep_map_cli.png"
const TILE_SIZE := 32.0
const SCREENSHOT_PADDING := 128


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_path := _parse_output_path(OS.get_cmdline_user_args())
	var map := SUNDERED_KEEP_MAP.new()
	var viewport := SubViewport.new()
	var map_size := map.map_size_tiles
	var viewport_size := Vector2i(
		int(float(map_size.x) * TILE_SIZE) + (SCREENSHOT_PADDING * 2),
		int(float(map_size.y) * TILE_SIZE) + (SCREENSHOT_PADDING * 2)
	)

	viewport.name = "SunderedKeepScreenshotViewport"
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	map.name = "SunderedKeepScreenshotMap"
	map.position = Vector2(SCREENSHOT_PADDING, SCREENSHOT_PADDING)
	viewport.add_child(map)
	await process_frame

	var hud := map.get_node_or_null("SunderedKeepCustodianHUD")
	if hud != null:
		hud.visible = false

	for _frame in range(6):
		RenderingServer.force_draw(false)
		await process_frame

	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("[SunderedKeepScreenshot] Viewport capture returned an empty image.")
		quit(1)
		return

	var absolute_output := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	var result := image.save_png(absolute_output)
	if result != OK:
		push_error("[SunderedKeepScreenshot] Failed to save %s: %s" % [absolute_output, error_string(result)])
		quit(1)
		return

	print("[SunderedKeepScreenshot] Saved %s (%dx%d)" % [absolute_output, image.get_width(), image.get_height()])
	quit()


func _parse_output_path(args: PackedStringArray) -> String:
	for index in range(args.size()):
		if args[index] == "--output" and index + 1 < args.size():
			return args[index + 1]
	return DEFAULT_OUTPUT_PATH
