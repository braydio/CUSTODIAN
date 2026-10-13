class_name ForlornRitualantMusicDirector
extends Node
## Scene-scoped adapter from authored Ritualant events to the single MusicManager player.

const OWNER_PREFIX := "forlorn_ritualant_underground_"
const EXPLORATION_TRACK := "res://content/audio/music/ash_bell/forlorn_ritualant_the_ninth_was_never_cast_loop_v2.ogg"
const COMBAT_TRACK := "res://content/audio/music/ash_bell/forlorn_ritualant_the_ninth_answers_nothing_combat_loop_v2.ogg"
const STILLING_TRACK := "res://content/audio/music/ash_bell/forlorn_ritualant_stilling_release_v1.ogg"
const HOSTILE_TRACK := "res://content/audio/music/ash_bell/forlorn_ritualant_the_ninth_was_taken_hostile_resolution_v1.ogg"

@export_range(-18.0, -1.0, 0.5) var dialogue_duck_db := -6.0
@export_range(-18.0, -1.0, 0.5) var ninth_answer_duck_db := -8.0
@export_range(0.1, 2.0, 0.05) var ninth_answer_duck_seconds := 0.7
@export_range(0.0, 2.0, 0.05) var transition_seconds := 0.45

var _level: Node
var _site: ForlornRitualantSite
var _event_state: AshBellEventState
var _music_manager: Node
var _owner_id: StringName
var _has_music_claim := false
var _reveal_reached := false
var _exploration_started := false
var _peaceful_cue_started := false
var _hostile_cue_started := false
var _restoring_route_state := false
var _restored_terminal_state := false
var _dialogue_duck_active := false
var _ninth_answer_duck_active := false
var _ninth_answer_duck_remaining := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_level = get_parent()
	_site = _level.get_node_or_null("PlayableRoot/ForlornRitualantSite") as ForlornRitualantSite
	if _site == null or _site.event_state == null:
		push_warning("[RitualantMusic] Authored site state is unavailable")
		return
	_event_state = _site.event_state
	_music_manager = get_node_or_null("/root/MusicManager")
	if _music_manager == null:
		push_warning("[RitualantMusic] MusicManager is unavailable")
		return
	_owner_id = StringName(OWNER_PREFIX + str(get_instance_id()))
	if _music_manager.has_signal("scoped_track_finished"):
		_music_manager.scoped_track_finished.connect(_on_scoped_track_finished)
	if not _site.music_cue_requested.is_connected(_on_site_music_cue_requested):
		_site.music_cue_requested.connect(_on_site_music_cue_requested)
	if not _event_state.resolution_changed.is_connected(_on_resolution_changed):
		_event_state.resolution_changed.connect(_on_resolution_changed)
	var ritualant := _site.forlorn_ritualant
	if ritualant != null:
		if ritualant.has_signal("ninth_answer_started"):
			ritualant.ninth_answer_started.connect(_on_ninth_answer_started)
	var camera_director := _level.get("camera_zone_director") as AuthoredCameraZoneDirector2D
	if camera_director != null:
		if not camera_director.active_profile_changed.is_connected(_on_camera_profile_changed):
			camera_director.active_profile_changed.connect(_on_camera_profile_changed)
		if camera_director.get_active_profile_id() in [&"CHAPEL_APPROACH", &"CHAPEL_GAMEPLAY_RELEASE"]:
			_reveal_reached = true
			_start_exploration_if_eligible()


func _process(delta: float) -> void:
	if _ninth_answer_duck_active:
		_ninth_answer_duck_remaining = maxf(0.0, _ninth_answer_duck_remaining - delta)
		if _ninth_answer_duck_remaining <= 0.0:
			_ninth_answer_duck_active = false
			_apply_ducks()
	var presenter := _site.dialogue_presenter if _site != null else null
	var dialogue_active := presenter != null and presenter.is_active()
	if dialogue_active != _dialogue_duck_active:
		_dialogue_duck_active = dialogue_active
		_apply_ducks()


func begin_route_restore() -> void:
	_restoring_route_state = true


func complete_route_restore(restore_succeeded: bool) -> void:
	_restoring_route_state = false
	if not restore_succeeded or _event_state == null:
		return
	var resolution := _event_state.resolution
	_restored_terminal_state = resolution in [
		AshBellEventState.Resolution.RITUALANT_DISSOLVED,
		AshBellEventState.Resolution.SITE_STABILIZED,
		AshBellEventState.Resolution.SITE_DEFILED,
	]
	if _event_state.ritualant_hostile and not _restored_terminal_state:
		_play_combat_loop()
	elif _restored_terminal_state:
		if _has_music_claim:
			_music_manager.stop_scoped_music(_owner_id, transition_seconds)
	elif _reveal_reached:
		_start_exploration_if_eligible()


func _on_camera_profile_changed(_previous: StringName, current: StringName) -> void:
	if current in [&"CHAPEL_APPROACH", &"CHAPEL_GAMEPLAY_RELEASE"]:
		_reveal_reached = true
		_start_exploration_if_eligible()


func _start_exploration_if_eligible() -> void:
	if _exploration_started or _restored_terminal_state or _event_state == null:
		return
	if _event_state.ritualant_hostile:
		_play_combat_loop()
		return
	if _event_state.resolution in [
		AshBellEventState.Resolution.RITUALANT_DISSOLVED,
		AshBellEventState.Resolution.SITE_STABILIZED,
		AshBellEventState.Resolution.SITE_DEFILED,
	]:
		return
	if not _claim_music():
		return
	_exploration_started = true
	_music_manager.play_scoped_track(_owner_id, EXPLORATION_TRACK, true, transition_seconds)


func _on_resolution_changed(new_resolution: int) -> void:
	if _restoring_route_state or _event_state == null:
		return
	match new_resolution:
		AshBellEventState.Resolution.PROVOKED_RITUALANT:
			_play_combat_loop()
		AshBellEventState.Resolution.SITE_DEFILED:
			_play_hostile_resolution()
		AshBellEventState.Resolution.RITUALANT_DISSOLVED:
			# Survival is a nonlethal terminal outcome, so it resolves to quiet.
			if _claim_music():
				_music_manager.stop_scoped_music(_owner_id, transition_seconds)


func _on_site_music_cue_requested(cue_id: StringName) -> void:
	if _restoring_route_state or cue_id != &"stilling_release" or _peaceful_cue_started:
		return
	_peaceful_cue_started = true
	if _claim_music():
		_music_manager.play_scoped_track(_owner_id, STILLING_TRACK, false, transition_seconds)


func _play_combat_loop() -> void:
	if _event_state == null or not _event_state.ritualant_hostile:
		return
	if _claim_music():
		_music_manager.play_scoped_track(_owner_id, COMBAT_TRACK, true, transition_seconds)
		_exploration_started = true


func _play_hostile_resolution() -> void:
	if _hostile_cue_started:
		return
	_hostile_cue_started = true
	if _claim_music():
		_music_manager.play_scoped_track(_owner_id, HOSTILE_TRACK, false, transition_seconds)


func _on_ninth_answer_started() -> void:
	if not _has_music_claim or not _event_state.ritualant_hostile:
		return
	_ninth_answer_duck_active = true
	_ninth_answer_duck_remaining = ninth_answer_duck_seconds
	_apply_ducks()


func _apply_ducks() -> void:
	if not _has_music_claim or _music_manager == null:
		return
	_music_manager.set_scoped_duck(
		_owner_id, &"dialogue", _dialogue_duck_active, dialogue_duck_db, 0.16
	)
	_music_manager.set_scoped_duck(
		_owner_id, &"ninth_answer", _ninth_answer_duck_active, ninth_answer_duck_db, 0.08
	)


func _claim_music() -> bool:
	if _music_manager == null:
		return false
	if not _has_music_claim:
		_has_music_claim = _music_manager.begin_scoped_music(_owner_id)
	return _has_music_claim and _music_manager.get_scoped_owner() == _owner_id


func _on_scoped_track_finished(owner_id: StringName, finished_path: String) -> void:
	if owner_id != _owner_id or not _has_music_claim:
		return
	if finished_path in [STILLING_TRACK, HOSTILE_TRACK] and not _restored_terminal_state:
		_music_manager.play_scoped_track(_owner_id, EXPLORATION_TRACK, true, transition_seconds)
		_exploration_started = true


func debug_get_owner_id() -> StringName:
	return _owner_id


func debug_get_active_duck_db() -> float:
	var active: Array[float] = []
	if _dialogue_duck_active:
		active.append(dialogue_duck_db)
	if _ninth_answer_duck_active:
		active.append(ninth_answer_duck_db)
	return active.min() if not active.is_empty() else 0.0


func _exit_tree() -> void:
	if _music_manager != null and _has_music_claim:
		_music_manager.release_scoped_music(_owner_id, transition_seconds)
