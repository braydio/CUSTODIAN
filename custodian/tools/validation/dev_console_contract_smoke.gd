extends SceneTree
## Focused coverage for the native Developer Shell's command-registry
## contract: the legacy `add_command`/`add_signal`/`callv(parts)` behaviors
## the HUD adapter depends on, plus DevMode gating.
##
## All access to the `/root/DevConsole` and `/root/DevMode` autoloads goes
## through `call`/`get`/`set`/`has_method`, matching the duck-typed access
## pattern already used elsewhere (`debug_screen.gd::_dev_allows`), because a
## statically Node-typed reference has no compile-time knowledge of either
## autoload's script members.

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var console := root.get_node_or_null("DevConsole")
	var dev_mode := root.get_node_or_null("DevMode")
	_assert_true(console != null, "DevConsole autoload should exist at /root/DevConsole")
	_assert_true(dev_mode != null, "DevMode autoload should exist at /root/DevMode")
	if console == null or dev_mode == null:
		_finish()
		return

	_check_variadic_contract(console)
	_check_metadata_contract(console)
	_check_exactly_once(console)
	_check_unknown_command(console)
	_check_invalid_callback(console)
	_check_command_replacement(console)
	_check_builtin_and_custom_coexist(console)
	await _check_gating(console, dev_mode)
	await _check_input_suppression()

	_finish()


## GDScript lambdas capture outer locals by value, not by reference --
## reassigning a captured variable inside a lambda never propagates back out.
## Every closure below that needs to report back mutates a shared Dictionary
## in place instead of reassigning a captured local.
func _check_variadic_contract(console: Node) -> void:
	var observed := {"args": []}
	var handler := func(...args):
		observed["args"] = args
		return "echoed:%s" % ", ".join(args)
	console.call("add_command", "smoke_echo", handler)
	_assert_true(bool(console.call("has_command", "smoke_echo")), "add_command should register the command")
	var result := String(console.call("execute_line", "smoke_echo a b c"))
	_assert_true(result == "echoed:a, b, c", "variadic callback should receive original args, got '%s'" % result)
	_assert_true((observed["args"] as Array).size() == 3, "handler should see 3 individual positional args, not one Array")


func _check_metadata_contract(console: Node) -> void:
	# Two-argument legacy call shape must remain valid alongside the new
	# optional third `metadata` argument. Handlers are variadic because
	# `execute_line` always dispatches via `callv(parts)`, where `parts` may
	# be empty -- a fixed-arity handler would raise a too-few-arguments error.
	console.call("add_command", "smoke_legacy", func(...args): return "ok")
	_assert_true(bool(console.call("has_command", "smoke_legacy")), "two-argument add_command should still work")

	console.call("add_command", "smoke_meta", func(...args): return "ok", {
		"category": "TEST", "usage": "smoke_meta", "description": "test command",
	})
	var meta: Dictionary = console.call("get_command_metadata", "smoke_meta")
	_assert_true(String(meta.get("category", "")) == "TEST", "metadata should round-trip through add_command")


func _check_exactly_once(console: Node) -> void:
	var observed := {"calls": 0}
	console.call("add_command", "smoke_once", func(...args):
		observed["calls"] = int(observed["calls"]) + 1
		return "ran")
	console.call("execute_line", "smoke_once")
	_assert_true(int(observed["calls"]) == 1, "execute_line should invoke the handler exactly once, called %d times" % int(observed["calls"]))


func _check_unknown_command(console: Node) -> void:
	var result := String(console.call("execute_line", "smoke_does_not_exist"))
	_assert_true(result.begins_with("Unknown command"), "unknown command should produce a readable error, got '%s'" % result)


func _check_invalid_callback(console: Node) -> void:
	console.call("add_command", "smoke_stale", Callable(RefCounted.new(), "nonexistent_method"))
	var result := String(console.call("execute_line", "smoke_stale"))
	_assert_true(result.contains("no longer available"), "invalid callback should fail gracefully, got '%s'" % result)
	_assert_true(not bool(console.call("has_command", "smoke_stale")), "invalid callback should be pruned from the registry")


func _check_command_replacement(console: Node) -> void:
	var observed := {"first": 0, "second": 0}
	console.call("add_command", "smoke_replace", func(...args):
		observed["first"] = int(observed["first"]) + 1
		return "first")
	console.call("add_command", "smoke_replace", func(...args):
		observed["second"] = int(observed["second"]) + 1
		return "second")
	var result := String(console.call("execute_line", "smoke_replace"))
	_assert_true(result == "second", "re-registering a command should replace the previous callback, got '%s'" % result)
	_assert_true(int(observed["first"]) == 0 and int(observed["second"]) == 1, "only the latest registration should run")


## This SceneTree-only harness never instantiates the HUD scene, so it cannot
## observe `ui.gd`'s real `_register_devconsole_commands()` call. It instead
## registers through the identical adapter shape ui.gd uses
## (`console.add_command(name, func(...args): return handler.call(args))`)
## to prove built-ins and HUD-style commands share one registry and both
## surface through `help`.
func _check_builtin_and_custom_coexist(console: Node) -> void:
	_assert_true(bool(console.call("has_command", "help")), "built-in help command should exist")
	_assert_true(bool(console.call("has_command", "clear")), "built-in clear command should exist")

	var handler := func(_args: Array) -> String:
		return "HUD-style command ran"
	console.call("add_command", "smoke_hud_style", func(...args): return handler.call(args))
	_assert_true(bool(console.call("has_command", "smoke_hud_style")), "HUD-style registration should coexist with built-ins")

	var help_text := String(console.call("execute_line", "help"))
	_assert_true(help_text.contains("smoke_hud_style"), "help overview should list HUD-style commands too")
	_assert_true(help_text.contains("HELP") or help_text.contains("SYSTEM"), "help overview should still list built-in categories")


func _check_gating(console: Node, dev_mode: Node) -> void:
	var original: bool = bool(dev_mode.get("debug_ui_enabled"))

	dev_mode.set("debug_ui_enabled", false)
	console.call("open_console")
	_assert_true(not bool(console.call("is_open")), "console should refuse to open when DevMode denies debug_ui")
	var denied := String(console.call("execute_line", "help"))
	_assert_true(denied == "Developer commands unavailable.", "public execution API should be gated, got '%s'" % denied)

	dev_mode.set("debug_ui_enabled", true)
	console.call("open_console")
	_assert_true(bool(console.call("is_open")), "console should open once debug_ui is allowed")
	await process_frame

	dev_mode.set("debug_ui_enabled", false)
	dev_mode.emit_signal("capabilities_changed", dev_mode.call("get_capabilities"))
	_assert_true(not bool(console.call("is_open")), "revoking capability while open should close the console immediately")

	dev_mode.set("debug_ui_enabled", original)
	dev_mode.emit_signal("capabilities_changed", dev_mode.call("get_capabilities"))


## `sample_suppressed()` is the seam `Operator._sample_input_frame()` uses
## while the developer shell owns keyboard focus. It must report no activity
## to gameplay, and holding a key across the suppression window must not
## manufacture a `just_pressed` edge once ordinary sampling resumes -- that is
## the "phantom attack on close" bug this method exists to prevent.
##
## `Input.is_action_just_pressed()` only becomes true one engine frame after
## `Input.action_press()`, and only reads true for that one frame. Realistic
## usage has the press observed on its own tick (just_pressed), several real
## frames of suppression while the console is open and the key stays held,
## then resumed sampling once it closes -- by which point the engine's own
## just-pressed window has long since expired and only the router's
## `_previous_pressed` bookkeeping stands between the key and a phantom edge.
## Each `await process_frame` below is load-bearing for that reason, not
## decorative: without it the press/suppress/resume calls could land inside
## the same engine frame as the original edge, which is not the scenario this
## test exists to prove.
func _check_input_suppression() -> void:
	var router := OperatorInputRouter.new()
	Input.action_release(&"dodge")
	router.sample(false, 0.25, 0)
	await process_frame

	Input.action_press(&"dodge")
	await process_frame
	var pressed_tick := router.sample(false, 0.25, 0)
	_assert_true(pressed_tick.just_pressed(&"dodge"), "setup: the press should be observed as an edge on its own tick")

	await process_frame
	await process_frame
	var suppressed := router.sample_suppressed(0)
	_assert_true(not suppressed.pressed(&"dodge"), "a suppressed frame must not report the held action as pressed")
	_assert_true(not suppressed.just_pressed(&"dodge"), "a suppressed frame must report no press edge")
	_assert_true(not suppressed.has_any_activity(), "a suppressed frame must report no activity at all")

	await process_frame
	await process_frame

	# The key is still physically held when suppression ends.
	var resumed := router.sample(false, 0.25, 0)
	_assert_true(resumed.pressed(&"dodge"), "a key held through suppression must read as held once sampling resumes")
	_assert_true(
		not resumed.just_pressed(&"dodge"),
		"a key already down before/through suppression must not manufacture a just_pressed edge on resume"
	)

	Input.action_release(&"dodge")
	await process_frame
	router.sample(false, 0.25, 0)


func _finish() -> void:
	if _failed:
		push_error("dev_console_contract_smoke failed")
		quit(1)
		return
	print("dev_console_contract_smoke ok")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
