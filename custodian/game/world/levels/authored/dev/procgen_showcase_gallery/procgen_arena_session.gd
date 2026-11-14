extends Node
class_name ProcgenArenaSession

signal session_updated(status: Dictionary)

const HOST_SCRIPT := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_host.gd")
const PRESET_PATH := "res://content/data/dev/procgen_showcase/generation_presets.v1.json"
const DEFAULT_SEED := 417203
const MAX_SEED := 2147483647

enum GenerationState { IDLE, BUILDING, READY, FAILED }

var _gallery: Node2D
var _controls: Node
var _accepted_host: Node
var _staging_host: Node
var _presets: Dictionary = {}
var _selected_preset_id := "ascent_compact"
var _selected_seed := DEFAULT_SEED
var _state := GenerationState.IDLE
var _last_error := ""
var _token := 0
var _last_fingerprint := ""
var _accepted_revision := 0
var _destroying := false


func _ready() -> void:
	_gallery = get_parent() as Node2D
	_presets = _load_presets()
	if _presets.is_empty():
		_fail("No validated generation presets are available.")
		return
	_selected_preset_id = str(_presets.keys()[0])
	_selected_seed = int(_presets[_selected_preset_id].get("seed", DEFAULT_SEED))
	_start_candidate(_selected_seed, _selected_preset_id, true)


func bind_controls(controls: Node) -> void:
	_controls = controls
	if is_instance_valid(_controls):
		_controls.call("bind_session", self, _presets)
		_publish_status()


func get_presets() -> Dictionary:
	return _presets.duplicate(true)


func get_session_status() -> Dictionary:
	var accepted_status: Dictionary = _accepted_host.call("get_arena_status") if is_instance_valid(_accepted_host) else {}
	var staging_status: Dictionary = _staging_host.call("get_arena_status") if is_instance_valid(_staging_host) else {}
	return {
		"state": _state_name(),
		"seed": _selected_seed,
		"preset_id": _selected_preset_id,
		"error": _last_error,
		"fingerprint": _last_fingerprint,
		"accepted_revision": _accepted_revision,
		"busy": _state == GenerationState.BUILDING,
		"operator_in_arena": bool(accepted_status.get("active", false)),
		"accepted_ready": bool(accepted_status.get("ready", false)) or bool(accepted_status.get("active", false)),
		"staging_complete": bool(staging_status.get("staging_complete", false)),
		"accepted_host_count": 1 if is_instance_valid(_accepted_host) else 0,
		"staging_host_count": 1 if is_instance_valid(_staging_host) else 0,
	}


## Detached read-only projection of the currently accepted generated world.
## The session remains the sole authority that selects which host is accepted.
func get_accepted_inspector_snapshot() -> Dictionary:
	if not is_instance_valid(_accepted_host) or not _accepted_host.has_method("get_inspector_snapshot"):
		return {}
	return (_accepted_host.call("get_inspector_snapshot") as Dictionary).duplicate(true)


func set_seed(seed_value: int) -> bool:
	if seed_value < 0 or seed_value > MAX_SEED or _is_busy_or_active():
		return false
	_selected_seed = seed_value
	_last_error = ""
	_publish_status()
	return true


func set_preset(preset_id: String) -> bool:
	if not _presets.has(preset_id) or _is_busy_or_active():
		return false
	_selected_preset_id = preset_id
	_selected_seed = int(_presets[preset_id].get("seed", _selected_seed))
	_last_error = ""
	_publish_status()
	return true


func regenerate_same_seed() -> bool:
	return request_generation(_selected_seed, _selected_preset_id)


func reroll_explicit_seed(seed_value: int) -> bool:
	return request_generation(seed_value, _selected_preset_id)


func request_generation(seed_value: int, preset_id: String) -> bool:
	if _state == GenerationState.BUILDING or is_instance_valid(_staging_host):
		return _reject("Generation is busy; wait for the current request to finish.")
	if bool(get_session_status().get("operator_in_arena", false)):
		return _reject("Return the Operator to the gallery before regenerating the active arena.")
	if seed_value < 0 or seed_value > MAX_SEED:
		return _reject("Seed must be an integer from 0 through 2147483647.")
	if not _presets.has(preset_id):
		return _reject("Select a validated generation preset.")
	_selected_seed = seed_value
	_selected_preset_id = preset_id
	_start_candidate(seed_value, preset_id, false)
	return true


func cancel_generation() -> bool:
	if _state != GenerationState.BUILDING or not is_instance_valid(_staging_host):
		return false
	_token += 1
	_staging_host.call("cancel_generation")
	_staging_host.tree_exited.connect(_on_cancelled_candidate_exited.bind(_staging_host), CONNECT_ONE_SHOT)
	_staging_host.queue_free()
	_state = GenerationState.IDLE if is_instance_valid(_accepted_host) else GenerationState.FAILED
	_last_error = "Generation cancelled. Retry when staged resources have been released."
	_publish_status()
	return true


func _start_candidate(seed_value: int, preset_id: String, initial: bool) -> void:
	if not is_instance_valid(_gallery) or is_instance_valid(_staging_host):
		_fail("Gallery is unavailable or another staging candidate still owns resources.")
		return
	var request: Dictionary = _presets[preset_id].duplicate(true)
	request["seed"] = seed_value
	request["map_size"] = [int(request.map_size[0]), int(request.map_size[1])]
	request["room_count"] = int(request.room_count)
	var candidate := HOST_SCRIPT.new() as Node
	candidate.name = "ProcgenArenaHost" if not is_instance_valid(_accepted_host) else "ProcgenArenaHostStaging"
	if not bool(candidate.call("configure_generation_request", request)):
		candidate.free()
		_fail("Generation request did not pass the host's validated preset contract.")
		return
	_staging_host = candidate
	_state = GenerationState.BUILDING
	_last_error = ""
	_token += 1
	var candidate_token := _token
	candidate.set_meta("session_token", candidate_token)
	candidate.connect("staging_finished", _on_candidate_staged.bind(candidate, candidate_token, initial), CONNECT_ONE_SHOT)
	_gallery.add_child(candidate)
	_publish_status()


func _on_candidate_staged(status: Dictionary, candidate: Node, candidate_token: int, initial: bool) -> void:
	if not is_instance_valid(candidate):
		return
	if candidate != _staging_host or candidate_token != _token or _destroying:
		candidate.call("dispose_if_safe")
		return
	if not bool(status.get("ready", false)):
		var reason := str(status.get("failure", "Generated arena staging failed."))
		candidate.call("dispose_if_safe")
		_staging_host = null
		_state = GenerationState.IDLE if is_instance_valid(_accepted_host) else GenerationState.FAILED
		_last_error = reason
		_publish_status()
		return
	if is_instance_valid(_accepted_host) and bool(_accepted_host.call("get_arena_status").get("active", false)):
		candidate.call("dispose_if_safe")
		_staging_host = null
		_state = GenerationState.READY
		_last_error = "Operator entered the accepted arena while staging; staged replacement was discarded."
		_publish_status()
		return
	var previous := _accepted_host
	if is_instance_valid(previous):
		previous.name = "ProcgenArenaHostRetiring"
		previous.call("set_interaction_enabled", false)
	candidate.name = "ProcgenArenaHost"
	candidate.call("set_session_accepted", true)
	_accepted_host = candidate
	_staging_host = null
	_last_fingerprint = str(status.get("generation_fingerprint", ""))
	_accepted_revision += 1
	_state = GenerationState.READY
	_last_error = ""
	if is_instance_valid(previous):
		previous.call("dispose_if_safe")
	_publish_status()


func _on_cancelled_candidate_exited(candidate: Node) -> void:
	if _staging_host == candidate:
		_staging_host = null
	if _state == GenerationState.IDLE and _last_error.begins_with("Generation cancelled"):
		await get_tree().process_frame
		await get_tree().process_frame
		_last_error = "Generation cancelled. You can retry."
		_publish_status()


func _load_presets() -> Dictionary:
	if not FileAccess.file_exists(PRESET_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESET_PATH))
	if not parsed is Dictionary or not (parsed as Dictionary).get("presets", []) is Array:
		return {}
	var result := {}
	for item: Variant in parsed.presets:
		if not item is Dictionary:
			continue
		var preset: Dictionary = item
		if _valid_preset(preset):
			result[str(preset.preset_id)] = preset.duplicate(true)
	return result


func _valid_preset(preset: Dictionary) -> bool:
	var map_size: Variant = preset.get("map_size", null)
	if not map_size is Array or map_size.size() != 2:
		return false
	return str(preset.get("profile_id", "")) == "sundered_keep_ascent" \
			and int(map_size[0]) == 96 \
			and int(map_size[1]) == 96 \
			and int(preset.get("room_count", 0)) == 12 \
			and int(preset.get("seed", -1)) >= 0 \
			and int(preset.get("seed", -1)) <= MAX_SEED \
			and not str(preset.get("preset_id", "")).is_empty()


func _is_busy_or_active() -> bool:
	return _state == GenerationState.BUILDING or bool(get_session_status().get("operator_in_arena", false))


func _reject(message: String) -> bool:
	_last_error = message
	_publish_status()
	return false


func _fail(message: String) -> void:
	_state = GenerationState.FAILED
	_last_error = message
	_publish_status()


func _publish_status() -> void:
	var status := get_session_status()
	session_updated.emit(status)
	if is_instance_valid(_controls):
		_controls.call("refresh_status", status)


func _state_name() -> String:
	match _state:
		GenerationState.IDLE: return "IDLE"
		GenerationState.BUILDING: return "BUILDING"
		GenerationState.READY: return "READY"
		_: return "FAILED"


func _exit_tree() -> void:
	_destroying = true
	_token += 1
	if is_instance_valid(_staging_host):
		_staging_host.call("cancel_generation")
		_staging_host.queue_free()


func _on_host_finished(_status: Dictionary) -> void:
	_publish_status()
