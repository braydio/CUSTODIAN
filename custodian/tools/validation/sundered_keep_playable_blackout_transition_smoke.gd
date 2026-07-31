extends SceneTree

const ROUTE_PATH := "res://content/routes/sundered_keep/sundered_keep_route.json"
const MANAGER_PATH := "res://game/world/routes/route_traversal_manager.gd"
const INGRESS_PATH := "res://game/world/procgen/ingress/world_ingress_site.gd"
const BRIDGE_PATH := (
	"res://game/world/routes/transitions/playable_blackout_bridge_2d.gd"
)


func _init() -> void:
	var errors: Array[String] = []
	var route := _read_json(ROUTE_PATH)
	var production := _find_record(route.get("profiles", []), "profile_id", "production")
	var entry := _find_record(route.get("edges", []), "edge_id", "enter_vista")
	_check(
		str(production.get("entry_edge_id", "")) == "enter_vista",
		"production does not enter the authored approach",
		errors
	)
	_check(
		str(entry.get("transition_style", "")) == "playable_blackout",
		"enter_vista is not playable_blackout",
		errors
	)
	var manager_text := _read_text(MANAGER_PATH)
	var ingress_text := _read_text(INGRESS_PATH)
	var bridge_text := _read_text(BRIDGE_PATH)
	for token in [
		"_run_playable_blackout_transition",
		"wait_for_bridge_run",
		"fade_origin_branches",
	]:
		_check(manager_text.contains(token), "manager missing %s" % token, errors)
	_check(
		ingress_text.contains("complete_deferred_origin_isolation"),
		"world ingress isolates procgen before blackout coverage",
		errors
	)
	for token in [
		"BlackWorldSpaceBackdrop",
		"BlackoutRouteContactShadow",
		"BlackoutRouteRails",
	]:
		_check(bridge_text.contains(token), "bridge missing %s" % token, errors)
	_finish(errors, "SunderedKeepPlayableBlackoutTransitionSmoke")


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(_read_text(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _find_record(records: Variant, key: String, value: String) -> Dictionary:
	for raw: Variant in records:
		if raw is Dictionary and str((raw as Dictionary).get(key, "")) == value:
			return raw as Dictionary
	return {}


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)


func _finish(errors: Array[String], label: String) -> void:
	if errors.is_empty():
		print("[%s] PASS" % label)
		quit(0)
		return
	for error in errors:
		push_error("[%s] %s" % [label, error])
	quit(1)
