extends SceneTree

const ROOT := "res://content/ui/black_reliquary"

const REQUIRED_ASSETS := [
	"panels/ui_panel_9slice_dark_gold.png",
	"panels/ui_panel_9slice_deep.png",
	"icons/icon_gate_locked.png",
	"icons/icon_gate_open.png",
	"icons/icon_return_mooring.png",
	"icons/icon_key_item.png",
	"icons/icon_objective.png",
	"icons/compass_rose_small.png",
	"minimap/minimap_fill_dark.png",
]

const REQUIRED_SCENES := [
	"res://game/ui/hud/custodian_hud.tscn",
	"res://game/ui/components/black_reliquary_panel.tscn",
	"res://game/ui/components/black_reliquary_prompt.tscn",
	"res://game/ui/components/black_reliquary_minimap_frame.tscn",
	"res://game/ui/minimap/minimap_panel.tscn",
]


func _initialize() -> void:
	var failures: Array[String] = []
	if not DirAccess.dir_exists_absolute(ROOT):
		failures.append("Missing UI root: %s" % ROOT)
	for relative_path in REQUIRED_ASSETS:
		var path := "%s/%s" % [ROOT, relative_path]
		if not _resource_or_file_exists(path):
			failures.append("Missing required asset: %s" % path)
	if not _prompt_assets_exist():
		failures.append("Missing prompt assets under either %s/prompts or %s/prompt" % [ROOT, ROOT])
	if not _minimap_assets_exist():
		failures.append("Missing minimap asset directory or minimap fill")
	for scene_path in REQUIRED_SCENES:
		if not ResourceLoader.exists(scene_path):
			failures.append("Missing scene: %s" % scene_path)
			continue
		var packed := load(scene_path)
		if not (packed is PackedScene):
			failures.append("Scene did not load as PackedScene: %s" % scene_path)
	if failures.is_empty():
		print("[BlackReliquaryUISmoke] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[BlackReliquaryUISmoke] %s" % failure)
		quit(1)


func _prompt_assets_exist() -> bool:
	for root_name in ["prompts", "prompt"]:
		var prefix := "%s/%s" % [ROOT, root_name]
		if (
			_resource_or_file_exists(prefix + "/plaque_header_small.png")
			and _resource_or_file_exists(prefix + "/plaque_body_small.png")
			and _resource_or_file_exists(prefix + "/input_key_badge.png")
		):
			return true
	return false


func _minimap_assets_exist() -> bool:
	return DirAccess.dir_exists_absolute(ROOT + "/minimap") and _resource_or_file_exists(ROOT + "/minimap/minimap_fill_dark.png")


func _resource_or_file_exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)
