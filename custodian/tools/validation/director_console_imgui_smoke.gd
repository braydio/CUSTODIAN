extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame

	var bus := root.get_node_or_null("DebugBus")
	var collector := root.get_node_or_null("DebugSnapshotCollector")
	var console := root.get_node_or_null("DebugImguiConsole")
	var imgui := root.get_node_or_null("ImGui")

	assert(bus != null, "DebugBus autoload missing.")
	assert(collector != null, "DebugSnapshotCollector autoload missing.")
	assert(console != null, "DebugImguiConsole autoload missing.")
	assert(imgui != null, "Dear ImGui autoload missing.")
	assert(imgui.has_signal("imgui_layout"), "Dear ImGui autoload does not expose imgui_layout.")

	bus.set("enabled", true)
	bus.call("set_category", "WORLD", {
		"seed": 12345,
		"profile": "smoke",
		"terrain_connectivity": true,
		"terrain_fallback": false,
		"required_cell_count": 8,
		"missing_required_count": 0,
		"rescue_carved_cells": 0,
		"generation_mode": "SMOKE",
	})
	bus.call("set_category", "SECTORS", [{
		"name": "Gate",
		"threat": "LOW",
		"enemy_count": 0,
		"power": "ON",
		"defenses": "1/1",
		"damage_pct": 0,
		"pathable": true,
	}])
	bus.call("push_event", "PROCGEN", "smoke event")
	bus.call("set_debug_override", "slowmo", true)
	bus.call("queue_command", {"type": "smoke_command"})

	assert(bool(bus.get("enabled")), "DebugBus did not enable.")
	assert((bus.get("stats") as Dictionary).has("WORLD"), "DebugBus WORLD category missing.")
	assert((bus.get("events") as Array).size() == 1, "DebugBus event history did not record enabled event.")
	assert(bool((bus.get("debug_overrides") as Dictionary).get("slowmo", false)), "Debug override not stored.")

	var commands: Array = bus.call("drain_commands")
	assert(commands.size() == 1 and (commands[0] as Dictionary).get("type", "") == "smoke_command", "Queued debug command did not drain.")
	assert((bus.get("command_queue") as Array).is_empty(), "Debug command queue did not clear after drain.")

	print("[DirectorConsoleImguiSmoke] PASS")
	quit(0)
