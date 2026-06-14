extends RefCounted
class_name TerminalCommandRouter


const VALID_VERBS := {
	"HELP": true, "STATUS": true, "ENEMIES": true, "WAVE": true, "SECTORS": true,
	"CONTRACT": true, "PLANET": true, "MAP": true, "CLEAR": true, "WALL": true,
	"START": true, "OVERLAY": true, "ALLOCATE_DEFENSE": true, "DEPLOY": true, "FOCUS": true,
	"TURRET": true, "REROUTE": true, "GOTO": true, "WAIT": true, "HARDEN": true,
	"REPAIR": true, "MOVE": true, "RETURN": true, "SYNC": true, "LOCKDOWN": true,
	"FORTIFY": true, "BOOST": true, "SCAN": true, "STABILIZE": true, "PRIORITIZE": true,
	"DRONE": true, "POLICY": true, "CONFIG": true, "SET": true, "FAB": true, "BUILD": true, "SCAVENGE": true,
}

const SNAPSHOT_REFRESH_VERBS := [
	"STATUS", "ENEMIES", "WAVE", "SECTORS", "CONTRACT", "PLANET", "MAP",
	"START", "WALL", "TURRET",
	"WAIT", "RESET", "REBOOT", "SET", "FAB", "BUILD", "CONFIG",
	"FOCUS", "HARDEN", "SCAVENGE", "REPAIR", "DEPLOY",
	"MOVE", "RETURN", "SYNC", "LOCKDOWN", "OVERLAY", "ALLOCATE_DEFENSE", "REROUTE",
]


func parse(command: String) -> Dictionary:
	var normalized := command.strip_edges().to_upper()
	var tokens := normalized.split(" ", false)
	var verb := tokens[0] if not tokens.is_empty() else ""
	var args: Array[String] = []
	var params: Dictionary = {}
	for i in range(1, tokens.size()):
		var token := str(tokens[i])
		if token.contains("="):
			var parts := token.split("=", false, 1)
			if parts.size() == 2:
				params[str(parts[0]).to_lower()] = str(parts[1])
		else:
			args.append(token)
	return {
		"raw": command,
		"normalized": normalized,
		"verb": verb,
		"args": args,
		"params": params,
	}


func is_known_verb(verb: String) -> bool:
	return VALID_VERBS.has(verb.strip_edges().to_upper())


func should_refresh_snapshot(command_upper: String) -> bool:
	var verb := command_upper.split(" ", false, 1)[0]
	return verb in SNAPSHOT_REFRESH_VERBS


func execute(ui: Node, parsed: Dictionary) -> bool:
	# Temporary compatibility bridge: command parsing/validation now lives here,
	# while the legacy command handlers are migrated command-by-command.
	if ui.has_method("_execute_local_terminal_command_legacy"):
		return bool(ui.call("_execute_local_terminal_command_legacy", parsed))
	return false
