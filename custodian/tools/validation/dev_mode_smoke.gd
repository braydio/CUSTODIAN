extends SceneTree

const DEV_MODE_SCRIPT := preload("res://game/systems/debug/dev_mode.gd")


func _init() -> void:
	var failures: Array[String] = []
	var release_default: Dictionary = DEV_MODE_SCRIPT.resolve_capabilities(
		false, false, false, PackedStringArray()
	)
	if bool(release_default.get("enabled", true)):
		failures.append("release default unexpectedly enabled developer mode")

	var debug_default: Dictionary = DEV_MODE_SCRIPT.resolve_capabilities(
		true, false, false, PackedStringArray()
	)
	if not bool(debug_default.get("debug_ui_enabled", false)):
		failures.append("debug build did not enable cheap developer UI")
	if bool(debug_default.get("heavy_diagnostics_enabled", true)):
		failures.append("debug build enabled heavy diagnostics without opt-in")

	var observed_release: Dictionary = DEV_MODE_SCRIPT.resolve_capabilities(
		false, false, false, PackedStringArray(["--observe"])
	)
	if not bool(observed_release.get("enabled", false)) or not bool(observed_release.get("observatory_sampling_enabled", false)):
		failures.append("--observe did not opt a release-style state into observatory capability")

	var heavy_release: Dictionary = DEV_MODE_SCRIPT.resolve_capabilities(
		false, false, false, PackedStringArray(["--heavy-diagnostics"])
	)
	if not bool(heavy_release.get("heavy_diagnostics_enabled", false)):
		failures.append("--heavy-diagnostics did not enable the heavy capability")

	var forced_off: Dictionary = DEV_MODE_SCRIPT.resolve_capabilities(
		true, true, true, PackedStringArray(["--no-dev-mode"]), true
	)
	if bool(forced_off.get("enabled", true)) or bool(forced_off.get("debug_ui_enabled", true)):
		failures.append("explicit disable did not override debug/feature/project enablement")

	var project := ConfigFile.new()
	if project.load("res://project.godot") != OK:
		failures.append("could not load project.godot")
	else:
		var keys := project.get_section_keys("autoload")
		if not keys.has("DevMode"):
			failures.append("DevMode autoload is missing")
		if keys.find("DevMode") < 0 or keys.find("DebugBus") < 0 or keys.find("DevMode") > keys.find("DebugBus"):
			failures.append("DevMode must load before debug systems")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("dev_mode_smoke ok")
	quit(0)
