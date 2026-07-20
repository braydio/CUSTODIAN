extends Node

signal capabilities_changed(capabilities: Dictionary)

const SETTING_ENABLED := "custodian/dev/enabled"
const SETTING_HEAVY_DIAGNOSTICS := "custodian/dev/heavy_diagnostics"

var enabled := false
var debug_ui_enabled := false
var observatory_sampling_enabled := false
var heavy_diagnostics_enabled := false


func _ready() -> void:
	refresh()


func refresh() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_args():
		if not args.has(argument):
			args.append(argument)
	for argument in OS.get_cmdline_user_args():
		if not args.has(argument):
			args.append(argument)
	var resolved := resolve_capabilities(
		OS.is_debug_build(),
		OS.has_feature("custodian_dev"),
		bool(ProjectSettings.get_setting(SETTING_ENABLED, false)),
		args,
		bool(ProjectSettings.get_setting(SETTING_HEAVY_DIAGNOSTICS, false))
	)
	enabled = bool(resolved.get("enabled", false))
	debug_ui_enabled = bool(resolved.get("debug_ui_enabled", false))
	observatory_sampling_enabled = bool(resolved.get("observatory_sampling_enabled", false))
	heavy_diagnostics_enabled = bool(resolved.get("heavy_diagnostics_enabled", false))
	capabilities_changed.emit(get_capabilities())


func allows(capability: StringName) -> bool:
	match capability:
		&"dev", &"enabled":
			return enabled
		&"debug_ui":
			return debug_ui_enabled
		&"observatory_sampling":
			return observatory_sampling_enabled
		&"heavy_diagnostics":
			return heavy_diagnostics_enabled
		_:
			return false


func get_capabilities() -> Dictionary:
	return {
		"enabled": enabled,
		"debug_ui_enabled": debug_ui_enabled,
		"observatory_sampling_enabled": observatory_sampling_enabled,
		"heavy_diagnostics_enabled": heavy_diagnostics_enabled,
	}


static func resolve_capabilities(
	debug_build: bool,
	custodian_dev_feature: bool,
	project_enabled: bool,
	command_line_args: PackedStringArray,
	project_heavy_diagnostics: bool = false
) -> Dictionary:
	var explicitly_enabled := _has_any_arg(command_line_args, [
		"--custodian-dev", "--dev-mode", "--debug-ui", "--observe", "--heavy-diagnostics",
	])
	var base_enabled := debug_build or custodian_dev_feature or project_enabled or explicitly_enabled
	if _has_any_arg(command_line_args, ["--no-custodian-dev", "--no-dev-mode"]):
		base_enabled = false
	var debug_ui := base_enabled and not _has_any_arg(command_line_args, ["--no-debug-ui"])
	var observatory := base_enabled and not _has_any_arg(command_line_args, ["--no-observe"])
	var heavy := base_enabled \
		and (project_heavy_diagnostics or _has_any_arg(command_line_args, ["--heavy-diagnostics"])) \
		and not _has_any_arg(command_line_args, ["--no-heavy-diagnostics"])
	return {
		"enabled": base_enabled,
		"debug_ui_enabled": debug_ui,
		"observatory_sampling_enabled": observatory,
		"heavy_diagnostics_enabled": heavy,
	}


static func _has_any_arg(args: PackedStringArray, candidates: Array[String]) -> bool:
	for candidate in candidates:
		if args.has(candidate):
			return true
	return false
