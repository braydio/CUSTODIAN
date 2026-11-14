extends Node2D
class_name ProcgenGalleryInspector

const OVERLAY_SCRIPT := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_overlay.gd")

var _session: Node
var _overlay: Node2D
var _controls: Node
var _snapshot: Dictionary = {}
var _accepted_revision := -1
var _snapshot_build_count := 0


func _ready() -> void:
	_overlay = OVERLAY_SCRIPT.new() as Node2D
	_overlay.name = "ProcgenGalleryOverlay"
	_overlay.z_index = 100
	add_child(_overlay)
	set_process(false)


func bind_session(session: Node, controls: Node) -> void:
	_session = session
	_controls = controls
	if is_instance_valid(_session) and _session.has_signal("session_updated"):
		var callback := Callable(self, "_on_session_updated")
		if not _session.is_connected("session_updated", callback):
			_session.connect("session_updated", callback)
	if is_instance_valid(_controls) and _controls.has_method("bind_inspector"):
		_controls.call("bind_inspector", self)
	if is_instance_valid(_session):
		_on_session_updated(_session.call("get_session_status"))


func set_layer_enabled(layer: String, enabled: bool) -> void:
	if is_instance_valid(_overlay):
		_overlay.call("set_layer_enabled", layer, enabled)


func get_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


func get_snapshot_build_count() -> int:
	return _snapshot_build_count


func refresh_snapshot() -> void:
	if not is_instance_valid(_session):
		_clear_snapshot()
		return
	var status: Dictionary = _session.call("get_session_status")
	if int(status.get("accepted_host_count", 0)) > 0 and bool(status.get("accepted_ready", false)):
		_accepted_revision = -1
	_on_session_updated(status)


func _on_session_updated(status: Dictionary) -> void:
	var accepted_count := int(status.get("accepted_host_count", 0))
	var accepted_ready := bool(status.get("accepted_ready", false))
	if accepted_count == 0:
		if str(status.get("state", "")) != "BUILDING":
			_clear_snapshot()
		return
	if not accepted_ready or not is_instance_valid(_session):
		return
	if str(status.get("state", "")) == "IDLE" and str(status.get("error", "")).begins_with("Generation cancelled"):
		_accepted_revision = -1
	var revision := int(status.get("accepted_revision", -1))
	if revision == _accepted_revision and not _snapshot.is_empty():
		return
	var next_snapshot: Variant = _session.call("get_accepted_inspector_snapshot")
	if not next_snapshot is Dictionary or next_snapshot.is_empty():
		_clear_snapshot()
		return
	_snapshot = (next_snapshot as Dictionary).duplicate(true)
	_accepted_revision = revision
	_snapshot_build_count += 1
	if is_instance_valid(_overlay):
		_overlay.call("set_snapshot", _snapshot)
	if is_instance_valid(_controls) and _controls.has_method("refresh_inspector_snapshot"):
		_controls.call("refresh_inspector_snapshot", _snapshot)


func _clear_snapshot() -> void:
	_snapshot.clear()
	_accepted_revision = -1
	if is_instance_valid(_overlay):
		_overlay.call("clear_snapshot")
	if is_instance_valid(_controls) and _controls.has_method("refresh_inspector_snapshot"):
		_controls.call("refresh_inspector_snapshot", {})


func _exit_tree() -> void:
	if is_instance_valid(_session):
		var callback := Callable(self, "_on_session_updated")
		if _session.is_connected("session_updated", callback):
			_session.disconnect("session_updated", callback)
	_clear_snapshot()
