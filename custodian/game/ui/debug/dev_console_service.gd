extends CanvasLayer
## Autoload registry/execution authority for the native Developer Shell.
##
## Replaces the third-party `dev-console` addon as the public `/root/DevConsole`
## node. Every existing HUD command registration (`add_command`, `add_signal`,
## the variadic `callv(parts)` dispatch contract) keeps working unchanged --
## this is the thing callers depend on, not the presentation.
##
## This service owns the command registry, execution, bounded output/history
## buffers, and DevMode capability gating. It does not own gameplay simulation,
## spawning, inventory, or world-state authority: commands only request those
## through the handlers callers register.
##
## Authority: design/02_features/debug_ui/DEBUG_DEV_UI_SYSTEM.md

signal console_opened()
signal console_closed()
signal command_executed(command_name: String, raw_line: String, result: String)
signal output_appended(entry: Dictionary)

const PANEL_SCENE := preload("res://game/ui/debug/dev_console_panel.tscn")

const MAX_OUTPUT_ENTRIES := 250
const MAX_HISTORY_ENTRIES := 100
const MAX_OUTPUT_CHARS := 4096
const TOGGLE_KEYCODE := KEY_QUOTELEFT

const LEVEL_INPUT := "INPUT"
const LEVEL_ERROR := "ERROR"
const LEVEL_RESULT := "RESULT"

var _commands: Dictionary = {}
var _command_metadata: Dictionary = {}
var _history: Array[String] = []
var _output: Array[Dictionary] = []
var _open := false
var _panel: Control = null
var _session_clock := 0.0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_unhandled_key_input(true)
	_register_builtin_commands()
	var dev_mode := get_node_or_null("/root/DevMode")
	if dev_mode != null and dev_mode.has_signal("capabilities_changed"):
		dev_mode.capabilities_changed.connect(_on_dev_mode_capabilities_changed)


func _process(delta: float) -> void:
	_session_clock += delta


func _unhandled_key_input(event: InputEvent) -> void:
	if not _allows_debug_ui():
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == TOGGLE_KEYCODE or key_event.physical_keycode == TOGGLE_KEYCODE:
		toggle_console()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Command registry -- preserves the legacy addon's public contract exactly.
# ---------------------------------------------------------------------------

func add_command(command_name: String, callback: Callable, metadata: Dictionary = {}) -> void:
	var key := command_name.strip_edges().to_lower()
	if key.is_empty():
		return
	_commands[key] = callback
	_command_metadata[key] = metadata.duplicate(true)


func add_signal(signal_name: String, target_signal: Signal) -> void:
	target_signal.connect(func(...args): _append_signal_output(signal_name, args))


func has_command(command_name: String) -> bool:
	return _commands.has(command_name.strip_edges().to_lower())


func get_command_names() -> PackedStringArray:
	var names := PackedStringArray()
	for key in _commands.keys():
		names.append(key)
	names.sort()
	return names


func get_matching_commands(prefix: String) -> PackedStringArray:
	var needle := prefix.strip_edges().to_lower()
	var matches := PackedStringArray()
	if needle.is_empty():
		return matches
	for name in get_command_names():
		if name.begins_with(needle):
			matches.append(name)
	return matches


func get_command_metadata(command_name: String) -> Dictionary:
	return _command_metadata.get(command_name.strip_edges().to_lower(), {}).duplicate(true)


# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------

## Preserves the legacy behavioral baseline: `callv(parts)`, one return-value
## presentation, invalid callbacks pruned rather than crashing. Do not replace
## `callback.callv(parts)` with `callback.call(parts)` -- the HUD adapter wraps
## every handler as `func(...args): return handler.call(args)`, which expects
## individual positional arguments, not one Array argument.
func execute_line(line: String) -> String:
	if not _allows_debug_ui():
		var denied := "Developer commands unavailable."
		append_output(LEVEL_ERROR, "SYSTEM", denied)
		return denied
	var clean := line.strip_edges()
	if clean.is_empty():
		return ""
	append_output(LEVEL_INPUT, "SYSTEM", "> " + clean)
	_push_history(clean)
	var parts := clean.split(" ", false)
	if parts.is_empty():
		return ""
	var command_name := parts[0].to_lower()
	parts.remove_at(0)
	var result_text := _dispatch(command_name, parts)
	if not result_text.is_empty():
		var category := String(_command_metadata.get(command_name, {}).get("category", "GENERAL")).to_upper()
		var level := LEVEL_ERROR if _looks_like_failure(result_text) else LEVEL_RESULT
		append_output(level, category, result_text)
	command_executed.emit(command_name, clean, result_text)
	return result_text


func _dispatch(command_name: String, args: PackedStringArray) -> String:
	if not _commands.has(command_name):
		return "Unknown command: %s" % command_name
	var callback: Callable = _commands[command_name]
	if not callback.is_valid():
		_commands.erase(command_name)
		_command_metadata.erase(command_name)
		return "Command handler is no longer available."
	var result: Variant = callback.callv(Array(args))
	return "" if result == null else str(result)


## Legacy handlers return plain strings with no structured success/failure
## flag, so this is a heuristic over the handful of phrasings those handlers
## already use (grep-verified against `ui.gd`), not a generic parser.
func _looks_like_failure(result_text: String) -> bool:
	return result_text.begins_with("Unknown command") \
		or result_text.contains("no longer available") \
		or result_text.begins_with("Failed") \
		or result_text.contains("not found")


func _push_history(line: String) -> void:
	if _history.is_empty() or _history.back() != line:
		_history.append(line)
	while _history.size() > MAX_HISTORY_ENTRIES:
		_history.pop_front()


func get_history() -> Array[String]:
	return _history.duplicate(true)


# ---------------------------------------------------------------------------
# Output buffering
# ---------------------------------------------------------------------------

func append_output(level: String, category: String, message: String) -> Dictionary:
	var text := message
	if text.length() > MAX_OUTPUT_CHARS:
		text = text.substr(0, MAX_OUTPUT_CHARS) + "\n…(truncated)"
	var entry := {
		"time": _session_clock,
		"level": level,
		"category": category,
		"message": text,
	}
	_output.append(entry)
	while _output.size() > MAX_OUTPUT_ENTRIES:
		_output.pop_front()
	output_appended.emit(entry)
	return entry


func get_output() -> Array[Dictionary]:
	return _output.duplicate(true)


func _append_signal_output(signal_name: String, args: Array) -> void:
	var arg_text := ", ".join(args.map(func(a): return str(a)))
	append_output(LEVEL_RESULT, "SIGNAL", "%s(%s)" % [signal_name, arg_text])


# ---------------------------------------------------------------------------
# Open/close + gating
# ---------------------------------------------------------------------------

func open_console() -> void:
	if _open:
		return
	if not _allows_debug_ui():
		return
	if _gameplay_terminal_open():
		return
	_ensure_panel()
	_open = true
	_panel.call("present_opened")
	console_opened.emit()


func close_console() -> void:
	if not _open:
		return
	_open = false
	if _panel != null and is_instance_valid(_panel):
		_panel.call("present_closed")
	console_closed.emit()


func toggle_console() -> void:
	if _open:
		close_console()
	else:
		open_console()


func is_open() -> bool:
	return _open


func clear_output() -> void:
	_output.clear()
	if _panel != null and is_instance_valid(_panel):
		_panel.call("render_output")


func _ensure_panel() -> void:
	if _panel != null and is_instance_valid(_panel):
		return
	_panel = PANEL_SCENE.instantiate() as Control
	_panel.name = "ConsoleView"
	add_child(_panel)
	_panel.call("bind_service", self)


func _allows_debug_ui() -> bool:
	var dev_mode := get_node_or_null("/root/DevMode")
	return dev_mode != null and dev_mode.has_method("allows") and bool(dev_mode.call("allows", &"debug_ui"))


## The gameplay command terminal (`ui.gd`'s in-world terminal, distinct from
## this developer shell) owns its own modal focus. The developer shell must
## not steal keyboard focus from it, so it refuses to open while the terminal
## is up; `ui.gd` closes this shell on its side when the terminal opens.
func _gameplay_terminal_open() -> bool:
	for host in get_tree().get_nodes_in_group(&"gameplay_command_terminal_host"):
		if is_instance_valid(host) and host.has_method("is_terminal_open") and bool(host.call("is_terminal_open")):
			return true
	return false


func _on_dev_mode_capabilities_changed(_capabilities: Dictionary) -> void:
	if _open and not _allows_debug_ui():
		close_console()


# ---------------------------------------------------------------------------
# Built-in commands
# ---------------------------------------------------------------------------

## `_dispatch` always calls through `callv(parts)`, which unpacks `parts` as
## individual positional arguments -- the same convention the HUD adapter's
## `func(...args): return handler.call(args)` wrapper exists to satisfy. A
## built-in registered as a bare `Callable(self, "_cmd_help")` would be
## fixed-arity and error out whenever a caller passed a different argument
## count (most commonly zero), so built-ins are wrapped the same way.
func _register_builtin_commands() -> void:
	add_command("help", func(...args): return _cmd_help(args), {
		"category": "SYSTEM",
		"usage": "help [command]",
		"description": "List commands by category, or show usage for one command.",
	})
	add_command("clear", func(...args): return _cmd_clear(args), {
		"category": "SYSTEM",
		"usage": "clear",
		"description": "Clear the visible output.",
	})
	add_command("cls", func(...args): return _cmd_clear(args), {
		"category": "SYSTEM",
		"usage": "cls",
		"description": "Alias for clear.",
	})
	add_command("history", func(...args): return _cmd_history(args), {
		"category": "SYSTEM",
		"usage": "history",
		"description": "Show recently submitted commands.",
	})


func _cmd_help(args: Array) -> String:
	if args.size() > 0:
		var target := str(args[0]).strip_edges().to_lower()
		if not _commands.has(target):
			return "Unknown command: %s" % target
		var meta := get_command_metadata(target)
		var usage := String(meta.get("usage", target))
		var description := String(meta.get("description", "No description available."))
		return "%s\nUsage: %s\n%s" % [target.to_upper(), usage, description]
	var by_category: Dictionary = {}
	for name in get_command_names():
		var category := String(_command_metadata.get(name, {}).get("category", "GENERAL")).to_upper()
		var bucket: Array = by_category.get(category, [])
		bucket.append(name)
		by_category[category] = bucket
	var categories := by_category.keys()
	categories.sort()
	var lines: Array[String] = []
	for category in categories:
		var names: Array = by_category[category]
		names.sort()
		lines.append("%s: %s" % [category, ", ".join(names)])
	return "\n".join(lines)


func _cmd_clear(_args: Array) -> String:
	clear_output()
	return ""


func _cmd_history(_args: Array) -> String:
	if _history.is_empty():
		return "No command history."
	return "\n".join(_history)
