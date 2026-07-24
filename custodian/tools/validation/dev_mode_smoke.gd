extends SceneTree

const DEV_MODE_SCRIPT := preload("res://game/systems/debug/dev_mode.gd")
const CAMERA_SCRIPT := preload("res://game/world/camera.gd")
const OPERATOR_SCRIPT := preload(
	"res://game/actors/operator/operator.gd"
)


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

	for action_key in [
		["debug_free_camera", KEY_F6],
		["debug_infinite_health", KEY_F7],
		["debug_infinite_stamina", KEY_F8],
	]:
		var action := StringName(action_key[0])
		var keycode := action_key[1] as Key
		if not InputMap.has_action(action):
			failures.append("%s input action missing" % String(action))
		elif not _action_contains_key(action, keycode):
			failures.append(
				"%s must use %s" % [String(action), OS.get_keycode_string(keycode)]
			)

	for method_name in [
		"set_debug_free_camera_enabled",
		"set_infinite_health_enabled",
		"set_infinite_stamina_enabled",
		"get_playtest_controls",
	]:
		if not _script_has_method(DEV_MODE_SCRIPT, method_name):
			failures.append("DevMode missing %s" % method_name)

	var camera := CAMERA_SCRIPT.new() as CameraController
	camera.set_debug_free_camera_enabled(true)
	if not camera.is_debug_free_camera_enabled() or camera.follow_enabled:
		failures.append("CameraController did not enter free-camera mode")
	camera.set_debug_free_camera_enabled(false)
	if camera.is_debug_free_camera_enabled() or not camera.follow_enabled:
		failures.append("CameraController did not restore follow mode")
	camera.free()

	if not _script_has_method(
		OPERATOR_SCRIPT,
		"apply_debug_resource_overrides"
	):
		failures.append("Operator missing debug resource override hook")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("dev_mode_smoke ok")
	quit(0)


func _action_contains_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey \
				and (event as InputEventKey).keycode == keycode:
			return true
	return false


func _script_has_method(script: Script, method_name: String) -> bool:
	for method in script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return true
	return false
