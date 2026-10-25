extends Node
## MusicManager — authoritative global playlist and owner-scoped music lease.
## Two decks overlap cue changes; scoped ducks are mixed independently of cue fades.

signal scoped_track_finished(owner_id: StringName, path: String)
signal scoped_music_silenced(owner_id: StringName)

const DEFAULT_MUSIC_PATHS := [
	"res://content/audio/music/return_causeway/return_causeway_01.ogg",
	"res://content/audio/music/return_causeway/hall_still_answers.ogg",
]
const PLAYER_COUNT := 2
const SILENCE_DB := -60.0

var _player: AudioStreamPlayer = null # Stable legacy handle for MusicPlayer.
var _players: Array[AudioStreamPlayer] = []
var _deck_paths: Array[String] = ["", ""]
var _deck_envelopes: Array[float] = [0.0, 0.0]
var _active_deck := 0
var _current_path := ""
var _playlist_paths: Array[String] = []
var _playlist_index := 0
var _global_volume_db := 0.0
var _scoped_owner: StringName = &""
var _scoped_snapshot: Dictionary = {}
var _scoped_mode: StringName = &""
var _scoped_path := ""
var _scoped_base_volume_db := 0.0
var _scoped_ducks: Dictionary = {}
var _duck_gain_db := 0.0
var _cue_transition_tween: Tween
var _cue_transition_generation := 0
var _duck_tween: Tween
var _duck_generation := 0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		return

	_ensure_players()
	play_playlist(DEFAULT_MUSIC_PATHS)


func _exit_tree() -> void:
	_cancel_cue_transition()
	_cancel_duck_transition()
	for index in range(_players.size()):
		_stop_deck(index)
	_players.clear()
	_player = null
	_current_path = ""
	_playlist_paths.clear()
	_playlist_index = 0


func _ensure_players() -> void:
	if _players.size() == PLAYER_COUNT:
		var all_valid := true
		for player in _players:
			all_valid = all_valid and is_instance_valid(player)
		if all_valid:
			return
	_players.clear()
	for index in range(PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer" if index == 0 else "MusicPlayerSecondary"
		player.bus = "Master"
		player.volume_db = SILENCE_DB
		player.finished.connect(_on_player_finished.bind(index))
		add_child(player)
		_players.append(player)
	_player = _players[0]


func play_track(path: String) -> void:
	if path.is_empty():
		return
	play_playlist([path])


func play_playlist(paths: Array, restart: bool = false) -> void:
	var normalized_paths: Array[String] = []
	for path_variant: Variant in paths:
		var path := str(path_variant)
		if not path.is_empty() and not normalized_paths.has(path):
			normalized_paths.append(path)
	if normalized_paths.is_empty():
		return
	_ensure_players()
	if _scoped_owner.is_empty() \
	and not restart \
	and normalized_paths == _playlist_paths \
	and _active_player() != null \
	and _active_player().playing:
		return

	# A global playlist is a successor-zone claim. It invalidates every pending
	# scoped completion before replacing either deck.
	_cancel_cue_transition()
	_cancel_duck_transition()
	_scoped_owner = &""
	_scoped_snapshot.clear()
	_scoped_mode = &""
	_scoped_path = ""
	_scoped_ducks.clear()
	_duck_gain_db = 0.0
	_playlist_paths = normalized_paths
	_playlist_index = 0
	_stop_all_decks()
	_active_deck = 0
	_current_path = ""
	_refresh_player_volumes()
	_play_playlist_index()


func _play_playlist_index() -> void:
	if _players.is_empty() or _playlist_paths.is_empty():
		return
	for attempt: int in range(_playlist_paths.size()):
		var index := (_playlist_index + attempt) % _playlist_paths.size()
		var path := _playlist_paths[index]
		var stream := _load_music_stream(path, false)
		if stream == null:
			push_warning("[MusicManager] Could not load: %s" % path)
			continue
		_playlist_index = index
		var player := _players[_active_deck]
		player.stop()
		player.stream = stream
		_deck_paths[_active_deck] = path
		_deck_envelopes[_active_deck] = 1.0
		_current_path = path
		_refresh_player_volumes()
		player.play()
		return
	_stop_all_decks()
	_current_path = ""


func _on_player_finished(deck_index: int) -> void:
	if deck_index < 0 or deck_index >= _players.size() or deck_index != _active_deck:
		return
	if not _scoped_owner.is_empty():
		if _scoped_mode == &"one_shot":
			var owner_id := _scoped_owner
			var finished_path := _scoped_path
			_scoped_mode = &"silent"
			_scoped_path = ""
			_stop_deck(deck_index)
			_current_path = ""
			scoped_track_finished.emit(owner_id, finished_path)
		return
	if _playlist_paths.is_empty():
		return
	_playlist_index = (_playlist_index + 1) % _playlist_paths.size()
	_play_playlist_index()


func stop_track() -> void:
	_cancel_cue_transition()
	_cancel_duck_transition()
	_scoped_owner = &""
	_scoped_snapshot.clear()
	_scoped_mode = &""
	_scoped_path = ""
	_scoped_ducks.clear()
	_duck_gain_db = 0.0
	_stop_all_decks()
	_current_path = ""
	_playlist_paths.clear()
	_playlist_index = 0


func get_current_path() -> String:
	return _current_path


func get_playlist_paths() -> Array[String]:
	return _playlist_paths.duplicate()


func get_playlist_index() -> int:
	return _playlist_index


func set_volume_db(value: float) -> void:
	_ensure_players()
	if not _scoped_owner.is_empty():
		_scoped_base_volume_db = value
	else:
		_global_volume_db = value
	_refresh_player_volumes()


func get_volume_db() -> float:
	var player := _active_player()
	return player.volume_db if player != null else _global_volume_db


func begin_scoped_music(owner_id: StringName) -> bool:
	if owner_id.is_empty():
		return false
	if _scoped_owner == owner_id:
		return true
	# Scoped scenes cannot steal another scene's lease. A global playlist is the
	# explicit successor-zone authority and clears this owner before it plays.
	if not _scoped_owner.is_empty():
		return false
	_ensure_players()
	var player := _active_player()
	_scoped_snapshot = {
		"paths": _playlist_paths.duplicate(),
		"index": _playlist_index,
		"path": _current_path,
		"playing": player != null and player.playing,
		"position": player.get_playback_position() if player != null else 0.0,
		"volume_db": _global_volume_db,
		"fade_seconds": 0.35,
	}
	_scoped_owner = owner_id
	_scoped_mode = &"claimed"
	_scoped_path = ""
	_scoped_base_volume_db = _global_volume_db
	_scoped_ducks.clear()
	_cancel_duck_transition()
	_duck_gain_db = 0.0
	_refresh_player_volumes()
	return true


func play_scoped_track(
	owner_id: StringName,
	path: String,
	loop: bool,
	fade_seconds: float = 0.45,
	volume_db: float = 0.0
) -> void:
	if owner_id.is_empty() or owner_id != _scoped_owner or path.is_empty():
		return
	if _scoped_path == path \
	and _scoped_mode == (&"loop" if loop else &"one_shot") \
	and _active_player() != null \
	and _active_player().playing:
		return
	_ensure_players()
	var stream := _load_music_stream(path, loop)
	if stream == null:
		push_warning("[MusicManager] Could not load scoped cue: %s" % path)
		return
	var ticket := _begin_cue_transition()
	var outgoing_index := _active_deck if _active_player() != null and _active_player().playing else -1
	var incoming_index := (1 - _active_deck) if outgoing_index >= 0 else _active_deck
	for index in range(_players.size()):
		if index != outgoing_index and index != incoming_index:
			_stop_deck(index)
	_stop_deck(incoming_index)
	_players[incoming_index].stream = stream
	_deck_paths[incoming_index] = path
	_deck_envelopes[incoming_index] = 0.0
	_active_deck = incoming_index
	_current_path = path
	_scoped_path = path
	_scoped_mode = &"loop" if loop else &"one_shot"
	_scoped_base_volume_db = volume_db
	_refresh_player_volumes()
	_players[incoming_index].play()
	if fade_seconds <= 0.0:
		_on_crossfade_finished(ticket, incoming_index, outgoing_index)
		return
	var outgoing_start := _deck_envelopes[outgoing_index] if outgoing_index >= 0 else 0.0
	_cue_transition_tween = create_tween()
	_cue_transition_tween.set_trans(Tween.TRANS_SINE)
	_cue_transition_tween.set_ease(Tween.EASE_IN_OUT)
	_cue_transition_tween.tween_method(
		_set_crossfade_progress.bind(ticket, incoming_index, outgoing_index, outgoing_start),
		0.0,
		1.0,
		fade_seconds
	)
	_cue_transition_tween.finished.connect(
		_on_crossfade_finished.bind(ticket, incoming_index, outgoing_index),
		CONNECT_ONE_SHOT
	)


func set_scoped_duck(
	owner_id: StringName,
	duck_id: StringName,
	active: bool,
	amount_db: float = -6.0,
	fade_seconds: float = 0.12
) -> void:
	if owner_id.is_empty() or owner_id != _scoped_owner or duck_id.is_empty():
		return
	if active:
		_scoped_ducks[duck_id] = minf(0.0, amount_db)
	else:
		_scoped_ducks.erase(duck_id)
	_set_duck_target(_effective_scoped_duck_db(), fade_seconds)


func stop_scoped_music(owner_id: StringName, fade_seconds: float = 0.35) -> void:
	if owner_id.is_empty() or owner_id != _scoped_owner:
		return
	_scoped_mode = &"silent"
	_scoped_path = ""
	_scoped_ducks.clear()
	_cancel_duck_transition()
	_duck_gain_db = 0.0
	_refresh_player_volumes()
	_fade_scoped_to_silence(owner_id, fade_seconds)


func release_scoped_music(owner_id: StringName, fade_seconds: float = 0.35) -> void:
	if owner_id.is_empty() or owner_id != _scoped_owner:
		return
	var snapshot := _scoped_snapshot.duplicate(true)
	snapshot["fade_seconds"] = fade_seconds
	_scoped_ducks.clear()
	_cancel_duck_transition()
	_duck_gain_db = 0.0
	_refresh_player_volumes()
	_fade_scoped_to_silence(owner_id, fade_seconds, snapshot)


func get_scoped_owner() -> StringName:
	return _scoped_owner


func get_active_deck_index() -> int:
	return _active_deck


func _load_music_stream(path: String, loop: bool) -> AudioStreamOggVorbis:
	var source := load(path) as AudioStreamOggVorbis
	if source == null:
		return null
	var stream := source.duplicate(true) as AudioStreamOggVorbis
	if stream == null:
		return null
	stream.set_loop(loop)
	stream.set_loop_offset(0.0)
	return stream


func _fade_scoped_to_silence(
	owner_id: StringName,
	seconds: float,
	restore_snapshot: Dictionary = {}
) -> void:
	var ticket := _begin_cue_transition()
	if seconds <= 0.0 or not _any_deck_playing():
		_on_silence_transition_finished(ticket, owner_id, restore_snapshot)
		return
	var start_envelopes: Array[float] = _deck_envelopes.duplicate()
	_cue_transition_tween = create_tween()
	_cue_transition_tween.set_trans(Tween.TRANS_SINE)
	_cue_transition_tween.set_ease(Tween.EASE_IN_OUT)
	_cue_transition_tween.tween_method(
		_set_silence_progress.bind(ticket, start_envelopes), 0.0, 1.0, seconds
	)
	_cue_transition_tween.finished.connect(
		_on_silence_transition_finished.bind(ticket, owner_id, restore_snapshot),
		CONNECT_ONE_SHOT
	)


func _set_crossfade_progress(
	progress: float,
	ticket: int,
	incoming_index: int,
	outgoing_index: int,
	outgoing_start: float
) -> void:
	if ticket != _cue_transition_generation:
		return
	var clamped := clampf(progress, 0.0, 1.0)
	_deck_envelopes[incoming_index] = sin(clamped * PI * 0.5)
	if outgoing_index >= 0:
		_deck_envelopes[outgoing_index] = outgoing_start * cos(clamped * PI * 0.5)
	_refresh_player_volumes()


func _on_crossfade_finished(ticket: int, incoming_index: int, outgoing_index: int) -> void:
	if ticket != _cue_transition_generation:
		return
	_deck_envelopes[incoming_index] = 1.0
	if outgoing_index >= 0:
		_stop_deck(outgoing_index)
	_refresh_player_volumes()
	_cue_transition_tween = null


func _set_silence_progress(progress: float, ticket: int, starts: Array[float]) -> void:
	if ticket != _cue_transition_generation:
		return
	var remaining := 1.0 - clampf(progress, 0.0, 1.0)
	for index in range(_players.size()):
		_deck_envelopes[index] = starts[index] * remaining
	_refresh_player_volumes()


func _on_silence_transition_finished(
	ticket: int,
	owner_id: StringName,
	restore_snapshot: Dictionary
) -> void:
	if ticket != _cue_transition_generation or owner_id != _scoped_owner:
		return
	_stop_all_decks()
	_current_path = ""
	_cue_transition_tween = null
	scoped_music_silenced.emit(owner_id)
	if not restore_snapshot.is_empty():
		_restore_playlist_snapshot(owner_id, restore_snapshot)


func _restore_playlist_snapshot(owner_id: StringName, snapshot: Dictionary) -> void:
	if owner_id != _scoped_owner:
		return
	_scoped_owner = &""
	_scoped_mode = &""
	_scoped_path = ""
	_scoped_snapshot.clear()
	_scoped_ducks.clear()
	_duck_gain_db = 0.0
	_playlist_paths.clear()
	for value: Variant in snapshot.get("paths", []):
		_playlist_paths.append(str(value))
	_playlist_index = int(snapshot.get("index", 0))
	_global_volume_db = float(snapshot.get("volume_db", 0.0))
	if not bool(snapshot.get("playing", false)):
		_current_path = ""
		_refresh_player_volumes()
		return
	var path := str(snapshot.get("path", ""))
	var stream := _load_music_stream(path, false) if not path.is_empty() else null
	if stream == null:
		_current_path = ""
		_refresh_player_volumes()
		return
	var incoming_index := 1 - _active_deck
	_stop_all_decks()
	_active_deck = incoming_index
	_players[incoming_index].stream = stream
	_deck_paths[incoming_index] = path
	_deck_envelopes[incoming_index] = 0.0
	_current_path = path
	_refresh_player_volumes()
	_players[incoming_index].play(maxf(0.0, float(snapshot.get("position", 0.0))))
	var ticket := _begin_cue_transition()
	if float(snapshot.get("fade_seconds", 0.35)) <= 0.0:
		_deck_envelopes[incoming_index] = 1.0
		_refresh_player_volumes()
		return
	_cue_transition_tween = create_tween()
	_cue_transition_tween.set_trans(Tween.TRANS_SINE)
	_cue_transition_tween.set_ease(Tween.EASE_IN_OUT)
	_cue_transition_tween.tween_method(
		_set_crossfade_progress.bind(ticket, incoming_index, -1, 0.0),
		0.0,
		1.0,
		float(snapshot.get("fade_seconds", 0.35))
	)
	_cue_transition_tween.finished.connect(
		_on_crossfade_finished.bind(ticket, incoming_index, -1), CONNECT_ONE_SHOT
	)


func _set_duck_target(target_db: float, seconds: float) -> void:
	_cancel_duck_transition()
	var ticket := _duck_generation
	if seconds <= 0.0:
		_duck_gain_db = target_db
		_refresh_player_volumes()
		return
	_duck_tween = create_tween()
	_duck_tween.set_trans(Tween.TRANS_SINE)
	_duck_tween.set_ease(Tween.EASE_IN_OUT)
	_duck_tween.tween_method(
		_set_duck_gain.bind(ticket), _duck_gain_db, target_db, seconds
	)
	_duck_tween.finished.connect(_on_duck_finished.bind(ticket), CONNECT_ONE_SHOT)


func _set_duck_gain(value: float, ticket: int) -> void:
	if ticket != _duck_generation:
		return
	_duck_gain_db = value
	_refresh_player_volumes()


func _on_duck_finished(ticket: int) -> void:
	if ticket == _duck_generation:
		_duck_tween = null


func _effective_scoped_duck_db() -> float:
	var duck_db := 0.0
	for value: Variant in _scoped_ducks.values():
		duck_db = minf(duck_db, float(value))
	return duck_db


func _refresh_player_volumes() -> void:
	var base_db := _scoped_base_volume_db if not _scoped_owner.is_empty() else _global_volume_db
	for index in range(_players.size()):
		if _deck_envelopes[index] <= 0.0:
			_players[index].volume_db = SILENCE_DB
		else:
			_players[index].volume_db = maxf(
				SILENCE_DB,
				base_db + _duck_gain_db + linear_to_db(_deck_envelopes[index])
			)


func _active_player() -> AudioStreamPlayer:
	if _players.is_empty() or _active_deck < 0 or _active_deck >= _players.size():
		return null
	return _players[_active_deck]


func _any_deck_playing() -> bool:
	for player in _players:
		if player.playing:
			return true
	return false


func _stop_deck(index: int) -> void:
	if index < 0 or index >= _players.size():
		return
	_players[index].stop()
	_players[index].stream = null
	_players[index].volume_db = SILENCE_DB
	_deck_paths[index] = ""
	_deck_envelopes[index] = 0.0


func _stop_all_decks() -> void:
	for index in range(_players.size()):
		_stop_deck(index)


func _begin_cue_transition() -> int:
	_cancel_cue_transition()
	return _cue_transition_generation


func _cancel_cue_transition() -> void:
	_cue_transition_generation += 1
	if _cue_transition_tween != null and _cue_transition_tween.is_valid():
		_cue_transition_tween.kill()
	_cue_transition_tween = null


func _cancel_duck_transition() -> void:
	_duck_generation += 1
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = null
